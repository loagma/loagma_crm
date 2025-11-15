import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../../services/api_config.dart';

class AdminCreateUserScreen extends StatefulWidget {
  const AdminCreateUserScreen({super.key});

  @override
  State<AdminCreateUserScreen> createState() => _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends State<AdminCreateUserScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String? selectedRoleId;
  bool isLoading = false;
  List<Map<String, dynamic>> roles = [];

  @override
  void initState() {
    super.initState();
    fetchRoles();
  }

  Future<void> fetchRoles() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/roles');
      if (kDebugMode) print('📡 Fetching roles from $url');

      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Request timed out after 30 seconds');
            },
          );

      if (kDebugMode) print('✅ Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (!mounted) return;
          setState(() {
            roles = List<Map<String, dynamic>>.from(data['roles']);
          });
          if (kDebugMode) print('✅ Loaded ${roles.length} roles from backend');
        } else {
          Fluttertoast.showToast(msg: "Failed to load roles");
        }
      } else {
        Fluttertoast.showToast(
          msg: "Failed to load roles: ${response.statusCode}",
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error fetching roles: $e');
      Fluttertoast.showToast(msg: "Error loading roles: Check network");
    }
  }

  Future<void> createUser() async {
    final phone = _phoneController.text.trim();
    final roleId = selectedRoleId;

    if (phone.isEmpty || roleId == null) {
      Fluttertoast.showToast(msg: "Please fill all fields");
      return;
    }

    setState(() => isLoading = true);

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/users');
      if (kDebugMode) print('📡 Creating user via $url');
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"contactNumber": phone, "roleId": roleId}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Fluttertoast.showToast(
          msg: data['message'] ?? "User created successfully",
        );
        _phoneController.clear();
        if (!mounted) return;
        setState(() {
          selectedRoleId = null;
        });
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? "Failed to create user");
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error creating user: $e');
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create User"),
        backgroundColor: const Color(0xFFD7BE69),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Contact Number",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedRoleId,
              items: roles.map((role) {
                return DropdownMenuItem<String>(
                  value: role['id'],
                  child: Text(role['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedRoleId = value;
                });
              },
              decoration: InputDecoration(
                labelText: "Select Role",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFFD7BE69),
              ),
              onPressed: isLoading ? null : createUser,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Create User", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
