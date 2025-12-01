@echo off
echo ========================================
echo Rebuilding Flutter App
echo ========================================
echo.

cd loagma_crm

echo Step 1: Cleaning build cache...
call flutter clean

echo.
echo Step 2: Getting dependencies...
call flutter pub get

echo.
echo Step 3: Running app...
echo ========================================
echo Make sure backend is running!
echo Backend: cd backend ^&^& npm run dev
echo ========================================
echo.

call flutter run

pause
