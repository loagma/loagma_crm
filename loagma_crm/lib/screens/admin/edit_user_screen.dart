import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../../services/api_config.dart';

class EditUserScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  String? selectedRoleId;
  List<Map<String, dynamic>> roles = [];
  bool isLoading = false;
  bool isLoadingRoles = true;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: widget.user['contactNumber'],
    );
    _nameController = TextEditingController(text: widget.user['name'] ?? '');
    _emailController = TextEditingController(text: widget.user['email'] ?? '');
    selectedRoleId = widget.user['roleId'];
    fetchRoles();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> fetchRoles() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/roles');
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          roles = List<Map<String, dynamic>>.from(data['roles']);
          isLoadingRoles = false;
        });
      } else {
        setState(() => isLoadingRoles = false);
        Fluttertoast.showToast(msg: "Failed to load roles");
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading roles: $e');
      setState(() => isLoadingRoles = false);
      Fluttertoast.showToast(msg: "Error loading roles");
    }
  }

  Future<void> updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/admin/users/${widget.user['id']}',
      );
      if (kDebugMode) print('📡 Updating user via $url');

      final response = await http
          .put(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "contactNumber": _phoneController.text.trim(),
              "name": _nameController.text.trim(),
              "email": _emailController.text.trim(),
              "roleId": selectedRoleId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Fluttertoast.showToast(msg: "User updated successfully");
        if (!mounted) return;
        Navigator.pop(context, true); // Return true to refresh list
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? "Failed to update");
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error updating user: $e');
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit User"),
        backgroundColor: const Color(0xFFD7BE69),
      ),
      body: isLoadingRoles
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD7BE69)),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
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
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Name (Optional)",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email (Optional)",
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
                        setState(() => selectedRoleId = value);
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
                      onPressed: isLoading ? null : updateUser,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Update User",
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
