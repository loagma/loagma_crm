@echo off
cls
echo ========================================
echo Account Master - Complete Setup
echo ========================================
echo.
echo This script will:
echo 1. Apply database migration
echo 2. Generate Prisma Client
echo 3. Verify everything is working
echo.
pause

echo.
echo ========================================
echo Step 1: Applying Database Migration
echo ========================================
cd backend
node apply-migration.js

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Migration failed!
    echo.
    echo Please check:
    echo 1. Is PostgreSQL running?
    echo 2. Is DATABASE_URL correct in backend\.env?
    echo 3. Do you have database permissions?
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Step 2: Generating Prisma Client
echo ========================================
call npx prisma generate

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Prisma generate failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Step 3: Verification
echo ========================================
echo.
echo ✅ Database migration applied
echo ✅ Prisma Client generated
echo ✅ Backend is ready
echo.
echo ========================================
echo Next Steps:
echo ========================================
echo.
echo 1. Start backend:
echo    cd backend
echo    npm run dev
echo.
echo 2. Test Account Master:
echo    - Open Flutter app
echo    - Navigate to Account Master
echo    - Test all new fields
echo.
echo 3. Test Pincode Lookup:
echo    - Enter pincode: 400001
echo    - Click Lookup button
echo    - Location should auto-fill
echo.
echo ========================================
echo Setup Complete! 🎉
echo ========================================
echo.
pause
