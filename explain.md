# LOAGMA CRM - Complete Project Documentation

## 📋 Project Overview

**LOAGMA CRM** is a comprehensive Customer Relationship Management system built with Flutter (Frontend) and Node.js (Backend). It's designed for managing business accounts, sales operations, and customer relationships with role-based access control.

### 🎯 Project Purpose
- Manage customer accounts and business relationships
- Track sales activities and customer interactions
- Provide role-based access (Admin, Manager, Salesman)
- Handle geolocation-based account management
- Support image uploads and document management
- Real-time data synchronization

---

## 🏗️ Architecture Overview

### Frontend (Flutter)
- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: StatefulWidget with setState
- **Navigation**: GoRouter for routing
- **HTTP Client**: http package for API calls
- **Image Handling**: image_picker package
- **Maps**: google_maps_flutter
- **Location**: geolocator package

### Backend (Node.js)
- **Framework**: Express.js
- **Database**: PostgreSQL with Prisma ORM
- **Authentication**: JWT tokens
- **File Upload**: Multer middleware
- **API Architecture**: RESTful APIs
- **Environment**: dotenv for configuration

---

## 👥 User Roles & Permissions

### 1. **Admin**
- Full system access
- User management (create, edit, delete users)
- Account master management
- System configuration
- Reports and analytics
- Department and area management

### 2. **Manager**
- Team management
- Account oversight
- Performance monitoring
- Report generation
- Salesman supervision

### 3. **Salesman**
- Account creation and management
- Customer interaction tracking
- Lead management
- Personal dashboard
- Account editing capabilities

---

## 🚀 Core Features

### 🔐 Authentication System
- **Login/Logout**: Secure JWT-based authentication
- **Role-based Access**: Different dashboards per role
- **Session Management**: Automatic token refresh
- **Password Security**: Encrypted password storage

### 📊 Dashboard Features
- **Role-specific Dashboards**: Customized for each user type
- **Real-time Statistics**: Account counts, status tracking
- **Quick Actions**: Fast access to common tasks
- **Navigation Menu**: Role-based menu items

### 👤 Account Management

#### Account Creation
- **Business Information**:
  - Business Name (required)
  - Business Type (Kirana Store, Sweet Shop, Restaurant, etc.)
  - Business Size (Semi Retailer, Retailer, Wholesaler, etc.)
  - Person Name (required)
  - Contact Number (10-digit validation)
  - Date of Birth (date picker)
  - GST Number (auto-uppercase)
  - PAN Card (auto-uppercase, 10 char limit)

#### Customer Lifecycle Management
- **Customer Stages**: Lead → Prospect → Customer → Inactive
- **Funnel Stages**: Awareness → Interest → Consideration → Intent → Evaluation → Converted
- **Status Management**: Active/Inactive toggle

#### Image Management
- **Shop Owner Image**: Required, camera/gallery picker
- **Shop Image**: Required, camera/gallery picker
- **Image Processing**: Compression, base64 encoding
- **Preview & Edit**: Visual image management

#### Location Management
- **Pincode Lookup**: Auto-fills location details
- **Geographic Data**: Country, State, District, City
- **Area Selection**: Dynamic dropdown based on pincode
- **Address Entry**: Multi-line address input
- **Geolocation**: GPS coordinates capture
- **Google Maps**: Interactive map display

### 🔍 Advanced Search & Filtering

#### Multi-criteria Filtering
- **Customer Stage**: Lead, Prospect, Customer, Inactive
- **Business Type**: Multiple business categories
- **Business Size**: Different size categories
- **Funnel Stage**: Sales pipeline stages
- **Location**: City and Pincode filtering
- **Status**: Approval and Active status
- **Search**: Text search across multiple fields

#### Filter Management
- **Expandable Filters**: Collapsible filter panel
- **Active Filter Count**: Visual indicator
- **Clear All Filters**: Reset functionality
- **Filter Persistence**: Maintains state during session

