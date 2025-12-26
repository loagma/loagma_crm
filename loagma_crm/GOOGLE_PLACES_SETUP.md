# Google Places API Setup Guide

This guide explains how to set up Google Places API integration to enable shop reviews and photos in the CRM application.

## Features Added

- **Enhanced Shop Details Dialog**: View detailed information about shops including:
  - Basic shop information (address, phone, website)
  - Customer reviews with ratings
  - Shop photos
  - Opening hours
  - Price level information

## Setup Instructions

### 1. Get Google Places API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Navigate to **APIs & Services** > **Credentials**
4. Click **Create Credentials** > **API Key**
5. Copy the generated API key

### 2. Enable Places API

1. In Google Cloud Console, go to **APIs & Services** > **Library**
2. Search for "Places API"
3. Click on **Places API** and click **Enable**

### 3. Configure API Key in App

The API key is already configured in `loagma_crm/lib/config/google_places_config.dart`:

```dart
class GooglePlacesConfig {
  static const String apiKey = 'AIzaSyDWHsbHNwwhNNiQJFDE2BIXMVYv6ZpDOrI';
  // ... other configuration
}
```

**Note**: The API key is already set up and should work immediately.

### 4. Optional: Restrict API Key (Recommended)

For security, restrict your API key:

1. In Google Cloud Console, go to **APIs & Services** > **Credentials**
2. Click on your API key
3. Under **API restrictions**, select **Restrict key**
4. Choose **Places API** from the list
5. Save the changes

## Usage

The Google Places API integration is now fully functional. Users can:

1. Go to **Admin Assignments Map** screen
2. Tap on any assignment marker to see nearby places
3. Tap on purple place markers to see detailed information
4. View enhanced shop details with three tabs:
   - **Details**: Basic information, contact details, opening hours
   - **Reviews**: Customer reviews and ratings from Google
   - **Photos**: Shop photos from Google Places

## Troubleshooting

### API Key Not Working

- Ensure the Places API is enabled for your project
- Check that your API key has the correct permissions
- Verify there are no IP or domain restrictions blocking the requests

### No Reviews/Photos Showing

- Not all places have reviews or photos available
- The place must be verified on Google Maps to have detailed information
- Some places may have limited data available

### Console Warnings

If you see warnings in the console about API key configuration, it means:
- The API key validation failed
- The API key doesn't have proper permissions for Places API

## Cost Considerations

Google Places API has usage-based pricing:
- Place Details requests: $17 per 1,000 requests
- Photos requests: $7 per 1,000 requests

Monitor your usage in Google Cloud Console to avoid unexpected charges.

## Current Status

✅ **API Key Configured**: The API key is already set up in GooglePlacesConfig
✅ **Google Maps-like Interface**: Draggable bottom sheet with tabbed content
✅ **Place Details**: Reviews, photos, and contact information
✅ **Error Handling**: Graceful fallbacks when data is unavailable