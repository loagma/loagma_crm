# Beat Planning Module - Simplified

## Overview
Weekly beat planning system that distributes areas across Monday-Saturday (6 working days) for salesmen.

## How It Works

### For Admin
1. Go to **Beat Plan Management** screen
2. Click **+ New Plan** button
3. Select a salesman (auto-loads their assigned areas/pincodes)
4. Choose week start date
5. Click **Generate Random Beat Plan**
6. System automatically distributes all areas across Mon-Sat

### For Salesman
1. Go to **My Beat Plan** from dashboard
2. See this week's plan with day-by-day breakdown
3. Click on any day to see assigned areas
4. Mark areas as "Done" when completed (only for today)

## Key Features

### Random Area Distribution
- All areas from salesman's assignments are shuffled
- Distributed evenly across 6 days (Mon-Sat)
- No area appears on multiple days
- Example: 12 areas = 2 areas per day

### Simple Status
- **ACTIVE** - Plan is ready and visible to salesman
- No complex draft/lock workflow

### Area Sources
1. First tries: AreaAssignment table (salesman's assigned areas)
2. Fallback: Account table (areas from accounts with matching pincodes)

## API Endpoints

### Admin
- `POST /beat-plans/generate` - Create new beat plan
- `GET /beat-plans` - List all beat plans
- `DELETE /beat-plans/:id` - Delete a beat plan
- `GET /beat-plans/:id` - Get plan details

### Salesman
- `GET /beat-plans/today` - Get today's areas
- `GET /beat-plans/this-week` - Get full week plan
- `POST /beat-plans/complete-area` - Mark area done

## Database Tables

### WeeklyBeatPlan
- salesmanId, salesmanName
- weekStartDate, weekEndDate (Mon-Sat)
- pincodes[], totalAreas
- status (ACTIVE)

### DailyBeatPlan
- weeklyBeatId, dayOfWeek (1-6)
- assignedAreas[]
- status (PLANNED/COMPLETED)

### BeatCompletion
- dailyBeatId, areaName
- accountsVisited, completedAt
- latitude, longitude (optional)

## Troubleshooting

### "Only 1 area assigned"
- Check if salesman has area assignments
- Verify areas array in AreaAssignment is populated
- Check if accounts exist for the pincodes

### "No beat plan for today"
- Verify a plan exists for current week
- Check if today is Mon-Sat (no Sunday plans)
- Ensure plan status is ACTIVE

### Areas not showing
- Backend logs show area distribution
- Check `📍 Found X areas for distribution` in logs
- Verify AreaAssignment has areas[] populated
