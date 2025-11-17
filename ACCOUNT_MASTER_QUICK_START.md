# Account Master CRUD - Quick Start Guide

## 🚀 Quick Setup (5 Minutes)

### Step 1: Apply Database Migration
```bash
cd backend
npx prisma migrate dev --name add_account_approval_tracking
npx prisma generate
```

### Step 2: Restart Backend
```bash
# If backend is running, stop it (Ctrl+C) and restart
npm run dev
```

### Step 3: Run Flutter App
```bash
cd loagma_crm
flutter run
```

---

## 🎯 What You Get

### ✅ Complete CRUD Operations
- **Create** accounts with auto-tracking of creator
- **Read** accounts with pagination, search, and filters
- **Update** account details
- **Delete** accounts with confirmation
- **Approve/Reject** accounts (for managers)

### ✅ New Screens
1. **Account List Screen** - View all accounts in a beautiful card layout
2. **Account Detail Screen** - View and edit individual accounts

### ✅ Backend APIs
10 new API endpoints for complete account management

---

## 📱 How to Use

### For Salesman/Telecaller:

1. **Create Account:**
   - Tap "Account Master" in sidebar
   - Fill in the form
   - Submit
   - Account is created with status "Pending Approval"

2. **View Accounts:**
   - Navigate to Account List (see integration below)
   - See all your created accounts
   - Search, filter, and manage

3. **Edit Account:**
   - Tap on any account card
   - Tap Edit button
   - Make changes
   - Save

4. **Delete Account:**
   - Tap Delete button on account card
   - Confirm deletion

### For Manager/Admin:

1. **Approve Accounts:**
   - View pending accounts
   - Tap Approve button
   - Account status changes to "Approved"

2. **View All Accounts:**
   - See accounts from all users
   - Filter by approval status
   - View creator and approver information

---

## 🔗 Integration with Sidebar

### Option 1: Replace Current "Account Master" Menu

**File:** `loagma_crm/lib/widgets/role_dashboard_template.dart`

Find the "Account Master" menu item and replace with:

```dart
MenuItem(
  icon: Icons.account_box_outlined,
  title: "Account Master",
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AccountListScreen(),
      ),
    );
  },
),
```

Don't forget to add the import at the top:
```dart
import '../screens/shared/account_list_screen.dart';
```

### Option 2: Add Both List and Create as Separate Items

```dart
MenuItem(
  icon: Icons.list_alt_outlined,
  title: "View Accounts",
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AccountListScreen(),
      ),
    );
  },
),
MenuItem(
  icon: Icons.add_box_outlined,
  title: "Create Account",
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AccountMasterScreen(),
      ),
    );
  },
),
```

Add imports:
```dart
import '../screens/shared/account_list_screen.dart';
import '../screens/shared/account_master_screen.dart';
```

---

## 🧪 Quick Test

### Test 1: Create Account
1. Login as Salesman
2. Go to Account Master
3. Fill form:
   - Name: "Test Customer"
   - Phone: "9876543210"
   - Stage: "Lead"
4. Submit
5. ✅ Should see success message with account code

### Test 2: View Accounts
1. Navigate to Account List
2. ✅ Should see the account you just created
3. ✅ Status should show "Pending"
4. ✅ Your name should show as creator

### Test 3: Edit Account
1. Tap on the account card
2. Tap Edit button
3. Change name to "Test Customer Updated"
4. Save
5. ✅ Should see success message
6. ✅ Name should be updated

### Test 4: Search
1. In Account List, type in search box
2. ✅ Should filter accounts in real-time

### Test 5: Delete
1. Tap Delete button
2. Confirm
3. ✅ Account should be removed

---

## 📊 Database Schema Changes

### New Fields in Account Table:
- `createdById` (String?) - Who created the account
- `approvedById` (String?) - Who approved the account
- `approvedAt` (DateTime?) - When it was approved
- `isApproved` (Boolean) - Approval status (default: false)

### Relations:
- Account → User (createdBy)
- Account → User (approvedBy)
- Account → User (assignedTo)

---

## 🎨 UI Features

### Account List Screen:
- ✨ Beautiful card-based layout
- 🔍 Real-time search
- 🎯 Smart filters (stage, approval status)
- 📱 Pull-to-refresh
- ♾️ Infinite scroll
- 🎨 Color-coded approval badges
- ⚡ Fast and responsive

### Account Detail Screen:
- 👤 Profile-style header
- ✏️ Inline editing
- 📊 Complete information display
- 👥 Creator and approver tracking
- 📅 Timestamp tracking
- 🎨 Clean, modern design

---

## 🔐 Security Features

- ✅ All APIs require authentication
- ✅ User ID automatically extracted from JWT token
- ✅ Creator tracking prevents data manipulation
- ✅ Approval workflow ensures data quality
- ✅ Role-based access control

---

## 📈 Performance Features

- ✅ Pagination (20 items per page)
- ✅ Lazy loading (infinite scroll)
- ✅ Efficient database queries
- ✅ Indexed fields for fast search
- ✅ Optimized API responses

---

## 🐛 Common Issues & Solutions

### Issue: Migration fails
**Solution:** Make sure PostgreSQL is running and DATABASE_URL is correct in `.env`

### Issue: "Failed to create account"
**Solution:** 
- Check backend is running on correct port
- Verify authentication token is valid
- Ensure contact number is exactly 10 digits

### Issue: Accounts not showing
**Solution:**
- Check if you're logged in
- Verify backend API is accessible
- Check console for error messages

### Issue: Can't approve accounts
**Solution:**
- Ensure you're logged in as Manager/Admin
- Check role permissions in database

---

## 📚 Documentation

- **Backend API:** `backend/ACCOUNT_API_DOCUMENTATION.md`
- **Migration Guide:** `backend/MIGRATION_INSTRUCTIONS.md`
- **Full Implementation:** `loagma_crm/ACCOUNT_MASTER_IMPLEMENTATION.md`

---

## ✅ Checklist

- [ ] Applied database migration
- [ ] Restarted backend server
- [ ] Updated Flutter dependencies
- [ ] Added Account List to sidebar menu
- [ ] Tested account creation
- [ ] Tested account viewing
- [ ] Tested account editing
- [ ] Tested account deletion
- [ ] Tested search functionality
- [ ] Tested filter functionality
- [ ] Tested approval workflow (if manager/admin)

---

## 🎉 You're Done!

Your Account Master CRUD is now fully functional with:
- ✅ Complete CRUD operations
- ✅ User tracking (createdBy, approvedBy)
- ✅ Approval workflow
- ✅ Beautiful UI
- ✅ Search and filters
- ✅ Pagination
- ✅ Role-based access

**Happy coding! 🚀**
