# Expense Management Feature - Access Guide

## Where to Find the Expense Screen

### File Location
**Path:** `loagma_crm/lib/screens/shared/create_expense_screen.dart`

### How Employees Can Access It

All employees can now submit expenses through their dashboard menu:

1. **Login** to the app with your credentials
2. **Open the side menu** (tap the menu icon in the top-right)
3. **Tap "Submit Expense"** - it appears right after "Account Master"

### Available for All Roles
- ✅ Admin
- ✅ Sales
- ✅ NSM (National Sales Manager)
- ✅ RSM (Regional Sales Manager)
- ✅ ASM (Area Sales Manager)
- ✅ TSO (Territory Sales Officer)
- ✅ Telecaller
- ✅ All other roles

### Features
- Select expense type (Travel, Food, Fuel, Accommodation, etc.)
- Enter amount
- Choose expense date
- Add bill/receipt number (optional)
- Add description (optional)
- Submit for approval

### Backend API
The expense data is sent to: `POST /api/expenses`

### Database
Expenses are stored in the `Expense` table with fields:
- expenseType
- amount
- expenseDate
- description
- billNumber
- status (PENDING, APPROVED, REJECTED)
- userId (who submitted it)

## Navigation Integration
The expense screen has been added to the role dashboard template at:
`loagma_crm/lib/widgets/role_dashboard_template.dart`

All role menus now include the "Submit Expense" option with the receipt icon.
