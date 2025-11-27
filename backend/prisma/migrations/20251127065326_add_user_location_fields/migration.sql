/*
  Warnings:

  - You are about to drop the column `designation` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `employeeCode` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `functionalRoleId` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `jobPost` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `jobPostCode` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `jobPostName` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `joiningDate` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `managerId` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `nationality` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `postUnder` on the `User` table. All the data in the column will be lost.
  - Made the column `isActive` on table `Account` required. This step will fail if there are existing NULL values in that column.

*/
-- DropForeignKey
ALTER TABLE "User" DROP CONSTRAINT "User_managerId_fkey";

-- DropIndex
DROP INDEX "User_employeeCode_key";

-- AlterTable
ALTER TABLE "Account" ADD COLUMN     "businessSize" TEXT,
ADD COLUMN     "latitude" DOUBLE PRECISION,
ADD COLUMN     "longitude" DOUBLE PRECISION,
ALTER COLUMN "isActive" SET NOT NULL;

-- AlterTable
ALTER TABLE "User" DROP COLUMN "designation",
DROP COLUMN "employeeCode",
DROP COLUMN "functionalRoleId",
DROP COLUMN "jobPost",
DROP COLUMN "jobPostCode",
DROP COLUMN "jobPostName",
DROP COLUMN "joiningDate",
DROP COLUMN "managerId",
DROP COLUMN "nationality",
DROP COLUMN "postUnder",
ADD COLUMN     "area" TEXT,
ADD COLUMN     "country" TEXT,
ADD COLUMN     "district" TEXT,
ADD COLUMN     "latitude" DOUBLE PRECISION,
ADD COLUMN     "longitude" DOUBLE PRECISION;

-- CreateIndex
CREATE INDEX "Account_businessType_idx" ON "Account"("businessType");

-- CreateIndex
CREATE INDEX "Account_businessSize_idx" ON "Account"("businessSize");
