-- MySQL dump 10.13  Distrib 8.0.40, for Win64 (x86_64)
--
-- Host: gateway01.ap-southeast-1.prod.aws.tidbcloud.com    Database: test
-- ------------------------------------------------------
-- Server version	8.0.11-TiDB-v7.5.6-serverless

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Account`
--

DROP TABLE IF EXISTS `Account`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Account` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `accountCode` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `businessName` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `businessType` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `businessSize` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `personName` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contactNumber` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dateOfBirth` datetime(3) DEFAULT NULL,
  `customerStage` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `funnelStage` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `gstNumber` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `panCard` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ownerImage` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `shopImage` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `pincode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `country` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `district` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `area` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `areaId` int DEFAULT NULL,
  `assignedToId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `assignedDays` json DEFAULT NULL,
  `createdById` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvedById` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvedAt` datetime(3) DEFAULT NULL,
  `isApproved` tinyint(1) NOT NULL DEFAULT '0',
  `verificationNotes` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `rejectionNotes` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  UNIQUE KEY `Account_accountCode_key` (`accountCode`),
  KEY `Account_pincode_idx` (`pincode`),
  KEY `Account_isActive_idx` (`isActive`),
  KEY `Account_customerStage_idx` (`customerStage`),
  KEY `Account_createdAt_idx` (`createdAt`),
  KEY `Account_businessType_idx` (`businessType`),
  KEY `Account_businessSize_idx` (`businessSize`),
  KEY `Account_approvedById_fkey` (`approvedById`),
  KEY `Account_areaId_fkey` (`areaId`),
  KEY `Account_assignedToId_fkey` (`assignedToId`),
  KEY `Account_createdById_fkey` (`createdById`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `Account_approvedById_fkey` FOREIGN KEY (`approvedById`) REFERENCES `user_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `Account_areaId_fkey` FOREIGN KEY (`areaId`) REFERENCES `Area` (`area_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `Account_assignedToId_fkey` FOREIGN KEY (`assignedToId`) REFERENCES `user_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `Account_createdById_fkey` FOREIGN KEY (`createdById`) REFERENCES `user_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Area`
--

DROP TABLE IF EXISTS `Area`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Area` (
  `area_id` int NOT NULL AUTO_INCREMENT,
  `area_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `zone_id` int NOT NULL,
  PRIMARY KEY (`area_id`) /*T![clustered_index] CLUSTERED */,
  KEY `Area_zone_id_fkey` (`zone_id`),
  CONSTRAINT `Area_zone_id_fkey` FOREIGN KEY (`zone_id`) REFERENCES `Zone` (`zone_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `AreaAssignment`
--

DROP TABLE IF EXISTS `AreaAssignment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `AreaAssignment` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `salesmanId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pinCode` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `country` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `state` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `district` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `city` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `areas` json DEFAULT NULL,
  `businessTypes` json DEFAULT NULL,
  `assignedDate` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `totalBusinesses` int NOT NULL DEFAULT '0',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `AreaAssignment_salesmanId_idx` (`salesmanId`),
  KEY `AreaAssignment_pinCode_idx` (`pinCode`),
  KEY `AreaAssignment_city_district_idx` (`city`,`district`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `AreaAssignment_salesmanId_fkey` FOREIGN KEY (`salesmanId`) REFERENCES `user_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Attendance`
--

DROP TABLE IF EXISTS `Attendance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Attendance` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeName` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `date` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `punchInTime` datetime(3) NOT NULL,
  `punchInLatitude` double NOT NULL,
  `punchInLongitude` double NOT NULL,
  `punchInPhoto` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `punchInAddress` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bikeKmStart` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `punchOutTime` datetime(3) DEFAULT NULL,
  `punchOutLatitude` double DEFAULT NULL,
  `punchOutLongitude` double DEFAULT NULL,
  `punchOutPhoto` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `punchOutAddress` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bikeKmEnd` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `totalWorkHours` double DEFAULT NULL,
  `totalDistanceKm` double DEFAULT NULL,
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active',
  `isLatePunchIn` tinyint(1) NOT NULL DEFAULT '0',
  `lateApprovalId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvalCode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `isEarlyPunchOut` tinyint(1) NOT NULL DEFAULT '0',
  `earlyPunchOutApprovalId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `earlyPunchOutCode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `Attendance_employeeId_idx` (`employeeId`),
  KEY `Attendance_date_idx` (`date`),
  KEY `Attendance_status_idx` (`status`),
  KEY `Attendance_punchInTime_idx` (`punchInTime`),
  KEY `Attendance_isLatePunchIn_idx` (`isLatePunchIn`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `BeatCompletion`
--

DROP TABLE IF EXISTS `BeatCompletion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `BeatCompletion` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dailyBeatId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `salesmanId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `areaName` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `accountsVisited` int NOT NULL DEFAULT '0',
  `completedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `notes` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `isVerified` tinyint(1) NOT NULL DEFAULT '0',
  `verifiedBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `verifiedAt` datetime(3) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `BeatCompletion_dailyBeatId_idx` (`dailyBeatId`),
  KEY `BeatCompletion_salesmanId_idx` (`salesmanId`),
  KEY `BeatCompletion_completedAt_idx` (`completedAt`),
  KEY `BeatCompletion_areaName_idx` (`areaName`),
  KEY `BeatCompletion_verifiedBy_fkey` (`verifiedBy`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `BeatCompletion_dailyBeatId_fkey` FOREIGN KEY (`dailyBeatId`) REFERENCES `DailyBeatPlan` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `BeatCompletion_salesmanId_fkey` FOREIGN KEY (`salesmanId`) REFERENCES `user_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `BeatCompletion_verifiedBy_fkey` FOREIGN KEY (`verifiedBy`) REFERENCES `user_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `City`
--

DROP TABLE IF EXISTS `City`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `City` (
  `city_id` int NOT NULL AUTO_INCREMENT,
  `city_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `district_id` int NOT NULL,
  PRIMARY KEY (`city_id`) /*T![clustered_index] CLUSTERED */,
  KEY `City_district_id_fkey` (`district_id`),
  CONSTRAINT `City_district_id_fkey` FOREIGN KEY (`district_id`) REFERENCES `District` (`district_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Country`
--

DROP TABLE IF EXISTS `Country`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Country` (
  `country_id` int NOT NULL AUTO_INCREMENT,
  `country_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`country_id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `DailyBeatPlan`
--

DROP TABLE IF EXISTS `DailyBeatPlan`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DailyBeatPlan` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `weeklyBeatId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dayOfWeek` int NOT NULL,
  `dayDate` datetime(3) NOT NULL,
  `assignedAreas` json DEFAULT NULL,
  `plannedVisits` int NOT NULL DEFAULT '0',
  `actualVisits` int NOT NULL DEFAULT '0',
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PLANNED',
  `completedAt` datetime(3) DEFAULT NULL,
  `carriedFromDate` datetime(3) DEFAULT NULL,
  `carriedToDate` datetime(3) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `DailyBeatPlan_weeklyBeatId_idx` (`weeklyBeatId`),
  KEY `DailyBeatPlan_dayOfWeek_idx` (`dayOfWeek`),
  KEY `DailyBeatPlan_dayDate_idx` (`dayDate`),
  KEY `DailyBeatPlan_status_idx` (`status`),
  UNIQUE KEY `DailyBeatPlan_weeklyBeatId_dayOfWeek_key` (`weeklyBeatId`,`dayOfWeek`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `DailyBeatPlan_weeklyBeatId_fkey` FOREIGN KEY (`weeklyBeatId`) REFERENCES `WeeklyBeatPlan` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `District`
--

DROP TABLE IF EXISTS `District`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `District` (
  `district_id` int NOT NULL AUTO_INCREMENT,
  `district_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `region_id` int NOT NULL,
  PRIMARY KEY (`district_id`) /*T![clustered_index] CLUSTERED */,
  KEY `District_region_id_fkey` (`region_id`),
  CONSTRAINT `District_region_id_fkey` FOREIGN KEY (`region_id`) REFERENCES `Region` (`region_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `EarlyPunchOutApproval`
--

DROP TABLE IF EXISTS `EarlyPunchOutApproval`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `EarlyPunchOutApproval` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeName` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `attendanceId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `requestDate` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `punchOutDate` datetime(3) NOT NULL,
  `reason` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `approvedBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvedAt` datetime(3) DEFAULT NULL,
  `adminRemarks` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvalCode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `codeExpiresAt` datetime(3) DEFAULT NULL,
  `codeUsed` tinyint(1) NOT NULL DEFAULT '0',
  `codeUsedAt` datetime(3) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `EarlyPunchOutApproval_employeeId_idx` (`employeeId`),
  KEY `EarlyPunchOutApproval_attendanceId_idx` (`attendanceId`),
  KEY `EarlyPunchOutApproval_status_idx` (`status`),
  KEY `EarlyPunchOutApproval_requestDate_idx` (`requestDate`),
  KEY `EarlyPunchOutApproval_approvalCode_idx` (`approvalCode`),
  KEY `EarlyPunchOutApproval_approvedBy_fkey` (`approvedBy`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `EarlyPunchOutApproval_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `user_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `EarlyPunchOutApproval_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `user_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `EmployeeArea`
--

DROP TABLE IF EXISTS `EmployeeArea`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `EmployeeArea` (
  `area_id` int DEFAULT NULL,
  `city_id` int DEFAULT NULL,
  `country_id` int DEFAULT NULL,
  `district_id` int DEFAULT NULL,
  `employeeId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `region_id` int DEFAULT NULL,
  `state_id` int DEFAULT NULL,
  `zone_id` int DEFAULT NULL,
  `id` int NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `EmployeeArea_employeeId_key` (`employeeId`),
  KEY `EmployeeArea_area_id_fkey` (`area_id`),
  KEY `EmployeeArea_city_id_fkey` (`city_id`),
  KEY `EmployeeArea_country_id_fkey` (`country_id`),
  KEY `EmployeeArea_district_id_fkey` (`district_id`),
  KEY `EmployeeArea_region_id_fkey` (`region_id`),
  KEY `EmployeeArea_state_id_fkey` (`state_id`),
  KEY `EmployeeArea_zone_id_fkey` (`zone_id`),
  CONSTRAINT `EmployeeArea_area_id_fkey` FOREIGN KEY (`area_id`) REFERENCES `Area` (`area_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `EmployeeArea_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `City` (`city_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `EmployeeArea_country_id_fkey` FOREIGN KEY (`country_id`) REFERENCES `Country` (`country_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `EmployeeArea_district_id_fkey` FOREIGN KEY (`district_id`) REFERENCES `District` (`district_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `EmployeeArea_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `user_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `EmployeeArea_region_id_fkey` FOREIGN KEY (`region_id`) REFERENCES `Region` (`region_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `EmployeeArea_state_id_fkey` FOREIGN KEY (`state_id`) REFERENCES `State` (`state_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `EmployeeArea_zone_id_fkey` FOREIGN KEY (`zone_id`) REFERENCES `Zone` (`zone_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Expense`
--

DROP TABLE IF EXISTS `Expense`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Expense` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expenseType` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `amount` double NOT NULL,
  `expenseDate` datetime(3) NOT NULL,
  `description` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `billNumber` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `attachmentUrl` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Pending',
  `approvedBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvedAt` datetime(3) DEFAULT NULL,
  `rejectionReason` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `paidAt` datetime(3) DEFAULT NULL,
  `remarks` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `Expense_employeeId_idx` (`employeeId`),
  KEY `Expense_status_idx` (`status`),
  KEY `Expense_expenseDate_idx` (`expenseDate`),
  KEY `Expense_expenseType_idx` (`expenseType`),
  KEY `Expense_approvedBy_fkey` (`approvedBy`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `Expense_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `user_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `Expense_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `user_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `LatePunchApproval`
--

DROP TABLE IF EXISTS `LatePunchApproval`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `LatePunchApproval` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeName` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `requestDate` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `punchInDate` datetime(3) NOT NULL,
  `reason` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `approvedBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvedAt` datetime(3) DEFAULT NULL,
  `adminRemarks` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvalCode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `codeExpiresAt` datetime(3) DEFAULT NULL,
  `codeUsed` tinyint(1) NOT NULL DEFAULT '0',
  `codeUsedAt` datetime(3) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `LatePunchApproval_employeeId_idx` (`employeeId`),
  KEY `LatePunchApproval_status_idx` (`status`),
  KEY `LatePunchApproval_requestDate_idx` (`requestDate`),
  KEY `LatePunchApproval_approvalCode_idx` (`approvalCode`),
  KEY `LatePunchApproval_approvedBy_fkey` (`approvedBy`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `LatePunchApproval_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `user_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `LatePunchApproval_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `user_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Leave`
--

DROP TABLE IF EXISTS `Leave`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Leave` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeName` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `leaveType` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `startDate` datetime(3) NOT NULL,
  `endDate` datetime(3) NOT NULL,
  `numberOfDays` int NOT NULL,
  `reason` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `requestedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `approvedBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvedAt` datetime(3) DEFAULT NULL,
  `rejectionReason` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `adminRemarks` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `Leave_employeeId_idx` (`employeeId`),
  KEY `Leave_status_idx` (`status`),
  KEY `Leave_startDate_idx` (`startDate`),
  KEY `Leave_endDate_idx` (`endDate`),
  KEY `Leave_leaveType_idx` (`leaveType`),
  KEY `Leave_requestedAt_idx` (`requestedAt`),
  KEY `Leave_approvedBy_fkey` (`approvedBy`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `Leave_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `user_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `Leave_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `user_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `LeaveBalance`
--

DROP TABLE IF EXISTS `LeaveBalance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `LeaveBalance` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `year` int NOT NULL,
  `sickLeaves` int NOT NULL DEFAULT '12',
  `casualLeaves` int NOT NULL DEFAULT '10',
  `earnedLeaves` int NOT NULL DEFAULT '20',
  `usedSickLeaves` int NOT NULL DEFAULT '0',
  `usedCasualLeaves` int NOT NULL DEFAULT '0',
  `usedEarnedLeaves` int NOT NULL DEFAULT '0',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  UNIQUE KEY `LeaveBalance_employeeId_key` (`employeeId`),
  KEY `LeaveBalance_employeeId_idx` (`employeeId`),
  KEY `LeaveBalance_year_idx` (`year`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `LeaveBalance_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `user_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Notification`
--

DROP TABLE IF EXISTS `Notification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Notification` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `priority` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'normal',
  `targetRole` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `targetUserId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `data` json DEFAULT NULL,
  `isRead` tinyint(1) NOT NULL DEFAULT '0',
  `readAt` datetime(3) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `Notification_targetRole_idx` (`targetRole`),
  KEY `Notification_targetUserId_idx` (`targetUserId`),
  KEY `Notification_type_idx` (`type`),
  KEY `Notification_isRead_idx` (`isRead`),
  KEY `Notification_createdAt_idx` (`createdAt`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `Notification_targetUserId_fkey` FOREIGN KEY (`targetUserId`) REFERENCES `user_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Region`
--

DROP TABLE IF EXISTS `Region`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Region` (
  `region_id` int NOT NULL AUTO_INCREMENT,
  `region_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `state_id` int NOT NULL,
  PRIMARY KEY (`region_id`) /*T![clustered_index] CLUSTERED */,
  KEY `Region_state_id_fkey` (`state_id`),
  CONSTRAINT `Region_state_id_fkey` FOREIGN KEY (`state_id`) REFERENCES `State` (`state_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Role`
--

DROP TABLE IF EXISTS `Role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Role` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SalaryInformation`
--

DROP TABLE IF EXISTS `SalaryInformation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `SalaryInformation` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `basicSalary` double NOT NULL,
  `hra` double DEFAULT '0',
  `travelAllowance` double DEFAULT '0',
  `dailyAllowance` double DEFAULT '0',
  `medicalAllowance` double DEFAULT '0',
  `specialAllowance` double DEFAULT '0',
  `otherAllowances` double DEFAULT '0',
  `providentFund` double DEFAULT '0',
  `professionalTax` double DEFAULT '0',
  `incomeTax` double DEFAULT '0',
  `otherDeductions` double DEFAULT '0',
  `effectiveFrom` datetime(3) NOT NULL,
  `effectiveTo` datetime(3) DEFAULT NULL,
  `currency` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'INR',
  `paymentFrequency` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Monthly',
  `bankName` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `accountNumber` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ifscCode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `panNumber` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  UNIQUE KEY `SalaryInformation_employeeId_key` (`employeeId`),
  KEY `SalaryInformation_employeeId_idx` (`employeeId`),
  KEY `SalaryInformation_effectiveFrom_idx` (`effectiveFrom`),
  KEY `SalaryInformation_isActive_idx` (`isActive`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `SalaryInformation_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `user_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SalesmanTrackingPoint`
--

DROP TABLE IF EXISTS `SalesmanTrackingPoint`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `SalesmanTrackingPoint` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `clientPointId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `employeeId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `attendanceId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `latitude` double NOT NULL,
  `longitude` double NOT NULL,
  `speed` double DEFAULT NULL,
  `accuracy` double DEFAULT NULL,
  `recordedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE KEY `SalesmanTrackingPoint_clientPointId_key` (`clientPointId`),
  KEY `SalesmanTrackingPoint_employeeId_idx` (`employeeId`),
  KEY `SalesmanTrackingPoint_attendanceId_idx` (`attendanceId`),
  KEY `SalesmanTrackingPoint_recordedAt_idx` (`recordedAt`),
  KEY `SalesmanTrackingPoint_employeeId_attendanceId_recordedAt_idx` (`employeeId`,`attendanceId`,`recordedAt`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `SalesmanTrackingPoint_attendanceId_fkey` FOREIGN KEY (`attendanceId`) REFERENCES `Attendance` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `SalesmanTrackingPoint_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `user_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Shop`
--

DROP TABLE IF EXISTS `Shop`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Shop` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `placeId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `name` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `businessType` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `address` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pincode` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `area` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `country` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `phoneNumber` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `rating` double DEFAULT NULL,
  `stage` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'new',
  `assignedTo` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notes` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `lastContactDate` datetime(3) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  UNIQUE KEY `Shop_placeId_key` (`placeId`),
  KEY `Shop_pincode_idx` (`pincode`),
  KEY `Shop_businessType_idx` (`businessType`),
  KEY `Shop_stage_idx` (`stage`),
  KEY `Shop_assignedTo_idx` (`assignedTo`),
  KEY `Shop_area_idx` (`area`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `State`
--

DROP TABLE IF EXISTS `State`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `State` (
  `state_id` int NOT NULL AUTO_INCREMENT,
  `state_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `country_id` int NOT NULL,
  PRIMARY KEY (`state_id`) /*T![clustered_index] CLUSTERED */,
  KEY `State_country_id_fkey` (`country_id`),
  CONSTRAINT `State_country_id_fkey` FOREIGN KEY (`country_id`) REFERENCES `Country` (`country_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `TaskAssignment`
--

DROP TABLE IF EXISTS `TaskAssignment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `TaskAssignment` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `salesmanId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `salesmanName` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pincode` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `country` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `district` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `areas` json DEFAULT NULL,
  `businessTypes` json DEFAULT NULL,
  `totalBusinesses` int DEFAULT '0',
  `assignedDate` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `TaskAssignment_salesmanId_idx` (`salesmanId`),
  KEY `TaskAssignment_pincode_idx` (`pincode`),
  KEY `TaskAssignment_assignedDate_idx` (`assignedDate`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `TelecallerCallLog`
--

DROP TABLE IF EXISTS `TelecallerCallLog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `TelecallerCallLog` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `accountId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `telecallerId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `calledAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `durationSec` int DEFAULT NULL,
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notes` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `recordingUrl` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nextFollowupAt` datetime(3) DEFAULT NULL,
  `followupNotes` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  KEY `TelecallerCallLog_telecallerId_calledAt_idx` (`telecallerId`,`calledAt`),
  KEY `TelecallerCallLog_accountId_calledAt_idx` (`accountId`,`calledAt`),
  KEY `TelecallerCallLog_nextFollowupAt_idx` (`nextFollowupAt`),
  KEY `TelecallerCallLog_status_idx` (`status`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `TelecallerCallLog_accountId_fkey` FOREIGN KEY (`accountId`) REFERENCES `Account` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `TelecallerCallLog_telecallerId_fkey` FOREIGN KEY (`telecallerId`) REFERENCES `user_crm` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `TelecallerPincodeAssignment`
--

DROP TABLE IF EXISTS `TelecallerPincodeAssignment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `TelecallerPincodeAssignment` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `telecallerId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pincode` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dayOfWeek` int NOT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `TelecallerPincodeAssignment_telecallerId_idx` (`telecallerId`),
  KEY `TelecallerPincodeAssignment_pincode_dayOfWeek_idx` (`pincode`,`dayOfWeek`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `TelecallerPincodeAssignment_telecallerId_fkey` FOREIGN KEY (`telecallerId`) REFERENCES `user_crm` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `WeeklyAccountAssignment`
--

DROP TABLE IF EXISTS `WeeklyAccountAssignment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `WeeklyAccountAssignment` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `accountId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `salesmanId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pincode` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `weekStartDate` datetime(3) NOT NULL,
  `assignedDays` json NOT NULL,
  `visitFrequency` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `isManualOverride` tinyint(1) NOT NULL DEFAULT '0',
  `sequenceNo` int NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  `overriddenAt` datetime(3) DEFAULT NULL,
  `overrideBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `overrideReason` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `plannedAt` datetime(3) DEFAULT NULL,
  `plannedBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `recurrenceAfterDays` int DEFAULT NULL,
  `recurrenceStartDate` datetime(3) DEFAULT NULL,
  `recurrenceNextDate` datetime(3) DEFAULT NULL,
  KEY `WeeklyAccountAssignment_salesmanId_weekStartDate_idx` (`salesmanId`,`weekStartDate`),
  KEY `WeeklyAccountAssignment_pincode_weekStartDate_idx` (`pincode`,`weekStartDate`),
  KEY `WeeklyAccountAssignment_salesmanId_pincode_weekStartDate_seq_idx` (`salesmanId`,`pincode`,`weekStartDate`,`sequenceNo`),
  UNIQUE KEY `WeeklyAccountAssignment_accountId_weekStartDate_key` (`accountId`,`weekStartDate`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `WeeklyAccountAssignment_salesmanId_recurrenceNextDate_idx` (`salesmanId`,`recurrenceNextDate`),
  CONSTRAINT `WeeklyAccountAssignment_accountId_fkey` FOREIGN KEY (`accountId`) REFERENCES `Account` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `WeeklyBeatPlan`
--

DROP TABLE IF EXISTS `WeeklyBeatPlan`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `WeeklyBeatPlan` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `salesmanId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `salesmanName` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `weekStartDate` datetime(3) NOT NULL,
  `weekEndDate` datetime(3) NOT NULL,
  `pincodes` json DEFAULT NULL,
  `totalAreas` int NOT NULL DEFAULT '0',
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `generatedBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvedBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvedAt` datetime(3) DEFAULT NULL,
  `lockedBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `lockedAt` datetime(3) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `WeeklyBeatPlan_salesmanId_idx` (`salesmanId`),
  KEY `WeeklyBeatPlan_weekStartDate_idx` (`weekStartDate`),
  KEY `WeeklyBeatPlan_status_idx` (`status`),
  KEY `WeeklyBeatPlan_generatedBy_idx` (`generatedBy`),
  KEY `WeeklyBeatPlan_approvedBy_fkey` (`approvedBy`),
  KEY `WeeklyBeatPlan_lockedBy_fkey` (`lockedBy`),
  UNIQUE KEY `WeeklyBeatPlan_salesmanId_weekStartDate_key` (`salesmanId`,`weekStartDate`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `WeeklyBeatPlan_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `user_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `WeeklyBeatPlan_generatedBy_fkey` FOREIGN KEY (`generatedBy`) REFERENCES `user_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `WeeklyBeatPlan_lockedBy_fkey` FOREIGN KEY (`lockedBy`) REFERENCES `user_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `WeeklyBeatPlan_salesmanId_fkey` FOREIGN KEY (`salesmanId`) REFERENCES `user_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Zone`
--

DROP TABLE IF EXISTS `Zone`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Zone` (
  `zone_id` int NOT NULL AUTO_INCREMENT,
  `zone_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `city_id` int NOT NULL,
  PRIMARY KEY (`zone_id`) /*T![clustered_index] CLUSTERED */,
  KEY `Zone_city_id_fkey` (`city_id`),
  CONSTRAINT `Zone_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `City` (`city_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `_prisma_migrations`
--

DROP TABLE IF EXISTS `_prisma_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `_prisma_migrations` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `checksum` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `finished_at` datetime(3) DEFAULT NULL,
  `migration_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `logs` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `rolled_back_at` datetime(3) DEFAULT NULL,
  `started_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `applied_steps_count` int unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `department_crm`
--

DROP TABLE IF EXISTS `department_crm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `department_crm` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE KEY `Department_name_key` (`name`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_crm`
--

DROP TABLE IF EXISTS `user_crm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_crm` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeCode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `name` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contactNumber` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `alternativeNumber` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `roleId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `roles` json DEFAULT NULL,
  `departmentId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `otp` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `otpExpiry` datetime(3) DEFAULT NULL,
  `lastLogin` datetime(3) DEFAULT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  `dateOfBirth` datetime(3) DEFAULT NULL,
  `gender` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `image` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `preferredLanguages` json DEFAULT NULL,
  `address` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pincode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `country` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `district` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `area` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `aadharCard` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `panCard` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notes` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `workStartTime` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT '09:00:00',
  `workEndTime` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT '18:00:00',
  `latePunchInGraceMinutes` int DEFAULT '45',
  `earlyPunchOutGraceMinutes` int DEFAULT '30',
  UNIQUE KEY `User_employeeCode_key` (`employeeCode`),
  UNIQUE KEY `User_email_key` (`email`),
  UNIQUE KEY `User_contactNumber_key` (`contactNumber`),
  KEY `User_departmentId_fkey` (`departmentId`),
  KEY `User_roleId_fkey` (`roleId`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `User_departmentId_fkey` FOREIGN KEY (`departmentId`) REFERENCES `department_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `User_roleId_fkey` FOREIGN KEY (`roleId`) REFERENCES `Role` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-07 15:25:41

