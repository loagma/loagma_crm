-- Add isHomeLocation column to SalesmanRouteLog table
ALTER TABLE "SalesmanRouteLog" ADD COLUMN "isHomeLocation" BOOLEAN NOT NULL DEFAULT false;

-- Create index for isHomeLocation queries
CREATE INDEX "SalesmanRouteLog_isHomeLocation_idx" ON "SalesmanRouteLog"("isHomeLocation");
