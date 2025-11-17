# Account Master CRUD API Documentation

## Base URL
```
http://localhost:5000/accounts
```

## Authentication
All endpoints require Bearer token authentication.
```
Authorization: Bearer <your_jwt_token>
```

---

## Endpoints

### 1. Create Account
**POST** `/accounts`

Creates a new account with automatic tracking of creator.

**Request Body:**
```json
{
  "personName": "John Doe",
  "contactNumber": "9876543210",
  "dateOfBirth": "1990-01-15T00:00:00.000Z",
  "businessType": "Retail",
  "customerStage": "Lead",
  "funnelStage": "Awareness",
  "areaId": 123,
  "createdById": "user-uuid" // Optional, auto-filled from token
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Account created successfully",
  "data": {
    "id": "account-uuid",
    "accountCode": "ACC250100001",
    "personName": "John Doe",
    "contactNumber": "9876543210",
    "dateOfBirth": "1990-01-15T00:00:00.000Z",
    "businessType": "Retail",
    "customerStage": "Lead",
    "funnelStage": "Awareness",
    "isApproved": false,
    "createdById": "user-uuid",
    "approvedById": null,
    "approvedAt": null,
    "areaId": 123,
    "createdAt": "2025-01-17T10:30:00.000Z",
    "updatedAt": "2025-01-17T10:30:00.000Z",
    "createdBy": {
      "id": "user-uuid",
      "name": "Creator Name",
      "contactNumber": "1234567890",
      "roleId": "role-id"
    },
    "area": {
      "area_id": 123,
      "area_name": "Downtown",
      "zone": { ... }
    }
  }
}
```

---

### 2. Get All Accounts
**GET** `/accounts`

Fetches accounts with pagination and filtering.

**Query Parameters:**
- `page` (number, default: 1) - Page number
- `limit` (number, default: 50) - Items per page
- `search` (string) - Search by name, code, or phone
- `areaId` (number) - Filter by area
- `assignedToId` (string) - Filter by assigned user
- `customerStage` (string) - Filter by customer stage
- `funnelStage` (string) - Filter by funnel stage
- `isApproved` (boolean) - Filter by approval status
- `createdById` (string) - Filter by creator

**Example:**
```
GET /accounts?page=1&limit=20&isApproved=false&customerStage=Lead
```

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "account-uuid",
      "accountCode": "ACC250100001",
      "personName": "John Doe",
      "contactNumber": "9876543210",
      "isApproved": false,
      "createdBy": {
        "id": "user-uuid",
        "name": "Creator Name",
        "roleId": "salesman"
      },
      ...
    }
  ],
  "pagination": {
    "total": 150,
    "page": 1,
    "limit": 20,
    "totalPages": 8
  }
}
```

---

### 3. Get Account by ID
**GET** `/accounts/:id`

Fetches a single account with full details.

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "account-uuid",
    "accountCode": "ACC250100001",
    "personName": "John Doe",
    "contactNumber": "9876543210",
    "dateOfBirth": "1990-01-15T00:00:00.000Z",
    "businessType": "Retail",
    "customerStage": "Lead",
    "funnelStage": "Awareness",
    "isApproved": false,
    "createdById": "user-uuid",
    "approvedById": null,
    "approvedAt": null,
    "createdAt": "2025-01-17T10:30:00.000Z",
    "updatedAt": "2025-01-17T10:30:00.000Z",
    "createdBy": {
      "id": "user-uuid",
      "name": "Creator Name",
      "contactNumber": "1234567890",
      "email": "creator@example.com",
      "roleId": "salesman"
    },
    "approvedBy": null,
    "assignedTo": null,
    "area": {
      "area_id": 123,
      "area_name": "Downtown",
      "zone": {
        "zone_id": 45,
        "zone_name": "Central Zone",
        "city": { ... }
      }
    }
  }
}
```

---

### 4. Update Account
**PUT** `/accounts/:id`

Updates an existing account.

**Request Body:**
```json
{
  "personName": "John Updated",
  "contactNumber": "9876543210",
  "businessType": "Wholesale",
  "customerStage": "Prospect",
  "funnelStage": "Interest"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Account updated successfully",
  "data": {
    "id": "account-uuid",
    "accountCode": "ACC250100001",
    "personName": "John Updated",
    ...
  }
}
```

---

### 5. Delete Account
**DELETE** `/accounts/:id`