### 📱 Mobile-First Design

#### Responsive UI
- **Card-based Layout**: Modern card design
- **Professional Color Scheme**: Gold (#D7BE69) primary color
- **Touch-friendly**: Optimized for mobile interaction
- **Loading States**: Visual feedback for all operations

#### User Experience
- **Bottom Sheets**: Modal forms and dialogs
- **Swipe Actions**: Intuitive gesture support
- **Pull-to-Refresh**: Data refresh functionality
- **Error Handling**: User-friendly error messages

---

## 🛠️ Technical Implementation

### Frontend Architecture

#### Project Structure
```
loagma_crm/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/                   # Data models
│   │   ├── account_model.dart
│   │   └── user_model.dart
│   ├── services/                 # API services
│   │   ├── api_config.dart
│   │   ├── account_service.dart
│   │   ├── user_service.dart
│   │   └── pincode_service.dart
│   ├── screens/                  # UI screens
│   │   ├── auth/                # Authentication screens
│   │   ├── admin/               # Admin-specific screens
│   │   ├── manager/             # Manager-specific screens
│   │   ├── salesman/            # Salesman-specific screens
│   │   └── shared/              # Shared screens
│   └── utils/                   # Utility functions
│       └── custom_toast.dart
```

#### Key Services

##### API Configuration
```dart
class ApiConfig {
  static const String baseUrl = 'http://your-api-url';
  static const String accountsEndpoint = '/accounts';
  static const String usersEndpoint = '/users';
  static const String authEndpoint = '/auth';
}
```

##### User Service
- Session management
- Role-based access control
- Token handling
- User state persistence

##### Account Service
- CRUD operations for accounts
- Image upload handling
- Geolocation data management
- Search and filtering

##### Pincode Service
- Location data fetching
- Area lookup functionality
- Geographic validation

### Backend Architecture

#### Database Schema (Prisma)

##### User Model
```prisma
model User {
  id          String   @id @default(cuid())
  email       String   @unique
  password    String
  name        String
  role        Role
  isActive    Boolean  @default(true)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  accounts    Account[]
}
```

##### Account Model
```prisma
model Account {
  id              String    @id @default(cuid())
  accountCode     String    @unique
  businessName    String?
  personName      String
  contactNumber   String
  businessType    String?
  businessSize    String?
  customerStage   String?
  funnelStage     String?
  gstNumber       String?
  panCard         String?
  dateOfBirth     DateTime?
  ownerImage      String?
  shopImage       String?
  pincode         String?
  country         String?
  state           String?
  district        String?
  city            String?
  area            String?
  address         String?
  latitude        Float?
  longitude       Float?
  isActive        Boolean   @default(true)
  isApproved      Boolean   @default(false)
  createdById     String
  createdBy       User      @relation(fields: [createdById], references: [id])
  createdAt       DateTime  @default(now())
  updatedAt       DateTime  @updatedAt
}
```

#### API Endpoints

##### Authentication
- `POST /auth/login` - User login
- `POST /auth/logout` - User logout
- `POST /auth/refresh` - Token refresh

##### Accounts
- `GET /accounts` - List accounts with filtering
- `POST /accounts` - Create new account
- `GET /accounts/:id` - Get account details
- `PUT /accounts/:id` - Update account
- `DELETE /accounts/:id` - Delete account

##### Users
- `GET /users` - List users (Admin only)
- `POST /users` - Create user (Admin only)
- `PUT /users/:id` - Update user
- `DELETE /users/:id` - Delete user (Admin only)

##### Utilities
- `GET /pincode/:code` - Get location data by pincode
- `GET /areas/:pincode` - Get areas by pincode

---

## 🎨 UI/UX Features

### Design System

#### Color Palette
- **Primary Gold**: #D7BE69 (main brand color)
- **Success Green**: #059669 (call buttons, success states)
- **Error Red**: #DC2626 (error states, validation)
- **Text Dark**: #1F2937 (primary text)
- **Text Muted**: #6B7280 (secondary text)

#### Typography
- **Headers**: Bold, 20px for main titles
- **Body Text**: Regular, 14-16px for content
- **Captions**: 11-12px for labels and hints
- **Buttons**: Semi-bold, 16px for actions

#### Components

##### Cards
- **Elevation**: Subtle shadows for depth
- **Rounded Corners**: 16px border radius
- **Padding**: 18px internal spacing
- **Borders**: Light gray borders

##### Buttons
- **Primary**: Gold background, white text
- **Secondary**: Outlined with gold border
- **Icon Buttons**: Circular with shadows
- **Loading States**: Spinner indicators

##### Forms
- **Text Fields**: Outlined with gold focus
- **Dropdowns**: Consistent styling
- **Validation**: Red borders for errors
- **Section Headers**: Color-coded backgrounds

### Interactive Elements

#### Account Cards
- **Avatar**: Circular with initials
- **Action Buttons**: Edit and Call buttons
- **Information Display**: Structured data layout
- **Touch Feedback**: Ripple effects

#### Filter System
- **Chip-based Filters**: Toggle selection
- **Expandable Panel**: Collapsible interface
- **Active Indicators**: Visual feedback
- **Clear Actions**: Easy reset options

#### Image Pickers
- **Placeholder State**: Upload instructions
- **Preview Mode**: Full image display
- **Edit Overlay**: Action buttons
- **Source Selection**: Camera/Gallery options

---

## 🔧 Advanced Features

### Geolocation Integration

#### GPS Functionality
- **Permission Handling**: Location access requests
- **Accuracy Settings**: High precision GPS
- **Error Management**: Service availability checks
- **Coordinate Display**: Lat/Long formatting

#### Google Maps
- **Interactive Maps**: Zoom, pan, markers
- **Custom Markers**: Account location pins
- **Info Windows**: Account details popup
- **External Launch**: Open in Google Maps app

### Image Processing

#### Upload Pipeline
1. **Source Selection**: Camera or Gallery
2. **Image Compression**: 800x800px max, 70% quality
3. **Base64 Encoding**: API-compatible format
4. **Preview Generation**: Immediate feedback
5. **Server Upload**: Async processing

#### Storage Strategy
- **Base64 Strings**: Embedded in database
- **Compression**: Optimized file sizes
- **Validation**: Image format checking
- **Error Handling**: Upload failure recovery

### Data Synchronization

#### Real-time Updates
- **Optimistic Updates**: Immediate UI feedback
- **Error Recovery**: Rollback on failure
- **Conflict Resolution**: Server-side validation
- **Cache Management**: Local data storage

#### Offline Support
- **Local Storage**: Critical data caching
- **Sync Queue**: Pending operations
- **Network Detection**: Connectivity monitoring
- **Graceful Degradation**: Offline functionality

---

## 📊 Performance Optimizations

### Frontend Optimizations

#### Rendering Performance
- **Lazy Loading**: On-demand widget creation
- **Image Caching**: Efficient memory usage
- **List Virtualization**: Large dataset handling
- **State Management**: Minimal rebuilds

#### Network Efficiency
- **Request Batching**: Combined API calls
- **Caching Strategy**: Response caching
- **Compression**: Gzip encoding
- **Timeout Handling**: Request timeouts

### Backend Optimizations

#### Database Performance
- **Indexing**: Optimized query performance
- **Connection Pooling**: Efficient connections
- **Query Optimization**: Minimal data transfer
- **Pagination**: Large dataset handling

#### API Efficiency
- **Response Compression**: Reduced payload size
- **Caching Headers**: Browser caching
- **Rate Limiting**: API protection
- **Error Handling**: Graceful failures

---

## 🔒 Security Features

### Authentication Security
- **JWT Tokens**: Secure session management
- **Password Hashing**: bcrypt encryption
- **Token Expiration**: Automatic logout
- **Refresh Tokens**: Seamless renewal

### Data Protection
- **Input Validation**: SQL injection prevention
- **XSS Protection**: Cross-site scripting prevention
- **CORS Configuration**: Cross-origin security
- **Rate Limiting**: Brute force protection

### Role-based Security
- **Permission Checks**: Endpoint protection
- **Data Isolation**: User-specific data
- **Admin Controls**: Privileged operations
- **Audit Logging**: Activity tracking

---

## 🧪 Testing Strategy

### Frontend Testing
- **Unit Tests**: Service and utility testing
- **Widget Tests**: UI component testing
- **Integration Tests**: End-to-end workflows
- **Performance Tests**: Memory and speed testing

### Backend Testing
- **API Tests**: Endpoint functionality
- **Database Tests**: Data integrity
- **Security Tests**: Vulnerability scanning
- **Load Tests**: Performance under stress

---

## 🚀 Deployment & DevOps

### Frontend Deployment
- **Build Process**: Flutter build optimization
- **Asset Optimization**: Image and font compression
- **Code Splitting**: Lazy loading implementation
- **Platform Builds**: Android/iOS compilation

### Backend Deployment
- **Environment Configuration**: Production settings
- **Database Migration**: Schema updates
- **Load Balancing**: Traffic distribution
- **Monitoring**: Performance tracking

### CI/CD Pipeline
- **Automated Testing**: Pre-deployment validation
- **Build Automation**: Continuous integration
- **Deployment Automation**: Zero-downtime updates
- **Rollback Strategy**: Quick recovery options

---

## 📈 Analytics & Monitoring

### User Analytics
- **Usage Tracking**: Feature utilization
- **Performance Metrics**: App responsiveness
- **Error Tracking**: Crash reporting
- **User Behavior**: Interaction patterns

### Business Metrics
- **Account Creation**: Growth tracking
- **User Engagement**: Activity levels
- **Conversion Rates**: Sales pipeline metrics
- **Geographic Distribution**: Location analytics

---

## 🛣️ NEW FEATURE: Salesman Route Tracking

### Overview
A comprehensive route tracking system that records salesman travel patterns during active attendance sessions. This feature provides complete visibility into field operations with GPS trail visualization, route playback, and movement analytics.

### 🎯 Key Features

#### **GPS Route Recording**
- **Continuous Tracking**: Records GPS points every 20-30 seconds during active attendance
- **Battery Optimized**: Intelligent filtering to avoid duplicate points and minimize battery drain
- **Accuracy Validation**: Filters abnormal GPS jumps and validates coordinate ranges
- **Automatic Integration**: Seamlessly starts/stops with punch-in/punch-out without user intervention

#### **Admin Route Visualization**
- **Interactive Maps**: Google Maps integration with complete route polylines
- **Start/End Markers**: Green marker for punch-in, red marker for punch-out locations
- **Animated Playback**: Moving marker that replays the salesman's journey at 1 point per second
- **Route Summary**: Distance, duration, and GPS point statistics

#### **Movement Analytics**
- **Distance Charts**: Time-based distance progression using Haversine formula calculations
- **Speed Analysis**: Speed over time graphs when GPS speed data is available
- **Route Statistics**: Total distance, work hours, and movement patterns
- **Performance Insights**: Route efficiency and travel behavior analysis

### 🏗️ Technical Implementation

#### **Database Schema**
```sql
-- New table added without modifying existing structure
CREATE TABLE "SalesmanRouteLog" (
    "id" TEXT NOT NULL,
    "employeeId" TEXT NOT NULL,
    "attendanceId" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "speed" DOUBLE PRECISION,
    "accuracy" DOUBLE PRECISION,
    "recordedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT "SalesmanRouteLog_pkey" PRIMARY KEY ("id")
);

-- Optimized indexes for performance
CREATE INDEX "SalesmanRouteLog_employeeId_idx" ON "SalesmanRouteLog"("employeeId");
CREATE INDEX "SalesmanRouteLog_attendanceId_idx" ON "SalesmanRouteLog"("attendanceId");
CREATE INDEX "SalesmanRouteLog_recordedAt_idx" ON "SalesmanRouteLog"("recordedAt");
```

#### **Backend API Endpoints**
- `POST /api/routes/point` - Store GPS route point (lightweight, high-frequency)
- `GET /api/routes/attendance/:id` - Fetch complete route for visualization
- `GET /api/routes/summary` - Get route overview for multiple sessions

#### **Frontend Services**
- **RouteService**: API communication and distance calculations
- **RouteTrackingService**: GPS point collection and filtering
- **Integration**: Seamless integration with existing AttendanceService

#### **Route Visualization Components**
- **RouteVisualizationScreen**: Complete route display with maps and charts
- **RouteListScreen**: Admin overview of all tracked routes
- **Interactive Controls**: Play/pause/reset route playback functionality

### 🔧 Performance Optimizations

#### **Battery Efficiency**
- **Smart Intervals**: 25-second GPS collection intervals (not every second)
- **Movement Filtering**: Only stores points with >10m movement
- **Duplicate Prevention**: Avoids storing redundant location data
- **Background Optimization**: Minimal CPU usage during tracking

#### **Network Efficiency**
- **Lightweight Payloads**: Minimal data per GPS point
- **Batch Processing**: Efficient API calls without overwhelming server
- **Error Resilience**: Continues tracking even if individual API calls fail
- **Graceful Degradation**: Works with intermittent connectivity

#### **Database Performance**
- **Indexed Queries**: Optimized for fast route retrieval
- **Efficient Relations**: Proper foreign key relationships
- **Bulk Operations**: Optimized for high-frequency inserts
- **Query Optimization**: Minimal data transfer for visualization

### 📊 Route Analytics Features

#### **Distance Calculations**
- **Haversine Formula**: Accurate distance between GPS coordinates
- **Cumulative Distance**: Total travel distance for entire route
- **Segment Analysis**: Distance between consecutive points
- **Route Efficiency**: Direct vs actual travel distance comparison

#### **Speed Analysis**
- **Real-time Speed**: GPS-derived speed data when available
- **Average Speed**: Route-wide speed calculations
- **Speed Patterns**: Time-based speed variation analysis
- **Movement Detection**: Stationary vs moving time identification

#### **Visual Analytics**
- **Interactive Charts**: fl_chart library for smooth visualizations
- **Time-based Graphs**: X-axis time progression with Y-axis metrics
- **Multi-metric Display**: Distance and speed charts in tabbed interface
- **Real-time Updates**: Charts update as route playback progresses

### 🛡️ Security & Privacy

#### **Data Protection**
- **Employee Consent**: Route tracking only during work hours
- **Secure Storage**: Encrypted GPS data in production database
- **Access Control**: Admin-only access to route visualization
- **Data Retention**: Configurable retention policies for route data

#### **Privacy Compliance**
- **Work Hours Only**: Tracking limited to active attendance sessions
- **Transparent Operation**: Clear indication when tracking is active
- **User Control**: Automatic stop when punch-out occurs
- **Minimal Data**: Only essential GPS coordinates stored

### 🚀 Integration Benefits

#### **Operational Insights**
- **Field Efficiency**: Understand salesman travel patterns
- **Territory Coverage**: Visualize area coverage and gaps
- **Time Management**: Analyze time spent traveling vs on-site
- **Route Optimization**: Identify efficient travel routes

#### **Management Tools**
- **Performance Monitoring**: Track field team productivity
- **Compliance Verification**: Ensure salesmen visit assigned areas
- **Resource Planning**: Optimize territory assignments
- **Training Opportunities**: Identify coaching needs from route data

#### **Business Intelligence**
- **Travel Cost Analysis**: Calculate fuel and time costs
- **Customer Visit Patterns**: Understand client interaction frequency
- **Market Coverage**: Assess geographic market penetration
- **Efficiency Metrics**: Measure field operation effectiveness

### 🔄 Backward Compatibility

#### **Zero Breaking Changes**
- **Existing Features Intact**: All current CRM functionality unchanged
- **Optional Enhancement**: Route tracking enhances without replacing
- **Graceful Fallback**: System works normally if route tracking fails
- **Progressive Enhancement**: New features add value without disruption

#### **Seamless Integration**
- **Automatic Activation**: Starts with existing punch-in process
- **Transparent Operation**: No additional user actions required
- **Existing UI Preserved**: All current screens and workflows unchanged
- **Data Consistency**: Maintains all existing data relationships

### 📈 Future Enhancements

#### **Advanced Analytics**
- **Predictive Routing**: AI-powered route suggestions
- **Traffic Integration**: Real-time traffic data incorporation
- **Weather Correlation**: Route efficiency vs weather conditions
- **Customer Density Mapping**: Optimize routes based on client locations

#### **Enhanced Visualization**
- **3D Route Display**: Elevation-aware route visualization
- **Heat Maps**: Activity density visualization
- **Comparative Analysis**: Multi-salesman route comparison
- **Export Capabilities**: Route data export for external analysis

## 🔮 Future Enhancements

### Planned Features
- **Push Notifications**: Real-time alerts
- **Offline Sync**: Complete offline support
- **Advanced Analytics**: Business intelligence
- **Integration APIs**: Third-party connections
- **Mobile App**: Native iOS/Android apps
- **Web Dashboard**: Browser-based interface

### Scalability Improvements
- **Microservices**: Service decomposition
- **Cloud Storage**: File management
- **CDN Integration**: Global content delivery
- **Database Sharding**: Horizontal scaling

---

## 📚 Development Guidelines

### Code Standards
- **Naming Conventions**: Consistent naming
- **Documentation**: Comprehensive comments
- **Error Handling**: Graceful error management
- **Performance**: Optimized implementations

### Best Practices
- **Security First**: Security-conscious development
- **User Experience**: User-centric design
- **Maintainability**: Clean, readable code
- **Testing**: Comprehensive test coverage

---

## 🛠️ Setup & Installation

### Prerequisites
- Flutter SDK 3.x
- Node.js 18+
- PostgreSQL 14+
- Android Studio / Xcode
- Git

### Frontend Setup
```bash
cd loagma_crm
flutter pub get
flutter run
```

### Backend Setup
```bash
cd backend
npm install
npx prisma migrate dev
npm run dev
```

### Environment Configuration
- Configure API endpoints
- Set up database connections
- Configure authentication keys
- Set up external service APIs

---

## 📞 Support & Maintenance

### Documentation
- **API Documentation**: Comprehensive endpoint docs
- **User Guides**: Feature usage instructions
- **Developer Docs**: Technical implementation guides
- **Troubleshooting**: Common issue resolution

### Maintenance Schedule
- **Regular Updates**: Security patches
- **Feature Releases**: New functionality
- **Performance Monitoring**: Continuous optimization
- **User Feedback**: Feature improvement cycles

---

## 🎯 Conclusion

LOAGMA CRM is a comprehensive, feature-rich customer relationship management system that provides:

- **Complete Account Management**: From lead to customer conversion
- **Role-based Access Control**: Secure, permission-based operations
- **Mobile-first Design**: Optimized for field sales operations
- **Advanced Features**: Geolocation, image management, real-time sync
- **Scalable Architecture**: Built for growth and expansion
- **Professional UI/UX**: Modern, intuitive user experience

The system successfully bridges the gap between traditional CRM systems and modern mobile-first business operations, providing a powerful tool for sales teams and business management.

---

*This documentation covers the complete LOAGMA CRM system as of the current implementation. For specific technical details or feature requests, please refer to the respective code modules and API documentation.*