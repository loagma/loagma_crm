# 🚀 How to Test the Task Assignment Module

## Method 1: Run the App (Easiest)

### On Android Emulator:
```bash
cd loagma_crm
flutter run -d emulator-5554
```

### On Windows Desktop:
```bash
cd loagma_crm
flutter run -d windows
```

### On Chrome Browser:
```bash
cd loagma_crm
flutter run -d chrome
```

---

## 📱 Step-by-Step Testing Guide

### Step 1: Login to the App
1. Launch the app
2. Login with your credentials
3. You'll be redirected to the dashboard

### Step 2: Navigate to Task Assignment

**Option A: Direct URL (if running on web)**
```
http://localhost:port/#/dashboard/admin/task-assignment
```

**Option B: Add a Test Button (Temporary)**

Open your dashboard file and add this button:

```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFFD7BE69),
  ),
  onPressed: () {
    context.go('/dashboard/admin/task-assignment');
  },
  child: Text('Task Assignment'),
)
```

**Option C: Add to Sidebar Menu**

If you have a sidebar, add this menu item:

```dart
ListTile(
  leading: Icon(Icons.assignment, color: Color(0xFFD7BE69)),
  title: Text('Task Assignment'),
  onTap: () {
    Navigator.pop(context); // Close drawer if any
    context.go('/dashboard/admin/task-assignment');
  },
)
```

### Step 3: Test the Features

Once you're on the Task Assignment screen, you should see:

#### 🎨 UI Elements:
- **Header**: "Assign Pin-Code Areas to Salesmen"
- **Dropdown**: "Select Salesman" with 3 mock salesmen
- **Input Field**: "Enter Pin Code" (6-digit)
- **Assign Button**: Golden color (#D7BE69)

#### ✅ Test Scenarios:

**Test 1: Select a Salesman**
1. Click the dropdown
2. You should see 3 salesmen:
   - Rajesh Kumar (EMP001) - 2 pin codes
   - Priya Sharma (EMP002) - 1 pin code
   - Amit Patel (EMP003) - 0 pin codes
3. Select any salesman

**Test 2: Assign a Pin Code**
1. Select "Rajesh Kumar"
2. Enter pin code: `400001`
3. Click "Assign" button
4. ✅ Success dialog should appear
5. ✅ Pin code should appear in the list below

**Test 3: Validation**
1. Try entering invalid pin codes:
   - `123` (too short) ❌
   - `abcdef` (not numeric) ❌
   - `1234567` (too long) ❌
2. Try assigning without selecting salesman ❌
3. Try assigning duplicate pin code ❌

**Test 4: View Assigned Pin Codes**
1. Select "Rajesh Kumar"
2. You should see 2 existing pin codes:
   - 400001
   - 400002
3. Each pin code has a delete icon

**Test 5: Remove Pin Code**
1. Click the delete icon on any pin code
2. Confirmation dialog appears
3. Click "Remove"
4. ✅ Pin code is removed from the list

**Test 6: Multiple Assignments**
1. Select "Amit Patel" (has 0 pin codes)
2. Assign multiple pin codes:
   - 400010
   - 400011
   - 400012
3. All should appear in the list

---

## 🔍 What You Should See

### Initial Screen:
```
┌─────────────────────────────────────┐
│ ← Task Assignment                   │
├─────────────────────────────────────┤
│ Assign Pin-Code Areas to Salesmen  │
│                                     │
│ Select Salesman                     │
│ ┌─────────────────────────────────┐ │
│ │ Choose a salesman          ▼    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Enter Pin Code                      │
│ ┌──────────────────┐ ┌──────────┐  │
│ │ 📍 Enter 6-digit │ │ Assign   │  │
│ └──────────────────┘ └──────────┘  │
└─────────────────────────────────────┘
```

### After Selecting Salesman:
```
┌─────────────────────────────────────┐
│ Assigned Pin Codes        [2 areas] │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ 📍 Pin Code: 400001             │ │
│ │    Assigned to Rajesh Kumar  🗑️ │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 📍 Pin Code: 400002             │ │
│ │    Assigned to Rajesh Kumar  🗑️ │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Success Dialog:
```
┌─────────────────────────────────────┐
│ ✅ Success!                         │
├─────────────────────────────────────┤
│ Pin code 400001 has been            │
│ successfully assigned to:           │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 👤 Rajesh Kumar                 │ │
│ │    9876543210                   │ │
│ └─────────────────────────────────┘ │
│                                     │
│                            [  OK  ] │
└─────────────────────────────────────┘
```

---

## 🐛 Troubleshootin

### Issue: Can't find the screen
**Solution**: Make sure you're navigating to the correct route:
```dart
context.go('/dashboard/admin/task-assignment');
```

### Issue: App won't build
**Solution**: Clean and rebuild:
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: Route not found
**Solution**: Check that `app_router.dart` has the route registered:
```dart
GoRoute(
  path: 'task-assignment',
  builder: (_, __) => const TaskAssignmentScreen(),
),
```

### Issue: Import errors
**Solution**: Make sure all files are saved and run:
```bash
flutter pub get
```

---

## 📊 Expected Behavior

✅ **Loading State**: Shows spinner while fetching salesmen  
✅ **Dropdown**: Lists all salesmen with avatar and contact  
✅ **Validation**: Prevents invalid pin codes  
✅ **Assignment**: Shows success dialog and updates list  
✅ **Removal**: Confirms before removing pin code  
✅ **Empty State**: Shows "No pin codes assigned" message  
✅ **Toast Messages**: Shows feedback for all actions  

---

## 🎥 Quick Demo Flow

1. **Launch app** → Login
2. **Navigate** → `/dashboard/admin/task-assignment`
3. **Select** → "Rajesh Kumar" from dropdown
4. **See** → 2 existing pin codes (400001, 400002)
5. **Enter** → New pin code "400003"
6. **Click** → "Assign" button
7. **See** → Success dialog
8. **Verify** → Pin code 400003 appears in list
9. **Click** → Delete icon on 400003
10. **Confirm** → Click "Remove" in dialog
11. **Verify** → Pin code removed from list

---

## 📝 Notes

- Currently using **mock data** (3 salesmen)
- All assignments are **local only** (not saved to backend)
- Ready for **backend integration** (see `task_assignment_service.dart`)
- **No existing features** were modified or broken
- **Theme colors** match your app (#D7BE69)

---

## 🔗 Quick Links

- **Main Screen**: `lib/screens/admin/task_assignment_screen.dart`
- **Service**: `lib/services/task_assignment_service.dart`
- **Models**: `lib/models/salesman_model.dart`, `lib/models/pincode_assignment_model.dart`
- **Route**: `lib/router/app_router.dart`

---

**Ready to test!** 🚀
