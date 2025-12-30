# Beat Planning Module - Production Deployment Guide

This guide will help you deploy the Weekly Beat Planning module to your production environment on Render.

## 🚀 Deployment Steps

### Step 1: Deploy Code to Production

1. **Push to Git Repository**:
   ```bash
   git add .
   git commit -m "Add Weekly Beat Planning module"
   git push origin main
   ```

2. **Render Auto-Deploy**: 
   - Render will automatically detect the changes and redeploy
   - Wait for the deployment to complete (usually 2-3 minutes)

### Step 2: Run Database Migration

You have **3 options** to run the migration on production:

#### Option A: Web Interface (Recommended)
1. Open your browser and go to: `https://your-app-name.onrender.com/beat-planning-migration`
2. Log in to your admin account in another tab
3. Copy the JWT token from browser developer tools (Network tab → any API request → Authorization header)
4. Paste the token in the migration page
5. Click "Check Status" to verify current state
6. Click "Run Migration" to create the tables

#### Option B: API Endpoint
```bash
# Get your JWT token first by logging in
curl -X POST "https://your-app-name.onrender.com/api/migration/beat-planning" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Option C: Direct Script Execution
```bash
# SSH into Render (if available) or use Render Shell
node migrate_beat_planning_production.js
```

### Step 3: Verify Migration Success

1. **Check Migration Status**:
   ```bash
   curl "https://your-app-name.onrender.com/api/migration/beat-planning/status" \
     -H "Authorization: Bearer YOUR_JWT_TOKEN"
   ```

2. **Expected Response**:
   ```json
   {
     "success": true,
     "message": "Beat planning tables exist",
     "data": {
       "migrationRequired": false,
       "tableStatus": {
         "WeeklyBeatPlan": { "exists": true, "count": 0 },
         "DailyBeatPlan": { "exists": true, "count": 0 },
         "BeatCompletion": { "exists": true, "count": 0 }
       }
     }
   }
   ```

### Step 4: Test the Beat Planning System

1. **Admin Test**:
   - Log in as admin
   - Navigate to "Beat Plan Management"
   - Try generating a beat plan
   - Verify the plan appears in the list

2. **Salesman Test**:
   - Log in as salesman
   - Navigate to "Today's Beat Plan"
   - Verify the interface loads (may show "No beat plan" if none assigned)

## 🔧 Troubleshooting

### Migration Fails with Permission Error
```
Error: permission denied for table User
```
**Solution**: The database user needs CREATE and ALTER permissions. Contact your database provider.

### Tables Already Exist Error
```
Error: relation "WeeklyBeatPlan" already exists
```
**Solution**: This is normal. The migration script handles existing tables gracefully.

### Authentication Error
```
Error: Only admins can run migrations
```
**Solution**: Ensure you're using a JWT token from an admin user account.

### Connection Timeout
```
Error: connect ETIMEDOUT
```
**Solution**: Check if your production server is running and accessible.

## 📊 Database Schema Created

The migration creates these tables:

### WeeklyBeatPlan
- Stores weekly beat plans for salesmen
- Links to User table via salesmanId
- Tracks status (DRAFT, ACTIVE, LOCKED, COMPLETED)

### DailyBeatPlan  
- Stores daily area assignments
- Links to WeeklyBeatPlan via weeklyBeatId
- Tracks completion status per day

### BeatCompletion
- Stores individual area completion records
- Links to DailyBeatPlan and User tables
- Captures GPS location and visit details

## 🔒 Security Considerations

1. **Admin Only**: Migration endpoints require admin authentication
2. **Production Safety**: Migration scripts use IF NOT EXISTS to prevent data loss
3. **Error Handling**: Failed migrations don't crash the application
4. **Rollback**: Tables can be dropped manually if needed (backup first!)

## 📱 Flutter App Updates

The Flutter app will automatically work with the new backend once deployed. No additional steps needed for the mobile app.

## 🎯 Post-Deployment Checklist

- [ ] Migration completed successfully
- [ ] All 3 tables created (WeeklyBeatPlan, DailyBeatPlan, BeatCompletion)
- [ ] Admin can access Beat Plan Management
- [ ] Admin can generate beat plans
- [ ] Salesman can access Today's Beat Plan
- [ ] API endpoints respond correctly
- [ ] No errors in server logs

## 🆘 Emergency Rollback

If you need to remove the beat planning tables:

```sql
-- ⚠️ WARNING: This will delete all beat planning data!
DROP TABLE IF EXISTS "BeatCompletion" CASCADE;
DROP TABLE IF EXISTS "DailyBeatPlan" CASCADE;  
DROP TABLE IF EXISTS "WeeklyBeatPlan" CASCADE;
```

## 📞 Support

If you encounter issues:

1. Check the server logs in Render dashboard
2. Verify database connection is working
3. Ensure admin user has proper permissions
4. Test with the migration status endpoint first

## 🎉 Success!

Once migration is complete, your production system will have:

- ✅ Full beat planning functionality
- ✅ Admin beat plan management
- ✅ Salesman daily beat execution
- ✅ Analytics and reporting
- ✅ Offline-capable mobile app
- ✅ GPS tracking and verification

The Weekly Beat Planning module is now live in production! 🚀