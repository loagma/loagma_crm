# Weekly Beat Planning Module

A comprehensive beat planning system for sales force management that allows admins to assign territories to salesmen and track their daily progress.

## 🎯 Features

### Admin Features
- **Generate Weekly Beat Plans**: Auto-distribute areas across 7 days for optimal coverage
- **Assign Pincodes**: Assign multiple pincodes to salesmen for territory management
- **Beat Plan Management**: View, edit, approve, and lock beat plans
- **Analytics Dashboard**: Track completion rates, missed beats, and performance metrics
- **Missed Beat Handling**: Automatically carry forward incomplete areas to next available day
- **Lock/Unlock Plans**: Prevent changes to finalized plans

### Salesman Features
- **Today's Beat Plan**: View only today's assigned areas (read-only)
- **Area Completion**: Mark areas as complete with visit count and notes
- **Offline Support**: Cached beat plans work without internet
- **GPS Integration**: Location tracking for area completion verification
- **Account Lists**: View accounts in assigned areas with contact details

### System Features
- **Scalable Architecture**: Handles 100+ areas efficiently
- **No Overlapping Areas**: Ensures areas don't appear on multiple days
- **Clean Architecture**: Follows repository pattern with proper separation
- **Offline-First UI**: Works seamlessly with poor connectivity
- **Real-time Sync**: Updates sync when connection is restored

## 🏗️ Architecture

### Backend (Node.js + Express + Prisma)

```
backend/src/
├── controllers/beatPlanController.js    # API request handlers
├── services/beatPlanService.js          # Business logic
├── routes/beatPlanRoutes.js            # Route definitions
└── prisma/schema.prisma                # Database models
```

**Database Models:**
- `WeeklyBeatPlan`: Weekly plan with salesman, dates, pincodes, status
- `DailyBeatPlan`: Daily breakdown with assigned areas and completion status
- `BeatCompletion`: Individual area completion tracking with GPS and notes

### Frontend (Flutter + Clean Architecture)

```
loagma_crm/lib/
├── models/beat_plan_model.dart          # Data models
├── services/beat_plan_service.dart      # API service layer
└── screens/
    ├── admin/
    │   ├── beat_plan_management_screen.dart
    │   ├── generate_beat_plan_screen.dart
    │   └── beat_plan_details_screen.dart
    └── salesman/
        └── todays_beat_plan_screen.dart
```

## 🚀 Installation & Setup

### 1. Database Migration

Run the beat planning migration:

```bash
cd backend
node run_beat_planning_migration.js
```

### 2. Test the System

```bash
cd backend
node test_beat_planning.js
```

### 3. Start the Backend

```bash
cd backend
npm start
```

### 4. Run Flutter App

```bash
cd loagma_crm
flutter pub get
flutter run
```

## 📱 Usage Guide

### For Admins

#### 1. Generate Beat Plan
1. Navigate to **Beat Plan Management** from admin dashboard
2. Click **+ (Generate Beat Plan)**
3. Select salesman from dropdown
4. Choose week start date (automatically sets to Monday)
5. Add pincodes (6-digit codes)
6. Click **Generate Beat Plan**

#### 2. Manage Beat Plans
- **View All Plans**: See all generated plans with status and completion rates
- **Plan Details**: Click on any plan to see daily breakdown
- **Activate Plan**: Change status from DRAFT to ACTIVE
- **Lock Plan**: Prevent further modifications
- **Handle Missed Beats**: Carry forward incomplete areas

#### 3. Analytics
- View completion rates by salesman
- Track missed beats and performance metrics
- Monitor weekly and monthly trends

### For Salesmen

#### 1. View Today's Beat Plan
1. Navigate to **Today's Beat Plan** from salesman dashboard
2. See assigned areas for today only
3. View accounts in each area with contact details

#### 2. Complete Areas
1. Click **Complete** button next to an area
2. Enter number of accounts visited
3. Add optional notes
4. System captures GPS location automatically

#### 3. Track Progress
- See completion percentage in real-time
- View completed vs pending areas
- Access offline when no internet connection

## 🔧 API Endpoints

### Admin Endpoints
```
POST   /beat-plans/generate              # Generate weekly beat plan
GET    /beat-plans                       # List all beat plans
GET    /beat-plans/:id                   # Get beat plan details
PUT    /beat-plans/:id                   # Update beat plan
POST   /beat-plans/:id/toggle-lock       # Lock/unlock beat plan
POST   /beat-plans/handle-missed/:id     # Handle missed beats
GET    /beat-plans/analytics             # Get analytics
```

