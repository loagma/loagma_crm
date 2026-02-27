// src/config/db.js
import './env.js';
import { PrismaClient } from '@prisma/client';

// Configure PrismaClient with connection pooling and error handling
const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
  errorFormat: 'pretty',
});

// Enhanced connection with retry logic
async function connectWithRetry(retries = 5, delay = 3000) {
  for (let i = 0; i < retries; i++) {
    try {
      await prisma.$connect();
      console.log('✅ Connected to database via Prisma');
      return;
    } catch (err) {
      const isP1001 = err.code === 'P1001' || err.message?.includes("Can't reach database server");

      console.error(`❌ Prisma connection attempt ${i + 1}/${retries} failed:`, err.message);

      if (i < retries - 1) {
        console.log(`⏳ Retrying connection in ${delay}ms...`);
        await new Promise(resolve => setTimeout(resolve, delay));
        delay = Math.min(delay * 1.5, 10000); // Exponential backoff, max 10s
      } else {
        // Don't throw - let the app start and handle errors at request time
        // Let the app start; database operations may fail until connection succeeds
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
