/*
  Warnings:

  - You are about to drop the column `type_id` on the `Area` table. All the data in the column will be lost.
  - You are about to drop the `AreaType` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "Area" DROP CONSTRAINT "Area_type_id_fkey";

-- AlterTable
ALTER TABLE "Area" DROP COLUMN "type_id";

-- DropTable
DROP TABLE "AreaType";
