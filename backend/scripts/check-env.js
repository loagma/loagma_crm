/**
 * Environment Variables Validation Script
 * Checks all required and optional environment variables
 */

import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load .env file
dotenv.config({ path: join(__dirname, '../.env') });

console.log('🔍 Checking Environment Variables...\n');

// Define required and optional variables
const required = {
  DATABASE_URL: {
    description: 'PostgreSQL database connection string (Neon/supabase)',
    example: 'postgresql://user:password@host:port/dbname?sslmode=require',
    validate: (val) => {
      if (!val) return false;
      // Check if it starts with postgresql:// or postgres://
      return val.startsWith('postgresql://') || val.startsWith('postgres://');
    },
    fix: 'Get connection string from Neon/supabase dashboard'
  },
  JWT_SECRET: {
    description: 'Secret key for JWT token signing',
    example: 'your-secret-key-here-min-32-chars',
    validate: (val) => val && val.length >= 32,
    fix: 'Generate a secure random string (min 32 characters)'
  }
};

const optional = {
  PORT: {
    description: 'Server port',
    default: '5000',
    validate: (val) => !val || (!isNaN(parseInt(val)) && parseInt(val) > 0 && parseInt(val) < 65536)
  },
  HOST: {
    description: 'Server host',
    default: '0.0.0.0',
    validate: () => true
  },
  WS_PORT: {
    description: 'WebSocket server port',
    default: '8081',
    validate: (val) => !val || (!isNaN(parseInt(val)) && parseInt(val) > 0 && parseInt(val) < 65536)
  },
  NODE_ENV: {
    description: 'Node environment (development/production)',
    default: 'development',
    validate: (val) => !val || ['development', 'production', 'test'].includes(val)
  },
  CORS_ORIGIN: {
    description: 'CORS allowed origins',
    default: '*',
    validate: () => true
  },
  // Twilio SMS (optional - falls back to mock SMS)
  TWILIO_SID: {
    description: 'Twilio Account SID (optional - for SMS)',
    default: 'Not set (will use mock SMS)',
    validate: () => true
  },
  TWILIO_ACCOUNT_SID: {
    description: 'Twilio Account SID (alternative name)',
    default: 'Not set',
    validate: () => true
  },
  TWILIO_AUTH_TOKEN: {
    description: 'Twilio Auth Token (optional - for SMS)',
    default: 'Not set (will use mock SMS)',
    validate: () => true
  },
  TWILIO_PHONE: {
    description: 'Twilio Phone Number (optional - for SMS)',
    default: 'Not set',
    validate: () => true
  },
  USE_MOCK_SMS: {
    description: 'Use mock SMS (true/false)',
    default: 'false',
    validate: (val) => !val || ['true', 'false'].includes(val)
  },
  // Cloudinary (optional - for image uploads)
  CLOUDINARY_CLOUD_NAME: {
    description: 'Cloudinary Cloud Name (optional - for image uploads)',
    default: 'Not set (image uploads will fail)',
    validate: () => true
  },
  CLOUDINARY_API_KEY: {
    description: 'Cloudinary API Key (optional)',
    default: 'Not set',
    validate: () => true
  },
  CLOUDINARY_API_SECRET: {
    description: 'Cloudinary API Secret (optional)',
    default: 'Not set',
    validate: () => true
  },
  CLOUDINARY_SECURE: {
    description: 'Use HTTPS for Cloudinary (true/false)',
    default: 'false',
    validate: (val) => !val || ['true', 'false'].includes(val)
  },
  // Google Maps (optional)
  GOOGLE_MAPS_API_KEY: {
    description: 'Google Maps API Key (optional - for Places API)',
    default: 'Not set (Google Places will fail)',
    validate: () => true
  },
  // Master OTP (optional - for testing)
  MASTER_OTP: {
    description: 'Master OTP for testing (optional)',
    default: 'Not set',
    validate: () => true
  }
};

let hasErrors = false;
let hasWarnings = false;

// Check required variables
console.log('📋 REQUIRED VARIABLES:');
console.log('─'.repeat(80));

for (const [key, config] of Object.entries(required)) {
  const value = process.env[key];
  const isValid = config.validate(value);
  
  if (!isValid) {
    hasErrors = true;
    console.log(`❌ ${key}`);
    console.log(`   Description: ${config.description}`);
    if (value) {
      console.log(`   Current: ${value.substring(0, 20)}... (INVALID)`);
    } else {
      console.log(`   Current: Not set`);
    }
    console.log(`   Example: ${config.example}`);
    console.log(`   Fix: ${config.fix}`);
    console.log('');
  } else {
    console.log(`✅ ${key}`);
    console.log(`   Description: ${config.description}`);
    // Mask sensitive values
    if (key === 'DATABASE_URL') {
      const masked = value.replace(/:[^:@]+@/, ':****@');
      console.log(`   Current: ${masked.substring(0, 60)}...`);
    } else if (key === 'JWT_SECRET') {
      console.log(`   Current: ${value.substring(0, 8)}...${value.substring(value.length - 4)} (${value.length} chars)`);
    } else {
      console.log(`   Current: ${value.substring(0, 40)}...`);
    }
    console.log('');
  }
}

// Check optional variables
console.log('\n📋 OPTIONAL VARIABLES:');
console.log('─'.repeat(80));

