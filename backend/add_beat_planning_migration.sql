-- Beat Planning Module Migration
-- Add Weekly Beat Planning tables to existing database

-- Step 1: Create WeeklyBeatPlan table
CREATE TABLE IF NOT EXISTS "WeeklyBeatPlan" (
    "id" TEXT NOT NULL,
    "salesmanId" TEXT NOT NULL,
    "salesmanName" TEXT NOT NULL,
    "weekStartDate" TIMESTAMP(3) NOT NULL,
    "weekEndDate" TIMESTAMP(3) NOT NULL,
    "pincodes" TEXT[],
    "totalAreas" INTEGER NOT NULL DEFAULT 0,
    "status" TEXT NOT NULL DEFAULT 'DRAFT',
    "generatedBy" TEXT,
    "approvedBy" TEXT,
    "approvedAt" TIMESTAMP(3),
    "lockedBy" TEXT,
    "lockedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WeeklyBeatPlan_pkey" PRIMARY KEY ("id")
)

-- Step 2: Create DailyBeatPlan table
CREATE TABLE IF NOT EXISTS "DailyBeatPlan" (
    "id" TEXT NOT NULL,
    "weeklyBeatId" TEXT NOT NULL,
    "dayOfWeek" INTEGER NOT NULL,
    "dayDate" TIMESTAMP(3) NOT NULL,
    "assignedAreas" TEXT[],
    "plannedVisits" INTEGER NOT NULL DEFAULT 0,
    "actualVisits" INTEGER NOT NULL DEFAULT 0,
    "status" TEXT NOT NULL DEFAULT 'PLANNED',
    "completedAt" TIMESTAMP(3),
    "carriedFromDate" TIMESTAMP(3),
    "carriedToDate" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DailyBeatPlan_pkey" PRIMARY KEY ("id")
)

-- Step 3: Create BeatCompletion table
CREATE TABLE IF NOT EXISTS "BeatCompletion" (
    "id" TEXT NOT NULL,
    "dailyBeatId" TEXT NOT NULL,
    "salesmanId" TEXT NOT NULL,
    "areaName" TEXT NOT NULL,
    "accountsVisited" INTEGER NOT NULL DEFAULT 0,
    "completedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "notes" TEXT,
    "isVerified" BOOLEAN NOT NULL DEFAULT false,
    "verifiedBy" TEXT,
    "verifiedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "BeatCompletion_pkey" PRIMARY KEY ("id")
)

-- Step 4: Add unique constraints (only if they don't exist)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'WeeklyBeatPlan_salesmanId_weekStartDate_key'
    ) THEN
        ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_salesmanId_weekStartDate_key" UNIQUE ("salesmanId", "weekStartDate");
    END IF;
END $$

-- Step 5: Add unique constraint for DailyBeatPlan
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'DailyBeatPlan_weeklyBeatId_dayOfWeek_key'
    ) THEN
        ALTER TABLE "DailyBeatPlan" ADD CONSTRAINT "DailyBeatPlan_weeklyBeatId_dayOfWeek_key" UNIQUE ("weeklyBeatId", "dayOfWeek");
    END IF;
END $$

-- Step 6: Create indexes for WeeklyBeatPlan (only if they don't exist)
CREATE INDEX IF NOT EXISTS "WeeklyBeatPlan_salesmanId_idx" ON "WeeklyBeatPlan"("salesmanId")

CREATE INDEX IF NOT EXISTS "WeeklyBeatPlan_weekStartDate_idx" ON "WeeklyBeatPlan"("weekStartDate")

CREATE INDEX IF NOT EXISTS "WeeklyBeatPlan_status_idx" ON "WeeklyBeatPlan"("status")

CREATE INDEX IF NOT EXISTS "WeeklyBeatPlan_generatedBy_idx" ON "WeeklyBeatPlan"("generatedBy")

-- Step 7: Create indexes for DailyBeatPlan
CREATE INDEX IF NOT EXISTS "DailyBeatPlan_weeklyBeatId_idx" ON "DailyBeatPlan"("weeklyBeatId")

CREATE INDEX IF NOT EXISTS "DailyBeatPlan_dayOfWeek_idx" ON "DailyBeatPlan"("dayOfWeek")

CREATE INDEX IF NOT EXISTS "DailyBeatPlan_dayDate_idx" ON "DailyBeatPlan"("dayDate")

CREATE INDEX IF NOT EXISTS "DailyBeatPlan_status_idx" ON "DailyBeatPlan"("status")

-- Step 8: Create indexes for BeatCompletion
CREATE INDEX IF NOT EXISTS "BeatCompletion_dailyBeatId_idx" ON "BeatCompletion"("dailyBeatId")

CREATE INDEX IF NOT EXISTS "BeatCompletion_salesmanId_idx" ON "BeatCompletion"("salesmanId")

CREATE INDEX IF NOT EXISTS "BeatCompletion_completedAt_idx" ON "BeatCompletion"("completedAt")

CREATE INDEX IF NOT EXISTS "BeatCompletion_areaName_idx" ON "BeatCompletion"("areaName")

-- Step 9: Add foreign key constraints (only if they don't exist)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'WeeklyBeatPlan_salesmanId_fkey'
    ) THEN
        ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_salesmanId_fkey" FOREIGN KEY ("salesmanId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'WeeklyBeatPlan_generatedBy_fkey'
    ) THEN
        ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_generatedBy_fkey" FOREIGN KEY ("generatedBy") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'WeeklyBeatPlan_approvedBy_fkey'
    ) THEN
        ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_approvedBy_fkey" FOREIGN KEY ("approvedBy") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'WeeklyBeatPlan_lockedBy_fkey'
    ) THEN
        ALTER TABLE "WeeklyBeatPlan" ADD CONSTRAINT "WeeklyBeatPlan_lockedBy_fkey" FOREIGN KEY ("lockedBy") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'DailyBeatPlan_weeklyBeatId_fkey'
    ) THEN
        ALTER TABLE "DailyBeatPlan" ADD CONSTRAINT "DailyBeatPlan_weeklyBeatId_fkey" FOREIGN KEY ("weeklyBeatId") REFERENCES "WeeklyBeatPlan"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'BeatCompletion_dailyBeatId_fkey'
    ) THEN
        ALTER TABLE "BeatCompletion" ADD CONSTRAINT "BeatCompletion_dailyBeatId_fkey" FOREIGN KEY ("dailyBeatId") REFERENCES "DailyBeatPlan"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'BeatCompletion_salesmanId_fkey'
    ) THEN
        ALTER TABLE "BeatCompletion" ADD CONSTRAINT "BeatCompletion_salesmanId_fkey" FOREIGN KEY ("salesmanId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END $$

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'BeatCompletion_verifiedBy_fkey'
    ) THEN
        ALTER TABLE "BeatCompletion" ADD CONSTRAINT "BeatCompletion_verifiedBy_fkey" FOREIGN KEY ("verifiedBy") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    END IF;
END $$