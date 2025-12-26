import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/google_places_config.dart';

class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Get place details including reviews and photos
  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (!GooglePlacesConfig.isConfigured) {
      print('⚠️ Google Places API key not configured');
      print('📝 To enable Google Places features:');
      print(
        '   1. Get an API key from https://console.cloud.google.com/apis/credentials',
      );
      print('   2. Enable the Places API for your project');
      print('   3. Set your API key in GooglePlacesConfig.apiKey');
      return null;
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/details/json?place_id=$placeId&fields=name,rating,reviews,photos,formatted_phone_number,opening_hours,website,price_level&key=${GooglePlacesConfig.apiKey}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          return data['result'];
        } else {
          print('Google Places API error: ${data['status']}');
          return null;
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching place details: $e');
      return null;
    }
  }

  /// Fetch nearby places using Google Places API
  static Future<List<Map<String, dynamic>>> fetchNearbyPlaces({
    required double lat,
    required double lng,
    required int radius,
    required String type,
  }) async {
    if (!GooglePlacesConfig.isConfigured) {
      print('⚠️ Google Places API key not configured for nearby places');
      return [];
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/nearbysearch/json?location=$lat,$lng&radius=$radius&type=$type&key=${GooglePlacesConfig.apiKey}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(data['results'] ?? []);
        } else {
          print('Google Places API error: ${data['status']}');
          return [];
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching nearby places: $e');
      return [];
    }
  }

  /// Fetch place details (alias for getPlaceDetails for compatibility)
  static Future<Map<String, dynamic>?> fetchPlaceDetails(String placeId) async {
    return getPlaceDetails(placeId);
  }

  /// Get photo URL from photo reference
  static String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    if (!GooglePlacesConfig.isConfigured) {
      return '';
    }
    return '$_baseUrl/photo?maxwidth=$maxWidth&photo_reference=$photoReference&key=${GooglePlacesConfig.apiKey}';
  }

  /// Format reviews for display
  static List<Map<String, dynamic>> formatReviews(List<dynamic>? reviews) {
    if (reviews == null) return [];

    return reviews.map((review) {
      return {
        'author_name': review['author_name'] ?? 'Anonymous',
        'rating': review['rating'] ?? 0,
        'text': review['text'] ?? '',
        'time': review['time'] ?? 0,
        'profile_photo_url': review['profile_photo_url'],
        'relative_time_description': review['relative_time_description'] ?? '',
      };
    }).toList();
  }

  /// Format photos for display
  static List<String> formatPhotos(
    List<dynamic>? photos, {
    int maxWidth = 400,
  }) {
    if (photos == null) return [];

    return photos.map((photo) {
      final photoReference = photo['photo_reference'];
      return getPhotoUrl(photoReference, maxWidth: maxWidth);
    }).toList();
  }

  /// Get opening hours text
  static List<String> getOpeningHours(Map<String, dynamic>? openingHours) {
    if (openingHours == null || openingHours['weekday_text'] == null) {
      return [];
    }
    return List<String>.from(openingHours['weekday_text']);
  }

  /// Format price level
  static String formatPriceLevel(int? priceLevel) {
    if (priceLevel == null) return 'Price not available';

    switch (priceLevel) {
      case 0:
        return 'Free';
      case 1:
        return 'Inexpensive (\$)';
      case 2:
        return 'Moderate (\$\$)';
      case 3:
        return 'Expensive (\$\$\$)';
      case 4:
        return 'Very Expensive (\$\$\$\$)';
      default:
        return 'Price not available';
    }
  }
}
