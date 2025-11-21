# Simple Migration Guide - Account Master

## Easiest Method: Direct SQL in Neon Console

Since you're using Neon (PostgreSQL), follow these steps:

### Step 1: Open Neon Console
1. Go to https://console.neon.tech/
2. Select your project
3. Click on "SQL Editor" or "Query"

### Step 2: Copy and Run This SQL

```sql
-- Account Master Migration
BEGIN;

-- Add new columns
ALTER TABLE "Account" ADD COLUMN IF NOT EXISTS "businessName" TEXT;
ALTER TABLE "Account" ADD COLUMN IF NOT EXISTS "gstNumber" TEXT;
ALTER TABLE "Account" ADD COLUMN IF NOT EXISTS "panCard" TEXT;
ALTER TABLE "Account" ADD COLUMN IF NOT EXISTS "ownerImage" TEXT;
ALTER TABLE "Account" ADD COLUMN IF NOT EXISTS "shopImage" TEXT;
ALTER TABLE "Account" ADD COLUMN IF NOT EXISTS "isActive" BOOLEAN DEFAULT true;
ALTER TABLE "Account" ADD COLUMN IF NOT EXISTS "pincode" TEXT;
ALTER TABLE "Account" ADD COLUMN IF NOT EXISTS "country" TEXT;
ALTER TABLE "Account" ADD COLUMN IF NOT EXISTS "state" TEXT;
ALTER TABLE "Account" ADD COLUMN IF NOT EXISTS "district" TEXT;
ALTER TABLE "Account" ADD COLUMN IF NOT EXISTS "city" TEXT;
ALTER TABLE "Account" ADD COLUMN IF NOT EXISTS "area" TEXT;
ALTER TABLE "Account" ADD COLUMN IF NOT EXISTS "address" TEXT;

-- Update existing records
UPDATE "Account" 
SET "businessName" = "personName" || '''s Business'
WHERE "businessName" IS NULL;

UPDATE "Account" 
SET "isActive" = true
WHERE "isActive" IS NULL;

-- Create indexes
CREATE INDEX IF NOT EXISTS "Account_pincode_idx" ON "Account"("pincode");
CREATE INDEX IF NOT EXISTS "Account_isActive_idx" ON "Account"("isActive");
CREATE INDEX IF NOT EXISTS "Account_customerStage_idx" ON "Account"("customerStage");
CREATE INDEX IF NOT EXISTS "Account_createdAt_idx" ON "Account"("createdAt");

COMMIT;
```

### Step 3: Verify in Neon Console

Run this to check:
```sql
SELECT "accountCode", "businessName", "personName", "isActive" 
FROM "Account" 
LIMIT 5;
```

You should see:
- `businessName` column exists
- Existing records have businessName = "[PersonName]'s Business"
- `isActive` is true for all records

### Step 4: Update Prisma

Open a terminal in the **backend** folder and run:

```bash
cd backend
npx prisma db pull
npx prisma generate
```

This will:
1. Pull the updated schema from your database
2. Generate the Prisma Client with new fields

### Step 5: Restart Backend

```bash
cd backend
npm run dev
```

### Step 6: Test the New Account Master Screen

1. Open your Flutter app
2. Navigate to Account Master
3. You should see all the new fields:
   - Business Name
   - GST Number
   - PAN Card
   - Image pickers
   - Pincode lookup
   - Active/Inactive toggle

## Troubleshooting

### If SQL fails:
- Check you're connected to the right database
- Ensure you have write permissions
- Try running each ALTER TABLE statement one by one

### If Prisma commands fail:
Make sure you're in the `backend` folder:
```bash
cd C:\sparsh workspace\ADRS\loagma_crm\backend
npx prisma db pull
npx prisma generate
```

### If backend won't start:
```bash
cd backend
npm install
npm run dev
```

## Quick Commands Reference

```bash
# Navigate to backend
cd "C:\sparsh workspace\ADRS\loagma_crm\backend"

# Pull schema from database
npx prisma db pull

# Generate Prisma Client
npx prisma generate

# Start backend
npm run dev
```

## What's Next?

After migration is complete:
1. ✅ Backend is updated with new fields
2. ✅ Flutter has image_picker installed
3. ✅ New Account Master screen is ready
4. 🎯 Test creating accounts with all new fields
5. 🎯 Test pincode lookup
6. 🎯 Test image upload

## Need Help?

If you get stuck:
1. Check the SQL ran successfully in Neon
2. Verify `npx prisma db pull` completed
3. Verify `npx prisma generate` completed
4. Restart your backend server
5. Check backend logs for errors
