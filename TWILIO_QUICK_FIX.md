# 🚀 Twilio Quick Fix

## The Problem
**Error**: "Authenticate" when sending SMS  
**Cause**: Invalid Twilio credentials in `.env` file

---

## The Fix (3 Steps)

### 1️⃣ Get Real Credentials
Go to: https://console.twilio.com/
- Copy **Account SID** (starts with AC)
- Copy **Auth Token** (click to reveal)
- Copy your **Phone Number** (from Phone Numbers section)

### 2️⃣ Update `.env` File
Open: `backend/.env`

Replace these lines:
```env
TWILIO_SID=your_real_account_sid_here
TWILIO_AUTH_TOKEN=your_real_auth_token_here
TWILIO_PHONE=your_real_phone_number_here
```

### 3️⃣ Test It
```bash
cd backend
node test-twilio.js
```

Should see: ✅ All Twilio checks passed!

---

## Done! 🎉

Now your OTP SMS will work properly.

**Test OTP sending:**
```bash
node test-otp-send.js
```
