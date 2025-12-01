@echo off
echo ========================================
echo Configuration Check
echo ========================================
echo.

echo Checking Backend Configuration...
echo ----------------------------------------
findstr /C:"USE_MOCK_SMS" backend\.env
echo.

echo Checking Flutter Configuration...
echo ----------------------------------------
findstr /C:"useProduction" loagma_crm\lib\services\api_config.dart
echo.

echo ========================================
echo Expected Values:
echo   Backend: USE_MOCK_SMS=true
echo   Flutter: useProduction = false
echo ========================================
echo.

pause
