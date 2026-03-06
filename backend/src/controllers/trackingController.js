import prisma from '../config/db.js';
import { ensureRedisConnection, getRedisClient, isRedisEnabled } from '../config/redis.js';
import { getTrackingRuntimeStats, getIO } from '../socket/socketServer.js';

const parseFloatValue = (value) => {
  if (value === null || value === undefined || value === '') return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
};

const parseDateValue = (value) => {
  if (!value) return null;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
};

const toRadians = (degrees) => degrees * (Math.PI / 180);

const calculateDistanceKm = (lat1, lon1, lat2, lon2) => {
  const R = 6371;
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

const MAX_ACCEPTABLE_ACCURACY_METERS = 50;

const persistLatestToRedis = async ({
  employeeId,
  attendanceId,
  latitude,
  longitude,
  speed,
  accuracy,
  recordedAt,
}) => {
  if (!isRedisEnabled()) return;
  const ready = await ensureRedisConnection();
  if (!ready) return;
  const redis = getRedisClient();
  if (!redis) return;
  const payload = {
    employeeId: employeeId.toString(),
    attendanceId: attendanceId?.toString() || null,
    latitude,
    longitude,
    speed: speed ?? 0,
    accuracy: accuracy ?? 0,
    recordedAt: new Date(recordedAt).toISOString(),
    lastSeenAt: new Date(recordedAt).toISOString(),
  };
  await redis.set(
    `tracking:latest:${employeeId.toString()}`,
    JSON.stringify(payload),
    'EX',
    60 * 60 * 12
  );
};

export const createTrackingPoint = async (req, res) => {
  try {
    const {
      clientPointId,
      employeeId,
      attendanceId,
      latitude,
      longitude,
      speed,
      accuracy,
      recordedAt,
    } = req.body;

    if (!employeeId || !attendanceId) {
      return res.status(400).json({
        success: false,
        message: 'employeeId and attendanceId are required',
      });
    }

    const latValue = parseFloatValue(latitude);
    const lngValue = parseFloatValue(longitude);
    const accuracyValue = parseFloatValue(accuracy);

    if (latValue === null || lngValue === null) {
      return res.status(400).json({
        success: false,
        message: 'latitude and longitude must be valid numbers',
      });
    }

    if (accuracyValue !== null && accuracyValue > MAX_ACCEPTABLE_ACCURACY_METERS) {
      return res.status(400).json({
        success: false,
        message: 'Location accuracy too low',
      });
    }

    const data = {
      clientPointId: clientPointId || null,
      employeeId,
      attendanceId,
      latitude: latValue,
      longitude: lngValue,
      speed: parseFloatValue(speed),
      accuracy: accuracyValue,
    };

    const recordedAtValue = parseDateValue(recordedAt);
    if (recordedAtValue) {
      data.recordedAt = recordedAtValue;
    }

    let point;
    try {
      point = await prisma.salesmanTrackingPoint.create({ data });
    } catch (createError) {
      if (
        createError?.code === 'P2002' &&
        clientPointId &&
        typeof clientPointId === 'string'
      ) {
        point = await prisma.salesmanTrackingPoint.findFirst({
          where: { clientPointId },
        });
      } else {
        throw createError;
      }
    }

    console.log(`✅ Tracking point saved: employeeId=${employeeId}, attendanceId=${attendanceId}, lat=${latValue}, lng=${lngValue}`);

    await persistLatestToRedis({
      employeeId,
      attendanceId,
      latitude: point.latitude,
      longitude: point.longitude,
      speed: point.speed,
      accuracy: point.accuracy,
      recordedAt: point.recordedAt,
    });

    return res.status(201).json({
      success: true,
      message: 'Tracking point saved',
      data: point,
    });
  } catch (error) {
    console.error('❌ Error saving tracking point:', error);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const createTrackingPointsBatch = async (req, res) => {
  try {
    const points = Array.isArray(req.body?.points) ? req.body.points : null;
    if (!points || points.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'points array is required',
      });
    }

    const results = [];
    const acceptedClientPointIds = [];

    for (const point of points) {
      const employeeId = point?.employeeId?.toString();
      const attendanceId = point?.attendanceId?.toString();
      const clientPointId =
        point?.clientPointId != null ? point.clientPointId.toString() : null;
      const latitude = parseFloatValue(point?.latitude);
      const longitude = parseFloatValue(point?.longitude);
      const accuracyValue = parseFloatValue(point?.accuracy);

      if (!employeeId || !attendanceId || latitude === null || longitude === null) {
        results.push({
          clientPointId,
          success: false,
          message: 'Invalid point payload',
        });
        continue;
      }

      if (accuracyValue !== null && accuracyValue > MAX_ACCEPTABLE_ACCURACY_METERS) {
        results.push({
          clientPointId,
          success: false,
          message: 'Location accuracy too low',
        });
        continue;
      }

      const data = {
        clientPointId,
        employeeId,
        attendanceId,
        latitude,
        longitude,
        speed: parseFloatValue(point?.speed),
        accuracy: accuracyValue,
      };

      const recordedAtValue = parseDateValue(point?.recordedAt);
      if (recordedAtValue) {
        data.recordedAt = recordedAtValue;
      }

      try {
        const created = await prisma.salesmanTrackingPoint.create({ data });
        await persistLatestToRedis({
          employeeId,
          attendanceId,
          latitude: created.latitude,
          longitude: created.longitude,
          speed: created.speed,
          accuracy: created.accuracy,
          recordedAt: created.recordedAt,
        });
        // Broadcast to admin-room so live map stays in sync even when salesman uses REST fallback
        try {
          getIO().to('admin-room').emit('location-update', {
            employeeId,
            employeeName: point?.employeeName || employeeId,
            attendanceId,
            latitude: created.latitude,
            longitude: created.longitude,
            speed: created.speed ?? 0,
            accuracy: created.accuracy ?? 0,
            recordedAt: created.recordedAt.toISOString(),
            lastSeenAt: new Date().toISOString(),
            status: 'LIVE',
            source: 'rest-batch',
          });
        } catch (_) {
          // Socket.IO not yet initialized (e.g., test env) — skip broadcast
        }
        results.push({ clientPointId, success: true });
        if (clientPointId) acceptedClientPointIds.push(clientPointId);
      } catch (error) {
        if (error?.code === 'P2002' && clientPointId) {
          // Duplicate from retry/ack loss, treat as accepted.
          results.push({ clientPointId, success: true, duplicate: true });
          acceptedClientPointIds.push(clientPointId);
        } else {
          results.push({
            clientPointId,
            success: false,
            message: error.message,
          });
        }
      }
    }

    return res.status(200).json({
      success: true,
      acceptedClientPointIds,
      results,
    });
  } catch (error) {
    console.error('❌ Error in createTrackingPointsBatch:', error);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const getTrackingRoute = async (req, res) => {
  try {
    const { employeeId, attendanceId, start, end, limit } = req.query;

    if (!employeeId) {
      return res.status(400).json({
        success: false,
        message: 'employeeId is required',
      });
    }

    // Validate Prisma client is initialized
    if (!prisma) {
      console.error('❌ Prisma client not initialized');
      return res.status(500).json({
        success: false,
        message: 'Database connection error. Please restart the server.',
      });
    }

    // Calculate date range
    const now = new Date();
    const parsedStart = parseDateValue(start);
    const parsedEnd = parseDateValue(end);

    // Default to today if no dates provided
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
    const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

    const finalStartDate = parsedStart || startOfToday;
    const finalEndDate = parsedEnd || endOfToday;

    console.log(`📍 Fetching route for employeeId=${employeeId}, attendanceId=${attendanceId || 'all'}, date range: ${finalStartDate.toISOString()} to ${finalEndDate.toISOString()}`);

    // Try to query - if model doesn't exist, catch the error
    let points = [];
    try {
      const whereClause = {
        employeeId: employeeId.toString(),
        ...(attendanceId ? { attendanceId: attendanceId.toString() } : {}),
        recordedAt: {
          gte: finalStartDate,
          lte: finalEndDate,
        },
      };

      points = await prisma.salesmanTrackingPoint.findMany({
        where: whereClause,
        orderBy: { recordedAt: 'asc' },
        take: limit ? Number(limit) : undefined,
      });

      console.log(`✅ Found ${points.length} tracking points for route`);
    } catch (dbError) {
      // Check if error is about missing model
      const errorMsg = dbError.message || dbError.toString();
      if (errorMsg.includes('salesmanTrackingPoint') ||
        errorMsg.includes('undefined') ||
        errorMsg.includes("Cannot read properties") ||
        dbError.code === 'P2001') {
        console.error('❌ Prisma model salesmanTrackingPoint not available');
        console.error('   Solution: Stop the server, then run: cd backend && npx prisma generate');
        return res.status(500).json({
          success: false,
          message: 'Database model not available. Please stop server and run: npx prisma generate',
        });
      }
      // Re-throw other database errors
      throw dbError;
    }

    return res.json({
      success: true,
      data: points,
      meta: {
        count: points.length,
        dateRange: {
          start: finalStartDate.toISOString(),
          end: finalEndDate.toISOString(),
        },
        attendanceId: attendanceId || null,
      },
    });
  } catch (error) {
    console.error('❌ Error in getTrackingRoute:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to load tracking route',
    });
  }
};

export const getLiveTracking = async (req, res) => {
  try {
    const { employeeId } = req.query;

    if (isRedisEnabled()) {
      const ready = await ensureRedisConnection();
      if (ready) {
        const redis = getRedisClient();
        if (redis) {
          if (employeeId) {
            const cached = await redis.get(
              `tracking:latest:${employeeId.toString()}`
            );
            if (cached) {
              return res.json({
                success: true,
                data: JSON.parse(cached),
                source: 'redis',
              });
            }
          } else {
            const keys = await redis.keys('tracking:latest:*');
            if (keys.length > 0) {
              const values = await redis.mget(keys);
              const parsed = values
                .filter(Boolean)
                .map((v) => {
                  try {
                    return JSON.parse(v);
                  } catch (_) {
                    return null;
                  }
                })
                .filter(Boolean);
              if (parsed.length > 0) {
                return res.json({
                  success: true,
                  data: parsed,
                  source: 'redis',
                });
              }
            }
          }
        }
      }
    }

    if (employeeId) {
      const latest = await prisma.salesmanTrackingPoint.findFirst({
        where: { employeeId: employeeId.toString() },
        orderBy: { recordedAt: 'desc' },
      });

      return res.json({
        success: true,
        data: latest,
        source: 'database',
      });
    }

    // Get the latest tracking point per employee using a subquery (MySQL-compatible)
    const latestPerEmployee = await prisma.$queryRaw`
      SELECT t.id, t.employeeId, t.attendanceId,
             t.latitude, t.longitude, t.speed,
             t.accuracy, t.recordedAt
      FROM SalesmanTrackingPoint t
      INNER JOIN (
        SELECT employeeId, MAX(recordedAt) AS maxRecordedAt
        FROM SalesmanTrackingPoint
        GROUP BY employeeId
      ) sub ON t.employeeId = sub.employeeId
           AND t.recordedAt = sub.maxRecordedAt;
    `;

    return res.json({
      success: true,
      data: latestPerEmployee,
      source: 'database',
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const getTrackingRouteStats = async (req, res) => {
  try {
    const { employeeId, attendanceId, start, end } = req.query;
    if (!employeeId) {
      return res.status(400).json({
        success: false,
        message: 'employeeId is required',
      });
    }

    const now = new Date();
    const parsedStart = parseDateValue(start);
    const parsedEnd = parseDateValue(end);
    const startOfToday = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
      0,
      0,
      0
    );
    const endOfToday = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
      23,
      59,
      59,
      999
    );

    const finalStartDate = parsedStart || startOfToday;
    const finalEndDate = parsedEnd || endOfToday;

    const points = await prisma.salesmanTrackingPoint.findMany({
      where: {
        employeeId: employeeId.toString(),
        ...(attendanceId ? { attendanceId: attendanceId.toString() } : {}),
        recordedAt: {
          gte: finalStartDate,
          lte: finalEndDate,
        },
      },
      orderBy: { recordedAt: 'asc' },
      select: {
        latitude: true,
        longitude: true,
        recordedAt: true,
        attendanceId: true,
      },
    });

    let totalDistanceKm = 0;
    for (let i = 1; i < points.length; i += 1) {
      totalDistanceKm += calculateDistanceKm(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude
      );
    }

    const firstPoint = points.length > 0 ? points[0] : null;
    const lastPoint = points.length > 0 ? points[points.length - 1] : null;
    const durationSec =
      firstPoint && lastPoint
        ? Math.max(
            0,
            Math.floor(
              (new Date(lastPoint.recordedAt).getTime() -
                new Date(firstPoint.recordedAt).getTime()) /
                1000
            )
          )
        : 0;

    return res.json({
      success: true,
      data: {
        employeeId: employeeId.toString(),
        attendanceId: attendanceId || lastPoint?.attendanceId || null,
        totalDistanceKm: Number(totalDistanceKm.toFixed(3)),
        pointCount: points.length,
        durationSec,
        lastSeenAt: lastPoint?.recordedAt || null,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

export const getTrackingDebugSession = async (req, res) => {
  try {
    const { employeeId, attendanceId } = req.query;

    if (!employeeId || !attendanceId) {
      return res.status(400).json({
        success: false,
        message: 'employeeId and attendanceId are required',
      });
    }

    const now = new Date();
    const since = new Date(now.getTime() - 5 * 60 * 1000);

    const [lastPoint, recentPoints] = await Promise.all([
      prisma.salesmanTrackingPoint.findFirst({
        where: {
          employeeId: employeeId.toString(),
          attendanceId: attendanceId.toString(),
        },
        orderBy: { recordedAt: 'desc' },
      }),
      prisma.salesmanTrackingPoint.count({
        where: {
          employeeId: employeeId.toString(),
          attendanceId: attendanceId.toString(),
          recordedAt: { gte: since },
        },
      }),
    ]);

    let redisLatest = null;
    if (isRedisEnabled()) {
      const ready = await ensureRedisConnection();
      if (ready) {
        const redis = getRedisClient();
        if (redis) {
          const raw = await redis.get(`tracking:latest:${employeeId.toString()}`);
          if (raw) {
            try {
              redisLatest = JSON.parse(raw);
            } catch (_) {
              redisLatest = null;
            }
          }
        }
      }
    }

    const runtimeStats = getTrackingRuntimeStats();
    const perMinuteRate = Number((recentPoints / 5).toFixed(2));
    const lastSeenAt = lastPoint?.recordedAt || redisLatest?.lastSeenAt || null;
    const ackLagMs = lastSeenAt
      ? Math.max(0, Date.now() - new Date(lastSeenAt).getTime())
      : null;

    return res.json({
      success: true,
      data: {
        employeeId: employeeId.toString(),
        attendanceId: attendanceId.toString(),
        recentPointCount5Min: recentPoints,
        pointsPerMinute: perMinuteRate,
        lastSeenAt,
        ackLagMs,
        redis: {
          enabled: isRedisEnabled(),
          latest: redisLatest,
        },
        runtime: runtimeStats,
      },
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
