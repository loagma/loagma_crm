# Loagma CRM - Complete Database Documentation

## Overview
This document provides comprehensive documentation for the Loagma CRM database schema, including all tables, their purposes, relationships, and usage status across the application.

**Database Type:** PostgreSQL  
**ORM:** Prisma  
**Total Tables:** 29  
**Actively Used:** 17  
**Unused/Legacy:** 11  
**Partially Used:** 1

---

## Table of Contents
1. [Location Hierarchy Tables](#location-hierarchy-tables)
2. [User Management Tables](#user-management-tables)
3. [Customer/Account Management](#customeraccount-management)
4. [Attendance & Tracking](#attendance--tracking)
5. [Leave Management](#leave-management)
6. [Approval Workflow Tables](#approval-workflow-tables)
7. [Beat Planning Tables](#beat-planning-tables)
8. [Financial Tables](#financial-tables)
9. [Task & Area Assignment](#task--area-assignment)
10. [Notification System](#notification-system)
11. [Unused/Legacy Tables](#unusedlegacy-tables)
12. [Database Relationships](#database-relationships)

---

## Location Hierarchy Tables (UNUSED - Legacy Structure)

### 1. Country
**Purpose:** Top-level geographical entity for location hierarchy  
**Status:** ❌ NOT USED (No data, not used in application)  
**Primary Key:** `country_id` (Auto-increment)

**Fields:**
- `country_id`: Unique identifier
- `country_name`: Name of the country (VARCHAR 100)

**Relationships:**
- Has many: States, EmployeeAreas

**Why Not Used:**
- Controllers exist but no data is populated
- Account table stores location as STRING fields (country, state, city, etc.) instead of foreign keys
- Application uses pincode-based location system with text fields
- Can be removed in future cleanup

---

### 2. State
**Purpose:** State/Province level in location hierarchy  
**Status:** ❌ NOT USED (No data, not used in application)  
**Primary Key:** `state_id` (Auto-increment)

**Fields:**
- `state_id`: Unique identifier
- `state_name`: Name of the state (VARCHAR 100)
- `country_id`: Foreign key to Country

**Relationships:**
- Belongs to: Country
- Has many: Regions, EmployeeAreas

**Why Not Used:**
- Controllers exist but no data is populated
- Account table stores state as STRING field
- Not referenced in actual business logic

---

### 3. Region
**Purpose:** Regional division within states  
**Status:** ❌ NOT USED (No data, not used in application)  
**Primary Key:** `region_id` (Auto-increment)

**Fields:**
- `region_id`: Unique identifier
- `region_name`: Name of the region (VARCHAR 100)
- `state_id`: Foreign key to State

**Relationships:**
- Belongs to: State
- Has many: Districts, EmployeeAreas

**Why Not Used:**
- Controllers exist but no data is populated
- Not used in application flow
- Intermediate level that's skipped in actual implementation

---

### 4. District
**Purpose:** District level in location hierarchy  
**Status:** ❌ NOT USED (No data, not used in application)  
**Primary Key:** `district_id` (Auto-increment)

**Fields:**
- `district_id`: Unique identifier
- `district_name`: Name of the district (VARCHAR 100)
- `region_id`: Foreign key to Region

**Relationships:**
- Belongs to: Region
- Has many: Cities, EmployeeAreas

**Why Not Used:**
- Controllers exist but no data is populated
- Account table stores district as STRING field
- Not referenced in actual business logic

---

### 5. City
**Purpose:** City level in location hierarchy  
**Status:** ❌ NOT USED (No data, not used in application)  
**Primary Key:** `city_id` (Auto-increment)

**Fields:**
- `city_id`: Unique identifier
- `city_name`: Name of the city (VARCHAR 100)
- `district_id`: Foreign key to District

**Relationships:**
- Belongs to: District
- Has many: Zones, EmployeeAreas

**Why Not Used:**
- Controllers exist but no data is populated
- Account table stores city as STRING field
- Not referenced in actual business logic

---

### 6. Zone
**Purpose:** Zone/sector within cities  
**Status:** ❌ NOT USED (No data, not used in application)  
**Primary Key:** `zone_id` (Auto-increment)

**Fields:**
- `zone_id`: Unique identifier
- `zone_name`: Name of the zone (VARCHAR 100)
- `city_id`: Foreign key to City

**Relationships:**
- Belongs to: City
- Has many: Areas, EmployeeAreas

**Why Not Used:**
- Controllers exist but no data is populated
- Not used in application flow
- Application uses pincode-based system instead

---

### 7. Area
**Purpose:** Smallest geographical unit in hierarchy  
**Status:** ❌ NOT USED (No data, legacy field in Account)  
**Primary Key:** `area_id` (Auto-increment)

**Fields:**
- `area_id`: Unique identifier
- `area_name`: Name of the area (VARCHAR 100)
- `zone_id`: Foreign key to Zone

**Relationships:**
- Belongs to: Zone
- Has many: Accounts, EmployeeAreas

**Why Not Used:**
- Controllers exist but no data is populated
- Account table has optional `areaId` field but it's rarely used (mostly null)
- Account table stores area as STRING field instead
- Beat planning uses area names as strings, not foreign keys
- Can be removed in future cleanup

---

## User Management Tables

### 8. Department
**Purpose:** Organizational departments for employee categorization  
**Status:** ✅ ACTIVE (Used in user management)  
**Primary Key:** `id` (String)

**Fields:**
- `id`: Unique identifier (String)
- `name`: Department name (Unique)
- `createdAt`: Timestamp

**Relationships:**
- Has many: Users

**Usage:**
- Used in user/employee management
- Seeded with departments like Sales, Marketing, HR, etc.
- Referenced in User table

---

### 9. Role
**Purpose:** User role definitions for access control  
**Status:** ✅ ACTIVE (Critical for authorization)  
**Primary Key:** `id` (String)

**Fields:**
- `id`: Unique identifier (String)
- `name`: Role name
- `createdAt`: Timestamp

**Relationships:**
- Has many: Users

**Usage:**
- Used extensively in authentication and authorization
- Roles: admin, salesman, telecaller, manager
- Referenced in User table and role-based access control

---

### 10. User
**Purpose:** Core user/employee table storing all user information  
**Status:** ✅ ACTIVE (Most critical table)  
**Primary Key:** `id` (String)

**Fields:**
- `id`: Unique identifier
- `employeeCode`: Unique employee code
- `name`: Full name
- `email`: Email address (Unique)
- `contactNumber`: Phone number (Unique)
- `alternativeNumber`: Secondary phone
- `roleId`: Foreign key to Role
- `roles`: Array of role strings
- `departmentId`: Foreign key to Department
- `otp`, `otpExpiry`: OTP authentication
- `lastLogin`: Last login timestamp
- `isActive`: Account status
- `dateOfBirth`, `gender`: Personal info
- `image`: Profile picture URL
- `preferredLanguages`: Array of languages
- Address fields: `address`, `city`, `state`, `pincode`, `country`, `district`, `area`
- Location: `latitude`, `longitude`
- Documents: `aadharCard`, `panCard`
- `password`: Hashed password
- `notes`: Additional notes
- Working hours config: `workStartTime`, `workEndTime`, `latePunchInGraceMinutes`, `earlyPunchOutGraceMinutes`

**Relationships:**
- Belongs to: Role, Department
- Has one: EmployeeArea, SalaryInformation, LeaveBalance
- Has many: Accounts (assigned, created, approved), Expenses, Notifications, Leave requests, Approval requests, Beat plans, Tracking points

**Usage:**
- Central table for all user operations
- Used in authentication, authorization
- Referenced by almost all other tables
- Stores salesman, admin, telecaller, manager data

---

### 11. EmployeeArea
**Purpose:** Links employees to their assigned geographical areas  
**Status:** ❌ NOT USED (References unused location hierarchy)  
**Primary Key:** `id` (Auto-increment)

**Fields:**
- `id`: Unique identifier
- `employeeId`: Foreign key to User (Unique)
- `country_id`, `state_id`, `region_id`, `district_id`, `city_id`, `zone_id`, `area_id`: Location hierarchy references (all unused)
- `latitude`, `longitude`: GPS coordinates

**Relationships:**
- Belongs to: User, Country, State, Region, District, City, Zone, Area

**Why Not Used:**
- References location hierarchy tables that have no data
- Foreign keys point to empty tables
- GPS coordinates are useful but table structure is over-engineered
- Could be simplified to just store lat/long on User table directly
- Only counted in admin delete operations, never actively queried

---

## Customer/Account Management

### 12. Account
**Purpose:** Customer/shop/business accounts managed by salesmen  
**Status:** ✅ ACTIVE (Core business entity)  
**Primary Key:** `id` (String)

**Fields:**
- `id`: Unique identifier
- `accountCode`: Unique account code (auto-generated)
- `businessName`: Name of the business
- `businessType`: Type of business (grocery, cafe, hotel, etc.)
- `businessSize`: Semi Retailer, Retailer, Semi Wholesaler, Wholesaler, Home Buyer
- `personName`: Contact person name
- `contactNumber`: Phone number
- `dateOfBirth`: Contact person DOB
- `customerStage`: Stage in customer lifecycle
- `funnelStage`: Sales funnel stage
- `gstNumber`, `panCard`: Business documents
- `ownerImage`, `shopImage`: Photo URLs
- `isActive`: Account status
- Location (pincode-based): `pincode`, `country`, `state`, `district`, `city`, `area`, `address`
- GPS: `latitude`, `longitude`
- `areaId`: Legacy area relation
- Assignment: `assignedToId`, `assignedDays` (beat days array)
- Approval: `createdById`, `approvedById`, `approvedAt`, `isApproved`, `verificationNotes`, `rejectionNotes`
- Timestamps: `createdAt`, `updatedAt`

**Relationships:**
- Belongs to: Area (legacy - not used), User (assignedTo, createdBy, approvedBy)

**Usage:**
- Heavily used in account controller
- Used in shop controller for account creation
- Referenced in beat planning
- Used in salesman reports
- Critical for CRM functionality
- **Note:** Location stored as STRING fields (pincode, country, state, district, city, area), NOT as foreign keys to location hierarchy tables

---

## Attendance & Tracking

### 13. Attendance
**Purpose:** Track employee punch-in/punch-out and work hours  
**Status:** ✅ ACTIVE (Critical for workforce management)  
**Primary Key:** `id` (String CUID)

**Fields:**
- `id`: Unique identifier
- `employeeId`: Foreign key to User
- `employeeName`: Employee name
- `date`: Attendance date
- Punch In: `punchInTime`, `punchInLatitude`, `punchInLongitude`, `punchInPhoto`, `punchInAddress`, `bikeKmStart`
- Punch Out: `punchOutTime`, `punchOutLatitude`, `punchOutLongitude`, `punchOutPhoto`, `punchOutAddress`, `bikeKmEnd`
- Calculated: `totalWorkHours`, `totalDistanceKm`
- `status`: active, completed
- Late approval: `isLatePunchIn`, `lateApprovalId`, `approvalCode`
- Early punch-out: `isEarlyPunchOut`, `earlyPunchOutApprovalId`, `earlyPunchOutCode`
- Timestamps: `createdAt`, `updatedAt`

**Relationships:**
- Has many: SalesmanTrackingPoints

**Usage:**
- Used extensively in attendance controller
- Referenced in punch status controller
- Used in salesman reports
- Integrated with approval workflows
- Tracks live location during work hours

---

### 14. SalesmanTrackingPoint
**Purpose:** Store GPS tracking points during active attendance sessions  
**Status:** ✅ ACTIVE (Live tracking feature)  
**Primary Key:** `id` (String CUID)

**Fields:**
- `id`: Unique identifier
- `employeeId`: Foreign key to User
- `attendanceId`: Foreign key to Attendance
- `latitude`, `longitude`: GPS coordinates
- `speed`: Movement speed
- `accuracy`: GPS accuracy
- `recordedAt`: Timestamp

**Relationships:**
- Belongs to: User, Attendance

**Usage:**
- Used in tracking controller
- Stores real-time location data
- Enables live tracking of salesmen
- Used for route analysis and verification

---

## Leave Management

### 15. Leave
**Purpose:** Employee leave requests and approvals  
**Status:** ✅ ACTIVE (HR management)  
**Primary Key:** `id` (String CUID)

**Fields:**
- `id`: Unique identifier
- `employeeId`: Foreign key to User
- `employeeName`: Employee name
- `leaveType`: Sick, Casual, Earned, Unpaid, Emergency, Maternity, Paternity
- `startDate`, `endDate`: Leave period
- `numberOfDays`: Total leave days
- `reason`: Leave reason
- `status`: PENDING, APPROVED, REJECTED, CANCELLED
- Approval: `requestedAt`, `approvedBy`, `approvedAt`, `rejectionReason`, `adminRemarks`
- Timestamps: `createdAt`, `updatedAt`

**Relationships:**
- Belongs to: User (employee), User (approver)

**Usage:**
- Used in leave controller
- Used in leave service for balance management
- Integrated with approval workflow
- Referenced in employee reports

---

### 16. LeaveBalance
**Purpose:** Track annual leave allocations and usage per employee  
**Status:** ✅ ACTIVE (HR management)  
**Primary Key:** `id` (String CUID)

**Fields:**
- `id`: Unique identifier
- `employeeId`: Foreign key to User (Unique)
- `year`: Leave balance year
- Allocations: `sickLeaves` (12), `casualLeaves` (10), `earnedLeaves` (20)
- Used: `usedSickLeaves`, `usedCasualLeaves`, `usedEarnedLeaves`
- Timestamps: `createdAt`, `updatedAt`

**Relationships:**
- Belongs to: User (one-to-one)

**Usage:**
- Used in leave service
- Auto-created when employee requests leave
- Tracks remaining leave balance
- Updated when leaves are approved/rejected

---

## Approval Workflow Tables

### 17. LatePunchApproval
**Purpose:** Handle late punch-in approval requests from employees  
**Status:** ✅ ACTIVE (Approval workflow)  
**Primary Key:** `id` (String CUID)

**Fields:**
- `id`: Unique identifier
- `employeeId`: Foreign key to User
- `employeeName`: Employee name
- `requestDate`: Request timestamp
- `punchInDate`: Intended punch-in date
- `reason`: Reason for late punch-in
- `status`: PENDING, APPROVED, REJECTED
- Admin response: `approvedBy`, `approvedAt`, `adminRemarks`
- Approval code: `approvalCode`, `codeExpiresAt`, `codeUsed`, `codeUsedAt`
- Timestamps: `createdAt`, `updatedAt`

**Relationships:**
- Belongs to: User (employee), User (approver)

**Usage:**
- Used in late punch approval controller
- Generates OTP codes for approved requests
- Integrated with attendance system
- Tracks code usage and expiry

---

### 18. EarlyPunchOutApproval
**Purpose:** Handle early punch-out approval requests  
**Status:** ✅ ACTIVE (Approval workflow)  
**Primary Key:** `id` (String CUID)

**Fields:**
- `id`: Unique identifier
- `employeeId`: Foreign key to User
- `employeeName`: Employee name
- `attendanceId`: Current attendance session
- `requestDate`: Request timestamp
- `punchOutDate`: Intended punch-out date
- `reason`: Reason for early punch-out
- `status`: PENDING, APPROVED, REJECTED
- Admin response: `approvedBy`, `approvedAt`, `adminRemarks`
- Approval code: `approvalCode`, `codeExpiresAt`, `codeUsed`, `codeUsedAt`
- Timestamps: `createdAt`, `updatedAt`

**Relationships:**
- Belongs to: User (employee), User (approver)

**Usage:**
- Used in early punch-out approval controller
- Generates OTP codes for approved requests
- Linked to active attendance sessions
- Tracks code usage and expiry

---

## Beat Planning Tables

### 19. WeeklyBeatPlan
**Purpose:** Weekly territory/area assignment plans for salesmen  
**Status:** ✅ ACTIVE (Territory management)  
**Primary Key:** `id` (String CUID)

**Fields:**
- `id`: Unique identifier
- `salesmanId`: Foreign key to User
- `salesmanName`: Salesman name
- `weekStartDate`: Monday of the week
- `weekEndDate`: Sunday of the week
- `pincodes`: Array of assigned pincodes
- `totalAreas`: Number of areas to cover
- `status`: DRAFT, ACTIVE, LOCKED, COMPLETED
- Admin control: `generatedBy`, `approvedBy`, `approvedAt`, `lockedBy`, `lockedAt`
- Timestamps: `createdAt`, `updatedAt`

**Relationships:**
- Belongs to: User (salesman, generator, approver, locker)
- Has many: DailyBeatPlans

**Unique Constraint:** One plan per salesman per week

**Usage:**
- Used in beat plan controller
- Used in beat plan service
- Manages weekly territory assignments
- Supports auto-migration of beat plans

---

### 20. DailyBeatPlan
**Purpose:** Day-wise breakdown of weekly beat plans  
**Status:** ✅ ACTIVE (Daily territory planning)  
**Primary Key:** `id` (String CUID)

**Fields:**
- `id`: Unique identifier
- `weeklyBeatId`: Foreign key to WeeklyBeatPlan
- `dayOfWeek`: 1=Monday ... 7=Sunday
- `dayDate`: Actual date
- `assignedAreas`: Array of area names for the day
- `plannedVisits`: Number of planned visits
- `actualVisits`: Number of completed visits
- `status`: PLANNED, IN_PROGRESS, COMPLETED, MISSED
- `completedAt`: Completion timestamp
- Carry forward: `carriedFromDate`, `carriedToDate`
- Timestamps: `createdAt`, `updatedAt`

**Relationships:**
- Belongs to: WeeklyBeatPlan
- Has many: BeatCompletions

**Unique Constraint:** One plan per day per weekly beat

**Usage:**
- Used in beat plan controller
- Tracks daily progress
- Supports missed beat carry-forward
- Used in salesman daily reports

---

### 21. BeatCompletion
**Purpose:** Track completion of individual area visits  
**Status:** ✅ ACTIVE (Beat tracking)  
**Primary Key:** `id` (String CUID)

**Fields:**
- `id`: Unique identifier
- `dailyBeatId`: Foreign key to DailyBeatPlan
- `salesmanId`: Foreign key to User
- `areaName`: Area visited
- `accountsVisited`: Number of accounts visited
- `completedAt`: Completion timestamp
- `latitude`, `longitude`: GPS location
- `notes`: Optional notes
- Verification: `isVerified`, `verifiedBy`, `verifiedAt`
- Timestamps: `createdAt`, `updatedAt`

**Relationships:**
- Belongs to: DailyBeatPlan, User (salesman), User (verifier)

**Usage:**
- Used in beat plan controller
- Tracks area-wise completion
- Supports admin verification
- Used in performance reports

---

## Financial Tables

### 22. SalaryInformation
**Purpose:** Store employee salary structure and bank details  
**Status:** ✅ ACTIVE (HR/Payroll)  
**Primary Key:** `id` (String CUID)

**Fields:**
- `id`: Unique identifier
- `employeeId`: Foreign key to User (Unique)
- `basicSalary`: Base salary
- Allowances: `hra`, `travelAllowance`, `dailyAllowance`, `medicalAllowance`, `specialAllowance`, `otherAllowances`
- Deductions: `providentFund`, `professionalTax`, `incomeTax`, `otherDeductions`
- `effectiveFrom`, `effectiveTo`: Validity period
- `currency`: Default INR
- `paymentFrequency`: Default Monthly
- Bank details: `bankName`, `accountNumber`, `ifscCode`
- `panNumber`: PAN card
- `remarks`: Additional notes
- `isActive`: Status
- Timestamps: `createdAt`, `updatedAt`

**Relationships:**
- Belongs to: User (one-to-one)

**Usage:**
- Used in salary controller
- Stores complete salary structure
- Supports salary history with effectiveFrom/To
- Used in payroll processing

---

### 23. Expense
**Purpose:** Track employee expense claims and reimbursements  
**Status:** ✅ ACTIVE (Expense management)  
**Primary Key:** `id` (String CUID)

**Fields:**
- `id`: Unique identifier
- `employeeId`: Foreign key to User
- `expenseType`: Travel, Food, Accommodation, Fuel, Other
- `amount`: Expense amount
- `expenseDate`: Date of expense
- `description`: Expense description
- `billNumber`: Bill/receipt number
- `attachmentUrl`: Bill image URL
- `status`: Pending, Approved, Rejected, Paid
- Approval: `approvedBy`, `approvedAt`, `rejectionReason`
- `paidAt`: Payment timestamp
- `remarks`: Additional notes
- Timestamps: `createdAt`, `updatedAt`

**Relationships:**
- Belongs to: User (employee), User (approver)

**Usage:**
- Used in expense controller
- Tracks expense claims
- Supports approval workflow
- Used in financial reports

---

## Task & Area Assignment

### 24. TaskAssignment
**Purpose:** Assign specific tasks/territories to salesmen  
**Status:** ⚠️ PARTIALLY USED (Legacy/alternative to beat planning)  
**Primary Key:** `id` (String CUID)

**Fields:**
- `id`: Unique identifier
- `salesmanId`: Salesman ID
- `salesmanName`: Salesman name
- `pincode`: Assigned pincode
- Location: `country`, `state`, `district`, `city`
- `areas`: Array of area names
- `businessTypes`: Array of business types to focus on
- `totalBusinesses`: Number of businesses
- `assignedDate`: Assignment date
- Timestamps: `createdAt`, `updatedAt`

**Relationships:**
- None (stores denormalized data)

**Usage:**
- Used in task assignment controller
- Alternative to beat planning
- Less frequently used than WeeklyBeatPlan
- Stores static assignments

---

### 25. AreaAssignment
**Purpose:** Assign geographical areas to salesmen  
**Status:** ✅ ACTIVE (Territory assignment)  
**Primary Key:** `id` (String CUID)

**Fields:**
- `id`: Unique identifier
- `salesmanId`: Foreign key to User
- `pinCode`: Assigned pincode
- Location: `country`, `state`, `district`, `city`
- `areas`: Array of area names
- `businessTypes`: Array of business types
- `assignedDate`: Assignment date
- `totalBusinesses`: Number of businesses
- Timestamps: `createdAt`, `updatedAt`

**Relationships:**
- Belongs to: User (salesman)

**Usage:**
- Used in area assignment controller
- Seeded with initial assignments
- Used for territory management
- Referenced in salesman operations

---

## Notification System

### 26. Notification
**Purpose:** System notifications for users  
**Status:** ✅ ACTIVE (Communication system)  
**Primary Key:** `id` (String CUID)

**Fields:**
- `id`: Unique identifier
- `title`: Notification title
- `message`: Notification message
- `type`: punch_in, punch_out, general, alert, late_punch_approval
- `priority`: low, normal, high, urgent
- `targetRole`: Target role (null = all)
- `targetUserId`: Specific user (null = all with role)
- `data`: JSON additional data
- `isRead`: Read status
- `readAt`: Read timestamp
- Timestamps: `createdAt`, `updatedAt`

**Relationships:**
- Belongs to: User (optional)

**Usage:**
- Used in notification controller
- Used in notification service
- Sends notifications for attendance, approvals, etc.
- Supports role-based and user-specific notifications

---

## Unused/Legacy Tables

### 27. Shop
**Purpose:** Originally intended for Google Places API shop data  
**Status:** ❌ NOT USED (Replaced by Account table)  
**Primary Key:** `id` (String CUID)

**Fields:**
- `id`: Unique identifier
- `placeId`: Google Places ID
- `name`: Shop name
- `businessType`: Type of business
- Address: `address`, `pincode`, `area`, `city`, `state`, `country`
- GPS: `latitude`, `longitude`
- `phoneNumber`: Contact number
- `rating`: Shop rating
- `stage`: new, follow-up, converted, lost
- `assignedTo`: Salesman ID
- `notes`: Additional notes
- `lastContactDate`: Last contact date
- Timestamps: `createdAt`, `updatedAt`

**Why Not Used:**
- Functionality merged into Account table
- Account table handles both manual and Google Places data
- No controller actively uses Shop model
- Can be removed in future cleanup

---

### Location Hierarchy Tables (All Unused)

See the "Location Hierarchy Tables (UNUSED - Legacy Structure)" section above for details on:
- Country
- State  
- Region
- District
- City
- Zone
- Area

All these tables have controllers but contain no data and are not used in the application. The application uses a pincode-based system with STRING fields instead.

---

## Database Relationships

### Relationship Summary

**One-to-One Relationships:**
- User ↔ EmployeeArea
- User ↔ SalaryInformation
- User ↔ LeaveBalance

**One-to-Many Relationships:**
- Country → States → Regions → Districts → Cities → Zones → Areas (Location hierarchy)
- User → Accounts (created, assigned, approved)
- User → Expenses (created, approved)
- User → Notifications
- User → Leave requests
- User → Approval requests (late punch, early punch-out)
- User → Beat plans (salesman, generator, approver)
- User → Tracking points
- WeeklyBeatPlan → DailyBeatPlans
- DailyBeatPlan → BeatCompletions
- Attendance → TrackingPoints

**Many-to-Many Relationships:**
- None (handled through arrays or junction tables)

---

## Key Insights

## Key Insights

### ✅ Actively Used Tables (16/29)
1. **User** - Central user/employee management (HEAVILY USED)
2. **Department** - Employee departments (ACTIVE)
3. **Role** - User roles and permissions (ACTIVE)
4. **Account** - Customer/business management (HEAVILY USED)
5. **Attendance** - Punch in/out tracking (HEAVILY USED)
6. **SalesmanTrackingPoint** - Live GPS tracking (ACTIVE)
7. **Leave** - Leave requests (ACTIVE)
8. **LeaveBalance** - Leave balance tracking (ACTIVE)
9. **LatePunchApproval** - Late punch-in approvals (ACTIVE)
10. **EarlyPunchOutApproval** - Early punch-out approvals (ACTIVE)
11. **WeeklyBeatPlan** - Weekly territory plans (ACTIVE)
12. **DailyBeatPlan** - Daily beat plans (ACTIVE)
13. **BeatCompletion** - Beat completion tracking (ACTIVE)
14. **SalaryInformation** - Employee salary details (ACTIVE)
15. **Expense** - Expense claims (ACTIVE)
16. **AreaAssignment** - Territory assignments (ACTIVE)
17. **Notification** - System notifications (ACTIVE)

### ⚠️ Partially Used Tables (1/29)
1. **TaskAssignment** - Alternative to beat planning, less frequently used than AreaAssignment

### ❌ Unused/Legacy Tables (12/29)
1. **Shop** - Not used, Account table handles this functionality
2. **Country** - No data, not used (location stored as strings)
3. **State** - No data, not used (location stored as strings)
4. **Region** - No data, not used (location stored as strings)
5. **District** - No data, not used (location stored as strings)
6. **City** - No data, not used (location stored as strings)
7. **Zone** - No data, not used (location stored as strings)
8. **Area** - No data, Account.areaId is legacy field (mostly null)
9. **EmployeeArea** - References unused location hierarchy tables

### Critical Tables (Core Business Logic)
1. **User** - Central to all operations, authentication, authorization
2. **Account** - Customer/business management, CRM core
3. **Attendance** - Workforce tracking, punch in/out
4. **WeeklyBeatPlan/DailyBeatPlan** - Territory management
5. **Notification** - System communication
6. **LatePunchApproval/EarlyPunchOutApproval** - Approval workflows

### Tables with Approval Workflows
1. **Account** - Telecaller creates, Admin approves
2. **Leave** - Employee requests, Admin approves
3. **LatePunchApproval** - Employee requests, Admin approves with OTP
4. **EarlyPunchOutApproval** - Employee requests, Admin approves with OTP
5. **Expense** - Employee claims, Admin approves

### Critical Tables (Core Business Logic)
1. User - Central to all operations
2. Account - Customer/business management
3. Attendance - Workforce tracking
4. WeeklyBeatPlan/DailyBeatPlan - Territory management
5. Notification - System communication

### Tables with Approval Workflows
1. Account - Telecaller creates, Admin approves
2. Leave - Employee requests, Admin approves
3. LatePunchApproval - Employee requests, Admin approves with OTP
4. EarlyPunchOutApproval - Employee requests, Admin approves with OTP
5. Expense - Employee claims, Admin approves

---

## Recommendations

### Cleanup Opportunities
1. **Remove Shop table** - Not used, functionality in Account table
2. **Remove entire location hierarchy** - Country, State, Region, District, City, Zone, Area tables are not used
   - No data is populated in these tables
   - Application uses pincode-based STRING fields instead
   - Controllers exist but serve no purpose
   - Account.areaId is a legacy field that's mostly null
3. **Remove EmployeeArea table** - References unused location hierarchy tables
4. **TaskAssignment vs AreaAssignment** - Consolidate if possible
5. **Clean up Account table** - Remove areaId field and areaRelation since Area table is unused

### Optimization Opportunities
1. Add indexes on frequently queried fields (already present on most)
2. Consider archiving old attendance records
3. Implement soft deletes for audit trail
4. Add composite indexes for common query patterns

### Data Integrity
1. All foreign keys have proper cascade rules
2. Unique constraints on critical fields (email, phone, codes)
3. Default values set appropriately
4. Timestamps tracked on all tables

---

