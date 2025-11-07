import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? selectedRoleId;
  bool isLoading = false;

  // baseUrl moved to ApiService for emulator/device mapping

  List<Map<String, dynamic>> roles = [];

  @override
  void initState() {
    super.initState();
    fetchRoles();
  }

  Future<void> fetchRoles() async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/roles'); // Get all roles API
      if (kDebugMode) print('📡 Fetching roles from $url');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        setState(() {
          roles = List<Map<String, dynamic>>.from(data['roles']);
        });
      } else {
        Fluttertoast.showToast(msg: "Failed to load roles");
      }
    } catch (e) {
      if (e is TimeoutException) {
        Fluttertoast.showToast(msg: "Request timed out while loading roles.");
        if (kDebugMode) print('❌ Roles timeout: $e');
      } else {
        if (kDebugMode) print('❌ Error fetching roles: $e');
        Fluttertoast.showToast(msg: "Error: $e");
      }
    }
  }

  Future<void> createUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final roleId = selectedRoleId;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || roleId == null) {
      Fluttertoast.showToast(msg: "Please fill all fields");
      return;
    }

    setState(() => isLoading = true);

    try {
      final url = Uri.parse('${ApiService.baseUrl}/users');
      if (kDebugMode) print('📡 Creating user via $url');
      final response = await http
          .post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "contactNumber": phone,
          "roleId": roleId,
        }),
      )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Fluttertoast.showToast(msg: data['message'] ?? "User created successfully");
  _nameController.clear();
  _emailController.clear();
  _phoneController.clear();
        if (!mounted) return;
        setState(() {
          selectedRoleId = null;
        });
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? "Failed to create user");
      }
    } catch (e) {
      if (e is TimeoutException) {
        Fluttertoast.showToast(msg: "Request timed out while creating user.");
        if (kDebugMode) print('❌ Create user timeout: $e');
      } else {
        if (kDebugMode) print('❌ Error creating user: $e');
        Fluttertoast.showToast(msg: "Error: $e");
      }
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
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Contact Number",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: selectedRoleId,
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
