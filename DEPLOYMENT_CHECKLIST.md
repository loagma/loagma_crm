# Account Master CRUD - Deployment Checklist

## 📋 Pre-Deployment Checklist

### Backend Setup
- [ ] PostgreSQL database is running
- [ ] `.env` file has correct DATABASE_URL
- [ ] All dependencies installed (`npm install`)
- [ ] Prisma schema is up to date

### Database Migration
```bash
cd backend
npx prisma migrate dev --name add_account_approval_tracking
npx prisma generate
```
- [ ] Migration applied successfully
- [ ] No migration errors
- [ ] Prisma client generated

### Backend Server
```bash
npm run dev
```
- [ ] Server starts without errors
- [ ] Server running on correct port (default: 5000)
- [ ] No console errors

### Frontend Setup
```bash
cd loagma_crm
flutter pub get
```
- [ ] All dependencies installed
- [ ] No dependency conflicts
- [ ] Flutter SDK is up to date

---

## 🧪 Testing Checklist

### Backend API Testing

#### 1. Create Account
```bash
curl -X POST http://localhost:5000/accounts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "personName": "Test User",
    "contactNumber": "9876543210",
    "customerStage": "Lead"
  }'
```
- [ ] Returns 201 status
- [ ] Account code generated
- [ ] createdById is set
- [ ] isApproved is false

#### 2. Get All Accounts
```bash
curl http://localhost:5000/accounts \
  -H "Authorization: Bearer YOUR_TOKEN"
```
- [ ] Returns 200 status
- [ ] Pagination works
- [ ] Accounts array returned

#### 3. Get Account by ID
```bash
curl http://localhost:5000/accounts/ACCOUNT_ID \
  -H "Authorization: Bearer YOUR_TOKEN"
```
- [ ] Returns 200 status
- [ ] Full account details returned
- [ ] Related objects included

#### 4. Update Account
```bash
curl -X PUT http://localhost:5000/accounts/ACCOUNT_ID \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"personName": "Updated Name"}'
```
- [ ] Returns 200 status
- [ ] Account updated successfully

#### 5. Approve Account
```bash
curl -X POST http://localhost:5000/accounts/ACCOUNT_ID/approve \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```
- [ ] Returns 200 status
- [ ] isApproved set to true
- [ ] approvedById set
- [ ] approvedAt timestamp set

#### 6. Delete Account
```bash
curl -X DELETE http://localhost:5000/accounts/ACCOUNT_ID \
  -H "Authorization: Bearer YOUR_TOKEN"
```
- [ ] Returns 200 status
- [ ] Account deleted successfully

### Frontend Testing

#### Account Creation
- [ ] Login as Salesman/Telecaller
- [ ] Navigate to Account Master
- [ ] Fill form with valid data
- [ ] Submit form
- [ ] Success message appears
- [ ] Account code displayed
- [ ] Form clears after submission

#### Account List View
- [ ] Navigate to Account List screen
- [ ] Accounts display in cards
- [ ] Approval badges show correctly
- [ ] Creator names visible
- [ ] Scroll works smoothly
- [ ] Pull-to-refresh works

#### Search Functionality
- [ ] Type in search box
- [ ] Results filter in real-time
- [ ] Clear search works
- [ ] Search by name works
- [ ] Search by phone works
- [ ] Search by account code works

#### Filter Functionality
- [ ] Open filter dialog
- [ ] Select customer stage filter
- [ ] Apply filter
- [ ] Results filtered correctly
- [ ] Select approval status filter
- [ ] Apply filter
- [ ] Results filtered correctly
- [ ] Clear filters works

#### Account Detail View
- [ ] Tap on account card
- [ ] Detail screen opens
- [ ] All information displays correctly
- [ ] Approval status shows
- [ ] Creator information shows
- [ ] Timestamps display correctly

#### Account Edit
- [ ] Tap Edit button
- [ ] Form appears with current data
- [ ] Modify fields
- [ ] Save changes
- [ ] Success message appears
- [ ] Data updates in view mode

#### Account Delete
- [ ] Tap Delete button
- [ ] Confirmation dialog appears
- [ ] Confirm deletion
- [ ] Success message appears
- [ ] Account removed from list

#### Pagination
- [ ] Scroll to bottom of list
- [ ] Loading indicator appears
- [ ] Next page loads automatically
- [ ] No duplicate items
- [ ] Smooth scrolling

---

## 🔗 Integration Checklist

### Add Account List to Sidebar

#### Option 1: Replace Current Menu Item
**File:** `loagma_crm/lib/widgets/role_dashboard_template.dart`

1. [ ] Open the file
2. [ ] Find "Account Master" menu item in sales/telecaller menu
3. [ ] Add import: `import '../screens/shared/account_list_screen.dart';`
4. [ ] Replace navigation to use `AccountListScreen()`
5. [ ] Save file
6. [ ] Hot reload app
7. [ ] Test navigation

#### Option 2: Add Separate Menu Items
1. [ ] Add "View Accounts" menu item
2. [ ] Add "Create Account" menu item
3. [ ] Add necessary imports
4. [ ] Save file
5. [ ] Hot reload app
6. [ ] Test both navigations

---

## 🎯 Role-Based Testing

