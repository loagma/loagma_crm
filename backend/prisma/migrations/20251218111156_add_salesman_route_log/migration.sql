-- CreateTable
CREATE TABLE "SalesmanRouteLog" (
    "id" TEXT NOT NULL,
    "employeeId" TEXT NOT NULL,
    "attendanceId" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "speed" DOUBLE PRECISION,
    "accuracy" DOUBLE PRECISION,
    "recordedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SalesmanRouteLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "SalesmanRouteLog_employeeId_idx" ON "SalesmanRouteLog"("employeeId");

-- CreateIndex
CREATE INDEX "SalesmanRouteLog_attendanceId_idx" ON "SalesmanRouteLog"("attendanceId");

-- CreateIndex
CREATE INDEX "SalesmanRouteLog_recordedAt_idx" ON "SalesmanRouteLog"("recordedAt");

-- AddForeignKey
ALTER TABLE "SalesmanRouteLog" ADD CONSTRAINT "SalesmanRouteLog_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SalesmanRouteLog" ADD CONSTRAINT "SalesmanRouteLog_attendanceId_fkey" FOREIGN KEY ("attendanceId") REFERENCES "Attendance"("id") ON DELETE CASCADE ON UPDATE CASCADE;