Deletes an account permanently.

**Response (200):**
```json
{
  "success": true,
  "message": "Account deleted successfully"
}
```

---

### 6. Approve Account
**POST** `/accounts/:id/approve`

Approves an account (typically by manager/admin).

**Request Body:**
```json
{
  "approvedById": "approver-user-uuid" // Optional, auto-filled from token
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Account approved successfully",
  "data": {
    "id": "account-uuid",
    "accountCode": "ACC250100001",
    "isApproved": true,
    "approvedById": "approver-uuid",
    "approvedAt": "2025-01-17T11:00:00.000Z",
    "approvedBy": {
      "id": "approver-uuid",
      "name": "Manager Name",
      "contactNumber": "1234567890"
    },
    ...
  }
}
```

---

### 7. Reject Account Approval
**POST** `/accounts/:id/reject`

Rejects/removes approval from an account.

**Response (200):**
```json
{
  "success": true,
  "message": "Account approval rejected",
  "data": {
    "id": "account-uuid",
    "isApproved": false,
    "approvedById": null,
    "approvedAt": null,
    ...
  }
}
```

---

### 8. Get Account Statistics
**GET** `/accounts/stats`

Gets statistics about accounts.

**Query Parameters:**
- `assignedToId` (string) - Filter by assigned user
- `areaId` (number) - Filter by area
- `createdById` (string) - Filter by creator

**Response (200):**
```json
{
  "success": true,
  "data": {
    "totalAccounts": 150,
    "approvedAccounts": 120,
    "pendingAccounts": 30,
    "byCustomerStage": [
      { "customerStage": "Lead", "_count": 50 },
      { "customerStage": "Prospect", "_count": 60 },
      { "customerStage": "Customer", "_count": 40 }
    ],
    "byFunnelStage": [
      { "funnelStage": "Awareness", "_count": 45 },
      { "funnelStage": "Interest", "_count": 55 },
      { "funnelStage": "Converted", "_count": 50 }
    ],
    "recentAccounts": [
      {
        "id": "account-uuid",
        "accountCode": "ACC250100001",
        "personName": "John Doe",
        "contactNumber": "9876543210",
        "customerStage": "Lead",
        "isApproved": false,
        "createdAt": "2025-01-17T10:30:00.000Z",
        "createdBy": {
          "name": "Creator Name",
          "roleId": "salesman"
        }
      }
    ]
  }
}
```

---

### 9. Bulk Assign Accounts
**POST** `/accounts/bulk/assign`

Assigns multiple accounts to a user.

**Request Body:**
```json
{
  "accountIds": ["account-uuid-1", "account-uuid-2", "account-uuid-3"],
  "assignedToId": "user-uuid"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "3 accounts assigned successfully",
  "count": 3
}
```

---

### 10. Bulk Approve Accounts
**POST** `/accounts/bulk/approve`

Approves multiple accounts at once.

**Request Body:**
```json
{
  "accountIds": ["account-uuid-1", "account-uuid-2", "account-uuid-3"],
  "approvedById": "approver-uuid" // Optional, auto-filled from token
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "3 accounts approved successfully",
  "count": 3
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "message": "Person name and contact number are required"
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "Account not found"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "message": "Error message details"
}
```

---

## Account Code Format

Account codes are automatically generated in the format:
```
ACC + YY + MM + XXXX
```

Where:
- `ACC` = Prefix
- `YY` = Last 2 digits of year
- `MM` = Month (01-12)
- `XXXX` = Sequential number (0001-9999)

Example: `ACC250100001` = First account created in January 2025

---

## Role-Based Access

### Salesman / Telecaller
- ✅ Create accounts (auto-tracked as creator)
- ✅ View their own created accounts
- ✅ Edit their own created accounts
- ✅ Delete their own created accounts
- ❌ Approve accounts

### Manager / Admin
- ✅ View all accounts
- ✅ Approve/Reject accounts
- ✅ Bulk operations
- ✅ View statistics

---

## Testing with cURL

### Create Account
```bash
curl -X POST http://localhost:5000/accounts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "personName": "Test User",
    "contactNumber": "9876543210",
    "customerStage": "Lead"
  }'
```

### Get Accounts
```bash
curl "http://localhost:5000/accounts?page=1&limit=10" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Approve Account
```bash
curl -X POST http://localhost:5000/accounts/ACCOUNT_ID/approve \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN"
```
