-- CreateTable
CREATE TABLE "SalaryInformation" (
    "id" TEXT NOT NULL,
    "employeeId" TEXT NOT NULL,
    "basicSalary" DOUBLE PRECISION NOT NULL,
    "hra" DOUBLE PRECISION DEFAULT 0,
    "travelAllowance" DOUBLE PRECISION DEFAULT 0,
    "dailyAllowance" DOUBLE PRECISION DEFAULT 0,
    "medicalAllowance" DOUBLE PRECISION DEFAULT 0,
    "specialAllowance" DOUBLE PRECISION DEFAULT 0,
    "otherAllowances" DOUBLE PRECISION DEFAULT 0,
    "providentFund" DOUBLE PRECISION DEFAULT 0,
    "professionalTax" DOUBLE PRECISION DEFAULT 0,
    "incomeTax" DOUBLE PRECISION DEFAULT 0,
    "otherDeductions" DOUBLE PRECISION DEFAULT 0,
    "effectiveFrom" TIMESTAMP(3) NOT NULL,
    "effectiveTo" TIMESTAMP(3),
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "paymentFrequency" TEXT NOT NULL DEFAULT 'Monthly',
    "bankName" TEXT,
    "accountNumber" TEXT,
    "ifscCode" TEXT,
    "panNumber" TEXT,
    "remarks" TEXT,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SalaryInformation_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "SalaryInformation_employeeId_key" ON "SalaryInformation"("employeeId");

-- CreateIndex
CREATE INDEX "SalaryInformation_employeeId_idx" ON "SalaryInformation"("employeeId");

-- CreateIndex
CREATE INDEX "SalaryInformation_effectiveFrom_idx" ON "SalaryInformation"("effectiveFrom");

-- CreateIndex
CREATE INDEX "SalaryInformation_isActive_idx" ON "SalaryInformation"("isActive");

-- AddForeignKey
ALTER TABLE "SalaryInformation" ADD CONSTRAINT "SalaryInformation_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
