/// Google Places API Configuration
class GooglePlacesConfig {
  // Google Places API Key
  static const String apiKey = 'AIzaSyDWHsbHNwwhNNiQJFDE2BIXMVYv6ZpDOrI';

  // Default search parameters
  static const int defaultRadius = 1500; // meters
  static const String defaultPlaceType = 'store';
  static const int defaultPhotoMaxWidth = 800;

  // Place types for filtering
  static const List<String> businessTypes = [
    'store',
    'restaurant',
    'gas_station',
    'bank',
    'atm',
    'pharmacy',
    'hospital',
    'school',
    'shopping_mall',
    'supermarket',
    'bakery',
    'cafe',
    'clothing_store',
    'electronics_store',
    'furniture_store',
    'hardware_store',
    'jewelry_store',
    'shoe_store',
    'book_store',
    'florist',
    'convenience_store', // Kirana Store equivalent
    'lodging', // Hostel equivalent
    'meal_takeaway', // Caterers equivalent
    'food', // Sweets/confectionery equivalent
  ];

  // Validation
  static bool get isConfigured => apiKey != 'YOUR_GOOGLE_PLACES_API_KEY';

  static void validateConfiguration() {
    if (!isConfigured) {
      throw Exception(
        'Google Places API key not configured. '
        'Please set your API key in GooglePlacesConfig.apiKey',
      );
    }
  }
}
