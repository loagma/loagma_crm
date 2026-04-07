-- Safe physical table renames without dropping/recreating data.
-- Keep Prisma model names unchanged via @@map in schema.prisma.

-- Rename User table to user_crm.
RENAME TABLE `User` TO `user_crm`;

-- Rename Department to lowercase using an intermediate name for case-safe handling.
RENAME TABLE `Department` TO `department_tmp_rename`;
RENAME TABLE `department_tmp_rename` TO `department`;
