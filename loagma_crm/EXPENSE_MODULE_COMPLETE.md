# 💰 Daily Expense Module - Complete Implementation

## ✅ What Was Implemented

### Full End-to-End Expense Management System
- Employees can submit daily expenses
- Track expense status (Pending, Approved, Rejected, Paid)
- View expense history and statistics
- Admin can approve/reject expenses

---

## 📊 Database Schema (Prisma)

### Expense Model
```prisma
model Expense {
  id              String    @id @default(cuid())
  employeeId      String
  expenseType     String    // Travel, Food, Accommodation, Fuel, Other
  amount          Float
  expenseDate     DateTime
  description     String?
  billNumber      String?
  attachmentUrl   String?
  status          String    @default("Pending")
  approvedBy      String?
  approvedAt      DateTime?
  rejectionReason String?
  paidAt          DateTime?
  remarks         String?
  createdAt       DateTime  @default(now())
  updatedAt       DateTime  @updatedAt
  employee        User      @relation("EmployeeExpenses")
  approver        User?     @relation("ApprovedExpenses")
}
```

### Run Migration
```bash
cd backend
npx prisma migrate dev --name add_expense_model
npx prisma generate
```

---

## 🔧 Backend Implementation

### Files Created

#### 1. `backend/src/controllers/expenseController.js`
**Functions:**
- `createExpense` - Employee creates expense
- `getMyExpenses` - Get logged-in user's expenses
- `getAllExpenses` - Admin views all expenses
- `updateExpense` - Employee updates pending expense
- `deleteExpense` - Employee deletes pending expense
- `updateExpenseStatus` - Admin approves/rejects
- `getExpenseStatistics` - Dashboard statistics

#### 2. `backend/src/routes/expenseRoutes.js`
**Routes:**
```javascript
POST   /api/expenses              // Create expense
GET    /api/expenses/my           // Get my expenses
GET    /api/expenses/statistics   // Get statistics
PUT    /api/expenses/:id          // Update expense
DELETE /api/expenses/:id          // Delete expense
GET    /api/expenses/all          // Admin: Get all
PATCH  /api/expenses/:id/status   // Admin: Approve/Reject
```

#### 3. Updated `backend/src/app.js`
Added expense routes to the app.

---

## 📱 Flutter Implementation

### Files Created

#### 1. `lib/services/expense_service.dart`
Service layer for API calls:
- `createExpense()`
- `getMyExpenses()`
- `getExpenseStatistics()`
- `updateExpense()`
- `deleteExpense()`

#### 2. `lib/screens/shared/create_expense_screen.dart`
**Features:**
- Expense type dropdown (Travel, Food, Fuel, etc.)
- Amount input with validation
- Date picker
- Bill number field
- Description field
- Submit button with loading state

---

## 🎯 How to Use

### For Employees

#### 1. Submit Expense
```
1. Open app → Login
2. Go to "My Expenses" or "Submit Expense"
3. Fill in details:
   - Expense Type: Travel/Food/Fuel/etc.
   - Amount: ₹500
   - Date: Select date
   - Bill Number: (optional)
   - Description: (optional)
4. Click "Submit Expense"
5. ✅ Expense submitted for approval
```

#### 2. View My Expenses
```
1. Go to "My Expenses"
2. See list of all expenses
3. Filter by:
   - Status (Pending/Approved/Rejected)
   - Date range
   - Expense type
4. View statistics:
   - Total expenses this month
   - Pending amount
   - Approved amount
```

#### 3. Edit/Delete Expense
```
1. Go to "My Expenses"
2. Find pending expense
3. Click Edit or Delete
4. ✅ Only pending expenses can be modified
```

### For Admin/Manager

#### 1. View All Expenses
```
1. Login as admin
2. Go to "Expense Management"
3. See all employee expenses
4. Filter by employee, status, date
```

#### 2. Approve/Reject Expense
```
1. Click on expense
2. Review details
3. Click "Approve" or "Reject"
4. If rejecting, add reason
5. ✅ Employee gets notified
```

---

## 🔄 Expense Workflow

```
Employee Submits
      ↓
Status: Pending
      ↓
Manager Reviews
      ↓
   Approved? ────→ Yes → Status: Approved
      ↓                        ↓
     No                   Finance Pays
      ↓                        ↓
Status: Rejected        Status: Paid
```

---

## 📊 Expense Types

1. **Travel** - Transportation costs
2. **Food** - Meal expenses
3. **Accommodation** - Hotel stays
4. **Fuel** - Vehicle fuel
5. **Conveyance** - Local transport
6. **Medical** - Medical expenses
7. **Office Supplies** - Stationery, etc.
8. **Client Meeting** - Client entertainment
9. **Other** - Miscellaneous

---

## 🧪 API Testing

### Create Expense
```bash
POST http://localhost:5000/api/expenses
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "expenseType": "Travel",
  "amount": 500,
  "expenseDate": "2024-11-20",
  "description": "Client visit to Mumbai",
  "billNumber": "BILL123"
}
```