for (const [key, config] of Object.entries(optional)) {
  const value = process.env[key];
  const isValid = !value || config.validate(value);
  const isSet = !!value;
  const displayValue = isSet ? value : config.default;
  
  if (!isValid) {
    hasWarnings = true;
    console.log(`⚠️  ${key} (INVALID)`);
    console.log(`   Description: ${config.description}`);
    console.log(`   Current: ${value} (INVALID FORMAT)`);
    console.log(`   Default: ${config.default}`);
    console.log('');
  } else {
    const status = isSet ? '✅' : '⚪';
    console.log(`${status} ${key} ${isSet ? '(set)' : '(using default)'}`);
    console.log(`   Description: ${config.description}`);
    // Mask sensitive values
    if (key.includes('SECRET') || key.includes('TOKEN') || key.includes('KEY')) {
      if (isSet && displayValue !== 'Not set') {
        console.log(`   Current: ${displayValue.substring(0, 8)}...${displayValue.substring(displayValue.length - 4)}`);
      } else {
        console.log(`   Current: ${displayValue}`);
      }
    } else {
      console.log(`   Current: ${displayValue}`);
    }
    console.log('');
  }
}

// Check database URL format
if (process.env.DATABASE_URL) {
  const dbUrl = process.env.DATABASE_URL;
  console.log('🔗 DATABASE URL CHECK:');
  console.log('─'.repeat(80));
  
  // Check for Neon database
  if (dbUrl.includes('neon.tech')) {
    console.log('✅ Using Neon database');
    
    // Check for SSL mode
    if (!dbUrl.includes('sslmode=require') && !dbUrl.includes('sslmode=prefer')) {
      hasWarnings = true;
      console.log('⚠️  Missing sslmode parameter - recommended: ?sslmode=require');
      console.log('   Fix: Add ?sslmode=require to DATABASE_URL for Neon');
    } else {
      console.log('✅ SSL mode configured');
    }
    
    // Check for pooler
    if (dbUrl.includes('-pooler')) {
      console.log('✅ Using connection pooler (recommended for Neon)');
    } else {
      console.log('ℹ️  Not using pooler - consider using pooler endpoint for better performance');
    }
  } else {
    console.log('ℹ️  Using non-Neon database');
  }
  
  // Check if it looks like a valid connection string
  if (!dbUrl.includes('://')) {
    hasErrors = true;
    console.log('❌ Invalid DATABASE_URL format - missing protocol');
  }
  console.log('');
}

// Check Twilio configuration
console.log('📱 TWILIO SMS CHECK:');
console.log('─'.repeat(80));
const hasTwilioSid = !!(process.env.TWILIO_SID || process.env.TWILIO_ACCOUNT_SID);
const hasTwilioToken = !!process.env.TWILIO_AUTH_TOKEN;
const hasTwilioPhone = !!process.env.TWILIO_PHONE;

if (hasTwilioSid && hasTwilioToken && hasTwilioPhone) {
  console.log('✅ Twilio SMS configured - real SMS will be sent');
} else if (process.env.USE_MOCK_SMS === 'true') {
  console.log('✅ Mock SMS mode enabled - OTP will be logged to console');
} else {
  hasWarnings = true;
  console.log('⚠️  Twilio not fully configured - will fall back to mock SMS');
  console.log('   Missing:');
  if (!hasTwilioSid) console.log('     - TWILIO_SID or TWILIO_ACCOUNT_SID');
  if (!hasTwilioToken) console.log('     - TWILIO_AUTH_TOKEN');
  if (!hasTwilioPhone) console.log('     - TWILIO_PHONE');
  console.log('   Set USE_MOCK_SMS=true to explicitly use mock SMS');
}

console.log('');

// Check Cloudinary configuration
console.log('☁️  CLOUDINARY CHECK:');
console.log('─'.repeat(80));
const hasCloudinaryName = !!process.env.CLOUDINARY_CLOUD_NAME;
const hasCloudinaryKey = !!process.env.CLOUDINARY_API_KEY;
const hasCloudinarySecret = !!process.env.CLOUDINARY_API_SECRET;

if (hasCloudinaryName && hasCloudinaryKey && hasCloudinarySecret) {
  console.log('✅ Cloudinary configured - image uploads will work');
} else {
  hasWarnings = true;
  console.log('⚠️  Cloudinary not configured - image uploads will fail');
  console.log('   Missing:');
  if (!hasCloudinaryName) console.log('     - CLOUDINARY_CLOUD_NAME');
  if (!hasCloudinaryKey) console.log('     - CLOUDINARY_API_KEY');
  if (!hasCloudinarySecret) console.log('     - CLOUDINARY_API_SECRET');
}

console.log('');

// Summary
console.log('─'.repeat(80));
console.log('📊 SUMMARY:');
console.log('─'.repeat(80));

if (hasErrors) {
  console.log('❌ ERRORS FOUND: Some required variables are missing or invalid');
  console.log('   Please fix the errors above before running the server');
  process.exit(1);
} else {
  console.log('✅ All required variables are configured correctly');
}

if (hasWarnings) {
  console.log('⚠️  WARNINGS: Some optional variables are missing');
  console.log('   The server will run but some features may not work');
} else {
  console.log('✅ All optional variables are configured');
}

console.log('\n✅ Environment check complete!');
