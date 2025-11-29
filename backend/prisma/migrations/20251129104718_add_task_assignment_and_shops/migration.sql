-- CreateTable
CREATE TABLE "TaskAssignment" (
    "id" TEXT NOT NULL,
    "salesmanId" TEXT NOT NULL,
    "salesmanName" TEXT NOT NULL,
    "pincode" TEXT NOT NULL,
    "country" TEXT,
    "state" TEXT,
    "district" TEXT,
    "city" TEXT,
    "areas" TEXT[],
    "businessTypes" TEXT[],
    "totalBusinesses" INTEGER DEFAULT 0,
    "assignedDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TaskAssignment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Shop" (
    "id" TEXT NOT NULL,
    "placeId" TEXT,
    "name" TEXT NOT NULL,
    "businessType" TEXT NOT NULL,
    "address" TEXT,
    "pincode" TEXT NOT NULL,
    "area" TEXT,
    "city" TEXT,
    "state" TEXT,
    "country" TEXT,
    "latitude" DOUBLE PRECISION,
    "longitude" DOUBLE PRECISION,
    "phoneNumber" TEXT,
    "rating" DOUBLE PRECISION,
    "stage" TEXT NOT NULL DEFAULT 'new',
    "assignedTo" TEXT,
    "notes" TEXT,
    "lastContactDate" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Shop_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "TaskAssignment_salesmanId_idx" ON "TaskAssignment"("salesmanId");

-- CreateIndex
CREATE INDEX "TaskAssignment_pincode_idx" ON "TaskAssignment"("pincode");

-- CreateIndex
CREATE INDEX "TaskAssignment_assignedDate_idx" ON "TaskAssignment"("assignedDate");

-- CreateIndex
CREATE UNIQUE INDEX "Shop_placeId_key" ON "Shop"("placeId");

-- CreateIndex
CREATE INDEX "Shop_pincode_idx" ON "Shop"("pincode");

-- CreateIndex
CREATE INDEX "Shop_businessType_idx" ON "Shop"("businessType");

-- CreateIndex
CREATE INDEX "Shop_stage_idx" ON "Shop"("stage");

-- CreateIndex
CREATE INDEX "Shop_assignedTo_idx" ON "Shop"("assignedTo");

-- CreateIndex
CREATE INDEX "Shop_area_idx" ON "Shop"("area");
