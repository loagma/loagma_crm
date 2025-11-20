# Salary Management System - Quick Start Guide

## Overview
A comprehensive salary and allowance management system integrated into the Loagma CRM. This system helps monitor company expenses including travel allowances, daily allowances, and other compensation components.

## Features

### 1. Salary Components
- **Basic Salary**: Core compensation
- **HRA (House Rent Allowance)**: Housing support
- **Travel Allowance**: Transportation expenses
- **Daily Allowance**: Per diem expenses
- **Medical Allowance**: Healthcare support
- **Special Allowance**: Additional compensation
- **Other Allowances**: Miscellaneous benefits

### 2. Deductions
- **Provident Fund (PF)**: Retirement savings
- **Professional Tax**: State tax
- **Income Tax (TDS)**: Tax deducted at source
- **Other Deductions**: Miscellaneous deductions

### 3. Automatic Calculations
- Gross Salary (sum of all allowances)
- Total Deductions (sum of all deductions)
- Net Salary (gross - deductions)

### 4. Expense Monitoring
- Total company expenses by category
- Department-wise expense breakdown
- Travel and daily allowance tracking
- Average salary statistics

## How to Use

### For Administrators

#### 1. Access Salary Management
1. Login to the admin dashboard
2. Click on "Salary Management" from the sidebar menu
3. View the statistics dashboard showing:
   - Total employees with salary information
   - Total gross salary expenses
   - Total travel allowances
   - Total daily allowances

#### 2. Add New Salary Information
1. Click the "Add Salary" floating button
2. Select the employee from the dropdown
3. Fill in salary components:
   - Enter basic salary (required)
   - Add allowances (travel, daily, medical, etc.)
   - Enter deductions (PF, tax, etc.)
4. View real-time calculation of:
   - Gross Salary
   - Total Deductions
   - Net Salary
5. Add bank details (optional):
   - Bank name
   - Account number
   - IFSC code
   - PAN number
6. Set effective date (required)
7. Add remarks if needed
8. Click "Save Salary Information"

#### 3. Edit Existing Salary
1. Find the employee in the salary list
2. Click the edit icon (blue pencil)
3. Modify the required fields
4. Save changes

#### 4. Delete Salary Information
1. Find the employee in the salary list
2. Click the delete icon (red trash)
3. Confirm deletion

#### 5. Search and Filter
- Use the search bar to find employees by:
  - Name
  - Employee code
  - Email address

### For Expense Monitoring

#### View Company Expenses
The statistics cards at the top show:
- **Total Employees**: Number of employees with salary data
- **Total Gross Salary**: Sum of all gross salaries
- **Travel Allowance**: Total travel expenses
- **Daily Allowance**: Total daily expenses

#### Department-wise Analysis
The backend API provides department-wise breakdown:
```
GET /salaries/statistics
```
Returns expenses grouped by department.

#### Salary Range Analysis
Filter employees by salary range:
```
GET /salaries?minSalary=40000&maxSalary=60000
```

## Database Schema

### SalaryInformation Table
```
- id: Unique identifier
- employeeId: Reference to employee (unique)
- basicSalary: Base salary amount
- hra: House rent allowance
- travelAllowance: Travel expenses
- dailyAllowance: Daily expenses
- medicalAllowance: Medical benefits
- specialAllowance: Special compensation
- otherAllowances: Other benefits
- providentFund: PF deduction
- professionalTax: Professional tax
- incomeTax: Income tax (TDS)
- otherDeductions: Other deductions
- effectiveFrom: Start date
- effectiveTo: End date (optional)
- currency: Currency code (default: INR)
- paymentFrequency: Monthly/Quarterly/Annually
- bankName: Employee's bank
- accountNumber: Account number
- ifscCode: Bank IFSC code
- panNumber: PAN card number
- remarks: Additional notes
- isActive: Active status
- createdAt: Creation timestamp
- updatedAt: Last update timestamp
```

## API Endpoints

### Backend Routes
All salary routes are prefixed with `/salaries`:

