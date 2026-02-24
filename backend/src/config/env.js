import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: join(__dirname, '../../.env') });

// Validate and auto-fix DATABASE_URL configuration for Neon
if (process.env.DATABASE_URL) {
  let dbUrl = process.env.DATABASE_URL;
  let wasModified = false;
  
  // Check if this is a Neon database (contains neon.tech)
  if (dbUrl.includes('neon.tech')) {
    const hasSslMode = dbUrl.includes('sslmode=');
    const hasChannelBinding = dbUrl.includes('channel_binding=');
    const hasConnectTimeout = dbUrl.includes('connect_timeout=');
    
    // Auto-append missing parameters
    if (!hasSslMode) {
      const separator = dbUrl.includes('?') ? '&' : '?';
      dbUrl += `${separator}sslmode=require`;
      wasModified = true;
    }
    
    if (!hasChannelBinding) {
      const separator = dbUrl.includes('?') ? '&' : '?';
      dbUrl += `${separator}channel_binding=require`;
      wasModified = true;
    }
    
    if (!hasConnectTimeout) {
      const separator = dbUrl.includes('?') ? '&' : '?';
      dbUrl += `${separator}connect_timeout=15`;
      wasModified = true;
    }
    
    // Update the environment variable if we made changes
    if (wasModified) {
      process.env.DATABASE_URL = dbUrl;
      console.log('✅ Auto-updated DATABASE_URL with required Neon SSL parameters');
      console.log('   Added: sslmode=require, channel_binding=require, connect_timeout=15');
    }
    
    // Show warning if still missing critical parameters (shouldn't happen after auto-fix)
    if (!hasSslMode || !hasConnectTimeout) {
      console.warn('\n⚠️  ============================================');
      console.warn('⚠️  NEON DATABASE CONFIGURATION WARNING');
      console.warn('⚠️  ============================================');
      console.warn('⚠️  Your DATABASE_URL appears to be a Neon database but may be missing required parameters.');
      console.warn('⚠️  Neon requires SSL and connection timeout settings.');
      console.warn('\n📝 Required DATABASE_URL format for Neon:');
      console.warn('   postgresql://user:password@host:5432/database?sslmode=require&channel_binding=require&connect_timeout=15');
      console.warn('\n🔧 If deploying on Render:');
      console.warn('   1. Go to your Render dashboard');
      console.warn('   2. Navigate to Environment Variables');
      console.warn('   3. Update DATABASE_URL to include: ?sslmode=require&channel_binding=require&connect_timeout=15');
      console.warn('⚠️  ============================================\n');
    }
  }
}

// Redis defaults for live tracking cache
if (process.env.REDIS_ENABLED === undefined) {
  process.env.REDIS_ENABLED =
    process.env.NODE_ENV === 'production' ? 'true' : 'false';
}
