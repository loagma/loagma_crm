# Test Guide: Enhanced Map Functionality

## Testing the Enhanced Map Feature

### Prerequisites
1. ✅ Backend server running with Google Maps API key configured
2. ✅ Flutter app connected to backend
3. ✅ At least one salesman with accounts in the system
4. ✅ Valid pincode data in the database

### Test Steps

#### 1. Basic Map Loading
1. Open Admin Map screen
2. **Expected**: Map loads with current location (blue marker)
3. **Expected**: Legend shows: My Location, Approved Shops, Pending Shops, Google Places, Nearby Places

#### 2. Salesman Selection
1. Click the people icon in app bar
2. Select one or more salesmen
3. **Expected**: Map shows existing accounts as green/orange markers
4. **Expected**: Pincode card populates with available pincodes

#### 3. Pincode Selection (Main Feature)
1. Click on a pincode in the pincode card
2. **Expected**: Loading indicator appears
3. **Expected**: Map shows both:
   - Existing salesman accounts (green/orange markers)
   - Google Places shops (purple markers)
4. **Expected**: Pincode card shows "X Google Places shops found"

#### 4. Google Places Interaction
1. Click on a purple marker (Google Places shop)
2. **Expected**: Modal shows shop details with rating
3. Click "Focus on Map" button
4. **Expected**: Map centers on the shop
5. Click "Add as Account" button
6. **Expected**: Confirmation dialog appears
7. Confirm account creation
8. **Expected**: Success message and map refreshes

#### 5. Multi-Pincode Selection
1. Select multiple pincodes
2. **Expected**: Map shows shops from all selected pincodes
3. **Expected**: Different colored markers for different shop types

#### 6. Error Handling
1. Select a pincode with no Google Places data
2. **Expected**: No error, just shows existing accounts
3. Test with invalid pincode
4. **Expected**: Graceful error handling

### Expected Marker Colors

| Color | Type | Description |
|-------|------|-------------|
| 🔵 Blue | Current Location | Your GPS position |
| 🟢 Green | Approved Shops | Existing approved accounts |
| 🟠 Orange | Pending Shops | Existing pending accounts |
| 🟣 Purple | Google Places | Potential shops from Google |
| 🔴 Red | Nearby Places | General nearby locations |

### API Endpoints to Test

#### 1. Get Shops by Pincode
```bash
GET /shops/pincode/500001?businessTypes=store,restaurant,cafe
```

**Expected Response:**
```json
{
  "success": true,
  "pincode": "500001",
  "totalShops": 25,
  "existingAccounts": {
    "count": 5,
    "shops": [...]
  },
  "googlePlacesShops": {
    "count": 20,
    "shops": [...]
  }
}
```

#### 2. Create Account from Google Place
```bash
POST /shops/google-place/ChIJXYZ123/create-account
{
  "customerStage": "Lead",
  "funnelStage": "Awareness",
  "notes": "Created from Google Places"
}
```

### Troubleshooting

#### No Google Places Showing
1. Check backend logs for API key errors
2. Verify Google Places API is enabled
3. Check API quota limits

#### Map Not Updating
1. Check browser console for JavaScript errors
2. Verify network requests are successful
3. Check if markers are being created but not visible

#### Performance Issues
1. Limit number of selected pincodes
2. Check if too many markers are being rendered
3. Monitor API rate limits

### Success Criteria

✅ **Basic Functionality**
- Map loads without errors
- Salesman selection works
- Pincode selection triggers Google Places search

✅ **Enhanced Features**
- Purple markers appear for Google Places
- Shop details modal works
- Account creation from Google Places works

✅ **User Experience**
- Loading indicators show during API calls
- Error messages are user-friendly
- Map performance is smooth with multiple markers

✅ **Data Integrity**
- No duplicate shops between existing and Google Places
- Account creation generates valid account codes
- All required fields are populated

### Performance Benchmarks

- **Map Load Time**: < 3 seconds
- **Pincode Selection**: < 5 seconds for Google Places data
- **Marker Rendering**: < 2 seconds for 50+ markers
- **Account Creation**: < 3 seconds

### Known Limitations

1. **API Rate Limits**: Google Places API has daily quotas
2. **Geocoding Dependency**: Some pincodes may not geocode properly
3. **Business Type Coverage**: Limited to predefined business types
4. **Offline Mode**: No offline caching of Google Places data

### Future Enhancements

1. **Caching**: Store Google Places results locally
2. **Filtering**: Filter Google Places by rating, distance
3. **Bulk Operations**: Convert multiple Google Places at once
4. **Analytics**: Track conversion rates from Google Places
5. **Custom Business Types**: Allow admin to configure search types