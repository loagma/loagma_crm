// src/config/db.js
import './env.js';
import { PrismaClient } from '@prisma/client';

// Configure PrismaClient with connection pooling and error handling
const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
  errorFormat: 'pretty',
});

// Enhanced connection with retry logic for Neon database
async function connectWithRetry(retries = 5, delay = 3000) {
  for (let i = 0; i < retries; i++) {
    try {
      await prisma.$connect();
      console.log('✅ Connected to PostgreSQL via Prisma');
      return;
    } catch (err) {
      const isNeon = process.env.DATABASE_URL?.includes('neon.tech');
      const isP1001 = err.code === 'P1001' || err.message?.includes("Can't reach database server");
      
      console.error(`❌ Prisma connection attempt ${i + 1}/${retries} failed:`, err.message);
      
      // Provide helpful guidance for Neon P1001 errors
      if (isNeon && isP1001 && i === retries - 1) {
        console.error('\n🔴 ============================================');
        console.error('🔴 DATABASE CONNECTION FAILED');
        console.error('🔴 ============================================');
        console.error('🔴 Error: Cannot reach Neon database server');
        console.error('\n💡 Common causes:');
        console.error('   1. DATABASE_URL missing SSL parameters');
        console.error('   2. Database compute instance is idle (cold start)');
        console.error('   3. Network/firewall restrictions');
        console.error('\n🔧 Solution:');
        console.error('   Update your DATABASE_URL in Render environment variables:');
        console.error('   Add: ?sslmode=require&channel_binding=require&connect_timeout=15');
        console.error('   Full format:');
        console.error('   postgresql://user:pass@host:5432/db?sslmode=require&channel_binding=require&connect_timeout=15');
        console.error('🔴 ============================================\n');
      }
      
      if (i < retries - 1) {
        console.log(`⏳ Retrying connection in ${delay}ms... (Neon may need time to wake up)`);
        await new Promise(resolve => setTimeout(resolve, delay));
        delay = Math.min(delay * 1.5, 10000); // Exponential backoff, max 10s
      } else {
        // Don't throw - let the app start and handle errors at request time
        // This is important for Neon which may have cold starts
        console.warn('⚠️  App will continue to start. Database operations may fail until connection is established.');
      }
    }
  }
}

// Connect with retry logic
connectWithRetry();

// Handle graceful shutdown
process.on('beforeExit', async () => {
  await prisma.$disconnect();
});

export default prisma;
