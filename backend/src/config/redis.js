import Redis from 'ioredis';

const redisEnabled = (process.env.REDIS_ENABLED || 'false') === 'true';
const redisUrl = process.env.REDIS_URL;

let redis = null;

if (redisEnabled && redisUrl) {
  if (!redisUrl.includes('@')) {
    console.warn(
      '⚠️ REDIS_URL has no credentials. Redis Cloud often requires redis://default:<password>@host:port'
    );
  }

  redis = new Redis(redisUrl, {
    maxRetriesPerRequest: 1,
    lazyConnect: true,
    enableReadyCheck: true,
  });

  redis.on('connect', () => {
    console.log('✅ Redis connected');
  });

  redis.on('error', (err) => {
    console.error('❌ Redis error:', err.message);
  });
} else {
  console.log(
    `ℹ️ Redis disabled (${redisEnabled ? 'REDIS_URL missing' : 'REDIS_ENABLED=false'})`
  );
}

export const isRedisEnabled = () => Boolean(redis);

export const ensureRedisConnection = async () => {
  if (!redis) return false;
  if (redis.status === 'ready') return true;
  try {
    await redis.connect();
    return true;
  } catch (error) {
    console.error('❌ Failed to connect Redis:', error.message);
    return false;
  }
};

export const getRedisClient = () => redis;

export default {
  isRedisEnabled,
  ensureRedisConnection,
  getRedisClient,
};
