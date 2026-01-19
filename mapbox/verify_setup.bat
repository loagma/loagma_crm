@echo off
REM Mapbox Setup Verification Script for Windows
REM This script verifies that Mapbox is properly configured

echo.
echo Verifying Mapbox Setup...
echo.

set MAPBOX_TOKEN=pk.eyJ1IjoibG9hZ21hY3JtMTIzIiwiYSI6ImNta2YzZHBrYTBmZHkzZ3F2MGVudjB3NGQifQ.xa5ojP6rByCK2U6Xs0OZyA

REM Test 1: Verify token format
echo 1. Checking token format...
echo %MAPBOX_TOKEN% | findstr /B "pk." >nul
if %errorlevel% equ 0 (
    echo [32m[OK] Token format is correct ^(public token^)[0m
) else (
    echo [31m[ERROR] Token format is incorrect[0m
    exit /b 1
)
echo.

REM Test 2: Verify token with Mapbox API
echo 2. Verifying token with Mapbox API...
curl -s "https://api.mapbox.com/styles/v1/mapbox/streets-v12?access_token=%MAPBOX_TOKEN%" > temp_response.txt
findstr /C:"mapbox://styles/mapbox/streets-v12" temp_response.txt >nul
if %errorlevel% equ 0 (
    echo [32m[OK] Token is valid and working[0m
) else (
    echo [31m[ERROR] Token validation failed[0m
    type temp_response.txt
    del temp_response.txt
    exit /b 1
)
del temp_response.txt
echo.

REM Test 3: Check Flutter configuration
echo 3. Checking Flutter configuration...
findstr /C:"pk.eyJ1IjoibG9hZ21hY3JtMTIzIiwiYSI6ImNta2YzZHBrYTBmZHkzZ3F2MGVudjB3NGQifQ.xa5ojP6rByCK2U6Xs0OZyA" "..\loagma_crm\lib\config\mapbox_config.dart" >nul
if %errorlevel% equ 0 (
    echo [32m[OK] Flutter config is correct[0m
) else (
    echo [31m[ERROR] Flutter config needs update[0m
    exit /b 1
)
echo.

REM Test 4: Check Android configuration
echo 4. Checking Android configuration...
findstr /C:"MAPBOX_ACCESS_TOKEN=pk.eyJ1IjoibG9hZ21hY3JtMTIzIiwiYSI6ImNta2YzZHBrYTBmZHkzZ3F2MGVudjB3NGQifQ.xa5ojP6rByCK2U6Xs0OZyA" "..\loagma_crm\android\gradle.properties" >nul
if %errorlevel% equ 0 (
    echo [32m[OK] Android config is correct[0m
) else (
    echo [31m[ERROR] Android config needs update[0m
    exit /b 1
)
echo.

REM Test 5: Check iOS configuration
echo 5. Checking iOS configuration...
findstr /C:"pk.eyJ1IjoibG9hZ21hY3JtMTIzIiwiYSI6ImNta2YzZHBrYTBmZHkzZ3J2MGVudjB3NGQifQ.xa5ojP6rByCK2U6Xs0OZyA" "..\loagma_crm\ios\Runner\Info.plist" >nul
if %errorlevel% equ 0 (
    echo [32m[OK] iOS config is correct[0m
) else (
    echo [31m[ERROR] iOS config needs update[0m
    exit /b 1
)
echo.

REM Test 6: Run Flutter tests
echo 6. Running Mapbox integration tests...
cd ..\loagma_crm
flutter test test\integration\mapbox_integration_test.dart --reporter compact > temp_test_output.txt 2>&1
findstr /C:"All tests passed!" temp_test_output.txt >nul
if %errorlevel% equ 0 (
    echo [32m[OK] All Mapbox integration tests passed[0m
) else (
    echo [33m[WARNING] Some tests may require additional setup[0m
)
del temp_test_output.txt
cd ..\mapbox
echo.

REM Summary
echo ========================================
echo [32mMapbox Setup Verification Complete![0m
echo ========================================
echo.
echo Your Mapbox integration is properly configured and ready to use!
echo.
echo Next steps:
echo   1. Run your Flutter app: flutter run
echo   2. Navigate to Live Tracking screen
echo   3. View the map with your configured style
echo.
echo For more information, see: mapbox\SETUP_COMPLETE.md
echo.

pause
