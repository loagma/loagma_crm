# Loagma CRM Backend API Documentation

## Base URL
```
http://localhost:5000
```

---

## 🌍 LOCATION MASTER APIs

### Countries

#### Get All Countries
```http
GET /locations/countries
```
**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "India",
      "createdAt": "2024-01-01T00:00:00.000Z",
      "_count": { "states": 5 }
    }
  ]
}
```

#### Create Country
```http
POST /locations/countries
Content-Type: application/json

{
  "name": "India"
}
```

#### Update Country
```http
PUT /locations/countries/:id
Content-Type: application/json

{
  "name": "India"
}
```

#### Delete Country
```http
DELETE /locations/countries/:id
```

---

### States

#### Get All States
```http
GET /locations/states
GET /locations/states?countryId=uuid
```

#### Create State
```http
POST /locations/states
Content-Type: application/json

{
  "name": "Gujarat",
  "countryId": "uuid"
}
```

#### Update State
```http
PUT /locations/states/:id
Content-Type: application/json

{
  "name": "Gujarat",
  "countryId": "uuid"
}
```

#### Delete State
```http
DELETE /locations/states/:id
```

---

### Districts

#### Get All Districts
```http
GET /locations/districts
GET /locations/districts?stateId=uuid
```

#### Create District
```http
POST /locations/districts
Content-Type: application/json

{
  "name": "Ahmedabad",
  "stateId": "uuid"
}
```

#### Update District
```http
PUT /locations/districts/:id
Content-Type: application/json

{
  "name": "Ahmedabad",
  "stateId": "uuid"
}
```

#### Delete District
```http
DELETE /locations/districts/:id
```

---

### Cities

#### Get All Cities
```http
GET /locations/cities
GET /locations/cities?districtId=uuid
```

#### Create City
```http
POST /locations/cities
Content-Type: application/json

{
  "name": "Ahmedabad City",
  "districtId": "uuid"
}
```

#### Update City
```http
PUT /locations/cities/:id
Content-Type: application/json

{
  "name": "Ahmedabad City",
  "districtId": "uuid"
}
```

#### Delete City
```http
DELETE /locations/cities/:id
```

---

### Zones

#### Get All Zones
```http
GET /locations/zones
GET /locations/zones?cityId=uuid
```

#### Create Zone
```http
POST /locations/zones
Content-Type: application/json

{
  "name": "West Zone",
  "cityId": "uuid"
}
```

#### Update Zone
```http
PUT /locations/zones/:id
Content-Type: application/json

{
  "name": "West Zone",
  "cityId": "uuid"
}
```

#### Delete Zone
```http
DELETE /locations/zones/:id
```

---

### Areas

#### Get All Areas
```http
GET /locations/areas
GET /locations/areas?zoneId=uuid
```

#### Create Area
```http
POST /locations/areas
Content-Type: application/json

{
  "name": "Vastrapur",
  "zoneId": "uuid"
}
```

#### Update Area
```http
PUT /locations/areas/:id
Content-Type: application/json

{
  "name": "Vastrapur",
  "zoneId": "uuid"
}
```

#### Delete Area
```http
DELETE /locations/areas/:id
```

---

## 👤 ACCOUNT MASTER APIs

### Get All Accounts
```http
GET /accounts
GET /accounts?page=1&limit=50
GET /accounts?areaId=uuid
GET /accounts?assignedToId=uuid
GET /accounts?customerStage=Lead
GET /accounts?funnelStage=Prospect
GET /accounts?search=John
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "accountCode": "ACC2401001",
      "personName": "John Doe",
      "dateOfBirth": "1990-01-01T00:00:00.000Z",
      "contactNumber": "9876543210",
      "businessType": "Retail",
      "customerStage": "Lead",
      "funnelStage": "Prospect",
      "assignedToId": "uuid",
      "areaId": "uuid",
      "createdAt": "2024-01-01T00:00:00.000Z",
      "updatedAt": "2024-01-01T00:00:00.000Z",
      "assignedTo": {
        "id": "uuid",
        "name": "Sales Person",
        "contactNumber": "9999999999"
      },
      "area": {
        "id": "uuid",
        "name": "Vastrapur",
        "zone": {
          "name": "West Zone",
          "city": {
            "name": "Ahmedabad City"
          }
        }
      }
    }
  ],
  "pagination": {
    "total": 100,
    "page": 1,
    "limit": 50,
    "totalPages": 2
  }
}
```

### Get Account by ID
```http
GET /accounts/:id
```

### Create Account
```http
POST /accounts
Content-Type: application/json

