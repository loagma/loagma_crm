# CRM DB and Loagma New DB - Full Schema Documentation

Generated on: 2026-04-04 11:02:32

## Summary

- CRM DB tables: 31
- Loagma New DB tables: 73
- Common tables (case-insensitive name match): 2

## CRM DB Schema

### Table: _prisma_migrations

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(36) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL |
| checksum | varchar(64) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL |
| finished_at | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| migration_name | varchar(255) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL |
| logs | text | NULL | NULL | COLLATE utf8mb4_unicode_ci | text COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| rolled_back_at | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| started_at | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| applied_steps_count | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: Account

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| accountCode | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| businessName | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| businessType | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| businessSize | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| personName | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| contactNumber | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| dateOfBirth | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| customerStage | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| funnelStage | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| gstNumber | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| panCard | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| ownerImage | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| shopImage | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| isActive | tinyint(1) | NOT NULL | '1' | - | tinyint(1) NOT NULL DEFAULT '1' |
| pincode | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| country | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| state | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| district | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| city | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| area | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| address | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| latitude | double | NULL | NULL | - | double DEFAULT NULL |
| longitude | double | NULL | NULL | - | double DEFAULT NULL |
| areaId | int | NULL | NULL | - | int DEFAULT NULL |
| assignedToId | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| assignedDays | json | NULL | NULL | - | json DEFAULT NULL |
| createdById | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| approvedById | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| approvedAt | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| isApproved | tinyint(1) | NOT NULL | '0' | - | tinyint(1) NOT NULL DEFAULT '0' |
| verificationNotes | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| rejectionNotes | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| updatedAt | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |

#### Keys, Indexes, Constraints

- UNIQUE KEY `Account_accountCode_key` (`accountCode`)
- KEY `Account_pincode_idx` (`pincode`)
- KEY `Account_isActive_idx` (`isActive`)
- KEY `Account_customerStage_idx` (`customerStage`)
- KEY `Account_createdAt_idx` (`createdAt`)
- KEY `Account_businessType_idx` (`businessType`)
- KEY `Account_businessSize_idx` (`businessSize`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `Account_areaId_fkey` (`areaId`)
- KEY `Account_assignedToId_fkey` (`assignedToId`)
- KEY `Account_createdById_fkey` (`createdById`)
- KEY `Account_approvedById_fkey` (`approvedById`)
- CONSTRAINT `Account_areaId_fkey` FOREIGN KEY (`areaId`) REFERENCES `Area` (`area_id`) ON DELETE SET NULL ON UPDATE CASCADE
- CONSTRAINT `Account_assignedToId_fkey` FOREIGN KEY (`assignedToId`) REFERENCES `User` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
- CONSTRAINT `Account_createdById_fkey` FOREIGN KEY (`createdById`) REFERENCES `User` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
- CONSTRAINT `Account_approvedById_fkey` FOREIGN KEY (`approvedById`) REFERENCES `User` (`id`) ON DELETE SET NULL ON UPDATE CASCADE

### Table: Area

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| area_id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| area_name | varchar(100) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL |
| zone_id | int | NOT NULL | - | - | int NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`area_id`) /*T![clustered_index] CLUSTERED */
- KEY `Area_zone_id_fkey` (`zone_id`)
- CONSTRAINT `Area_zone_id_fkey` FOREIGN KEY (`zone_id`) REFERENCES `Zone` (`zone_id`) ON DELETE CASCADE ON UPDATE CASCADE

### Table: AreaAssignment

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| salesmanId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| pinCode | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| country | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| state | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| district | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| city | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| areas | json | NULL | NULL | - | json DEFAULT NULL |
| businessTypes | json | NULL | NULL | - | json DEFAULT NULL |
| assignedDate | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| totalBusinesses | int | NOT NULL | '0' | - | int NOT NULL DEFAULT '0' |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| updatedAt | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |

#### Keys, Indexes, Constraints

