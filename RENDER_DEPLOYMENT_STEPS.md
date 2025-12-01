# 🚀 Deploy to Render - Simple Steps

## What You Need to Do

Deploy the fixed backend code to Render so your Flutter app can use it.

---

## Step 1: Push Code to Git (2 Commands)

```bash
git add .
git commit -m "Fix: Add Mock SMS mode for OTP"
git push origin main
```

**Or use the script:**
```bash
deploy.bat
```

---

## Step 2: Add Environment Variable on Render

1. Open: **https://dashboard.render.com/**
2. Click your backend service
3. Click **Environment** tab
4. Click **Add Environment Variable**
5. Add:
   - **Key:** `USE_MOCK_SMS`
   - **Value:** `true`
6. Click **Save Changes**

---

## Step 3: Wait for Deployment

Render will automatically redeploy (2-5 minutes).

Watch the deployment in the **Events** tab.

---

## Step 4: Rebuild Flutter App

```bash
cd loagma_crm
flutter run
```

---

## Step 5: Test OTP

1. Open app
2. Enter phone: `9285543488`
3. Click "Send OTP"
4. Go to **Render Dashboard** → **Logs**
5. Look for: `📱 OTP: 1234`
6. Enter OTP in app
7. Login! ✅

---

## 🎯 Quick Checklist

- [ ] Run: `git add . && git commit -m "Fix OTP" && git push`
- [ ] Render: Add `USE_MOCK_SMS=true` environment variable
- [ ] Wait for Render to redeploy
- [ ] Rebuild Flutter: `flutter run`
- [ ] Test OTP login
- [ ] Check Render logs for OTP

---

## 📱 Where to Find OTP

**Render Dashboard → Your Service → Logs**

Look for:
```
📱 OTP: 1234
```

---

## ⚡ Super Quick Version

```bash
# 1. Push code
git add . && git commit -m "Fix OTP" && git push

# 2. Go to Render Dashboard
# 3. Add: USE_MOCK_SMS=true
# 4. Wait for deploy
# 5. Rebuild Flutter
cd loagma_crm && flutter run
```

---

**That's it! Your production backend will work with Mock SMS mode.**
