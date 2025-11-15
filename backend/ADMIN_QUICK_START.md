# Admin Quick Start

## Step 1: Configure Admin Phone Number

Edit `backend/prisma/seed.js` and change the admin phone number:

```javascript
const adminPhone = '+919876543210'; // Change to your phone
```

## Step 2: Run Database Migration (if needed)

```bash
npx prisma migrate dev
```

## Step 3: Seed Admin User

```bash
npm run seed
```

You should see:
```
✅ Admin user created with phone: +919876543210
✅ Roles seeded
🎉 Seeding completed!
```

## Step 4: Start Backend Server

```bash
npm run dev
```

## Step 5: Test Admin Login

1. Open Flutter app
2. Enter admin phone number
3. Check backend console for OTP
4. Enter OTP
5. Should redirect to Admin Dashboard

## Admin Capabilities

Once logged in as admin, you can:

1. **Create Users**
   - Enter contact number
   - Select role
   - User can login and complete profile

2. **View Users**
   - See all users
   - Delete users

3. **Manage Roles**
   - Create new roles
   - Edit role names
   - Delete roles

## API Endpoints

### Admin Endpoints (Requires Admin Role)
```
POST   /admin/users          - Create user
GET    /admin/users          - Get all users
DELETE /admin/users/:id      - Delete user
```

### Role Endpoints
```
GET    /roles                - Get all roles (public)
POST   /roles                - Create role (Admin only)
PUT    /roles/:id            - Update role (Admin only)
DELETE /roles/:id            - Delete role (Admin only)
```

## Troubleshooting

### Admin user already exists
If you see "ℹ️ Admin user already exists", the admin is already seeded. You can:
- Use the existing admin phone
- Or manually delete from database and re-seed

### Can't login as admin
1. Check if admin user exists in database
2. Verify phone number matches exactly
3. Check OTP in backend console
4. Ensure role is set to 'admin'

### Role-based routing not working
1. Check user has a role assigned
2. Verify role name matches exactly (case-sensitive)
3. Check RoleRouter in Flutter app