- KEY `AreaAssignment_salesmanId_idx` (`salesmanId`)
- KEY `AreaAssignment_pinCode_idx` (`pinCode`)
- KEY `AreaAssignment_city_district_idx` (`city`,`district`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- CONSTRAINT `AreaAssignment_salesmanId_fkey` FOREIGN KEY (`salesmanId`) REFERENCES `User` (`id`) ON DELETE CASCADE ON UPDATE CASCADE

### Table: Attendance

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| employeeId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| employeeName | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| date | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| punchInTime | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |
| punchInLatitude | double | NOT NULL | - | - | double NOT NULL |
| punchInLongitude | double | NOT NULL | - | - | double NOT NULL |
| punchInPhoto | longtext | NULL | NULL | COLLATE utf8mb4_unicode_ci | longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| punchInAddress | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| bikeKmStart | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| punchOutTime | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| punchOutLatitude | double | NULL | NULL | - | double DEFAULT NULL |
| punchOutLongitude | double | NULL | NULL | - | double DEFAULT NULL |
| punchOutPhoto | longtext | NULL | NULL | COLLATE utf8mb4_unicode_ci | longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| punchOutAddress | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| bikeKmEnd | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| totalWorkHours | double | NULL | NULL | - | double DEFAULT NULL |
| totalDistanceKm | double | NULL | NULL | - | double DEFAULT NULL |
| status | varchar(191) | NOT NULL | 'active' | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active' |
| isLatePunchIn | tinyint(1) | NOT NULL | '0' | - | tinyint(1) NOT NULL DEFAULT '0' |
| lateApprovalId | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| approvalCode | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| isEarlyPunchOut | tinyint(1) | NOT NULL | '0' | - | tinyint(1) NOT NULL DEFAULT '0' |
| earlyPunchOutApprovalId | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| earlyPunchOutCode | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| updatedAt | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |

#### Keys, Indexes, Constraints

- KEY `Attendance_employeeId_idx` (`employeeId`)
- KEY `Attendance_date_idx` (`date`)
- KEY `Attendance_status_idx` (`status`)
- KEY `Attendance_punchInTime_idx` (`punchInTime`)
- KEY `Attendance_isLatePunchIn_idx` (`isLatePunchIn`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: BeatCompletion

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| dailyBeatId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| salesmanId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| areaName | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| accountsVisited | int | NOT NULL | '0' | - | int NOT NULL DEFAULT '0' |
| completedAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| latitude | double | NULL | NULL | - | double DEFAULT NULL |
| longitude | double | NULL | NULL | - | double DEFAULT NULL |
| notes | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| isVerified | tinyint(1) | NOT NULL | '0' | - | tinyint(1) NOT NULL DEFAULT '0' |
| verifiedBy | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| verifiedAt | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| updatedAt | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |

#### Keys, Indexes, Constraints

- KEY `BeatCompletion_dailyBeatId_idx` (`dailyBeatId`)
- KEY `BeatCompletion_salesmanId_idx` (`salesmanId`)
- KEY `BeatCompletion_completedAt_idx` (`completedAt`)
- KEY `BeatCompletion_areaName_idx` (`areaName`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `BeatCompletion_verifiedBy_fkey` (`verifiedBy`)
- CONSTRAINT `BeatCompletion_dailyBeatId_fkey` FOREIGN KEY (`dailyBeatId`) REFERENCES `DailyBeatPlan` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
- CONSTRAINT `BeatCompletion_salesmanId_fkey` FOREIGN KEY (`salesmanId`) REFERENCES `User` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
- CONSTRAINT `BeatCompletion_verifiedBy_fkey` FOREIGN KEY (`verifiedBy`) REFERENCES `User` (`id`) ON DELETE SET NULL ON UPDATE CASCADE

### Table: City

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| city_id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| city_name | varchar(100) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL |
| district_id | int | NOT NULL | - | - | int NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`city_id`) /*T![clustered_index] CLUSTERED */
- KEY `City_district_id_fkey` (`district_id`)
- CONSTRAINT `City_district_id_fkey` FOREIGN KEY (`district_id`) REFERENCES `District` (`district_id`) ON DELETE CASCADE ON UPDATE CASCADE

### Table: Country

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| country_id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| country_name | varchar(100) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`country_id`) /*T![clustered_index] CLUSTERED */

### Table: DailyBeatPlan

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| weeklyBeatId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| dayOfWeek | int | NOT NULL | - | - | int NOT NULL |
| dayDate | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |
| assignedAreas | json | NULL | NULL | - | json DEFAULT NULL |
| plannedVisits | int | NOT NULL | '0' | - | int NOT NULL DEFAULT '0' |
| actualVisits | int | NOT NULL | '0' | - | int NOT NULL DEFAULT '0' |
| status | varchar(191) | NOT NULL | 'PLANNED' | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PLANNED' |
| completedAt | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| carriedFromDate | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| carriedToDate | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| updatedAt | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |

#### Keys, Indexes, Constraints

- KEY `DailyBeatPlan_weeklyBeatId_idx` (`weeklyBeatId`)
- KEY `DailyBeatPlan_dayOfWeek_idx` (`dayOfWeek`)
- KEY `DailyBeatPlan_dayDate_idx` (`dayDate`)
- KEY `DailyBeatPlan_status_idx` (`status`)
- UNIQUE KEY `DailyBeatPlan_weeklyBeatId_dayOfWeek_key` (`weeklyBeatId`,`dayOfWeek`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- CONSTRAINT `DailyBeatPlan_weeklyBeatId_fkey` FOREIGN KEY (`weeklyBeatId`) REFERENCES `WeeklyBeatPlan` (`id`) ON DELETE CASCADE ON UPDATE CASCADE

### Table: Department

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| name | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |

#### Keys, Indexes, Constraints

- UNIQUE KEY `Department_name_key` (`name`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: District

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| district_id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| district_name | varchar(100) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL |
| region_id | int | NOT NULL | - | - | int NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`district_id`) /*T![clustered_index] CLUSTERED */
- KEY `District_region_id_fkey` (`region_id`)
- CONSTRAINT `District_region_id_fkey` FOREIGN KEY (`region_id`) REFERENCES `Region` (`region_id`) ON DELETE CASCADE ON UPDATE CASCADE

### Table: EarlyPunchOutApproval

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| employeeId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| employeeName | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| attendanceId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| requestDate | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| punchOutDate | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |
| reason | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| status | varchar(191) | NOT NULL | 'PENDING' | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING' |
| approvedBy | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| approvedAt | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| adminRemarks | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| approvalCode | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| codeExpiresAt | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| codeUsed | tinyint(1) | NOT NULL | '0' | - | tinyint(1) NOT NULL DEFAULT '0' |
| codeUsedAt | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| updatedAt | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |

#### Keys, Indexes, Constraints

- KEY `EarlyPunchOutApproval_employeeId_idx` (`employeeId`)
- KEY `EarlyPunchOutApproval_attendanceId_idx` (`attendanceId`)
- KEY `EarlyPunchOutApproval_status_idx` (`status`)
- KEY `EarlyPunchOutApproval_requestDate_idx` (`requestDate`)
- KEY `EarlyPunchOutApproval_approvalCode_idx` (`approvalCode`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `EarlyPunchOutApproval_approvedBy_fkey` (`approvedBy`)
- CONSTRAINT `EarlyPunchOutApproval_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `User` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
- CONSTRAINT `EarlyPunchOutApproval_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `User` (`id`) ON DELETE SET NULL ON UPDATE CASCADE

### Table: EmployeeArea

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| area_id | int | NULL | NULL | - | int DEFAULT NULL |
| city_id | int | NULL | NULL | - | int DEFAULT NULL |
| country_id | int | NULL | NULL | - | int DEFAULT NULL |
| district_id | int | NULL | NULL | - | int DEFAULT NULL |
| employeeId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| latitude | double | NULL | NULL | - | double DEFAULT NULL |
| longitude | double | NULL | NULL | - | double DEFAULT NULL |
| region_id | int | NULL | NULL | - | int DEFAULT NULL |
| state_id | int | NULL | NULL | - | int DEFAULT NULL |
| zone_id | int | NULL | NULL | - | int DEFAULT NULL |
| id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- UNIQUE KEY `EmployeeArea_employeeId_key` (`employeeId`)
- KEY `EmployeeArea_area_id_fkey` (`area_id`)
- KEY `EmployeeArea_city_id_fkey` (`city_id`)
- KEY `EmployeeArea_country_id_fkey` (`country_id`)
- KEY `EmployeeArea_district_id_fkey` (`district_id`)
- KEY `EmployeeArea_region_id_fkey` (`region_id`)
- KEY `EmployeeArea_state_id_fkey` (`state_id`)
- KEY `EmployeeArea_zone_id_fkey` (`zone_id`)
- CONSTRAINT `EmployeeArea_area_id_fkey` FOREIGN KEY (`area_id`) REFERENCES `Area` (`area_id`) ON DELETE SET NULL ON UPDATE CASCADE
- CONSTRAINT `EmployeeArea_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `City` (`city_id`) ON DELETE SET NULL ON UPDATE CASCADE
- CONSTRAINT `EmployeeArea_country_id_fkey` FOREIGN KEY (`country_id`) REFERENCES `Country` (`country_id`) ON DELETE SET NULL ON UPDATE CASCADE
- CONSTRAINT `EmployeeArea_district_id_fkey` FOREIGN KEY (`district_id`) REFERENCES `District` (`district_id`) ON DELETE SET NULL ON UPDATE CASCADE
- CONSTRAINT `EmployeeArea_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `User` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
- CONSTRAINT `EmployeeArea_region_id_fkey` FOREIGN KEY (`region_id`) REFERENCES `Region` (`region_id`) ON DELETE SET NULL ON UPDATE CASCADE
- CONSTRAINT `EmployeeArea_state_id_fkey` FOREIGN KEY (`state_id`) REFERENCES `State` (`state_id`) ON DELETE SET NULL ON UPDATE CASCADE
- CONSTRAINT `EmployeeArea_zone_id_fkey` FOREIGN KEY (`zone_id`) REFERENCES `Zone` (`zone_id`) ON DELETE SET NULL ON UPDATE CASCADE

### Table: Expense

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| employeeId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| expenseType | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| amount | double | NOT NULL | - | - | double NOT NULL |
| expenseDate | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |
| description | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| billNumber | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| attachmentUrl | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| status | varchar(191) | NOT NULL | 'Pending' | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Pending' |
| approvedBy | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| approvedAt | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| rejectionReason | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| paidAt | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| remarks | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| updatedAt | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |

#### Keys, Indexes, Constraints

- KEY `Expense_employeeId_idx` (`employeeId`)
- KEY `Expense_status_idx` (`status`)
- KEY `Expense_expenseDate_idx` (`expenseDate`)
- KEY `Expense_expenseType_idx` (`expenseType`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `Expense_approvedBy_fkey` (`approvedBy`)
- CONSTRAINT `Expense_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `User` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
- CONSTRAINT `Expense_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `User` (`id`) ON DELETE SET NULL ON UPDATE CASCADE

### Table: LatePunchApproval

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| employeeId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| employeeName | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| requestDate | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| punchInDate | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |
| reason | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| status | varchar(191) | NOT NULL | 'PENDING' | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING' |
| approvedBy | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| approvedAt | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| adminRemarks | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| approvalCode | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| codeExpiresAt | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| codeUsed | tinyint(1) | NOT NULL | '0' | - | tinyint(1) NOT NULL DEFAULT '0' |
| codeUsedAt | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| updatedAt | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |

#### Keys, Indexes, Constraints

- KEY `LatePunchApproval_employeeId_idx` (`employeeId`)
- KEY `LatePunchApproval_status_idx` (`status`)
- KEY `LatePunchApproval_requestDate_idx` (`requestDate`)
- KEY `LatePunchApproval_approvalCode_idx` (`approvalCode`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `LatePunchApproval_approvedBy_fkey` (`approvedBy`)
- CONSTRAINT `LatePunchApproval_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `User` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
- CONSTRAINT `LatePunchApproval_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `User` (`id`) ON DELETE SET NULL ON UPDATE CASCADE

### Table: Leave

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| employeeId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| employeeName | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| leaveType | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| startDate | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |
| endDate | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |
| numberOfDays | int | NOT NULL | - | - | int NOT NULL |
| reason | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| status | varchar(191) | NOT NULL | 'PENDING' | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING' |
| requestedAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| approvedBy | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| approvedAt | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| rejectionReason | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| adminRemarks | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| updatedAt | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |

#### Keys, Indexes, Constraints

- KEY `Leave_employeeId_idx` (`employeeId`)
- KEY `Leave_status_idx` (`status`)
- KEY `Leave_startDate_idx` (`startDate`)
- KEY `Leave_endDate_idx` (`endDate`)
- KEY `Leave_leaveType_idx` (`leaveType`)
- KEY `Leave_requestedAt_idx` (`requestedAt`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `Leave_approvedBy_fkey` (`approvedBy`)
- CONSTRAINT `Leave_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `User` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
- CONSTRAINT `Leave_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `User` (`id`) ON DELETE SET NULL ON UPDATE CASCADE

### Table: LeaveBalance

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| employeeId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| year | int | NOT NULL | - | - | int NOT NULL |
| sickLeaves | int | NOT NULL | '12' | - | int NOT NULL DEFAULT '12' |
| casualLeaves | int | NOT NULL | '10' | - | int NOT NULL DEFAULT '10' |
| earnedLeaves | int | NOT NULL | '20' | - | int NOT NULL DEFAULT '20' |
| usedSickLeaves | int | NOT NULL | '0' | - | int NOT NULL DEFAULT '0' |
| usedCasualLeaves | int | NOT NULL | '0' | - | int NOT NULL DEFAULT '0' |
| usedEarnedLeaves | int | NOT NULL | '0' | - | int NOT NULL DEFAULT '0' |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| updatedAt | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |

#### Keys, Indexes, Constraints

- UNIQUE KEY `LeaveBalance_employeeId_key` (`employeeId`)
- KEY `LeaveBalance_employeeId_idx` (`employeeId`)
- KEY `LeaveBalance_year_idx` (`year`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- CONSTRAINT `LeaveBalance_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `User` (`id`) ON DELETE CASCADE ON UPDATE CASCADE

### Table: Notification

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| title | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| message | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| type | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| priority | varchar(191) | NOT NULL | 'normal' | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'normal' |
| targetRole | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| targetUserId | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| data | json | NULL | NULL | - | json DEFAULT NULL |
| isRead | tinyint(1) | NOT NULL | '0' | - | tinyint(1) NOT NULL DEFAULT '0' |
| readAt | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| updatedAt | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |

#### Keys, Indexes, Constraints

- KEY `Notification_targetRole_idx` (`targetRole`)
- KEY `Notification_targetUserId_idx` (`targetUserId`)
- KEY `Notification_type_idx` (`type`)
- KEY `Notification_isRead_idx` (`isRead`)
- KEY `Notification_createdAt_idx` (`createdAt`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- CONSTRAINT `Notification_targetUserId_fkey` FOREIGN KEY (`targetUserId`) REFERENCES `User` (`id`) ON DELETE CASCADE ON UPDATE CASCADE

### Table: Region

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| region_id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| region_name | varchar(100) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL |
| state_id | int | NOT NULL | - | - | int NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`region_id`) /*T![clustered_index] CLUSTERED */
- KEY `Region_state_id_fkey` (`state_id`)
- CONSTRAINT `Region_state_id_fkey` FOREIGN KEY (`state_id`) REFERENCES `State` (`state_id`) ON DELETE CASCADE ON UPDATE CASCADE

### Table: Role

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| name | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: SalaryInformation

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| employeeId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| basicSalary | double | NOT NULL | - | - | double NOT NULL |
| hra | double | N/A | '0' | - | double DEFAULT '0' |
| travelAllowance | double | N/A | '0' | - | double DEFAULT '0' |
| dailyAllowance | double | N/A | '0' | - | double DEFAULT '0' |
| medicalAllowance | double | N/A | '0' | - | double DEFAULT '0' |
| specialAllowance | double | N/A | '0' | - | double DEFAULT '0' |
| otherAllowances | double | N/A | '0' | - | double DEFAULT '0' |
| providentFund | double | N/A | '0' | - | double DEFAULT '0' |
| professionalTax | double | N/A | '0' | - | double DEFAULT '0' |
| incomeTax | double | N/A | '0' | - | double DEFAULT '0' |
| otherDeductions | double | N/A | '0' | - | double DEFAULT '0' |
| effectiveFrom | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |
| effectiveTo | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| currency | varchar(191) | NOT NULL | 'INR' | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'INR' |
| paymentFrequency | varchar(191) | NOT NULL | 'Monthly' | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Monthly' |
| bankName | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| accountNumber | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| ifscCode | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| panNumber | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| remarks | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| isActive | tinyint(1) | NOT NULL | '1' | - | tinyint(1) NOT NULL DEFAULT '1' |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| updatedAt | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |

#### Keys, Indexes, Constraints

- UNIQUE KEY `SalaryInformation_employeeId_key` (`employeeId`)
- KEY `SalaryInformation_employeeId_idx` (`employeeId`)
- KEY `SalaryInformation_effectiveFrom_idx` (`effectiveFrom`)
- KEY `SalaryInformation_isActive_idx` (`isActive`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- CONSTRAINT `SalaryInformation_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `User` (`id`) ON DELETE CASCADE ON UPDATE CASCADE

### Table: SalesmanTrackingPoint

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| clientPointId | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| employeeId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| attendanceId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| latitude | double | NOT NULL | - | - | double NOT NULL |
| longitude | double | NOT NULL | - | - | double NOT NULL |
| speed | double | NULL | NULL | - | double DEFAULT NULL |
| accuracy | double | NULL | NULL | - | double DEFAULT NULL |
| recordedAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |

#### Keys, Indexes, Constraints

- UNIQUE KEY `SalesmanTrackingPoint_clientPointId_key` (`clientPointId`)
- KEY `SalesmanTrackingPoint_employeeId_idx` (`employeeId`)
- KEY `SalesmanTrackingPoint_attendanceId_idx` (`attendanceId`)
- KEY `SalesmanTrackingPoint_recordedAt_idx` (`recordedAt`)
- KEY `SalesmanTrackingPoint_employeeId_attendanceId_recordedAt_idx` (`employeeId`,`attendanceId`,`recordedAt`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- CONSTRAINT `SalesmanTrackingPoint_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `User` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
- CONSTRAINT `SalesmanTrackingPoint_attendanceId_fkey` FOREIGN KEY (`attendanceId`) REFERENCES `Attendance` (`id`) ON DELETE CASCADE ON UPDATE CASCADE

### Table: Shop

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| placeId | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| name | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| businessType | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| address | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| pincode | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| area | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| city | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| state | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| country | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| latitude | double | NULL | NULL | - | double DEFAULT NULL |
| longitude | double | NULL | NULL | - | double DEFAULT NULL |
| phoneNumber | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| rating | double | NULL | NULL | - | double DEFAULT NULL |
| stage | varchar(191) | NOT NULL | 'new' | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'new' |
| assignedTo | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| notes | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| lastContactDate | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| updatedAt | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |

#### Keys, Indexes, Constraints

- UNIQUE KEY `Shop_placeId_key` (`placeId`)
- KEY `Shop_pincode_idx` (`pincode`)
- KEY `Shop_businessType_idx` (`businessType`)
- KEY `Shop_stage_idx` (`stage`)
- KEY `Shop_assignedTo_idx` (`assignedTo`)
- KEY `Shop_area_idx` (`area`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: State

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| state_id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| state_name | varchar(100) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL |
| country_id | int | NOT NULL | - | - | int NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`state_id`) /*T![clustered_index] CLUSTERED */
- KEY `State_country_id_fkey` (`country_id`)
- CONSTRAINT `State_country_id_fkey` FOREIGN KEY (`country_id`) REFERENCES `Country` (`country_id`) ON DELETE CASCADE ON UPDATE CASCADE

### Table: TaskAssignment

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| salesmanId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| salesmanName | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| pincode | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| country | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| state | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| district | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| city | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| areas | json | NULL | NULL | - | json DEFAULT NULL |
| businessTypes | json | NULL | NULL | - | json DEFAULT NULL |
| totalBusinesses | int | N/A | '0' | - | int DEFAULT '0' |
| assignedDate | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| updatedAt | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |

#### Keys, Indexes, Constraints

- KEY `TaskAssignment_salesmanId_idx` (`salesmanId`)
- KEY `TaskAssignment_pincode_idx` (`pincode`)
- KEY `TaskAssignment_assignedDate_idx` (`assignedDate`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: TelecallerCallLog

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| accountId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| telecallerId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| calledAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| durationSec | int | NULL | NULL | - | int DEFAULT NULL |
| status | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| notes | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| recordingUrl | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| nextFollowupAt | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| followupNotes | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |

#### Keys, Indexes, Constraints

- KEY `TelecallerCallLog_telecallerId_calledAt_idx` (`telecallerId`,`calledAt`)
- KEY `TelecallerCallLog_accountId_calledAt_idx` (`accountId`,`calledAt`)
- KEY `TelecallerCallLog_nextFollowupAt_idx` (`nextFollowupAt`)
- KEY `TelecallerCallLog_status_idx` (`status`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- CONSTRAINT `TelecallerCallLog_accountId_fkey` FOREIGN KEY (`accountId`) REFERENCES `Account` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
- CONSTRAINT `TelecallerCallLog_telecallerId_fkey` FOREIGN KEY (`telecallerId`) REFERENCES `User` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE

### Table: TelecallerPincodeAssignment

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| telecallerId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| pincode | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| dayOfWeek | int | NOT NULL | - | - | int NOT NULL |
| isActive | tinyint(1) | NOT NULL | '1' | - | tinyint(1) NOT NULL DEFAULT '1' |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| updatedAt | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |

#### Keys, Indexes, Constraints

- KEY `TelecallerPincodeAssignment_telecallerId_idx` (`telecallerId`)
- KEY `TelecallerPincodeAssignment_pincode_dayOfWeek_idx` (`pincode`,`dayOfWeek`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- CONSTRAINT `TelecallerPincodeAssignment_telecallerId_fkey` FOREIGN KEY (`telecallerId`) REFERENCES `User` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE

### Table: User

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| employeeCode | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| name | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| email | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| contactNumber | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| alternativeNumber | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| roleId | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| roles | json | NULL | NULL | - | json DEFAULT NULL |
| departmentId | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| otp | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| otpExpiry | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| lastLogin | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| isActive | tinyint(1) | NOT NULL | '1' | - | tinyint(1) NOT NULL DEFAULT '1' |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| updatedAt | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |
| dateOfBirth | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| gender | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| image | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| preferredLanguages | json | NULL | NULL | - | json DEFAULT NULL |
| address | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| city | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| state | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| pincode | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| country | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| district | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| area | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| latitude | double | NULL | NULL | - | double DEFAULT NULL |
| longitude | double | NULL | NULL | - | double DEFAULT NULL |
| aadharCard | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| panCard | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| password | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| notes | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| workStartTime | varchar(191) | N/A | '09:00:00' | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT '09:00:00' |
| workEndTime | varchar(191) | N/A | '18:00:00' | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT '18:00:00' |
| latePunchInGraceMinutes | int | N/A | '45' | - | int DEFAULT '45' |
| earlyPunchOutGraceMinutes | int | N/A | '30' | - | int DEFAULT '30' |

#### Keys, Indexes, Constraints

- UNIQUE KEY `User_employeeCode_key` (`employeeCode`)
- UNIQUE KEY `User_email_key` (`email`)
- UNIQUE KEY `User_contactNumber_key` (`contactNumber`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `User_departmentId_fkey` (`departmentId`)
- KEY `User_roleId_fkey` (`roleId`)
- CONSTRAINT `User_departmentId_fkey` FOREIGN KEY (`departmentId`) REFERENCES `Department` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
- CONSTRAINT `User_roleId_fkey` FOREIGN KEY (`roleId`) REFERENCES `Role` (`id`) ON DELETE SET NULL ON UPDATE CASCADE

### Table: WeeklyAccountAssignment

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| accountId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| salesmanId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| pincode | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| weekStartDate | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |
| assignedDays | json | NOT NULL | - | - | json NOT NULL |
| isManualOverride | tinyint(1) | NOT NULL | '0' | - | tinyint(1) NOT NULL DEFAULT '0' |
| sequenceNo | int | NOT NULL | - | - | int NOT NULL |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| updatedAt | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |
| visitFrequency | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| overriddenAt | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| overrideBy | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| overrideReason | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| plannedAt | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| plannedBy | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| recurrenceAfterDays | int | NULL | NULL | - | int DEFAULT NULL |
| recurrenceStartDate | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| recurrenceNextDate | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |

#### Keys, Indexes, Constraints

- KEY `WeeklyAccountAssignment_salesmanId_weekStartDate_idx` (`salesmanId`,`weekStartDate`)
- KEY `WeeklyAccountAssignment_pincode_weekStartDate_idx` (`pincode`,`weekStartDate`)
- KEY `WeeklyAccountAssignment_salesmanId_pincode_weekStartDate_seq_idx` (`salesmanId`,`pincode`,`weekStartDate`,`sequenceNo`)
- UNIQUE KEY `WeeklyAccountAssignment_accountId_weekStartDate_key` (`accountId`,`weekStartDate`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `WeeklyAccountAssignment_salesmanId_recurrenceNextDate_idx` (`salesmanId`,`recurrenceNextDate`)
- CONSTRAINT `WeeklyAccountAssignment_accountId_fkey` FOREIGN KEY (`accountId`) REFERENCES `Account` (`id`) ON DELETE CASCADE ON UPDATE CASCADE

### Table: WeeklyBeatPlan

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| salesmanId | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| salesmanName | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| weekStartDate | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |
| weekEndDate | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |
| pincodes | json | NULL | NULL | - | json DEFAULT NULL |
| totalAreas | int | NOT NULL | '0' | - | int NOT NULL DEFAULT '0' |
| status | varchar(191) | NOT NULL | 'DRAFT' | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT' |
| generatedBy | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| approvedBy | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| approvedAt | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| lockedBy | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| lockedAt | datetime(3) | NULL | NULL | - | datetime(3) DEFAULT NULL |
| createdAt | datetime(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |
| updatedAt | datetime(3) | NOT NULL | - | - | datetime(3) NOT NULL |

#### Keys, Indexes, Constraints

- KEY `WeeklyBeatPlan_salesmanId_idx` (`salesmanId`)
- KEY `WeeklyBeatPlan_weekStartDate_idx` (`weekStartDate`)
- KEY `WeeklyBeatPlan_status_idx` (`status`)
- KEY `WeeklyBeatPlan_generatedBy_idx` (`generatedBy`)
- UNIQUE KEY `WeeklyBeatPlan_salesmanId_weekStartDate_key` (`salesmanId`,`weekStartDate`)
- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `WeeklyBeatPlan_approvedBy_fkey` (`approvedBy`)
- KEY `WeeklyBeatPlan_lockedBy_fkey` (`lockedBy`)
- CONSTRAINT `WeeklyBeatPlan_salesmanId_fkey` FOREIGN KEY (`salesmanId`) REFERENCES `User` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
- CONSTRAINT `WeeklyBeatPlan_generatedBy_fkey` FOREIGN KEY (`generatedBy`) REFERENCES `User` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
- CONSTRAINT `WeeklyBeatPlan_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `User` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
- CONSTRAINT `WeeklyBeatPlan_lockedBy_fkey` FOREIGN KEY (`lockedBy`) REFERENCES `User` (`id`) ON DELETE SET NULL ON UPDATE CASCADE

### Table: Zone

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| zone_id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| zone_name | varchar(100) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL |
| city_id | int | NOT NULL | - | - | int NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`zone_id`) /*T![clustered_index] CLUSTERED */
- KEY `Zone_city_id_fkey` (`city_id`)
- CONSTRAINT `Zone_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `City` (`city_id`) ON DELETE CASCADE ON UPDATE CASCADE

## Loagma New DB Schema

### Table: admin

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| userid | int | NOT NULL | - | AUTO_INCREMENT | int unsigned NOT NULL AUTO_INCREMENT |
| session_id | varchar(250) | N/A | '' | - | varchar(250) DEFAULT '' |
| username | varchar(250) | NOT NULL | - | - | varchar(250) NOT NULL |
| name | text | NOT NULL | - | - | text NOT NULL |
| password | varchar(60) | NOT NULL | - | - | varchar(60) NOT NULL |
| type | varchar(250) | NOT NULL | '' | - | varchar(250) NOT NULL DEFAULT '' |
| register_date | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| last_activity | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| data | text | NULL | NULL | - | text DEFAULT NULL |
| delivery_manage_by | varchar(255) | NOT NULL | 'SuperAdmin' | - | varchar(255) NOT NULL DEFAULT 'SuperAdmin' |
| org_name | varchar(255) | NULL | NULL | - | varchar(255) DEFAULT NULL |
| org_email | varchar(255) | NULL | NULL | - | varchar(255) DEFAULT NULL |
| org_contact_no | varchar(255) | NULL | NULL | - | varchar(255) DEFAULT NULL |
| org_gst | varchar(255) | NULL | NULL | - | varchar(255) DEFAULT NULL |
| org_address | text | NOT NULL | - | - | text NOT NULL |
| category_id | text | NULL | NULL | - | text DEFAULT NULL |
| city_id | varchar(255) | NULL | NULL | - | varchar(255) DEFAULT NULL |
| areas | text | NULL | NULL | - | text DEFAULT NULL |
| web_token | text | NULL | NULL | - | text DEFAULT NULL |
| commission | int | NULL | NULL | - | int DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`userid`) /*T![clustered_index] CLUSTERED */

### Table: bom_items

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| bom_item_id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint NOT NULL AUTO_INCREMENT |
| bom_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| raw_material_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| quantity_per_unit | decimal(10,3) | NOT NULL | - | - | decimal(10,3) NOT NULL |
| unit_type | varchar(20) | NOT NULL | - | COLLATE utf8mb4_0900_ai_ci | varchar(20) COLLATE utf8mb4_0900_ai_ci NOT NULL |
| wastage_percent | decimal(5,2) | N/A | '0.00' | - | decimal(5,2) DEFAULT '0.00' |
| created_at | datetime | N/A | CURRENT_TIMESTAMP | - | datetime DEFAULT CURRENT_TIMESTAMP |
| updated_at | datetime | N/A | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`bom_item_id`) /*T![clustered_index] CLUSTERED */
- KEY `fk_bom_items_bom` (`bom_id`)
- CONSTRAINT `fk_bom_items_bom` FOREIGN KEY (`bom_id`) REFERENCES `bom_master` (`bom_id`) ON DELETE RESTRICT ON UPDATE CASCADE

### Table: bom_master

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| bom_id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| product_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| bom_version | varchar(20) | NOT NULL | - | COLLATE utf8mb4_0900_ai_ci | varchar(20) COLLATE utf8mb4_0900_ai_ci NOT NULL |
| status | enum('DRAFT','APPROVED','LOCKED') | N/A | 'DRAFT' | COLLATE utf8mb4_0900_ai_ci | enum('DRAFT','APPROVED','LOCKED') COLLATE utf8mb4_0900_ai_ci DEFAULT 'DRAFT' |
| remarks | text | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | text COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| created_by | bigint | NULL | NULL | - | bigint DEFAULT NULL |
| approved_by | bigint | NULL | NULL | - | bigint DEFAULT NULL |
| created_at | datetime | N/A | CURRENT_TIMESTAMP | - | datetime DEFAULT CURRENT_TIMESTAMP |
| updated_at | datetime | N/A | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`bom_id`) /*T![clustered_index] CLUSTERED */
- UNIQUE KEY `uk_product_version` (`product_id`,`bom_version`)

### Table: brand

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| brand_id | int | NOT NULL | - | AUTO_INCREMENT | int unsigned NOT NULL AUTO_INCREMENT |
| name | text | NOT NULL | - | - | text NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`brand_id`) /*T![clustered_index] CLUSTERED */

### Table: BusinessType

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(10) | NOT NULL | - | - | varchar(10) NOT NULL |
| name | varchar(100) | NOT NULL | - | - | varchar(100) NOT NULL |
| createdAt | timestamp(3) | NOT NULL | CURRENT_TIMESTAMP(3) | - | timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: cache

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| key | varchar(255) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL |
| value | mediumtext | NOT NULL | - | COLLATE utf8mb4_unicode_ci | mediumtext COLLATE utf8mb4_unicode_ci NOT NULL |
| expiration | int | NOT NULL | - | - | int NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`key`) /*T![clustered_index] CLUSTERED */
- KEY `cache_expiration_index` (`expiration`)

### Table: cache_locks

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| key | varchar(255) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL |
| owner | varchar(255) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL |
| expiration | int | NOT NULL | - | - | int NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`key`) /*T![clustered_index] CLUSTERED */
- KEY `cache_locks_expiration_index` (`expiration`)

### Table: calling_staff

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| name | varchar(20) | NOT NULL | - | - | varchar(20) NOT NULL |
| contact_no | varchar(11) | NOT NULL | - | - | varchar(11) NOT NULL |
| type | varchar(30) | NOT NULL | - | COMMENT | varchar(30) NOT NULL COMMENT 'tele-marketer, converter, Cold caller, etc' |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- UNIQUE KEY `unique_contactNumber` (`contact_no`)

### Table: cart

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| cart_id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| userid | bigint | NOT NULL | - | - | bigint NOT NULL |
| addressId | int | NOT NULL | - | - | int NOT NULL |
| product_id | bigint | NOT NULL | - | - | bigint NOT NULL |
| vendor_product_id | int | NOT NULL | '0' | - | int NOT NULL DEFAULT '0' |
| pack_id | varchar(255) | NOT NULL | - | - | varchar(255) NOT NULL |
| quantity | smallint | NOT NULL | '0' | - | smallint unsigned NOT NULL DEFAULT '0' |
| total | decimal(10,2) | NOT NULL | '0.00' | - | decimal(10,2) NOT NULL DEFAULT '0.00' |
| ctype_id | varchar(250) | NOT NULL | 'vegetables_fruits' | - | varchar(250) NOT NULL DEFAULT 'vegetables_fruits' |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | - | timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`cart_id`) /*T![clustered_index] CLUSTERED */
- UNIQUE KEY `unique_user_product_pack_address` (`userid`,`product_id`,`pack_id`,`addressId`)

### Table: cart_type

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| cart_tid | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| type_name | text | NOT NULL | - | - | text NOT NULL |
| ctype_id | text | NOT NULL | - | - | text NOT NULL |
| is_used | tinyint | NOT NULL | '0' | - | tinyint unsigned NOT NULL DEFAULT '0' |
| has_express | tinyint | NOT NULL | '0' | - | tinyint unsigned NOT NULL DEFAULT '0' |
| express_charge | decimal(10,2) | NOT NULL | '0.00' | - | decimal(10,2) unsigned NOT NULL DEFAULT '0.00' |
| min_total | decimal(10,2) | NOT NULL | '0.00' | - | decimal(10,2) unsigned NOT NULL DEFAULT '0.00' |
| delivery_charge | decimal(10,2) | NOT NULL | '0.00' | - | decimal(10,2) unsigned NOT NULL DEFAULT '0.00' |
| note | text | NOT NULL | - | - | text NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`cart_tid`) /*T![clustered_index] CLUSTERED */

### Table: categories

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| cat_id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| name | varchar(250) | NOT NULL | - | - | varchar(250) NOT NULL |
| parent_cat_id | int | NOT NULL | - | - | int unsigned NOT NULL |
| is_active | tinyint | NOT NULL | '0' | - | tinyint unsigned NOT NULL DEFAULT '0' |
| type | tinyint | NOT NULL | '0' | COMMENT | tinyint NOT NULL DEFAULT '0' COMMENT '0:Has_subcategories, 1: Has_products' |
| image_slug | varchar(15) | N/A | ' ' | - | varchar(15) DEFAULT ' ' |
| image_name | text | NULL | NULL | - | text DEFAULT NULL |
| img_last_updated | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`cat_id`) /*T![clustered_index] CLUSTERED */

### Table: daily_book_stock

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| vendor_product_id | int | NOT NULL | - | - | int NOT NULL |
| date | date | NOT NULL | - | - | date NOT NULL |
| closing_stock | decimal(10,2) | NOT NULL | '0.00' | - | decimal(10,2) NOT NULL DEFAULT '0.00' |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | - | timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP |
| updated_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- UNIQUE KEY `unique_product_date` (`vendor_product_id`,`date`)
- KEY `idx_product_date` (`vendor_product_id`,`date`)
- KEY `idx_date` (`date`)

### Table: deli_staff

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| deli_id | int | NOT NULL | - | AUTO_INCREMENT | int unsigned NOT NULL AUTO_INCREMENT |
| admin_id | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| role | varchar(20) | NOT NULL | 'driver' | - | varchar(20) NOT NULL DEFAULT 'driver' |
| name | text | NOT NULL | - | - | text NOT NULL |
| mobile | varchar(20) | NOT NULL | - | - | varchar(20) NOT NULL |
| password | varchar(250) | NULL | NULL | - | varchar(250) DEFAULT NULL |
| sess_id | varchar(250) | NULL | NULL | - | varchar(250) DEFAULT NULL |
| lat | double(10,8) | NULL | NULL | - | double(10,8) DEFAULT NULL |
| lng | double(11,8) | NULL | NULL | - | double(11,8) DEFAULT NULL |
| location_last_updated | timestamp | NOT NULL | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| is_locked | tinyint | NOT NULL | '0' | - | tinyint unsigned NOT NULL DEFAULT '0' |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`deli_id`) /*T![clustered_index] CLUSTERED */
- UNIQUE KEY `mobile` (`mobile`)

### Table: department

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(10) | NOT NULL | - | - | varchar(10) NOT NULL |
| name | varchar(100) | NOT NULL | - | - | varchar(100) NOT NULL |
| createdAt | timestamp(3) | N/A | CURRENT_TIMESTAMP(3) | - | timestamp(3) DEFAULT CURRENT_TIMESTAMP(3) |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: driver_accountability_log

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| driver_deli_id | int | NOT NULL | - | COMMENT | int NOT NULL COMMENT 'References deli_staff.deli_id (the driver being held accountable)' |
| trip_id | int | NOT NULL | - | - | int NOT NULL |
| audit_log_id | int | NOT NULL | - | - | int NOT NULL |
| item_id | int | NOT NULL | - | - | int NOT NULL |
| vendor_product_id | int | NOT NULL | - | - | int NOT NULL |
| product_id | int | NOT NULL | - | - | int NOT NULL |
| loss_type | enum('theft','lost','damaged','unreturned','other') | NOT NULL | - | COLLATE utf8mb4_unicode_ci | enum('theft','lost','damaged','unreturned','other') COLLATE utf8mb4_unicode_ci NOT NULL |
| quantity_lost | decimal(10,2) | NOT NULL | - | - | decimal(10,2) NOT NULL |
| unit_type | varchar(20) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| monetary_value | decimal(10,2) | NOT NULL | - | - | decimal(10,2) NOT NULL |
| penalty_status | enum('pending','applied','waived','disputed') | N/A | 'pending' | COLLATE utf8mb4_unicode_ci | enum('pending','applied','waived','disputed') COLLATE utf8mb4_unicode_ci DEFAULT 'pending' |
| penalty_applied_at | datetime | NULL | NULL | - | datetime DEFAULT NULL |
| penalty_applied_by | int | NULL | NULL | - | int DEFAULT NULL |
| loss_notes | text | NULL | NULL | COLLATE utf8mb4_unicode_ci | text COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| resolution_notes | text | NULL | NULL | COLLATE utf8mb4_unicode_ci | text COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| created_at | datetime | N/A | CURRENT_TIMESTAMP | - | datetime DEFAULT CURRENT_TIMESTAMP |
| updated_at | datetime | N/A | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `idx_driver` (`driver_deli_id`)
- KEY `idx_trip` (`trip_id`)
- KEY `idx_audit_log` (`audit_log_id`)

### Table: driver_rating

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| rating_id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| order_id | bigint | NOT NULL | - | - | bigint NOT NULL |
| user_id | bigint | NULL | NULL | - | bigint DEFAULT NULL |
| rating | int | NOT NULL | - | - | int NOT NULL |
| review_text | text | NULL | NULL | - | text DEFAULT NULL |
| review_type | enum('delivered','cancelled') | NOT NULL | - | - | enum('delivered','cancelled') NOT NULL |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | - | timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`order_id`) /*T![clustered_index] CLUSTERED */
- UNIQUE KEY `rating_id` (`rating_id`)

### Table: failed_jobs

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| uuid | varchar(255) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL |
| connection | text | NOT NULL | - | COLLATE utf8mb4_unicode_ci | text COLLATE utf8mb4_unicode_ci NOT NULL |
| queue | text | NOT NULL | - | COLLATE utf8mb4_unicode_ci | text COLLATE utf8mb4_unicode_ci NOT NULL |
| payload | longtext | NOT NULL | - | COLLATE utf8mb4_unicode_ci | longtext COLLATE utf8mb4_unicode_ci NOT NULL |
| exception | longtext | NOT NULL | - | COLLATE utf8mb4_unicode_ci | longtext COLLATE utf8mb4_unicode_ci NOT NULL |
| failed_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | - | timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`)

### Table: hsn_codes

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| hsn_code | varchar(50) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL |
| is_active | tinyint(1) | NOT NULL | '1' | - | tinyint(1) NOT NULL DEFAULT '1' |
| created_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |
| updated_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: inventory_op

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| op_id | int | NOT NULL | - | - | int unsigned NOT NULL |
| product_id | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| op_type | varchar(255) | NOT NULL | 'inbound' | COMMENT; COLLATE utf8_unicode_ci | varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'inbound' COMMENT 'purchase, sale, damage, expire, free' |
| quantity | decimal(10,2) | NOT NULL | '0.00' | - | decimal(10,2) NOT NULL DEFAULT '0.00' |
| unit_type | text | NULL | NULL | COLLATE utf8_unicode_ci | text COLLATE utf8_unicode_ci DEFAULT NULL |
| unitquantity | decimal(10,2) | NOT NULL | '0.00' | - | decimal(10,2) NOT NULL DEFAULT '0.00' |
| amount | decimal(10,2) | NOT NULL | '0.00' | - | decimal(10,2) NOT NULL DEFAULT '0.00' |
| op_date | date | NOT NULL | - | - | date NOT NULL |
| note | text | NOT NULL | - | COLLATE utf8_unicode_ci | text COLLATE utf8_unicode_ci NOT NULL |
| updated_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | - | timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`op_id`) /*T![clustered_index] CLUSTERED */

### Table: issue_to_production

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| issue_id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| status | enum('DRAFT','ISSUED','COMPLETED','CANCELLED') | N/A | 'DRAFT' | COLLATE utf8mb4_0900_ai_ci | enum('DRAFT','ISSUED','COMPLETED','CANCELLED') COLLATE utf8mb4_0900_ai_ci DEFAULT 'DRAFT' |
| remarks | text | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | text COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| issued_by | bigint | NULL | NULL | - | bigint DEFAULT NULL |
| issued_at | datetime | NULL | NULL | - | datetime DEFAULT NULL |
| created_at | datetime | N/A | CURRENT_TIMESTAMP | - | datetime DEFAULT CURRENT_TIMESTAMP |
| updated_at | datetime | N/A | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`issue_id`) /*T![clustered_index] CLUSTERED */
- KEY `idx_issue_status` (`status`)
- KEY `idx_issue_created` (`created_at`)

### Table: issue_to_production_items

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| issue_item_id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| issue_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| raw_material_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| quantity | decimal(10,3) | NOT NULL | - | - | decimal(10,3) NOT NULL |
| unit_type | varchar(20) | NOT NULL | - | COLLATE utf8mb4_0900_ai_ci | varchar(20) COLLATE utf8mb4_0900_ai_ci NOT NULL |
| created_at | datetime | N/A | CURRENT_TIMESTAMP | - | datetime DEFAULT CURRENT_TIMESTAMP |
| updated_at | datetime | N/A | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`issue_item_id`) /*T![clustered_index] CLUSTERED */
- KEY `fk_issue_items_issue` (`issue_id`)
- KEY `fk_issue_items_material` (`raw_material_id`)
- CONSTRAINT `fk_issue_items_issue` FOREIGN KEY (`issue_id`) REFERENCES `issue_to_production` (`issue_id`)
- CONSTRAINT `fk_issue_items_material` FOREIGN KEY (`raw_material_id`) REFERENCES `product` (`product_id`)

### Table: job_batches

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(255) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL |
| name | varchar(255) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL |
| total_jobs | int | NOT NULL | - | - | int NOT NULL |
| pending_jobs | int | NOT NULL | - | - | int NOT NULL |
| failed_jobs | int | NOT NULL | - | - | int NOT NULL |
| failed_job_ids | longtext | NOT NULL | - | COLLATE utf8mb4_unicode_ci | longtext COLLATE utf8mb4_unicode_ci NOT NULL |
| options | mediumtext | NULL | NULL | COLLATE utf8mb4_unicode_ci | mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| cancelled_at | int | NULL | NULL | - | int DEFAULT NULL |
| created_at | int | NOT NULL | - | - | int NOT NULL |
| finished_at | int | NULL | NULL | - | int DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: jobs

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| queue | varchar(255) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL |
| payload | longtext | NOT NULL | - | COLLATE utf8mb4_unicode_ci | longtext COLLATE utf8mb4_unicode_ci NOT NULL |
| attempts | tinyint | NOT NULL | - | - | tinyint unsigned NOT NULL |
| reserved_at | int | NULL | NULL | - | int unsigned DEFAULT NULL |
| available_at | int | NOT NULL | - | - | int unsigned NOT NULL |
| created_at | int | NOT NULL | - | - | int unsigned NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `jobs_queue_index` (`queue`)

### Table: master_orders

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| user_id | int | NOT NULL | - | - | int NOT NULL |
| txn_id | varchar(255) | NOT NULL | - | - | varchar(255) NOT NULL |
| payment_status | varchar(255) | NOT NULL | - | - | varchar(255) NOT NULL |
| order_count | int | NOT NULL | - | - | int NOT NULL |
| payment_method | varchar(255) | NOT NULL | - | - | varchar(255) NOT NULL |
| delivery_info | text | NOT NULL | - | - | text NOT NULL |
| order_total | float(10,2) | NOT NULL | - | - | float(10,2) NOT NULL |
| delivery_charge | float(10,2) | NOT NULL | - | - | float(10,2) NOT NULL |
| discount | float(10,2) | NOT NULL | - | - | float(10,2) NOT NULL |
| before_discount | float(10,2) | NOT NULL | - | - | float(10,2) NOT NULL |
| status | enum('1','0') | NOT NULL | - | - | enum('1','0') NOT NULL |
| created_at | datetime | NOT NULL | - | - | datetime NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: migrations

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | AUTO_INCREMENT | int unsigned NOT NULL AUTO_INCREMENT |
| migration | varchar(255) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL |
| batch | int | NOT NULL | - | - | int NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: offer_log

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | - | int NOT NULL |
| user_id | int | NOT NULL | - | - | int NOT NULL |
| order_id | int | NOT NULL | - | - | int NOT NULL |
| offer_id | int | NOT NULL | - | - | int NOT NULL |
| used_date | date | NOT NULL | - | - | date NOT NULL |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | - | timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `idx_user_offer_date` (`user_id`,`offer_id`,`used_date`)

### Table: offers

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| off_id | bigint | NOT NULL | - | - | bigint NOT NULL |
| name | text | NULL | NULL | - | text DEFAULT NULL |
| off_type | varchar(250) | NOT NULL | ' ' | - | varchar(250) NOT NULL DEFAULT ' ' |
| product_id | bigint | N/A | '0' | COMMENT | bigint DEFAULT '0' COMMENT 'vendorProductId' |
| off_data | text | NULL | NULL | - | text DEFAULT NULL |
| is_active | tinyint | NOT NULL | '0' | - | tinyint NOT NULL DEFAULT '0' |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`off_id`) /*T![clustered_index] CLUSTERED */

### Table: orders

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| order_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| bill_number | int | NULL | NULL | - | int DEFAULT NULL |
| master_order_id | int | NOT NULL | '0' | - | int NOT NULL DEFAULT '0' |
| txn_id | varchar(250) | NOT NULL | - | - | varchar(250) NOT NULL |
| buyer_userid | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| start_time | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| last_update_time | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| short_datetime | text | NOT NULL | - | - | text NOT NULL |
| order_state | varchar(250) | NOT NULL | - | - | varchar(250) NOT NULL |
| payment_method | varchar(250) | NOT NULL | 'cod' | - | varchar(250) NOT NULL DEFAULT 'cod' |
| ctype_id | varchar(250) | NOT NULL | 'vegetables_fruits' | - | varchar(250) NOT NULL DEFAULT 'vegetables_fruits' |
| items_count | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| delivery_charge | decimal(10,0) | NOT NULL | '0' | - | decimal(10,0) NOT NULL DEFAULT '0' |
| order_total | decimal(12,2) | NOT NULL | '0.00' | - | decimal(12,2) unsigned NOT NULL DEFAULT '0.00' |
| bill_amount | int | NULL | NULL | - | int DEFAULT NULL |
| delivery_info | text | NOT NULL | - | - | text NOT NULL |
| area_name | text | NOT NULL | - | - | text NOT NULL |
| feedback | varchar(100) | NOT NULL | - | - | varchar(100) NOT NULL |
| admin_id | bigint | NOT NULL | '0' | - | bigint unsigned NOT NULL DEFAULT '0' |
| payment_status | varchar(250) | NOT NULL | 'not_paid' | - | varchar(250) NOT NULL DEFAULT 'not_paid' |
| amountReceivedInfo | longtext | NULL | NULL | COLLATE utf8mb4_bin | longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL |
| trip_id | int | NULL | NULL | - | int DEFAULT NULL |
| discount | decimal(10,2) | NOT NULL | '0.00' | - | decimal(10,2) NOT NULL DEFAULT '0.00' |
| before_discount | decimal(10,2) | NOT NULL | '0.00' | - | decimal(10,2) NOT NULL DEFAULT '0.00' |
| time_slot | varchar(250) | NOT NULL | 'Now' | - | varchar(250) NOT NULL DEFAULT 'Now' |
| delivered_time | int | NULL | NULL | - | int DEFAULT NULL |
| deli_id | int | NULL | NULL | - | int DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`order_id`) /*T![clustered_index] CLUSTERED */

### Table: orders_item

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| order_id | bigint | NOT NULL | '0' | - | bigint unsigned NOT NULL DEFAULT '0' |
| item_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| product_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| vendor_product_id | int | NULL | NULL | - | int DEFAULT NULL |
| pinfo | text | NOT NULL | - | - | text NOT NULL |
| offers | text | NULL | NULL | - | text DEFAULT NULL |
| quantity | mediumint | NOT NULL | '0' | - | mediumint unsigned NOT NULL DEFAULT '0' |
| qty_loaded | int | NULL | NULL | - | int DEFAULT NULL |
| qty_delivered | int | NULL | NULL | - | int DEFAULT NULL |
| qty_returned | int | NULL | NULL | - | int DEFAULT NULL |
| item_price | decimal(12,2) | NOT NULL | '0.00' | - | decimal(12,2) unsigned NOT NULL DEFAULT '0.00' |
| item_total | decimal(12,2) | NOT NULL | '0.00' | - | decimal(12,2) unsigned NOT NULL DEFAULT '0.00' |
| op_id | bigint | N/A | '0' | - | bigint DEFAULT '0' |
| commission | double(10,2) | NOT NULL | - | - | double(10,2) NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`item_id`) /*T![clustered_index] CLUSTERED */

