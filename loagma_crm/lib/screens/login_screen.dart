import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/api_config.dart';
import '../utils/role_router.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool isLoading = false;
  bool isLoadingRoles = false;
  String? selectedDevRole;
  List<Map<String, dynamic>> roles = [];

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _loadRoles();
    }
  }

  Future<void> _loadRoles() async {
    setState(() => isLoadingRoles = true);
    try {
      // final url = Uri.parse('${ApiConfig.baseUrl}/roles');
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
      if (kDebugMode) print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (!mounted) return;
          setState(() {
            roles = List<Map<String, dynamic>>.from(data['roles']);
            isLoadingRoles = false;
          });
          if (kDebugMode) print('✅ Loaded ${roles.length} roles');
        } else {
          if (kDebugMode) print('❌ API returned success: false');
          setState(() => isLoadingRoles = false);
        }
      } else {
        if (kDebugMode)
          print('❌ HTTP ${response.statusCode}: ${response.body}');
        setState(() => isLoadingRoles = false);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error fetching roles: $e');
      setState(() => isLoadingRoles = false);
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load roles. Please check your connection.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> handleSendOtp() async {
    final contactNumber = _phoneController.text.trim().replaceAll(
      RegExp(r'[^\d+]'),
      '',
    );

    if (contactNumber.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter your contact number");
      return;
    }

    if (kDebugMode) print("📞 Cleaned contact number: $contactNumber");

    setState(() => isLoading = true);

    try {
      if (kDebugMode) print("📡 Sending OTP request...");
      final response = await ApiService.sendOtp(contactNumber);
      if (kDebugMode) print("✅ API Response: $response");

      if (response['success'] == true) {
        if (!mounted) return;

        Fluttertoast.showToast(
          msg: response['message'] ?? "OTP sent successfully",
        );

        Navigator.pushNamed(
          context,
          '/otp',
          arguments: {
            'contactNumber': contactNumber,
            'isNewUser': response['isNewUser'] ?? false,
          },
        );
      } else {
        Fluttertoast.showToast(
          msg: response['message'] ?? "Something went wrong",
        );
      }
    } catch (e) {
      if (e is TimeoutException) {
        Fluttertoast.showToast(
          msg: "Request timed out. Please check your network/server.",
        );
      } else {
        Fluttertoast.showToast(msg: "Error: $e");
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7BE69),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Image.asset('assets/logo.png', width: 120, height: 120),
                const SizedBox(height: 20),

                // Title
                const Text(
                  "Login or Signup",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD7BE69),
                  ),
                ),
                const SizedBox(height: 30),

                // Phone Input
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: "Enter Phone Number",
                    prefixIcon: const Icon(
                      Icons.phone_android,
                      color: Color(0xFFD7BE69),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                // Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD7BE69),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isLoading ? null : handleSendOtp,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Next",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),

                // Development Skip Button with Role Selection
                if (kDebugMode) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    'Dev Mode - Select Role',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  isLoadingRoles
                      ? Column(
                          children: [
                            const CircularProgressIndicator(
                              color: Color(0xFFD7BE69),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Loading roles from server...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        )
                      : roles.isEmpty
                      ? Column(
                          children: [
                            const Text(
                              'Failed to load roles',
                              style: TextStyle(fontSize: 14, color: Colors.red),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD7BE69),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                              ),
                              onPressed: _loadRoles,
                            ),
                          ],
                        )
                      : DropdownButtonFormField<String>(
                          value: selectedDevRole,
                          items: roles.map((role) {
                            return DropdownMenuItem<String>(
                              value: role['name'],
                              child: Text(role['name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedDevRole = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Choose role to test",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: selectedDevRole == null || isLoadingRoles
                        ? null
                        : () {
                            RoleRouter.navigateToRoleDashboard(
                              context,
                              selectedDevRole,
                              userContact: 'Dev Mode',
                            );
                          },
                    child: const Text(
                      'Skip Login (Dev Mode)',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
