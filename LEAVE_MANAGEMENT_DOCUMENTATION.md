# 📋 Leave Management System - Complete Documentation

## 🎯 Overview

The Leave Management System is a comprehensive end-to-end solution integrated into the Loagma CRM application. It provides complete leave request, approval, and tracking functionality for both employees (Salesman) and administrators.

## ✨ Features

### 👤 **For Employees (Salesman)**
- **Apply for Leave**: Submit leave requests with date validation and reason
- **View Leave History**: See all past and current leave requests with status
- **Leave Balance Tracking**: Monitor available leaves by type (Sick, Casual, Earned)
- **Cancel Pending Requests**: Cancel leave requests that haven't been processed
- **Real-time Notifications**: Get notified when leave is approved/rejected
- **Dashboard Integration**: Quick access and leave statistics on main dashboard

### 👨‍💼 **For Administrators**
- **Pending Requests Management**: View and process all pending leave requests
- **Approve/Reject Leaves**: Make decisions with mandatory remarks
- **Comprehensive Leave History**: View all employee leaves with advanced filtering
- **Employee Context**: See employee details for informed decision making
- **Bulk Operations**: Efficient processing of multiple requests
- **Audit Trail**: Complete history of all leave actions

## 🏗️ Architecture

### **Backend (Node.js + Prisma + PostgreSQL)**

#### Database Schema
```sql
-- Leave Request Table
model Leave {
  id              String    @id @default(cuid())
  employeeId      String    // Employee requesting leave
  employeeName    String    // Employee name for easy reference
  leaveType       String    // Sick, Casual, Earned, Emergency, Unpaid
  startDate       DateTime  // Leave start date
  endDate         DateTime  // Leave end date
  numberOfDays    Int       // Total number of leave days
  reason          String?   // Reason for leave
  status          String    @default("PENDING") // PENDING, APPROVED, REJECTED, CANCELLED
  
  // Approval workflow
  requestedAt     DateTime  @default(now())
  approvedBy      String?   // Admin who approved/rejected
  approvedAt      DateTime? // When the decision was made
  rejectionReason String?   // Admin's reason for rejection
  adminRemarks    String?   // Additional admin comments
  
  // Relations and indexes
  employee        User      @relation("EmployeeLeaves")
  approver        User?     @relation("ApprovedLeaves")
  
  @@index([employeeId, status, startDate])
}

-- Leave Balance Table
model LeaveBalance {
  id              String    @id @default(cuid())
  employeeId      String    @unique
  year            Int       // Leave balance year
  sickLeaves      Int       @default(12)
  casualLeaves    Int       @default(10)
  earnedLeaves    Int       @default(20)
  usedSickLeaves  Int       @default(0)
  usedCasualLeaves Int      @default(0)
  usedEarnedLeaves Int      @default(0)
  
  employee        User      @relation(fields: [employeeId])
}
```

#### API Endpoints

**Employee Endpoints:**
- `POST /leaves` - Apply for leave
- `GET /leaves/my` - Get employee's leave history
- `GET /leaves/balance` - Get leave balance and statistics
- `PATCH /leaves/:id/cancel` - Cancel pending leave request

**Admin Endpoints:**
- `GET /leaves/all` - Get all leaves with filtering
- `GET /leaves/pending` - Get pending leave requests
- `PATCH /leaves/:id/approve` - Approve leave request
- `PATCH /leaves/:id/reject` - Reject leave request with reason

#### Business Logic Services

**LeaveService Class:**
- Working days calculation (excludes weekends)
- Leave balance validation and management
- Overlap detection for leave requests
- Automatic balance updates on approval/rejection
- Leave statistics and analytics

**NotificationService Integration:**
- Leave request notifications to admin
- Approval/rejection notifications to employees
- Rich notification data for UI integration

### **Frontend (Flutter)**

#### Data Models
```dart
class LeaveModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int numberOfDays;
  final String? reason;
  final String status;
  // ... additional fields and helper methods
}

class LeaveBalance {
  final int sickLeaves;
  final int casualLeaves;
  final int earnedLeaves;
  final int usedSickLeaves;
  final int usedCasualLeaves;
  final int usedEarnedLeaves;
  // ... calculated properties
}
```