### Table: otp

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| contactno | varchar(30) | NOT NULL | - | - | varchar(30) NOT NULL |
| slug | varchar(16) | NOT NULL | - | - | varchar(16) NOT NULL |
| otp_num | varchar(10) | NOT NULL | - | - | varchar(10) NOT NULL |
| otp_time | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| purpose | varchar(250) | NOT NULL | - | - | varchar(250) NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`contactno`) /*T![clustered_index] CLUSTERED */

### Table: password_reset_tokens

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| email | varchar(255) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL |
| token | varchar(255) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL |
| created_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`email`) /*T![clustered_index] CLUSTERED */

### Table: physical_stock

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | - | int NOT NULL |
| vendor_product_id | int | NOT NULL | - | - | int NOT NULL |
| stock | double | NOT NULL | - | - | double NOT NULL |
| last_updated_at | datetime | N/A | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| note | text | NULL | NULL | - | text DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `vendor_product_id` (`vendor_product_id`)

### Table: product

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| product_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| cat_id | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| parent_cat_id | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| brand | text | NOT NULL | - | - | text NOT NULL |
| ctype_id | varchar(250) | NOT NULL | 'vegetables_fruits' | - | varchar(250) NOT NULL DEFAULT 'vegetables_fruits' |
| seq_no | int | N/A | '0' | - | int unsigned DEFAULT '0' |
| start_date | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| is_published | tinyint | NOT NULL | '0' | - | tinyint unsigned NOT NULL DEFAULT '0' |
| is_used | tinyint | NOT NULL | '0' | - | tinyint NOT NULL DEFAULT '0' |
| is_deleted | tinyint | NOT NULL | '0' | - | tinyint NOT NULL DEFAULT '0' |
| in_stock | tinyint | NOT NULL | '0' | - | tinyint unsigned NOT NULL DEFAULT '0' |
| inventory_type | enum('SINGLE','PACK_WISE') | NOT NULL | 'SINGLE' | - | enum('SINGLE','PACK_WISE') NOT NULL DEFAULT 'SINGLE' |
| inventory_unit_type | varchar(255) | NOT NULL | 'WEIGHT' | - | varchar(255) NOT NULL DEFAULT 'WEIGHT' |
| name | text | NOT NULL | - | - | text NOT NULL |
| description | text | NOT NULL | - | - | text NOT NULL |
| display_photo | text | NULL | NULL | - | text DEFAULT NULL |
| keywords | text | NULL | NULL | - | text DEFAULT NULL |
| spec_params | text | NOT NULL | - | - | text NOT NULL |
| packs | text | NULL | NULL | - | text DEFAULT NULL |
| default_pack_id | varchar(255) | NOT NULL | ' ' | - | varchar(255) NOT NULL DEFAULT ' ' |
| hsn_code | varchar(10) | NOT NULL | - | - | varchar(10) NOT NULL |
| gst_percent | decimal(5,2) | NOT NULL | - | - | decimal(5,2) NOT NULL |
| offers | text | NULL | NULL | - | text DEFAULT NULL |
| cache_txt | mediumtext | NULL | NULL | - | mediumtext DEFAULT NULL |
| img_last_updated | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| stock | decimal(10,3) | NULL | NULL | - | decimal(10,3) DEFAULT NULL |
| stock_ut_id | varchar(100) | NULL | NULL | - | varchar(100) DEFAULT NULL |
| order_limit | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| buffer_limit | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| product_pack_count | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| nop | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| pack_prd_wt | decimal(12,3) | NULL | NULL | - | decimal(12,3) DEFAULT NULL |
| gross_wt_of_pack | decimal(12,3) | NULL | NULL | - | decimal(12,3) DEFAULT NULL |
| gst_tax_type | varchar(50) | NULL | NULL | - | varchar(50) DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`product_id`) /*T![clustered_index] CLUSTERED */