### Salesman Role
- [ ] Can create accounts
- [ ] Can view own accounts
- [ ] Can edit own accounts
- [ ] Can delete own accounts
- [ ] Cannot approve accounts
- [ ] Creator name shows correctly

### Telecaller Role
- [ ] Can create accounts
- [ ] Can view own accounts
- [ ] Can edit own accounts
- [ ] Can delete own accounts
- [ ] Cannot approve accounts
- [ ] Creator name shows correctly

### Manager/Admin Role
- [ ] Can view all accounts
- [ ] Can approve accounts
- [ ] Can reject approvals
- [ ] Can use bulk operations
- [ ] Can view statistics
- [ ] Approver name shows correctly

---

## 🐛 Error Handling Testing

### Backend Errors
- [ ] Test with invalid token
- [ ] Test with missing required fields
- [ ] Test with duplicate contact number
- [ ] Test with invalid contact number format
- [ ] Test with non-existent account ID
- [ ] Test with unauthorized access

### Frontend Errors
- [ ] Test with no internet connection
- [ ] Test with backend server down
- [ ] Test with invalid form data
- [ ] Test with empty search
- [ ] Test with no results
- [ ] Test error messages display correctly

---

## 📊 Performance Testing

### Backend Performance
- [ ] Test with 100 accounts
- [ ] Test with 1000 accounts
- [ ] Test pagination performance
- [ ] Test search performance
- [ ] Test filter performance
- [ ] Check database query efficiency

### Frontend Performance
- [ ] Test scroll performance with many items
- [ ] Test search responsiveness
- [ ] Test filter responsiveness
- [ ] Test image loading (if any)
- [ ] Test memory usage
- [ ] Test app size

---

## 🔒 Security Testing

### Authentication
- [ ] All endpoints require auth token
- [ ] Invalid tokens rejected
- [ ] Expired tokens rejected
- [ ] User ID extracted correctly from token

### Authorization
- [ ] Users can only see appropriate data
- [ ] Role-based access enforced
- [ ] Cannot manipulate createdById
- [ ] Cannot manipulate approvedById

### Data Validation
- [ ] Contact number validation works
- [ ] Required fields enforced
- [ ] Duplicate prevention works
- [ ] SQL injection prevented
- [ ] XSS prevention works

---

## 📱 Device Testing

### Android
- [ ] Test on Android emulator
- [ ] Test on physical Android device
- [ ] Test different screen sizes
- [ ] Test different Android versions

### iOS (if applicable)
- [ ] Test on iOS simulator
- [ ] Test on physical iOS device
- [ ] Test different screen sizes
- [ ] Test different iOS versions

---

## 📝 Documentation Review

- [ ] Read MIGRATION_INSTRUCTIONS.md
- [ ] Read ACCOUNT_API_DOCUMENTATION.md
- [ ] Read ACCOUNT_MASTER_IMPLEMENTATION.md
- [ ] Read ACCOUNT_MASTER_QUICK_START.md
- [ ] Read IMPLEMENTATION_SUMMARY.md
- [ ] All documentation is clear and accurate

---

## 🚀 Production Deployment

### Backend Deployment
- [ ] Environment variables set correctly
- [ ] Database migration applied on production
- [ ] Server deployed and running
- [ ] Health check endpoint working
- [ ] Logs configured
- [ ] Error monitoring set up

### Frontend Deployment
- [ ] API base URL updated for production
- [ ] App built for release
- [ ] App tested on production backend
- [ ] App signed (if required)
- [ ] App uploaded to store (if applicable)

---

## ✅ Final Verification

### Functionality
- [ ] All CRUD operations work
- [ ] User tracking works
- [ ] Approval workflow works
- [ ] Search works
- [ ] Filters work
- [ ] Pagination works

### UI/UX
- [ ] UI is responsive
- [ ] Loading states show correctly
- [ ] Error messages are clear
- [ ] Success messages are clear
- [ ] Navigation is smooth
- [ ] Design is consistent

### Performance
- [ ] App loads quickly
- [ ] API responses are fast
- [ ] No memory leaks
- [ ] No crashes
- [ ] Smooth scrolling
- [ ] Efficient data loading

### Security
- [ ] Authentication works
- [ ] Authorization works
- [ ] Data validation works
- [ ] No security vulnerabilities
- [ ] Sensitive data protected

---

## 📞 Post-Deployment

### Monitoring
- [ ] Set up error tracking
- [ ] Set up performance monitoring
- [ ] Set up usage analytics
- [ ] Set up alerts for critical errors

### User Training
- [ ] Create user guide
- [ ] Train Salesman/Telecaller users
- [ ] Train Manager/Admin users
- [ ] Provide support contact

### Maintenance
- [ ] Schedule regular backups
- [ ] Plan for updates
- [ ] Monitor user feedback
- [ ] Track feature requests

---

## 🎉 Deployment Complete!

Once all items are checked:
- [ ] Mark deployment as complete
- [ ] Notify stakeholders
- [ ] Monitor for issues
- [ ] Gather user feedback
- [ ] Plan next iteration

---

**Deployment Date:** _______________
**Deployed By:** _______________
**Version:** 1.0.0
**Status:** ⬜ In Progress / ✅ Complete