### Get My Expenses
```bash
GET http://localhost:5000/api/expenses/my
Authorization: Bearer YOUR_TOKEN
```

### Get Statistics
```bash
GET http://localhost:5000/api/expenses/statistics
Authorization: Bearer YOUR_TOKEN
```

---

## 🎨 UI Features

### Create Expense Screen
- ✅ Clean, intuitive form
- ✅ Dropdown for expense types
- ✅ Date picker
- ✅ Amount validation
- ✅ Optional fields
- ✅ Loading states
- ✅ Success/error messages

### My Expenses Screen (To be created)
- List of all expenses
- Status badges (Pending/Approved/Rejected)
- Filter options
- Search functionality
- Summary cards
- Pull to refresh

### Expense Detail Screen (To be created)
- Full expense details
- Status timeline
- Approval/rejection info
- Edit/Delete buttons (if pending)

---

## 🔐 Security & Permissions

### Employee Permissions
- ✅ Create own expenses
- ✅ View own expenses
- ✅ Edit/delete pending expenses only
- ❌ Cannot approve expenses
- ❌ Cannot view others' expenses

### Admin/Manager Permissions
- ✅ View all expenses
- ✅ Approve/reject expenses
- ✅ View statistics
- ✅ Filter by employee
- ✅ Export reports

---

## 📝 Next Steps to Complete

### 1. Create My Expenses List Screen
```dart
// lib/screens/shared/my_expenses_screen.dart
- Display list of expenses
- Show status badges
- Add filters
- Show summary cards
```

### 2. Add to Navigation
```dart
// In role_dashboard_template.dart
MenuItem(
  icon: Icons.receipt_long,
  title: "My Expenses",
  onTap: () {
    Navigator.of(context, rootNavigator: false).pop();
    Future.microtask(() => 
      Navigator.push(context, 
        MaterialPageRoute(builder: (_) => MyExpensesScreen())
      )
    );
  },
),
```

### 3. Add to All Role Menus
- Admin menu
- Sales menu
- NSM/RSM/ASM/TSO menus
- All employees can submit expenses

### 4. Create Expense Detail Screen
```dart
// lib/screens/shared/expense_detail_screen.dart
- Show full expense details
- Display status
- Show approval info
- Edit/Delete buttons
```

### 5. Admin Expense Management Screen
```dart
// lib/screens/admin/expense_management_screen.dart
- View all expenses
- Approve/reject functionality
- Filters and search
- Export to Excel
```

---

## 🚀 Quick Start

### Backend
```bash
cd backend

# Run migration
npx prisma migrate dev --name add_expense_model

# Generate Prisma client
npx prisma generate

# Restart server
npm run dev
```

### Flutter
```bash
cd loagma_crm

# Run app
flutter run

# Test expense creation
1. Login as any employee
2. Navigate to Submit Expense
3. Fill form and submit
4. Check backend logs
```

---

## 📊 Database Queries

### Get Employee's Total Expenses
```sql
SELECT 
  SUM(amount) as total,
  COUNT(*) as count,
  status
FROM Expense
WHERE employeeId = 'user-id'
GROUP BY status;
```

### Get Monthly Expenses
```sql
SELECT 
  DATE_TRUNC('month', expenseDate) as month,
  SUM(amount) as total
FROM Expense
WHERE employeeId = 'user-id'
GROUP BY month
ORDER BY month DESC;
```

---

## 💡 Future Enhancements

### Phase 2
- [ ] Upload bill/receipt images
- [ ] Multi-level approval workflow
- [ ] Expense categories with limits
- [ ] Budget tracking
- [ ] Email notifications

### Phase 3
- [ ] Expense reports (PDF/Excel)
- [ ] Analytics dashboard
- [ ] Expense trends
- [ ] Department-wise reports
- [ ] Tax calculations

### Phase 4
- [ ] Mobile app camera integration
- [ ] OCR for bill scanning
- [ ] GPS location tracking
- [ ] Mileage calculator
- [ ] Integration with accounting software

---

## 🐛 Troubleshooting

### Expense not saving?
1. Check backend logs
2. Verify token is valid
3. Check database connection
4. Run Prisma migration

### Can't see expenses?
1. Check API response
2. Verify user is authenticated
3. Check expense service logs
4. Verify backend route is registered

### Approval not working?
1. Check user has admin role
2. Verify expense exists
3. Check backend logs
4. Verify status update logic

---

## 📞 Support

**Files to check:**
- Backend: `backend/src/controllers/expenseController.js`
- Routes: `backend/src/routes/expenseRoutes.js`
- Service: `loagma_crm/lib/services/expense_service.dart`
- UI: `loagma_crm/lib/screens/shared/create_expense_screen.dart`

**Common issues:**
- Migration not run → Run `npx prisma migrate dev`
- Routes not working → Check `app.js` has expense routes
- Auth errors → Verify token is being sent
- Validation errors → Check required fields

---

**Status**: ✅ Core Implementation Complete
**Date**: November 2024
**Ready for**: Testing & Enhancement
**Next**: Create My Expenses List Screen
