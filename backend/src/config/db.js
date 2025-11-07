// src/config/db.js
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

prisma.$connect()
  .then(() => console.log('✅ Connected to PostgreSQL via Prisma'))
  .catch(err => console.error('❌ Prisma connection error:', err));

export default prisma;
