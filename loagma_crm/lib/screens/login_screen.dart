// import 'package:flutter/material.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _phoneController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFD7BE69), 
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Text("Login", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
//           const SizedBox(height: 50),
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(25),
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               // borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
//             ),
//             child: Column(
//               children: [
//                 Image.asset('assets/logo.png', width: 150),
//                 const SizedBox(height: 15),
//                 const Text("Please sign in to continue", style: TextStyle(color: Colors.grey)),
//                 const SizedBox(height: 20),
//                 TextField(
//                   controller: _phoneController,
//                   keyboardType: TextInputType.phone,
//                   decoration: InputDecoration(
//                     hintText: "Enter Phone Number",
//                     prefixIcon: const Icon(Icons.phone_android, color: Colors.amber),
//                     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFFD7BE69),
//                     minimumSize: const Size(double.infinity, 45),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                   ),
//                   onPressed: () {
//                     Navigator.pushNamed(context, '/otp');
//                   },
//                   child: const Text("Send OTP", style: TextStyle(color: Colors.white)),
//                 ),
//               ],
//             ),
//           ),
//         ],
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
    final contactNumber = _phoneController.text.trim();

    if (contactNumber.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter your contact number");
      return;
    }

    setState(() => isLoading = true);

    try {
      if (kDebugMode) print("📡 Sending OTP request to API...");
      final response = await ApiService.sendOtp(contactNumber);
      if (kDebugMode) print("✅ API Response: $response");

      if (response['success'] == true) {
        if (!mounted) return;
        Fluttertoast.showToast(msg: response['message'] ?? "OTP sent successfully");

        // Navigate to OTP screen with contactNumber
        Navigator.pushNamed(
          context,
          '/otp',
          arguments: {'contactNumber': contactNumber},
        );
      } else {
        Fluttertoast.showToast(msg: response['message'] ?? "Something went wrong");
      }
    } catch (e) {
      if (e is TimeoutException) {
        Fluttertoast.showToast(msg: "Request timed out. Please check your network or server and try again.");
        if (kDebugMode) print("❌ API Timeout: $e");
      } else {
        if (kDebugMode) print("❌ API Error: $e");
        Fluttertoast.showToast(msg: "Error: $e\nCheck your network or server");
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset('assets/logo.png', width: 150, height: 150),
              const SizedBox(height: 20),

              const Text(
                "Login",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please sign in to continue",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 40),

              // Input container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: "Enter Phone Number",
                        prefixIcon: const Icon(Icons.phone_android, color: Colors.amber),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD7BE69),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isLoading ? null : handleSendOtp,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Send OTP", style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
