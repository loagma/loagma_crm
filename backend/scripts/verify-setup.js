import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';

dotenv.config();

const prisma = new PrismaClient();

async function verifySetup() {
    console.log('🔍 Verifying Backend Setup...\n');

    // Check environment variables
    console.log('📋 Environment Variables:');
    const requiredEnvVars = [
        'DATABASE_URL',
        'JWT_SECRET',
        'TWILIO_ACCOUNT_SID',
        'TWILIO_AUTH_TOKEN',
        'TWILIO_PHONE_NUMBER',
        'CLOUDINARY_CLOUD_NAME',
        'CLOUDINARY_API_KEY',
        'CLOUDINARY_API_SECRET'
    ];

    let envVarsOk = true;
    for (const envVar of requiredEnvVars) {
        const isSet = !!process.env[envVar];
        console.log(`  ${isSet ? '✅' : '❌'} ${envVar}: ${isSet ? 'Set' : 'Missing'}`);
        if (!isSet) envVarsOk = false;
    }

    if (!envVarsOk) {
        console.log('\n⚠️  Some environment variables are missing. Check .env file.\n');
    }

    // Check database connection
    console.log('\n🗄️  Database Connection:');
    try {
        await prisma.$connect();
        console.log('  ✅ Database connected successfully');

        // Check tables
        const userCount = await prisma.user.count();
        const accountCount = await prisma.accountMaster.count();

        console.log(`  ℹ️  Users: ${userCount}`);
        console.log(`  ℹ️  Accounts: ${accountCount}`);
    } catch (error) {
        console.log('  ❌ Database connection failed:', error.message);
    } finally {
        await prisma.$disconnect();
    }

    // Check Node version
    console.log('\n🟢 Node.js Version:');
    console.log(`  ℹ️  ${process.version}`);
    if (parseInt(process.version.slice(1)) < 18) {
        console.log('  ⚠️  Node.js 18+ recommended');
    } else {
        console.log('  ✅ Node.js version is compatible');
    }

    console.log('\n✨ Setup verification complete!\n');
}

verifySetup().catch(console.error);
