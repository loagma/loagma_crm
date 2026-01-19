# Mapbox Quick Reference Card

## 🔑 Your Credentials

```
Account: loagmacrm123
Token: pk.eyJ1IjoibG9hZ21hY3JtMTIzIiwiYSI6ImNta2YzZHBrYTBmZHkzZ3F2MGVudjB3NGQifQ.xa5ojP6rByCK2U6Xs0OZyA
Dashboard: https://account.mapbox.com/
```

## 📁 Configuration Files

| Platform | File Path | Status |
|----------|-----------|--------|
| Flutter | `loagma_crm/lib/config/mapbox_config.dart` | ✅ |
| Android | `loagma_crm/android/gradle.properties` | ✅ |
| iOS | `loagma_crm/ios/Runner/Info.plist` | ✅ |
| Backend | `backend/.env` | ✅ |

## 🗺️ Map Styles

```dart
// Default (configured)
MapboxConfig.defaultMapStyle
// "mapbox://styles/mapbox/streets-v12"

// Alternatives (available)
MapboxConfig.satelliteMapStyle
// "mapbox://styles/mapbox/satellite-v9"

MapboxConfig.outdoorsMapStyle
// "mapbox://styles/mapbox/outdoors-v12"
```

## 🚀 Quick Commands

### Test Token
```bash
curl "https://api.mapbox.com/styles/v1/mapbox/streets-v12?access_token=pk.eyJ1IjoibG9hZ21hY3JtMTIzIiwiYSI6ImNta2YzZHBrYTBmZHkzZ3F2MGVudjB3NGQifQ.xa5ojP6rByCK2U6Xs0OZyA"
```

### Run Flutter App
```bash
cd loagma_crm
flutter clean
flutter pub get
flutter run
```

### Check Configuration
```bash
# Flutter
cat loagma_crm/lib/config/mapbox_config.dart | grep "accessToken"

# Android
cat loagma_crm/android/gradle.properties | grep "MAPBOX"

# Backend
cat backend/.env | grep "MAPBOX"
```

## 📊 Usage Limits

| Resource | Free Tier Limit |
|----------|----------------|
| Map Loads | 50,000/month |
| Geocoding | 100,000/month |
| Rate Limit | No limit on requests/second |

⚠️ **Set up alerts at 40,000 map loads (80% threshold)**

## 🔧 Basic Map Implementation

```dart
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../config/mapbox_config.dart';

MapWidget(
  resourceOptions: ResourceOptions(
    accessToken: MapboxConfig.accessToken,
  ),
  cameraOptions: CameraOptions(
    center: Point(coordinates: Position(lng, lat)),
    zoom: MapboxConfig.defaultZoom,
  ),
  styleUri: MapboxConfig.defaultMapStyle,
  onMapCreated: (MapboxMap map) {
    // Map ready to use
  },
)
```

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Map not loading | Check internet, verify token |
| Build error (Android) | Check gradle.properties has all 3 tokens |
| Build error (iOS) | Check Info.plist has MBXAccessToken |
| Error tiles | Check style URL, verify token scopes |

## 📞 Support Links

- **Dashboard**: [https://account.mapbox.com/](https://account.mapbox.com/)
- **Docs**: [https://docs.mapbox.com/flutter/maps/guides/](https://docs.mapbox.com/flutter/maps/guides/)
- **Forum**: [https://community.mapbox.com/](https://community.mapbox.com/)

## ✅ Setup Status

```
✅ Account created
✅ Token generated and validated
✅ All platforms configured
✅ Dependencies installed
✅ Ready for development
⚠️ Set up usage alerts (recommended)
```

## 🎯 Next Steps

1. Set up usage alerts at [Dashboard](https://account.mapbox.com/)
2. Test map loading in Flutter app
3. Continue with Task 7 in `.kiro/specs/live-salesman-tracking/tasks.md`
4. Implement live tracking features

---

**Quick Reference v1.0 - Last Updated: January 15, 2026**
