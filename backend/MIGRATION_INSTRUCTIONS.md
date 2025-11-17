# Database Migration Instructions for Account Master

## Changes Made to Schema

Added the following fields to the `Account` model:
- `createdById` - String? (references User who created the account)
- `approvedById` - String? (references User who approved the account)
- `approvedAt` - DateTime? (timestamp of approval)
- `isApproved` - Boolean (default: false)

Updated User model relations to support:
- `assignedAccounts` - Accounts assigned to this user
- `createdAccounts` - Accounts created by this user
- `approvedAccounts` - Accounts approved by this user

## Steps to Apply Migration

### 1. Generate Prisma Migration

```bash
cd backend
npx prisma migrate dev --name add_account_approval_tracking
```

### 2. Apply Migration to Database

The above command will automatically apply the migration. If you need to apply manually:

```bash
npx prisma migrate deploy
```

### 3. Generate Prisma Client

```bash
npx prisma generate
```

### 4. Verify Migration

```bash
npx prisma studio
```

This will open Prisma Studio where you can verify the new fields exist in the Account table.

## Rollback (if needed)

If you need to rollback this migration:

```bash
npx prisma migrate resolve --rolled-back add_account_approval_tracking
```

## Testing the Changes

### Test Account Creation
```bash
curl -X POST http://localhost:5000/accounts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "personName": "Test User",
    "contactNumber": "9876543210",
    "createdById": "USER_ID"
  }'
```

### Test Account Approval
```bash
curl -X POST http://localhost:5000/accounts/ACCOUNT_ID/approve \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "approvedById": "APPROVER_USER_ID"
  }'
```

### Test Fetching Accounts with Filters
```bash
# Get only approved accounts
curl "http://localhost:5000/accounts?isApproved=true" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get accounts created by specific user
curl "http://localhost:5000/accounts?createdById=USER_ID" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Notes

- All existing accounts will have `isApproved = false` by default
- `createdById`, `approvedById`, and `approvedAt` will be `null` for existing accounts
- The migration is backward compatible - existing functionality will continue to work
