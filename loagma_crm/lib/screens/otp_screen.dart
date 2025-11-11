import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

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

      // Debug logging
      print('🔍 OTP Verify Response: $data');

      if (data['success'] == true) {
        // Successful login for both new and existing users
        print('✅ Redirecting to dashboard...');
        Fluttertoast.showToast(msg: "Login successful");
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        print('❌ Verification failed: ${data['message']}');
        Fluttertoast.showToast(msg: data['message'] ?? "Invalid OTP");
      }
    } catch (e) {
      print('❌ Exception during OTP verification: $e');
      if (mounted) setState(() => isLoading = false);
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7BE69),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', height: 100),
                const SizedBox(height: 30),
                const Text(
                  "Verify OTP",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 50),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Enter OTP",
                    prefixIcon: const Icon(Icons.lock, color: Colors.amber),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: isLoading ? null : verifyOtp,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Verify"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
