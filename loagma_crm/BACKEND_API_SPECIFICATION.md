# 🔌 Backend API Specification - Task Assignment Module

## Base URL
```
https://your-api-domain.com/api
```

---

## 📡 API Endpoints

### 1. Fetch All Salesmen
**Endpoint:** `GET /salesmen`

**Description:** Fetch all salesmen/sales representatives

**Request:**
```http
GET /salesmen HTTP/1.1
Host: your-api-domain.com
```

**Response:**
```json
{
  "success": true,
  "salesmen": [
    {
      "id": "1",
      "_id": "507f1f77bcf86cd799439011",
      "name": "Rajesh Kumar",
      "contactNumber": "9876543210",
      "employeeCode": "EMP001",
      "email": "rajesh@example.com",
      "assignedPinCodes": ["400001", "400002"]
    }
  ]
}
```

**Status Codes:**
- `200` - Success
- `500` - Server Error

---

### 2. Fetch Location by Pin Code
**Endpoint:** `GET /location/pincode/:pinCode`

**Description:** Fetch location details including country, state, district, city, and available areas for a given pin code

**Request:**
```http
GET /location/pincode/400001 HTTP/1.1
Host: your-api-domain.com
```

**Response:**
```json
{
  "success": true,
  "location": {
    "pinCode": "400001",
    "country": "India",
    "state": "Maharashtra",
    "district": "Mumbai",
    "city": "Mumbai",
    "areas": [
      "Andheri East",
      "Andheri West",
      "Bandra",
      "Juhu",
      "Versova",
      "Lokhandwala"
    ]
  }
}
```

**Status Codes:**
- `200` - Success
- `404` - Pin code not found
- `500` - Server Error

---

### 3. Assign Areas to Salesman
**Endpoint:** `POST /task-assignments/areas`

**Description:** Assign multiple areas with business types to a salesman

**Request:**
```http
POST /task-assignments/areas HTTP/1.1
Host: your-api-domain.com
Content-Type: application/json

{
  "salesmanId": "1",
  "salesmanName": "Rajesh Kumar",
  "pinCode": "400001",
  "country": "India",
  "state": "Maharashtra",
  "district": "Mumbai",
  "city": "Mumbai",
  "areas": [
    "Andheri East",
    "Andheri West",
    "Bandra"
  ],
  "businessTypes": [
    "grocery",
    "cafe",
    "restaurant",
    "hotel"
  ]
}
```

**Response:**
```json
{
  "success": true,
  "message": "Successfully assigned 3 areas to Rajesh Kumar",
  "assignment": {
    "id": "assignment_123",
    "_id": "507f1f77bcf86cd799439011",
    "salesmanId": "1",
    "salesmanName": "Rajesh Kumar",
    "pinCode": "400001",
    "country": "India",
    "state": "Maharashtra",
    "district": "Mumbai",
    "city": "Mumbai",
    "areas": ["Andheri East", "Andheri West", "Bandra"],
    "businessTypes": ["grocery", "cafe", "restaurant", "hotel"],
    "assignedDate": "2025-11-28T10:30:00.000Z",
    "totalBusinesses": 45
  }
}
```

**Status Codes:**
- `200` or `201` - Success
- `400` - Bad Request (validation error)
- `404` - Salesman not found
- `500` - Server Error

---

### 4. Get Assignments by Salesman
**Endpoint:** `GET /task-assignments/salesman/:salesmanId`

**Description:** Fetch all area assignments for a specific salesman

**Request:**
```http
GET /task-assignments/salesman/1 HTTP/1.1
Host: your-api-domain.com
```

**Response:**
```json
{
  "success": true,
  "assignments": [
    {
      "id": "assignment_123",
      "_id": "507f1f77bcf86cd799439011",
      "salesmanId": "1",
      "salesmanName": "Rajesh Kumar",
      "pinCode": "400001",
      "country": "India",
      "state": "Maharashtra",
      "district": "Mumbai",
      "city": "Mumbai",
      "areas": ["Andheri East", "Andheri West"],
      "businessTypes": ["grocery", "cafe", "restaurant"],
      "assignedDate": "2025-11-28T10:30:00.000Z",
      "totalBusinesses": 45
    }
  ]
}
```

**Status Codes:**
- `200` - Success
- `404` - Salesman not found
- `500` - Server Error

---

### 5. Fetch Businesses by Area and Type
**Endpoint:** `POST /businesses/search`

**Description:** Search and count businesses in selected areas filtered by business types

