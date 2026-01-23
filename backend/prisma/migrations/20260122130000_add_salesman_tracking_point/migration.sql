-- CreateTable
CREATE TABLE "SalesmanTrackingPoint" (
    "id" TEXT NOT NULL,
    "employeeId" TEXT NOT NULL,
    "attendanceId" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "speed" DOUBLE PRECISION,
    "accuracy" DOUBLE PRECISION,
    "recordedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SalesmanTrackingPoint_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "SalesmanTrackingPoint_employeeId_idx" ON "SalesmanTrackingPoint"("employeeId");

-- CreateIndex
CREATE INDEX "SalesmanTrackingPoint_attendanceId_idx" ON "SalesmanTrackingPoint"("attendanceId");

-- CreateIndex
CREATE INDEX "SalesmanTrackingPoint_recordedAt_idx" ON "SalesmanTrackingPoint"("recordedAt");

-- AddForeignKey
ALTER TABLE "SalesmanTrackingPoint" ADD CONSTRAINT "SalesmanTrackingPoint_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SalesmanTrackingPoint" ADD CONSTRAINT "SalesmanTrackingPoint_attendanceId_fkey" FOREIGN KEY ("attendanceId") REFERENCES "Attendance"("id") ON DELETE CASCADE ON UPDATE CASCADE;
