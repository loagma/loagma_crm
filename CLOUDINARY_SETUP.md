# Cloudinary Setup Guide

## Why Cloudinary?
Cloudinary is used to store and serve images (employee photos, account owner/shop images) efficiently with automatic optimization and CDN delivery.

## Setup Steps

### 1. Create Cloudinary Account
1. Go to https://cloudinary.com/
2. Sign up for a free account
3. After signup, you'll be taken to the Dashboard

### 2. Get Your Credentials
From your Cloudinary Dashboard, you'll find:
- **Cloud Name**: Your unique cloud name
- **API Key**: Your API key
- **API Secret**: Your API secret (click "eye" icon to reveal)

### 3. Configure Backend

Edit `backend/.env` file and add:

```env
# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your_cloud_name_here
CLOUDINARY_API_KEY=your_api_key_here
CLOUDINARY_API_SECRET=your_api_secret_here
CLOUDINARY_SECURE=true
```

**Important:** Replace the placeholder values with your actual Cloudinary credentials!

### 4. Restart Backend Server

After updating the `.env` file:

```bash
cd backend
npm start
```

## Testing Image Upload

### From Frontend:
1. Go to "Create Employee" or "Create Account Master"
2. Select an image for profile/owner/shop
3. Submit the form

### Check Backend Logs:
You should see:
```
🖼️ Image upload check:
  - Owner image provided: true
  - Owner image starts with data:image: true
  - Owner image length: 50000
📸 Uploading owner image to Cloudinary...
✅ Owner image uploaded: https://res.cloudinary.com/...
```

### If Upload Fails:
Check for error messages like:
```
❌ Owner image upload failed: Invalid credentials
```

This means your Cloudinary credentials are incorrect or missing.

## Troubleshooting

### Images Not Showing in View
1. Check backend logs when creating account/employee
2. Verify image URLs are being saved (should start with `https://res.cloudinary.com/`)
3. Check browser console for image loading errors
4. Verify Cloudinary credentials are correct

### Upload Fails
1. **Invalid credentials**: Double-check your `.env` file
2. **Network error**: Check internet connection
3. **Image too large**: Frontend limits images to 800x800, 70-85% quality
4. **Cloudinary quota exceeded**: Free tier has limits, check your dashboard

### Images Not Displaying
1. Check if image URL starts with `http` or `https`
2. Verify the URL is accessible in browser
3. Check CORS settings in Cloudinary (usually not an issue)
4. Look for console errors in browser DevTools

## Free Tier Limits
- **Storage**: 25 GB
- **Bandwidth**: 25 GB/month
- **Transformations**: 25,000/month

This is usually sufficient for small to medium applications.

## Image Folders Structure
Images are organized in Cloudinary:
- `users/` - Employee profile pictures
- `accounts/owners/` - Account owner photos
- `accounts/shops/` - Shop/outlet photos

## Security Notes
- Never commit `.env` file to git
- Keep your API Secret confidential
- Use environment variables in production
- Consider using signed uploads for production

## Support
If you continue having issues:
1. Check Cloudinary Dashboard for upload activity
2. Review backend console logs
3. Verify all environment variables are set correctly
4. Ensure backend server was restarted after adding credentials
