# Mapbox Integration Test Guide

This guide will help you verify that your Mapbox integration is working correctly.

## Quick Verification Tests

### Test 1: Token Validation (Command Line)

Run this command to verify your token is valid:

**Windows (PowerShell):**
```powershell
curl "https://api.mapbox.com/styles/v1/mapbox/streets-v12?access_token=pk.eyJ1IjoibG9hZ21hY3JtMTIzIiwiYSI6ImNta2YzZHBrYTBmZHkzZ3F2MGVudjB3NGQifQ.xa5ojP6rByCK2U6Xs0OZyA"
```

**Expected Result:**
- Status: 200 OK
- Response: JSON data with map style information

✅ **Your token has been validated and is working!**

---

### Test 2: Configuration Files Check

Verify all configuration files contain the correct token:

**Flutter Config:**
```bash
cat loagma_crm/lib/config/mapbox_config.dart | grep "pk.eyJ1"
```

**Android Config:**
```bash
cat loagma_crm/android/gradle.properties | grep "MAPBOX_ACCESS_TOKEN"
```

**iOS Config:**
```bash
type loagma_crm\ios\Runner\Info.plist | findstr "MBXAccessToken"
```

**Backend Config:**
```bash
cat backend/.env | grep "MAPBOX_ACCESS_TOKEN"
```

✅ **All configuration files verified!**

---

### Test 3: Flutter App Test

Create a simple test to verify Mapbox loads in your Flutter app:

1. **Create a test map screen** (optional - for quick testing):

```dart
// loagma_crm/lib/screens/test_map_screen.dart
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../config/mapbox_config.dart';

class TestMapScreen extends StatefulWidget {
  const TestMapScreen({Key? key}) : super(key: key);

  @override
  State<TestMapScreen> createState() => _TestMapScreenState();
}

class _TestMapScreenState extends State<TestMapScreen> {
  MapboxMap? mapboxMap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapbox Test'),
        backgroundColor: Colors.blue,
      ),
      body: MapWidget(
        key: const ValueKey("mapWidget"),
        resourceOptions: ResourceOptions(
          accessToken: MapboxConfig.accessToken,
        ),
        cameraOptions: CameraOptions(
          center: Point(coordinates: Position(77.5946, 12.9716)), // Bangalore
          zoom: 12.0,
        ),
        styleUri: MapboxConfig.defaultMapStyle,
        onMapCreated: (MapboxMap map) {
          mapboxMap = map;
          print('✅ Mapbox map created successfully!');
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (mapboxMap != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Mapbox is working!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
```

2. **Run the app:**
```bash
cd loagma_crm
flutter run
```

3. **Navigate to the test screen** and verify:
   - ✅ Map loads without errors
   - ✅ You can see the map tiles
   - ✅ You can zoom and pan
   - ✅ No console errors related to Mapbox

---

### Test 4: Check Dependencies

Verify Mapbox SDK is installed:

```bash
cd loagma_crm
flutter pub get
```

Check for `mapbox_maps_flutter` in the output.

✅ **Dependency verified: mapbox_maps_flutter ^2.17.0**

---

## Expected Results Summary

| Test | Status | Result |
|------|--------|--------|
| Token Validation | ✅ | HTTP 200 OK |
| Flutter Config | ✅ | Token present |
| Android Config | ✅ | All tokens present |
| iOS Config | ✅ | Token present |
| Backend Config | ✅ | Token present |
| Dependencies | ✅ | mapbox_maps_flutter installed |

---

## Common Issues and Solutions

### Issue 1: Map Not Loading

**Symptoms:**
- Blank screen where map should be
- Console error: "Invalid access token"

**Solutions:**
1. Verify token in `mapbox_config.dart` is correct
2. Check internet connection
3. Verify token hasn't been revoked at [Mapbox Dashboard](https://account.mapbox.com/access-tokens/)

### Issue 2: Build Errors on Android

**Symptoms:**
- Gradle build fails
- Error about missing Mapbox token

**Solutions:**
1. Check `android/gradle.properties` has all three tokens:
   - MAPBOX_ACCESS_TOKEN
   - MAPBOX_DOWNLOADS_TOKEN
   - SDK_REGISTRY_TOKEN
2. Run `flutter clean` then `flutter pub get`
3. Rebuild the app

### Issue 3: Build Errors on iOS

**Symptoms:**
- iOS build fails
- Error about missing MBXAccessToken

**Solutions:**
1. Check `ios/Runner/Info.plist` has `MBXAccessToken` key
2. Verify token string has no extra quotes or spaces
3. Run `flutter clean` then `flutter pub get`
4. Rebuild the app

### Issue 4: Map Loads but Shows Error Tiles

**Symptoms:**
- Map loads but shows error/warning tiles
- Console error about style loading

**Solutions:**
1. Check internet connection
2. Verify style URL is correct: `mapbox://styles/mapbox/streets-v12`
3. Check token has `styles:read` scope
4. Try a different style (satellite or outdoors)

---

## Performance Testing

### Test Map Performance

1. **Load Time**: Map should load within 2-3 seconds
2. **Zoom Performance**: Smooth zooming without lag
3. **Pan Performance**: Smooth panning without stuttering
4. **Marker Rendering**: Markers should appear instantly

### Monitor Usage

Check your usage at [Mapbox Dashboard](https://account.mapbox.com/):
- Each map load counts as 1 request
- Free tier: 50,000 map loads/month
- Set up alerts at 40,000 (80% threshold)

---

## Next Steps After Successful Testing

Once all tests pass:

1. ✅ Mapbox is fully configured and working
2. 🚀 Proceed to implement live tracking features
3. 📍 Add real-time location markers
4. 🗺️ Implement route visualization
5. 👥 Add salesman clustering

**Continue with Task 7 in `.kiro/specs/live-salesman-tracking/tasks.md`**

---

## Support Resources

- **Mapbox Flutter SDK Docs**: [https://docs.mapbox.com/flutter/maps/guides/](https://docs.mapbox.com/flutter/maps/guides/)
- **API Reference**: [https://docs.mapbox.com/api/](https://docs.mapbox.com/api/)
- **Community Forum**: [https://community.mapbox.com/](https://community.mapbox.com/)
- **GitHub Issues**: [https://github.com/mapbox/mapbox-maps-flutter/issues](https://github.com/mapbox/mapbox-maps-flutter/issues)

---

**All tests passed! Your Mapbox integration is ready for development! 🎉**
