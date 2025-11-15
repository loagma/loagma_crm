# 📱 Loagma CRM - User Guide

## 🎯 Quick Start

### Step 1: Open the App
Launch the Loagma CRM app on your device.

### Step 2: Access the Menu
Tap the **☰ menu icon** in the top-left corner to open the drawer.

---

## 📋 Main Features

### 1️⃣ Create Account Master

**Purpose**: Add new customer/account to the system

**Steps**:
1. Open drawer (☰)
2. Tap **"Master"** to expand
3. Select the location level you want to work with:
   - **Country** - If you only need country
   - **State** - If you need up to state
   - **District** - If you need up to district
   - **City** - If you need up to city
   - **Zone** - If you need up to zone
   - **Area** - If you need complete location (recommended)

4. **Select Locations** (cascading dropdowns):
   ```
   Country: India
     ↓
   State: Madhya Pradesh
     ↓
   District: Jabalpur
     ↓
   City: Jabalpur City
     ↓
   Zone: Zone A
     ↓
   Area: Ranjhi
   ```

5. Tap **"Next: Account Master Details"**

6. **Fill Account Information**:
   - **Person Name** ⭐ (Required)
   - **Contact Number** ⭐ (Required, 10 digits)
   - **Date of Birth** (Optional - tap to select)
   - **Business Type** (Optional - e.g., Retail, Wholesale)
   - **Customer Stage** (Optional):
     - Lead - New potential customer
     - Prospect - Interested customer
     - Customer - Confirmed customer
   - **Funnel Stage** (Optional):
     - Awareness - Just aware of product
     - Interest - Showing interest
     - Converted - Made a purchase

7. Tap **"Submit"**

8. ✅ **Success!** You'll see:
   - Success message
   - Auto-generated account code (e.g., ACC2411001)
   - Form resets for next entry

**Tips**:
- ⭐ = Required fields
- Account code is automatically generated
- Contact number must be unique
- You can tap "Clear" to reset the form

---

### 2️⃣ View All Account Masters

**Purpose**: See all created accounts, search, filter, and manage them

**Steps**:
1. Open drawer (☰)
2. Tap **"View All Account Masters"**

**What You Can Do**:

#### 🔍 Search Accounts
- Tap the search bar at the top
- Type:
  - Person name (e.g., "Rajesh")
  - Account code (e.g., "ACC2411001")
  - Contact number (e.g., "9876543210")
- Results update instantly

#### 🎯 Filter by Stage
- Tap the filter dropdown
- Select:
  - **All** - Show all accounts
  - **Lead** - Show only leads
  - **Prospect** - Show only prospects
  - **Customer** - Show only customers

#### 👁️ View Account Details
- **Option 1**: Tap on any account card
- **Option 2**: Tap menu (⋮) → "View Details"
- See complete information:
  - Account Code
  - Person Name
  - Contact Number
  - Date of Birth
  - Business Type
  - Customer Stage
  - Funnel Stage
  - Created Date

#### 🗑️ Delete Account
1. Tap menu (⋮) on account card
2. Select **"Delete"**
3. Confirmation dialog appears:
   - "Are you sure you want to delete account [Name]?"
4. Tap **"Delete"** to confirm or **"Cancel"** to keep

#### 🔄 Refresh Data
- **Option 1**: Pull down the list
- **Option 2**: Tap refresh icon (🔄) in top-right

**Understanding the Display**:
- **Blue badge** 🔵 = Lead
- **Orange badge** 🟠 = Prospect
- **Green badge** 🟢 = Customer
- **Circle with initial** = First letter of person's name
- **Bottom bar** = Shows total accounts and page number

---

### 3️⃣ Back Button Confirmation

**Purpose**: Prevent accidental data loss

**When It Appears**:
- When you're filling the account form
- You tap the back button (←)

**What Happens**:
1. Dialog appears: "Do you want to go back? Any unsaved changes will be lost."
2. **Two options**:
   - **Cancel** - Stay on the form, continue editing
   - **Yes, Go Back** - Return to location selection (data will be lost)

**Tip**: Always submit your form before going back to save your data!

---

## 🎨 Understanding the Interface

