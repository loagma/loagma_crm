# Quick Start Guide - New Employee Management Features

## 🚀 Getting Started

### Step 1: Apply Database Migration
```bash
cd backend
node apply-user-fields-migration.js
```

Expected output:
```
✅ Connected to database
📝 Applying migration...
✅ Migration applied successfully
✅ Verified columns: [
  { column_name: 'country', data_type: 'text' },
  { column_name: 'district', data_type: 'text' }
]
```

### Step 2: Start Backend Server
```bash
cd backend
npm run dev
```

### Step 3: Run Flutter App
```bash
cd loagma_crm
flutter run
```

## 📱 Using the New Features

### Feature 1: Check for Duplicate Employees
1. Navigate to **Admin → Create Employee**
2. Enter a 10-digit contact number
3. If employee exists:
   - Dialog appears automatically
   - Shows employee details and photo
   - Options: **View** | **Edit** | **Delete**

### Feature 2: Upload Profile Picture
1. Scroll to bottom of Create Employee form
2. Find **"Profile Picture"** section
3. Click **"Choose Photo"**
4. Select image from gallery
5. Preview appears immediately
6. Click **"Create Employee"** to upload

### Feature 3: Auto-Fill Address from Pincode
1. Enter 6-digit pincode (e.g., `400001`)
2. Click **"Lookup"** button
3. Watch fields auto-fill:
   - Country → India
   - State → Maharashtra
   - District → Mumbai
   - City → Mumbai

### Feature 4: Manual Address Entry
1. Check **"Enter address manually"**
2. All address fields become editable
3. Type your own values
4. Pincode lookup is disabled

## 🎯 Common Use Cases

### Creating Employee with Photo
```
1. Enter phone: 9876543210
2. Enter name: John Doe
3. Enter email: john@example.com
4. Select role and department
5. Enter salary: 50000
6. Scroll down to Profile Picture
7. Click "Choose Photo"
8. Select image
9. Click "Create Employee"
```

### Handling Duplicate Phone Numbers
```
1. Enter phone: 9876543210 (existing)
2. Dialog appears with employee info
3. Options:
   - View: See full employee details
   - Edit: Update employee information
   - Delete: Remove employee
   - Close: Cancel and try different number
```

### Using Pincode Lookup
```
Popular Indian Pincodes to Test:
- 400001 → Mumbai, Maharashtra
- 110001 → New Delhi, Delhi
- 560001 → Bangalore, Karnataka
- 600001 → Chennai, Tamil Nadu
- 700001 → Kolkata, West Bengal
```

## 🔍 Verification Checklist

After implementation, verify:

- [ ] Database has `country` and `district` columns
- [ ] Backend server starts without errors
- [ ] Flutter app compiles successfully
- [ ] Can create employee with phone number
- [ ] Duplicate check shows dialog for existing numbers
- [ ] Can upload and preview profile picture
- [ ] Pincode lookup fetches location data
- [ ] Manual address toggle works
- [ ] Employee list shows profile pictures
- [ ] Can view employee details with photo
- [ ] Can edit employee information
- [ ] Can delete employee

## 🐛 Troubleshooting

### Issue: "Column does not exist" error
**Solution**: Run migration script
```bash
cd backend
node apply-user-fields-migration.js
```

### Issue: Image upload fails
**Check**:
- Internet connection
- Cloudinary service status
- Image file size (should be < 10MB)
- Image format (JPG, PNG supported)

### Issue: Pincode lookup not working
**Check**:
- Internet connection
- Valid 6-digit Indian pincode
- API: https://api.postalpincode.in/pincode/400001

### Issue: Duplicate check not triggering
**Check**:
- Phone number is exactly 10 digits
- Backend server is running
- API endpoint: GET /api/admin/users?contactNumber=XXXXXXXXXX

## 📊 Testing Data

### Test Employee 1
```
Phone: 9999888877
Name: Test Employee
Email: test@example.com
Salary: 45000
Pincode: 400001
```

### Test Employee 2
```
Phone: 8888777766
Name: Demo User
Email: demo@example.com
Salary: 55000
Pincode: 110001
```

## 🔗 API Endpoints Reference

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/admin/users` | Create employee |
| GET | `/api/admin/users` | List all employees |
| GET | `/api/admin/users?contactNumber=XXX` | Check duplicate |
| PUT | `/api/admin/users/:id` | Update employee |
| DELETE | `/api/admin/users/:id` | Delete employee |

## 📸 Cloudinary Info

- **Cloud Name**: dfncqhkl9
- **API Key**: 652667859422493
- **Upload URL**: https://api.cloudinary.com/v1_1/dfncqhkl9/image/upload
- **Preset**: ml_default

## ✅ Success Indicators

You'll know everything is working when:

1. ✅ Creating employee with existing phone shows dialog
2. ✅ Profile picture appears in employee list
3. ✅ Pincode lookup fills all address fields
4. ✅ Manual address toggle enables/disables fields
5. ✅ Image URL starts with `res.cloudinary.com`
6. ✅ All CRUD operations work smoothly

## 📞 Support

If you encounter issues:
1. Check console logs in Flutter
2. Check backend server logs
3. Verify database connection
4. Test API endpoints with Postman
5. Review IMPLEMENTATION_SUMMARY.md for details

---

**Ready to go!** 🎉

Start by creating your first employee with a profile picture!
