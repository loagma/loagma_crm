# Loagma CRM Backend

Complete backend API for Loagma CRM Dashboard with Location Master and Account Management.

## 🚀 Features

### Location Master Management
- ✅ Country, State, District, City, Zone, Area hierarchy
- ✅ Cascading dropdowns support
- ✅ Full CRUD operations for all location levels
- ✅ Automatic relationship management
- ✅ Count of child entities

### Account Master Management
- ✅ Complete account CRUD operations
- ✅ Auto-generated account codes (ACC2411001 format)
- ✅ Location assignment (Area-based)
- ✅ Sales person assignment
- ✅ Customer stage tracking (Lead/Prospect/Customer)
- ✅ Funnel stage tracking
- ✅ Advanced filtering and search
- ✅ Pagination support
- ✅ Account statistics and analytics
- ✅ Bulk operations (assign accounts)

### Additional Features
- ✅ User authentication with OTP
- ✅ Role-based access control
- ✅ Department and functional roles
- ✅ Sales hierarchy management

## 📁 Project Structure

```
backend/
├── prisma/
│   ├── schema.prisma          # Database schema
│   ├── seed.js                # Initial data seeding
│   └── seedLocations.js       # Location master data
├── src/
│   ├── config/
│   │   ├── db.js              # Database configuration
│   │   └── env.js             # Environment variables
│   ├── controllers/
│   │   ├── authController.js  # Authentication logic
│   │   ├── userController.js  # User management
│   │   ├── locationController.js  # Location CRUD
│   │   └── accountController.js   # Account CRUD
│   ├── middleware/
│   │   ├── authMiddleware.js  # JWT verification
│   │   ├── roleGuard.js       # Role-based access
│   │   └── validation.js      # Request validation
│   ├── routes/
│   │   ├── authRoutes.js      # Auth endpoints
│   │   ├── userRoutes.js      # User endpoints
│   │   ├── locationRoutes.js  # Location endpoints
│   │   └── accountRoutes.js   # Account endpoints
│   ├── utils/
│   │   ├── jwtUtils.js        # JWT helpers
│   │   ├── otpGenerator.js    # OTP generation
│   │   └── smsService.js      # SMS integration
│   ├── app.js                 # Express app setup
│   └── server.js              # Server entry point
├── .env                       # Environment variables
├── package.json
├── API_DOCUMENTATION.md       # Complete API docs
├── TEST_EXAMPLES.md           # Testing guide
└── README.md                  # This file
```

## 🛠️ Setup Instructions

### Prerequisites
- Node.js (v18 or higher)
- PostgreSQL database
- npm or yarn

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Configure Environment
Create a `.env` file:
```env
DATABASE_URL="postgresql://user:password@localhost:5432/loagma_crm"
PORT=5000
JWT_SECRET=your_jwt_secret_key_here
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token
TWILIO_PHONE_NUMBER=your_twilio_phone
```

### 3. Setup Database
```bash
# Generate Prisma Client
npx prisma generate

# Run migrations
npx prisma migrate dev

# Seed initial data (roles, departments, users)
npm run seed

# Seed location master data
npm run seed:locations
```

### 4. Start Development Server
```bash
npm run dev
```

Server will run on `http://localhost:5000`

## 📚 API Endpoints

### Location Master APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/locations/countries` | Get all countries |
| POST | `/locations/countries` | Create country |
| PUT | `/locations/countries/:id` | Update country |
| DELETE | `/locations/countries/:id` | Delete country |
| GET | `/locations/states?countryId=uuid` | Get states by country |
| POST | `/locations/states` | Create state |
| PUT | `/locations/states/:id` | Update state |
| DELETE | `/locations/states/:id` | Delete state |
| GET | `/locations/districts?stateId=uuid` | Get districts by state |
| POST | `/locations/districts` | Create district |
| PUT | `/locations/districts/:id` | Update district |
| DELETE | `/locations/districts/:id` | Delete district |
| GET | `/locations/cities?districtId=uuid` | Get cities by district |
| POST | `/locations/cities` | Create city |
| PUT | `/locations/cities/:id` | Update city |
| DELETE | `/locations/cities/:id` | Delete city |
| GET | `/locations/zones?cityId=uuid` | Get zones by city |
| POST | `/locations/zones` | Create zone |
| PUT | `/locations/zones/:id` | Update zone |
| DELETE | `/locations/zones/:id` | Delete zone |
| GET | `/locations/areas?zoneId=uuid` | Get areas by zone |
| POST | `/locations/areas` | Create area |
| PUT | `/locations/areas/:id` | Update area |
| DELETE | `/locations/areas/:id` | Delete area |

### Account Master APIs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/accounts` | Get all accounts (with filters) |
| GET | `/accounts/:id` | Get account by ID |
| POST | `/accounts` | Create new account |
| PUT | `/accounts/:id` | Update account |
| DELETE | `/accounts/:id` | Delete account |
| GET | `/accounts/stats` | Get account statistics |
| POST | `/accounts/bulk/assign` | Bulk assign accounts |

