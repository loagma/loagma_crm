import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../services/user_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final List<TextEditingController> _otpDigitControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  String? contactNumber;
  bool isLoading = false;

  void _syncOtpValue() {
    _otpController.text = _otpDigitControllers.map((c) => c.text).join();
  }

  @override
  void dispose() {
    _otpController.dispose();
    for (final controller in _otpDigitControllers) {
      controller.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

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
      // NEW USER → CREATE BASIC ACCOUNT AND GO TO NO-ROLE SCREEN
      // ---------------------------------------------------------------------
      if (data['isNewUser'] == true) {
        // For new users, we need to create a basic account first
        // Then they'll be directed to no-role screen until admin assigns role

        // Create a basic user account with minimal info
        try {
          final signupData = await ApiService.completeSignup(
            contactNumber!,
            'New User', // Default name, admin can update later
            '$contactNumber@temp.com', // Temporary email, admin can update later
          );

          if (signupData['success'] == true) {
            // Save the session
            await UserService.loginFromApi(signupData);

            // Navigate to no-role screen (admin needs to assign role)
            context.go('/no-role');
          } else {
            Fluttertoast.showToast(
              msg: signupData['message'] ?? "Failed to create account",
            );
          }
        } catch (e) {
          Fluttertoast.showToast(msg: "Error creating account: $e");
        }
        return;
      }

      // ---------------------------------------------------------------------
      // EXISTING USER → SAVE FULL SESSION
      // ---------------------------------------------------------------------
      await UserService.loginFromApi(data);

      final userRole = UserService.currentRole;
      final userId = UserService.currentUserId;
      final userName = UserService.name;

      if (kDebugMode) {
        print('✅ Login successful:');
        print('   User ID: $userId');
        print('   Role: $userRole');
        print('   Name: $userName');
        print('   Contact: $contactNumber');
      }

      if (userRole == null || userRole.isEmpty) {
        // Navigate to no role screen
        context.go('/no-role');
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.78,
            ),
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/logo.png', height: 84),
                    const SizedBox(height: 14),
                    const Text(
                      'Verify OTP',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enter the 4-digit OTP sent to $contactNumber",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        return Container(
                          width: 58,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          child: TextField(
                            controller: _otpDigitControllers[index],
                            focusNode: _otpFocusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFD7BE69),
                                  width: 2.0,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 3) {
                                _otpFocusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
                                _otpFocusNodes[index - 1].requestFocus();
                              }
                              _syncOtpValue();
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD7BE69),
                          foregroundColor: Colors.black87,
                          disabledBackgroundColor: const Color(0xFFD7BE69),
                          disabledForegroundColor: Colors.black54,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isLoading ? null : verifyOtp,
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black87,
                                ),
                              )
                            : const Text(
                                "Verify OTP",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
