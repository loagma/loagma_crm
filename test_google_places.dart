// Simple test to verify Google Places data flow
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  await testGooglePlacesAPI();
}

Future<void> testGooglePlacesAPI() async {
  try {
    print('🔍 Testing Google Places API...');

    final uri = Uri.parse('http://localhost:5000/shops/pincode/500080');
    print('📡 URL: $uri');

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    print('📊 Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Success: ${data['success']}');
      print('📊 Total shops: ${data['totalShops']}');
      print('📊 Existing accounts: ${data['existingAccounts']['count']}');
      print('📊 Google Places: ${data['googlePlacesShops']['count']}');

      // Check first few Google Places shops
      final googleShops = data['googlePlacesShops']['shops'] as List;
      print('\n🏪 First 3 Google Places shops:');
      for (int i = 0; i < 3 && i < googleShops.length; i++) {
        final shop = googleShops[i];
        print(
          '  ${i + 1}. ${shop['name']} at (${shop['latitude']}, ${shop['longitude']})',
        );
      }
    } else {
      print('❌ Failed: ${response.statusCode}');
      print('❌ Body: ${response.body}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
