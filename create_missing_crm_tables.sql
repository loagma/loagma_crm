SET FOREIGN_KEY_CHECKS=0;

CREATE TABLE IF NOT EXISTS `department_crm` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE KEY `Department_name_key` (`name`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `LoginUserRoles_crm` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `LoginUser_crm` (
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
  CONSTRAINT `User_roleId_fkey` FOREIGN KEY (`roleId`) REFERENCES `LoginUserRoles_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS=1;
