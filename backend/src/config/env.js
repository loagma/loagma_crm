import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: join(__dirname, '../../.env') });

// Redis defaults for live tracking cache
if (process.env.REDIS_ENABLED === undefined) {
  process.env.REDIS_ENABLED =
    process.env.NODE_ENV === 'production' ? 'true' : 'false';
}
