@echo off
echo ========================================
echo Account Master Migration
echo ========================================
echo.

echo Running migration script...
node apply-migration.js

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Migration successful!
    echo ========================================
    echo.
    echo Now generating Prisma Client...
    call npx prisma generate
    
    echo.
    echo ========================================
    echo All done! You can now:
    echo 1. Start your backend: npm run dev
    echo 2. Test the Account Master screen
    echo ========================================
) else (
    echo.
    echo ========================================
    echo Migration failed!
    echo ========================================
    echo.
    echo Please check the error above.
)

echo.
pause
