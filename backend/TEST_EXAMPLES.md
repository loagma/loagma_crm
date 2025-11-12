# API Testing Examples

## Quick Start Guide

### 1. Setup Database
```bash
cd backend
npx prisma migrate dev
npm run seed
npm run seed:locations
```

### 2. Start Server
```bash
npm run dev
```

Server runs on: `http://localhost:5000`

---

## Test Sequence

### Step 1: Verify Server is Running
```bash
curl http://localhost:5000
```
Expected: `Loagma CRM Backend running well!!`

---

### Step 2: Get Location Data

#### Get all countries
```bash
curl http://localhost:5000/locations/countries
```

#### Get states (copy a countryId from above response)
```bash
curl "http://localhost:5000/locations/states?countryId=PASTE_COUNTRY_ID_HERE"
```

#### Get districts (copy a stateId)
```bash
curl "http://localhost:5000/locations/districts?stateId=PASTE_STATE_ID_HERE"
```

#### Get cities (copy a districtId)
```bash
curl "http://localhost:5000/locations/cities?districtId=PASTE_DISTRICT_ID_HERE"
```

#### Get zones (copy a cityId)
```bash
curl "http://localhost:5000/locations/zones?cityId=PASTE_CITY_ID_HERE"
```

#### Get areas (copy a zoneId)
```bash
curl "http://localhost:5000/locations/areas?zoneId=PASTE_ZONE_ID_HERE"
```

---

### Step 3: Create Account

```bash
curl -X POST http://localhost:5000/accounts \
  -H "Content-Type: application/json" \
  -d '{
    "personName": "Rajesh Kumar",
    "contactNumber": "9876543210",
    "dateOfBirth": "1985-05-15",
    "businessType": "Retail",
    "customerStage": "Lead",
    "funnelStage": "Awareness",
    "areaId": "PASTE_AREA_ID_HERE"
  }'
```

---

### Step 4: Get All Accounts

```bash
curl http://localhost:5000/accounts
```

With pagination:
```bash
curl "http://localhost:5000/accounts?page=1&limit=10"
```

With filters:
```bash
curl "http://localhost:5000/accounts?customerStage=Lead"
curl "http://localhost:5000/accounts?areaId=PASTE_AREA_ID_HERE"
```

With search:
```bash
curl "http://localhost:5000/accounts?search=Rajesh"
```

---

### Step 5: Get Account by ID

```bash
curl http://localhost:5000/accounts/PASTE_ACCOUNT_ID_HERE
```

---

### Step 6: Update Account

```bash
curl -X PUT http://localhost:5000/accounts/PASTE_ACCOUNT_ID_HERE \
  -H "Content-Type: application/json" \
  -d '{
    "customerStage": "Prospect",
    "funnelStage": "Interest"
  }'
```

---

### Step 7: Get Account Statistics

```bash
curl http://localhost:5000/accounts/stats
```

---

### Step 8: Create More Location Data

#### Add a new state
```bash
curl -X POST http://localhost:5000/locations/states \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Rajasthan",
    "countryId": "PASTE_COUNTRY_ID_HERE"
  }'
```

#### Add a new district
```bash
curl -X POST http://localhost:5000/locations/districts \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Jaipur",
    "stateId": "PASTE_STATE_ID_HERE"
  }'
```

---

## Using Postman

### Import Collection

Create a new Postman collection with these requests:

1. **GET Countries** - `http://localhost:5000/locations/countries`
2. **GET States** - `http://localhost:5000/locations/states?countryId={{countryId}}`
3. **GET Districts** - `http://localhost:5000/locations/districts?stateId={{stateId}}`
4. **GET Cities** - `http://localhost:5000/locations/cities?districtId={{districtId}}`
5. **GET Zones** - `http://localhost:5000/locations/zones?cityId={{cityId}}`
6. **GET Areas** - `http://localhost:5000/locations/areas?zoneId={{zoneId}}`
7. **POST Account** - `http://localhost:5000/accounts`
8. **GET Accounts** - `http://localhost:5000/accounts`
9. **GET Account Stats** - `http://localhost:5000/accounts/stats`

---

## Sample Data After Seeding

After running `npm run seed:locations`, you'll have:

### Countries
- India

### States
- Gujarat
- Maharashtra

### Districts
- Ahmedabad (Gujarat)
- Surat (Gujarat)
- Mumbai (Maharashtra)
- Pune (Maharashtra)

### Cities
- Ahmedabad City
- Surat City
- Mumbai City
- Pune City

### Zones
- West Zone (Ahmedabad)
- East Zone (Ahmedabad)
- West Zone (Surat)
- South Mumbai
- Central Mumbai

### Areas
- Vastrapur, Bodakdev, Satellite, Navrangpura (Ahmedabad West)
- Maninagar, Nikol, Vastral (Ahmedabad East)
- Adajan, Vesu, Pal (Surat West)
- Colaba, Nariman Point, Churchgate (Mumbai South)
- Dadar, Parel, Byculla (Mumbai Central)

---

## Common Issues & Solutions

### Issue: "Cannot find module '@prisma/client'"
**Solution:**
```bash
npx prisma generate
```

### Issue: "Database connection error"
**Solution:** Check your `.env` file has correct `DATABASE_URL`

### Issue: "Port 5000 already in use"
**Solution:** Change PORT in `.env` or kill the process:
```bash
# Windows
netstat -ano | findstr :5000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:5000 | xargs kill -9
```

---

## Testing Workflow for Dashboard

### For Dropdown Population:

1. **Country Dropdown**: Call `GET /locations/countries`
2. **State Dropdown**: Call `GET /locations/states?countryId={selected}`
3. **District Dropdown**: Call `GET /locations/districts?stateId={selected}`
4. **City Dropdown**: Call `GET /locations/cities?districtId={selected}`
5. **Zone Dropdown**: Call `GET /locations/zones?cityId={selected}`
6. **Area Dropdown**: Call `GET /locations/areas?zoneId={selected}`

### For Account Creation:

1. User selects location hierarchy (Country → State → District → City → Zone → Area)
2. User fills account details (Name, Contact, DOB, Business Type, etc.)
3. Call `POST /accounts` with all data
4. Account code is auto-generated (e.g., ACC2411001)
5. Display success message with account code

### For Account List:

1. Call `GET /accounts` with optional filters
2. Display in table/list format
3. Support pagination, search, and filtering
4. Show location hierarchy for each account

---

## Next Steps

1. ✅ Backend APIs are ready
2. 🔄 Integrate with Flutter frontend
3. 🔄 Add authentication middleware to protect routes
4. 🔄 Add validation middleware
5. 🔄 Add logging and error tracking
