import pg from 'pg';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: join(__dirname, '.env') });

const { Client } = pg;

async function checkData() {
  const client = new Client({
    connectionString: process.env.DATABASE_URL,
  });

  try {
    await client.connect();
    console.log('✅ Connected to database\n');

    // Check countries
    const countries = await client.query('SELECT * FROM country LIMIT 10');
    console.log(`📍 Countries (${countries.rows.length}):`);
    console.log(JSON.stringify(countries.rows, null, 2));

    if (countries.rows.length > 0) {
      const countryId = countries.rows[0].id;
      
      // Check states
      const states = await client.query('SELECT * FROM state WHERE "countryId" = $1 LIMIT 10', [countryId]);
      console.log(`\n📍 States for ${countries.rows[0].name} (${states.rows.length}):`);
      console.log(JSON.stringify(states.rows, null, 2));

      if (states.rows.length > 0) {
        const stateId = states.rows[0].id;
        
        // Check districts
        const districts = await client.query('SELECT * FROM district WHERE "stateId" = $1 LIMIT 10', [stateId]);
        console.log(`\n📍 Districts for ${states.rows[0].name} (${districts.rows.length}):`);
        console.log(JSON.stringify(districts.rows, null, 2));

        if (districts.rows.length > 0) {
          const districtId = districts.rows[0].id;
          
          // Check cities
          const cities = await client.query('SELECT * FROM city WHERE "districtId" = $1 LIMIT 10', [districtId]);
          console.log(`\n📍 Cities for ${districts.rows[0].name} (${cities.rows.length}):`);
          console.log(JSON.stringify(cities.rows, null, 2));

          if (cities.rows.length > 0) {
            const cityId = cities.rows[0].id;
            
            // Check zones
            const zones = await client.query('SELECT * FROM zone WHERE "cityId" = $1 LIMIT 10', [cityId]);
            console.log(`\n📍 Zones for ${cities.rows[0].name} (${zones.rows.length}):`);
            console.log(JSON.stringify(zones.rows, null, 2));

            if (zones.rows.length > 0) {
              const zoneId = zones.rows[0].id;
              
              // Check areas
              const areas = await client.query('SELECT * FROM area WHERE "zoneId" = $1 LIMIT 10', [zoneId]);
              console.log(`\n📍 Areas for ${zones.rows[0].name} (${areas.rows.length}):`);
              console.log(JSON.stringify(areas.rows, null, 2));
            }
          }
        }
      }
    }

    // Check accounts
    const accounts = await client.query('SELECT * FROM "Account" LIMIT 5');
    console.log(`\n👤 Accounts (${accounts.rows.length}):`);
    console.log(JSON.stringify(accounts.rows, null, 2));

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await client.end();
  }
}

checkData();
