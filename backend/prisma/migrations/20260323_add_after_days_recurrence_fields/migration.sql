ALTER TABLE `WeeklyAccountAssignment`
  ADD COLUMN `recurrenceAfterDays` INTEGER NULL,
  ADD COLUMN `recurrenceStartDate` DATETIME(3) NULL,
  ADD COLUMN `recurrenceNextDate` DATETIME(3) NULL;

CREATE INDEX `WeeklyAccountAssignment_salesmanId_recurrenceNextDate_idx`
  ON `WeeklyAccountAssignment`(`salesmanId`, `recurrenceNextDate`);
