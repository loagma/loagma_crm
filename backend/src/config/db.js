// src/config/db.js
import './env.js';
import { PrismaClient } from '@prisma/client';

// Configure Prisma with connection pooling and retry logic for Neon
const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
  datasources: {
    db: {
      url: process.env.DATABASE_URL,
    },
  },
});

// Connection state
let isConnected = false;
let connectionRetries = 0;
const MAX_RETRIES = 5;
const RETRY_DELAY = 3000; // 3 seconds

/**
 * Test database connection with retry logic
 */
async function connectWithRetry() {
  if (isConnected) {
    return true;
  }

  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      await prisma.$connect();
      isConnected = true;
      connectionRetries = 0;
      console.log('✅ Connected to PostgreSQL via Prisma');
      return true;
    } catch (error) {
      connectionRetries = attempt;
      const errorMessage = error.message || error.toString();
      
      // Check if it's a connection error
      if (errorMessage.includes("Can't reach database server") || 
          errorMessage.includes("P1001") ||
          errorMessage.includes("ECONNREFUSED")) {
        
        if (attempt < MAX_RETRIES) {
          console.log(`⚠️ Database connection attempt ${attempt}/${MAX_RETRIES} failed. Retrying in ${RETRY_DELAY/1000}s...`);
          await new Promise(resolve => setTimeout(resolve, RETRY_DELAY));
          continue;
        } else {
          console.error('❌ Failed to connect to database after', MAX_RETRIES, 'attempts');
          console.error('❌ Please check:');
          console.error('   1. Database server is running');
          console.error('   2. DATABASE_URL in .env is correct');
          console.error('   3. Network/firewall allows connection');
          console.error('   4. For Neon: Database might be paused - check Neon dashboard');
          console.error('❌ Prisma connection error:', errorMessage);
          isConnected = false;
          return false;
        }
      } else {
        // Other errors (auth, etc.)
        console.error('❌ Prisma connection error:', errorMessage);
        isConnected = false;
        return false;
      }
    }
  }
  
  return false;
}

// Initial connection attempt
connectWithRetry().catch(err => {
  console.error('❌ Initial database connection failed:', err);
});

// Handle disconnections
prisma.$on('beforeExit', async () => {
  console.log('🔄 Prisma client disconnecting...');
  isConnected = false;
});

// Graceful shutdown handler
process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down gracefully...');
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n🛑 Shutting down gracefully...');
  await prisma.$disconnect();
  process.exit(0);
});

// Health check function
export async function checkDatabaseHealth() {
  try {
    await prisma.$queryRaw`SELECT 1`;
    return { healthy: true, connected: isConnected };
  } catch (error) {
    isConnected = false;
    // Try to reconnect
    await connectWithRetry();
    return { healthy: false, connected: false, error: error.message };
  }
}

export default prisma;
