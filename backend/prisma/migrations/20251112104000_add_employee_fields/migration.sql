/*
  Warnings:

  - You are about to drop the `Area` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `City` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Country` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `District` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `State` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Zone` table. If the table is not empty, all the data it contains will be lost.
  - A unique constraint covering the columns `[employeeCode]` on the table `User` will be added. If there are existing duplicate values, this will fail.

*/
-- DropForeignKey
ALTER TABLE "Account" DROP CONSTRAINT "Account_areaId_fkey";

-- DropForeignKey
ALTER TABLE "Area" DROP CONSTRAINT "Area_zoneId_fkey";

-- DropForeignKey
ALTER TABLE "City" DROP CONSTRAINT "City_districtId_fkey";

-- DropForeignKey
ALTER TABLE "District" DROP CONSTRAINT "District_stateId_fkey";

-- DropForeignKey
ALTER TABLE "EmployeeArea" DROP CONSTRAINT "EmployeeArea_areaId_fkey";

-- DropForeignKey
ALTER TABLE "State" DROP CONSTRAINT "State_countryId_fkey";

-- DropForeignKey
ALTER TABLE "Zone" DROP CONSTRAINT "Zone_cityId_fkey";

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "dateOfBirth" TIMESTAMP(3),
ADD COLUMN     "designation" TEXT,
ADD COLUMN     "employeeCode" TEXT,
ADD COLUMN     "gender" TEXT,
ADD COLUMN     "image" TEXT,
ADD COLUMN     "inchargeCode" TEXT,
ADD COLUMN     "inchargeName" TEXT,
ADD COLUMN     "jobPost" TEXT,
ADD COLUMN     "jobPostCode" TEXT,
ADD COLUMN     "jobPostName" TEXT,
ADD COLUMN     "joiningDate" TIMESTAMP(3),
ADD COLUMN     "nationality" TEXT,
ADD COLUMN     "postUnder" TEXT,
ADD COLUMN     "preferredLanguages" TEXT[];

-- DropTable
DROP TABLE "Area";

-- DropTable
DROP TABLE "City";

-- DropTable
DROP TABLE "Country";

-- DropTable
DROP TABLE "District";

-- DropTable
DROP TABLE "State";

-- DropTable
DROP TABLE "Zone";

-- CreateTable
CREATE TABLE "country" (
    "country_id" SERIAL NOT NULL,
    "country_name" VARCHAR(100) NOT NULL,

    CONSTRAINT "country_pkey" PRIMARY KEY ("country_id")
);

-- CreateTable
CREATE TABLE "state" (
    "state_id" SERIAL NOT NULL,
    "state_name" VARCHAR(100) NOT NULL,
    "country_id" INTEGER,

    CONSTRAINT "state_pkey" PRIMARY KEY ("state_id")
);

-- CreateTable
CREATE TABLE "district" (
    "district_id" SERIAL NOT NULL,
    "district_name" VARCHAR(100) NOT NULL,
    "state_id" INTEGER,

    CONSTRAINT "district_pkey" PRIMARY KEY ("district_id")
);

-- CreateTable
CREATE TABLE "city" (
    "city_id" SERIAL NOT NULL,
    "city_name" VARCHAR(100) NOT NULL,
    "district_id" INTEGER,

    CONSTRAINT "city_pkey" PRIMARY KEY ("city_id")
);

-- CreateTable
CREATE TABLE "zone" (
    "zone_id" SERIAL NOT NULL,
    "zone_name" VARCHAR(100) NOT NULL,
    "city_id" INTEGER,

    CONSTRAINT "zone_pkey" PRIMARY KEY ("zone_id")
);

-- CreateTable
CREATE TABLE "area" (
    "area_id" SERIAL NOT NULL,
    "area_name" VARCHAR(100) NOT NULL,
    "zone_id" INTEGER,

    CONSTRAINT "area_pkey" PRIMARY KEY ("area_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_employeeCode_key" ON "User"("employeeCode");

-- AddForeignKey
ALTER TABLE "state" ADD CONSTRAINT "state_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "country"("country_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "district" ADD CONSTRAINT "district_state_id_fkey" FOREIGN KEY ("state_id") REFERENCES "state"("state_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "city" ADD CONSTRAINT "city_district_id_fkey" FOREIGN KEY ("district_id") REFERENCES "district"("district_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "zone" ADD CONSTRAINT "zone_city_id_fkey" FOREIGN KEY ("city_id") REFERENCES "city"("city_id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "area" ADD CONSTRAINT "area_zone_id_fkey" FOREIGN KEY ("zone_id") REFERENCES "zone"("zone_id") ON DELETE CASCADE ON UPDATE NO ACTION;
