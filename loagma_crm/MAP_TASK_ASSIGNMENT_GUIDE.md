# 🗺️ Map-Based Pin-Code Task Assignment - Complete Guide

## ✨ Features Implemented

### 1. **Pin-Code Based Task Assignment**
- Assign tasks to salesmen based on pin-code areas
- One salesman can handle multiple areas
- Automatic location detection from pin code

### 2. **Google Maps API Integration**
- Auto-fetch shops using Google Places API
- Search by business types: Grocery, Cafe, Hotel, Dairy, Restaurant, Bakery, Pharmacy, Supermarket, Others
- Real-time business discovery

### 3. **Map Visualization with Stage Colors**
- **Yellow Markers** → New shops
- **Blue Markers** → Follow-up required
- **Green Markers** → Converted customers
- **Red Markers** → Lost opportunities
- Interactive markers with shop details

### 4. **List & Map Views**
- Toggle between list and map views
- Marker clustering for high-density areas
- Interactive shop information windows

### 5. **Shop Stage Management**
- Update shop stages: New → Follow-up → Converted/Lost
- Track last contact date
- Add notes for each shop

---

## 📱 User Flow

### Tab 1: Assign Areas

1. **Select Salesman**
   - Choose from dropdown list of active salesmen
   - Shows name and employee code

2. **Enter Pin Code**
   - Type 6-digit pin code
   - Click "Fetch" to get location details
   - Auto-populates: Country, State, District, City, Areas

3. **Select Areas**
   - Multiple area selection using chips
   - Visual feedback for selected areas

4. **Select Business Types**
   - Choose from 9 business categories
   - Multiple selection allowed
   - Icons for easy identification

5. **Fetch Businesses**
   - Click "Fetch Businesses" button
   - Uses Google Places API to find shops
   - Shows total count and breakdown by type

6. **Assign to Salesman**
   - Click "Assign Areas to Salesman"
   - Saves assignment to database
   - Shops automatically assigned to salesman

### Tab 2: Map View

1. **Interactive Map**
   - Google Maps with color-coded markers
   - Zoom and pan controls
   - My location button

2. **Color Legend**
   - Yellow = New
   - Blue = Follow-up
   - Green = Converted
   - Red = Lost

3. **Shop Details**
   - Tap marker to see shop info
   - Update stage directly from map
   - View rating and address

### Tab 3: Assignments

1. **View All Assignments**
   - Expandable cards for each assignment
   - Shows pin code, areas, business types
   - Total businesses count

---

## 🔧 Backend API Endpoints

### Base URL
```
https://your-backend.com/task-assignments
```

### 1. Get All Salesmen
```
GET /salesmen
Response: {
  success: true,
  salesmen: [...]
}
```

### 2. Get Location by Pin Code
```
GET /location/pincode/:pincode
Response: {
  success: true,
  location: {
    pincode: "400001",
    country: "India",
    state: "Maharashtra",
    district: "Mumbai",
    city: "Mumbai",
    areas: ["Andheri", "Bandra", ...]
  }
}
```

### 3. Assign Areas
```
POST /assignments/areas
Body: {
  salesmanId: "...",
  salesmanName: "...",
  pincode: "400001",
  country: "India",
  state: "Maharashtra",
  district: "Mumbai",
  city: "Mumbai",
  areas: ["Andheri", "Bandra"],
  businessTypes: ["grocery", "cafe"]
}
```

### 4. Search Businesses (Google Places)
```
POST /businesses/search
Body: {
  pincode: "400001",
  areas: ["Andheri"],
  businessTypes: ["grocery", "cafe"]
}
Response: {
  success: true,
  totalBusinesses: 45,
  breakdown: {
    grocery: 25,
    cafe: 20
  },
  businesses: [...]
}
```

### 5. Save Shops
```
POST /shops
Body: {
  shops: [...],
  salesmanId: "..."
}
```

### 6. Update Shop Stage
```
PATCH /shops/:shopId/stage
Body: {
  stage: "follow-up"
}
```

### 7. Get Shops by Salesman
```
GET /shops/salesman/:salesmanId
```

### 8. Get Assignments by Salesman
```
GET /assignments/salesman/:salesmanId
```

---

## 🗄️ Database Schema

### TaskAssignment Table
```prisma
model TaskAssignment {
  id              String    @id @default(cuid())
  salesmanId      String
  salesmanName    String
  pincode         String
  country         String?
  state           String?
  district        String?
  city            String?
  areas           String[]
  businessTypes   String[]
  totalBusinesses Int?
  assignedDate    DateTime  @default(now())
  createdAt       DateTime  @default(now())
  updatedAt       DateTime  @updatedAt
}
```

### Shop Table
```prisma
model Shop {
  id              String    @id @default(cuid())
  placeId         String?   @unique
  name            String
  businessType    String
  address         String?
  pincode         String
  area            String?
  city            String?
  state           String?
  country         String?
  latitude        Float?
  longitude       Float?
  phoneNumber     String?
  rating          Float?
  stage           String    @default("new")
  assignedTo      String?
  notes           String?
  lastContactDate DateTime?
  createdAt       DateTime  @default(now())
  updatedAt       DateTime  @updatedAt
}
```

---