### Table: product_photos

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| product_id | bigint | NOT NULL | '0' | - | bigint unsigned NOT NULL DEFAULT '0' |
| photo_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| file_location | varchar(250) | NOT NULL | '0' | - | varchar(250) NOT NULL DEFAULT '0' |
| photo_slug | varchar(10) | NOT NULL | '0000' | - | varchar(10) NOT NULL DEFAULT '0000' |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`photo_id`) /*T![clustered_index] CLUSTERED */

### Table: product_purchase

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| item_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| day_id | varchar(20) | NOT NULL | '01-01-2018' | - | varchar(20) NOT NULL DEFAULT '01-01-2018' |
| product_id | bigint | NOT NULL | '0' | - | bigint unsigned NOT NULL DEFAULT '0' |
| quantity | decimal(10,2) | NOT NULL | '0.00' | - | decimal(10,2) unsigned NOT NULL DEFAULT '0.00' |
| unit_id | text | NOT NULL | - | - | text NOT NULL |
| cost | decimal(10,2) | NOT NULL | '0.00' | - | decimal(10,2) NOT NULL DEFAULT '0.00' |
| post_date | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`item_id`) /*T![clustered_index] CLUSTERED */
- UNIQUE KEY `day_id` (`day_id`,`product_id`)

### Table: product_taxes

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| product_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| tax_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| tax_percent | decimal(5,2) | NOT NULL | - | - | decimal(5,2) NOT NULL |
| created_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |
| updated_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `product_taxes_product_id_foreign` (`product_id`)
- KEY `product_taxes_tax_id_foreign` (`tax_id`)
- UNIQUE KEY `product_taxes_product_id_tax_id_unique` (`product_id`,`tax_id`)
- KEY `product_taxes_product_id_index` (`product_id`)
- KEY `product_taxes_tax_id_index` (`tax_id`)
- CONSTRAINT `product_taxes_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE
- CONSTRAINT `product_taxes_tax_id_foreign` FOREIGN KEY (`tax_id`) REFERENCES `taxes` (`id`) ON DELETE CASCADE

### Table: products

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| name | varchar(255) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL |
| sku | varchar(255) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| description | text | NULL | NULL | COLLATE utf8mb4_unicode_ci | text COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| price | decimal(10,2) | NOT NULL | '0.00' | - | decimal(10,2) NOT NULL DEFAULT '0.00' |
| stock | int | NOT NULL | '0' | - | int NOT NULL DEFAULT '0' |
| created_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |
| updated_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- UNIQUE KEY `products_sku_unique` (`sku`)

### Table: promo

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| promo_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| title | varchar(250) | NULL | NULL | - | varchar(250) DEFAULT NULL |
| description | text | NULL | NULL | - | text DEFAULT NULL |
| ctype_id | varchar(250) | NOT NULL | 'all' | - | varchar(250) NOT NULL DEFAULT 'all' |
| discount | decimal(10,3) | NOT NULL | '0.000' | - | decimal(10,3) NOT NULL DEFAULT '0.000' |
| max_use | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| from | datetime(6) | NULL | NULL | - | datetime(6) DEFAULT NULL |
| to | datetime(6) | NULL | NULL | - | datetime(6) DEFAULT NULL |
| status | tinyint | NOT NULL | '0' | - | tinyint NOT NULL DEFAULT '0' |
| promo_data | text | NOT NULL | - | COMMENT | text NOT NULL COMMENT 'amount, percentage, percentage_up_to, ladder' |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`promo_id`) /*T![clustered_index] CLUSTERED */

### Table: promo_log

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| log_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| order_id | bigint | N/A | '0' | - | bigint unsigned DEFAULT '0' |
| userid | bigint | N/A | '0' | - | bigint unsigned DEFAULT '0' |
| promo_id | bigint | N/A | '0' | - | bigint unsigned DEFAULT '0' |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`log_id`) /*T![clustered_index] CLUSTERED */

### Table: purchase_order_items

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| purchase_order_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| product_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| line_no | int | NOT NULL | - | - | int unsigned NOT NULL |
| unit | varchar(20) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| quantity | decimal(12,3) | NOT NULL | - | - | decimal(12,3) NOT NULL |
| price | decimal(12,2) | NOT NULL | - | - | decimal(12,2) NOT NULL |
| discount_percent | decimal(5,2) | NULL | NULL | - | decimal(5,2) DEFAULT NULL |
| tax_percent | decimal(5,2) | NULL | NULL | - | decimal(5,2) DEFAULT NULL |
| line_total | decimal(14,2) | NOT NULL | - | - | decimal(14,2) NOT NULL |
| description | text | NULL | NULL | COLLATE utf8mb4_unicode_ci | text COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| created_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |
| updated_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `purchase_order_items_purchase_order_id_foreign` (`purchase_order_id`)
- KEY `purchase_order_items_product_id_foreign` (`product_id`)
- KEY `purchase_order_items_purchase_order_id_product_id_index` (`purchase_order_id`,`product_id`)
- CONSTRAINT `purchase_order_items_purchase_order_id_foreign` FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`) ON DELETE CASCADE
- CONSTRAINT `purchase_order_items_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`)

