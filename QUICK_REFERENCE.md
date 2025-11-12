# ⚡ Quick Reference Card

## 🚀 Start Everything (Copy & Paste)

### Terminal 1: Start Backend
```bash
cd backend && npm run dev
```

### Terminal 2: Start Flutter
```bash
cd loagma_crm && flutter run
```

---

## 🔧 First Time Setup

```bash
# Backend Setup
cd backend
npm install
npx prisma generate
npx prisma migrate dev
npm run seed
npm run seed:locations

# Flutter Setup
cd loagma_crm
flutter pub get
```

---

## 📝 Update Flutter to Use New Dashboard

**File**: `loagma_crm/lib/main.dart`

```dart
import 'screens/dashboard_screen_new.dart';

// Change this line:
home: const DashboardScreenNew(),
```

---

## 🌐 API URL Configuration

**File**: `loagma_crm/lib/services/api_config.dart`

```dart
// Android Emulator
static const String baseUrl = 'http://10.0.2.2:5000';

// iOS Simulator
static const String baseUrl = 'http://localhost:5000';

// Physical Device (replace with your IP)
static const String baseUrl = 'http://192.168.1.100:5000';
```

**Find your IP**:
```bash
# Windows
ipconfig

# Mac/Linux
ifconfig | grep inet
```

---

## ✅ Quick Test

```bash
# Test backend
curl http://localhost:5000

# Test countries API
curl http://localhost:5000/locations/countries

# Test account creation
curl -X POST http://localhost:5000/accounts \
  -H "Content-Type: application/json" \
  -d '{"personName":"Test User","contactNumber":"9876543210"}'
```

---

## 📱 Test in App

1. Open app
2. Drawer → Master → Area
3. Select: India → Gujarat → Ahmedabad → Ahmedabad City → West Zone → Vastrapur
4. Click "Next"
5. Fill: Name="Test", Contact="9999999999"
6. Click "Submit"
7. ✅ Success!

---

## 🐛 Troubleshooting

### Backend not starting?
```bash
cd backend
npm install
npm run dev
```

### No data in dropdowns?
```bash
cd backend
npm run seed:locations
```

### Connection refused?
Check API URL in `api_config.dart` matches your platform

### Port 5000 in use?
```bash
# Windows
netstat -ano | findstr :5000
taskkill /PID <PID> /F

# Mac/Linux
lsof -ti:5000 | xargs kill -9
```

---

## 📚 Documentation

- **Complete Guide**: `COMPLETE_SOLUTION_SUMMARY.md`
- **Testing Guide**: `INTEGRATION_TESTING_GUIDE.md`
- **API Docs**: `backend/API_DOCUMENTATION.md`
- **Flutter Integration**: `backend/FLUTTER_INTEGRATION_GUIDE.md`

---

## 🎯 Key Files

### Backend
- Controllers: `backend/src/controllers/locationController.js`
- Controllers: `backend/src/controllers/accountController.js`
- Routes: `backend/src/routes/locationRoutes.js`
- Routes: `backend/src/routes/accountRoutes.js`

### Flutter
- Dashboard: `loagma_crm/lib/screens/dashboard_screen_new.dart`
- Services: `loagma_crm/lib/services/location_service.dart`
- Services: `loagma_crm/lib/services/account_service.dart`
- Config: `loagma_crm/lib/services/api_config.dart`

---

## 🔍 View Database

```bash
cd backend
npx prisma studio
```

Opens at: `http://localhost:5555`

---

## 📊 API Endpoints

### Locations
- `GET /locations/countries`
- `GET /locations/states?countryId=ID`
- `GET /locations/districts?stateId=ID`
- `GET /locations/cities?districtId=ID`
- `GET /locations/zones?cityId=ID`
- `GET /locations/areas?zoneId=ID`

### Accounts
- `GET /accounts`
- `POST /accounts`
- `GET /accounts/:id`
- `PUT /accounts/:id`
- `DELETE /accounts/:id`
- `GET /accounts/stats`

---

## ⚡ Quick Commands

```bash
# Start backend
cd backend && npm run dev

# Start Flutter
cd loagma_crm && flutter run

# Seed data
cd backend && npm run seed:locations

# View database
cd backend && npx prisma studio

# Test API
curl http://localhost:5000/locations/countries

# Flutter clean
cd loagma_crm && flutter clean && flutter pub get
```

---

## ✅ Success Checklist

- [ ] Backend running on port 5000
- [ ] Countries API returns data
- [ ] Flutter app launches
- [ ] Dropdowns load data
- [ ] Cascading works
- [ ] Account creation succeeds
- [ ] Success message appears

---

## 🎉 You're Ready!

Everything is set up. Just run the commands above and test!

**Need help?** Check `INTEGRATION_TESTING_GUIDE.md`
