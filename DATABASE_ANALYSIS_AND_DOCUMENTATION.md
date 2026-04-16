# Loagma CRM Database - Complete Analysis & Documentation

## Database Overview

**Database Name**: loagma_new  
**Server**: TiDB Cloud (MySQL-compatible)  
**Host**: gateway01.ap-southeast-1.prod.aws.tidbcloud.com:4000  
**Region**: Asia Pacific (Singapore)  
**Version**: TiDB v7.5.6-serverless  
**Character Set**: UTF8MB4  
**Collation**: utf8mb4_unicode_ci  
**Engine**: InnoDB  

---

## Database Purpose

**Loagma CRM** is a comprehensive field sales and service management system designed for managing:
- Sales team territories and assignments
- Account/lead management with approval workflows
- Employee attendance tracking with GPS monitoring
- Beat planning and daily execution
- Leave and expense management
- Telecalling operations with call logging

---

## All Tables (31 Total)

### **1. Geographic Tables (7)**

#### Area
- **PK**: area_id (INT AUTO_INCREMENT)
- **Columns**: area_name (VARCHAR 100), zone_id (FK)
- **Purpose**: Geographic areas/pincodes
- **Status**: Empty (ready for data)

#### City
- **PK**: city_id (INT AUTO_INCREMENT)
- **Columns**: city_name (VARCHAR 100), district_id (FK)
- **Purpose**: City names
- **Status**: Empty (ready for data)

#### Country
- **PK**: country_id (INT AUTO_INCREMENT)
- **Columns**: country_name (VARCHAR 100)
- **Purpose**: Country data
- **Status**: Ready

#### District
- **PK**: district_id (INT AUTO_INCREMENT)
- **Columns**: district_name (VARCHAR 100), region_id (FK)
- **Purpose**: District hierarchy
- **Status**: Empty

#### Region
- **PK**: region_id (INT AUTO_INCREMENT)
- **Columns**: region_name (VARCHAR 100), state_id (FK)
- **Purpose**: Regional grouping
- **Status**: Empty

#### State
- **PK**: state_id (INT AUTO_INCREMENT)
- **Columns**: state_name (VARCHAR 100), country_id (FK)
- **Purpose**: State/province data
- **Status**: Empty

#### Zone
- **PK**: zone_id (INT AUTO_INCREMENT)
- **Columns**: zone_name (VARCHAR 100), city_id (FK)
- **Purpose**: City zone divisions
- **Status**: Empty

---

### **2. User Management Tables (3)**

#### LoginUser_crm
- **PK**: id (VARCHAR 191 - UUID)
- **Key Columns**:
  - employeeCode (VARCHAR 191, UNIQUE)
  - name, email (UNIQUE), contactNumber (UNIQUE)
  - password, otp, otpExpiry, lastLogin
  - address, city, state, pincode, country, district, area
  - latitude, longitude (GPS)
  - aadharCard, panCard (documents)
  - workStartTime (default 09:00:00)
  - workEndTime (default 18:00:00)
  - latePunchInGraceMinutes (default 45)
  - earlyPunchOutGraceMinutes (default 30)
  - isActive (default true)
  - roles (JSON array)
  - departmentId (FK)
  - roleId (FK)
  - createdAt, updatedAt
- **Sample Data**: 31 employees (codes 00001-00031)
- **Indexes**: employeeCode, email, contactNumber, departmentId, roleId

#### LoginUserRoles_crm
- **PK**: id (VARCHAR 191)
- **Columns**: name (VARCHAR 191), createdAt, updatedAt
- **Sample Data**: 5 roles (admin, manager, salesman, telecaller, test2)
- **Purpose**: Role definitions

#### department_crm
- **PK**: id
- **Purpose**: Employee departments
- **Referenced by**: LoginUser_crm.departmentId

---

### **3. Account & Lead Management (2)**

#### LeadsAccount_crm
- **PK**: id (VARCHAR 191)
- **Key Columns**:
  - accountCode (VARCHAR 191, UNIQUE) - 00026040001-00026040058
  - businessName, businessType, businessSize
  - personName, contactNumber (UNIQUE), dateOfBirth
  - pincode, country, state, district, city, area
  - areaId (FK→Area), latitude, longitude
  - gstNumber, panCard (UNIQUE)
  - ownerImage, shopImage (Cloudinary URLs)
  - customerStage, funnelStage
  - isApproved (default false), isActive (default true)
  - assignedToId (FK→LoginUser_crm)
  - assignedDays (JSON array)
  - createdById, approvedById (FK→LoginUser_crm)
  - approvedAt, verificationNotes, rejectionNotes
  - createdAt, updatedAt