### Table: purchase_orders

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| po_number | varchar(50) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL |
| financial_year | varchar(10) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL |
| supplier_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| salesman_id | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| department_id | varchar(10) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| doc_date | date | NOT NULL | - | - | date NOT NULL |
| expected_date | date | NULL | NULL | - | date DEFAULT NULL |
| status | enum('DRAFT','SENT','PARTIALLY_RECEIVED','CLOSED','CANCELLED') | NOT NULL | 'DRAFT' | COLLATE utf8mb4_unicode_ci | enum('DRAFT','SENT','PARTIALLY_RECEIVED','CLOSED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT' |
| narration | text | NULL | NULL | COLLATE utf8mb4_unicode_ci | text COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| created_by | bigint | NULL | NULL | - | bigint unsigned DEFAULT NULL |
| updated_by | bigint | NULL | NULL | - | bigint unsigned DEFAULT NULL |
| total_amount | decimal(14,2) | NOT NULL | '0' | - | decimal(14,2) NOT NULL DEFAULT '0' |
| charges_total | decimal(14,2) | NOT NULL | '0' | - | decimal(14,2) NOT NULL DEFAULT '0' |
| charges_json | json | NULL | NULL | - | json DEFAULT NULL |
| total_with_charges | decimal(14,2) | NOT NULL | '0' | - | decimal(14,2) NOT NULL DEFAULT '0' |
| created_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |
| updated_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `purchase_orders_supplier_id_foreign` (`supplier_id`)
- KEY `purchase_orders_supplier_id_index` (`supplier_id`)
- KEY `purchase_orders_status_index` (`status`)
- KEY `purchase_orders_doc_date_index` (`doc_date`)
- UNIQUE KEY `purchase_orders_po_number_unique` (`po_number`)
- KEY `purchase_orders_salesman_id_index` (`salesman_id`)
- KEY `purchase_orders_department_id_index` (`department_id`)
- CONSTRAINT `purchase_orders_supplier_id_foreign` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`)

### Table: purchase_voucher_items

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| purchase_voucher_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| source_purchase_order_id | bigint | NULL | NULL | - | bigint unsigned DEFAULT NULL |
| source_po_number | varchar(100) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| product_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| line_no | int | NOT NULL | '1' | - | int unsigned NOT NULL DEFAULT '1' |
| product_name | varchar(255) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| product_code | varchar(100) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| alias | varchar(255) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| unit | varchar(20) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| quantity | decimal(12,3) | NOT NULL | '0' | - | decimal(12,3) NOT NULL DEFAULT '0' |
| unit_price | decimal(12,2) | NOT NULL | '0' | - | decimal(12,2) NOT NULL DEFAULT '0' |
| taxable_amount | decimal(14,2) | NOT NULL | '0' | - | decimal(14,2) NOT NULL DEFAULT '0' |
| sgst | decimal(12,2) | NOT NULL | '0' | - | decimal(12,2) NOT NULL DEFAULT '0' |
| cgst | decimal(12,2) | NOT NULL | '0' | - | decimal(12,2) NOT NULL DEFAULT '0' |
| igst | decimal(12,2) | NOT NULL | '0' | - | decimal(12,2) NOT NULL DEFAULT '0' |
| cess | decimal(12,2) | NOT NULL | '0' | - | decimal(12,2) NOT NULL DEFAULT '0' |
| roff | decimal(12,2) | NOT NULL | '0' | - | decimal(12,2) NOT NULL DEFAULT '0' |
| value | decimal(14,2) | NOT NULL | '0' | - | decimal(14,2) NOT NULL DEFAULT '0' |
| purchase_account | varchar(255) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| gst_itc_eligibility | varchar(255) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| created_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |
| updated_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `purchase_voucher_items_purchase_voucher_id_foreign` (`purchase_voucher_id`)
- KEY `purchase_voucher_items_product_id_foreign` (`product_id`)
- KEY `purchase_voucher_items_purchase_voucher_id_product_id_index` (`purchase_voucher_id`,`product_id`)
- KEY `purchase_voucher_items_source_purchase_order_id_index` (`source_purchase_order_id`)
- CONSTRAINT `purchase_voucher_items_purchase_voucher_id_foreign` FOREIGN KEY (`purchase_voucher_id`) REFERENCES `purchase_vouchers` (`id`) ON DELETE CASCADE
- CONSTRAINT `purchase_voucher_items_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`)

### Table: purchase_vouchers

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| doc_no_prefix | varchar(20) | NOT NULL | '25-26/' | COLLATE utf8mb4_unicode_ci | varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '25-26/' |
| doc_no_number | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| doc_no | varchar(80) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| vendor_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| purchase_order_id | bigint | NULL | NULL | - | bigint unsigned DEFAULT NULL |
| doc_date | date | NOT NULL | - | - | date NOT NULL |
| bill_no | varchar(100) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL |
| bill_date | date | NULL | NULL | - | date DEFAULT NULL |
| narration | text | NULL | NULL | COLLATE utf8mb4_unicode_ci | text COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| do_not_update_inventory | tinyint(1) | NOT NULL | '0' | - | tinyint(1) NOT NULL DEFAULT '0' |
| purchase_type | varchar(50) | NOT NULL | 'Regular' | COLLATE utf8mb4_unicode_ci | varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Regular' |
| gst_reverse_charge | varchar(4) | NOT NULL | 'N' | COLLATE utf8mb4_unicode_ci | varchar(4) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N' |
| purchase_agent_id | varchar(100) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| status | enum('DRAFT','POSTED','CANCELLED') | NOT NULL | 'DRAFT' | COLLATE utf8mb4_unicode_ci | enum('DRAFT','POSTED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT' |
| items_total | decimal(14,2) | NOT NULL | '0' | - | decimal(14,2) NOT NULL DEFAULT '0' |
| charges_total | decimal(14,2) | NOT NULL | '0' | - | decimal(14,2) NOT NULL DEFAULT '0' |
| net_total | decimal(14,2) | NOT NULL | '0' | - | decimal(14,2) NOT NULL DEFAULT '0' |
| charges_json | json | NULL | NULL | - | json DEFAULT NULL |
| created_by | bigint | NULL | NULL | - | bigint unsigned DEFAULT NULL |
| updated_by | bigint | NULL | NULL | - | bigint unsigned DEFAULT NULL |
| created_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |
| updated_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `purchase_vouchers_vendor_id_foreign` (`vendor_id`)
- KEY `purchase_vouchers_purchase_order_id_foreign` (`purchase_order_id`)
- UNIQUE KEY `purchase_vouchers_doc_no_prefix_doc_no_number_unique` (`doc_no_prefix`,`doc_no_number`)
- KEY `purchase_vouchers_vendor_id_index` (`vendor_id`)
- KEY `purchase_vouchers_doc_date_index` (`doc_date`)
- KEY `purchase_vouchers_doc_no_index` (`doc_no`)
- KEY `purchase_vouchers_status_index` (`status`)
- CONSTRAINT `purchase_vouchers_vendor_id_foreign` FOREIGN KEY (`vendor_id`) REFERENCES `suppliers` (`id`)
- CONSTRAINT `purchase_vouchers_purchase_order_id_foreign` FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`) ON DELETE SET NULL