#### UI Screens

**Salesman Screens:**
- `LeaveManagementScreen` - Main dashboard with balance and history
- `ApplyLeaveScreen` - Comprehensive leave application form

**Admin Screens:**
- `LeaveRequestsScreen` - Tabbed interface for pending and all requests

**Reusable Widgets:**
- `LeaveCard` - Consistent leave display component
- `LeaveBalanceCard` - Visual balance overview with progress indicators

## 🚀 Implementation Details

### **Key Features Implemented**

#### 1. **Smart Date Validation**
- Prevents past date selection
- Calculates working days (excludes weekends)
- Validates date ranges and overlaps

#### 2. **Leave Balance Management**
- Automatic balance tracking by leave type
- Real-time balance updates on approval/rejection
- Visual progress indicators for used vs available leaves

#### 3. **Comprehensive Validation**
- Overlap detection for existing leave requests
- Balance validation (except for unpaid/emergency leaves)
- Mandatory reason validation with minimum length

#### 4. **Role-Based Access Control**
- Employee permissions: Apply, view own, cancel pending
- Admin permissions: View all, approve, reject with remarks
- Proper JWT authentication and role validation

#### 5. **Notification Integration**
- Real-time notifications for leave status changes
- Rich notification data for context
- Integration with existing notification system

#### 6. **Dashboard Integration**
- Leave statistics on salesman dashboard
- Quick action buttons for easy access
- Visual leave balance indicators

### **Business Rules Enforced**

1. **Leave Application Rules:**
   - Cannot apply for past dates
   - Cannot have overlapping leave requests
   - Must provide detailed reason (minimum 10 characters)
   - Working days calculation excludes weekends

2. **Leave Balance Rules:**
   - Sick Leave: 12 days per year
   - Casual Leave: 10 days per year
   - Earned Leave: 20 days per year
   - Emergency/Unpaid: No balance restrictions

3. **Approval Workflow:**
   - Only pending leaves can be approved/rejected
   - Admin must provide remarks for rejection
   - Automatic balance deduction on approval
   - Balance restoration on rejection/cancellation

4. **Cancellation Rules:**
   - Only pending leaves can be cancelled by employee
   - Approved/rejected leaves cannot be cancelled
   - Automatic balance restoration on cancellation

## 🎨 Design System Compliance

### **Color Palette**
- Primary: `Color(0xFFD7BE69)` (Gold/Tan)
- Success: `Colors.green`
- Error: `Colors.red`
- Warning: `Colors.orange`
- Info: `Colors.blue`

### **Status Color Coding**
- **Pending**: Orange (`Colors.orange`)
- **Approved**: Green (`Colors.green`)
- **Rejected**: Red (`Colors.red`)
- **Cancelled**: Grey (`Colors.grey`)

### **Typography & Spacing**
- Headers: `fontSize: 18-20, fontWeight: FontWeight.bold`
- Body: `fontSize: 14, fontWeight: FontWeight.normal`
- Small text: `fontSize: 12, color: Colors.grey[600]`
- Consistent 16px padding and 12px margins

### **Component Styling**
- Cards: `elevation: 2, borderRadius: 12px`
- Buttons: `borderRadius: 8px, padding: 16px horizontal`
- Status badges: `borderRadius: 20px, padding: 6px vertical, 12px horizontal`

## 📱 User Experience

### **Salesman Workflow**
1. **Dashboard Overview**: See leave balance and quick stats
2. **Apply Leave**: 
   - Select leave type with balance display
   - Choose dates with visual calendar
   - Provide detailed reason
   - Real-time validation feedback
3. **Track Requests**: View status with color-coded badges
4. **Manage Requests**: Cancel pending requests if needed

### **Admin Workflow**
1. **Pending Queue**: Prioritized list of requests needing attention
2. **Review Details**: Complete employee and leave information
3. **Make Decision**: Approve with optional remarks or reject with mandatory reason
4. **Track History**: Comprehensive view of all leave activities

