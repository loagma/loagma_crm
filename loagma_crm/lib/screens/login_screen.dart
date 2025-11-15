// import 'dart:async';
// import 'package:flutter/foundation.dart' show kDebugMode;
// import 'package:flutter/material.dart';
// import '../services/api_service.dart';
// import 'package:fluttertoast/fluttertoast.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _phoneController = TextEditingController();
//   bool isLoading = false;

//   Future<void> handleSendOtp() async {
//     // Remove all spaces and non-digit characters except +
//     final contactNumber = _phoneController.text.trim().replaceAll(
//       RegExp(r'[^\d+]'),
//       '',
//     );

//     if (contactNumber.isEmpty) {
//       Fluttertoast.showToast(msg: "Please enter your contact number");
//       return;
//     }

//     if (kDebugMode) print("📞 Cleaned contact number: $contactNumber");

//     setState(() => isLoading = true);

//     try {
//       if (kDebugMode) print("📡 Sending OTP request to API...");
//       final response = await ApiService.sendOtp(contactNumber);
//       if (kDebugMode) print("✅ API Response: $response");

//       if (response['success'] == true) {
//         if (!mounted) return;
//         Fluttertoast.showToast(
//           msg: response['message'] ?? "OTP sent successfully",
//         );

//         // Navigate to OTP screen with contactNumber and isNewUser flag
//         Navigator.pushNamed(
//           context,
//           '/otp',
//           arguments: {
//             'contactNumber': contactNumber,
//             'isNewUser': response['isNewUser'] ?? false,
//           },
//         );
//       } else {
//         Fluttertoast.showToast(
//           msg: response['message'] ?? "Something went wrong",
//         );
//       }
//     } catch (e) {
//       if (e is TimeoutException) {
//         Fluttertoast.showToast(
//           msg:
//               "Request timed out. Please check your network or server and try again.",
//         );
//         if (kDebugMode) print("❌ API Timeout: $e");
//       } else {
//         if (kDebugMode) print("❌ API Error: $e");
//         Fluttertoast.showToast(msg: "Error: $e\nCheck your network or server");
//       }
//     } finally {
//       if (mounted) setState(() => isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFD7BE69),
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(25),
//           child: Container(
//             padding: const EdgeInsets.all(30),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(25),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.black26,
//                   blurRadius: 8,
//                   offset: Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Logo
//                 Image.asset('assets/logo.png', width: 120, height: 120),
//                 const SizedBox(height: 20),

//                 // Title text
//                 const Text(
//                   "Login or Signup",
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFFD7BE69),
//                   ),
//                 ),
//                 const SizedBox(height: 30),

//                 // Phone number input
//                 TextField(
//                   controller: _phoneController,
//                   keyboardType: TextInputType.phone,
//                   decoration: InputDecoration(
//                     hintText: "Enter Phone Number",
//                     prefixIcon: const Icon(
//                       Icons.phone_android,
//                       color: Color(0xFFD7BE69),
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//                 // Button
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFFD7BE69),
//                     minimumSize: const Size(double.infinity, 50),

//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   onPressed: isLoading ? null : handleSendOtp,
//                   child: isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text(
//                           "Next",
//                           style: TextStyle(fontSize: 16, color: Colors.white),
//                         ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool isLoading = false;

  Future<void> handleSendOtp() async {
    // Remove spaces and non-digit characters except +
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

                const SizedBox(height: 20), // <-- Added margin above button
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

                // Development Skip Button
                if (kDebugMode) ...[
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      overlayColor: Colors.grey.withOpacity(0.1),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 232, 229, 159).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Skip Login (Dev Mode)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(255, 106, 105, 105),
                          fontWeight: FontWeight.w500,
                          
                          decorationThickness: 1.3,
                        ),
                      ),
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
