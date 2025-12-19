import 'dart:developer';
import 'package:google_place/google_place.dart';
import '../config/google_places_config.dart';

class GooglePlacesService {
  static GooglePlacesService? _instance;
  static GooglePlacesService get instance =>
      _instance ??= GooglePlacesService._();
  GooglePlacesService._();

  late GooglePlace _googlePlace;
  static String get _apiKey => GooglePlacesConfig.apiKey;

  /// Initialize the Google Places service
  void initialize() {
    GooglePlacesConfig.validateConfiguration();
    _googlePlace = GooglePlace(_apiKey);
    log('🗺️ Google Places Service initialized with API key');
  }

  /// Fetch nearby places within specified radius
  ///
  /// [lat] - Latitude of the center point
  /// [lng] - Longitude of the center point
  /// [radius] - Search radius in meters (default: 1500)
  /// [type] - Place type to search for (default: "store")
  ///
  /// Returns list of nearby places with basic information
  Future<List<SearchResult>> fetchNearbyPlaces({
    required double lat,
    required double lng,
    int radius = 1500,
    String type = "store",
  }) async {
    try {
      log(
        '🔍 Searching nearby places at ($lat, $lng) within ${radius}m for type: $type',
      );

      final result = await _googlePlace.search.getNearBySearch(
        Location(lat: lat, lng: lng),
        radius,
        type: type,
      );

      if (result != null && result.results != null) {
        log('✅ Found ${result.results!.length} nearby places');
        return result.results!;
      } else {
        log('⚠️ No nearby places found');
        return [];
      }
    } catch (e) {
      log('❌ Error fetching nearby places: $e');
      throw Exception('Failed to fetch nearby places: $e');
    }
  }

  /// Fetch detailed information about a specific place
  ///
  /// [placeId] - Google Place ID
  ///
  /// Returns detailed place information including:
  /// - name, rating, address
  /// - opening hours (open_now)
  /// - photos with full URLs
  /// - reviews (author, rating, text)
  Future<DetailsResult?> fetchPlaceDetails(String placeId) async {
    try {
      log('📍 Fetching details for place ID: $placeId');

      final result = await _googlePlace.details.get(placeId);

      if (result != null && result.result != null) {
        log('✅ Successfully fetched place details for: ${result.result!.name}');
        return result.result!;
      } else {
        log('⚠️ No details found for place ID: $placeId');
        return null;
      }
    } catch (e) {
      log('❌ Error fetching place details: $e');
      throw Exception('Failed to fetch place details: $e');
    }
  }

  /// Generate Google Photos URL from photo reference
  ///
  /// [photoReference] - Photo reference from place details
  /// [maxWidth] - Maximum width of the photo (default: 800)
  ///
  /// Returns full URL to the photo
  String getPhotoUrl(String photoReference, {int maxWidth = 800}) {
    final url =
        'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=$maxWidth'
        '&photo_reference=$photoReference'
        '&key=$_apiKey';

    log('📸 Generated photo URL for reference: $photoReference');
    return url;
  }

  /// Get multiple photo URLs from place details
  ///
  /// [placeDetails] - Place details result containing photos
  /// [maxWidth] - Maximum width for photos (default: 800)
  ///
  /// Returns list of photo URLs
  List<String> getPhotoUrls(DetailsResult placeDetails, {int maxWidth = 800}) {
    if (placeDetails.photos == null || placeDetails.photos!.isEmpty) {
      return [];
    }

    return placeDetails.photos!
        .map((photo) => getPhotoUrl(photo.photoReference!, maxWidth: maxWidth))
        .toList();
  }

  /// Extract formatted place information for UI display
  ///
  /// [placeDetails] - Place details result
  ///
  /// Returns formatted place information
  Map<String, dynamic> formatPlaceInfo(DetailsResult placeDetails) {
    return {
      'name': placeDetails.name ?? 'Unknown Place',
      'rating': placeDetails.rating?.toDouble() ?? 0.0,
      'address': placeDetails.formattedAddress ?? 'Address not available',
      'openNow': placeDetails.openingHours?.openNow ?? false,
      'photos': getPhotoUrls(placeDetails),
      'reviews':
          placeDetails.reviews
              ?.map(
                (review) => {
                  'author': review.authorName ?? 'Anonymous',
                  'rating': review.rating ?? 0,
                  'text': review.text ?? '',
                  'time': review.relativeTimeDescription ?? '',
                },
              )
              .toList() ??
          [],
      'phoneNumber': placeDetails.formattedPhoneNumber ?? '',
      'website': placeDetails.website ?? '',
      'priceLevel': placeDetails.priceLevel ?? 0,
      'types': placeDetails.types ?? [],
      'placeId': placeDetails.placeId ?? '',
    };
  }

  /// Search for places by text query
  ///
  /// [query] - Search query text
  /// [lat] - Latitude for location bias
  /// [lng] - Longitude for location bias
  ///
  /// Returns list of places matching the query
  Future<List<SearchResult>> searchPlacesByText({
    required String query,
    double? lat,
    double? lng,
  }) async {
    try {
      log('🔍 Searching places by text: "$query"');

      Location? location;
      if (lat != null && lng != null) {
        location = Location(lat: lat, lng: lng);
      }

      final result = await _googlePlace.search.getTextSearch(
        query,
        location: location,
      );

      if (result != null && result.results != null) {
        log('✅ Found ${result.results!.length} places for query: "$query"');
        return result.results!;
      } else {
        log('⚠️ No places found for query: "$query"');
        return [];
      }
    } catch (e) {
      log('❌ Error searching places by text: $e');
      throw Exception('Failed to search places: $e');
    }
  }

  /// Get place types for filtering
  static List<String> getPlaceTypes() {
    return [
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
  }
}

/// Extension to add convenience methods to SearchResult
extension SearchResultExtension on SearchResult {
  /// Get the main photo URL if available
  String? get mainPhotoUrl {
    if (photos != null && photos!.isNotEmpty) {
      return GooglePlacesService.instance.getPhotoUrl(
        photos!.first.photoReference!,
      );
    }
    return null;
  }

  /// Check if the place is currently open
  bool get isOpenNow {
    return openingHours?.openNow ?? false;
  }

  /// Get formatted rating string
  String get formattedRating {
    if (rating != null) {
      return '${rating!.toStringAsFixed(1)} ⭐';
    }
    return 'No rating';
  }
}

/// Extension to add convenience methods to DetailsResult
extension DetailsResultExtension on DetailsResult {
  /// Get all photo URLs
  List<String> get allPhotoUrls {
    return GooglePlacesService.instance.getPhotoUrls(this);
  }

  /// Get the main photo URL
  String? get mainPhotoUrl {
    final urls = allPhotoUrls;
    return urls.isNotEmpty ? urls.first : null;
  }

  /// Check if currently open
  bool get isCurrentlyOpen {
    return openingHours?.openNow ?? false;
  }

  /// Get formatted rating with stars
  String get formattedRating {
    if (rating != null) {
      return '${rating!.toStringAsFixed(1)} ⭐';
    }
    return 'No rating';
  }

  /// Get short address (first part before comma)
  String get shortAddress {
    if (formattedAddress != null) {
      final parts = formattedAddress!.split(',');
      return parts.isNotEmpty ? parts.first.trim() : formattedAddress!;
    }
    return 'Address not available';
  }
}