### **Mobile-First Design**
- Responsive layouts for all screen sizes
- Touch-friendly buttons and interactions
- Swipe-to-refresh functionality
- Optimized for one-handed use

## 🔧 Configuration & Customization

### **Leave Types Configuration**
```dart
// In LeaveService.getLeaveTypes()
static List<String> getLeaveTypes() {
  return [
    'Sick',      // Medical leave
    'Casual',    // Personal leave
    'Earned',    // Annual leave
    'Emergency', // Urgent situations
    'Unpaid',    // Unpaid leave
  ];
}
```

### **Leave Balance Configuration**
```javascript
// In LeaveService.getOrCreateLeaveBalance()
const defaultBalances = {
  sickLeaves: 12,    // Annual sick leave allocation
  casualLeaves: 10,  // Annual casual leave allocation
  earnedLeaves: 20,  // Annual earned leave allocation
};
```

### **Validation Rules**
```javascript
// Working days calculation excludes weekends
// Minimum reason length: 10 characters
// Maximum future date: 365 days
// Overlap detection: Checks PENDING and APPROVED leaves
```

## 🧪 Testing

### **Backend Tests**
- API endpoint testing with authentication
- Business logic validation
- Database operations and constraints
- Notification system integration

### **Frontend Tests**
- Model serialization/deserialization
- Service method functionality
- Widget rendering and interactions
- Navigation flow testing

### **Test Coverage**
- ✅ Leave application workflow
- ✅ Balance calculation and validation
- ✅ Approval/rejection process
- ✅ Notification delivery
- ✅ UI component rendering
- ✅ Data model integrity

## 🚀 Deployment & Production

### **Database Migration**
```bash
# Apply leave management schema
npx prisma migrate dev --name add_leave_management
npx prisma generate

# Initialize leave balances for existing users
node init_leave_balances.js
```

### **Environment Configuration**
- Ensure JWT authentication is properly configured
- Verify database connection and permissions
- Test notification system integration
- Validate role-based access controls

### **Performance Considerations**
- Database indexes on frequently queried fields
- Pagination for large datasets
- Efficient API calls with proper caching
- Optimized UI rendering with lazy loading

## 📊 Analytics & Monitoring

### **Key Metrics to Track**
- Leave application volume and trends
- Approval/rejection rates by admin
- Leave balance utilization by employee
- Average processing time for requests
- Most common leave types and reasons

### **Monitoring Points**
- API response times and error rates
- Database query performance
- Notification delivery success
- User engagement with leave features

## 🔮 Future Enhancements

### **Potential Features**
1. **Advanced Leave Policies**
   - Carry-forward rules for unused leaves
   - Probation period restrictions
   - Department-specific leave policies

2. **Workflow Enhancements**
   - Multi-level approval process
   - Delegate approval authority
   - Bulk approval operations

3. **Integration Opportunities**
   - Calendar system integration
   - Payroll system connectivity
   - HR management system sync

4. **Analytics Dashboard**
   - Leave trend analysis
   - Team availability planning
   - Predictive leave forecasting

## 📞 Support & Maintenance

### **Common Issues & Solutions**

**Issue**: Leave balance not updating
**Solution**: Check database constraints and service logic

**Issue**: Notifications not delivered
**Solution**: Verify notification service configuration

**Issue**: Date validation errors
**Solution**: Check timezone handling and date formatting

### **Maintenance Tasks**
- Regular database cleanup of old notifications
- Leave balance year-end rollover process
- Performance monitoring and optimization
- Security audit of authentication flows

---

## 🎉 Conclusion

The Leave Management System provides a complete, production-ready solution that seamlessly integrates with the existing Loagma CRM application. It maintains perfect consistency with the current design system while delivering comprehensive leave management functionality for both employees and administrators.

The system is built with scalability, maintainability, and user experience as core principles, ensuring it can grow with your organization's needs while providing an intuitive and efficient leave management experience.

**Ready for Production** ✅
**Fully Tested** ✅
**Design System Compliant** ✅
**Mobile Optimized** ✅
**Scalable Architecture** ✅