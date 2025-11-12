# ⚡ Quick Start Guide

Get your Loagma CRM backend up and running in 5 minutes!

## 🚀 Setup (First Time)

```bash
# 1. Navigate to backend folder
cd backend

# 2. Install dependencies
npm install

# 3. Setup environment variables
# Copy .env.example to .env and update DATABASE_URL

# 4. Generate Prisma Client
npx prisma generate

# 5. Run database migrations
npx prisma migrate dev

# 6. Seed initial data
npm run seed

# 7. Seed location master data
npm run seed:locations

# 8. Start the server
npm run dev
```

Server will be running at: **http://localhost:5000**

---

## ✅ Verify Setup

### Test 1: Server is running
```bash
curl http://localhost:5000
```
Expected: `Loagma CRM Backend running well!!`

### Test 2: Get countries
```bash
curl http://localhost:5000/locations/countries
```
Expected: JSON with India and other countries

### Test 3: Get accounts
```bash
curl http://localhost:5000/accounts
```
Expected: JSON with empty array or existing accounts

---

## 📋 Available Endpoints

### Location Master
- `GET /locations/countries` - Get all countries
- `GET /locations/states?countryId=xyz` - Get states by country
- `GET /locations/districts?stateId=xyz` - Get districts by state
- `GET /locations/cities?districtId=xyz` - Get cities by district
- `GET /locations/zones?cityId=xyz` - Get zones by city
- `GET /locations/areas?zoneId=xyz` - Get areas by zone

### Account Master
- `GET /accounts` - Get all accounts (with filters)
- `POST /accounts` - Create new account
- `GET /accounts/:id` - Get account by ID
- `PUT /accounts/:id` - Update account
- `DELETE /accounts/:id` - Delete account
- `GET /accounts/stats` - Get statistics

---

## 🎯 Create Your First Account

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

You'll get back an account with auto-generated code like `ACC2411001`

---

## 📚 Documentation

- **Complete API Docs**: `API_DOCUMENTATION.md`
- **Testing Guide**: `TEST_EXAMPLES.md`
- **Flutter Integration**: `FLUTTER_INTEGRATION_GUIDE.md`
- **Full README**: `README.md`

---

## 🔧 Common Commands

```bash
# Start development server
npm run dev

# Seed initial data
npm run seed

# Seed location data
npm run seed:locations

# Open Prisma Studio (Database GUI)
npx prisma studio

# Reset database (WARNING: Deletes all data)
npx prisma migrate reset

# Generate Prisma Client
npx prisma generate
```

---

## 🌟 What's Included

✅ Complete Location Master (Country → State → District → City → Zone → Area)
✅ Account Master with CRUD operations
✅ Auto-generated account codes
✅ Cascading dropdown support
✅ Search and filtering
✅ Pagination
✅ Statistics and analytics
✅ Sample data seeding
✅ Full API documentation

---

## 🎉 You're Ready!

Your backend is now ready to integrate with the Flutter frontend. Check `FLUTTER_INTEGRATION_GUIDE.md` for integration examples.

**Next Steps:**
1. Test all endpoints using the examples in `TEST_EXAMPLES.md`
2. Integrate with Flutter app using `FLUTTER_INTEGRATION_GUIDE.md`
3. Customize as needed for your requirements

---

## 💡 Tips

- Use Postman or Thunder Client for easier API testing
- Check `npx prisma studio` to view/edit database visually
- All responses follow format: `{ success: true/false, data/message: ... }`
- Account codes are auto-generated: `ACC + YY + MM + SEQUENCE`
- Contact numbers must be unique and 10 digits

---

## 🆘 Need Help?

- Check `API_DOCUMENTATION.md` for detailed endpoint info
- Check `TEST_EXAMPLES.md` for testing examples
- Check `README.md` for troubleshooting
- Check Prisma schema: `prisma/schema.prisma`

---

**Status**: ✅ Production Ready

All endpoints tested and working. Database schema complete. Ready for Flutter integration!
