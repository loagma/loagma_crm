# Account Master API Testing

## ✅ Fixed Issues

### 1. Dashboard Screen Errors - FIXED
- **Problem**: Name conflict between Flutter's `State` class and location model's `State` class
- **Solution**: Added import alias `import '../models/location_models.dart' as models;`
- **Status**: ✅ All errors resolved

### 2. Backend Server - RUNNING
- **Status**: ✅ Server running on http://localhost:5000
- **Database**: ✅ Connected to PostgreSQL via Prisma

### 3. Account Routes - REGISTERED
- **Status**: ✅ Routes registered at `/accounts`

## API Endpoints

### 1. Create Account
```
POST http://localhost:5000/accounts
Content-Type: application/json

{
  "personName": "John Doe",
  "contactNumber": "9876543210",
  "dateOfBirth": "1990-01-15",
  "businessType": "Retail",
  "customerStage": "Lead",
  "funnelStage": "Awareness",
  "areaId": 1
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "accountCode": "ACC2411XXXX",
    "personName": "John Doe",
    "contactNumber": "9876543210",
    ...
  }
}
```

### 2. Get All Accounts
```
GET http://localhost:5000/accounts?page=1&limit=50
```

### 3. Get Account by ID
```
GET http://localhost:5000/accounts/:id
```

### 4. Update Account
```
PUT http://localhost:5000/accounts/:id
Content-Type: application/json

{
  "customerStage": "Customer",
  "funnelStage": "Converted"
}
```

### 5. Delete Account
```
DELETE http://localhost:5000/accounts/:id
```

### 6. Get Account Stats
```
GET http://localhost:5000/accounts/stats
```

### 7. Bulk Assign Accounts
```
POST http://localhost:5000/accounts/bulk/assign
Content-Type: application/json

{
  "accountIds": ["id1", "id2", "id3"],
  "assignedToId": "user-id"
}
```

## Testing with Postman/Thunder Client

1. **Create Account** - Test with the POST endpoint above
2. **Verify Response** - Should return account with generated `accountCode`
3. **List Accounts** - Use GET endpoint to see all accounts
4. **Update Account** - Test PUT endpoint
5. **Delete Account** - Test DELETE endpoint

## Flutter Integration

The Flutter app already has:
- ✅ `AccountService` class with all API methods
- ✅ `Account` model for data handling
- ✅ `DashboardScreenNew` with account master form
- ✅ Location hierarchy selection (Country → State → District → City → Zone → Area)

## Account Code Generation

Format: `ACC{YY}{MM}{XXXX}`
- `ACC` = Prefix
- `YY` = Year (2 digits)
- `MM` = Month (2 digits)
- `XXXX` = Sequential number (4 digits, resets daily)

Example: `ACC24110001` (First account created in November 2024)

## Next Steps

1. Test account creation from Flutter app
2. Verify location hierarchy works correctly
3. Test account listing and filtering
4. Test account updates and deletion