{
  "personName": "John Doe",
  "dateOfBirth": "1990-01-01",
  "contactNumber": "9876543210",
  "businessType": "Retail",
  "customerStage": "Lead",
  "funnelStage": "Prospect",
  "assignedToId": "uuid",
  "areaId": "uuid"
}
```

**Required Fields:**
- `personName` (string)
- `contactNumber` (string)

**Optional Fields:**
- `dateOfBirth` (date)
- `businessType` (string)
- `customerStage` (string)
- `funnelStage` (string)
- `assignedToId` (uuid)
- `areaId` (uuid)

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "accountCode": "ACC2401001",
    "personName": "John Doe",
    ...
  }
}
```

### Update Account
```http
PUT /accounts/:id
Content-Type: application/json

{
  "personName": "John Doe Updated",
  "customerStage": "Customer",
  "funnelStage": "Converted"
}
```

### Delete Account
```http
DELETE /accounts/:id
```

### Get Account Statistics
```http
GET /accounts/stats
GET /accounts/stats?assignedToId=uuid
GET /accounts/stats?areaId=uuid
```

**Response:**
```json
{
  "success": true,
  "data": {
    "totalAccounts": 150,
    "byCustomerStage": [
      { "customerStage": "Lead", "_count": 50 },
      { "customerStage": "Prospect", "_count": 60 },
      { "customerStage": "Customer", "_count": 40 }
    ],
    "byFunnelStage": [
      { "funnelStage": "Awareness", "_count": 30 },
      { "funnelStage": "Interest", "_count": 40 },
      { "funnelStage": "Converted", "_count": 80 }
    ],
    "recentAccounts": [...]
  }
}
```

### Bulk Assign Accounts
```http
POST /accounts/bulk/assign
Content-Type: application/json

{
  "accountIds": ["uuid1", "uuid2", "uuid3"],
  "assignedToId": "uuid"
}
```

**Response:**
```json
{
  "success": true,
  "message": "3 accounts assigned successfully",
  "count": 3
}
```

---

## 🔐 Authentication APIs

### Send OTP
```http
POST /auth/send-otp
Content-Type: application/json

{
  "contactNumber": "9876543210"
}
```

### Verify OTP
```http
POST /auth/verify-otp
Content-Type: application/json

{
  "contactNumber": "9876543210",
  "otp": "123456"
}
```

---

## 👥 User APIs

### Get All Users
```http
GET /users
```

### Get User by ID
```http
GET /users/:id
```

---

## Error Responses

All endpoints return errors in this format:

```json
{
  "success": false,
  "message": "Error description"
}
```

**Common HTTP Status Codes:**
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `404` - Not Found
- `500` - Internal Server Error

---

## Setup Instructions

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Setup Database
```bash
# Run migrations
npx prisma migrate dev

# Seed initial data
npm run seed

# Seed location data
node prisma/seedLocations.js
```

### 3. Start Server
```bash
npm run dev
```

Server will run on `http://localhost:5000`

---

## Testing the APIs

### Using cURL

**Get all countries:**
```bash
curl http://localhost:5000/locations/countries
```

**Create a country:**
```bash
curl -X POST http://localhost:5000/locations/countries \
  -H "Content-Type: application/json" \
  -d '{"name":"India"}'
```

**Get states by country:**
```bash
curl "http://localhost:5000/locations/states?countryId=YOUR_COUNTRY_ID"
```

**Create an account:**
```bash
curl -X POST http://localhost:5000/accounts \
  -H "Content-Type: application/json" \
  -d '{
    "personName": "John Doe",
    "contactNumber": "9876543210",
    "businessType": "Retail",
    "customerStage": "Lead"
  }'
```

---

## Database Schema Overview

### Location Hierarchy
```
Country → State → District → City → Zone → Area
```

### Account Fields
- `accountCode` - Auto-generated (e.g., ACC2401001)
- `personName` - Customer name
- `dateOfBirth` - Optional
- `contactNumber` - Required, unique
- `businessType` - Optional
- `customerStage` - Lead/Prospect/Customer
- `funnelStage` - Awareness/Interest/Converted
- `assignedToId` - Sales person assigned
- `areaId` - Geographic area

---

## Notes

1. All location dropdowns are cascading (Country → State → District → City → Zone → Area)
2. Account codes are auto-generated with format: `ACC + YY + MM + SEQUENCE`
3. All GET endpoints support filtering via query parameters
4. Pagination is available on accounts list (default: 50 per page)
5. All timestamps are in ISO 8601 format