### Color Coding
- **Gold/Amber (#D7BE69)** - Primary theme color
  - Menu icons
  - Buttons
  - Headers
  - Selected items

- **Customer Stage Colors**:
  - 🔵 **Blue** = Lead (new potential customer)
  - 🟠 **Orange** = Prospect (interested customer)
  - 🟢 **Green** = Customer (confirmed customer)

### Icons Guide
- **☰** - Menu (open drawer)
- **←** - Back button
- **🔍** - Search
- **🎯** - Filter
- **⋮** - More options menu
- **👁️** - View details
- **✏️** - Edit (coming soon)
- **🗑️** - Delete
- **🔄** - Refresh
- **✓** - Submit/Confirm
- **✕** - Clear/Cancel

---

## 📊 Account Code Format

**Format**: `ACC + YY + MM + SEQUENCE`

**Examples**:
- `ACC2411001` = November 2024, 1st account of the day
- `ACC2411002` = November 2024, 2nd account of the day
- `ACC2412001` = December 2024, 1st account of the day

**Features**:
- Automatically generated
- Unique for each account
- Includes year and month
- Daily sequence number
- Cannot be changed

---

## ✅ Validation Rules

### Person Name
- ✅ Required
- ✅ Cannot be empty
- ✅ Any characters allowed

### Contact Number
- ✅ Required
- ✅ Must be exactly 10 digits
- ✅ Must be unique (no duplicates)
- ✅ Only numbers allowed
- ❌ Cannot have spaces or special characters

### Date of Birth
- ✅ Optional
- ✅ Must be a past date
- ✅ Use date picker to select

### Business Type
- ✅ Optional
- ✅ Free text field

### Customer Stage
- ✅ Optional
- ✅ Choose from: Lead, Prospect, Customer

### Funnel Stage
- ✅ Optional
- ✅ Choose from: Awareness, Interest, Converted

---

## 🔄 Common Workflows

### Workflow 1: Add New Lead
```
1. Open Menu → Master → Area
2. Select: India → Your State → Your District → Your City → Your Zone → Your Area
3. Tap "Next"
4. Fill:
   - Name: "Amit Sharma"
   - Contact: "9876543210"
   - Customer Stage: "Lead"
   - Funnel Stage: "Awareness"
5. Tap "Submit"
6. ✅ Done! Lead added with code ACC2411001
```

### Workflow 2: Search for Customer
```
1. Open Menu → "View All Account Masters"
2. Tap search bar
3. Type customer name or contact
4. Tap on result to view details
```

### Workflow 3: Filter and Review Leads
```
1. Open Menu → "View All Account Masters"
2. Tap filter dropdown
3. Select "Lead"
4. Review all leads
5. Tap any lead to see details
```

### Workflow 4: Delete Old Account
```
1. Open Menu → "View All Account Masters"
2. Find the account (search if needed)
3. Tap menu (⋮) → "Delete"
4. Confirm deletion
5. ✅ Account removed
```

---

## 💡 Tips & Best Practices

### Creating Accounts
1. ✅ Always fill required fields (marked with ⭐)
2. ✅ Use consistent naming (e.g., "First Last" format)
3. ✅ Double-check contact numbers (must be unique)
4. ✅ Select appropriate customer stage
5. ✅ Add business type for better categorization

### Managing Accounts
1. ✅ Use search to find accounts quickly
2. ✅ Use filters to focus on specific stages
3. ✅ Review account details before deleting
4. ✅ Pull to refresh to see latest data
5. ✅ Keep contact numbers updated

### Data Entry
1. ✅ Complete location selection before proceeding
2. ✅ Save your work by submitting (don't just go back)
3. ✅ Use "Clear" button to start fresh
4. ✅ Verify data before submitting

---

## ❓ Troubleshooting

### "Failed to load countries"
**Solution**: Check your internet connection and try again

### "Contact number already exists"
**Solution**: This contact is already in the system. Use a different number or search for the existing account.

### "Must be 10 digits"
**Solution**: Contact number must be exactly 10 digits, no spaces or special characters

### Dropdown not loading
**Solution**: 
1. Make sure you selected the parent level first
2. Pull down to refresh
3. Check internet connection

### Can't submit form
**Solution**: Check that all required fields (⭐) are filled correctly

---

## 📞 Quick Reference

### Required Fields
- ⭐ Person Name
- ⭐ Contact Number (10 digits)

### Optional Fields
- Date of Birth
- Business Type
- Customer Stage
- Funnel Stage

### Customer Stages
- **Lead** - New potential customer
- **Prospect** - Interested customer
- **Customer** - Confirmed customer

### Funnel Stages
- **Awareness** - Just aware of product
- **Interest** - Showing interest
- **Converted** - Made a purchase

---

## 🎯 Summary

**Main Actions**:
1. **Create Account** - Menu → Master → Select Level → Fill Form → Submit
2. **View Accounts** - Menu → View All Account Masters
3. **Search** - Type in search bar
4. **Filter** - Select from filter dropdown
5. **Delete** - Menu (⋮) → Delete → Confirm

**Remember**:
- ⭐ = Required field
- Account codes are auto-generated
- Contact numbers must be unique
- Always confirm before deleting
- Pull to refresh for latest data

---

**Need Help?** Contact your system administrator.

**Version**: 1.0.0
**Last Updated**: November 2024
