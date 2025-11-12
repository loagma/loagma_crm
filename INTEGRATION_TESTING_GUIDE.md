# 🚀 Complete Integration Testing Guide

## Quick Setup & Test (5 Minutes)

### Step 1: Start Backend Server

```bash
cd backend
npm run dev
```

Server should be running at `http://localhost:5000`

### Step 2: Verify Backend is Working

Open browser or use curl:
```bash
curl http://localhost:5000
```

Expected: `Loagma CRM Backend running well!!`

### Step 3: Test Location API

```bash
curl http://localhost:5000/locations/countries
```

Expected: JSON with countries data

### Step 4: Configure Flutter App

Open `loagma_crm/lib/services/api_config.dart` and update baseUrl:

```dart
// For Android Emulator
static const String baseUrl = 'http://10.0.2.2:5000';

// For iOS Simulator
static const String baseUrl = 'http://localhost:5000';

// For Physical Device (replace with your computer's IP)
static const String baseUrl = 'http://192.168.1.100:5000';
```

### Step 5: Update Main App to Use New Dashboard

Open `loagma_crm/lib/main.dart` and update:

```dart
import 'package:flutter/material.dart';
import 'screens/dashboard_screen_new.dart';  // Add this

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loagma CRM',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        useMaterial3: true,
      ),
      home: const DashboardScreenNew(),  // Change this
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### Step 6: Run Flutter App

```bash
cd loagma_crm
flutter pub get
flutter run
```

---

## 📋 Complete Testing Checklist

### Backend Testing

- [ ] **Server Running**: `curl http://localhost:5000`
- [ ] **Get Countries**: `curl http://localhost:5000/locations/countries`
- [ ] **Get States**: `curl "http://localhost:5000/locations/states?countryId=COUNTRY_ID"`
- [ ] **Get Districts**: `curl "http://localhost:5000/locations/districts?stateId=STATE_ID"`
- [ ] **Get Cities**: `curl "http://localhost:5000/locations/cities?districtId=DISTRICT_ID"`
- [ ] **Get Zones**: `curl "http://localhost:5000/locations/zones?cityId=CITY_ID"`
- [ ] **Get Areas**: `curl "http://localhost:5000/locations/areas?zoneId=ZONE_ID"`
- [ ] **Create Account**: 
```bash
curl -X POST http://localhost:5000/accounts \
  -H "Content-Type: application/json" \
  -d '{"personName":"Test User","contactNumber":"9876543210"}'
```
- [ ] **Get Accounts**: `curl http://localhost:5000/accounts`

### Flutter App Testing

#### 1. Location Dropdown Testing
- [ ] Open app, see welcome screen
- [ ] Open drawer, select "Country" from Master menu
- [ ] Country dropdown loads with data
- [ ] Select a country
- [ ] Click "Next: Account Master Details"
- [ ] Account form appears

#### 2. Cascading Dropdowns Testing
- [ ] Open drawer, select "Area" from Master menu
- [ ] Select Country → States load
- [ ] Select State → Districts load
- [ ] Select District → Cities load
- [ ] Select City → Zones load
- [ ] Select Zone → Areas load
- [ ] Select Area
- [ ] Click "Next: Account Master Details"

#### 3. Account Creation Testing
- [ ] Fill Person Name (required)
- [ ] Fill Contact Number (required, 10 digits)
- [ ] Select Date of Birth (optional)
- [ ] Fill Business Type (optional)
- [ ] Select Customer Stage (optional)
- [ ] Select Funnel Stage (optional)
- [ ] Click Submit
- [ ] Success message appears with account code
- [ ] Form resets

#### 4. Error Handling Testing
- [ ] Try submitting empty form → Validation errors appear
- [ ] Try invalid contact number → Error message
- [ ] Stop backend server → Network error message
- [ ] Restart backend → App recovers

---

## 🔧 Troubleshooting

### Issue: "Failed to load countries"

**Solution 1**: Check backend is running
```bash
curl http://localhost:5000
```

**Solution 2**: Check API URL in `api_config.dart`
- Android Emulator: `http://10.0.2.2:5000`
- iOS Simulator: `http://localhost:5000`
- Physical Device: `http://YOUR_IP:5000`

**Solution 3**: Check firewall/network
```bash
# Windows: Allow port 5000
netsh advfirewall firewall add rule name="Node5000" dir=in action=allow protocol=TCP localport=5000
```

### Issue: "Connection refused"

**Solution**: Make sure backend is running and accessible
```bash
# Test from terminal
curl http://localhost:5000/locations/countries

# If this works but app doesn't, check API URL configuration
```

### Issue: "No data in dropdowns"

**Solution**: Seed the database
```bash
cd backend
npm run seed:locations
```

### Issue: "Account creation fails"

**Solution 1**: Check required fields (personName, contactNumber)

**Solution 2**: Check contact number is unique
```bash
# View existing accounts
curl http://localhost:5000/accounts
```

**Solution 3**: Check backend logs for errors

---

## 📱 Testing on Different Platforms

### Android Emulator
1. Update `api_config.dart`:
```dart
static const String baseUrl = 'http://10.0.2.2:5000';
```
2. Run: `flutter run`

### iOS Simulator
1. Update `api_config.dart`:
```dart
static const String baseUrl = 'http://localhost:5000';
```
2. Run: `flutter run`

### Physical Device
1. Find your computer's IP:
```bash
# Windows
ipconfig

# Mac/Linux
ifconfig
```