### Table: receive_from_production

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| status | enum('DRAFT','RECEIVED') | NOT NULL | 'DRAFT' | COLLATE utf8mb4_unicode_ci | enum('DRAFT','RECEIVED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT' |
| remarks | text | NULL | NULL | COLLATE utf8mb4_unicode_ci | text COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| received_at | datetime | NULL | NULL | - | datetime DEFAULT NULL |
| created_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |
| updated_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: receive_from_production_items

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| receive_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| finished_product_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| quantity | decimal(10,3) | NOT NULL | - | - | decimal(10,3) NOT NULL |
| unit_type | varchar(20) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL |
| created_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |
| updated_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `receive_from_production_items_receive_id_foreign` (`receive_id`)
- KEY `receive_from_production_items_finished_product_id_foreign` (`finished_product_id`)
- CONSTRAINT `receive_from_production_items_finished_product_id_foreign` FOREIGN KEY (`finished_product_id`) REFERENCES `product` (`product_id`)
- CONSTRAINT `receive_from_production_items_receive_id_foreign` FOREIGN KEY (`receive_id`) REFERENCES `receive_from_production` (`id`) ON DELETE CASCADE

### Table: roles

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| name | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| createdAt | datetime | NOT NULL | CURRENT_TIMESTAMP | - | datetime NOT NULL DEFAULT CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- UNIQUE KEY `roles_name_unique` (`name`)

### Table: search

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| s.no | int | NOT NULL | - | - | int NOT NULL |
| user_id | int | NOT NULL | - | - | int NOT NULL |
| search_text | varchar(200) | NOT NULL | - | COLLATE utf8mb4_general_ci | varchar(200) COLLATE utf8mb4_general_ci NOT NULL |
| count | int | NOT NULL | - | COMMENT | int NOT NULL COMMENT 'no. of times this searchText has been used' |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | - | timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`s.no`) /*T![clustered_index] CLUSTERED */

### Table: sessions

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(255) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL |
| user_id | bigint | NULL | NULL | - | bigint unsigned DEFAULT NULL |
| ip_address | varchar(45) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| user_agent | text | NULL | NULL | COLLATE utf8mb4_unicode_ci | text COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| payload | longtext | NOT NULL | - | COLLATE utf8mb4_unicode_ci | longtext COLLATE utf8mb4_unicode_ci NOT NULL |
| last_activity | int | NOT NULL | - | - | int NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `sessions_user_id_index` (`user_id`)
- KEY `sessions_last_activity_index` (`last_activity`)

### Table: stock_audit_log

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| vendor_product_id | int | NOT NULL | - | - | int NOT NULL |
| trigger_pack_id | varchar(255) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL |
| pack_updates | json | NOT NULL | - | - | json NOT NULL |
| reason | varchar(500) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL |
| user_id | int | NULL | NULL | - | int DEFAULT NULL |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | - | timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `stock_audit_log_created_at_index` (`created_at`)
- KEY `stock_audit_log_vendor_product_id_created_at_index` (`vendor_product_id`,`created_at`)
- KEY `stock_audit_log_vendor_product_id_index` (`vendor_product_id`)
- KEY `stock_audit_log_trigger_pack_id_index` (`trigger_pack_id`)
- KEY `stock_audit_log_user_id_index` (`user_id`)

### Table: stock_count

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | - | int NOT NULL |
| assignment_id | int | NOT NULL | - | - | int NOT NULL |
| vendor_product_id | int | NOT NULL | - | - | int NOT NULL |
| counted_quantity | double | NOT NULL | - | - | double NOT NULL |
| count_unit | varchar(12) | NOT NULL | - | - | varchar(12) NOT NULL |
| standard_unit_quantity | decimal(10,2) | NULL | NULL | - | decimal(10,2) DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `idx_assignment` (`assignment_id`)
- KEY `idx_vendor_product` (`vendor_product_id`)

### Table: stock_count_assignments

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | - | int NOT NULL |
| master_session_id | int | NOT NULL | - | - | int NOT NULL |
| counter_user_id | int | NOT NULL | - | - | int NOT NULL |
| category_id | int | NOT NULL | - | - | int NOT NULL |
| status | enum('assigned','in_progress','completed','paused') | N/A | 'assigned' | - | enum('assigned','in_progress','completed','paused') DEFAULT 'assigned' |
| assigned_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | - | timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP |
| started_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |
| completed_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |
| notes | text | NULL | NULL | - | text DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- UNIQUE KEY `unique_session_category` (`master_session_id`,`category_id`)
- KEY `idx_counter_user` (`counter_user_id`)
- KEY `idx_master_session` (`master_session_id`)

### Table: stock_count_master_session

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | - | int NOT NULL |
| supervisor_id | int | NOT NULL | - | - | int NOT NULL |
| status | enum('planning','in_progress','completed','cancelled') | N/A | 'planning' | - | enum('planning','in_progress','completed','cancelled') DEFAULT 'planning' |
| total_categories | int | N/A | '0' | - | int DEFAULT '0' |
| completed_categories | int | N/A | '0' | - | int DEFAULT '0' |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | - | timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP |
| completed_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |
| notes | text | NULL | NULL | - | text DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: stock_notify

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| userid | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| product_id | bigint | NOT NULL | - | COMMENT | bigint unsigned NOT NULL COMMENT 'this is vendor prod id' |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | - | timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- UNIQUE KEY `userid` (`userid`,`product_id`)

