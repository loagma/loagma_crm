# Loagma CRM Backend API

Production-ready Node.js backend for Loagma CRM system.

## Project Structure

```
backend/
├── src/
│   ├── config/          # Configuration files
│   ├── controllers/     # Request handlers
│   ├── middleware/      # Express middleware
│   ├── routes/          # API routes
│   ├── services/        # Business logic
│   ├── utils/           # Helper functions
│   ├── app.js           # Express app setup
│   └── server.js        # Server entry point
├── prisma/
│   ├── migrations/      # Database migrations
│   ├── schema.prisma    # Database schema
│   └── seed.js          # Database seeding
├── .env                 # Environment variables
├── .env.example         # Environment template
└── package.json         # Dependencies

```

## Environment Variables

Copy `.env.example` to `.env` and configure:

```env
DATABASE_URL=postgresql://user:password@host:port/database
JWT_SECRET=your-secret-key
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
TWILIO_PHONE_NUMBER=your-twilio-number
CLOUDINARY_CLOUD_NAME=your-cloud-name
CLOUDINARY_API_KEY=your-api-key
CLOUDINARY_API_SECRET=your-api-secret
PORT=5000
NODE_ENV=production
```

## Installation

```bash
npm install
npx prisma generate
npx prisma migrate deploy
```

## Running

```bash
# Development
npm run dev

# Production
npm start
```

## API Endpoints

### Authentication
- `POST /auth/send-otp` - Send OTP to phone
- `POST /auth/verify-otp` - Verify OTP and login
- `POST /auth/refresh` - Refresh JWT token

### Users
- `GET /users` - Get all users
- `GET /users/:id` - Get user by ID
- `POST /users` - Create user
- `PUT /users/:id` - Update user
- `DELETE /users/:id` - Delete user

### Accounts
- `GET /accounts` - Get all accounts
- `POST /accounts` - Create account
- `PUT /accounts/:id` - Update account
- `DELETE /accounts/:id` - Delete account

### Task Assignments
- `GET /task-assignments` - Get assignments
- `POST /task-assignments` - Create assignment
- `PUT /task-assignments/:id` - Update assignment
- `DELETE /task-assignments/:id` - Delete assignment

### Locations
- `GET /locations/search` - Search locations
- `GET /pincode/:pincode` - Get location by pincode

### Expenses
- `GET /api/expenses` - Get expenses
- `POST /api/expenses` - Create expense
- `PUT /api/expenses/:id` - Update expense
- `DELETE /api/expenses/:id` - Delete expense

## Database

Uses PostgreSQL with Prisma ORM. Run migrations:

```bash
npx prisma migrate deploy
```

## Security

- JWT authentication
- Role-based access control
- Input validation
- CORS configured
- Environment variables for secrets

## License

Proprietary
