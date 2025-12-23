-- Migration to add isHomeLocation column to SalesmanRouteLog table
-- This fixes the error: The column `SalesmanRouteLog.isHomeLocation` does not exist in the current database

-- Add the isHomeLocation column with default value false
ALTER TABLE "SalesmanRouteLog" 
ADD COLUMN IF NOT EXISTS "isHomeLocation" BOOLEAN NOT NULL DEFAULT false;

-- Create index for performance optimization
CREATE INDEX IF NOT EXISTS "SalesmanRouteLog_isHomeLocation_idx" ON "SalesmanRouteLog"("isHomeLocation");

-- Update existing records: Mark the first GPS point of each attendance session as home location
WITH first_points AS (
  SELECT DISTINCT ON ("attendanceId") 
    "id",
    "attendanceId",
    "recordedAt"
  FROM "SalesmanRouteLog"
  ORDER BY "attendanceId", "recordedAt" ASC
)
UPDATE "SalesmanRouteLog" 
SET "isHomeLocation" = true
WHERE "id" IN (SELECT "id" FROM first_points);

-- Verify the migration
SELECT 
  COUNT(*) as total_points,
  COUNT(*) FILTER (WHERE "isHomeLocation" = true) as home_locations
FROM "SalesmanRouteLog";