-- Safe physical table renames without dropping/recreating data.
-- Keep Prisma model names unchanged via @@map in schema.prisma.

-- Rename Account table to LeadsAccount_crm.
RENAME TABLE `Account` TO `LeadsAccount_crm`;

-- Rename user_crm table to LoginUser_crm.
RENAME TABLE `user_crm` TO `LoginUser_crm`;

-- Rename Role table to LoginUserRoles_crm.
RENAME TABLE `Role` TO `LoginUserRoles_crm`;