**Request:**
```http
POST /businesses/search HTTP/1.1
Host: your-api-domain.com
Content-Type: application/json

{
  "pinCode": "400001",
  "areas": [
    "Andheri East",
    "Andheri West",
    "Bandra"
  ],
  "businessTypes": [
    "grocery",
    "cafe",
    "restaurant"
  ]
}
```

**Response:**
```json
{
  "success": true,
  "totalBusinesses": 45,
  "breakdown": {
    "grocery": "20",
    "cafe": "15",
    "restaurant": "10"
  },
  "message": "Found 45 businesses in 3 areas",
  "businesses": [
    {
      "id": "business_1",
      "name": "Fresh Mart",
      "type": "grocery",
      "area": "Andheri East",
      "address": "123 Main Street",
      "pinCode": "400001"
    }
  ]
}
```

**Status Codes:**
- `200` - Success
- `400` - Bad Request
- `500` - Server Error

---

### 6. Remove Assignment
**Endpoint:** `DELETE /task-assignments/:assignmentId`

**Description:** Remove/delete an area assignment

**Request:**
```http
DELETE /task-assignments/assignment_123 HTTP/1.1
Host: your-api-domain.com
```

**Response:**
```json
{
  "success": true,
  "message": "Assignment removed successfully"
}
```

**Status Codes:**
- `200` - Success
- `404` - Assignment not found
- `500` - Server Error

---

## 📋 Business Types Reference

The following business type IDs should be used:

| ID | Name | Icon |
|---|---|---|
| `grocery` | Grocery | 🛒 |
| `cafe` | Cafe | ☕ |
| `hotel` | Hotel | 🏨 |
| `dairy` | Dairy | 🥛 |
| `restaurant` | Restaurant | 🍽️ |
| `bakery` | Bakery | 🍞 |
| `pharmacy` | Pharmacy | 💊 |
| `supermarket` | Supermarket | 🏪 |
| `others` | Others | 📦 |

---

## 🗄️ Database Schema Suggestions

### Salesmen Collection/Table
```javascript
{
  _id: ObjectId,
  id: String,
  name: String,
  contactNumber: String,
  employeeCode: String,
  email: String,
  assignedPinCodes: [String],
  createdAt: Date,
  updatedAt: Date
}
```

### Locations Collection/Table
```javascript
{
  _id: ObjectId,
  pinCode: String (indexed),
  country: String,
  state: String,
  district: String,
  city: String,
  areas: [String],
  createdAt: Date,
  updatedAt: Date
}
```

### Task Assignments Collection/Table
```javascript
{
  _id: ObjectId,
  id: String,
  salesmanId: String (indexed),
  salesmanName: String,
  pinCode: String,
  country: String,
  state: String,
  district: String,
  city: String,
  areas: [String],
  businessTypes: [String],
  assignedDate: Date,
  totalBusinesses: Number,
  createdAt: Date,
  updatedAt: Date
}
```

### Businesses Collection/Table
```javascript
{
  _id: ObjectId,
  id: String,
  name: String,
  type: String (indexed),
  area: String (indexed),
  pinCode: String (indexed),
  address: String,
  contactNumber: String,
  email: String,
  createdAt: Date,
  updatedAt: Date
}
```

---

## 🔐 Authentication

All endpoints should require authentication. Add authentication headers:

```http
Authorization: Bearer <token>
```

---

## ⚠️ Error Response Format

All error responses should follow this format:

```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message"
}
```

---

## 📝 Notes for Backend Team

1. **Pin Code Validation**: Validate pin code format (6 digits for India)
2. **Duplicate Prevention**: Check if areas are already assigned to another salesman
3. **Business Count**: Calculate `totalBusinesses` based on actual data
4. **Pagination**: Consider adding pagination for large datasets
5. **Caching**: Cache location data by pin code for performance
6. **Indexing**: Add database indexes on frequently queried fields
7. **Logging**: Log all assignment operations for audit trail

---

## 🧪 Testing Endpoints

Use these sample requests for testing:

### Test 1: Fetch Salesmen
```bash
curl -X GET https://your-api-domain.com/api/salesmen
```

### Test 2: Fetch Location
```bash
curl -X GET https://your-api-domain.com/api/location/pincode/400001
```

### Test 3: Assign Areas
```bash
curl -X POST https://your-api-domain.com/api/task-assignments/areas \
  -H "Content-Type: application/json" \
  -d '{
    "salesmanId": "1",
    "salesmanName": "Rajesh Kumar",
    "pinCode": "400001",
    "country": "India",
    "state": "Maharashtra",
    "district": "Mumbai",
    "city": "Mumbai",
    "areas": ["Andheri East"],
    "businessTypes": ["grocery", "cafe"]
  }'
```

---

**Last Updated**: November 28, 2025
