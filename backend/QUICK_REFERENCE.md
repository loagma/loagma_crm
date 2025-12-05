# Quick Reference Card

## 🚀 Common Commands

```bash
# Start development server
npm run dev

# Start production server
npm start

# Test APIs
npm run test:api

# Verify setup
npm run verify

# Database commands
npm run db:generate    # Generate Prisma client
npm run db:migrate     # Run migrations
npm run db:seed        # Seed data
npm run db:studio      # Open database GUI
npm run db:reset       # Reset database (⚠️ deletes data)
```

## 📍 API Endpoints

### Health
- `GET /` - API info
- `GET /health` - Health check

### Authentication
- `POST /auth/send-otp` - Send OTP
- `POST /auth/verify-otp` - Verify OTP & login

### Users
- `GET /users` - List users
- `POST /users` - Create user
- `PUT /users/:id` - Update user
- `DELETE /users/:id` - Delete user

### Accounts
- `GET /accounts` - List accounts
- `POST /accounts` - Create account
- `PUT /accounts/:id` - Update account
- `DELETE /accounts/:id` - Delete account

### Task Assignments
- `GET /task-assignments` - List assignments
- `POST /task-assignments` - Create assignment
- `PUT /task-assignments/:id` - Update assignment
- `DELETE /task-assignments/:id` - Delete assignment

### Master Data
- `GET /masters/departments` - List departments
- `GET /masters/functional-roles` - List functional roles
- `GET /masters/roles` - List roles

### Locations
- `GET /locations/countries` - List countries
- `GET /locations/states` - List states
- `GET /locations/cities` - List cities
- `GET /pincode/:pincode` - Get location by pincode

## 📁 Project Structure

```
backend/
├── src/
│   ├── config/       # Configuration
│   ├── controllers/  # Request handlers
│   ├── middleware/   # Auth, validation
│   ├── routes/       # API routes
│   ├── services/     # Business logic
│   ├── utils/        # Helpers
│   └── server.js     # Entry point
├── prisma/           # Database
├── scripts/          # Utilities
└── docs/             # Documentation
```

## 🔧 Environment Variables

```env
# Server
PORT=5000
NODE_ENV=development

# Database
DATABASE_URL=postgresql://...

# JWT
JWT_SECRET=your-secret

# Twilio
TWILIO_ACCOUNT_SID=...
TWILIO_AUTH_TOKEN=...
TWILIO_PHONE_NUMBER=...

# Cloudinary
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...

# Google Maps
GOOGLE_MAPS_API_KEY=...
```

## 📚 Documentation

- [INDEX.md](./INDEX.md) - Documentation hub
- [QUICK_START.md](./QUICK_START.md) - 5-min setup
- [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) - API reference
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Deploy guide
- [VERIFICATION_REPORT.md](./VERIFICATION_REPORT.md) - Test results

## 🐛 Troubleshooting

### Server won't start
```bash
# Check environment
npm run verify

# Check port
# Change PORT in .env
```

### Database errors
```bash
# Regenerate client
npm run db:generate

# Check connection
npm run db:studio
```

### API not working
```bash
# Test APIs
npm run test:api

# Check logs
# Look at server console
```

## 🔒 Security

- Never commit `.env`
- Use strong `JWT_SECRET`
- Enable HTTPS in production
- Restrict CORS in production
- Keep dependencies updated

## 📞 Quick Help

1. Check [INDEX.md](./INDEX.md)
2. Run `npm run verify`
3. Run `npm run test:api`
4. Contact dev team

## ✅ Quick Test

```bash
# 1. Start server
npm run dev

# 2. Test health
curl http://localhost:5000/health

# 3. Test API
npm run test:api
```

Expected: All tests pass ✅

---

**Keep this card handy for quick reference!**
