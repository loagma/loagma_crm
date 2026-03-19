-- AlterTable
ALTER TABLE `WeeklyAccountAssignment` ADD COLUMN `overriddenAt` DATETIME(3) NULL,
    ADD COLUMN `overrideBy` VARCHAR(191) NULL,
    ADD COLUMN `overrideReason` VARCHAR(191) NULL,
    ADD COLUMN `plannedAt` DATETIME(3) NULL,
    ADD COLUMN `plannedBy` VARCHAR(191) NULL;
