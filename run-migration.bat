@echo off
echo ========================================
echo Account Master Database Migration
echo ========================================
echo.

cd backend

echo Step 1: Creating migration file...
call npx prisma migrate dev --create-only --name account_master_refactoring

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Migration creation failed. Trying alternative approach...
    echo.
    echo Please run the SQL script manually:
    echo 1. Open your Neon database console
    echo 2. Run the SQL from: backend\migrate-account-master.sql
    echo 3. Then run: npx prisma db pull
    echo 4. Then run: npx prisma generate
    pause
    exit /b 1
)

echo.
echo Step 2: Migration file created successfully!
echo.
echo Now you need to:
echo 1. Find the migration file in backend\prisma\migrations\
echo 2. Edit it and replace content with SQL from migrate-account-master.sql
echo 3. Then run this script again to apply it
echo.
pause
