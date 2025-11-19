# Backend Database Update Instructions

## Issue
The new user fields (name, email, address, etc.) are not saving because the backend server needs to be restarted after the database migration.

## Solution - Follow These Steps:

### Step 1: Stop the Backend Server
If your backend server is running, stop it (Ctrl+C in the terminal where it's running)

### Step 2: Regenerate Prisma Client
Open a terminal in the `backend` folder and run:
```bash
cd backend
npx prisma generate
```

### Step 3: Verify Migration
Check if migration was applied:
```bash
npx prisma migrate status
```

If it shows pending migrations, run:
```bash
npx prisma migrate deploy
```

### Step 4: Start the Backend Server
```bash
npm start
```
OR
```bash
node src/server.js
```

### Step 5: Test the API
After restarting, test creating a user with all fields from your Flutter app.

## Quick Test (Optional)
You can test if the database has the new columns by running:
```bash
node test-user-creation.js
```

This will create and delete a test user to verify all fields work.

## What Was Changed

### Database Schema (Prisma)
Added these fields to the User model:
- `alternativeNumber` - Alternative phone number
- `roles` - Array of role IDs for multiple roles
- `address` - Full address
- `city` - City name
- `state` - State name
- `pincode` - Postal code
- `aadharCard` - Aadhar card number
- `panCard` - PAN card number
- `password` - User password
- `notes` - Additional notes

### Backend API
The API endpoints already support all these fields:
- POST `/api/admin/users` - Create user
- PUT `/api/admin/users/:id` - Update user
- GET `/api/admin/users` - Get all users

## Troubleshooting

### If fields still don't save:
1. Check backend console for errors
2. Verify DATABASE_URL in `.env` file
3. Make sure Prisma client is regenerated: `npx prisma generate`
4. Restart the backend server

### If you see "column does not exist" error:
Run the migration again:
```bash
npx prisma migrate deploy
```

### If migration fails:
Try pushing the schema directly:
```bash
npx prisma db push
```

## Verification
After restarting the backend:
1. Create a new user from Flutter app with name and email
2. Check if the data appears in the user list
3. Click on the user to see full details
4. Edit the user and verify all fields are editable

The migration file is located at:
`backend/prisma/migrations/20251119064302_add_user_fields/migration.sql`
