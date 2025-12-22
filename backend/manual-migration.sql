-- Manual Migration Script for Attendance Approval System
-- Run this script when database connection is stable

-- Add missing columns to Attendance table
ALTER TABLE "Attendance" ADD COLUMN IF NOT EXISTS "isLatePunchIn" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "Attendance" ADD COLUMN IF NOT EXISTS "lateApprovalId" TEXT;
ALTER TABLE "Attendance" ADD COLUMN IF NOT EXISTS "approvalCode" TEXT;
ALTER TABLE "Attendance" ADD COLUMN IF NOT EXISTS "isEarlyPunchOut" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "Attendance" ADD COLUMN IF NOT EXISTS "earlyPunchOutApprovalId" TEXT;
ALTER TABLE "Attendance" ADD COLUMN IF NOT EXISTS "earlyPunchOutCode" TEXT;

-- Create LatePunchApproval table
CREATE TABLE IF NOT EXISTS "LatePunchApproval" (
    "id" TEXT NOT NULL,
    "employeeId" TEXT NOT NULL,
    "employeeName" TEXT NOT NULL,
    "requestDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "punchInDate" TIMESTAMP(3) NOT NULL,
    "reason" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "approvedBy" TEXT,
    "approvedAt" TIMESTAMP(3),
    "adminRemarks" TEXT,
    "approvalCode" TEXT,
    "codeExpiresAt" TIMESTAMP(3),
    "codeUsed" BOOLEAN NOT NULL DEFAULT false,
    "codeUsedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "LatePunchApproval_pkey" PRIMARY KEY ("id")
);

-- Create EarlyPunchOutApproval table
CREATE TABLE IF NOT EXISTS "EarlyPunchOutApproval" (
    "id" TEXT NOT NULL,
    "employeeId" TEXT NOT NULL,
    "employeeName" TEXT NOT NULL,
    "attendanceId" TEXT NOT NULL,
    "requestDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "punchOutDate" TIMESTAMP(3) NOT NULL,
    "reason" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "approvedBy" TEXT,
    "approvedAt" TIMESTAMP(3),
    "adminRemarks" TEXT,
    "approvalCode" TEXT,
    "codeExpiresAt" TIMESTAMP(3),
    "codeUsed" BOOLEAN NOT NULL DEFAULT false,
    "codeUsedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "EarlyPunchOutApproval_pkey" PRIMARY KEY ("id")
);

-- Create indexes for LatePunchApproval
CREATE INDEX IF NOT EXISTS "LatePunchApproval_employeeId_idx" ON "LatePunchApproval"("employeeId");
CREATE INDEX IF NOT EXISTS "LatePunchApproval_status_idx" ON "LatePunchApproval"("status");
CREATE INDEX IF NOT EXISTS "LatePunchApproval_requestDate_idx" ON "LatePunchApproval"("requestDate");
CREATE INDEX IF NOT EXISTS "LatePunchApproval_approvalCode_idx" ON "LatePunchApproval"("approvalCode");

-- Create indexes for EarlyPunchOutApproval
CREATE INDEX IF NOT EXISTS "EarlyPunchOutApproval_employeeId_idx" ON "EarlyPunchOutApproval"("employeeId");
CREATE INDEX IF NOT EXISTS "EarlyPunchOutApproval_attendanceId_idx" ON "EarlyPunchOutApproval"("attendanceId");
CREATE INDEX IF NOT EXISTS "EarlyPunchOutApproval_status_idx" ON "EarlyPunchOutApproval"("status");
CREATE INDEX IF NOT EXISTS "EarlyPunchOutApproval_requestDate_idx" ON "EarlyPunchOutApproval"("requestDate");
CREATE INDEX IF NOT EXISTS "EarlyPunchOutApproval_approvalCode_idx" ON "EarlyPunchOutApproval"("approvalCode");

-- Add index for Attendance.isLatePunchIn
CREATE INDEX IF NOT EXISTS "Attendance_isLatePunchIn_idx" ON "Attendance"("isLatePunchIn");

-- Add foreign key constraints
ALTER TABLE "LatePunchApproval" ADD CONSTRAINT IF NOT EXISTS "LatePunchApproval_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "LatePunchApproval" ADD CONSTRAINT IF NOT EXISTS "LatePunchApproval_approvedBy_fkey" FOREIGN KEY ("approvedBy") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "EarlyPunchOutApproval" ADD CONSTRAINT IF NOT EXISTS "EarlyPunchOutApproval_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "EarlyPunchOutApproval" ADD CONSTRAINT IF NOT EXISTS "EarlyPunchOutApproval_approvedBy_fkey" FOREIGN KEY ("approvedBy") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Update User table relations (add columns to track approval relationships)
-- Note: These are handled by Prisma relations, no additional columns needed

COMMIT;