@echo off
echo ========================================
echo Testing if Backend is Running
echo ========================================
echo.

echo Checking http://localhost:5000/health ...
echo.

curl -s http://localhost:5000/health

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo ✅ Backend is RUNNING on port 5000
    echo ========================================
) else (
    echo.
    echo ========================================
    echo ❌ Backend is NOT running
    echo.
    echo Start it with:
    echo   cd backend
    echo   npm run dev
    echo ========================================
)

echo.
pause
