# Salary Management - Quick Reference Card

## 🚀 Quick Start

### Access the Feature
1. Login as **Admin**
2. Click **"Salary Management"** from sidebar
3. View statistics and salary list

### Add Salary
1. Click **"Add Salary"** button (bottom right)
2. Select employee
3. Enter amounts
4. Save

## 📊 What You Can Track

### Allowances (Income)
- Basic Salary ✅
- HRA (House Rent)
- Travel Allowance 🚗
- Daily Allowance 📅
- Medical Allowance 🏥
- Special Allowance ⭐
- Other Allowances

### Deductions
- Provident Fund (PF)
- Professional Tax
- Income Tax (TDS)
- Other Deductions

### Calculations (Automatic)
- **Gross Salary** = All allowances
- **Total Deductions** = All deductions
- **Net Salary** = Gross - Deductions

## 🔍 Search & Filter

### Search By
- Employee name
- Employee code
- Email address

### Filter By
- Department
- Active status
- Salary range

## 📈 Statistics Available

### Main Dashboard Shows
1. **Total Employees** - Count with salary data
2. **Total Gross Salary** - Company expense
3. **Total Travel Allowance** - Travel costs
4. **Total Daily Allowance** - Daily costs

### API Statistics Include
- Department-wise breakdown
- Average salaries
- Total deductions
- Net payroll

## 🔗 API Endpoints

```
POST   /salaries                 Create/Update
GET    /salaries                 Get All (with filters)
GET    /salaries/statistics      Get Statistics
GET    /salaries/:employeeId     Get by Employee
DELETE /salaries/:employeeId     Delete
```

## 💡 Pro Tips

### For Expense Monitoring
- Check statistics dashboard regularly
- Use department filter for cost centers
- Export data for budget planning
- Track travel allowance trends

### For Salary Management
- Set effective dates for changes
- Add remarks for audit trail
- Keep bank details updated
- Mark inactive for historical records

### For Data Entry
- All amounts auto-calculate
- Basic salary is required
- Other fields are optional
- Effective date is required

## 🎯 Common Tasks

### View Company Expenses
```
Dashboard → Salary Management → View Statistics
```

### Add New Employee Salary
```
Salary Management → Add Salary → Fill Form → Save
```

### Update Salary
```
Salary Management → Find Employee → Edit → Save
```

### Search Employee
```
Salary Management → Type in Search Box
```

### Monitor Travel Costs
```
Salary Management → View "Travel Allowance" Card
```

### Monitor Daily Costs
```
Salary Management → View "Daily Allowance" Card
```

## 📱 Mobile/Desktop

Works on:
- ✅ Desktop (Windows, Mac, Linux)
- ✅ Mobile (Android, iOS)
- ✅ Web (Browser)

## 🔐 Security

- Admin access only
- Sensitive data - handle with care
- All changes timestamped
- Audit trail maintained

## 📞 Need Help?

Check these files:
- `SALARY_MANAGEMENT_GUIDE.md` - Full user guide
- `backend/SALARY_API_DOCUMENTATION.md` - API docs
- `SALARY_IMPLEMENTATION_SUMMARY.md` - Technical details

## ⚡ Quick Commands

### Backend
```bash
cd backend
npm run dev              # Start server
node test-salary-api.js  # Test API
npx prisma studio        # View database
```

### Frontend
```bash
cd loagma_crm
flutter run              # Run app
flutter pub get          # Install dependencies
```

## 🎨 UI Colors

- **Blue** - Basic Salary
- **Orange** - Travel Allowance
- **Purple** - Daily Allowance
- **Green** - Net Salary
- **Red** - Deductions

## 📋 Required Fields

When adding salary:
- ✅ Employee (select from dropdown)
- ✅ Basic Salary (amount)
- ✅ Effective From (date)

All other fields are optional!

## 💾 Data Storage

- Database: PostgreSQL
- Table: SalaryInformation
- Relation: One-to-One with User
- Indexed: employeeId, effectiveFrom, isActive

## 🔄 Update Frequency

Recommended:
- **Monthly** - Regular salary updates
- **Quarterly** - Review and adjustments
- **Annually** - Increments and revisions

## ✨ Key Benefits

1. **Centralized** - All salary data in one place
2. **Automated** - Calculations done automatically
3. **Searchable** - Find any employee quickly
4. **Trackable** - Monitor expenses easily
5. **Reportable** - Statistics at your fingertips

---

**Version**: 1.0.0  
**Last Updated**: November 20, 2024  
**Status**: ✅ Production Ready
