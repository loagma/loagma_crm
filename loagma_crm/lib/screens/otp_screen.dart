// import 'package:flutter/material.dart';

// class OtpScreen extends StatefulWidget {
//   const OtpScreen({super.key});

//   @override
//   State<OtpScreen> createState() => _OtpScreenState();
// }

// class _OtpScreenState extends State<OtpScreen> {
//   final TextEditingController _otpController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFD7BE69),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // 🖼️ App Logo
//           Padding(
//             padding: const EdgeInsets.only(bottom: 20),
//             child: Image.asset(
//               'assets/logo.png',
//               height: 100,
//               width: 100,
//             ),
//           ),

//           const Text(
//             "Verify OTP",
//             style: TextStyle(
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),

//           const SizedBox(height: 50),

//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(25),
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
//             ),
//             child: Column(
//               children: [
//                 const Text(
//                   "Enter the OTP sent to your phone",
//                   style: TextStyle(color: Colors.grey),
//                 ),
//                 const SizedBox(height: 20),
//                 TextField(
//                   controller: _otpController,
//                   keyboardType: TextInputType.number,
//                   decoration: InputDecoration(
//                     hintText: "Enter OTP",
//                     prefixIcon: const Icon(Icons.lock, color: Colors.amber),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.amber,
//                     minimumSize: const Size(double.infinity, 45),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                   onPressed: () {
//                     Navigator.pushReplacementNamed(context, '/home');
//                   },
//                   child: const Text(
//                     "Verify & Continue",
//                     style: TextStyle(color: Colors.white),
//                   ),
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
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool isLoading = false;
  String? contactNumber;

  // Use ApiService baseUrl so platform/emulator mappings are consistent
  // (ApiService chooses 10.0.2.2 for Android emulator, localhost for web, etc.)

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Retrieve the contactNumber from route arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    contactNumber = args?['contactNumber'];
  }

  Future<void> verifyOtp() async {
    final otp = _otpController.text.trim();

    if (contactNumber == null || contactNumber!.isEmpty) {
      Fluttertoast.showToast(msg: "Phone number missing. Please login again.");
      Navigator.pop(context);
      return;
    }

    if (otp.isEmpty || otp.length < 4) {
      Fluttertoast.showToast(msg: "Please enter a valid OTP");
      return;
    }

    setState(() => isLoading = true);

    try {
      final url = Uri.parse('${ApiService.baseUrl}/auth/verify-otp');
      if (kDebugMode) print("📡 Verifying OTP for $contactNumber with $otp (url: $url)");

      final response = await http
          .post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contactNumber": contactNumber,
          "otp": otp,
        }),
      )
          .timeout(const Duration(seconds: 10));

  final data = jsonDecode(response.body);
  if (kDebugMode) print("✅ API Response: $data");

      if (response.statusCode == 200 && data['success'] == true) {
        Fluttertoast.showToast(msg: data['message'] ?? "OTP verified successfully");
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? "Invalid OTP");
      }
    } catch (e) {
      if (e is TimeoutException) {
        Fluttertoast.showToast(msg: "Request timed out. Please check your network or server and try again.");
        if (kDebugMode) print("❌ OTP Timeout: $e");
      } else {
        if (kDebugMode) print("❌ Error verifying OTP: $e");
        Fluttertoast.showToast(msg: "Something went wrong. Please try again.");
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7BE69),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Image.asset('assets/logo.png', height: 100, width: 100),
          ),
          const Text(
            "Verify OTP",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 50),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                Text(
                  "Enter the OTP sent to $contactNumber",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Enter OTP",
                    prefixIcon: const Icon(Icons.lock, color: Colors.amber),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isLoading ? null : verifyOtp,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Verify & Continue", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
