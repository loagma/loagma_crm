-- CreateTable
CREATE TABLE "Attendance" (
    "id" TEXT NOT NULL,
    "employeeId" TEXT NOT NULL,
    "employeeName" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "punchInTime" TIMESTAMP(3) NOT NULL,
    "punchInLatitude" DOUBLE PRECISION NOT NULL,
    "punchInLongitude" DOUBLE PRECISION NOT NULL,
    "punchInPhoto" TEXT,
    "punchInAddress" TEXT,
    "bikeKmStart" TEXT,
    "punchOutTime" TIMESTAMP(3),
    "punchOutLatitude" DOUBLE PRECISION,
    "punchOutLongitude" DOUBLE PRECISION,
    "punchOutPhoto" TEXT,
    "punchOutAddress" TEXT,
    "bikeKmEnd" TEXT,
    "totalWorkHours" DOUBLE PRECISION,
    "totalDistanceKm" DOUBLE PRECISION,
    "status" TEXT NOT NULL DEFAULT 'active',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Attendance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AreaAssignment" (
    "id" TEXT NOT NULL,
    "salesmanId" TEXT NOT NULL,
    "pinCode" TEXT NOT NULL,
    "country" TEXT NOT NULL,
    "state" TEXT NOT NULL,
    "district" TEXT NOT NULL,
    "city" TEXT NOT NULL,
    "areas" TEXT[],
    "businessTypes" TEXT[],
    "assignedDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "totalBusinesses" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "AreaAssignment_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Attendance_employeeId_idx" ON "Attendance"("employeeId");

-- CreateIndex
CREATE INDEX "Attendance_date_idx" ON "Attendance"("date");

-- CreateIndex
CREATE INDEX "Attendance_status_idx" ON "Attendance"("status");

-- CreateIndex
CREATE INDEX "Attendance_punchInTime_idx" ON "Attendance"("punchInTime");

-- CreateIndex
CREATE INDEX "AreaAssignment_salesmanId_idx" ON "AreaAssignment"("salesmanId");

-- CreateIndex
CREATE INDEX "AreaAssignment_pinCode_idx" ON "AreaAssignment"("pinCode");

-- CreateIndex
CREATE INDEX "AreaAssignment_city_district_idx" ON "AreaAssignment"("city", "district");

-- AddForeignKey
ALTER TABLE "AreaAssignment" ADD CONSTRAINT "AreaAssignment_salesmanId_fkey" FOREIGN KEY ("salesmanId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