2. Update `api_config.dart`:
```dart
static const String baseUrl = 'http://192.168.1.100:5000';  // Your IP
```

3. Make sure device and computer are on same network

4. Run: `flutter run`

---

## 🎯 Quick Test Scenarios

### Scenario 1: Create Account with Full Location
1. Open app
2. Select "Area" from Master menu
3. Select: India → Gujarat → Ahmedabad → Ahmedabad City → West Zone → Vastrapur
4. Click Next
5. Fill: Name="Rajesh Kumar", Contact="9876543210"
6. Select: Customer Stage="Lead", Funnel Stage="Awareness"
7. Click Submit
8. ✅ Success message with account code (e.g., ACC2411001)

### Scenario 2: Create Account with Minimal Data
1. Open app
2. Select "Country" from Master menu
3. Select: India
4. Click Next
5. Fill: Name="Priya Shah", Contact="9876543211"
6. Click Submit
7. ✅ Success message

### Scenario 3: Test Validation
1. Open app
2. Select "Country" from Master menu
3. Select: India
4. Click Next
5. Leave Name empty
6. Click Submit
7. ✅ Validation error appears

### Scenario 4: Test Cascading Dropdowns
1. Open app
2. Select "Area" from Master menu
3. Select Country: India
4. ✅ States dropdown enables and loads
5. Select State: Gujarat
6. ✅ Districts dropdown enables and loads
7. Continue through all levels
8. ✅ Each level loads correctly

---

## 📊 Expected Data After Seeding

### Countries
- India

### States (India)
- Gujarat
- Maharashtra

### Districts
- Ahmedabad (Gujarat)
- Surat (Gujarat)
- Mumbai (Maharashtra)
- Pune (Maharashtra)

### Cities
- Ahmedabad City
- Surat City
- Mumbai City
- Pune City

### Zones
- West Zone (Ahmedabad)
- East Zone (Ahmedabad)
- West Zone (Surat)
- South Mumbai
- Central Mumbai

### Areas (17 total)
- Vastrapur, Bodakdev, Satellite, Navrangpura (Ahmedabad West)
- Maninagar, Nikol, Vastral (Ahmedabad East)
- Adajan, Vesu, Pal (Surat West)
- Colaba, Nariman Point, Churchgate (Mumbai South)
- Dadar, Parel, Byculla (Mumbai Central)

---

## 🎬 Video Testing Flow

### 1. Backend Setup (30 seconds)
```bash
cd backend
npm run dev
# Wait for "Server running on port http://localhost:5000"
```

### 2. Verify Backend (10 seconds)
```bash
curl http://localhost:5000/locations/countries
# Should see JSON with India
```

### 3. Start Flutter App (20 seconds)
```bash
cd loagma_crm
flutter run
# Wait for app to launch
```

### 4. Test Complete Flow (2 minutes)
1. Open drawer → Select "Area"
2. Select all dropdowns: India → Gujarat → Ahmedabad → Ahmedabad City → West Zone → Vastrapur
3. Click "Next"
4. Fill form: Name="Test User", Contact="9999999999"
5. Click "Submit"
6. See success message with account code

**Total Time: ~3 minutes from start to working app!**

---

## 🔍 Debugging Tips

### Enable Verbose Logging

In Flutter app, check console for:
```
Error fetching countries: ...
Error creating account: ...
```

In Backend, check terminal for:
```
POST /accounts 201
GET /locations/countries 200
```

### Test API Directly

Use Postman or curl to test each endpoint independently:
```bash
# Test countries
curl http://localhost:5000/locations/countries

# Test account creation
curl -X POST http://localhost:5000/accounts \
  -H "Content-Type: application/json" \
  -d '{"personName":"Test","contactNumber":"9999999999"}'
```

### Check Network Inspector

In Flutter DevTools:
1. Open DevTools
2. Go to Network tab
3. Watch API calls
4. Check request/response

---

## ✅ Success Criteria

Your integration is working correctly if:

1. ✅ Backend server starts without errors
2. ✅ Countries API returns data
3. ✅ Flutter app launches without errors
4. ✅ Country dropdown loads with "India"
5. ✅ Selecting country loads states
6. ✅ Cascading works through all 6 levels
7. ✅ Account form appears after location selection
8. ✅ Account creation succeeds
9. ✅ Success message shows account code
10. ✅ Form resets after submission

---

## 🚀 Next Steps After Testing

Once everything works:

1. **Add More Features**
   - View accounts list
   - Edit accounts
   - Delete accounts
   - Search and filter

2. **Improve UI**
   - Add loading indicators
   - Better error messages
   - Form validation feedback

3. **Add Authentication**
   - Login screen
   - JWT tokens
   - Protected routes

4. **Deploy**
   - Backend to cloud (Heroku, AWS, etc.)
   - Update API URLs
   - Test on production

---

## 📞 Quick Reference

**Backend URL**: `http://localhost:5000`
**API Docs**: `backend/API_DOCUMENTATION.md`
**Flutter Docs**: `backend/FLUTTER_INTEGRATION_GUIDE.md`

**Key Files**:
- Backend: `backend/src/controllers/locationController.js`
- Backend: `backend/src/controllers/accountController.js`
- Flutter: `loagma_crm/lib/screens/dashboard_screen_new.dart`
- Flutter: `loagma_crm/lib/services/location_service.dart`
- Flutter: `loagma_crm/lib/services/account_service.dart`

---

**Status**: ✅ Ready to Test!

Everything is set up and ready. Follow the steps above to test the complete integration.
