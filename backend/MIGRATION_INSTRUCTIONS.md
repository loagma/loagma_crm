# Account Master Migration Instructions

## Problem
You have 2 existing records in the Account table, and we're adding new fields. Prisma won't allow adding required fields to a table with existing data.

## Solution: Manual Migration Steps

### Step 1: Create Migration File

Run this command in the backend folder:
```bash
npx prisma migrate dev --create-only --name account_master_refactoring
```

This will create a migration file in `prisma/migrations/` folder without applying it.

### Step 2: Edit the Migration File

Open the newly created migration file (it will be in a folder like `prisma/migrations/20240XXX_account_master_refactoring/migration.sql`)

Replace its content with this:

```sql
-- AlterTable: Add new optional columns to Account table
ALTER TABLE "Account" 
ADD COLUMN IF NOT EXISTS "businessName" TEXT,
ADD COLUMN IF NOT EXISTS "gstNumber" TEXT,
ADD COLUMN IF NOT EXISTS "panCard" TEXT,
ADD COLUMN IF NOT EXISTS "ownerImage" TEXT,
ADD COLUMN IF NOT EXISTS "shopImage" TEXT,
ADD COLUMN IF NOT EXISTS "isActive" BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS "pincode" TEXT,
ADD COLUMN IF NOT EXISTS "country" TEXT,
ADD COLUMN IF NOT EXISTS "state" TEXT,
ADD COLUMN IF NOT EXISTS "district" TEXT,
ADD COLUMN IF NOT EXISTS "city" TEXT,
ADD COLUMN IF NOT EXISTS "area" TEXT,
ADD COLUMN IF NOT EXISTS "address" TEXT;

-- Update existing records: Set businessName from personName
UPDATE "Account" 
SET "businessName" = "personName" || '''s Business'
WHERE "businessName" IS NULL;

-- Update existing records: Set isActive to true if NULL
UPDATE "Account" 
SET "isActive" = true
WHERE "isActive" IS NULL;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS "Account_pincode_idx" ON "Account"("pincode");
CREATE INDEX IF NOT EXISTS "Account_isActive_idx" ON "Account"("isActive");
CREATE INDEX IF NOT EXISTS "Account_customerStage_idx" ON "Account"("customerStage");
CREATE INDEX IF NOT EXISTS "Account_createdAt_idx" ON "Account"("createdAt");
```

### Step 3: Apply the Migration

Run this command:
```bash
npx prisma migrate dev
```

This will apply the migration you just edited.

### Step 4: Generate Prisma Client

Run this command:
```bash
npx prisma generate
```

### Step 5: Verify

Check that the migration was successful:
```bash
npx prisma studio
```

Open Prisma Studio and verify:
- All existing accounts have a `businessName`
- All existing accounts have `isActive = true`
- New fields are present

## Alternative: Quick SQL Script

If you prefer, you can run this SQL directly in your database:

```sql
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

-- Update existing data
UPDATE "Account" SET "businessName" = "personName" || '''s Business' WHERE "businessName" IS NULL;
UPDATE "Account" SET "isActive" = true WHERE "isActive" IS NULL;

-- Create indexes
CREATE INDEX IF NOT EXISTS "Account_pincode_idx" ON "Account"("pincode");
CREATE INDEX IF NOT EXISTS "Account_isActive_idx" ON "Account"("isActive");
CREATE INDEX IF NOT EXISTS "Account_customerStage_idx" ON "Account"("customerStage");
CREATE INDEX IF NOT EXISTS "Account_createdAt_idx" ON "Account"("createdAt");
```

Then run:
```bash
npx prisma db pull
npx prisma generate
```

## After Migration

Once migration is complete, you can:
1. Restart your backend server
2. Test the new Account Master screen
3. Create new accounts with all the new fields

## Troubleshooting

### If migration fails:
1. Check your DATABASE_URL in `.env`
2. Ensure PostgreSQL is running
3. Check database permissions
4. Try the SQL script method instead

### If Prisma Client errors:
```bash
npx prisma generate --force
```

### To reset and start fresh (⚠️ WARNING: Deletes all data):
```bash
npx prisma migrate reset
```
