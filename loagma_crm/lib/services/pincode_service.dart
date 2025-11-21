import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class PincodeService {
  /// Fetch location details by pincode
  static Future<Map<String, dynamic>> getLocationByPincode(
    String pincode,
  ) async {
    try {
      // Validate pincode format
      if (pincode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pincode)) {
        return {
          'success': false,
          'message': 'Pincode must be exactly 6 digits',
        };
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/pincode/$pincode');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Pincode not found',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch location: $e'};
    }
  }

  /// Validate pincode format
  static bool isValidPincode(String pincode) {
    return pincode.length == 6 && RegExp(r'^\d{6}$').hasMatch(pincode);
  }
}