## 🚀 Setup Instructions

### Backend Setup

1. **Add Google Maps API Key**
```bash
# backend/.env
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

2. **Run Prisma Migration**
```bash
cd backend
npx prisma migrate dev --name add_task_assignment_and_shops
npx prisma generate
```

3. **Start Backend Server**
```bash
npm run dev
```

### Frontend Setup

1. **Install Dependencies**
```bash
cd loagma_crm
flutter pub get
```

2. **Configure Google Maps**

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<manifest>
  <application>
    <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
  </application>
</manifest>
```

**iOS** (`ios/Runner/AppDelegate.swift`):
```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

3. **Run Flutter App**
```bash
flutter run
```

---

## 🎯 Business Types

| ID | Name | Icon | Google Places Type |
|---|---|---|---|
| `grocery` | Grocery | 🛒 | grocery_or_supermarket |
| `cafe` | Cafe | ☕ | cafe |
| `hotel` | Hotel | 🏨 | lodging, hotel |
| `dairy` | Dairy | 🥛 | store |
| `restaurant` | Restaurant | 🍽️ | restaurant |
| `bakery` | Bakery | 🍞 | bakery |
| `pharmacy` | Pharmacy | 💊 | pharmacy, drugstore |
| `supermarket` | Supermarket | 🏪 | supermarket |
| `others` | Others | 📦 | store, establishment |

---

## 📊 Shop Stages

| Stage | Color | Description |
|---|---|---|
| `new` | Yellow | Newly discovered shop |
| `follow-up` | Blue | Requires follow-up contact |
| `converted` | Green | Successfully converted to customer |
| `lost` | Red | Lost opportunity |

---

## 🔑 Google Maps API Setup

1. **Go to Google Cloud Console**
   - https://console.cloud.google.com/

2. **Enable APIs**
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geocoding API

3. **Create API Key**
   - Create credentials → API Key
   - Restrict key to your app (optional)

4. **Add to Environment**
   - Backend: `.env` file
   - Android: `AndroidManifest.xml`
   - iOS: `AppDelegate.swift`

---

## 📝 Files Created

### Backend
- `backend/src/services/googlePlacesService.js` - Google Places integration
- `backend/src/controllers/taskAssignmentController.js` - Task assignment logic
- `backend/src/routes/taskAssignmentRoutes.js` - API routes
- `backend/prisma/schema.prisma` - Updated with TaskAssignment & Shop models

### Frontend
- `loagma_crm/lib/screens/admin/map_task_assignment_screen.dart` - Main UI
- `loagma_crm/lib/services/map_task_assignment_service.dart` - API service
- `loagma_crm/lib/models/shop_model.dart` - Shop data model
- `loagma_crm/lib/router/app_router.dart` - Updated with new route

---

## 🎨 UI Screenshots

### Assign Tab
- Salesman dropdown
- Pin code input with fetch button
- Location details card
- Area selection chips
- Business type filters
- Fetch businesses button
- Assign button

### Map Tab
- Full-screen Google Map
- Color-coded markers
- Legend overlay
- Interactive shop details
- Stage update dialog

### Assignments Tab
- Expandable assignment cards
- Pin code and area details
- Business type breakdown
- Total businesses count

---

## 🧪 Testing

### Test Pin Codes (India)
- **400001** - Mumbai, Maharashtra
- **110001** - Delhi, Delhi
- **560001** - Bangalore, Karnataka
- **600001** - Chennai, Tamil Nadu
- **700001** - Kolkata, West Bengal

### Test Flow
1. Login as Admin
2. Navigate to "Map Task Assignment"
3. Select a salesman
4. Enter pin code: 400001
5. Click "Fetch"
6. Select areas: Andheri, Bandra
7. Select business types: Grocery, Cafe
8. Click "Fetch Businesses"
9. View results on map
10. Click "Assign Areas to Salesman"
11. Switch to "Assignments" tab to verify

---

## 🐛 Troubleshooting

### Google Maps Not Showing
- Check API key is correct
- Verify APIs are enabled in Google Cloud Console
- Check internet connection
- Restart app after adding API key

### No Businesses Found
- Verify Google Places API is enabled
- Check API key has Places API access
- Try different pin code
- Check backend logs for errors

### Assignment Not Saving
- Check backend is running
- Verify database connection
- Check authentication token
- Review backend logs

---

## 🚀 Next Steps

1. **Add Filters**
   - Filter shops by stage
   - Filter by business type
   - Date range filters

2. **Analytics**
   - Conversion rate by area
   - Salesman performance metrics
   - Business type analysis

3. **Notifications**
   - Follow-up reminders
   - New shop alerts
   - Assignment notifications

4. **Offline Support**
   - Cache shop data
   - Offline map tiles
   - Sync when online

5. **Export Features**
   - Export assignments to PDF
   - CSV export for analysis
   - Share via email

---

## ✅ Status

✅ Backend API complete  
✅ Frontend UI complete  
✅ Google Maps integration  
✅ Database schema updated  
✅ Routing configured  
✅ Authentication integrated  
✅ Stage management  
✅ Multi-tab interface  
✅ Error handling  
✅ Loading states  

**Ready for Production!**

---

**Last Updated**: November 29, 2025
