import 'dart:async';
import 'dart:convert';
import 'dart:math';
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
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _alternativePhoneController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Dropdown values
  String? selectedRoleId;
  String? selectedDepartmentId;
  String? selectedGender;
  String? selectedLanguage;
  bool isActive = true;
  bool autoGeneratePassword = false;

  // Multiple roles selection
  List<String> selectedRoles = [];

  // Data lists
  List<Map<String, dynamic>> roles = [];
  List<Map<String, dynamic>> departments = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchRoles();
    fetchDepartments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _alternativePhoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
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
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error fetching roles: $e');
    }
  }

  Future<void> fetchDepartments() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/departments');
      if (kDebugMode) print('📡 Fetching departments from $url');

      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (!mounted) return;
          setState(() {
            departments = List<Map<String, dynamic>>.from(data['departments']);
          });
          if (kDebugMode) print('✅ Loaded ${departments.length} departments');
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error fetching departments: $e');
    }
  }

  String generatePassword() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(
      12,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contact number is required';
    }
    final phoneRegex = RegExp(r'^\d{10}$');
    final cleanedValue = value.replaceAll(RegExp(r'[^\d]'), '');
    if (!phoneRegex.hasMatch(cleanedValue)) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  String? validateAlternativePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final phoneRegex = RegExp(r'^\d{10}$');
    final cleanedValue = value.replaceAll(RegExp(r'[^\d]'), '');
    if (!phoneRegex.hasMatch(cleanedValue)) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  String? validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final pincodeRegex = RegExp(r'^\d{6}$');
    if (!pincodeRegex.hasMatch(value)) {
      return 'Please enter a valid 6-digit pincode';
    }
    return null;
  }

  String? validateAadhar(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final aadharRegex = RegExp(r'^\d{12}$');
    final cleanedValue = value.replaceAll(RegExp(r'[^\d]'), '');
    if (!aadharRegex.hasMatch(cleanedValue)) {
      return 'Please enter a valid 12-digit Aadhar number';
    }
    return null;
  }

  String? validatePAN(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    if (!panRegex.hasMatch(value.toUpperCase())) {
      return 'Please enter a valid PAN (e.g., ABCDE1234F)';
    }
    return null;
  }

  Future<void> createUser() async {
    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(msg: "Please fix all validation errors");
      return;
    }

    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      Fluttertoast.showToast(msg: "Contact number is required");
      return;
    }

    setState(() => isLoading = true);

    try {
      String? password = _passwordController.text.trim();
      if (autoGeneratePassword) {
        password = generatePassword();
      }

      final body = {
        "contactNumber": phone,
        if (_nameController.text.trim().isNotEmpty)
          "name": _nameController.text.trim(),
        if (_emailController.text.trim().isNotEmpty)
          "email": _emailController.text.trim(),
        if (_alternativePhoneController.text.trim().isNotEmpty)
          "alternativeNumber": _alternativePhoneController.text.trim(),
        if (selectedRoleId != null) "roleId": selectedRoleId,
        if (selectedRoles.isNotEmpty) "roles": selectedRoles,
        if (selectedDepartmentId != null) "departmentId": selectedDepartmentId,
        if (selectedGender != null) "gender": selectedGender,
        if (selectedLanguage != null) "preferredLanguages": [selectedLanguage],
        "isActive": isActive,
        if (password != null && password.isNotEmpty) "password": password,
        if (_addressController.text.trim().isNotEmpty)
          "address": _addressController.text.trim(),
        if (_cityController.text.trim().isNotEmpty)
          "city": _cityController.text.trim(),
        if (_stateController.text.trim().isNotEmpty)
          "state": _stateController.text.trim(),
        if (_pincodeController.text.trim().isNotEmpty)
          "pincode": _pincodeController.text.trim(),
        if (_aadharController.text.trim().isNotEmpty)
          "aadharCard": _aadharController.text.trim(),
        if (_panController.text.trim().isNotEmpty)
          "panCard": _panController.text.trim().toUpperCase(),
        if (_notesController.text.trim().isNotEmpty)
          "notes": _notesController.text.trim(),
      };

      final url = Uri.parse('${ApiConfig.baseUrl}/admin/users');
      if (kDebugMode) print('📡 Creating user via $url');
      if (kDebugMode) print('📤 Request body: $body');

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Fluttertoast.showToast(
          msg: data['message'] ?? "User created successfully",
          toastLength: Toast.LENGTH_LONG,
        );

        if (autoGeneratePassword && password != null) {
          Fluttertoast.showToast(
            msg: "Generated Password: $password",
            toastLength: Toast.LENGTH_LONG,
          );
        }

        // Clear form
        _formKey.currentState!.reset();
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _alternativePhoneController.clear();
        _addressController.clear();
        _cityController.clear();
        _stateController.clear();
        _pincodeController.clear();
        _aadharController.clear();
        _panController.clear();
        _passwordController.clear();
        _notesController.clear();

        if (!mounted) return;
        setState(() {
          selectedRoleId = null;
          selectedDepartmentId = null;
          selectedGender = null;
          selectedLanguage = null;
          selectedRoles.clear();
          isActive = true;
          autoGeneratePassword = false;
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
        title: const Text("Create Employee"),
        backgroundColor: const Color(0xFFD7BE69),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Full Name
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: "Full Name",
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty && value.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),

            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: validateEmail,
            ),
            const SizedBox(height: 15),

            // Contact Number
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: "Contact Number *",
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: "",
              ),
              validator: validatePhone,
            ),
            const SizedBox(height: 15),

            // Alternative Number
            TextFormField(
              controller: _alternativePhoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: "Alternative Number",
                prefixIcon: const Icon(Icons.phone_android),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: "",
              ),
              validator: validateAlternativePhone,
            ),
            const SizedBox(height: 15),

            // Gender
            DropdownButtonFormField<String>(
              value: selectedGender,
              items: const [
                DropdownMenuItem(value: "Male", child: Text("Male")),
                DropdownMenuItem(value: "Female", child: Text("Female")),
                DropdownMenuItem(value: "Other", child: Text("Other")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedGender = value;
                });
              },
              decoration: InputDecoration(
                labelText: "Gender",
                prefixIcon: const Icon(Icons.wc),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Language
            DropdownButtonFormField<String>(
              value: selectedLanguage,
              items: const [
                DropdownMenuItem(value: "English", child: Text("English")),
                DropdownMenuItem(value: "Hindi", child: Text("Hindi")),
                DropdownMenuItem(value: "Marathi", child: Text("Marathi")),
                DropdownMenuItem(value: "Gujarati", child: Text("Gujarati")),
                DropdownMenuItem(value: "Tamil", child: Text("Tamil")),
                DropdownMenuItem(value: "Telugu", child: Text("Telugu")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedLanguage = value;
                });
              },
              decoration: InputDecoration(
                labelText: "Preferred Language",
                prefixIcon: const Icon(Icons.language),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Select Role (Single)
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
                labelText: "Select Primary Role",
                prefixIcon: const Icon(Icons.badge),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Multiple Roles (Checkboxes)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.checklist, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Additional Roles (Multiple Selection)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (roles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Loading roles...",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...roles.map((role) {
                      final roleId = role['id'] as String;
                      return CheckboxListTile(
                        title: Text(role['name']),
                        value: selectedRoles.contains(roleId),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              selectedRoles.add(roleId);
                            } else {
                              selectedRoles.remove(roleId);
                            }
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Department
            DropdownButtonFormField<String>(
              value: selectedDepartmentId,
              items: departments.map((dept) {
                return DropdownMenuItem<String>(
                  value: dept['id'],
                  child: Text(dept['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDepartmentId = value;
                });
              },
              decoration: InputDecoration(
                labelText: "Department/Team",
                prefixIcon: const Icon(Icons.business),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Status
            SwitchListTile(
              title: const Text("Status"),
              subtitle: Text(isActive ? "Active" : "Inactive"),
              value: isActive,
              onChanged: (value) {
                setState(() {
                  isActive = value;
                });
              },
              secondary: Icon(
                isActive ? Icons.check_circle : Icons.cancel,
                color: isActive ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 15),

            // Password Section
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    enabled: !autoGeneratePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (!autoGeneratePassword &&
                          value != null &&
                          value.isNotEmpty &&
                          value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    const Text("Auto Generate", style: TextStyle(fontSize: 12)),
                    Checkbox(
                      value: autoGeneratePassword,
                      onChanged: (value) {
                        setState(() {
                          autoGeneratePassword = value ?? false;
                          if (autoGeneratePassword) {
                            _passwordController.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Address
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: "Address",
                prefixIcon: const Icon(Icons.home),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // City, State
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "City",
                      prefixIcon: const Icon(Icons.location_city),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "State",
                      prefixIcon: const Icon(Icons.map),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Pincode
            TextFormField(
              controller: _pincodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: "Pincode",
                prefixIcon: const Icon(Icons.pin_drop),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: "",
              ),
              validator: validatePincode,
            ),
            const SizedBox(height: 15),

            // Aadhar Card
            TextFormField(
              controller: _aadharController,
              keyboardType: TextInputType.number,
              maxLength: 12,
              decoration: InputDecoration(
                labelText: "Aadhar Card Number",
                prefixIcon: const Icon(Icons.credit_card),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: "",
                hintText: "XXXX XXXX XXXX",
              ),
              validator: validateAadhar,
            ),
            const SizedBox(height: 15),

            // PAN Card
            TextFormField(
              controller: _panController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: "PAN Card Number",
                prefixIcon: const Icon(Icons.account_balance_wallet),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: "",
                hintText: "ABCDE1234F",
              ),
              validator: validatePAN,
            ),
            const SizedBox(height: 15),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "Notes",
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Create Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFFD7BE69),
              ),
              onPressed: isLoading ? null : createUser,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Create Employee",
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
