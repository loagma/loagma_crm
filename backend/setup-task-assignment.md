# Task Assignment Setup Guide

## Quick Setup

### 1. Environment Variables
Add to your `.env` file:
```bash
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

### 2. Database Migration
```bash
# Generate Prisma Client
npx prisma generate

# Run migration
npx prisma migrate dev --name add_task_assignment_and_shops

# Or if already migrated
npx prisma migrate deploy
```

### 3. Start Server
```bash
npm run dev
```

## API Endpoints

All endpoints are prefixed with `/task-assignments`

### Available Routes:
- `GET /salesmen` - Get all salesmen
- `GET /location/pincode/:pincode` - Get location by pin code
- `POST /assignments/areas` - Assign areas to salesman
- `GET /assignments/salesman/:salesmanId` - Get assignments
- `DELETE /assignments/:assignmentId` - Delete assignment
- `POST /businesses/search` - Search businesses via Google Places
- `POST /shops` - Save shops to database
- `GET /shops/salesman/:salesmanId` - Get shops by salesman
- `GET /shops/pincode/:pincode` - Get shops by pincode
- `PATCH /shops/:shopId/stage` - Update shop stage

## Testing

### Test with cURL:

```bash
# Get salesmen
curl http://localhost:5000/task-assignments/salesmen \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get location
curl http://localhost:5000/task-assignments/location/pincode/400001 \
  -H "Authorization: Bearer YOUR_TOKEN"

# Search businesses
curl -X POST http://localhost:5000/task-assignments/businesses/search \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "pincode": "400001",
    "areas": ["Andheri"],
    "businessTypes": ["grocery", "cafe"]
  }'
```

## Google Maps API Setup

1. Go to https://console.cloud.google.com/
2. Create a new project or select existing
3. Enable these APIs:
   - Places API
   - Geocoding API
   - Maps JavaScript API
4. Create API Key
5. Add to `.env` file

## Database Schema

Two new tables added:
- `TaskAssignment` - Stores area assignments
- `Shop` - Stores discovered shops with stages

## Notes

- All routes require authentication
- Google Maps API key is required for business search
- Pin code service uses free India Post API
- Shops are deduplicated by Google Place ID
