# OTP Configuration Guide

## Overview
The authentication system now supports **two types of OTP verification**:

1. **Generated OTP** - Unique OTP sent via SMS to the user's phone
2. **Master OTP** - Universal OTP that works for all users (for testing/development)

## How It Works

### Generated OTP (Normal Flow)
1. User requests OTP via `/auth/send-otp`
2. System generates a unique 6-digit OTP
3. OTP is sent via SMS to the user's phone
4. OTP is valid for 5 minutes
5. User enters the OTP to verify and login

### Master OTP (Universal Access)
- A single OTP that works for **all users**
- Configured via environment variable `MASTER_OTP`
- Default value: `123456`
- No expiration time
- Useful for:
  - Development and testing
  - Demo purposes
  - Emergency access
  - Bypassing SMS costs during development

## Configuration

### Setting the Master OTP

Edit your `.env` file:

```env
# Master OTP Configuration
MASTER_OTP=123456
```

You can change `123456` to any value you prefer.

### Default Behavior

If `MASTER_OTP` is not set in the environment variables, the system defaults to `123456`.

## Usage Examples

### Example 1: Login with Generated OTP
```
1. POST /auth/send-otp
   Body: { "contactNumber": "9876543210" }
   
2. User receives SMS with OTP: "456789"

3. POST /auth/verify-otp
   Body: { "contactNumber": "9876543210", "otp": "456789" }
   
✅ Login successful
```

### Example 2: Login with Master OTP
```
1. POST /auth/send-otp
   Body: { "contactNumber": "9876543210" }
   
2. User ignores SMS and uses master OTP

3. POST /auth/verify-otp
   Body: { "contactNumber": "9876543210", "otp": "123456" }
   
✅ Login successful (using master OTP)
```

## Security Considerations

⚠️ **Important Security Notes:**

1. **Production Environment**: 
   - Use a strong, random master OTP
   - Consider disabling master OTP in production by removing the env variable
   - Or set it to a complex value known only to administrators

2. **Development Environment**:
   - Master OTP is convenient for testing
   - Saves SMS costs during development
   - Allows quick testing without waiting for SMS

3. **Best Practice**:
   - Keep master OTP secret
   - Don't commit actual master OTP values to version control
   - Use different master OTPs for different environments

## Logging

The system logs which OTP method was used:
- `🔐 Generated OTP verified successfully` - User used the SMS OTP
- `🔓 Master OTP used for login` - User used the master OTP

## Testing

To test the master OTP functionality:

```bash
# 1. Send OTP request
curl -X POST http://localhost:5000/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"contactNumber": "9876543210"}'

# 2. Verify with master OTP
curl -X POST http://localhost:5000/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"contactNumber": "9876543210", "otp": "123456"}'
```

## Disabling Master OTP

To disable master OTP in production:

1. Remove or comment out the `MASTER_OTP` line in `.env`
2. Or set it to an empty string: `MASTER_OTP=`

When disabled, only generated OTPs will work.
