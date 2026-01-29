-- AlterTable
ALTER TABLE "Account" ADD COLUMN "assignedDays" INTEGER[] DEFAULT ARRAY[]::INTEGER[];
