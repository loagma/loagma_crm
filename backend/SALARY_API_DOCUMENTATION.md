# Salary Management API Documentation

## Overview
This API provides comprehensive salary and allowance management for employees, including travel allowance, daily allowance, and other compensation components.

## Base URL
```
http://your-server:5000/salaries
```

## Endpoints

### 1. Create or Update Salary Information
**POST** `/salaries`

Creates new salary information or updates existing salary for an employee.

**Request Body:**
```json
{
  "employeeId": "string (required)",
  "basicSalary": "number (required)",
  "hra": "number (optional)",
  "travelAllowance": "number (optional)",
  "dailyAllowance": "number (optional)",
  "medicalAllowance": "number (optional)",
  "specialAllowance": "number (optional)",
  "otherAllowances": "number (optional)",
  "providentFund": "number (optional)",
  "professionalTax": "number (optional)",
  "incomeTax": "number (optional)",
  "otherDeductions": "number (optional)",
  "effectiveFrom": "ISO date string (required)",
  "effectiveTo": "ISO date string (optional)",
  "currency": "string (default: INR)",
  "paymentFrequency": "string (default: Monthly)",
  "bankName": "string (optional)",
  "accountNumber": "string (optional)",
  "ifscCode": "string (optional)",
  "panNumber": "string (optional)",
  "remarks": "string (optional)",
  "isActive": "boolean (default: true)"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Salary information created successfully",
  "data": {
    "id": "string",
    "employeeId": "string",
    "basicSalary": 50000,
    "travelAllowance": 5000,
    "dailyAllowance": 2000,
    "grossSalary": 57000,
    "totalDeductions": 5000,
    "netSalary": 52000,
    "employee": {
      "id": "string",
      "name": "John Doe",
      "employeeCode": "EMP001",
      "designation": "Sales Manager"
    }
  }
}
```

### 2. Get Salary by Employee ID
**GET** `/salaries/:employeeId`

Retrieves salary information for a specific employee.

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "string",
    "employeeId": "string",
    "basicSalary": 50000,
    "hra": 10000,
    "travelAllowance": 5000,
    "dailyAllowance": 2000,
    "medicalAllowance": 3000,
    "specialAllowance": 2000,
    "otherAllowances": 1000,
    "providentFund": 3000,
    "professionalTax": 1000,
    "incomeTax": 5000,
    "otherDeductions": 500,
    "grossSalary": 73000,
    "totalDeductions": 9500,
    "netSalary": 63500,
    "effectiveFrom": "2024-01-01T00:00:00.000Z",
    "currency": "INR",
    "paymentFrequency": "Monthly",
    "employee": {
      "id": "string",
      "name": "John Doe",
      "employeeCode": "EMP001",
      "designation": "Sales Manager",
      "email": "john@example.com",
      "contactNumber": "+919876543210",
      "department": {
        "id": "string",
        "name": "Sales"
      }
    }
  }
}
```

### 3. Get All Salaries
**GET** `/salaries`

Retrieves all salary information with optional filters.

**Query Parameters:**
- `departmentId` (optional): Filter by department
- `isActive` (optional): Filter by active status (true/false)
- `minSalary` (optional): Minimum basic salary
- `maxSalary` (optional): Maximum basic salary
- `search` (optional): Search by employee name, code, or email
- `page` (optional, default: 1): Page number
- `limit` (optional, default: 50): Items per page

**Example:**
```
GET /salaries?departmentId=dept123&isActive=true&page=1&limit=20
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "string",
      "employeeId": "string",
      "basicSalary": 50000,
      "travelAllowance": 5000,
      "dailyAllowance": 2000,
      "grossSalary": 57000,
      "totalDeductions": 5000,
      "netSalary": 52000,
      "employee": {
        "name": "John Doe",
        "employeeCode": "EMP001",
        "designation": "Sales Manager",
        "department": {
          "name": "Sales"
        }
      }
    }
  ],
  "pagination": {
    "total": 100,
    "page": 1,
    "limit": 20,
    "totalPages": 5
  }
}
```

### 4. Get Salary Statistics
**GET** `/salaries/statistics`

Retrieves comprehensive salary statistics and expense monitoring data.

**Query Parameters:**
- `departmentId` (optional): Filter statistics by department

**Response:**
```json
{
  "success": true,
  "data": {
    "totalEmployees": 50,
    "totalBasicSalary": 2500000,
    "totalTravelAllowance": 250000,
    "totalDailyAllowance": 100000,
    "totalGrossSalary": 3650000,
    "totalDeductions": 475000,
    "totalNetSalary": 3175000,
    "averageBasicSalary": 50000,
    "averageGrossSalary": 73000,
    "averageNetSalary": 63500,
    "departmentWise": {
      "Sales": {
        "count": 20,
        "totalBasicSalary": 1000000,
        "totalTravelAllowance": 100000,
        "totalDailyAllowance": 40000,
        "totalGrossSalary": 1460000,
        "totalNetSalary": 1270000
      },
      "Marketing": {
        "count": 15,
        "totalBasicSalary": 750000,
        "totalTravelAllowance": 75000,
        "totalDailyAllowance": 30000,
        "totalGrossSalary": 1095000,
        "totalNetSalary": 952500
      }
    }
  }
}
```

### 5. Delete Salary Information
**DELETE** `/salaries/:employeeId`

Deletes salary information for a specific employee.

**Response:**
```json
{
  "success": true,
  "message": "Salary information deleted successfully"
}
```

## Salary Calculation

### Gross Salary
```
Gross Salary = Basic Salary + HRA + Travel Allowance + Daily Allowance + 
               Medical Allowance + Special Allowance + Other Allowances
```

### Total Deductions
```
Total Deductions = Provident Fund + Professional Tax + Income Tax + Other Deductions
```

### Net Salary
```
Net Salary = Gross Salary - Total Deductions
```

## Use Cases for Expense Monitoring

### 1. Travel Expense Tracking
Monitor total travel allowances across the organization:
```
GET /salaries/statistics
```
Check `totalTravelAllowance` in the response.

### 2. Daily Allowance Monitoring
Track daily allowances by department:
```
GET /salaries/statistics?departmentId=dept123
```
Check `totalDailyAllowance` in the response.

### 3. Department-wise Expense Analysis
Get complete breakdown of expenses by department:
```
GET /salaries/statistics
```
Check `departmentWise` object for detailed breakdown.

### 4. Employee Compensation Report
Get all active employee salaries:
```
GET /salaries?isActive=true
```

### 5. Salary Range Analysis
Find employees within a specific salary range:
```
GET /salaries?minSalary=40000&maxSalary=60000
```

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "message": "Employee ID, Basic Salary, and Effective From date are required"
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "Employee not found"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "message": "Failed to save salary information",
  "error": "Error details"
}
```

## Notes

1. **Currency Support**: Default is INR, but can be customized per employee
2. **Payment Frequency**: Supports Monthly, Quarterly, and Annually
3. **Effective Dates**: Track salary changes over time with effectiveFrom and effectiveTo
4. **Bank Details**: Store banking information for salary processing
5. **Active Status**: Mark salary records as active/inactive for historical tracking
6. **Automatic Calculations**: Gross salary, deductions, and net salary are calculated automatically
7. **Department-wise Analytics**: Get expense breakdowns by department for better budget management