### Table: stock_voucher

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| voucher_type | enum('IN','OUT') | NOT NULL | 'IN' | COLLATE utf8mb4_unicode_ci | enum('IN','OUT') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'IN' |
| status | enum('DRAFT','POSTED') | NOT NULL | 'DRAFT' | COLLATE utf8mb4_unicode_ci | enum('DRAFT','POSTED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT' |
| voucher_date | date | NULL | NULL | - | date DEFAULT NULL |
| remarks | text | NULL | NULL | COLLATE utf8mb4_unicode_ci | text COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| posted_at | datetime | NULL | NULL | - | datetime DEFAULT NULL |
| created_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |
| updated_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: stock_voucher_items

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| voucher_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| product_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| quantity | decimal(10,3) | NOT NULL | - | - | decimal(10,3) NOT NULL |
| unit_type | varchar(20) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL |
| created_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |
| updated_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `stock_voucher_items_voucher_id_foreign` (`voucher_id`)
- KEY `stock_voucher_items_product_id_foreign` (`product_id`)
- CONSTRAINT `stock_voucher_items_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`)
- CONSTRAINT `stock_voucher_items_voucher_id_foreign` FOREIGN KEY (`voucher_id`) REFERENCES `stock_voucher` (`id`) ON DELETE CASCADE

