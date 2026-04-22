# Transaction History Debugging Guide

## Issue
Transaction history not showing in the app.

## Backend Status
✅ **Backend API is working correctly**

Test result:
```powershell
Invoke-RestMethod -Uri "http://localhost:5000/transaction-crm/history/004d8d81-6b16-4cbe-a94a-1b2d9c5d2f21"
```

Response: 3 transactions found ✅

## Debug Logging Added

I've added comprehensive logging to help identify the issue:

### In _loadTransactions():
```
📊 Loading transactions for account: [accountId]
🌐 Fetching from: [url]
📡 Response status: [status]
📡 Response body: [body]
✅ Decoded data: [data]
✅ Loaded [count] transactions
✅ State updated with transactions
✅ Loading complete. Transactions count: [count]
```

### In Transaction Section:
```
🔍 Rendering transaction section
🔍 Transactions count: [count]
🔍 Is loading: [true/false]
```

## How to Debug

### Step 1: Check Flutter Logs
Run the app and look for these messages in the terminal:

1. **On app start:**
   ```
   📊 Loading transactions for account: ...
   🌐 Fetching from: http://...
   📡 Response status: 200
   ✅ Loaded 3 transactions
   ```

2. **When clicking Transaction tab:**
   ```
   🔍 Rendering transaction section
   🔍 Transactions count: 3
   🔍 Is loading: false
   ```

### Step 2: Check for Errors

**If you see:**
```
❌ Cannot load transactions: account is null
```
→ Account data not passed to screen

**If you see:**
```
❌ Cannot load transactions: accountId is null
```
→ Account doesn't have id or accountCode field

**If you see:**
```
❌ HTTP error: 404
```
→ Backend route not found or server not running

**If you see:**
```
❌ Error loading transactions: [error]
```
→ Network error or parsing error

### Step 3: Verify UI

1. **Open Order Details screen**
2. **Look for three tabs at bottom:**
   - Order History
   - Order Funnel
   - Transaction ← Click this

3. **Transaction tab should show:**
   - If loading: Spinner
   - If empty: "No transactions available yet."
   - If loaded: List of transactions

### Step 4: Check Account ID

Make sure you're testing with an account that has transactions:

**Account with transactions:**
- ID: `004d8d81-6b16-4cbe-a94a-1b2d9c5d2f21`
- Has 3 transactions ✅

**To check in database:**
```bash
cd backend
node check-visit-data.js
```

## Common Issues

### Issue 1: Backend Not Running
**Symptom:** Network error in logs
**Solution:**
```bash
cd backend
npm run dev
```

### Issue 2: Wrong Account
**Symptom:** "No transactions available yet."
**Solution:** Test with account ID: `004d8d81-6b16-4cbe-a94a-1b2d9c5d2f21`

### Issue 3: Not Clicking Transaction Tab
**Symptom:** Not seeing transactions
**Solution:** Click the "Transaction" tab at the bottom

### Issue 4: API URL Wrong
**Symptom:** 404 error
**Solution:** Check `ApiConfig.baseUrl` in `api_config.dart`

## Expected Behavior

### When Transaction Tab is Clicked:

1. **Loading State:**
   ```
   Transaction History              [3 visits]
   
   [Loading spinner]
   ```

2. **Loaded State:**
   ```
   Transaction History              [3 visits]
   
   ┌─────────────────────────────────┐
   │ Visit #3            [00:00:01]  │
   │ ✓ Visit In: 22/4/2026 16:10    │
   │ ✗ Visit Out: 22/4/2026 16:10   │
   │ ⚡ Order Funnel: Placed order   │
   │ 📝 Notes: Complete test...      │
   │ 📷 Merchandise: 1 + 1 images    │
   └─────────────────────────────────┘
   
   ┌─────────────────────────────────┐
   │ Visit #2            [00:01:38]  │
   │ ...                             │
   └─────────────────────────────────┘
   ```

3. **Empty State:**
   ```
   Transaction History
   
   No transactions available yet.
   ```

## Quick Test

1. **Restart the app:**
   ```bash
   flutter run
   ```

2. **Watch the logs for:**
   ```
   📊 Loading transactions for account: ...
   ✅ Loaded 3 transactions
   ```

3. **Open Order Details for account:** `004d8d81-6b16-4cbe-a94a-1b2d9c5d2f21`

4. **Click "Transaction" tab**

5. **Should see 3 transactions**

## If Still Not Working

Share these logs:
1. The complete output from `📊 Loading transactions...` to `✅ Loading complete`
2. The output from `🔍 Rendering transaction section`
3. Any error messages in red

This will help identify the exact issue!