1. **POST /salaries** - Create or update salary
2. **GET /salaries** - Get all salaries (with filters)
3. **GET /salaries/statistics** - Get expense statistics
4. **GET /salaries/:employeeId** - Get salary by employee ID
5. **DELETE /salaries/:employeeId** - Delete salary information

### Flutter Routes
- `/salary-list` - Salary list screen
- `/salary-form` - Salary form screen (add/edit)

## Files Created/Modified

### Backend
- `backend/prisma/schema.prisma` - Added SalaryInformation model
- `backend/src/controllers/salaryController.js` - Salary business logic
- `backend/src/routes/salaryRoutes.js` - API routes
- `backend/src/app.js` - Added salary routes
- `backend/SALARY_API_DOCUMENTATION.md` - API documentation

### Frontend (Flutter)
- `loagma_crm/lib/services/salary_service.dart` - API service
- `loagma_crm/lib/screens/admin/salary_list_screen.dart` - List view
- `loagma_crm/lib/screens/admin/salary_form_screen.dart` - Form view
- `loagma_crm/lib/utils/currency_formatter.dart` - Currency formatting
- `loagma_crm/lib/main.dart` - Added routes
- `loagma_crm/lib/widgets/role_dashboard_template.dart` - Added menu item
- `loagma_crm/pubspec.yaml` - Added intl dependency

## Migration

The database migration has been applied:
```
20251120092724_add_salary_information
```

## Testing

### Test the Backend API
```bash
# Get all salaries
curl http://localhost:5000/salaries

# Get statistics
curl http://localhost:5000/salaries/statistics

# Create salary
curl -X POST http://localhost:5000/salaries \
  -H "Content-Type: application/json" \
  -d '{
    "employeeId": "employee_id_here",
    "basicSalary": 50000,
    "travelAllowance": 5000,
    "dailyAllowance": 2000,
    "effectiveFrom": "2024-01-01"
  }'
```

### Test the Flutter App
1. Run the app: `flutter run`
2. Login as admin
3. Navigate to "Salary Management"
4. Add/edit/view salary information

## Benefits

### For HR/Admin
- Centralized salary management
- Easy tracking of all compensation components
- Historical salary data with effective dates
- Bank details for payroll processing

### For Finance
- Real-time expense monitoring
- Department-wise cost analysis
- Travel and daily allowance tracking
- Budget planning and forecasting

### For Management
- Company-wide salary statistics
- Average compensation metrics
- Department performance vs cost
- Expense optimization insights

## Security Considerations

1. **Access Control**: Only admins can access salary management
2. **Data Privacy**: Salary information is sensitive - ensure proper authentication
3. **Audit Trail**: All changes are timestamped (createdAt, updatedAt)
4. **Soft Delete**: Consider implementing soft delete for audit purposes

## Future Enhancements

1. **Salary History**: Track salary changes over time
2. **Payslip Generation**: Auto-generate monthly payslips
3. **Tax Calculations**: Automatic tax computation
4. **Bonus Management**: Track bonuses and incentives
5. **Attendance Integration**: Link with attendance for deductions
6. **Export Reports**: Excel/PDF export for salary reports
7. **Email Notifications**: Send payslips via email
8. **Approval Workflow**: Multi-level approval for salary changes

## Support

For issues or questions:
1. Check the API documentation: `backend/SALARY_API_DOCUMENTATION.md`
2. Review the database schema in `backend/prisma/schema.prisma`
3. Check Flutter diagnostics for frontend issues

## Summary

The salary management system is now fully integrated with:
- ✅ Database schema with comprehensive fields
- ✅ Backend API with CRUD operations
- ✅ Statistics and expense monitoring endpoints
- ✅ Flutter UI with list and form screens
- ✅ Real-time salary calculations
- ✅ Search and filter capabilities
- ✅ Department-wise analytics
- ✅ Currency formatting
- ✅ Admin dashboard integration
- ✅ Proper routing and navigation