- **Sample Data**: 58 accounts (all in Hyderabad)
- **Indexes**: accountCode (UNIQUE), pincode, isActive, customerStage, businessType, createdAt

#### EmployeeArea
- **PK**: Composite (area_id, city_id, country_id, district_id, employeeId, region_id, state_id, zone_id)
- **Key Columns**:
  - employeeId (UNIQUE FK→LoginUser_crm)
  - area_id, city_id, country_id, district_id, region_id, state_id, zone_id
  - latitude, longitude
  - createdAt, updatedAt
- **Purpose**: Maps employees to geographic territories

---

### **4. Attendance & Tracking (2)**

#### Attendance
- **PK**: id (VARCHAR 191)
- **Key Columns**:
  - employeeId (FK→LoginUser_crm)
  - employeeName (VARCHAR 191)
  - date (DATETIME, default NOW)
  - punchInTime (DATETIME)
  - punchInLatitude, punchInLongitude (DOUBLE)
  - punchInPhoto (LONGTEXT - Base64 image)
  - punchInAddress (VARCHAR 191)
  - bikeKmStart (VARCHAR 191)
  - punchOutTime (DATETIME)
  - punchOutLatitude, punchOutLongitude (DOUBLE)
  - punchOutPhoto (LONGTEXT - Base64 image)
  - punchOutAddress (VARCHAR 191)
  - bikeKmEnd (VARCHAR 191)
  - totalWorkHours (DOUBLE)
  - totalDistanceKm (DOUBLE)
  - status (default 'active')
  - isLatePunchIn (default false)
  - isEarlyPunchOut (default false)
  - lateApprovalId, earlyPunchOutApprovalId (FK)
  - approvalCode, earlyPunchOutCode (VARCHAR 191)
  - createdAt, updatedAt
- **Indexes**: (employeeId, date), (employeeId, status), punchInTime, isLatePunchIn, status, date
- **Status**: Empty (ready for daily records)

#### SalesmanTrackingPoint
- **PK**: id (VARCHAR 191)
- **Columns**:
  - latitude (DOUBLE), longitude (DOUBLE)
  - speed (DOUBLE), accuracy (DOUBLE)
  - recordedAt (DATETIME, default NOW)
  - employeeId (FK→LoginUser_crm, CASCADE)
  - attendanceId (FK→Attendance, CASCADE)
  - clientPointId (VARCHAR 191, UNIQUE)
  - createdAt, updatedAt
- **Indexes**: (employeeId, attendanceId, recordedAt), clientPointId
- **Purpose**: Real-time GPS tracking
- **Status**: Empty

---

### **5. Beat Planning (3)**

#### WeeklyBeatPlan
- **PK**: id (VARCHAR 191)
- **Columns**:
  - salesmanId (FK→LoginUser_crm, CASCADE)
  - salesmanName (VARCHAR 191)
  - weekStartDate, weekEndDate (DATETIME)
  - pincodes (JSON)
  - totalAreas (INT, default 0)
  - status (default 'DRAFT') - DRAFT, APPROVED, LOCKED
  - generatedBy, approvedBy, lockedBy (FK→LoginUser_crm)
  - approvedAt, lockedAt (DATETIME)
  - createdAt, updatedAt
- **Indexes**: salesmanId, weekStartDate, status, (salesmanId, weekStartDate - UNIQUE)
- **Status**: Empty

#### DailyBeatPlan
- **PK**: id (VARCHAR 191)
- **Columns**:
  - weeklyBeatId (FK→WeeklyBeatPlan, CASCADE)
  - dayOfWeek (INT 1-7)
  - dayDate (DATE)
  - assignedAreas (JSON)
  - plannedVisits, actualVisits (INT)
  - status (default 'PLANNED')
  - completedAt (DATETIME)
  - carriedFromDate, carriedToDate (DATE)
  - createdAt, updatedAt
- **Indexes**: weeklyBeatId, (weeklyBeatId, dayOfWeek - UNIQUE), status
- **Status**: Empty

