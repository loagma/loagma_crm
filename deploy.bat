@echo off
echo ========================================
echo Deploying Backend to Render
echo ========================================
echo.

echo Step 1: Checking Git status...
git status
echo.

echo Step 2: Adding changes...
git add backend/src/utils/smsService.js
git add loagma_crm/lib/services/api_config.dart
echo.

echo Step 3: Committing changes...
git commit -m "Fix: Add Mock SMS mode for OTP sending"
echo.

echo Step 4: Pushing to Git...
git push origin main
echo.

echo ========================================
echo ✅ Code pushed to Git!
echo ========================================
echo.
echo Next steps:
echo 1. Go to Render Dashboard
echo 2. Add environment variable: USE_MOCK_SMS=true
echo 3. Wait for auto-deploy (or click Manual Deploy)
echo 4. Check logs for deployment success
echo 5. Test OTP from Flutter app
echo.
echo Render Dashboard: https://dashboard.render.com/
echo ========================================
echo.

pause
