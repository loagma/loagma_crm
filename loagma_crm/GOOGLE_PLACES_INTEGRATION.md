# Google Places API Integration Guide

## Overview
This integration adds Google Places functionality to your Flutter app, allowing you to:
- Search nearby places (stores, restaurants, etc.)
- Fetch detailed place information
- Display place photos, reviews, and ratings
- Show places on Google Maps with markers

## Setup Instructions

### 1. Get Google Places API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the following APIs:
   - Places API
   - Maps JavaScript API
   - Geocoding API
4. Create credentials (API Key)
5. Restrict the API key to your app (optional but recommended)

### 2. Configure API Key
Update the API key in `lib/config/google_places_config.dart`:

```dart
class GooglePlacesConfig {
  static const String apiKey = 'YOUR_ACTUAL_API_KEY_HERE';
  // ... rest of the configuration
}
```

### 3. Dependencies
The following dependency is already added to `pubspec.yaml`:
```yaml
dependencies:
  google_place: ^0.10.0
```

## Usage

### 1. Initialize the Service
```dart
import 'package:your_app/services/google_places_service.dart';

// In your app initialization
GooglePlacesService.instance.initialize();
```

### 2. Search Nearby Places
```dart
final places = await GooglePlacesService.instance.fetchNearbyPlaces(
  lat: userLatitude,
  lng: userLongitude,
  radius: 1500, // meters
  type: "store", // or "restaurant", "gas_station", etc.
);
```

### 3. Get Place Details
```dart
final details = await GooglePlacesService.instance.fetchPlaceDetails(placeId);
if (details != null) {
  final placeInfo = PlaceInfo.fromPlaceDetails(details);
  // Use placeInfo for UI display
}
```

### 4. Generate Photo URLs
```dart
final photoUrl = GooglePlacesService.instance.getPhotoUrl(
  photoReference,
  maxWidth: 800,
);
```

## Integration Points

### Enhanced Punch Screen
The `EnhancedPunchScreen` demonstrates full integration:
- Shows current location on map
- Displays nearby places as markers
- Lists nearby places in a horizontal scroll
- Shows detailed place information in a bottom sheet

### Key Features
1. **Automatic Place Loading**: When location is available, nearby places are automatically loaded
2. **Interactive Map**: Places are shown as markers on Google Maps
3. **Place Details**: Tap on places to see photos, reviews, ratings, and contact info
4. **Real-time Updates**: Location and places refresh automatically

## File Structure

```
lib/
├── config/
│   └── google_places_config.dart          # API configuration
├── services/
│   └── google_places_service.dart         # Core Places API service
├── models/
│   └── place_model.dart                   # Place data models
├── widgets/
│   └── place_details_widget.dart          # UI components for places
└── screens/
    └── salesman/
        └── enhanced_punch_screen.dart     # Example integration
```

## API Functions

### GooglePlacesService Methods

#### `fetchNearbyPlaces(lat, lng, radius, type)`
- **Purpose**: Search for nearby places
- **Parameters**:
  - `lat`: Latitude
  - `lng`: Longitude  
  - `radius`: Search radius in meters (default: 1500)
  - `type`: Place type (default: "store")
- **Returns**: `List<NearbyPlaceResult>`

#### `fetchPlaceDetails(placeId)`
- **Purpose**: Get detailed information about a place
- **Parameters**:
  - `placeId`: Google Place ID
- **Returns**: `PlaceDetailsResult?`

#### `getPhotoUrl(photoReference, maxWidth)`
- **Purpose**: Generate photo URL from reference
- **Parameters**:
  - `photoReference`: Photo reference from place data
  - `maxWidth`: Maximum photo width (default: 800)
- **Returns**: `String` (full photo URL)

## Place Data Fields

### From Place Details:
- **name**: Business name
- **rating**: Average rating (0-5)
- **address**: Formatted address
- **opening_hours.open_now**: Currently open status
- **photos**: Array of photo references
- **reviews**: Array with author, rating, text
- **formatted_phone_number**: Contact number
- **website**: Business website
- **price_level**: Price range (0-4)

### Generated URLs:
- **Photo URLs**: `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=PHOTO_REF&key=API_KEY`

## Usage Examples

### Basic Integration
```dart
// Initialize service
GooglePlacesService.instance.initialize();

// Search nearby stores
final places = await GooglePlacesService.instance.fetchNearbyPlaces(
  lat: 19.0760,
  lng: 72.8777,
  type: "store",
);

// Get details for first place
if (places.isNotEmpty) {
  final details = await GooglePlacesService.instance.fetchPlaceDetails(
    places.first.placeId!
  );
  
  if (details != null) {
    print('Place: ${details.name}');
    print('Rating: ${details.rating}');
    print('Address: ${details.formattedAddress}');
    print('Open: ${details.openingHours?.openNow}');
    
    // Get photo URLs
    final photoUrls = GooglePlacesService.instance.getPhotoUrls(details);
    print('Photos: ${photoUrls.length}');
  }
}
```

### Map Integration
```dart
Set<Marker> _buildMapMarkers() {
  Set<Marker> markers = {};
  
  // Add place markers
  for (int i = 0; i < nearbyPlaces.length; i++) {
    final place = nearbyPlaces[i];
    if (place.latitude != null && place.longitude != null) {
      markers.add(
        Marker(
          markerId: MarkerId('place_$i'),
          position: LatLng(place.latitude!, place.longitude!),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: '${place.formattedRating} • ${place.isOpenNow ? "Open" : "Closed"}',
          ),
          onTap: () => _showPlaceDetails(place),
        ),
      );
    }
  }
  
  return markers;
}
```

## Error Handling

The service includes comprehensive error handling:
- API key validation
- Network error handling
- Invalid place ID handling
- Photo loading fallbacks

## Performance Considerations

1. **Caching**: Consider implementing local caching for place data
2. **Rate Limiting**: Be aware of Google Places API quotas
3. **Image Loading**: Use proper loading states for photos
4. **Location Updates**: Avoid excessive API calls on location changes

## Troubleshooting

### Common Issues:
1. **API Key Not Working**: Ensure the key is properly configured and APIs are enabled
2. **No Places Found**: Check location permissions and GPS accuracy
3. **Photos Not Loading**: Verify API key has proper permissions for Photos API
4. **Rate Limit Exceeded**: Implement proper caching and request throttling

### Debug Tips:
- Check console logs for detailed error messages
- Verify API key restrictions in Google Cloud Console
- Test with known coordinates first
- Use the Google Places API testing tools

## Next Steps

1. **Set up your API key** in the configuration file
2. **Test the integration** using the EnhancedPunchScreen
3. **Customize place types** based on your business needs
4. **Add caching** for better performance
5. **Implement analytics** to track place interactions

## Support

For issues with the Google Places API:
- [Google Places API Documentation](https://developers.google.com/maps/documentation/places/web-service)
- [Flutter google_place Package](https://pub.dev/packages/google_place)

For integration issues, check the console logs and ensure all dependencies are properly installed.