# Debug Guide: Google Places Not Showing Issue

## Problem
The map shows only salesman-created accounts (orange markers) but not Google Places shops (purple markers) when a pincode is selected.

## Backend Status ✅
- **API Working**: `GET /shops/pincode/500080` returns 143 total shops (1 existing + 142 Google Places)
- **Google Maps API Key**: Configured and working
- **Data Structure**: Correct JSON response with `googlePlacesShops.shops` array

## Debugging Added

### 1. Pincode Selection Debug
**Location**: `_onPincodeSelected()` method
**Look for**:
```
🎯 Pincode selected: 500080
📊 Current selected pincodes: []
➕ Added pincode: 500080
📊 Updated selected pincodes: [500080]
🔄 Loading all shops for selected pincodes...
```

### 2. API Call Debug
**Location**: `ShopService.getShopsByPincode()` method
**Look for**:
```
🔍 Fetching shops for pincode: 500080
📡 Full URL: http://localhost:5000/shops/pincode/500080?businessTypes=store,restaurant,supermarket...
📊 Response status: 200
📊 Response body: {"success":true,"pincode":"500080"...}
✅ Successfully fetched shops data
📊 Total shops: 143
📊 Existing accounts: 1
📊 Google Places: 142
```

### 3. Data Processing Debug
**Location**: `_loadGooglePlacesForPincode()` method
**Look for**:
```
🔎 Loading shops from backend API for pincode: 500080
✅ Loaded 142 Google Places shops from backend
✅ Processed 142 valid Google Places shops
```

### 4. Marker Creation Debug
**Location**: `_updateMapMarkersWithAllShops()` method
**Look for**:
```
🗺️ Updating map markers with all shops
📊 Google Places shops count: 142
📊 Salesman accounts count: 1
🟣 Processing 142 Google Places shops for markers
🔍 Processing Google Place: Puma at (17.4041735, 78.4812748)
📍 Coordinates: (17.4041735, 78.4812748), Valid: true
✅ Added Google Places marker for Puma
🟣 Added 142 Google Places markers out of 142
🗺️ Updated map with 144 markers
   - Current location: 1
   - Salesman accounts: 1
   - Google Places: 142
   - Nearby places: 0
```

## Testing Steps

### 1. Run the Flutter App
```bash
flutter run
```

### 2. Navigate to Admin Map
- Login as admin
- Go to Admin Map screen

### 3. Select Salesmen
- Click people icon
- Select at least one salesman
- Should see existing accounts on map

### 4. Select Pincode
- Click on a pincode (e.g., 500080)
- **Watch console output** for debug messages

### 5. Expected Results
- Loading indicator should appear
- Console should show all debug messages above
- Map should show purple markers for Google Places
- Pincode card should show "142 Google Places shops found"

## Potential Issues to Check

### Issue 1: API Call Failing
**Symptoms**: No API debug messages or error messages
**Check**: Network connectivity, backend server running

### Issue 2: Data Processing Failing
**Symptoms**: API succeeds but no Google Places data processed
**Check**: Response structure, data type issues

### Issue 3: Marker Creation Failing
**Symptoms**: Data processed but no markers added
**Check**: Coordinate validation, marker creation errors

### Issue 4: Map Not Updating
**Symptoms**: Markers created but not visible
**Check**: setState called, map controller ready

## Quick Fixes to Try

### Fix 1: Restart Backend
```bash
cd backend
npm start
```

### Fix 2: Clear Flutter Cache
```bash
flutter clean
flutter pub get
flutter run
```

### Fix 3: Check API Directly
Test in browser: `http://localhost:5000/shops/pincode/500080`

### Fix 4: Force Marker Update
Add this after marker creation:
```dart
Future.delayed(Duration(milliseconds: 500), () {
  if (mounted) setState(() {});
});
```

## Success Indicators

✅ **Console shows all debug messages**
✅ **API returns 142 Google Places shops**
✅ **142 markers created successfully**
✅ **Map displays purple markers**
✅ **Pincode card shows Google Places count**

## If Still Not Working

1. **Check coordinates**: Ensure lat/lng are valid numbers
2. **Check marker IDs**: Ensure no duplicate marker IDs
3. **Check map bounds**: Ensure markers are within visible area
4. **Check marker icons**: Ensure BitmapDescriptor.hueViolet works
5. **Check setState**: Ensure UI updates after marker creation

## Debug Commands

### Test API directly:
```bash
curl http://localhost:5000/shops/pincode/500080
```

### Check first Google Place:
```bash
curl http://localhost:5000/shops/pincode/500080 | jq '.googlePlacesShops.shops[0]'
```

### Count markers by type:
Look for these counts in console:
- Current location: 1
- Salesman accounts: 1
- Google Places: 142
- Total markers: 144