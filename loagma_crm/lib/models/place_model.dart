import 'package:google_place/google_place.dart';
import '../config/google_places_config.dart';

/// Enhanced place model with formatted data for UI
class PlaceInfo {
  final String placeId;
  final String name;
  final double rating;
  final String address;
  final bool isOpenNow;
  final List<String> photoUrls;
  final List<PlaceReview> reviews;
  final String? phoneNumber;
  final String? website;
  final int priceLevel;
  final List<String> types;
  final double? latitude;
  final double? longitude;
  final String? businessStatus;

  PlaceInfo({
    required this.placeId,
    required this.name,
    required this.rating,
    required this.address,
    required this.isOpenNow,
    required this.photoUrls,
    required this.reviews,
    this.phoneNumber,
    this.website,
    this.priceLevel = 0,
    required this.types,
    this.latitude,
    this.longitude,
    this.businessStatus,
  });

  /// Create PlaceInfo from Google Places API result
  factory PlaceInfo.fromPlaceDetails(DetailsResult details) {
    return PlaceInfo(
      placeId: details.placeId ?? '',
      name: details.name ?? 'Unknown Place',
      rating: details.rating?.toDouble() ?? 0.0,
      address: details.formattedAddress ?? 'Address not available',
      isOpenNow: details.openingHours?.openNow ?? false,
      photoUrls:
          details.photos
              ?.map(
                (photo) =>
                    'https://maps.googleapis.com/maps/api/place/photo'
                    '?maxwidth=${GooglePlacesConfig.defaultPhotoMaxWidth}'
                    '&photo_reference=${photo.photoReference}'
                    '&key=${GooglePlacesConfig.apiKey}',
              )
              .toList() ??
          [],
      reviews:
          details.reviews
              ?.map((review) => PlaceReview.fromGoogleReview(review))
              .toList() ??
          [],
      phoneNumber: details.formattedPhoneNumber,
      website: details.website,
      priceLevel: details.priceLevel ?? 0,
      types: details.types ?? [],
      latitude: details.geometry?.location?.lat,
      longitude: details.geometry?.location?.lng,
      businessStatus: details.businessStatus,
    );
  }

  /// Create PlaceInfo from nearby search result
  factory PlaceInfo.fromNearbyResult(SearchResult result) {
    return PlaceInfo(
      placeId: result.placeId ?? '',
      name: result.name ?? 'Unknown Place',
      rating: result.rating?.toDouble() ?? 0.0,
      address: result.vicinity ?? 'Address not available',
      isOpenNow: result.openingHours?.openNow ?? false,
      photoUrls:
          result.photos
              ?.map(
                (photo) =>
                    'https://maps.googleapis.com/maps/api/place/photo'
                    '?maxwidth=${GooglePlacesConfig.defaultPhotoMaxWidth}'
                    '&photo_reference=${photo.photoReference}'
                    '&key=${GooglePlacesConfig.apiKey}',
              )
              .toList() ??
          [],
      reviews: [], // Reviews not available in nearby search
      priceLevel: result.priceLevel ?? 0,
      types: result.types ?? [],
      latitude: result.geometry?.location?.lat,
      longitude: result.geometry?.location?.lng,
      businessStatus: result.businessStatus,
    );
  }

  /// Get formatted rating string
  String get formattedRating {
    if (rating > 0) {
      return '${rating.toStringAsFixed(1)} ⭐';
    }
    return 'No rating';
  }

  /// Get price level description
  String get priceDescription {
    switch (priceLevel) {
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

  /// Get main photo URL
  String? get mainPhotoUrl {
    return photoUrls.isNotEmpty ? photoUrls.first : null;
  }

  /// Get business status description
  String get statusDescription {
    switch (businessStatus?.toLowerCase()) {
      case 'operational':
        return 'Open';
      case 'closed_temporarily':
        return 'Temporarily Closed';
      case 'closed_permanently':
        return 'Permanently Closed';
      default:
        return isOpenNow ? 'Open Now' : 'Closed';
    }
  }

  /// Get short address (first part)
  String get shortAddress {
    final parts = address.split(',');
    return parts.isNotEmpty ? parts.first.trim() : address;
  }

  /// Check if place has photos
  bool get hasPhotos => photoUrls.isNotEmpty;

  /// Check if place has reviews
  bool get hasReviews => reviews.isNotEmpty;

  /// Get average review rating
  double get averageReviewRating {
    if (reviews.isEmpty) return rating;

    final sum = reviews.fold<double>(0, (sum, review) => sum + review.rating);
    return sum / reviews.length;
  }

  /// Get total review count
  int get reviewCount => reviews.length;
}

/// Enhanced review model
class PlaceReview {
  final String author;
  final double rating;
  final String text;
  final String relativeTime;
  final String? authorPhotoUrl;
  final DateTime? timestamp;

  PlaceReview({
    required this.author,
    required this.rating,
    required this.text,
    required this.relativeTime,
    this.authorPhotoUrl,
    this.timestamp,
  });

  /// Create PlaceReview from Google Places API review
  factory PlaceReview.fromGoogleReview(Review review) {
    return PlaceReview(
      author: review.authorName ?? 'Anonymous',
      rating: review.rating?.toDouble() ?? 0.0,
      text: review.text ?? '',
      relativeTime: review.relativeTimeDescription ?? '',
      authorPhotoUrl: review.profilePhotoUrl,
      timestamp: review.time != null
          ? DateTime.fromMillisecondsSinceEpoch(review.time! * 1000)
          : null,
    );
  }

  /// Get formatted rating with stars
  String get formattedRating {
    return '${rating.toStringAsFixed(1)} ⭐';
  }

  /// Get star rating as string
  String get starRating {
    return '⭐' * rating.round();
  }

  /// Check if review has text
  bool get hasText => text.isNotEmpty;

  /// Get truncated text for preview
  String getTruncatedText(int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

/// Place search filters
class PlaceSearchFilter {
  final String? type;
  final int radius;
  final double? minRating;
  final bool? openNow;
  final int? maxPriceLevel;
  final String? keyword;

  PlaceSearchFilter({
    this.type,
    this.radius = 1500,
    this.minRating,
    this.openNow,
    this.maxPriceLevel,
    this.keyword,
  });

  /// Create filter for restaurants
  factory PlaceSearchFilter.restaurants({int radius = 1500}) {
    return PlaceSearchFilter(type: 'restaurant', radius: radius);
  }

  /// Create filter for stores
  factory PlaceSearchFilter.stores({int radius = 1500}) {
    return PlaceSearchFilter(type: 'store', radius: radius);
  }

  /// Create filter for gas stations
  factory PlaceSearchFilter.gasStations({int radius = 2000}) {
    return PlaceSearchFilter(type: 'gas_station', radius: radius);
  }

  /// Create filter for banks
  factory PlaceSearchFilter.banks({int radius = 1500}) {
    return PlaceSearchFilter(type: 'bank', radius: radius);
  }
}
