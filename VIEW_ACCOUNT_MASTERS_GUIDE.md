# 📋 How to View Saved Account Masters

## Where to Find Your Saved Accounts

You can view all saved account master details in **3 different ways**:

### Method 1: From Account Master Screen (NEW! ✨)
1. Open any dashboard (Admin, NSM, RSM, etc.)
2. Click on **"Account Master"** from the sidebar
3. Look at the **top-right corner** of the screen
4. Click the **list icon** (📋) button
5. You'll see the "View All Accounts" screen

### Method 2: From Sidebar Menu (NEW! ✨)
1. Open any dashboard
2. Open the sidebar (hamburger menu)
3. Click on **"View All Accounts"** menu item
4. You'll see all saved accounts

### Method 3: Direct Navigation
Navigate to the ViewAllMastersScreen directly from code

## What You'll See

### View All Accounts Screen Features:

#### 🔍 Search Bar
- Search by name, account code, or contact number
- Real-time search as you type

#### 🎯 Filter Dropdown
- Filter by Customer Stage:
  - All
  - Lead
  - Prospect
  - Customer

#### 📱 Account Cards
Each account shows:
- **Avatar** with first letter of name
- **Person Name** (bold)
- **Account Code**
- **Contact Number**
- **Customer Stage** (colored badge)
  - Lead = Blue
  - Prospect = Orange
  - Customer = Green

#### ⚙️ Actions Menu (3 dots)
For each account:
- **View Details** - See full account information
- **Edit** - Coming soon
- **Delete** - Remove account (with confirmation)

#### 📊 Summary Footer
- Shows total number of accounts
- Current page number

## Account Details Dialog

When you click "View Details" or tap an account card, you'll see:

```
┌─────────────────────────────────┐
│  Account Details                │
├─────────────────────────────────┤
│  Account Code:    ACC001        │
│  Person Name:     John Doe      │
│  Contact Number:  +919999999999 │
│  Date of Birth:   15/01/1990    │
│  Business Type:   Retail        │
│  Customer Stage:  Customer      │
│  Funnel Stage:    Converted     │
│  Created At:      17/11/2024    │
└─────────────────────────────────┘
```

## Features Implemented

### ✅ Search Functionality
- Search across name, code, and contact
- Instant results as you type
- Clear search to see all accounts

### ✅ Filter by Stage
- Quick filter dropdown
- Shows only accounts matching selected stage
- "All" option to see everything

### ✅ Delete with Confirmation
- Click delete from menu
- Confirmation dialog appears
- Cancel shows "Delete cancelled" toast
- Confirm deletes and shows success message

### ✅ Refresh
- Pull down to refresh (on mobile)
- Refresh icon in AppBar
- Auto-refresh after delete

### ✅ Empty State
- Shows friendly message when no accounts found
- Suggests creating first account

### ✅ Pagination Ready
- Supports page-based loading
- Shows current page in footer
- Ready for "Load More" feature

## Navigation Paths

### From Admin Dashboard:
```
Admin Dashboard
├── Sidebar → Account Master → List Icon (top-right)
└── Sidebar → View All Accounts
```

### From Other Dashboards (NSM, RSM, ASM, TSO):
```
Dashboard
├── Sidebar → Account Master → List Icon (top-right)
└── Sidebar → View All Accounts
```

## API Integration

### Endpoint Used:
```
GET /accounts?page=1&limit=20&search=...&customerStage=...
```

### Response Structure:
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "accountCode": "ACC001",
      "personName": "John Doe",
      "contactNumber": "+919999999999",
      "dateOfBirth": "1990-01-15",
      "businessType": "Retail",
      "customerStage": "Customer",
      "funnelStage": "Converted",
      "createdAt": "2024-11-17T10:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 50
  }
}
```

## Testing Steps

### 1. Create Some Accounts
1. Go to Account Master
2. Fill in the form
3. Click "Create Account"
4. Repeat 2-3 times

### 2. View All Accounts
1. Click the list icon (top-right) OR
2. Click "View All Accounts" from sidebar
3. You should see all created accounts

### 3. Test Search
1. Type a name in search bar
2. See filtered results
3. Clear search to see all

### 4. Test Filter
1. Select "Lead" from dropdown
2. See only Lead accounts
3. Select "All" to see everything

### 5. Test View Details
1. Click on an account card OR
2. Click 3-dot menu → View Details
3. See full account information

### 6. Test Delete
1. Click 3-dot menu → Delete
2. Confirmation dialog appears
3. Click Cancel → See "Delete cancelled" toast
4. Click Delete again → Confirm → Account removed

## Troubleshooting

### No Accounts Showing?
- Check if you've created any accounts
- Check internet connection
- Verify backend is running
- Check browser console for errors

### Search Not Working?
- Make sure you're typing in the search field
- Search works on name, code, and contact
- Try clearing and searching again

### Delete Not Working?
- Check if you have permission
- Verify backend is running
- Check for error messages

## Files Modified

1. **account_master_screen.dart**
   - Added "View All" button in AppBar
   - Imports ViewAllMastersScreen

2. **role_dashboard_template.dart**
   - Added "View All Accounts" menu item
   - Imports ViewAllMastersScreen

3. **view_all_masters_screen.dart**
   - Fixed type error: `accounts = data['accounts']`
   - Now correctly extracts List<Account> from Map

## Summary

✅ View All Accounts accessible from 2 places:
   - Account Master screen (list icon)
   - Sidebar menu (View All Accounts)

✅ Features working:
   - Search by name/code/contact
   - Filter by customer stage
   - View full details
   - Delete with confirmation
   - Refresh functionality

✅ Professional UI:
   - Card-based layout
   - Color-coded stages
   - Empty state message
   - Summary footer

**You can now easily view and manage all your saved account masters! 🎉**
