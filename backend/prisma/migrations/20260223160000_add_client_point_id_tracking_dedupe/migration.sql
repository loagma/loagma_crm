-- Add client-generated point id to support idempotent retries from mobile queue
ALTER TABLE "SalesmanTrackingPoint"
ADD COLUMN "clientPointId" TEXT;

-- Unique index for de-duplication of retransmitted points
CREATE UNIQUE INDEX "SalesmanTrackingPoint_clientPointId_key"
ON "SalesmanTrackingPoint"("clientPointId");

-- Composite route query index (employee + session + time)
CREATE INDEX "SalesmanTrackingPoint_employeeId_attendanceId_recordedAt_idx"
ON "SalesmanTrackingPoint"("employeeId", "attendanceId", "recordedAt");