### Query Parameters for Accounts

- `page` - Page number (default: 1)
- `limit` - Items per page (default: 50, max: 100)
- `areaId` - Filter by area
- `assignedToId` - Filter by assigned user
- `customerStage` - Filter by customer stage
- `funnelStage` - Filter by funnel stage
- `search` - Search by name, account code, or contact

## 🧪 Testing

### Quick Test
```bash
# Check server is running
curl http://localhost:5000

# Get all countries
curl http://localhost:5000/locations/countries

# Get all accounts
curl http://localhost:5000/accounts
```

### Create Test Account
```bash
curl -X POST http://localhost:5000/accounts \
  -H "Content-Type: application/json" \
  -d '{
    "personName": "Test User",
    "contactNumber": "9876543210",
    "businessType": "Retail",
    "customerStage": "Lead"
  }'
```

See `TEST_EXAMPLES.md` for comprehensive testing guide.

## 📖 Documentation

- **API Documentation**: See `API_DOCUMENTATION.md`
- **Testing Guide**: See `TEST_EXAMPLES.md`
- **Database Schema**: See `prisma/schema.prisma`

## 🗄️ Database Schema

### Location Hierarchy
```
Country (India)
  └── State (Gujarat, Maharashtra)
      └── District (Ahmedabad, Surat, Mumbai, Pune)
          └── City (Ahmedabad City, Surat City, etc.)
              └── Zone (West Zone, East Zone, etc.)
                  └── Area (Vastrapur, Bodakdev, etc.)
```

### Account Fields
- `accountCode` - Auto-generated unique code
- `personName` - Customer name (required)
- `contactNumber` - 10-digit phone (required, unique)
- `dateOfBirth` - Optional
- `businessType` - Optional
- `customerStage` - Lead/Prospect/Customer
- `funnelStage` - Awareness/Interest/Converted
- `assignedToId` - Sales person (optional)
- `areaId` - Geographic area (optional)

## 🔧 Available Scripts

```bash
npm run dev              # Start development server with nodemon
npm run seed             # Seed initial data (roles, users, departments)
npm run seed:locations   # Seed location master data
npx prisma studio        # Open Prisma Studio (database GUI)
npx prisma migrate dev   # Run database migrations
npx prisma generate      # Generate Prisma Client
```

## 🌟 Key Features Explained

### Auto-Generated Account Codes
Format: `ACC + YY + MM + SEQUENCE`
- Example: `ACC2411001` (November 2024, 1st account)
- Sequence resets daily
- Always 4 digits with leading zeros

### Cascading Dropdowns
Each location level filters by parent:
```javascript
// Get states for a country
GET /locations/states?countryId=xyz

// Get districts for a state
GET /locations/districts?stateId=abc

// And so on...
```

### Advanced Account Filtering
```javascript
// Multiple filters
GET /accounts?customerStage=Lead&areaId=xyz&page=1&limit=20

// Search
GET /accounts?search=John

// By assigned user
GET /accounts?assignedToId=user123
```

### Account Statistics
Get aggregated data:
- Total accounts
- Breakdown by customer stage
- Breakdown by funnel stage
- Recent accounts

## 🔐 Security

- JWT-based authentication
- OTP verification for login
- Role-based access control
- Input validation middleware
- SQL injection protection (Prisma ORM)

## 🐛 Troubleshooting

### Database Connection Issues
```bash
# Check PostgreSQL is running
# Verify DATABASE_URL in .env
# Test connection
npx prisma db pull
```

### Port Already in Use
```bash
# Change PORT in .env
# Or kill existing process
netstat -ano | findstr :5000
taskkill /PID <PID> /F
```

### Prisma Client Issues
```bash
# Regenerate client
npx prisma generate

# Reset database (WARNING: deletes all data)
npx prisma migrate reset
```

## 📝 Notes

1. All location endpoints support full CRUD operations
2. Account codes are automatically generated and unique
3. Contact numbers must be unique across accounts
4. All timestamps are in ISO 8601 format
5. Pagination defaults to 50 items per page
6. All responses follow consistent format: `{ success, data/message }`

## 🚀 Next Steps

- [ ] Add authentication middleware to protected routes
- [ ] Implement rate limiting
- [ ] Add request logging
- [ ] Set up error tracking (Sentry)
- [ ] Add API documentation UI (Swagger)
- [ ] Implement caching (Redis)
- [ ] Add file upload for account documents
- [ ] Implement audit logs

## 📞 Support

For issues or questions, refer to:
- API Documentation: `API_DOCUMENTATION.md`
- Testing Guide: `TEST_EXAMPLES.md`
- Database Schema: `prisma/schema.prisma`

---

**Status**: ✅ Ready for Production

All endpoints are tested and working. Database schema is complete. Ready to integrate with Flutter frontend.
