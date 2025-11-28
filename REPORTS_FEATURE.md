# Performance Reports Feature

## Overview
The Performance Reports feature allows Admin users to monitor salesman performance and track business growth through comprehensive analytics and visualizations.

## Access
- **Role Required**: Admin
- **Navigation**: Dashboard → Performance Reports
- **Route**: `/dashboard/admin/reports`

## Features

### 1. **Overview Tab** 📊
Provides high-level statistics and recent activity.

#### Statistics Cards:
- **New Accounts**: Number of accounts created in selected period
- **Active**: Number of active accounts
- **Approved**: Number of approved accounts
- **Pending**: Number of pending approval accounts
- **Total Accounts**: Total accounts in system
- **Active Salesmen**: Number of unique salesmen who created accounts

#### Recent Accounts List:
- Shows up to 10 most recent accounts
- Displays:
  - Account name and business name
  - Created by (salesman name)
  - Time ago (e.g., "2h ago", "3d ago")
  - Approval status (verified/pending icon)
  - Location indicator (if geolocation captured)

### 2. **Salesmen Tab** 👥
Detailed performance breakdown by salesman.

#### Features:
- **Ranked List**: Salesmen sorted by number of accounts created
- **Expandable Cards**: Tap to see detailed breakdown
- **Performance Metrics**:
  - Total accounts created
  - Active accounts
  - Approved accounts
- **Recent Activity**: Shows last 5 accounts created by each salesman with:
  - Account name
  - Creation date and time
  - Location indicator

#### Use Cases:
- Identify top performers
- Monitor individual salesman productivity
- Track approval rates per salesman
- See when accounts were created (time patterns)

### 3. **Map View** 🗺️
Visual representation of account locations.

#### Features:
- **Interactive Google Map**: Shows all accounts with geolocation
- **Custom Markers**: Yellow markers for each account
- **Info Windows**: Tap marker to see:
  - Person name
  - Business name
- **Auto-Center**: Map automatically centers on average location
- **Counter**: Shows total accounts with location data

#### Use Cases:
- Visualize geographic distribution of customers
- Identify coverage gaps
- Plan territory assignments
- Analyze market penetration by area

## Time Period Filters

### Quick Filters:
- **Today**: Accounts created today (since midnight)
- **Week**: Last 7 days
- **Month**: Last 30 days
- **All**: All time data

### Features:
- **Instant Switch**: Tap any period to update all tabs
- **Refresh Button**: Reload data manually
- **Real-time Updates**: Data reflects current state

## Data Displayed

### Account Information:
- Person name
- Business name
- Contact number
- Created by (salesman)
- Creation date/time
- Approval status
- Active status
- Location (if captured)

### Calculated Metrics:
- Total accounts per salesman
- Active vs inactive accounts
- Approved vs pending accounts
- Time-based trends
- Geographic distribution

## Performance Monitoring

### Key Metrics to Track:

1. **Volume Metrics**:
   - How many accounts created per day/week/month
   - Growth rate over time
   - Accounts per salesman

2. **Quality Metrics**:
   - Approval rate (approved/total)
   - Active rate (active/total)
   - Accounts with complete information (location, etc.)

3. **Efficiency Metrics**:
   - Time to create accounts
   - Geographic coverage
   - Salesman productivity comparison

4. **Geographic Metrics**:
   - Coverage by area
   - Density of accounts
   - Territory performance

## Business Insights

### What You Can Learn:

1. **Top Performers**:
   - Which salesmen are most productive
   - Who needs training or support
   - Best practices from top performers

2. **Time Patterns**:
   - Peak creation times
   - Day-of-week patterns
   - Seasonal trends

3. **Geographic Insights**:
   - Which areas have most customers
   - Underserved territories
   - Expansion opportunities

4. **Quality Indicators**:
   - Approval rates by salesman
   - Data completeness
   - Active customer ratio

## Usage Examples

### Scenario 1: Daily Performance Review
1. Select "Today" filter
2. Check Overview tab for daily statistics
3. Review Salesmen tab to see who created accounts
4. Check Map view to see geographic spread

### Scenario 2: Weekly Team Meeting
1. Select "Week" filter
2. Review top performers in Salesmen tab
3. Discuss approval rates and quality
4. Plan territory assignments using Map view

### Scenario 3: Monthly Business Review
1. Select "Month" filter
2. Analyze growth trends in Overview
3. Compare salesman performance
4. Identify areas for improvement

### Scenario 4: Territory Planning
1. Use Map view to see customer distribution
2. Identify coverage gaps
3. Assign salesmen to underserved areas
4. Track progress over time

## Technical Details

### Data Source:
- Fetches from `/accounts` API endpoint
- Filters by date range on client side
- Groups and aggregates data for display

### Performance:
- Loads all accounts once
- Client-side filtering for fast switching
- Efficient map rendering with markers
- Lazy loading for large datasets

### Refresh:
- Manual refresh button available
- Automatic refresh on period change
- Real-time data from database

## Future Enhancements (Potential)

1. **Export Reports**: Download as PDF/Excel
2. **Custom Date Ranges**: Select specific start/end dates
3. **More Metrics**: Revenue, conversion rates, etc.
4. **Comparison Views**: Compare periods, salesmen
5. **Notifications**: Alerts for milestones
6. **Goals/Targets**: Set and track targets
7. **Heatmaps**: Density visualization on map
8. **Charts**: Line/bar charts for trends

## Tips for Best Results

1. **Regular Monitoring**: Check reports daily/weekly
2. **Set Expectations**: Define targets for salesmen
3. **Recognize Performance**: Acknowledge top performers
4. **Address Issues**: Support struggling salesmen
5. **Use Location Data**: Encourage geolocation capture
6. **Quality Over Quantity**: Focus on approval rates
7. **Territory Balance**: Ensure fair distribution
8. **Data Completeness**: Ensure all fields filled

## Troubleshooting

### No Data Showing:
- Check if accounts exist in selected period
- Verify API connection
- Try "All" filter to see if any data exists

### Map Not Loading:
- Check internet connection
- Verify Google Maps API key configured
- Ensure accounts have latitude/longitude data

### Salesman Names Missing:
- Verify accounts have `createdBy` field
- Check user data is properly linked
- May show "Unknown" for old data

### Performance Issues:
- Use shorter time periods for large datasets
- Refresh page if data seems stale
- Check network connection

## Support

For issues or questions:
1. Check this documentation
2. Verify data exists in database
3. Check API endpoints are working
4. Review browser console for errors
