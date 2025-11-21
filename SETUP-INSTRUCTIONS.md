# 🚀 Account Master Setup - Complete Instructions

## ✅ What's Ready

Everything is implemented and ready to go:
- ✅ Backend code updated
- ✅ Database schema updated
- ✅ Frontend code updated
- ✅ Image picker installed
- ✅ Migration scripts created

## 🎯 Quick Setup (3 Steps)

### Option 1: Automated Setup (Recommended)

**Just run this file:**
```
FINAL-SETUP.bat
```

This will:
1. Apply database migration
2. Generate Prisma Client
3. Verify everything works

### Option 2: Manual Setup

**Step 1: Apply Migration**
```bash
cd backend
node apply-migration.js
```

**Step 2: Generate Prisma Client**
```bash
npx prisma generate
```

**Step 3: Start Backend**
```bash
npm run dev
```

## 🧪 Testing

### 1. Test Pincode API
Open in browser:
```
http://localhost:5000/pincode/400001
```

Should return:
```json
{
  "success": true,
  "data": {
    "pincode": "400001",
    "country": "India",
    "state": "Maharashtra",
    "district": "Mumbai",
    "city": "Mumbai",
    "area": "Churchgate"
  }
}
```

### 2. Test Account Master Screen

1. Open Flutter app
2. Navigate to Account Master
3. Fill in the form:
   - Business Name: "Test Business"
   - Person Name: "John Doe"
   - Contact: "9876543210"
   - Enter Pincode: "400001"
   - Click "Lookup" button
   - Location fields should auto-fill
   - Select owner image
   - Select shop image
   - Submit

### 3. Verify Database

Check that new fields exist:
```sql
SELECT 
  "accountCode",
  "businessName",
  "gstNumber",
  "panCard",
  "isActive",
  "pincode",
  "country"
FROM "Account"
LIMIT 5;
```

## 📋 New Features

### Form Fields (In Order):
1. Business Name
2. Business Type
3. Person Name *
4. Contact Number *
5. Customer Stage
6. Funnel Stage
7. GST Number (validated)
8. PAN Card (validated)
9. Owner Image (picker)
10. Shop Image (picker)
11. Active/Inactive Toggle
12. **Location:**
    - Pincode + Lookup button
    - Auto-fill: Country, State, District, City, Area
    - Manual Address

### Validations:
- Contact: 10 digits
- GST: `22AAAAA0000A1Z5` format
- PAN: `ABCDE1234F` format
- Pincode: 6 digits

## 🔧 Troubleshooting

### Migration Fails

**Error: "Cannot connect to database"**
```bash
# Check DATABASE_URL in backend/.env
# Ensure PostgreSQL is running
# Test connection:
cd backend
npx prisma db pull
```

**Error: "Column already exists"**
```
This is okay! The migration script handles this.
Just continue with: npx prisma generate
```

### Prisma Generate Fails

```bash
cd backend
npm install @prisma/client
npx prisma generate --force
```

### Backend Won't Start

```bash
cd backend
npm install
npm run dev
```

### Images Not Working

```bash
cd loagma_crm
flutter pub get
flutter clean
flutter pub get
```

### Pincode Lookup Not Working

1. Check backend is running: http://localhost:5000/health
2. Check pincode API: http://localhost:5000/pincode/400001
3. Check Flutter console for errors

## 📁 Important Files

### Backend:
- `backend/apply-migration.js` - Migration script
- `backend/RUN-MIGRATION.bat` - Run migration
- `backend/prisma/schema.prisma` - Database schema
- `backend/src/services/pincodeService.js` - Pincode lookup
- `backend/src/controllers/accountController.js` - Account CRUD

### Frontend:
- `loagma_crm/lib/screens/shared/account_master_screen.dart` - Main form
- `loagma_crm/lib/services/pincode_service.dart` - Pincode API
- `loagma_crm/lib/services/account_service.dart` - Account API

### Backup:
- `loagma_crm/lib/screens/shared/account_master_screen_old_backup.dart` - Old version

## 🎓 What Changed

### Database:
- Added 13 new columns to Account table
- Added 4 new indexes
- Updated existing records with defaults

### Backend:
- New pincode lookup endpoint
- Updated account controller
- Added GST/PAN validation
- Added pincode validation

### Frontend:
- Complete new UI
- Image picker integration
- Pincode auto-lookup
- Enhanced validation
- Better UX

## 📞 Need Help?

### Check Logs:
```bash
# Backend logs
cd backend
npm run dev

# Flutter logs
cd loagma_crm
flutter run
```

### Verify Setup:
```bash
# Check Prisma
cd backend
npx prisma studio

# Check Flutter dependencies
cd loagma_crm
flutter doctor
```

### Reset Everything (⚠️ Deletes data):
```bash
cd backend
npx prisma migrate reset
npx prisma generate
```

## ✨ Success Indicators

You'll know it's working when:
- ✅ Migration script completes without errors
- ✅ Prisma generate succeeds
- ✅ Backend starts without errors
- ✅ Pincode API returns data
- ✅ Account Master screen shows all fields
- ✅ Pincode lookup auto-fills location
- ✅ Images can be selected
- ✅ Form submits successfully

## 🎉 You're Done!

Once setup is complete:
1. Backend is running with new endpoints
2. Database has all new fields
3. Frontend has complete new UI
4. All features are working

Start creating accounts with the new fields!

---

**Last Updated:** November 21, 2024
**Status:** Ready for Production