#### BeatCompletion
- **PK**: id (VARCHAR 191)
- **Columns**:
  - dailyBeatId (FK→DailyBeatPlan, CASCADE)
  - salesmanId (FK→LoginUser_crm, CASCADE)
  - areaName (VARCHAR 191)
  - accountsVisited (INT)
  - completedAt (DATETIME, default NOW)
  - latitude, longitude (DOUBLE)
  - notes (VARCHAR 191)
  - isVerified (BOOLEAN, default false)
  - verifiedBy (FK→LoginUser_crm, SET NULL)
  - verifiedAt (DATETIME)
  - createdAt, updatedAt
- **Indexes**: dailyBeatId, salesmanId, completedAt, areaName, verifiedBy
- **Status**: Empty

---

### **6. Assignment Management (2)**

#### WeeklyAccountAssignment
- **PK**: id (VARCHAR 191)
- **Columns**:
  - accountId (FK→LeadsAccount_crm, CASCADE)
  - salesmanId (VARCHAR 191)
  - pincode (VARCHAR 191)
  - weekStartDate (DATETIME)
  - assignedDays (JSON) - [1,3,5] etc
  - visitFrequency (VARCHAR 191)
  - isManualOverride (BOOLEAN, default false)
  - sequenceNo (INT)
  - createdAt, updatedAt
  - overriddenAt, overrideBy, overrideReason
  - plannedAt, plannedBy
  - recurrenceAfterDays (INT)
  - recurrenceStartDate, recurrenceNextDate (DATETIME)
- **Indexes**: (salesmanId, weekStartDate), (pincode, weekStartDate), (accountId, weekStartDate - UNIQUE)
- **Sample Data**: 2 records
- **Status**: Active with sample data

#### AreaAssignment
- **PK**: id (VARCHAR 191)
- **Columns**:
  - salesmanId (VARCHAR 191)
  - pinCode, country, state, district, city (VARCHAR 191)
  - areas (JSON), businessTypes (JSON)
  - assignedDate, totalBusinesses (INT)
  - createdAt, updatedAt
- **Indexes**: salesmanId, pinCode, (city, district)
- **Status**: Empty

---

### **7. Approvals & Leave (4)**

#### LatePunchApproval
- **PK**: id (VARCHAR 191)
- **Columns**:
  - employeeId (FK→LoginUser_crm, CASCADE)
  - employeeName (VARCHAR 191)
  - punchInDate (DATE)
  - reason (TEXT)
  - status (default 'PENDING') - PENDING, APPROVED, REJECTED
  - approvedBy (FK→LoginUser_crm, SET NULL)
  - approvedAt (DATETIME)
  - adminRemarks (VARCHAR 191)
  - approvalCode (VARCHAR 191)
  - codeExpiresAt, codeUsedAt (DATETIME)
  - codeUsed (BOOLEAN)
  - createdAt, updatedAt
- **Indexes**: (employeeId, status), (employeeId, punchInDate)
- **Status**: Empty

#### EarlyPunchOutApproval
- **Similar to LatePunchApproval** with additional attendanceId (FK)
- **Status**: Empty

#### Leave
- **PK**: id (VARCHAR 191)
- **Columns**:
  - employeeId (FK→LoginUser_crm, CASCADE)
  - employeeName (VARCHAR 191)
  - leaveType (VARCHAR 191)
  - startDate, endDate (DATE)
  - numberOfDays (INT)
  - reason (TEXT)
  - requestedAt (DATETIME, default NOW)
  - status (default 'PENDING')
  - approvedBy (FK→LoginUser_crm, SET NULL)
  - approvedAt, rejectionReason (TEXT)
  - adminRemarks (VARCHAR 191)
  - createdAt, updatedAt
- **Indexes**: (employeeId, status), employeeId, leaveType, startDate, endDate
- **Status**: Empty

#### LeaveBalance
- **PK**: id (VARCHAR 191)
- **Columns**:
  - employeeId (UNIQUE FK→LoginUser_crm, CASCADE)
  - year (INT)
  - sickLeaves, casualLeaves, earnedLeaves (default 12, 10, 20)
  - usedSickLeaves, usedCasualLeaves, usedEarnedLeaves (default 0)
  - createdAt, updatedAt
- **Sample Data**: 2 records (00001, 00014 for year 2026)
- **Status**: Active with sample data

