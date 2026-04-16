# Database Quick Reference

## All 31 Tables List

| # | Table Name | Records | Primary Key | Key Field | Status |
|---|------------|---------|------------|-----------|--------|
| 1 | Area | 0 | area_id (INT) | area_name | Ready |
| 2 | AreaAssignment | 0 | id (VARCHAR) | salesmanId | Ready |
| 3 | Attendance | 0 | id (VARCHAR) | employeeId, date | Ready |
| 4 | BeatCompletion | 0 | id (VARCHAR) | dailyBeatId, salesmanId | Ready |
| 5 | BusinessType | 10 | id (VARCHAR) | name (10 types) | Fixed |
| 6 | City | 0 | city_id (INT) | city_name | Ready |
| 7 | Country | 0 | country_id (INT) | country_name | Ready |
| 8 | DailyBeatPlan | 0 | id (VARCHAR) | weeklyBeatId, dayOfWeek | Ready |
| 9 | District | 0 | district_id (INT) | district_name | Ready |
| 10 | EarlyPunchOutApproval | 0 | id (VARCHAR) | employeeId | Ready |
| 11 | EmployeeArea | 0 | Composite | employeeId | Ready |
| 12 | Expense | 0 | id (VARCHAR) | employeeId | Ready |
| 13 | LatePunchApproval | 0 | id (VARCHAR) | employeeId | Ready |
| 14 | LeadsAccount_crm | 58 | id (VARCHAR) | accountCode | **Active** |
| 15 | Leave | 0 | id (VARCHAR) | employeeId | Ready |
| 16 | LeaveBalance | 2 | id (VARCHAR) | employeeId | **Sample** |
| 17 | LoginUser_crm | 31 | id (VARCHAR) | employeeCode | **Active** |
| 18 | LoginUserRoles_crm | 5 | id (VARCHAR) | name | **Fixed** |
| 19 | Region | 0 | region_id (INT) | region_name | Ready |
| 20 | SalesmanTrackingPoint | 0 | id (VARCHAR) | employeeId | Ready |
| 21 | SalaryInformation | 30 | id (VARCHAR) | employeeId | **Active** |
| 22 | State | 0 | state_id (INT) | state_name | Ready |
| 23 | TaskAssignment | 4 | id (VARCHAR) | salesmanId | **Sample** |
| 24 | TelecallerCallLog | 0 | id (VARCHAR) | accountId, telecallerId | Ready |
| 25 | TelecallerPincodeAssignment | 0 | id (VARCHAR) | telecallerId | Ready |
| 26 | WeeklyAccountAssignment | 2 | id (VARCHAR) | accountId, weekStartDate | **Sample** |
| 27 | WeeklyBeatPlan | 0 | id (VARCHAR) | salesmanId, weekStartDate | Ready |
| 28 | Zone | 0 | zone_id (INT) | zone_name | Ready |
| 29 | department_crm | - | - | Referenced by users | Ready |
| 30 | Notification | 0 | id (VARCHAR) | targetUserId | Ready |
| 31 | _prisma_migrations | - | - | Migration tracking | Internal |

---

## Connection String

```env
DATABASE_URL="mysql://root:password@gateway01.ap-southeast-1.prod.aws.tidbcloud.com:4000/loagma_new?sslaccept=strict"
```

---

## Sample Data Snippets

**Account Example:**
```json
{
  "accountCode": "00026040001",
  "businessName": "Rao's Heritage Lodge",
  "businessType": "Hospitality",
  "personName": "Rao Singh",
  "contactNumber": "+91-9876543210",
  "pincode": "500001",
  "city": "Hyderabad",
  "isApproved": false,
  "customerStage": "Lead"
}
```

**Employee Example:**
```json
{
  "employeeCode": "00001",
  "name": "Rahul Sharma",
  "email": "rahul@loagma.com",
  "role": "salesman",
  "salary": 25000,
  "isActive": true
}
```

---

## Common SQL Queries

