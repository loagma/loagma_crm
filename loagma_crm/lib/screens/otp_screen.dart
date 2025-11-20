import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/role_router.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  String? contactNumber;
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    contactNumber = args?['contactNumber'];
  }

  Future<void> verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length < 4) {
      Fluttertoast.showToast(msg: "Please enter valid OTP");
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = await ApiService.verifyOtp(contactNumber!, otp);

      if (!mounted) return;
      setState(() => isLoading = false);

      if (kDebugMode) print('🔍 OTP Verify Response: $data');

      if (data['success'] == true) {
        final isNewUser = data['isNewUser'] == true;

        // Store token if available
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          if (kDebugMode) print('🔑 Token saved to SharedPreferences');
        }

        if (isNewUser) {
          if (kDebugMode) print('🆕 Redirecting to signup page...');
          Fluttertoast.showToast(msg: "Please complete your signup");
          Navigator.pushNamed(
            context,
            '/signup',
            arguments: {'contactNumber': contactNumber},
          );
        } else {
          if (kDebugMode) print('✅ Redirecting to role-based dashboard...');
          Fluttertoast.showToast(msg: "Login successful");

          // Get user role and contact from response
          final userRole = data['data']?['role'];
          final userContact = data['data']?['contactNumber'] ?? contactNumber;
          // Navigate to role-based dashboard with contact number
          RoleRouter.navigateToRoleDashboard(
            context,
            userRole,
            userContact: userContact,
          );
        }
      } else {
        if (kDebugMode) print('❌ Verification failed: ${data['message']}');
        Fluttertoast.showToast(msg: data['message'] ?? "Invalid OTP");
      }
    } catch (e) {
      if (kDebugMode) print('❌ Exception during OTP verification: $e');
      if (mounted) setState(() => isLoading = false);
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7BE69),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD7BE69),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Verify OTP',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Image.asset('assets/logo.png', height: 100),
                const SizedBox(height: 40),
                const Text(
                  "Enter the OTP sent to your phone",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Enter OTP",
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: Color.fromARGB(255, 72, 72, 71),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 235, 235, 233),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading ? null : verifyOtp,
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xFFD7BE69),
                        )
                      : const Text("Verify", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