### Table: supplier_products

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| supplier_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| product_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| supplier_sku | varchar(100) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(100) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| supplier_product_name | varchar(255) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(255) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| description | text | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | text COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| pack_size | decimal(10,3) | NULL | NULL | - | decimal(10,3) DEFAULT NULL |
| pack_unit | varchar(20) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(20) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| min_order_qty | decimal(12,3) | NULL | NULL | - | decimal(12,3) DEFAULT NULL |
| price | decimal(12,2) | NULL | NULL | - | decimal(12,2) DEFAULT NULL |
| currency | varchar(3) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(3) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| tax_percent | decimal(5,2) | NULL | NULL | - | decimal(5,2) DEFAULT NULL |
| discount_percent | decimal(5,2) | NULL | NULL | - | decimal(5,2) DEFAULT NULL |
| lead_time_days | smallint | NULL | NULL | - | smallint unsigned DEFAULT NULL |
| last_purchase_price | decimal(12,2) | NULL | NULL | - | decimal(12,2) DEFAULT NULL |
| last_purchase_date | date | NULL | NULL | - | date DEFAULT NULL |
| is_preferred | tinyint(1) | NOT NULL | '0' | - | tinyint(1) NOT NULL DEFAULT '0' |
| is_active | tinyint(1) | NOT NULL | '1' | - | tinyint(1) NOT NULL DEFAULT '1' |
| notes | text | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | text COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| metadata | json | NULL | NULL | - | json DEFAULT NULL |
| created_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |
| updated_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- UNIQUE KEY `supplier_products_supplier_id_supplier_sku_unique` (`supplier_id`,`supplier_sku`)
- KEY `supplier_products_product_id_foreign` (`product_id`)
- UNIQUE KEY `supplier_products_supplier_id_product_id_unique` (`supplier_id`,`product_id`)
- CONSTRAINT `supplier_products_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`)
- CONSTRAINT `supplier_products_supplier_id_foreign` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`) ON DELETE CASCADE

### Table: suppliers

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| supplier_code | varchar(50) | NOT NULL | - | COLLATE utf8mb4_0900_ai_ci | varchar(50) COLLATE utf8mb4_0900_ai_ci NOT NULL |
| supplier_name | varchar(255) | NOT NULL | - | COLLATE utf8mb4_0900_ai_ci | varchar(255) COLLATE utf8mb4_0900_ai_ci NOT NULL |
| short_name | varchar(255) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(255) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| business_type | varchar(100) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(100) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| department | varchar(100) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(100) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| gst_no | varchar(20) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(20) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| pan_no | varchar(20) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(20) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| tan_no | varchar(20) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(20) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| cin_no | varchar(30) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(30) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| vat_no | varchar(30) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(30) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| registration_no | varchar(50) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(50) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| fssai_no | varchar(50) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(50) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| website | varchar(255) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(255) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| email | varchar(255) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(255) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| phone | varchar(30) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(30) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| alternate_phone | varchar(30) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(30) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| contact_person | varchar(255) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(255) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| contact_person_email | varchar(255) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(255) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| contact_person_phone | varchar(30) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(30) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| contact_person_designation | varchar(100) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(100) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| address_line1 | varchar(255) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(255) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| city | varchar(100) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(100) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| state | varchar(100) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(100) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| country | varchar(100) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(100) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| pincode | varchar(20) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(20) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| bank_name | varchar(150) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(150) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| bank_branch | varchar(150) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(150) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| bank_account_name | varchar(150) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(150) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| bank_account_number | varchar(50) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(50) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| ifsc_code | varchar(20) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(20) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| swift_code | varchar(20) | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | varchar(20) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| payment_terms_days | smallint | NULL | NULL | - | smallint unsigned DEFAULT NULL |
| credit_limit | decimal(12,2) | NULL | NULL | - | decimal(12,2) DEFAULT NULL |
| rating | decimal(3,2) | NULL | NULL | - | decimal(3,2) DEFAULT NULL |
| is_preferred | tinyint(1) | NOT NULL | '0' | - | tinyint(1) NOT NULL DEFAULT '0' |
| status | enum('ACTIVE','INACTIVE','SUSPENDED') | NOT NULL | 'ACTIVE' | COLLATE utf8mb4_0900_ai_ci | enum('ACTIVE','INACTIVE','SUSPENDED') COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'ACTIVE' |
| notes | text | NULL | NULL | COLLATE utf8mb4_0900_ai_ci | text COLLATE utf8mb4_0900_ai_ci DEFAULT NULL |
| metadata | json | NULL | NULL | - | json DEFAULT NULL |
| created_by | bigint | NULL | NULL | - | bigint unsigned DEFAULT NULL |
| updated_by | bigint | NULL | NULL | - | bigint unsigned DEFAULT NULL |
| created_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |
| updated_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |
| deleted_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- UNIQUE KEY `suppliers_supplier_code_unique` (`supplier_code`)
- KEY `suppliers_gstin_index` (`gst_no`)
- KEY `suppliers_pan_index` (`pan_no`)

### Table: taxes

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | bigint | NOT NULL | - | AUTO_INCREMENT | bigint unsigned NOT NULL AUTO_INCREMENT |
| tax_category | varchar(100) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL |
| tax_sub_category | varchar(100) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL |
| tax_name | varchar(150) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL |
| is_active | tinyint(1) | NOT NULL | '1' | - | tinyint(1) NOT NULL DEFAULT '1' |
| created_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |
| updated_at | timestamp | NULL | NULL | - | timestamp NULL DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `taxes_tax_category_tax_sub_category_index` (`tax_category`,`tax_sub_category`)

### Table: time_slots

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| slot_id | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| time_slot_group_id | int | NOT NULL | - | - | int NOT NULL |
| area_id | varchar(250) | NULL | NULL | - | varchar(250) DEFAULT NULL |
| start_date | int | NOT NULL | '1' | - | int unsigned NOT NULL DEFAULT '1' |
| interval | int | NOT NULL | '1' | - | int unsigned NOT NULL DEFAULT '1' |
| count_limit | int | NOT NULL | '3' | - | int unsigned NOT NULL DEFAULT '3' |
| order_time_end | int | N/A | '0' | - | int unsigned DEFAULT '0' |
| delivery_time_start | int | N/A | '0' | - | int unsigned DEFAULT '0' |
| delivery_time_end | int | N/A | '0' | - | int unsigned DEFAULT '0' |
| display_text | varchar(250) | NOT NULL | '' | - | varchar(250) NOT NULL DEFAULT '' |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`slot_id`) /*T![clustered_index] CLUSTERED */

### Table: timing_slot_group_categories

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | - | int NOT NULL |
| group_id | int | NOT NULL | - | - | int NOT NULL |
| category_id | int | NOT NULL | - | - | int NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: timing_slot_groups

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | - | int NOT NULL |
| min_amount | float(10,2) | NOT NULL | - | - | float(10,2) NOT NULL |
| express_delivery_charge | float(10,2) | NOT NULL | - | - | float(10,2) NOT NULL |
| delivery_charge | float(10,2) | NOT NULL | - | - | float(10,2) NOT NULL |
| admin_id | int | NOT NULL | - | - | int NOT NULL |
| is_active | enum('1','0') | NOT NULL | - | - | enum('1','0') NOT NULL |
| created_at | datetime | NOT NULL | - | - | datetime NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- UNIQUE KEY `admin_id` (`admin_id`)

### Table: trip_audit_log

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| trip_id | int | NOT NULL | - | - | int NOT NULL |
| order_id | int | NOT NULL | - | - | int NOT NULL |
| item_id | int | NOT NULL | - | - | int NOT NULL |
| vendor_product_id | int | NOT NULL | - | - | int NOT NULL |
| product_id | int | NOT NULL | - | - | int NOT NULL |
| qty_loaded | int | NOT NULL | - | - | int NOT NULL |
| qty_claimed_delivered | int | NOT NULL | - | - | int NOT NULL |
| qty_claimed_returned | int | NOT NULL | - | - | int NOT NULL |
| qty_verified_delivered | int | NOT NULL | - | - | int NOT NULL |
| qty_verified_returned | int | NOT NULL | - | - | int NOT NULL |
| discrepancy_delivered | int | N/A | - | GENERATED ALWAYS | int GENERATED ALWAYS AS ((`qty_verified_delivered` - `qty_claimed_delivered`)) STORED |
| discrepancy_returned | int | N/A | - | GENERATED ALWAYS | int GENERATED ALWAYS AS ((`qty_verified_returned` - `qty_claimed_returned`)) STORED |
| auditor_deli_id | int | NOT NULL | - | COMMENT | int NOT NULL COMMENT 'References deli_staff.deli_id (the auditor who verified the trip)' |
| audited_at | datetime | NOT NULL | - | - | datetime NOT NULL |
| investigation_status | enum('pending','resolved') | N/A | 'pending' | COLLATE utf8mb4_unicode_ci | enum('pending','resolved') COLLATE utf8mb4_unicode_ci DEFAULT 'pending' |
| investigator_deli_id | int | NULL | NULL | COMMENT | int DEFAULT NULL COMMENT 'References deli_staff.deli_id (the investigator who resolved discrepancies)' |
| investigated_at | datetime | NULL | NULL | - | datetime DEFAULT NULL |
| resolution_outcome | enum('stock_loss','stock_recovered') | NULL | NULL | COLLATE utf8mb4_unicode_ci | enum('stock_loss','stock_recovered') COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| resolution_notes | text | NULL | NULL | COLLATE utf8mb4_unicode_ci | text COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| qty_recovered_returned | int | NULL | NULL | - | int DEFAULT NULL |
| driver_liable | tinyint(1) | N/A | '0' | - | tinyint(1) DEFAULT '0' |
| liability_amount | decimal(10,2) | N/A | '0.00' | - | decimal(10,2) DEFAULT '0.00' |
| created_at | datetime | N/A | CURRENT_TIMESTAMP | - | datetime DEFAULT CURRENT_TIMESTAMP |
| updated_at | datetime | N/A | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: trip_card_pincode

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| zone_id | int | NOT NULL | - | - | int NOT NULL |
| pincode | varchar(10) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL |
| created_at | datetime | N/A | CURRENT_TIMESTAMP | - | datetime DEFAULT CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `zone_id` (`zone_id`)
- CONSTRAINT `trip_card_pincode_ibfk_1` FOREIGN KEY (`zone_id`) REFERENCES `trip_cards` (`zone_id`) ON DELETE CASCADE

### Table: trip_cards

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| zone_id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| zone_name | varchar(100) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL |
| vehicle_id | int | NULL | NULL | - | int DEFAULT NULL |
| status | varchar(20) | N/A | 'IDLE' | COLLATE utf8mb4_unicode_ci | varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'IDLE' |
| created_at | datetime | N/A | CURRENT_TIMESTAMP | - | datetime DEFAULT CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`zone_id`) /*T![clustered_index] CLUSTERED */
- UNIQUE KEY `zone_name` (`zone_name`)

### Table: trips

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| trip_id | int | NOT NULL | - | - | int NOT NULL |
| deli_id | int | NULL | NULL | - | int unsigned DEFAULT NULL |
| status | varchar(30) | NOT NULL | - | COMMENT | varchar(30) NOT NULL COMMENT 'unass, ass, ongoing, completed' |
| description | varchar(40) | NOT NULL | - | COMMENT | varchar(40) NOT NULL COMMENT 'vehicle number, trip number. \\|\\| just vehicle number' |
| start_date | varchar(30) | NOT NULL | - | - | varchar(30) NOT NULL |
| completed_at | varchar(25) | NOT NULL | - | - | varchar(25) NOT NULL |
| created_at | timestamp | NOT NULL | CURRENT_TIMESTAMP | - | timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`trip_id`) /*T![clustered_index] CLUSTERED */

### Table: user

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| userid | bigint | NOT NULL | - | - | bigint unsigned NOT NULL |
| email | varchar(250) | NOT NULL | ' ' | - | varchar(250) NOT NULL DEFAULT ' ' |
| is_email_verified | tinyint | NOT NULL | '0' | - | tinyint NOT NULL DEFAULT '0' |
| contactno | varchar(250) | NOT NULL | - | - | varchar(250) NOT NULL |
| is_contact_verified | tinyint | NOT NULL | '0' | - | tinyint NOT NULL DEFAULT '0' |
| name | text | NOT NULL | - | - | text NOT NULL |
| account_state | varchar(250) | NOT NULL | 'incomplete' | - | varchar(250) NOT NULL DEFAULT 'incomplete' |
| address | text | NOT NULL | - | - | text NOT NULL |
| latitude | float(10,6) | NOT NULL | '0' | - | float(10,6) NOT NULL DEFAULT '0' |
| longitude | float(10,6) | NOT NULL | '0' | - | float(10,6) NOT NULL DEFAULT '0' |
| dob | text | NULL | NULL | - | text DEFAULT NULL |
| register_date | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| shop_name | varchar(255) | NULL | NULL | - | varchar(255) DEFAULT NULL |
| shop_address | varchar(255) | NULL | NULL | - | varchar(255) DEFAULT NULL |
| shop_plot_no | varchar(255) | NULL | NULL | - | varchar(255) DEFAULT NULL |
| user_type | enum('B2C','B2B') | NOT NULL | - | - | enum('B2C','B2B') NOT NULL |
| adhar_card | varchar(255) | NULL | NULL | - | varchar(255) DEFAULT NULL |
| shop_photo | varchar(255) | NULL | NULL | - | varchar(255) DEFAULT NULL |
| shop_licence | varchar(255) | NULL | NULL | - | varchar(255) DEFAULT NULL |
| bussiness_pan_card | varchar(255) | NULL | NULL | - | varchar(255) DEFAULT NULL |
| is_approved | enum('YES','NO','REQUESTED') | NOT NULL | 'YES' | - | enum('YES','NO','REQUESTED') NOT NULL DEFAULT 'YES' |
| session_id | text | NOT NULL | - | - | text NOT NULL |
| last_activity | int | NOT NULL | '0' | - | int unsigned NOT NULL DEFAULT '0' |
| push_notif_id | text | NOT NULL | - | - | text NOT NULL |
| is_first_login | tinyint | NOT NULL | '1' | - | tinyint unsigned NOT NULL DEFAULT '1' |
| has_unread_comments | tinyint | NOT NULL | '0' | - | tinyint unsigned NOT NULL DEFAULT '0' |
| password | varchar(250) | NULL | NULL | - | varchar(250) DEFAULT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`userid`) /*T![clustered_index] CLUSTERED */

### Table: user_addresses

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | - | int NOT NULL |
| user_id | int | NOT NULL | - | - | int NOT NULL |
| full_name | varchar(255) | NULL | NULL | - | varchar(255) DEFAULT NULL |
| full_address | varchar(255) | NULL | NULL | - | varchar(255) DEFAULT NULL |
| phone_no | varchar(255) | NULL | NULL | - | varchar(255) DEFAULT NULL |
| name | varchar(255) | NOT NULL | - | - | varchar(255) NOT NULL |
| address | varchar(255) | NOT NULL | - | - | varchar(255) NOT NULL |
| lat | double(10,8) | NOT NULL | - | - | double(10,8) NOT NULL |
| lng | double(11,8) | NOT NULL | - | - | double(11,8) NOT NULL |
| type | enum('Home','Office') | NOT NULL | - | - | enum('Home','Office') NOT NULL |
| city_id | varchar(255) | NOT NULL | - | - | varchar(255) NOT NULL |
| area_id | varchar(255) | NOT NULL | - | - | varchar(255) NOT NULL |
| is_default | enum('0','1') | NOT NULL | - | - | enum('0','1') NOT NULL |
| created_at | datetime | NOT NULL | - | - | datetime NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: users

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| employeeCode | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| name | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| email | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| contactNumber | varchar(191) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL |
| alternativeNumber | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| roleId | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| roles | json | NULL | NULL | - | json DEFAULT NULL |
| departmentId | varchar(10) | NULL | NULL | COLLATE utf8mb4_bin | varchar(10) COLLATE utf8mb4_bin DEFAULT NULL |
| otp | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| otpExpiry | datetime | NULL | NULL | - | datetime DEFAULT NULL |
| lastLogin | datetime | NULL | NULL | - | datetime DEFAULT NULL |
| isActive | tinyint(1) | NOT NULL | '1' | - | tinyint(1) NOT NULL DEFAULT '1' |
| createdAt | datetime | NOT NULL | CURRENT_TIMESTAMP | - | datetime NOT NULL DEFAULT CURRENT_TIMESTAMP |
| updatedAt | datetime | NOT NULL | CURRENT_TIMESTAMP | ON UPDATE CURRENT_TIMESTAMP | datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |
| dateOfBirth | datetime | NULL | NULL | - | datetime DEFAULT NULL |
| gender | varchar(50) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| image | text | NULL | NULL | COLLATE utf8mb4_unicode_ci | text COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| preferredLanguages | json | NULL | NULL | - | json DEFAULT NULL |
| address | text | NULL | NULL | COLLATE utf8mb4_unicode_ci | text COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| city | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| state | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| pincode | varchar(20) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| country | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| district | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| area | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| latitude | double | NULL | NULL | - | double DEFAULT NULL |
| longitude | double | NULL | NULL | - | double DEFAULT NULL |
| aadharCard | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| panCard | varchar(191) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| password | varchar(255) | NULL | NULL | COLLATE utf8mb4_unicode_ci | varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| notes | text | NULL | NULL | COLLATE utf8mb4_unicode_ci | text COLLATE utf8mb4_unicode_ci DEFAULT NULL |
| workStartTime | varchar(8) | NOT NULL | '09:00:00' | COLLATE utf8mb4_unicode_ci | varchar(8) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '09:00:00' |
| workEndTime | varchar(8) | NOT NULL | '18:00:00' | COLLATE utf8mb4_unicode_ci | varchar(8) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '18:00:00' |
| latePunchInGraceMinutes | int | NOT NULL | '45' | - | int NOT NULL DEFAULT '45' |
| earlyPunchOutGraceMinutes | int | NOT NULL | '30' | - | int NOT NULL DEFAULT '30' |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- UNIQUE KEY `users_employeecode_unique` (`employeeCode`)
- UNIQUE KEY `users_email_unique` (`email`)
- UNIQUE KEY `users_contactnumber_unique` (`contactNumber`)
- KEY `users_roleid_foreign` (`roleId`)
- KEY `users_departmentid_foreign` (`departmentId`)
- CONSTRAINT `users_roleid_foreign` FOREIGN KEY (`roleId`) REFERENCES `roles` (`id`) ON DELETE SET NULL
- CONSTRAINT `users_departmentid_foreign` FOREIGN KEY (`departmentId`) REFERENCES `Department` (`id`) ON DELETE SET NULL

### Table: vehicles

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| vehicle_id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| vehicle_number | varchar(50) | NOT NULL | - | COLLATE utf8mb4_unicode_ci | varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL |
| capacity_kg | decimal(10,2) | NOT NULL | - | - | decimal(10,2) NOT NULL |
| is_active | tinyint(1) | N/A | '1' | - | tinyint(1) DEFAULT '1' |
| created_at | datetime | N/A | CURRENT_TIMESTAMP | - | datetime DEFAULT CURRENT_TIMESTAMP |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`vehicle_id`) /*T![clustered_index] CLUSTERED */
- UNIQUE KEY `vehicle_number` (`vehicle_number`)
- KEY `idx_vehicle_capacity` (`capacity_kg`,`is_active`)

### Table: vendor_area_categories

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | - | int NOT NULL |
| admin_id | int | NOT NULL | - | - | int NOT NULL |
| city_id | varchar(255) | NOT NULL | '' | - | varchar(255) NOT NULL DEFAULT '' |
| area_id | varchar(255) | NOT NULL | - | - | varchar(255) NOT NULL |
| category_id | varchar(255) | NOT NULL | - | - | varchar(255) NOT NULL |
| commisson | int | NOT NULL | '0' | - | int NOT NULL DEFAULT '0' |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: vendor_products

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| admin_vendor_id | int | NOT NULL | - | - | int NOT NULL |
| product_id | int | NOT NULL | - | - | int NOT NULL |
| packs | text | NOT NULL | - | - | text NOT NULL |
| default_pack_id | varchar(255) | NOT NULL | - | - | varchar(255) NOT NULL |
| status | enum('1','0') | NOT NULL | - | - | enum('1','0') NOT NULL |
| in_stock | enum('1','0') | NOT NULL | - | - | enum('1','0') NOT NULL |
| created_at | datetime | NOT NULL | - | - | datetime NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: vendor_products_inventory

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| vendor_product_id | int | NOT NULL | - | - | int NOT NULL |
| product_id | int | NOT NULL | - | - | int NOT NULL |
| action_type | varchar(255) | NOT NULL | - | - | varchar(255) NOT NULL |
| pack_id | varchar(255) | NOT NULL | - | - | varchar(255) NOT NULL |
| vendor_id | int | NULL | NULL | - | int DEFAULT NULL |
| quantity | double(10,2) | NOT NULL | - | - | double(10,2) NOT NULL |
| unit_type | varchar(255) | NOT NULL | - | - | varchar(255) NOT NULL |
| unitquantity | double(10,2) | NOT NULL | - | - | double(10,2) NOT NULL |
| amount | double(10,2) | NOT NULL | - | - | double(10,2) NOT NULL |
| wholesale_user_id | int | NULL | NULL | - | int DEFAULT NULL |
| inv_date | date | NOT NULL | - | - | date NOT NULL |
| inv_type | enum('CREDIT','DEBIT') | NOT NULL | - | - | enum('CREDIT','DEBIT') NOT NULL |
| note | text | NOT NULL | - | - | text NOT NULL |
| trip_id | int | NULL | NULL | - | int DEFAULT NULL |
| updated_at | datetime | NOT NULL | - | - | datetime NOT NULL |
| created_at | datetime | NOT NULL | - | - | datetime NOT NULL |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */

### Table: zone_vehicles

#### Attributes (Columns)

| Column | Type | Nullability | Default | Extra | Full Definition |
|---|---|---|---|---|---|
| id | int | NOT NULL | - | AUTO_INCREMENT | int NOT NULL AUTO_INCREMENT |
| zone_id | int | NOT NULL | - | - | int NOT NULL |
| vehicle_id | int | NOT NULL | - | - | int NOT NULL |
| assigned_at | timestamp | N/A | CURRENT_TIMESTAMP | - | timestamp DEFAULT CURRENT_TIMESTAMP |
| is_active | tinyint(1) | N/A | '1' | - | tinyint(1) DEFAULT '1' |

#### Keys, Indexes, Constraints

- PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
- KEY `zone_id` (`zone_id`)
- KEY `vehicle_id` (`vehicle_id`)
- KEY `is_active` (`is_active`)
- CONSTRAINT `zone_vehicles_ibfk_1` FOREIGN KEY (`zone_id`) REFERENCES `trip_cards` (`zone_id`) ON DELETE CASCADE
- CONSTRAINT `zone_vehicles_ibfk_2` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`vehicle_id`) ON DELETE CASCADE

## Common Tables and Attributes (CRM vs Loagma)

| Common Name (normalized) | CRM Table Name | Loagma Table Name | Common Columns |
|---|---|---|---|
| department | Department | department | createdAt, id, name |
| user | User | user | address, email, latitude, longitude, name, password |

### Common Table Pair: Department (CRM) <-> department (Loagma)

| Column | CRM Type | Loagma Type | CRM Nullability | Loagma Nullability |
|---|---|---|---|---|
| createdAt | datetime(3) | timestamp(3) | NOT NULL | N/A |
| id | varchar(191) | varchar(10) | NOT NULL | NOT NULL |
| name | varchar(191) | varchar(100) | NOT NULL | NOT NULL |

### Common Table Pair: User (CRM) <-> user (Loagma)

| Column | CRM Type | Loagma Type | CRM Nullability | Loagma Nullability |
|---|---|---|---|---|
| address | varchar(191) | text | NULL | NOT NULL |
| email | varchar(191) | varchar(250) | NULL | NOT NULL |
| latitude | double | float(10,6) | NULL | NOT NULL |
| longitude | double | float(10,6) | NULL | NOT NULL |
| name | varchar(191) | text | NULL | NOT NULL |
| password | varchar(191) | varchar(250) | NULL | NULL |