---

### **8. Telecalling (2)**

#### TelecallerCallLog
- **PK**: id (VARCHAR 191)
- **Columns**:
  - accountId (FK→LeadsAccount_crm, RESTRICT)
  - telecallerId (FK→LoginUser_crm, RESTRICT)
  - calledAt (DATETIME, default NOW)
  - durationSec (INT)
  - nextFollowupAt (DATETIME)
  - status, notes (VARCHAR 191)
  - recordingUrl (VARCHAR 191)
  - followupNotes (TEXT)
  - createdAt, updatedAt
- **Indexes**: (telecallerId, calledAt), (accountId, calledAt), nextFollowupAt, status
- **Status**: Empty

#### TelecallerPincodeAssignment
- **PK**: id (VARCHAR 191)
- **Columns**:
  - telecallerId (FK→LoginUser_crm, RESTRICT)
  - pincode (VARCHAR 191)
  - dayOfWeek (INT)
  - isActive (default 1)
  - createdAt, updatedAt
- **Indexes**: telecallerId, (pincode, dayOfWeek)
- **Status**: Empty

---

### **9. HR & Payroll (2)**

#### SalaryInformation
- **PK**: id (VARCHAR 191)
- **Columns**:
  - employeeId (UNIQUE FK→LoginUser_crm, CASCADE)
  - basicSalary, hra, travelAllowance, dailyAllowance
  - medicalAllowance, specialAllowance, otherAllowances (DOUBLE)
  - providentFund, professionalTax, incomeTax, otherDeductions (DOUBLE)
  - effectiveFrom, effectiveTo (DATE)
  - currency (default 'INR'), paymentFrequency (default 'Monthly')
  - bankName, accountNumber, ifscCode, panNumber (VARCHAR 191)
  - remarks (VARCHAR 191)
  - isActive (default true)
  - createdAt, updatedAt
- **Sample Data**: 30 records (₹18K-₹28K monthly salary)
- **Status**: Active with sample data

#### Expense
- **PK**: id (VARCHAR 191)
- **Columns**:
  - employeeId (FK→LoginUser_crm, CASCADE)
  - expenseType, amount (DECIMAL)
  - expenseDate (DATE)
  - billNumber, attachmentUrl (VARCHAR 191)
  - status (default 'Pending')
  - approvedBy (FK→LoginUser_crm, SET NULL)
  - approvedAt, rejectionReason (TEXT)
  - paidAt (DATETIME)
  - remarks (VARCHAR 191)
  - createdAt, updatedAt
- **Indexes**: (employeeId, status), employeeId, expenseDate, expenseType, approvedBy
- **Status**: Empty

---

### **10. Business Configuration (2)**

#### BusinessType
- **PK**: id (VARCHAR 191) - BT001-BT010
- **Columns**: name (VARCHAR 191), createdAt
- **Sample Data**: 10 types (Retail, Wholesale, Manufacturing, IT, Healthcare, Education, Finance, Real Estate, Hospitality, Logistics)
- **Status**: Fixed master data

#### TaskAssignment
- **PK**: id (VARCHAR 191)
- **Columns**:
  - salesmanId, salesmanName (VARCHAR 191)
  - pincode, city, district, country, state
  - areas, businessTypes (JSON)
  - totalBusinesses (INT, default 0)
  - assignedDate, createdAt, updatedAt
- **Sample Data**: 4 records
- **Status**: Active

---

### **11. Infrastructure (1)**

#### Notification
- **PK**: id (VARCHAR 191)
- **Columns**:
  - title, message (TEXT)
  - type, priority (default 'normal')
  - targetRole, targetUserId (VARCHAR 191)
  - data (JSON)
  - isRead (default false)
  - readAt (DATETIME)
  - createdAt, updatedAt
- **Status**: Empty

---

## Current Data Summary

| Component | Count | Status |
|-----------|-------|--------|
| Accounts (LeadsAccount_crm) | 58 | Active (Hyderabad only) |
| Employees (LoginUser_crm) | 31 | Active (codes 00001-00031) |
| Salary Records | 30 | Active |
| Roles | 5 | Fixed (admin, manager, salesman, telecaller, test2) |
| Business Types | 10 | Fixed seed data |
| Leave Balance | 2 | Sample data |
| Weekly Assignments | 2 | Sample data |
| **Total Tables** | **31** | **Active** |

