import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/user_service.dart';
import '../../services/api_config.dart';
import '../../services/network_service.dart';

class AssignAccountScreen extends StatefulWidget {
  const AssignAccountScreen({super.key});

  @override
  State<AssignAccountScreen> createState() => _AssignAccountScreenState();
}

class _AssignAccountScreenState extends State<AssignAccountScreen> {
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _telecallers = [];

  String? _selectedTelecallerId;
  final Set<int> _selectedDays = {1, 2, 3, 4, 5, 6}; // Mon‑Sat by default
  final TextEditingController _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all users and filter telecallers
      final usersResult = await UserService.getAllUsers();
      final users = List<Map<String, dynamic>>.from(usersResult['data'] ?? []);
      final telecallers = users.where((u) {
        final role =
            (u['role'] ?? u['roleId'] ?? '').toString().toLowerCase();
        return role.contains('telecaller');
      }).toList();

      if (!mounted) return;

      setState(() {
        _telecallers = telecallers;
        if (_telecallers.isNotEmpty) {
          _selectedTelecallerId = _telecallers.first['id'] ??
              _telecallers.first['_id']; // default selection
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  Future<void> _saveAssignment() async {
    if (_selectedTelecallerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a telecaller first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one day'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Parse manual pincode input: comma / space / newline separated 6‑digit values
    final raw = _pincodeController.text;
    final tokens = raw.split(RegExp(r'[,\s]+'));
    final pinSet = <String>{};
    final pinRegex = RegExp(r'^\d{6}$');
    for (final t in tokens) {
      final trimmed = t.trim();
      if (trimmed.isEmpty) continue;
      if (pinRegex.hasMatch(trimmed)) {
        pinSet.add(trimmed);
      }
    }

    if (pinSet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least one valid 6‑digit pincode'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final days = _selectedDays.toList()..sort();

    try {
      final token = UserService.token;
      final headers = {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final body = {
        'assignments': pinSet
            .expand(
              (pin) => days.map(
                (d) => {'pincode': pin, 'dayOfWeek': d},
              ),
            )
            .toList(),
      };

      final uri = Uri.parse(
          '${ApiConfig.teleadminUrl}/telecallers/$_selectedTelecallerId/pincode-assignments');

      final response = await NetworkService.retryApiCall(
        () => http
            .put(uri, headers: headers, body: jsonEncode(body))
            .timeout(const Duration(seconds: 15)),
        maxRetries: 1,
        delay: const Duration(seconds: 2),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD7BE69),
            content: Text(
              'Assignments saved for telecaller. Total: ${data['data']?['count'] ?? pinSet.length * days.length}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception(data['message'] ?? 'Failed to save assignments');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to save assignments: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Account'),
        backgroundColor: const Color(0xFFD7BE69),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD7BE69)),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedTelecallerId,
                        decoration: const InputDecoration(
                          labelText: 'Telecaller',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          ..._telecallers.map(
                            (u) => DropdownMenuItem<String>(
                              value: u['id'] ?? u['_id'],
                              child: Text(u['name'] ?? 'Unknown'),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedTelecallerId = val),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Days',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildDayChip(1, 'Mon'),
                          _buildDayChip(2, 'Tue'),
                          _buildDayChip(3, 'Wed'),
                          _buildDayChip(4, 'Thu'),
                          _buildDayChip(5, 'Fri'),
                          _buildDayChip(6, 'Sat'),
                          _buildDayChip(7, 'Sun'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pincodes (comma / space separated)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _pincodeController,
                          maxLines: null,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'e.g. 482002, 483001 483220',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveAssignment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD7BE69),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Save Assignment'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDayChip(int day, String label) {
    final selected = _selectedDays.contains(day);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _toggleDay(day),
      selectedColor: const Color(0xFFD7BE69).withOpacity(0.2),
      checkmarkColor: const Color(0xFFD7BE69),
    );
  }
}

