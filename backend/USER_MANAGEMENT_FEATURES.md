# User Management Features

## New Features Added

### 1. Profile Picture Upload
- Users can now upload profile pictures during employee creation
- Images are uploaded to Cloudinary (Cloud name: dfncqhkl9)
- Images are displayed in:
  - Employee list view
  - Employee detail view
  - Existing employee dialog

### 2. Duplicate Phone Number Check
- When entering a contact number, the system automatically checks if an employee with that number already exists
- If found, displays a dialog with:
  - Employee details (name, email, role, department, status)
  - Profile picture
  - Action buttons: View, Edit, Delete

### 3. Pincode-based Location Lookup
- Enter a 6-digit pincode and click "Lookup" button
- Automatically fetches:
  - Country
  - State
  - District
  - City
- Uses Indian Postal Pincode API

### 4. Manual Address Entry
- Toggle "Enter address manually" checkbox
- Allows manual entry of:
  - Country
  - State
  - District
  - City
  - Address

### 5. Enhanced Database Fields
- Added `country` field to User table
- Added `district` field to User table
- Both fields are optional (TEXT type)

## API Endpoints

### Create User
**POST** `/admin/users`

New fields supported:
```json
{
  "contactNumber": "9876543210",
  "name": "John Doe",
  "email": "john@example.com",
  "salaryPerMonth": 50000,
  "image": "https://res.cloudinary.com/...",
  "country": "India",
  "district": "Mumbai",
  "city": "Mumbai",
  "state": "Maharashtra",
  "pincode": "400001",
  "address": "123 Main Street",
  ...
}
```

### Get All Users
**GET** `/admin/users`

Returns users with:
- Profile images
- Country and district information
- Salary details

### Update User
**PUT** `/admin/users/:id`

Supports updating:
- Profile image
- Country
- District
- All other user fields

### Delete User
**DELETE** `/admin/users/:id`

## Migration Applied

Migration file: `prisma/migrations/add_country_district_to_user.sql`

```sql
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "country" TEXT;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "district" TEXT;
```

To apply manually:
```bash
node apply-user-fields-migration.js
```

## Frontend Changes

### Create User Screen
- Phone number field with duplicate check indicator
- Profile picture upload section
- Pincode lookup button
- Manual address toggle
- Country and district fields

### View Users Screen
- Displays profile pictures in list
- Shows employee images in detail view

## Cloudinary Configuration

- **Cloud Name**: dfncqhkl9
- **API Key**: 652667859422493
- **Upload Preset**: ml_default
- **Max Image Size**: 800x800px
- **Image Quality**: 85%

## Testing

1. Create a new employee with profile picture
2. Try entering an existing phone number
3. Use pincode lookup (e.g., 400001 for Mumbai)
4. Toggle manual address entry
5. View employee list to see images
6. Edit employee to update image

## Notes

- Images are stored on Cloudinary CDN
- Pincode lookup uses free Indian Postal API
- All new fields are optional
- Backward compatible with existing data
