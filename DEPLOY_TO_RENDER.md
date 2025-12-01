# 🚀 Deploy Fixed Backend to Render

## What Needs to be Done

Your production server on Render needs:
1. ✅ The updated `smsService.js` with Mock SMS mode
2. ✅ Environment variable: `USE_MOCK_SMS=true`

---

## Step 1: Push Code to Git

The fixed `smsService.js` is already in your local repo. Push it to your Git repository:

```bash
git add backend/src/utils/smsService.js
git commit -m "Fix: Add Mock SMS mode for OTP sending"
git push origin main
```

**Or push all changes:**
```bash
git add .
git commit -m "Fix: Add Mock SMS fallback for Twilio authentication"
git push origin main
```

---

## Step 2: Update Render Environment Variables

1. Go to **[Render Dashboard](https://dashboard.render.com/)**
2. Click on your backend service (loagma-crm)
3. Go to **Environment** tab
4. Add this new environment variable:

```
Key: USE_MOCK_SMS
Value: true
```

5. Click **Save Changes**

---

## Step 3: Redeploy on Render

After pushing to Git, Render should auto-deploy. If not:

1. Go to your service dashboard
2. Click **Manual Deploy** → **Deploy latest commit**
3. Wait for deployment to complete (2-5 minutes)

---

## Step 4: Test Production API

After deployment, test the OTP endpoint:

```bash
curl -X POST https://loagma-crm.onrender.com/auth/send-otp \
  -H "Content-Type: application/json" \
  -d "{\"contactNumber\":\"9285543488\"}"
```

**Expected Response:**
```json
{
  "success": true,
  "message": "OTP sent successfully to your mobile number."
}
```

---

## Step 5: Check Render Logs for OTP

1. Go to Render Dashboard
2. Click on your service
3. Go to **Logs** tab
4. Send OTP from your app
5. Look for:
   ```
   📱 ========================================
   📱 MOCK SMS (Development Mode)
   📱 ========================================
   📱 OTP: 1234
   📱 ========================================
   ```

---

## Step 6: Rebuild Flutter App

Since you changed `useProduction` back to `true`:

```bash
cd loagma_crm
flutter run
```

---

## 🎯 Complete Deployment Checklist

- [ ] Push updated `smsService.js` to Git
- [ ] Add `USE_MOCK_SMS=true` to Render environment variables
- [ ] Redeploy on Render
- [ ] Check deployment logs (no errors)
- [ ] Test OTP endpoint with curl
- [ ] Rebuild Flutter app
- [ ] Test OTP from app
- [ ] Check Render logs for OTP

---

## 📋 Files to Deploy

These files have the Mock SMS fix:
- ✅ `backend/src/utils/smsService.js` (updated)
- ✅ `backend/.env` (local only - don't push this!)

---

## 🔐 Environment Variables on Render

Make sure these are set:

```env
PORT=5000
DATABASE_URL=your_database_url
JWT_SECRET=your_jwt_secret
USE_MOCK_SMS=true  ← Add this!
TWILIO_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token
TWILIO_PHONE=your_twilio_phone
CLOUDINARY_CLOUD_NAME=your_cloudinary_name
CLOUDINARY_API_KEY=your_cloudinary_key
CLOUDINARY_API_SECRET=your_cloudinary_secret
GOOGLE_MAPS_API_KEY=your_google_maps_key
```

---

## 🐛 Troubleshooting

### Issue: Still getting 500 error after deployment

**Check:**
1. Did you push the code? (`git push`)
2. Did Render redeploy? (check deployment status)
3. Did you add `USE_MOCK_SMS=true`? (check Environment tab)
4. Check Render logs for errors

### Issue: Can't see OTP in logs

**Solution:**
- Render logs show console output
- Look for lines with 📱 emoji
- May need to scroll or refresh logs

### Issue: Deployment failed

**Check:**
1. Build logs on Render
2. Make sure `package.json` is correct
3. Make sure all dependencies are listed

---

## 🎉 After Deployment

Once deployed and working:

1. **Flutter app** will call: `https://loagma-crm.onrender.com`
2. **OTP** will be in Render logs
3. **No local backend** needed
4. **Works from anywhere**

---

## 📱 How to Get OTP After Deployment

1. Open your Flutter app
2. Enter phone number
3. Click "Send OTP"
4. Go to **Render Dashboard** → **Logs**
5. Look for: `📱 OTP: 1234`
6. Enter OTP in app
7. Login! ✅

---

## Quick Commands

```bash
# Push to Git
git add backend/src/utils/smsService.js
git commit -m "Fix: Add Mock SMS mode"
git push origin main

# Test production API
curl -X POST https://loagma-crm.onrender.com/auth/send-otp \
  -H "Content-Type: application/json" \
  -d "{\"contactNumber\":\"9285543488\"}"

# Rebuild Flutter
cd loagma_crm
flutter run
```

---

**Status:** Ready to deploy!  
**Action:** Push code to Git and update Render environment variables
