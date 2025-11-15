# Loagma CRM

A fully scalable, production-ready Customer Relationship Management (CRM) platform built with Flutter for a high-performance cross-platform client interface and Node.js/Express for a robust, modular backend API layer. The system manages end-to-end customer lifecycle operations with real-time data sync, strong security, and micro-module scalability.

# Key Highlights

- Cross-platform client built using Flutter supporting Android, iOS, and Web deployment with a shared codebase.

- REST-based backend architecture using Node.js/Express ensuring high throughput and non-blocking request handling.

- Role-Based Access Control (RBAC) with hierarchical user roles.

---

##  Tech Stack

### Frontend (Flutter)
- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: StatefulWidget
- **HTTP Client**: http package
- **UI Components**: Material Design

### Backend (Node.js)
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: PostgreSQL
- **ORM**: Prisma
- **Authentication**: JWT
- **SMS Service**: Custom SMS integration by Twillio

---

##  Project Structure

```
loagma_crm/
├── backend/                    # Node.js Backend
│   ├── prisma/
│   │   └── schema.prisma      # Database schema
│   ├── src/
│   │   ├── config/            # Configuration files
│   │   ├── controllers/       # Route controllers
│   │   ├── middleware/        # Custom middleware
│   │   ├── routes/            # API routes
│   │   ├── utils/             # Utility functions
│   │   └── app.js             # Express app entry
│   ├── .env                   # Environment variables
│   └── package.json
│
└── loagma_crm/                # Flutter Frontend
    ├── lib/
    │   ├── models/            # Data models
    │   ├── screens/           # UI screens
    │   ├── services/          # API services
    │   └── main.dart          # App entry point
    ├── assets/                # Images, fonts, etc.
    └── pubspec.yaml
```

---

##  Prerequisites

### Backend Requirements
- Node.js (v18 or higher)
- PostgreSQL (v14 or higher)
- npm or yarn

### Frontend Requirements
- Flutter SDK (v3.0 or higher)
- Dart SDK (v3.0 or higher)
- Android Studio / Xcode (for mobile development)
- VS Code or Android Studio (recommended IDEs)

---

##  Installation & Setup

### 1. Clone the Repository

```bash
git clone [<(https://github.com/loagma/loagma_crm.git)>]
cd loagma_crm
```

### 2. Backend Setup

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Edit .env with your configuration
# (See Environment Variables section below)

# Generate Prisma Client
npx prisma generate

# Run database migrations
npx prisma migrate dev

# Seed database (optional)
npm run seed
```

### 3. Frontend Setup

```bash
# Navigate to Flutter app directory
cd loagma_crm

# Install dependencies
flutter pub get

# Update API configuration
# Edit lib/services/api_config.dart with your backend URL
```

---

##  Environment Variables

### Backend (.env)

Create a `.env` file in the `backend` directory:

```env
# Server Configuration
PORT=5000

# Database Configuration
DATABASE_URL=postgresql://username:password@localhost:5432/loagma_crm

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production

# SMS Service (Optional)
SMS_API_KEY=your-sms-api-key
SMS_SENDER_ID=your-sender-id
```

### Frontend (api_config.dart)

Update `loagma_crm/lib/services/api_config.dart`:

```dart
class ApiConfig {
  // For local development
  static const String baseUrl = 'http://localhost:5000';
  
  // For production
  static const String baseUrl = 'https://loagma-crm.onrender.com';
}
```

---

##  Database Setup

### 1. Create PostgreSQL Database

```bash
# Login to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE loagma_crm;

# Exit
\q
```

### 2. Run Migrations

```bash
cd backend
npx prisma migrate dev --name init
```

### 3. Seed Master Data (Optional)

```bash
# Create a seed script or manually insert data
# Example: Insert countries, states, regions, etc.
```

### 4. View Database (Optional)

```bash
npx prisma studio
```

This opens a web interface at `http://localhost:5555` to view and edit data.

---

##  Running the Application

### Start Backend Server

```bash
cd backend

# Development mode (with auto-reload)
npm run dev

# Production mode
npm start
```

Backend will run on `http://localhost:5000`

### Start Flutter App

```bash
cd loagma_crm

# Run on connected device/emulator
flutter run

# Run on specific device
flutter devices  # List available devices
flutter run -d <device-id>

# Run on Chrome (web)
flutter run -d chrome
```

### Development Mode Features

- **Skip Login**: In debug mode, a "Skip Login (Dev Mode)" button appears on the login screen for quick testing
- **Hot Reload**: Press `r` in terminal for hot reload, `R` for hot restart

---

## Build Apk
 - flutter build apk --release

---

##  Deployment

### Backend Deployment (Render/Heroku/Railway)

#### Using Render

1. **Create Account**: Sign up at [render.com](https://render.com)

2. **Create Web Service**:
   - Connect your GitHub repository
   - Select `backend` as root directory
   - Build Command: `npm install && npx prisma generate`
   - Start Command: `npm start`

3. **Add Environment Variables**:
   ```
   DATABASE_URL=<your-postgres-url>
   JWT_SECRET=<your-secret>
   PORT=5000
   ```

4. **Deploy**: Render will automatically deploy

**Live Backend URL**: 'https://loagma-crm.onrender.com';

#### Database Hosting

- **Render PostgreSQL**: Free tier available
- **Supabase**: Free PostgreSQL hosting
- **Railway**: PostgreSQL with free tier
- **ElephantSQL**: Free PostgreSQL hosting

### Frontend Deployment

#### Android APK

```bash
cd loagma_crm

# Build release APK
flutter build apk --release

# APK location: build/app/outputs/flutter-apk/app-release.apk
```

#### iOS App

```bash
cd loagma_crm

# Build iOS app
flutter build ios --release

# Follow Xcode instructions for App Store submission
```

#### Web Deployment

```bash
cd loagma_crm

# Build web app
flutter build web

# Deploy to Firebase Hosting, Netlify, or Vercel
# Output directory: build/web
```

---

## 🔧 Troubleshooting

### Backend Issues

**Port already in use**:
```bash
# Kill process on port 5000
npx kill-port 5000
```

**Database connection error**:
- Check PostgreSQL is running
- Verify DATABASE_URL in .env
- Ensure database exists

**Prisma errors**:
```bash
# Regenerate Prisma Client
npx prisma generate

# Reset database (WARNING: deletes all data)
npx prisma migrate reset
```

### Frontend Issues

**Dependencies error**:
```bash
flutter clean
flutter pub get
```

**Build errors**:
```bash
flutter clean
flutter pub get
flutter run
```

**API connection issues**:
- Check backend is running
- Verify API URL in `api_config.dart`
- Check network permissions in `AndroidManifest.xml`

---


##  Security

- JWT-based authentication
- OTP verification for login
- Role-based access control
- Secure password handling
- Environment variable protection

---

##  License

This project is proprietary software. All rights reserved.

---

##  Version

**Version**: 1.0.0  

---

##  Support

For issues and questions:
- Create an issue in the repository
- Contact the developer (Abhishek Dubey )

---

**Built with ❤️ using Flutter and Node.js**
