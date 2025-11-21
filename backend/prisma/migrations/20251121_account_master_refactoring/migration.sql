-- Account Master Refactoring Migration
-- Adds new fields for business information, images, and pincode-based location

-- Add new columns to Account table
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

-- Update existing records with default values
UPDATE "Account" 
SET "businessName" = COALESCE("personName", 'Unknown') || '''s Business'
WHERE "businessName" IS NULL;

UPDATE "Account" 
SET "isActive" = true
WHERE "isActive" IS NULL;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS "Account_pincode_idx" ON "Account"("pincode");
CREATE INDEX IF NOT EXISTS "Account_isActive_idx" ON "Account"("isActive");
CREATE INDEX IF NOT EXISTS "Account_customerStage_idx" ON "Account"("customerStage");
CREATE INDEX IF NOT EXISTS "Account_createdAt_idx" ON "Account"("createdAt");
