# Credential Setup Guide

This guide provides step-by-step instructions for setting up credentials securely for the Loagma CRM application.

## 🚨 Security Notice

**NEVER commit sensitive credentials to version control!** This includes:
- Service account JSON files
- API keys
- Environment files with secrets
- Private keys or certificates

## Quick Start

1. **Copy the environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Set up Google Cloud credentials** (choose one method):
   - Method A: Environment variable with JSON content (recommended for production)
   - Method B: Service account file path (recommended for development)

3. **Fill in your environment variables** in the `.env` file

4. **Test your setup** by running the application

## Detailed Setup Instructions

### Method A: Environment Variable with JSON Content (Recommended for Production)

1. **Get your service account JSON from Google Cloud Console:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Select your project
   - Navigate to "IAM & Admin" → "Service Accounts"
   - Find your service account or create a new one
   - Click "Actions" → "Manage keys"
   - Click "Add Key" → "Create new key"
   - Choose JSON format and download

2. **Set the environment variable:**
   ```bash
   # In your .env file, add the entire JSON content as a single line:
   GOOGLE_SERVICE_ACCOUNT_JSON='{"type":"service_account","project_id":"your-project",...}'
   ```

   **Important:** The JSON must be properly escaped and on a single line.

### Method B: Service Account File Path (Recommended for Development)

1. **Download your service account JSON file** (same as Method A, step 1)

2. **Place the file in a secure location:**
   ```bash
   # Create a secure directory (outside your project)
   mkdir -p ~/.config/gcloud/
   
   # Move your service account file there
   mv ~/Downloads/your-service-account.json ~/.config/gcloud/service-account.json
   
   # Set secure permissions
   chmod 600 ~/.config/gcloud/service-account.json
   ```

3. **Set the environment variable:**
   ```bash
   # In your .env file:
   GOOGLE_APPLICATION_CREDENTIALS=/home/yourusername/.config/gcloud/service-account.json
   ```

### Firebase Configuration

1. **Get your Firebase configuration:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Go to Project Settings (gear icon)
   - In the "General" tab, find your project configuration

2. **Add to your .env file:**
   ```bash
   FIREBASE_PROJECT_ID=your-firebase-project-id
   FIREBASE_API_KEY=your-firebase-api-key
   ```

## Environment Variables Reference

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `GOOGLE_SERVICE_ACCOUNT_JSON` | Service account JSON content | `'{"type":"service_account",...}'` |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to service account file | `/path/to/service-account.json` |
| `FIREBASE_PROJECT_ID` | Firebase project identifier | `my-project-12345` |
| `FIREBASE_API_KEY` | Firebase API key | `AIzaSyC...` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ENVIRONMENT` | Environment type | `development` |
| `DEBUG_MODE` | Enable debug logging | `true` |
| `API_BASE_URL` | Backend API URL | `http://localhost:3000` |

## Troubleshooting

### Common Issues

#### "Service account credentials not found"
- **Cause:** Neither `GOOGLE_SERVICE_ACCOUNT_JSON` nor `GOOGLE_APPLICATION_CREDENTIALS` is set
- **Solution:** Set one of these environment variables following the methods above

#### "Invalid service account JSON"
- **Cause:** Malformed JSON in `GOOGLE_SERVICE_ACCOUNT_JSON`
- **Solution:** Ensure the JSON is properly escaped and on a single line

#### "Permission denied accessing service account file"
- **Cause:** Incorrect file permissions or path
- **Solution:** Check file exists and has correct permissions (`chmod 600`)

#### "Firebase authentication failed"
- **Cause:** Incorrect Firebase configuration
- **Solution:** Verify `FIREBASE_PROJECT_ID` and `FIREBASE_API_KEY` are correct

### Validation Commands

Test your setup with these commands:

```bash
# Check if environment variables are set
echo $GOOGLE_APPLICATION_CREDENTIALS
echo $FIREBASE_PROJECT_ID

# Verify service account file exists and is readable
ls -la $GOOGLE_APPLICATION_CREDENTIALS

# Test Firebase connection (if you have Firebase CLI)
firebase projects:list
```

## Security Best Practices

### Development Environment

1. **Use separate service accounts** for development and production
2. **Store credentials outside your project directory**
3. **Set restrictive file permissions** (`chmod 600`)
4. **Never share credentials** via email, chat, or other insecure channels
5. **Rotate credentials regularly**

### Production Environment

1. **Use environment variables** or secure secret management services
2. **Enable audit logging** for credential access
3. **Use least-privilege principle** for service account permissions
4. **Monitor for unusual access patterns**
5. **Have a credential rotation plan**

### Team Collaboration

1. **Each developer should have their own credentials**
2. **Use shared development projects** separate from production
3. **Document the credential setup process** for new team members
4. **Use secure password managers** for sharing when necessary

## Getting Help

If you encounter issues:

1. **Check the troubleshooting section** above
2. **Verify your environment variables** are set correctly
3. **Check file permissions** and paths
4. **Review the application logs** for specific error messages
5. **Contact the development team** with specific error details

## Additional Resources

- [Google Cloud Service Account Documentation](https://cloud.google.com/iam/docs/service-accounts)
- [Firebase Admin SDK Setup](https://firebase.google.com/docs/admin/setup)
- [Environment Variables Best Practices](https://12factor.net/config)
- [Security Best Practices for API Keys](https://cloud.google.com/docs/authentication/api-keys)