import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/role_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? contactNumber;
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    contactNumber = args?['contactNumber'];
  }

  Future<void> completeSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill all fields");
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      Fluttertoast.showToast(msg: "Enter a valid email address");
      return;
    }

    setState(() => isLoading = true);

    try {
      if (kDebugMode) print('📤 Sending signup request...');
      if (kDebugMode) print('📞 Contact: $contactNumber');
      if (kDebugMode) print('👤 Name: $name');
      if (kDebugMode) print('📧 Email: $email');

      final data = await ApiService.completeSignup(contactNumber!, name, email);
      if (kDebugMode) print('📥 Signup Response: $data');

      if (data['success'] == true) {
        // Store token if available
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          if (kDebugMode) print('🔑 Token saved to SharedPreferences');
        }

        Fluttertoast.showToast(msg: "Signup successful! Welcome aboard!");
        if (!mounted) return;

        // Get user role and navigate to role-based dashboard
        final userRole = data['data']?['role'];
        final userContact = data['data']?['contactNumber'] ?? contactNumber;

        RoleRouter.navigateToRoleDashboard(
          context,
          userRole,
          userContact: userContact,
        );
      } else {
        Fluttertoast.showToast(
          msg: data['message'] ?? "Signup failed, please try again.",
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Signup Error: $e');
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
      backgroundColor: const Color(0xFFD7BE69),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                  const Text(
                    "Complete Your Signup",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD7BE69),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 🧾 Read-only Phone Number Field
                  TextField(
                    controller: TextEditingController(
                      text: contactNumber ?? '',
                    ),
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      prefixIcon: const Icon(
                        Icons.phone,
                        color: Color(0xFFD7BE69),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 👤 Name Field
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Color(0xFFD7BE69),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // ✉️ Email Field
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      prefixIcon: const Icon(
                        Icons.email,
                        color: Color(0xFFD7BE69),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 🟡 Submit Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7BE69),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading ? null : completeSignup,
                    child: isLoading
                        ? const SizedBox(
                            height: 25,
                            width: 25,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Create Account",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