**1. Get accounts pending approval**
```sql
SELECT accountCode, businessName, personName, contactNumber
FROM LeadsAccount_crm
WHERE isApproved = 0;
```

**2. Get all employees**
```sql
SELECT employeeCode, name, email, role FROM LoginUser_crm;
```

**3. Get today's attendance**
```sql
SELECT e.employeeCode, a.punchInTime, a.punchOutTime, a.totalWorkHours
FROM Attendance a
JOIN LoginUser_crm e ON a.employeeId = e.id
WHERE DATE(a.date) = CURDATE();
```

**4. Get leave requests pending approval**
```sql
SELECT e.employeeCode, l.leaveType, l.startDate, l.endDate
FROM Leave l
JOIN LoginUser_crm e ON l.employeeId = e.id
WHERE l.status = 'PENDING';
```

**5. Get accounts assigned to salesman**
```sql
SELECT ac.accountCode, ac.businessName
FROM LeadsAccount_crm ac
JOIN WeeklyAccountAssignment wa ON ac.id = wa.accountId
WHERE wa.salesmanId = '00001';
```

**6. Get employee salary info**
```sql
SELECT u.employeeCode, u.name, s.basicSalary, s.bankName
FROM SalaryInformation s
JOIN LoginUser_crm u ON s.employeeId = u.id;
```

**7. Get beat completion records**
```sql
SELECT bc.areaName, bc.accountsVisited, bc.completedAt, bc.isVerified
FROM BeatCompletion bc
WHERE DATE(bc.completedAt) = CURDATE();
```

**8. Get leave balance for employee**
```sql
SELECT sickLeaves, casualLeaves, earnedLeaves,
       usedSickLeaves, usedCasualLeaves, usedEarnedLeaves
FROM LeaveBalance
WHERE employeeId = '00001' AND year = YEAR(CURDATE());
```

**9. Get pending expense claims**
```sql
SELECT e.employeeCode, ex.expenseType, ex.amount, ex.status
FROM Expense ex
JOIN LoginUser_crm e ON ex.employeeId = e.id
WHERE ex.status = 'Pending';
```

**10. Get late punch approvals pending**
```sql
SELECT e.employeeCode, lpa.punchInDate, lpa.reason
FROM LatePunchApproval lpa
JOIN LoginUser_crm e ON lpa.employeeId = e.id
WHERE lpa.status = 'PENDING';
```

---

## Field Validation Rules

| Field | Type | Rules |
|-------|------|-------|
| employeeCode | VARCHAR(191) | UNIQUE, 5-digit zero-padded (00001-00031) |
| email | VARCHAR(191) | UNIQUE, valid format |
| contactNumber | VARCHAR(191) | UNIQUE, +91 prefix, 10-13 digits |
| accountCode | VARCHAR(191) | UNIQUE, auto-generated |
| pincode | VARCHAR(191) | 6 digits required |
| leaveType | VARCHAR(191) | Sick, Casual, Earned, Unpaid |
| status | VARCHAR(191) | PENDING, APPROVED, REJECTED (varies) |
| punchInTime | DATETIME | Required, > workStartTime |
| punchOutTime | DATETIME | Required, > punchInTime |

---

## Best Practices

✅ **DO:**
- Always filter by date for temporal data
- Use transactions for multi-table updates
- Hash passwords before storing
- Validate data before insert
- Use prepared statements

❌ **DON'T:**
- Fetch all records without filtering
- Expose password hashes in API responses
- Modify createdAt or _id fields
- Store sensitive data in plaintext
- Create accounts without approval workflow

---

## Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| Duplicate entry for UNIQUE key | Duplicate value insert | Check existing record first |
| Foreign key constraint failed | Parent record missing | Reference existing parent |
| Column cannot be null | Required field missing | Provide all required fields |
| Data out of range | Value too large | Check field limits |

---

**Created from**: updateandfinal20260416.sql  
**Date**: April 16, 2026
