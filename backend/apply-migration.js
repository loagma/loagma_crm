import { PrismaClient } from '@prisma/client';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const prisma = new PrismaClient();

async function applyMigration() {
  try {
    console.log('🚀 Starting Account Master migration...\n');

    // Read the migration SQL
    const migrationPath = join(
      __dirname,
      'prisma',
      'migrations',
      '20251121_account_master_refactoring',
      'migration.sql'
    );
    
    const sql = readFileSync(migrationPath, 'utf-8');
    
    // Split by semicolon and filter empty statements
    const statements = sql
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));

    console.log(`📝 Found ${statements.length} SQL statements to execute\n`);

    // Execute each statement
    for (let i = 0; i < statements.length; i++) {
      const statement = statements[i];
      console.log(`⏳ Executing statement ${i + 1}/${statements.length}...`);
      
      try {
        await prisma.$executeRawUnsafe(statement);
        console.log(`✅ Statement ${i + 1} completed\n`);
      } catch (error) {
        // If column already exists, that's okay
        if (error.message.includes('already exists')) {
          console.log(`⚠️  Statement ${i + 1} skipped (already exists)\n`);
        } else {
          console.error(`❌ Error in statement ${i + 1}:`, error.message);
          throw error;
        }
      }
    }

    // Verify the changes
    console.log('🔍 Verifying migration...\n');
    
    const accounts = await prisma.account.findMany({
      take: 5,
      select: {
        accountCode: true,
        businessName: true,
        personName: true,
        isActive: true,
        pincode: true,
      }
    });

    console.log('📊 Sample accounts after migration:');
    console.table(accounts);

    // Update _prisma_migrations table
    console.log('\n📝 Recording migration in database...');
    
    await prisma.$executeRawUnsafe(`
      INSERT INTO "_prisma_migrations" 
      ("id", "checksum", "finished_at", "migration_name", "logs", "rolled_back_at", "started_at", "applied_steps_count")
      VALUES (
        gen_random_uuid(),
        'manual_migration',
        NOW(),
        '20251121_account_master_refactoring',
        'Manual migration for Account Master refactoring',
        NULL,
        NOW(),
        1
      )
      ON CONFLICT DO NOTHING
    `);

    console.log('\n✨ Migration completed successfully!\n');
    console.log('Next steps:');
    console.log('1. Run: npx prisma generate');
    console.log('2. Restart your backend server');
    console.log('3. Test the new Account Master screen\n');

  } catch (error) {
    console.error('\n❌ Migration failed:', error);
    console.error('\nTroubleshooting:');
    console.error('1. Check your DATABASE_URL in .env');
    console.error('2. Ensure PostgreSQL is accessible');
    console.error('3. Check database permissions\n');
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

applyMigration();
