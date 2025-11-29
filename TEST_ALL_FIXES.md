# 🧪 Test All Fixes - Quick Guide

## ✅ Quick Test Commands

### 1. Test Backend
```bash
cd backend

# Start server
npm run dev

# Should see:
# ✅ Server running and accessible on http://0.0.0.0:5000
```

### 2. Test Salesmen Endpoint (No Auth Required)
```bash
# In a new terminal
curl http://localhost:5000/task-assignments/salesmen

# Should return:
# {"success":true,"salesmen":[...]}
```

### 3. Test Location Endpoint
```bash
curl http://localhost:5000/task-assignments/location/pincode/400001

# Should return location data
```

### 4. Test Flutter App
```bash
cd loagma_crm

# Clean and run
flutter clean
flutter pub get
flutter run
```

---

## 📋 Manual Testing Checklist

### OTP Login Test
- [ ] Open app
- [ ] Enter phone number: 9285543488
- [ ] Click "Send OTP"
- [ ] Check console for: `✅ Twilio SMS sent`
- [ ] Enter OTP
- [ ] Login successful

### Task Assignment Test
- [ ] Login as Admin
- [ ] Open menu (☰)
- [ ] See only ONE "Task Assignment" item
- [ ] Click "Task Assignment"
- [ ] See three tabs: Assign, Map, Assignments

### Assign Tab Test
- [ ] Dropdown shows salesmen (no auth error)
- [ ] Enter pincode: 400001
- [ ] Click "Fetch"
- [ ] Location details appear
- [ ] Select areas (Andheri, Bandra)
- [ ] Select business types (Grocery, Cafe)
- [ ] Click "Fetch Businesses"
- [ ] Success dialog shows count

### Map Tab Test
- [ ] Switch to "Map" tab
- [ ] Map displays with markers
- [ ] Markers are color-coded
- [ ] Legend shows in top-right
- [ ] Tap marker to see details
- [ ] Click "Update Stage"
- [ ] Stage updates successfully

### Assignments Tab Test
- [ ] Switch to "Assignments" tab
- [ ] See list of assignments
- [ ] Expand card to see details
- [ ] All information displays correctly

### Create Employee Test
- [ ] Navigate to "Create Employee"
- [ ] Fill all required fields
- [ ] Click "Create Employee"
- [ ] Success toast appears
- [ ] Form clears automatically
- [ ] Page scrolls to top
- [ ] No warning dialogs

---

## 🔍 Expected Console Output

### Backend Console
```
✅ Server running and accessible on http://0.0.0.0:5000
📞 Received contact number: 9285543488
🧹 Cleaned contact number: 9285543488
🔐 Generated OTP: 3705
💾 OTP stored in database
🔹 Sending OTP 3705 to +919285543488 using Twilio...
✅ Twilio SMS sent. SID: SM...
```

### Flutter Console
```
🔍 Fetching salesmen from: http://localhost:5000/task-assignments/salesmen
📡 Response status: 200
📡 Response body: {"success":true,"salesmen":[...]}
✅ Salesmen data: {success: true, salesmen: [...]}
✅ Loaded 1 salesmen
```

---

## ❌ Common Issues & Solutions

### Issue: "Connection refused"
**Solution**: Start backend with `npm run dev`

### Issue: "No salesmen found"
**Solution**: 
```bash
cd backend
node test-salesmen.js
node add-salesman-role.js <userId>
```

### Issue: "Twilio error"
**Solution**: Check `.env` has correct credentials

### Issue: "Map not showing"
**Solution**: Add Google Maps API key to Android/iOS

---

## ✅ Success Criteria

All these should work:
- ✅ OTP sends successfully
- ✅ Salesmen load in dropdown
- ✅ Location fetches by pincode
- ✅ Businesses fetch from Google
- ✅ Map displays with markers
- ✅ Stages can be updated
- ✅ Areas can be assigned
- ✅ Form clears on success
- ✅ Only one Task Assignment menu

---

## 🎯 Quick Smoke Test (2 minutes)

```bash
# Terminal 1: Start backend
cd backend && npm run dev

# Terminal 2: Test endpoint
curl http://localhost:5000/task-assignments/salesmen

# Terminal 3: Run Flutter
cd loagma_crm && flutter run

# In App:
# 1. Login
# 2. Open Task Assignment
# 3. Select salesman (should work!)
# 4. Enter pincode 400001
# 5. Click Fetch (should work!)
```

If all 5 steps work → **Everything is fixed!** ✅

---

**Last Updated**: November 29, 2025
