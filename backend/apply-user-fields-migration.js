import pkg from 'pg';
const { Client } = pkg;
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { readFileSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config();

async function applyMigration() {
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
  });

  try {
    await client.connect();
    console.log('✅ Connected to database');

    const migrationSQL = readFileSync(
      join(__dirname, 'prisma', 'migrations', 'add_country_district_to_user.sql'),
      'utf8'
    );

    console.log('📝 Applying migration...');
    await client.query(migrationSQL);
    console.log('✅ Migration applied successfully');

    // Verify the columns were added
    const result = await client.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'User' 
      AND column_name IN ('country', 'district')
    `);

    console.log('✅ Verified columns:', result.rows);
  } catch (error) {
    console.error('❌ Migration failed:', error);
  } finally {
    await client.end();
  }
}

applyMigration();
