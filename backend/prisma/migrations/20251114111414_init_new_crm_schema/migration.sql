/*
  Warnings:

  - The `areaId` column on the `Account` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The primary key for the `EmployeeArea` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `areaId` on the `EmployeeArea` table. All the data in the column will be lost.
  - You are about to drop the column `userId` on the `EmployeeArea` table. All the data in the column will be lost.
  - The `id` column on the `EmployeeArea` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - You are about to drop the column `code` on the `Role` table. All the data in the column will be lost.
  - You are about to drop the column `level` on the `Role` table. All the data in the column will be lost.
  - You are about to drop the column `reportsTo` on the `Role` table. All the data in the column will be lost.
  - You are about to drop the column `inchargeCode` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `inchargeName` on the `User` table. All the data in the column will be lost.
  - You are about to drop the `FunctionalRole` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `area` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `city` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `country` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `district` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `state` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `zone` table. If the table is not empty, all the data it contains will be lost.
  - A unique constraint covering the columns `[employeeId]` on the table `EmployeeArea` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `employeeId` to the `EmployeeArea` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE "EmployeeArea" DROP CONSTRAINT "EmployeeArea_userId_fkey";

-- DropForeignKey
ALTER TABLE "FunctionalRole" DROP CONSTRAINT "FunctionalRole_departmentId_fkey";

-- DropForeignKey
ALTER TABLE "FunctionalRole" DROP CONSTRAINT "FunctionalRole_reportsToId_fkey";

-- DropForeignKey
ALTER TABLE "Role" DROP CONSTRAINT "Role_reportsTo_fkey";

-- DropForeignKey
ALTER TABLE "User" DROP CONSTRAINT "User_functionalRoleId_fkey";

-- DropForeignKey
ALTER TABLE "area" DROP CONSTRAINT "area_zone_id_fkey";

-- DropForeignKey
ALTER TABLE "city" DROP CONSTRAINT "city_district_id_fkey";

-- DropForeignKey
ALTER TABLE "district" DROP CONSTRAINT "district_state_id_fkey";

-- DropForeignKey
ALTER TABLE "state" DROP CONSTRAINT "state_country_id_fkey";

-- DropForeignKey
ALTER TABLE "zone" DROP CONSTRAINT "zone_city_id_fkey";

-- DropIndex
DROP INDEX "EmployeeArea_userId_areaId_key";

-- DropIndex
DROP INDEX "Role_code_key";

-- AlterTable
ALTER TABLE "Account" DROP COLUMN "areaId",
ADD COLUMN     "areaId" INTEGER;

-- AlterTable
ALTER TABLE "EmployeeArea" DROP CONSTRAINT "EmployeeArea_pkey",
DROP COLUMN "areaId",
DROP COLUMN "userId",
ADD COLUMN     "area_id" INTEGER,
ADD COLUMN     "city_id" INTEGER,
ADD COLUMN     "country_id" INTEGER,
ADD COLUMN     "district_id" INTEGER,
ADD COLUMN     "employeeId" TEXT NOT NULL,
ADD COLUMN     "latitude" DOUBLE PRECISION,
ADD COLUMN     "longitude" DOUBLE PRECISION,
ADD COLUMN     "region_id" INTEGER,
ADD COLUMN     "state_id" INTEGER,
ADD COLUMN     "zone_id" INTEGER,
DROP COLUMN "id",
ADD COLUMN     "id" SERIAL NOT NULL,
ADD CONSTRAINT "EmployeeArea_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "Role" DROP COLUMN "code",
DROP COLUMN "level",
DROP COLUMN "reportsTo";

-- AlterTable
ALTER TABLE "User" DROP COLUMN "inchargeCode",
DROP COLUMN "inchargeName";

-- DropTable
DROP TABLE "FunctionalRole";

-- DropTable
DROP TABLE "area";

-- DropTable
DROP TABLE "city";

-- DropTable
DROP TABLE "country";

-- DropTable
DROP TABLE "district";

-- DropTable
DROP TABLE "state";

-- DropTable
DROP TABLE "zone";

-- CreateTable
CREATE TABLE "Country" (
    "country_id" SERIAL NOT NULL,
    "country_name" VARCHAR(100) NOT NULL,

    CONSTRAINT "Country_pkey" PRIMARY KEY ("country_id")
);

-- CreateTable
CREATE TABLE "State" (
    "state_id" SERIAL NOT NULL,
    "state_name" VARCHAR(100) NOT NULL,
    "country_id" INTEGER NOT NULL,

    CONSTRAINT "State_pkey" PRIMARY KEY ("state_id")
);

-- CreateTable
CREATE TABLE "Region" (
    "region_id" SERIAL NOT NULL,
    "region_name" VARCHAR(100) NOT NULL,
    "state_id" INTEGER NOT NULL,

    CONSTRAINT "Region_pkey" PRIMARY KEY ("region_id")
);

-- CreateTable
CREATE TABLE "District" (
    "district_id" SERIAL NOT NULL,
    "district_name" VARCHAR(100) NOT NULL,
    "region_id" INTEGER NOT NULL,

    CONSTRAINT "District_pkey" PRIMARY KEY ("district_id")
);

-- CreateTable
CREATE TABLE "City" (
    "city_id" SERIAL NOT NULL,
    "city_name" VARCHAR(100) NOT NULL,
    "district_id" INTEGER NOT NULL,

    CONSTRAINT "City_pkey" PRIMARY KEY ("city_id")
);

-- CreateTable
CREATE TABLE "Zone" (
    "zone_id" SERIAL NOT NULL,
    "zone_name" VARCHAR(100) NOT NULL,
    "city_id" INTEGER NOT NULL,

    CONSTRAINT "Zone_pkey" PRIMARY KEY ("zone_id")
);

-- CreateTable
CREATE TABLE "AreaType" (
    "type_id" SERIAL NOT NULL,
    "type_name" TEXT NOT NULL,

    CONSTRAINT "AreaType_pkey" PRIMARY KEY ("type_id")
);

-- CreateTable
CREATE TABLE "Area" (
    "area_id" SERIAL NOT NULL,
    "area_name" VARCHAR(100) NOT NULL,
    "zone_id" INTEGER NOT NULL,
    "type_id" INTEGER NOT NULL,

    CONSTRAINT "Area_pkey" PRIMARY KEY ("area_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "AreaType_type_name_key" ON "AreaType"("type_name");

-- CreateIndex
CREATE UNIQUE INDEX "EmployeeArea_employeeId_key" ON "EmployeeArea"("employeeId");

-- AddForeignKey
ALTER TABLE "State" ADD CONSTRAINT "State_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "Country"("country_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Region" ADD CONSTRAINT "Region_state_id_fkey" FOREIGN KEY ("state_id") REFERENCES "State"("state_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "District" ADD CONSTRAINT "District_region_id_fkey" FOREIGN KEY ("region_id") REFERENCES "Region"("region_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "City" ADD CONSTRAINT "City_district_id_fkey" FOREIGN KEY ("district_id") REFERENCES "District"("district_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Zone" ADD CONSTRAINT "Zone_city_id_fkey" FOREIGN KEY ("city_id") REFERENCES "City"("city_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Area" ADD CONSTRAINT "Area_zone_id_fkey" FOREIGN KEY ("zone_id") REFERENCES "Zone"("zone_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Area" ADD CONSTRAINT "Area_type_id_fkey" FOREIGN KEY ("type_id") REFERENCES "AreaType"("type_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EmployeeArea" ADD CONSTRAINT "EmployeeArea_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EmployeeArea" ADD CONSTRAINT "EmployeeArea_country_id_fkey" FOREIGN KEY ("country_id") REFERENCES "Country"("country_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EmployeeArea" ADD CONSTRAINT "EmployeeArea_state_id_fkey" FOREIGN KEY ("state_id") REFERENCES "State"("state_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EmployeeArea" ADD CONSTRAINT "EmployeeArea_region_id_fkey" FOREIGN KEY ("region_id") REFERENCES "Region"("region_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EmployeeArea" ADD CONSTRAINT "EmployeeArea_district_id_fkey" FOREIGN KEY ("district_id") REFERENCES "District"("district_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EmployeeArea" ADD CONSTRAINT "EmployeeArea_city_id_fkey" FOREIGN KEY ("city_id") REFERENCES "City"("city_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EmployeeArea" ADD CONSTRAINT "EmployeeArea_zone_id_fkey" FOREIGN KEY ("zone_id") REFERENCES "Zone"("zone_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "EmployeeArea" ADD CONSTRAINT "EmployeeArea_area_id_fkey" FOREIGN KEY ("area_id") REFERENCES "Area"("area_id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Account" ADD CONSTRAINT "Account_areaId_fkey" FOREIGN KEY ("areaId") REFERENCES "Area"("area_id") ON DELETE SET NULL ON UPDATE CASCADE;
