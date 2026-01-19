# Mapbox Setup for Live Salesman Tracking System

This directory contains configuration files and setup instructions for integrating Mapbox Maps SDK with the Live Salesman Tracking System.

## Overview

The Live Salesman Tracking System uses Mapbox for advanced mapping capabilities including:
- Interactive map display with zoom, pan, and rotation
- Real-time marker updates for salesman locations
- Route visualization with polylines
- Clustering for multiple nearby salesmen
- Custom marker styling for different user states

## Setup Instructions

### 1. Create Mapbox Account

1. Visit [https://account.mapbox.com/auth/signup/](https://account.mapbox.com/auth/signup/)
2. Sign up for a new account or log in to existing account
3. Verify your email address

### 2. Generate Access Token

1. Navigate to your [Mapbox Account Dashboard](https://account.mapbox.com/)
2. Go to "Access tokens" section
3. Click "Create a token"
4. Configure token with the following scopes:
   - `styles:read` - Required for map styles
   - `fonts:read` - Required for map fonts
   - `datasets:read` - Required for custom data
   - `vision:read` - Optional for advanced features
5. Set URL restrictions (recommended for production):
   - Add your domain(s) for web deployment
   - Leave empty for development/testing
6. Copy the generated access token

### 3. Configure Token Permissions

For the Live Salesman Tracking System, ensure your token has:
- **Public scopes**: `styles:read`, `fonts:read`
- **Secret scopes**: None required for basic functionality
- **URL restrictions**: Configure based on deployment environment

### 4. Select Map Style

Choose from available map styles:
- **Streets**: `mapbox://styles/mapbox/streets-v12` (recommended for business use)
- **Satellite**: `mapbox://styles/mapbox/satellite-v9` (for aerial view)
- **Outdoors**: `mapbox://styles/mapbox/outdoors-v12` (for field operations)
- **Light**: `mapbox://styles/mapbox/light-v11` (minimal style)
- **Dark**: `mapbox://styles/mapbox/dark-v11` (dark theme)

### 5. Security Configuration

1. **Token Security**:
   - Store access tokens securely using environment variables
   - Never commit tokens to version control
   - Use different tokens for development and production
   - Regularly rotate tokens

2. **Usage Monitoring**:
   - Set up usage alerts in Mapbox dashboard
   - Monitor API usage to avoid unexpected charges
   - Configure rate limiting if needed

### 6. Flutter Integration

After completing the setup above:
1. Add Mapbox Maps SDK dependency to `pubspec.yaml`
2. Configure platform-specific settings (Android/iOS)
3. Initialize Mapbox in your Flutter app
4. Implement map service class

## Configuration Files

- `mapbox_config_template.dart` - Template for Mapbox configuration
- `mapbox_styles.json` - Available map styles configuration
- `setup_mapbox.md` - Detailed setup instructions
- `security_guidelines.md` - Security best practices

## Next Steps

1. Complete the account setup following the instructions above
2. Update the configuration files with your specific tokens and settings
3. Proceed to Task 3: Flutter Project Structure and Dependencies
4. Implement Mapbox integration in Task 7: Mapbox Integration and Map Display

## Support

- [Mapbox Documentation](https://docs.mapbox.com/)
- [Mapbox Flutter SDK](https://docs.mapbox.com/flutter/maps/guides/)
- [Mapbox Support](https://support.mapbox.com/)