### Salesman Endpoints
```
GET    /beat-plans/today                 # Get today's beat plan
POST   /beat-plans/complete-area         # Mark area as complete
GET    /beat-plans/salesman/history      # Get beat plan history
```

## 🎨 UI Components

### Admin Screens
- **Beat Plan Management**: List view with filters and actions
- **Generate Beat Plan**: Form with salesman selection and pincode assignment
- **Beat Plan Details**: Daily breakdown with area completion status

### Salesman Screens
- **Today's Beat Plan**: Card-based layout with progress indicators
- **Area Completion**: Dialog with visit count and notes input

## 🔒 Security & Permissions

- **Role-based Access**: Admins can manage all plans, salesmen see only their own
- **JWT Authentication**: All API calls require valid authentication token
- **Data Validation**: Input validation on both frontend and backend
- **GPS Verification**: Location tracking for area completion verification

## 📊 Database Schema

### WeeklyBeatPlan
```sql
- id (Primary Key)
- salesmanId (Foreign Key to User)
- weekStartDate, weekEndDate
- pincodes (Array)
- totalAreas, status
- generatedBy, approvedBy, lockedBy
- timestamps
```

### DailyBeatPlan
```sql
- id (Primary Key)
- weeklyBeatId (Foreign Key)
- dayOfWeek (1-7), dayDate
- assignedAreas (Array)
- plannedVisits, actualVisits
- status, completedAt
- carriedFromDate, carriedToDate
```

### BeatCompletion
```sql
- id (Primary Key)
- dailyBeatId, salesmanId
- areaName, accountsVisited
- completedAt, latitude, longitude
- notes, isVerified
```

## 🧪 Testing

### Backend Tests
```bash
# Test beat plan generation
node test_beat_planning.js

# Test specific functionality
npm test -- --grep "beat planning"
```

### Frontend Tests
```bash
# Run widget tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## 🔄 Business Logic

### Area Distribution Algorithm
1. **Fetch Areas**: Get unique areas from accounts in assigned pincodes
2. **Shuffle**: Randomize area order for fair distribution
3. **Round-Robin**: Distribute areas evenly across 7 days
4. **Validation**: Ensure no area appears on multiple days

### Missed Beat Handling
1. **Identify Incomplete**: Find areas not marked complete by end of day
2. **Find Next Day**: Look for next available day in same week
3. **Carry Forward**: Add incomplete areas to next day's plan
4. **Update Status**: Mark original day as MISSED, update carry-forward dates

### Completion Tracking
1. **GPS Capture**: Record location when area is marked complete
2. **Visit Count**: Track number of accounts visited in area
3. **Progress Update**: Update daily plan completion percentage
4. **Auto-Complete**: Mark day as COMPLETED when all areas done

## 🚨 Error Handling

### Backend
- Validation errors return 400 with descriptive messages
- Authentication errors return 401
- Authorization errors return 403
- Server errors return 500 with error details

### Frontend
- Network errors show retry options
- Validation errors highlight problematic fields
- Success/error messages via SnackBar
- Offline mode with cached data

## 📈 Performance Optimizations

### Database
- Indexes on frequently queried fields (salesmanId, weekStartDate, status)
- Efficient queries with proper joins and filtering
- Pagination for large datasets

### Frontend
- Lazy loading of beat plan details
- Caching of today's beat plan for offline access
- Optimistic UI updates for better user experience
- Image optimization and compression

## 🔮 Future Enhancements

1. **Route Optimization**: AI-powered route planning for efficient area coverage
2. **Push Notifications**: Real-time alerts for beat plan updates
3. **Geofencing**: Automatic area completion when entering/exiting areas
4. **Voice Notes**: Audio recording for area completion notes
5. **Photo Verification**: Capture photos as proof of area visits
6. **Weather Integration**: Adjust beat plans based on weather conditions
7. **Customer Feedback**: Collect feedback from visited accounts
8. **Predictive Analytics**: ML-based prediction of completion rates

## 🤝 Contributing

1. Follow existing code patterns and architecture
2. Add proper error handling and validation
3. Include unit tests for new functionality
4. Update documentation for API changes
5. Test on both Android and iOS platforms

## 📞 Support

For technical support or feature requests:
- Create an issue in the project repository
- Contact the development team
- Check the troubleshooting guide in the main README

---

**Note**: This module integrates seamlessly with the existing attendance, account management, and user management systems. All beat planning data is synchronized with the main CRM database for comprehensive reporting and analytics.