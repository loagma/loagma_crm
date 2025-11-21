# Account Master Complete Refactoring Plan

## Overview
Complete refactoring of Account Master with new fields, pincode-based location lookup, and image uploads.

## New Requirements

### Fields (in order):
1. ✅ Business Name (new - required)
2. ✅ Business Type (existing - optional)
3. ✅ Person Name (existing - required)
4. ✅ Contact Number (existing - required)
5. ✅ Customer Stage (existing - optional)
6. ✅ Funnel Stage (existing - optional)
7. ✅ GST Number (new - optional)
8. ✅ PAN Card (new - optional)
9. ✅ Business Owner Personal Image (new - optional)
10. ✅ Shop Image (new - optional)
11. ✅ Active/Inactive Status (new - default: Active)

### Location Fields (Pincode-based):
- ✅ Pincode (enter first)
- ✅ Auto-fetch: Country, State, District, City, Area
- ✅ Manual Address field (last)
- ❌ Remove: Region, Zone (deprecated)

## Implementation Status

### ✅ Backend - Database Schema
**File:** `backend/prisma/schema.prisma`

Updated Account model with:
- businessName (String, required)
- gstNumber, panCard (String, optional)
- ownerImage, shopImage (String URLs, optional)
- isActive (Boolean, default: true)
- Pincode-based location fields (pincode, country, state, district, city, area)
- address (String, manual entry)
- Removed region/zone dependency
- Added indexes for performance

### ✅ Backend - Pincode Service
**File:** `backend/src/services/pincodeService.js`

Features:
- Fetches location from India Post API
- Validates 6-digit pincode format
- Returns: country, state, district, city, area
- Error handling for invalid pincodes

### ✅ Backend - Pincode Routes
**File:** `backend/src/routes/pincodeRoutes.js`

Endpoint: `GET /pincode/:pincode`
- Returns location details for given pincode
- 404 if pincode not found
- 500 for server errors

### ✅ Backend - App.js Registration
Added pincode routes to main app

### 🔄 Backend - Account Controller (NEEDS UPDATE)
**File:** `backend/src/controllers/accountController.js`

Needs to add:
- businessName (required)
- gstNumber, panCard
- ownerImage, shopImage URLs
- isActive field
- Pincode-based location fields
- address field
- Update validation logic

### 🔄 Flutter - Account Master Screen (NEEDS COMPLETE REWRITE)
**File:** `loagma_crm/lib/screens/shared/account_master_screen.dart`

Needs:
1. New form fields in correct order
2. Image picker for owner & shop images
3. Pincode lookup integration
4. Auto-populate location fields
5. Manual address field
6. Active/Inactive toggle
7. Remove region/zone dropdowns
8. Update validation
9. Update API calls

### 🔄 Flutter - Pincode Service (NEW)
**File:** `loagma_crm/lib/services/pincode_service.dart`

Needs:
- API call to `/pincode/:pincode`
- Parse and return location data
- Error handling

### 🔄 Flutter - Account Service (UPDATE)
**File:** `loagma_crm/lib/services/account_service.dart`

Needs to update:
- createAccount() with new fields
- updateAccount() with new fields
- Handle image URLs

### 🔄 Flutter - View All Accounts (UPDATE)
**File:** `loagma_crm/lib/screens/view_all_masters_screen.dart`

Needs to display:
- Business name
- New fields in list/detail view
- Images
- Active/Inactive status

## Database Migration Required

After schema changes, run:
```bash
cd backend
npx prisma migrate dev --name account_master_refactoring
npx prisma generate
```

## API Endpoints

### Existing (need updates):
- POST /accounts - Create account
- GET /accounts - List accounts
- GET /accounts/:id - Get account details
- PUT /accounts/:id - Update account
- DELETE /accounts/:id - Delete account

### New:
- GET /pincode/:pincode - Lookup location by pincode

## Image Upload Strategy

### Option 1: Base64 (Simple, no extra setup)
- Convert images to base64 strings
- Store in database as text
- Pros: Simple, no file storage needed
- Cons: Large database size

### Option 2: Cloud Storage (Recommended)
- Upload to cloud (AWS S3, Cloudinary, Firebase Storage)
- Store URLs in database
- Pros: Scalable, efficient
- Cons: Requires cloud setup

### Option 3: Local File Storage
- Save files to backend server
- Store file paths in database
- Pros: No external dependencies
- Cons: Not scalable, backup issues

**Recommendation:** Start with Base64 for MVP, migrate to cloud storage later.

## Testing Checklist

### Backend:
- [ ] Database migration successful
- [ ] Pincode API returns correct data
- [ ] Create account with all new fields
- [ ] Update account works
- [ ] Delete account works
- [ ] List accounts shows new fields
- [ ] Image URLs stored correctly

### Frontend:
- [ ] Form displays all fields in correct order
- [ ] Pincode lookup works
- [ ] Location fields auto-populate
- [ ] Image picker works for both images
- [ ] Validation works for all fields
- [ ] Create account successful
- [ ] View account shows all data
- [ ] Edit account works
- [ ] Delete account works
- [ ] Active/Inactive toggle works

## Next Steps

1. **Update Account Controller** - Add new fields to create/update logic
2. **Create Pincode Service (Flutter)** - API integration
3. **Rewrite Account Master Screen** - Complete UI with new fields
4. **Update Account Service** - API calls with new fields
5. **Update View All Screen** - Display new fields
6. **Run Database Migration** - Apply schema changes
7. **Test End-to-End** - Full CRUD operations
8. **Deploy** - Backend and frontend

## Estimated Time
- Backend updates: 1-2 hours
- Flutter UI rewrite: 3-4 hours
- Testing & fixes: 1-2 hours
- **Total: 5-8 hours**

## Files to Create/Update

### Backend:
1. ✅ `backend/prisma/schema.prisma` - Updated
2. ✅ `backend/src/services/pincodeService.js` - Created
3. ✅ `backend/src/routes/pincodeRoutes.js` - Created
4. ✅ `backend/src/app.js` - Updated
5. 🔄 `backend/src/controllers/accountController.js` - Needs update

### Flutter:
1. 🔄 `loagma_crm/lib/services/pincode_service.dart` - Need to create
2. 🔄 `loagma_crm/lib/services/account_service.dart` - Need to update
3. 🔄 `loagma_crm/lib/screens/shared/account_master_screen.dart` - Need complete rewrite
4. 🔄 `loagma_crm/lib/screens/view_all_masters_screen.dart` - Need to update

---

**Status:** Backend foundation complete, Flutter implementation pending
**Priority:** High - Core business functionality
**Complexity:** Medium-High - Multiple integrations required