---

## Key Design Patterns

### 1. Geographic Hierarchy (7 levels)
Country → State → Region → District → City → Zone → Area
- All use AUTO_INCREMENT primary keys
- CASCADE delete for referential integrity
- EmployeeArea bridges employees to territories

### 2. Approval Workflow (Standardized)
PENDING → APPROVED/REJECTED → Process continues
- Applied to: Accounts, Leave, Expenses, Late/Early Punches
- Tracks: createdBy, approvedBy, timestamps, notes

### 3. User Multi-Context
Same LoginUser_crm used as:
- Employee (has salary, attendance)
- Creator (creates accounts)
- Approver (approves requests)
- Manager (verifies beat completion)

### 4. Time-Series Data
Daily collections with GPS:
- Attendance (punch in/out with photos)
- SalesmanTrackingPoint (real-time GPS)
- Beat completion tracking

### 5. Assignment & Planning
Two-level structure:
- WeeklyBeatPlan (overview for week)
- DailyBeatPlan (daily execution: Mon-Fri)
- BeatCompletion (actual completion + verification)

### 6. Flexible Data with JSON
Arrays stored in JSON fields:
- assignedDays (days of week: 1-7)
- pincodes (service areas)
- areas (geographic assignments)
- businessTypes (business classifications)

---

## Common Queries

### Get accounts pending approval
```sql
SELECT accountCode, businessName, personName, contactNumber
FROM LeadsAccount_crm
WHERE isApproved = 0
ORDER BY createdAt DESC;
```

### Get today's attendance
```sql
SELECT e.employeeCode, e.name, a.punchInTime, a.punchOutTime,
       a.totalWorkHours, a.isLatePunchIn
FROM LoginUser_crm e
LEFT JOIN Attendance a ON e.id = a.employeeId 
  AND DATE(a.date) = CURDATE()
WHERE e.isActive = true;
```

### Get accounts assigned to salesman for week
```sql
SELECT ac.accountCode, ac.businessName, ac.contactNumber,
       waa.assignedDays, waa.visitFrequency
FROM LeadsAccount_crm ac
JOIN WeeklyAccountAssignment waa ON ac.id = waa.accountId
WHERE waa.salesmanId = '00001'
  AND waa.weekStartDate >= DATE_SUB(CURDATE(), INTERVAL 7 DAY);
```

### Get pending leave requests
```sql
SELECT e.employeeCode, e.name, l.leaveType, l.startDate, l.endDate
FROM Leave l
JOIN LoginUser_crm e ON l.employeeId = e.id
WHERE l.status = 'PENDING'
ORDER BY l.requestedAt;
```

### Get beat completion with verification
```sql
SELECT bc.id, bc.areaName, bc.accountsVisited, bc.completedAt,
       bc.isVerified, verifier.name as verifiedByName
FROM BeatCompletion bc
LEFT JOIN LoginUser_crm verifier ON bc.verifiedBy = verifier.id
WHERE bc.salesmanId = '00001'
  AND DATE(bc.completedAt) = CURDATE();
```

---

## Security & Best Practices

✅ **Passwords**: Hashed (bcrypt)  
✅ **Timestamps**: All records tracked (createdAt, updatedAt)  
✅ **Foreign Keys**: Enforced with proper cascade delete  
✅ **Unique Constraints**: Email, phone, account codes, etc.  
✅ **Indexes**: Strategic on FK and frequently queried columns  
✅ **Audit Trail**: createdBy, approvedBy, modifiedBy tracked  
✅ **JSON Data**: Flexible array storage for dynamic fields  
✅ **SSL Connection**: Strict SSL to TiDB Cloud

---

## Database Statistics

- **Total Tables**: 31
- **Primary Keys**: All VARCHAR(191) UUIDs or INT AUTO_INCREMENT
- **Foreign Keys**: 40+ relationships with CASCADE delete
- **Unique Constraints**: 15+ on business identifiers
- **Indexes**: 100+ including composite indexes
- **Character Set**: UTF8MB4 (Unicode support)
- **Collation**: utf8mb4_unicode_ci (case-insensitive)
- **Engine**: InnoDB (transactions, referential integrity)

---

**Documentation created from**: updateandfinal20260416.sql  
**Date**: April 16, 2026  
**Status**: ✓ Complete & Based on SQL File
