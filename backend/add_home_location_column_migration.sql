-- Migration to add isHomeLocation column to SalesmanRouteLog table
-- This fixes the error: "The column `SalesmanRouteLog.isHomeLocation` does not exist in the current database"

-- Add the missing column with default value
ALTER TABLE "SalesmanRouteLog" 
ADD COLUMN IF NOT EXISTS "isHomeLocation" BOOLEAN NOT NULL DEFAULT false;

-- Create index for performance (as defined in schema)
CREATE INDEX IF NOT EXISTS "SalesmanRouteLog_isHomeLocation_idx" ON "SalesmanRouteLog"("isHomeLocation");

-- Update existing records: mark the first record of each attendance session as home location
UPDATE "SalesmanRouteLog" 
SET "isHomeLocation" = true 
WHERE id IN (
    SELECT DISTINCT ON ("attendanceId") id 
    FROM "SalesmanRouteLog" 
    ORDER BY "attendanceId", "recordedAt" ASC
);

-- Verify the migration
SELECT 
    COUNT(*) as total_records,
    COUNT(*) FILTER (WHERE "isHomeLocation" = true) as home_locations,
    COUNT(DISTINCT "attendanceId") as unique_attendance_sessions
FROM "SalesmanRouteLog";