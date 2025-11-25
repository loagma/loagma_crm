import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../services/user_service.dart';

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

    /// Fetch parameters from go_router
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    contactNumber = args?['contactNumber'];
  }

  Future<void> verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length < 4) {
      Fluttertoast.showToast(msg: "Please enter valid OTP");
      return;
    }

    if (contactNumber == null) {
      Fluttertoast.showToast(msg: "Invalid contact number");
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = await ApiService.verifyOtp(contactNumber!, otp);

      if (!mounted) return;
      setState(() => isLoading = false);

      if (data['success'] != true) {
        Fluttertoast.showToast(msg: data['message'] ?? "Invalid OTP");
        return;
      }

      Fluttertoast.showToast(msg: "OTP Verified Successfully");

      // ---------------------------------------------------------------------
      // SAVE TOKEN (if exists)
      // ---------------------------------------------------------------------
      if (data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
      }

      // ---------------------------------------------------------------------
      // NEW USER → GO TO SIGNUP
      // ---------------------------------------------------------------------
      if (data['isNewUser'] == true) {
        context.push('/signup', extra: {
          'contactNumber': contactNumber,
        });
        return;
      }

      // ---------------------------------------------------------------------
      // EXISTING USER → SAVE FULL SESSION
      // ---------------------------------------------------------------------
      await UserService.loginFromApi(data);

      final userRole = UserService.currentRole;

      if (userRole == null || userRole.isEmpty) {
        Fluttertoast.showToast(msg: "User role missing");
        return;
      }

      // ---------------------------------------------------------------------
      // NAVIGATE TO DASHBOARD (guards will validate)
      // ---------------------------------------------------------------------
      context.go('/dashboard/$userRole');

    } catch (e) {
      if (kDebugMode) print("❌ OTP Verification Error: $e");
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
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Verify OTP',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 100),
              const SizedBox(height: 30),

              Text(
                "Enter the OTP sent to $contactNumber",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Enter OTP",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
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
                    : const Text(
                        "Verify",
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
