-- Add working hours columns to User table (with IF NOT EXISTS checks)
DO $$ 
BEGIN
    -- Add workStartTime column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'User' AND column_name = 'workStartTime') THEN
        ALTER TABLE "User" ADD COLUMN "workStartTime" TIME DEFAULT '09:00:00';
    END IF;
    
    -- Add workEndTime column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'User' AND column_name = 'workEndTime') THEN
        ALTER TABLE "User" ADD COLUMN "workEndTime" TIME DEFAULT '18:00:00';
    END IF;
    
    -- Add latePunchInGraceMinutes column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'User' AND column_name = 'latePunchInGraceMinutes') THEN
        ALTER TABLE "User" ADD COLUMN "latePunchInGraceMinutes" INTEGER DEFAULT 45;
    END IF;
    
    -- Add earlyPunchOutGraceMinutes column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'User' AND column_name = 'earlyPunchOutGraceMinutes') THEN
        ALTER TABLE "User" ADD COLUMN "earlyPunchOutGraceMinutes" INTEGER DEFAULT 30;
    END IF;
END $$;

-- Update existing users with default working hours where NULL
UPDATE "User" SET 
  "workStartTime" = '09:00:00'
WHERE "workStartTime" IS NULL;

UPDATE "User" SET 
  "workEndTime" = '18:00:00'
WHERE "workEndTime" IS NULL;

UPDATE "User" SET 
  "latePunchInGraceMinutes" = 45
WHERE "latePunchInGraceMinutes" IS NULL;

UPDATE "User" SET 
  "earlyPunchOutGraceMinutes" = 30
WHERE "earlyPunchOutGraceMinutes" IS NULL;