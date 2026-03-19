-- CreateTable
CREATE TABLE `Country` (
    `country_id` INTEGER NOT NULL AUTO_INCREMENT,
    `country_name` VARCHAR(100) NOT NULL,

    PRIMARY KEY (`country_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `State` (
    `state_id` INTEGER NOT NULL AUTO_INCREMENT,
    `state_name` VARCHAR(100) NOT NULL,
    `country_id` INTEGER NOT NULL,

    INDEX `State_country_id_fkey`(`country_id`),
    PRIMARY KEY (`state_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Region` (
    `region_id` INTEGER NOT NULL AUTO_INCREMENT,
    `region_name` VARCHAR(100) NOT NULL,
    `state_id` INTEGER NOT NULL,

    INDEX `Region_state_id_fkey`(`state_id`),
    PRIMARY KEY (`region_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `District` (
    `district_id` INTEGER NOT NULL AUTO_INCREMENT,
    `district_name` VARCHAR(100) NOT NULL,
    `region_id` INTEGER NOT NULL,

    INDEX `District_region_id_fkey`(`region_id`),
    PRIMARY KEY (`district_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `City` (
    `city_id` INTEGER NOT NULL AUTO_INCREMENT,
    `city_name` VARCHAR(100) NOT NULL,
    `district_id` INTEGER NOT NULL,

    INDEX `City_district_id_fkey`(`district_id`),
    PRIMARY KEY (`city_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Zone` (
    `zone_id` INTEGER NOT NULL AUTO_INCREMENT,
    `zone_name` VARCHAR(100) NOT NULL,
    `city_id` INTEGER NOT NULL,

    INDEX `Zone_city_id_fkey`(`city_id`),
    PRIMARY KEY (`zone_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Area` (
    `area_id` INTEGER NOT NULL AUTO_INCREMENT,
    `area_name` VARCHAR(100) NOT NULL,
    `zone_id` INTEGER NOT NULL,

    INDEX `Area_zone_id_fkey`(`zone_id`),
    PRIMARY KEY (`area_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Department` (
    `id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `Department_name_key`(`name`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Role` (
    `id` VARCHAR(191) NOT NULL,
    `name` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `User` (
    `id` VARCHAR(191) NOT NULL,
    `employeeCode` VARCHAR(191) NULL,
    `name` VARCHAR(191) NULL,
    `email` VARCHAR(191) NULL,
    `contactNumber` VARCHAR(191) NOT NULL,
    `alternativeNumber` VARCHAR(191) NULL,
    `roleId` VARCHAR(191) NULL,
    `roles` JSON NULL,
    `departmentId` VARCHAR(191) NULL,
    `otp` VARCHAR(191) NULL,
    `otpExpiry` DATETIME(3) NULL,
    `lastLogin` DATETIME(3) NULL,
    `isActive` BOOLEAN NOT NULL DEFAULT true,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,
    `dateOfBirth` DATETIME(3) NULL,
    `gender` VARCHAR(191) NULL,
    `image` VARCHAR(191) NULL,
    `preferredLanguages` JSON NULL,
    `address` VARCHAR(191) NULL,
    `city` VARCHAR(191) NULL,
    `state` VARCHAR(191) NULL,
    `pincode` VARCHAR(191) NULL,
    `country` VARCHAR(191) NULL,
    `district` VARCHAR(191) NULL,
    `area` VARCHAR(191) NULL,
    `latitude` DOUBLE NULL,
    `longitude` DOUBLE NULL,
    `aadharCard` VARCHAR(191) NULL,
    `panCard` VARCHAR(191) NULL,
    `password` VARCHAR(191) NULL,
    `notes` VARCHAR(191) NULL,
    `workStartTime` VARCHAR(191) NULL DEFAULT '09:00:00',
    `workEndTime` VARCHAR(191) NULL DEFAULT '18:00:00',
    `latePunchInGraceMinutes` INTEGER NULL DEFAULT 45,
    `earlyPunchOutGraceMinutes` INTEGER NULL DEFAULT 30,

    UNIQUE INDEX `User_employeeCode_key`(`employeeCode`),
    UNIQUE INDEX `User_email_key`(`email`),
    UNIQUE INDEX `User_contactNumber_key`(`contactNumber`),
    INDEX `User_departmentId_fkey`(`departmentId`),
    INDEX `User_roleId_fkey`(`roleId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `EmployeeArea` (
    `area_id` INTEGER NULL,
    `city_id` INTEGER NULL,
    `country_id` INTEGER NULL,
    `district_id` INTEGER NULL,
    `employeeId` VARCHAR(191) NOT NULL,
    `latitude` DOUBLE NULL,
    `longitude` DOUBLE NULL,
    `region_id` INTEGER NULL,
    `state_id` INTEGER NULL,
    `zone_id` INTEGER NULL,
    `id` INTEGER NOT NULL AUTO_INCREMENT,

    UNIQUE INDEX `EmployeeArea_employeeId_key`(`employeeId`),
    INDEX `EmployeeArea_area_id_fkey`(`area_id`),
    INDEX `EmployeeArea_city_id_fkey`(`city_id`),
    INDEX `EmployeeArea_country_id_fkey`(`country_id`),
    INDEX `EmployeeArea_district_id_fkey`(`district_id`),
    INDEX `EmployeeArea_region_id_fkey`(`region_id`),
    INDEX `EmployeeArea_state_id_fkey`(`state_id`),
    INDEX `EmployeeArea_zone_id_fkey`(`zone_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Account` (
    `id` VARCHAR(191) NOT NULL,
    `accountCode` VARCHAR(191) NOT NULL,
    `businessName` VARCHAR(191) NULL,
    `businessType` VARCHAR(191) NULL,
    `businessSize` VARCHAR(191) NULL,
    `personName` VARCHAR(191) NOT NULL,
    `contactNumber` VARCHAR(191) NOT NULL,
    `dateOfBirth` DATETIME(3) NULL,
    `customerStage` VARCHAR(191) NULL,
    `funnelStage` VARCHAR(191) NULL,
    `gstNumber` VARCHAR(191) NULL,
    `panCard` VARCHAR(191) NULL,
    `ownerImage` VARCHAR(191) NULL,
    `shopImage` VARCHAR(191) NULL,
    `isActive` BOOLEAN NOT NULL DEFAULT true,
    `pincode` VARCHAR(191) NULL,
    `country` VARCHAR(191) NULL,
    `state` VARCHAR(191) NULL,
    `district` VARCHAR(191) NULL,
    `city` VARCHAR(191) NULL,
    `area` VARCHAR(191) NULL,
    `address` VARCHAR(191) NULL,
    `latitude` DOUBLE NULL,
    `longitude` DOUBLE NULL,
    `areaId` INTEGER NULL,
    `assignedToId` VARCHAR(191) NULL,
    `assignedDays` JSON NULL,
    `createdById` VARCHAR(191) NULL,
    `approvedById` VARCHAR(191) NULL,
    `approvedAt` DATETIME(3) NULL,
    `isApproved` BOOLEAN NOT NULL DEFAULT false,
    `verificationNotes` VARCHAR(191) NULL,
    `rejectionNotes` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `Account_accountCode_key`(`accountCode`),
    INDEX `Account_pincode_idx`(`pincode`),
    INDEX `Account_isActive_idx`(`isActive`),
    INDEX `Account_customerStage_idx`(`customerStage`),
    INDEX `Account_createdAt_idx`(`createdAt`),
    INDEX `Account_businessType_idx`(`businessType`),
    INDEX `Account_businessSize_idx`(`businessSize`),
    INDEX `Account_approvedById_fkey`(`approvedById`),
    INDEX `Account_areaId_fkey`(`areaId`),
    INDEX `Account_assignedToId_fkey`(`assignedToId`),
    INDEX `Account_createdById_fkey`(`createdById`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `WeeklyAccountAssignment` (
    `id` VARCHAR(191) NOT NULL,
    `accountId` VARCHAR(191) NOT NULL,
    `salesmanId` VARCHAR(191) NOT NULL,
    `pincode` VARCHAR(191) NOT NULL,
    `weekStartDate` DATETIME(3) NOT NULL,
    `assignedDays` JSON NOT NULL,
    `visitFrequency` VARCHAR(191) NULL,
    `isManualOverride` BOOLEAN NOT NULL DEFAULT false,
    `sequenceNo` INTEGER NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `WeeklyAccountAssignment_salesmanId_weekStartDate_idx`(`salesmanId`, `weekStartDate`),
    INDEX `WeeklyAccountAssignment_pincode_weekStartDate_idx`(`pincode`, `weekStartDate`),
    INDEX `WeeklyAccountAssignment_salesmanId_pincode_weekStartDate_seq_idx`(`salesmanId`, `pincode`, `weekStartDate`, `sequenceNo`),
    UNIQUE INDEX `WeeklyAccountAssignment_accountId_weekStartDate_key`(`accountId`, `weekStartDate`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `TelecallerCallLog` (
    `id` VARCHAR(191) NOT NULL,
    `accountId` VARCHAR(191) NOT NULL,
    `telecallerId` VARCHAR(191) NOT NULL,
    `calledAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `durationSec` INTEGER NULL,
    `status` VARCHAR(191) NOT NULL,
    `notes` VARCHAR(191) NULL,
    `recordingUrl` VARCHAR(191) NULL,
    `nextFollowupAt` DATETIME(3) NULL,
    `followupNotes` VARCHAR(191) NULL,

    INDEX `TelecallerCallLog_telecallerId_calledAt_idx`(`telecallerId`, `calledAt`),
    INDEX `TelecallerCallLog_accountId_calledAt_idx`(`accountId`, `calledAt`),
    INDEX `TelecallerCallLog_nextFollowupAt_idx`(`nextFollowupAt`),
    INDEX `TelecallerCallLog_status_idx`(`status`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `TelecallerPincodeAssignment` (
    `id` VARCHAR(191) NOT NULL,
    `telecallerId` VARCHAR(191) NOT NULL,
    `pincode` VARCHAR(191) NOT NULL,
    `dayOfWeek` INTEGER NOT NULL,
    `isActive` BOOLEAN NOT NULL DEFAULT true,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `TelecallerPincodeAssignment_telecallerId_idx`(`telecallerId`),
    INDEX `TelecallerPincodeAssignment_pincode_dayOfWeek_idx`(`pincode`, `dayOfWeek`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `SalaryInformation` (
    `id` VARCHAR(191) NOT NULL,
    `employeeId` VARCHAR(191) NOT NULL,
    `basicSalary` DOUBLE NOT NULL,
    `hra` DOUBLE NULL DEFAULT 0,
    `travelAllowance` DOUBLE NULL DEFAULT 0,
    `dailyAllowance` DOUBLE NULL DEFAULT 0,
    `medicalAllowance` DOUBLE NULL DEFAULT 0,
    `specialAllowance` DOUBLE NULL DEFAULT 0,
    `otherAllowances` DOUBLE NULL DEFAULT 0,
    `providentFund` DOUBLE NULL DEFAULT 0,
    `professionalTax` DOUBLE NULL DEFAULT 0,
    `incomeTax` DOUBLE NULL DEFAULT 0,
    `otherDeductions` DOUBLE NULL DEFAULT 0,
    `effectiveFrom` DATETIME(3) NOT NULL,
    `effectiveTo` DATETIME(3) NULL,
    `currency` VARCHAR(191) NOT NULL DEFAULT 'INR',
    `paymentFrequency` VARCHAR(191) NOT NULL DEFAULT 'Monthly',
    `bankName` VARCHAR(191) NULL,
    `accountNumber` VARCHAR(191) NULL,
    `ifscCode` VARCHAR(191) NULL,
    `panNumber` VARCHAR(191) NULL,
    `remarks` VARCHAR(191) NULL,
    `isActive` BOOLEAN NOT NULL DEFAULT true,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `SalaryInformation_employeeId_key`(`employeeId`),
    INDEX `SalaryInformation_employeeId_idx`(`employeeId`),
    INDEX `SalaryInformation_effectiveFrom_idx`(`effectiveFrom`),
    INDEX `SalaryInformation_isActive_idx`(`isActive`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Expense` (
    `id` VARCHAR(191) NOT NULL,
    `employeeId` VARCHAR(191) NOT NULL,
    `expenseType` VARCHAR(191) NOT NULL,
    `amount` DOUBLE NOT NULL,
    `expenseDate` DATETIME(3) NOT NULL,
    `description` VARCHAR(191) NULL,
    `billNumber` VARCHAR(191) NULL,
    `attachmentUrl` VARCHAR(191) NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'Pending',
    `approvedBy` VARCHAR(191) NULL,
    `approvedAt` DATETIME(3) NULL,
    `rejectionReason` VARCHAR(191) NULL,
    `paidAt` DATETIME(3) NULL,
    `remarks` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `Expense_employeeId_idx`(`employeeId`),
    INDEX `Expense_status_idx`(`status`),
    INDEX `Expense_expenseDate_idx`(`expenseDate`),
    INDEX `Expense_expenseType_idx`(`expenseType`),
    INDEX `Expense_approvedBy_fkey`(`approvedBy`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `TaskAssignment` (
    `id` VARCHAR(191) NOT NULL,
    `salesmanId` VARCHAR(191) NOT NULL,
    `salesmanName` VARCHAR(191) NOT NULL,
    `pincode` VARCHAR(191) NOT NULL,
    `country` VARCHAR(191) NULL,
    `state` VARCHAR(191) NULL,
    `district` VARCHAR(191) NULL,
    `city` VARCHAR(191) NULL,
    `areas` JSON NULL,
    `businessTypes` JSON NULL,
    `totalBusinesses` INTEGER NULL DEFAULT 0,
    `assignedDate` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `TaskAssignment_salesmanId_idx`(`salesmanId`),
    INDEX `TaskAssignment_pincode_idx`(`pincode`),
    INDEX `TaskAssignment_assignedDate_idx`(`assignedDate`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Shop` (
    `id` VARCHAR(191) NOT NULL,
    `placeId` VARCHAR(191) NULL,
    `name` VARCHAR(191) NOT NULL,
    `businessType` VARCHAR(191) NOT NULL,
    `address` VARCHAR(191) NULL,
    `pincode` VARCHAR(191) NOT NULL,
    `area` VARCHAR(191) NULL,
    `city` VARCHAR(191) NULL,
    `state` VARCHAR(191) NULL,
    `country` VARCHAR(191) NULL,
    `latitude` DOUBLE NULL,
    `longitude` DOUBLE NULL,
    `phoneNumber` VARCHAR(191) NULL,
    `rating` DOUBLE NULL,
    `stage` VARCHAR(191) NOT NULL DEFAULT 'new',
    `assignedTo` VARCHAR(191) NULL,
    `notes` VARCHAR(191) NULL,
    `lastContactDate` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `Shop_placeId_key`(`placeId`),
    INDEX `Shop_pincode_idx`(`pincode`),
    INDEX `Shop_businessType_idx`(`businessType`),
    INDEX `Shop_stage_idx`(`stage`),
    INDEX `Shop_assignedTo_idx`(`assignedTo`),
    INDEX `Shop_area_idx`(`area`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Attendance` (
    `id` VARCHAR(191) NOT NULL,
    `employeeId` VARCHAR(191) NOT NULL,
    `employeeName` VARCHAR(191) NOT NULL,
    `date` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `punchInTime` DATETIME(3) NOT NULL,
    `punchInLatitude` DOUBLE NOT NULL,
    `punchInLongitude` DOUBLE NOT NULL,
    `punchInPhoto` LONGTEXT NULL,
    `punchInAddress` VARCHAR(191) NULL,
    `bikeKmStart` VARCHAR(191) NULL,
    `punchOutTime` DATETIME(3) NULL,
    `punchOutLatitude` DOUBLE NULL,
    `punchOutLongitude` DOUBLE NULL,
    `punchOutPhoto` LONGTEXT NULL,
    `punchOutAddress` VARCHAR(191) NULL,
    `bikeKmEnd` VARCHAR(191) NULL,
    `totalWorkHours` DOUBLE NULL,
    `totalDistanceKm` DOUBLE NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'active',
    `isLatePunchIn` BOOLEAN NOT NULL DEFAULT false,
    `lateApprovalId` VARCHAR(191) NULL,
    `approvalCode` VARCHAR(191) NULL,
    `isEarlyPunchOut` BOOLEAN NOT NULL DEFAULT false,
    `earlyPunchOutApprovalId` VARCHAR(191) NULL,
    `earlyPunchOutCode` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `Attendance_employeeId_idx`(`employeeId`),
    INDEX `Attendance_date_idx`(`date`),
    INDEX `Attendance_status_idx`(`status`),
    INDEX `Attendance_punchInTime_idx`(`punchInTime`),
    INDEX `Attendance_isLatePunchIn_idx`(`isLatePunchIn`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `SalesmanTrackingPoint` (
    `id` VARCHAR(191) NOT NULL,
    `clientPointId` VARCHAR(191) NULL,
    `employeeId` VARCHAR(191) NOT NULL,
    `attendanceId` VARCHAR(191) NOT NULL,
    `latitude` DOUBLE NOT NULL,
    `longitude` DOUBLE NOT NULL,
    `speed` DOUBLE NULL,
    `accuracy` DOUBLE NULL,
    `recordedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `SalesmanTrackingPoint_clientPointId_key`(`clientPointId`),
    INDEX `SalesmanTrackingPoint_employeeId_idx`(`employeeId`),
    INDEX `SalesmanTrackingPoint_attendanceId_idx`(`attendanceId`),
    INDEX `SalesmanTrackingPoint_recordedAt_idx`(`recordedAt`),
    INDEX `SalesmanTrackingPoint_employeeId_attendanceId_recordedAt_idx`(`employeeId`, `attendanceId`, `recordedAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `AreaAssignment` (
    `id` VARCHAR(191) NOT NULL,
    `salesmanId` VARCHAR(191) NOT NULL,
    `pinCode` VARCHAR(191) NOT NULL,
    `country` VARCHAR(191) NOT NULL,
    `state` VARCHAR(191) NOT NULL,
    `district` VARCHAR(191) NOT NULL,
    `city` VARCHAR(191) NOT NULL,
    `areas` JSON NULL,
    `businessTypes` JSON NULL,
    `assignedDate` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `totalBusinesses` INTEGER NOT NULL DEFAULT 0,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `AreaAssignment_salesmanId_idx`(`salesmanId`),
    INDEX `AreaAssignment_pinCode_idx`(`pinCode`),
    INDEX `AreaAssignment_city_district_idx`(`city`, `district`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Notification` (
    `id` VARCHAR(191) NOT NULL,
    `title` VARCHAR(191) NOT NULL,
    `message` VARCHAR(191) NOT NULL,
    `type` VARCHAR(191) NOT NULL,
    `priority` VARCHAR(191) NOT NULL DEFAULT 'normal',
    `targetRole` VARCHAR(191) NULL,
    `targetUserId` VARCHAR(191) NULL,
    `data` JSON NULL,
    `isRead` BOOLEAN NOT NULL DEFAULT false,
    `readAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `Notification_targetRole_idx`(`targetRole`),
    INDEX `Notification_targetUserId_idx`(`targetUserId`),
    INDEX `Notification_type_idx`(`type`),
    INDEX `Notification_isRead_idx`(`isRead`),
    INDEX `Notification_createdAt_idx`(`createdAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `LatePunchApproval` (
    `id` VARCHAR(191) NOT NULL,
    `employeeId` VARCHAR(191) NOT NULL,
    `employeeName` VARCHAR(191) NOT NULL,
    `requestDate` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `punchInDate` DATETIME(3) NOT NULL,
    `reason` VARCHAR(191) NOT NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'PENDING',
    `approvedBy` VARCHAR(191) NULL,
    `approvedAt` DATETIME(3) NULL,
    `adminRemarks` VARCHAR(191) NULL,
    `approvalCode` VARCHAR(191) NULL,
    `codeExpiresAt` DATETIME(3) NULL,
    `codeUsed` BOOLEAN NOT NULL DEFAULT false,
    `codeUsedAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `LatePunchApproval_employeeId_idx`(`employeeId`),
    INDEX `LatePunchApproval_status_idx`(`status`),
    INDEX `LatePunchApproval_requestDate_idx`(`requestDate`),
    INDEX `LatePunchApproval_approvalCode_idx`(`approvalCode`),
    INDEX `LatePunchApproval_approvedBy_fkey`(`approvedBy`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `EarlyPunchOutApproval` (
    `id` VARCHAR(191) NOT NULL,
    `employeeId` VARCHAR(191) NOT NULL,
    `employeeName` VARCHAR(191) NOT NULL,
    `attendanceId` VARCHAR(191) NOT NULL,
    `requestDate` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `punchOutDate` DATETIME(3) NOT NULL,
    `reason` VARCHAR(191) NOT NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'PENDING',
    `approvedBy` VARCHAR(191) NULL,
    `approvedAt` DATETIME(3) NULL,
    `adminRemarks` VARCHAR(191) NULL,
    `approvalCode` VARCHAR(191) NULL,
    `codeExpiresAt` DATETIME(3) NULL,
    `codeUsed` BOOLEAN NOT NULL DEFAULT false,
    `codeUsedAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `EarlyPunchOutApproval_employeeId_idx`(`employeeId`),
    INDEX `EarlyPunchOutApproval_attendanceId_idx`(`attendanceId`),
    INDEX `EarlyPunchOutApproval_status_idx`(`status`),
    INDEX `EarlyPunchOutApproval_requestDate_idx`(`requestDate`),
    INDEX `EarlyPunchOutApproval_approvalCode_idx`(`approvalCode`),
    INDEX `EarlyPunchOutApproval_approvedBy_fkey`(`approvedBy`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `Leave` (
    `id` VARCHAR(191) NOT NULL,
    `employeeId` VARCHAR(191) NOT NULL,
    `employeeName` VARCHAR(191) NOT NULL,
    `leaveType` VARCHAR(191) NOT NULL,
    `startDate` DATETIME(3) NOT NULL,
    `endDate` DATETIME(3) NOT NULL,
    `numberOfDays` INTEGER NOT NULL,
    `reason` VARCHAR(191) NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'PENDING',
    `requestedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `approvedBy` VARCHAR(191) NULL,
    `approvedAt` DATETIME(3) NULL,
    `rejectionReason` VARCHAR(191) NULL,
    `adminRemarks` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `Leave_employeeId_idx`(`employeeId`),
    INDEX `Leave_status_idx`(`status`),
    INDEX `Leave_startDate_idx`(`startDate`),
    INDEX `Leave_endDate_idx`(`endDate`),
    INDEX `Leave_leaveType_idx`(`leaveType`),
    INDEX `Leave_requestedAt_idx`(`requestedAt`),
    INDEX `Leave_approvedBy_fkey`(`approvedBy`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `LeaveBalance` (
    `id` VARCHAR(191) NOT NULL,
    `employeeId` VARCHAR(191) NOT NULL,
    `year` INTEGER NOT NULL,
    `sickLeaves` INTEGER NOT NULL DEFAULT 12,
    `casualLeaves` INTEGER NOT NULL DEFAULT 10,
    `earnedLeaves` INTEGER NOT NULL DEFAULT 20,
    `usedSickLeaves` INTEGER NOT NULL DEFAULT 0,
    `usedCasualLeaves` INTEGER NOT NULL DEFAULT 0,
    `usedEarnedLeaves` INTEGER NOT NULL DEFAULT 0,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `LeaveBalance_employeeId_key`(`employeeId`),
    INDEX `LeaveBalance_employeeId_idx`(`employeeId`),
    INDEX `LeaveBalance_year_idx`(`year`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `WeeklyBeatPlan` (
    `id` VARCHAR(191) NOT NULL,
    `salesmanId` VARCHAR(191) NOT NULL,
    `salesmanName` VARCHAR(191) NOT NULL,
    `weekStartDate` DATETIME(3) NOT NULL,
    `weekEndDate` DATETIME(3) NOT NULL,
    `pincodes` JSON NULL,
    `totalAreas` INTEGER NOT NULL DEFAULT 0,
    `status` VARCHAR(191) NOT NULL DEFAULT 'DRAFT',
    `generatedBy` VARCHAR(191) NULL,
    `approvedBy` VARCHAR(191) NULL,
    `approvedAt` DATETIME(3) NULL,
    `lockedBy` VARCHAR(191) NULL,
    `lockedAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `WeeklyBeatPlan_salesmanId_idx`(`salesmanId`),
    INDEX `WeeklyBeatPlan_weekStartDate_idx`(`weekStartDate`),
    INDEX `WeeklyBeatPlan_status_idx`(`status`),
    INDEX `WeeklyBeatPlan_generatedBy_idx`(`generatedBy`),
    INDEX `WeeklyBeatPlan_approvedBy_fkey`(`approvedBy`),
    INDEX `WeeklyBeatPlan_lockedBy_fkey`(`lockedBy`),
    UNIQUE INDEX `WeeklyBeatPlan_salesmanId_weekStartDate_key`(`salesmanId`, `weekStartDate`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `DailyBeatPlan` (
    `id` VARCHAR(191) NOT NULL,
    `weeklyBeatId` VARCHAR(191) NOT NULL,
    `dayOfWeek` INTEGER NOT NULL,
    `dayDate` DATETIME(3) NOT NULL,
    `assignedAreas` JSON NULL,
    `plannedVisits` INTEGER NOT NULL DEFAULT 0,
    `actualVisits` INTEGER NOT NULL DEFAULT 0,
    `status` VARCHAR(191) NOT NULL DEFAULT 'PLANNED',
    `completedAt` DATETIME(3) NULL,
    `carriedFromDate` DATETIME(3) NULL,
    `carriedToDate` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `DailyBeatPlan_weeklyBeatId_idx`(`weeklyBeatId`),
    INDEX `DailyBeatPlan_dayOfWeek_idx`(`dayOfWeek`),
    INDEX `DailyBeatPlan_dayDate_idx`(`dayDate`),
    INDEX `DailyBeatPlan_status_idx`(`status`),
    UNIQUE INDEX `DailyBeatPlan_weeklyBeatId_dayOfWeek_key`(`weeklyBeatId`, `dayOfWeek`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `BeatCompletion` (
    `id` VARCHAR(191) NOT NULL,
    `dailyBeatId` VARCHAR(191) NOT NULL,
    `salesmanId` VARCHAR(191) NOT NULL,
    `areaName` VARCHAR(191) NOT NULL,
    `accountsVisited` INTEGER NOT NULL DEFAULT 0,
    `completedAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `latitude` DOUBLE NULL,
    `longitude` DOUBLE NULL,
    `notes` VARCHAR(191) NULL,
    `isVerified` BOOLEAN NOT NULL DEFAULT false,
    `verifiedBy` VARCHAR(191) NULL,
    `verifiedAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `BeatCompletion_dailyBeatId_idx`(`dailyBeatId`),
    INDEX `BeatCompletion_salesmanId_idx`(`salesmanId`),
    INDEX `BeatCompletion_completedAt_idx`(`completedAt`),
    INDEX `BeatCompletion_areaName_idx`(`areaName`),
    INDEX `BeatCompletion_verifiedBy_fkey`(`verifiedBy`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `State` ADD CONSTRAINT `State_country_id_fkey` FOREIGN KEY (`country_id`) REFERENCES `Country`(`country_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Region` ADD CONSTRAINT `Region_state_id_fkey` FOREIGN KEY (`state_id`) REFERENCES `State`(`state_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `District` ADD CONSTRAINT `District_region_id_fkey` FOREIGN KEY (`region_id`) REFERENCES `Region`(`region_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `City` ADD CONSTRAINT `City_district_id_fkey` FOREIGN KEY (`district_id`) REFERENCES `District`(`district_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Zone` ADD CONSTRAINT `Zone_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `City`(`city_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Area` ADD CONSTRAINT `Area_zone_id_fkey` FOREIGN KEY (`zone_id`) REFERENCES `Zone`(`zone_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `User` ADD CONSTRAINT `User_departmentId_fkey` FOREIGN KEY (`departmentId`) REFERENCES `Department`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `User` ADD CONSTRAINT `User_roleId_fkey` FOREIGN KEY (`roleId`) REFERENCES `Role`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `EmployeeArea` ADD CONSTRAINT `EmployeeArea_area_id_fkey` FOREIGN KEY (`area_id`) REFERENCES `Area`(`area_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `EmployeeArea` ADD CONSTRAINT `EmployeeArea_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `City`(`city_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `EmployeeArea` ADD CONSTRAINT `EmployeeArea_country_id_fkey` FOREIGN KEY (`country_id`) REFERENCES `Country`(`country_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `EmployeeArea` ADD CONSTRAINT `EmployeeArea_district_id_fkey` FOREIGN KEY (`district_id`) REFERENCES `District`(`district_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `EmployeeArea` ADD CONSTRAINT `EmployeeArea_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `EmployeeArea` ADD CONSTRAINT `EmployeeArea_region_id_fkey` FOREIGN KEY (`region_id`) REFERENCES `Region`(`region_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `EmployeeArea` ADD CONSTRAINT `EmployeeArea_state_id_fkey` FOREIGN KEY (`state_id`) REFERENCES `State`(`state_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `EmployeeArea` ADD CONSTRAINT `EmployeeArea_zone_id_fkey` FOREIGN KEY (`zone_id`) REFERENCES `Zone`(`zone_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Account` ADD CONSTRAINT `Account_approvedById_fkey` FOREIGN KEY (`approvedById`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Account` ADD CONSTRAINT `Account_areaId_fkey` FOREIGN KEY (`areaId`) REFERENCES `Area`(`area_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Account` ADD CONSTRAINT `Account_assignedToId_fkey` FOREIGN KEY (`assignedToId`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Account` ADD CONSTRAINT `Account_createdById_fkey` FOREIGN KEY (`createdById`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `WeeklyAccountAssignment` ADD CONSTRAINT `WeeklyAccountAssignment_accountId_fkey` FOREIGN KEY (`accountId`) REFERENCES `Account`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `TelecallerCallLog` ADD CONSTRAINT `TelecallerCallLog_accountId_fkey` FOREIGN KEY (`accountId`) REFERENCES `Account`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `TelecallerCallLog` ADD CONSTRAINT `TelecallerCallLog_telecallerId_fkey` FOREIGN KEY (`telecallerId`) REFERENCES `User`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `TelecallerPincodeAssignment` ADD CONSTRAINT `TelecallerPincodeAssignment_telecallerId_fkey` FOREIGN KEY (`telecallerId`) REFERENCES `User`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `SalaryInformation` ADD CONSTRAINT `SalaryInformation_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Expense` ADD CONSTRAINT `Expense_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Expense` ADD CONSTRAINT `Expense_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `SalesmanTrackingPoint` ADD CONSTRAINT `SalesmanTrackingPoint_attendanceId_fkey` FOREIGN KEY (`attendanceId`) REFERENCES `Attendance`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `SalesmanTrackingPoint` ADD CONSTRAINT `SalesmanTrackingPoint_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `AreaAssignment` ADD CONSTRAINT `AreaAssignment_salesmanId_fkey` FOREIGN KEY (`salesmanId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Notification` ADD CONSTRAINT `Notification_targetUserId_fkey` FOREIGN KEY (`targetUserId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `LatePunchApproval` ADD CONSTRAINT `LatePunchApproval_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `LatePunchApproval` ADD CONSTRAINT `LatePunchApproval_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `EarlyPunchOutApproval` ADD CONSTRAINT `EarlyPunchOutApproval_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `EarlyPunchOutApproval` ADD CONSTRAINT `EarlyPunchOutApproval_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Leave` ADD CONSTRAINT `Leave_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `Leave` ADD CONSTRAINT `Leave_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `LeaveBalance` ADD CONSTRAINT `LeaveBalance_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `WeeklyBeatPlan` ADD CONSTRAINT `WeeklyBeatPlan_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `WeeklyBeatPlan` ADD CONSTRAINT `WeeklyBeatPlan_generatedBy_fkey` FOREIGN KEY (`generatedBy`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `WeeklyBeatPlan` ADD CONSTRAINT `WeeklyBeatPlan_lockedBy_fkey` FOREIGN KEY (`lockedBy`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `WeeklyBeatPlan` ADD CONSTRAINT `WeeklyBeatPlan_salesmanId_fkey` FOREIGN KEY (`salesmanId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `DailyBeatPlan` ADD CONSTRAINT `DailyBeatPlan_weeklyBeatId_fkey` FOREIGN KEY (`weeklyBeatId`) REFERENCES `WeeklyBeatPlan`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `BeatCompletion` ADD CONSTRAINT `BeatCompletion_dailyBeatId_fkey` FOREIGN KEY (`dailyBeatId`) REFERENCES `DailyBeatPlan`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `BeatCompletion` ADD CONSTRAINT `BeatCompletion_salesmanId_fkey` FOREIGN KEY (`salesmanId`) REFERENCES `User`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `BeatCompletion` ADD CONSTRAINT `BeatCompletion_verifiedBy_fkey` FOREIGN KEY (`verifiedBy`) REFERENCES `User`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

