# Loagma CRM - Full Stack Project Structure

## 📁 Complete Project Structure

```
loagma_crm/
├── backend/                          # Node.js Express API Server
│   ├── prisma/                       # Database Schema & Migrations
│   │   ├── migrations/               # Auto-generated DB migrations
│   │   ├── schema.prisma            # Database schema definition
│   │   └── seed.js                  # Database seeding script
│   ├── src/                         # Source code
│   │   ├── config/                  # Configuration files
│   │   │   └── db.js               # Database connection setup
│   │   ├── generated/               # Auto-generated Prisma client
│   │   │   └── prisma/             # Prisma client files
│   │   ├── app.js                  # Express app configuration
│   │   └── server.js               # Server entry point
│   ├── .env                        # Environment variables
│   ├── .env.example               # Environment template
│   ├── package.json               # Dependencies & scripts
│   └── README.md                  # Backend documentation
│
├── loagma_crm/                      # Original Flutter App (Legacy)
│   ├── lib/                        # Flutter source code
│   ├── android/                    # Android platform files
│   ├── ios/                        # iOS platform files
│   ├── web/                        # Web platform files
│   ├── windows/                    # Windows platform files
│   └── pubspec.yaml               # Flutter dependencies
│
└── loagma-crm-fullstack/           # New Full Stack Structure
    ├── frontend/                   # Flutter Frontend (New)
    │   ├── lib/                   # Flutter source code
    │   │   ├── main.dart         # App entry point
    │   │   ├── screens/          # UI screens
    │   │   ├── providers/        # State management
    │   │   ├── services/         # API services
    │   │   └── models/           # Data models
    │   └── pubspec.yaml          # Flutter dependencies
    │
    ├── backend/                   # Node.js Express API (Duplicate)
    ├── shared/                    # Shared utilities
    ├── docs/                      # Documentation
    └── README.md                  # Project overview
```

## 🚀 Current Status

### ✅ Backend (Working)
- **Framework**: Node.js + Express.js
- **Database**: PostgreSQL with Prisma ORM
- **Authentication**: JWT ready
- **Status**: ✅ Running on http://localhost:5000
- **Database**: ✅ Connected to Neon PostgreSQL
- **Seeding**: ✅ Sample data loaded

### 🔧 Database Schema
- **Geographical Hierarchy**: Country → State → District → City → Zone → Area
- **Role Management**: Sales hierarchy (NSM, RSM, ASM, TSM) + Functional roles
- **User Management**: Complete user system with OTP authentication
- **CRM Features**: Account/Customer management with area assignments

### 📱 Frontend Options
1. **Original Flutter App** (`loagma_crm/`) - Existing but needs API integration
2. **New Flutter App** (`loagma-crm-fullstack/frontend/`) - Clean structure for full-stack

## 🛠 Quick Commands

### Backend
```bash
cd backend
npm run dev          # Start development server
npm run seed         # Seed database with sample data
npx prisma studio    # Open database GUI
npx prisma migrate dev # Run database migrations
```

### Flutter (Original)
```bash
cd loagma_crm
flutter pub get      # Install dependencies
flutter run -d chrome    # Run on web
flutter run -d windows   # Run on Windows (needs Visual Studio)
```

## 🔗 Database Connection

- **Provider**: PostgreSQL (Neon Cloud)
- **ORM**: Prisma
- **Connection**: ✅ Active
- **Generated Client**: ✅ Available at `backend/src/generated/prisma/`

## 📋 Next Steps

1. **Choose Frontend**: Decide between existing or new Flutter structure
2. **API Integration**: Connect Flutter app to backend APIs
3. **Authentication**: Implement OTP-based login system
4. **Features**: Build CRM functionality (customers, sales, reports)

## 🔧 Issues Fixed

1. ✅ Added missing `users` relation in Department model
2. ✅ Generated Prisma client successfully
3. ✅ Fixed module type in package.json
4. ✅ Updated seed script to handle duplicates
5. ✅ Database connection working properly
6. ✅ Backend server running successfully