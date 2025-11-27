# Employee Management System Updates

## Changes Completed

### Backend Changes
1. ✅ **Numeric User IDs**: Changed from UUID to EMP000001 format
   - File: `backend/src/controllers/adminController.js`
   - File: `backend/src/controllers/userController.js`
   - Added `generateNumericUserId()` function

2. ✅ **Database Schema Updates**
   - File: `backend/prisma/schema.prisma`
   - Added to User model:
     - `area String?`
     - `latitude Float?`
     - `longitude Float?`
   - Migration applied with `npx prisma db push`

3. ✅ **API Updates**
   - Updated `createUserByAdmin` to accept area, latitude, longitude
   - Updated `updateUserByAdmin` to accept area, latitude, longitude

### Frontend - Create User Screen
1. ✅ **Multi-Select Languages**: Changed from single dropdown to multi-select
2. ✅ **Area Selection**: Added dropdown after pincode lookup (like account master)
3. ✅ **Geolocation**: Added current location capture with Google Maps display
4. ✅ **Dependencies**: Added geolocator, google_maps_flutter, url_launcher

## Required Manual Updates

### Edit User Screen (`loagma_crm/lib/screens/admin/edit_user_screen.dart`)

**Step 1: Update imports** (add at top):
```dart
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
```

**Step 2: Update state variables** (around line 40):
```dart
// Change from:
String? selectedLanguage;

// To:
List<String> selectedLanguages = [];
String? selectedArea;
double? _latitude;
double? _longitude;
bool isLoadingGeolocation = false;
bool isLoadingAreas = false;
List<Map<String, dynamic>> _availableAreas = [];
```

**Step 3: Update initState** (around line 105):
```dart
// Change from:
if (widget.user['preferredLanguages'] != null &&
    widget.user['preferredLanguages'] is List &&
    (widget.user['preferredLanguages'] as List).isNotEmpty) {
  selectedLanguage = widget.user['preferredLanguages'][0];
}

// To:
if (widget.user['preferredLanguages'] != null &&
    widget.user['preferredLanguages'] is List) {
  selectedLanguages = List<String>.from(widget.user['preferredLanguages']);
}

// Initialize area and geolocation
selectedArea = widget.user['area'];
_latitude = widget.user['latitude'] != null ? widget.user['latitude'].toDouble() : null;
_longitude = widget.user['longitude'] != null ? widget.user['longitude'].toDouble() : null;
```

**Step 4: Add geolocation functions** (after pickImage function):
```dart
Future<void> _getCurrentLocation() async {
  setState(() => isLoadingGeolocation = true);
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: 'Location services are disabled');
      setState(() => isLoadingGeolocation = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: 'Location permission denied');
        setState(() => isLoadingGeolocation = false);
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });

    Fluttertoast.showToast(
      msg: 'Location captured: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
    );
  } catch (e) {
    Fluttertoast.showToast(msg: 'Failed to get location: $e');
  } finally {
    if (mounted) {
      setState(() => isLoadingGeolocation = false);
    }
  }
}

Future<void> _openInGoogleMaps() async {
  if (_latitude == null || _longitude == null) return;
  final url = 'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude';
  final uri = Uri.parse(url);
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    Fluttertoast.showToast(msg: 'Error opening Google Maps: $e');
  }
}
```

**Step 5: Update updateUser function** (around line 305):
```dart
// Change from:
if (selectedLanguage != null) "preferredLanguages": [selectedLanguage],

// To:
if (selectedLanguages.isNotEmpty) "preferredLanguages": selectedLanguages,

// Add after district:
if (selectedArea != null) "area": selectedArea,
if (_latitude != null) "latitude": _latitude,
if (_longitude != null) "longitude": _longitude,
```

**Step 6: Update UI - Replace language dropdown** (around line 503):
```dart
// Replace the DropdownButtonFormField for language with:
ListTile(
  shape: RoundedRectangleBorder(
    side: const BorderSide(color: Colors.grey),
    borderRadius: BorderRadius.circular(12),
  ),
  title: const Text("Preferred Languages"),
  subtitle: Text(
    selectedLanguages.isEmpty
        ? "Tap to select"
        : selectedLanguages.join(", "),
  ),
  leading: const Icon(Icons.language),
  trailing: const Icon(Icons.arrow_drop_down),
  onTap: () {
    // Use the same showMultiSelectDialog from create_user_screen
  },
),
```

### User Detail Screen (`loagma_crm/lib/screens/admin/user_detail_screen.dart`)

**Update the Personal Information section** (around line 150):
```dart
// Change language display from:
if (widget.user['preferredLanguages'] != null &&
    (widget.user['preferredLanguages'] as List).isNotEmpty)
  _buildInfoRow(
    Icons.language,
    "Preferred Language",
    (widget.user['preferredLanguages'] as List).join(', '),
  ),

// To:
if (widget.user['preferredLanguages'] != null &&
    (widget.user['preferredLanguages'] as List).isNotEmpty)
  _buildInfoRow(
    Icons.language,
    "Preferred Languages",
    (widget.user['preferredLanguages'] as List).join(', '),
  ),
```

**Add after Address Information section** (around line 220):
```dart
// GEOLOCATION INFORMATION
if (widget.user['latitude'] != null && widget.user['longitude'] != null) ...[
  _buildSectionTitle("Geolocation"),
  _buildInfoCard([
    _buildInfoRow(
      Icons.location_on,
      "Coordinates",
      "Lat: ${widget.user['latitude'].toStringAsFixed(6)}, Lng: ${widget.user['longitude'].toStringAsFixed(6)}",
    ),
    const SizedBox(height: 12),
    Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7BE69), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              widget.user['latitude'].toDouble(),
              widget.user['longitude'].toDouble(),
            ),
            zoom: 15,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('employee_location'),
              position: LatLng(
                widget.user['latitude'].toDouble(),
                widget.user['longitude'].toDouble(),
              ),
            ),
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
        ),
      ),
    ),
  ]),
  const SizedBox(height: 20),
],
```

**Add area to Address Information** (around line 200):
```dart
if (widget.user['area'] != null)
  _buildInfoRow(Icons.place, "Area", widget.user['area']),
```

## Dependencies to Add

Add to `loagma_crm/pubspec.yaml`:
```yaml
dependencies:
  geolocator: ^10.1.0
  google_maps_flutter: ^2.5.0
  url_launcher: ^6.2.2
```

Then run:
```bash
cd loagma_crm
flutter pub get
```

## Testing Checklist

- [ ] Create new employee with multiple languages
- [ ] Create employee with pincode lookup and area selection
- [ ] Capture geolocation and verify map display
- [ ] Edit employee and update languages, area, location
- [ ] View employee details and verify all fields display correctly
- [ ] Verify new employee IDs are in EMP000001 format
- [ ] Test on both Android and iOS (if applicable)

## Notes

- User IDs are now sequential: EMP000001, EMP000002, etc.
- Geolocation requires location permissions on device
- Google Maps requires API key configuration
- Area dropdown only appears after successful pincode lookup
- All location fields are optional
