-- AlterTable
ALTER TABLE "User" ADD COLUMN     "aadharCard" TEXT,
ADD COLUMN     "address" TEXT,
ADD COLUMN     "alternativeNumber" TEXT,
ADD COLUMN     "city" TEXT,
ADD COLUMN     "notes" TEXT,
ADD COLUMN     "panCard" TEXT,
ADD COLUMN     "password" TEXT,
ADD COLUMN     "pincode" TEXT,
ADD COLUMN     "roles" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "state" TEXT;
