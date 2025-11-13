# Backend Update Instructions for Employee Account Master

## ✅ What Was Done

1. **Updated Prisma Schema** - Added all employee fields to the User model:
   - employeeCode (unique)
   - designation
   - dateOfBirth
   - gender
   - nationality
   - image
   - postUnder
   - jobPost
   - joiningDate
   - preferredLanguages (array)
   - jobPostCode
   - jobPostName
   - inchargeCode
   - inchargeName

## 🔧 What You Need to Do

### Step 1: Run Migration (MANUALLY)

Open a terminal in the `backend` folder and run:

```bash
npx prisma migrate dev --name add_employee_fields
```

When prompted "Are you sure you want to create and apply this migration?", type **`y`** and press Enter.

This will:
- Create a new migration file
- Update your database schema
- Regenerate Prisma Client

### Step 2: Verify Migration

After the migration completes, you should see:
```
✔ Generated Prisma Client
Your database is now in sync with your schema.
```

### Step 3: Update User Controller (Optional)

If you want to create/update employees via API, you'll need to update the user controller to accept these new fields.

**File:** `backend/src/controllers/userController.js`

Add the new fields to the create/update operations:

```javascript
export const createEmployee = async (req, res) => {
  try {
    const {
      employeeCode,
      name,
      email,
      contactNumber,
      designation,
      dateOfBirth,
      gender,
      nationality,
      image,
      departmentId,
      postUnder,
      jobPost,
      joiningDate,
      preferredLanguages,
      jobPostCode,
      jobPostName,
      inchargeCode,
      inchargeName,
      isActive
    } = req.body;

    const employee = await prisma.user.create({
      data: {
        employeeCode,
        name,
        email,
        contactNumber,
        designation,
        dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : null,
        gender,
        nationality,
        image,
        departmentId,
        postUnder,
        jobPost,
        joiningDate: joiningDate ? new Date(joiningDate) : null,
        preferredLanguages,
        jobPostCode,
        jobPostName,
        inchargeCode,
        inchargeName,
        isActive: isActive ?? true
      },
      include: {
        department: true,
        functionalRole: true
      }
    });

    res.status(201).json({ success: true, data: employee });
  } catch (error) {
    console.error('Create Employee Error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};
```

### Step 4: Add Employee Routes (Optional)

**File:** `backend/src/routes/userRoutes.js`

Add employee-specific routes:

```javascript
import { createEmployee, updateEmployee, getEmployees } from '../controllers/userController.js';

router.post('/employees', createEmployee);
router.get('/employees', getEmployees);
router.put('/employees/:id', updateEmployee);
```

### Step 5: Restart Backend Server

After migration, restart your backend server:

```bash
npm run dev
```

## 📋 Summary

**Current Status:**
- ✅ Prisma schema updated with all employee fields
- ⏳ Migration needs to be run manually (interactive command)
- ⏳ User controller needs to be updated to handle new fields
- ⏳ Routes need to be added for employee operations

**Next Steps:**
1. Run the migration command manually
2. Update user controller (optional, for API support)
3. Add employee routes (optional)
4. Test the Employee Account Master form

## 🎯 Form Fields Mapping

| Form Field | Database Field | Type |
|------------|---------------|------|
| Employee Code | employeeCode | String (unique) |
| Employee Name | name | String |
| Contact Number | contactNumber | String (unique) |
| Email ID | email | String (unique) |
| Designation | designation | String |
| Date of Birth | dateOfBirth | DateTime |
| Gender | gender | String |
| Nationality | nationality | String |
| Image | image | String (URL) |
| Department | departmentId | String (FK) |
| Post Under | postUnder | String |
| Job Post | jobPost | String |
| Joining Date | joiningDate | DateTime |
| Active | isActive | Boolean |
| Preferred Languages | preferredLanguages | String[] |
| Job Post Code | jobPostCode | String |
| Job Post Name | jobPostName | String |
| Incharge Code | inchargeCode | String |
| Incharge Name | inchargeName | String |

All fields are now supported in the database schema!
