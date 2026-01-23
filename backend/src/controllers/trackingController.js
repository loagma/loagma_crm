import prisma from '../config/db.js';

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

export const createTrackingPoint = async (req, res) => {
  try {
    const {
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

    if (latValue === null || lngValue === null) {
      return res.status(400).json({
        success: false,
        message: 'latitude and longitude must be valid numbers',
      });
    }

    const data = {
      employeeId,
      attendanceId,
      latitude: latValue,
      longitude: lngValue,
      speed: parseFloatValue(speed),
      accuracy: parseFloatValue(accuracy),
    };

    const recordedAtValue = parseDateValue(recordedAt);
    if (recordedAtValue) {
      data.recordedAt = recordedAtValue;
    }

    const point = await prisma.salesmanTrackingPoint.create({ data });

    console.log(`✅ Tracking point saved: employeeId=${employeeId}, attendanceId=${attendanceId}, lat=${latValue}, lng=${lngValue}`);

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
    if (!prisma || !prisma.salesmanTrackingPoint) {
      console.error('❌ Prisma client not initialized properly');
      return res.status(500).json({
        success: false,
        message: 'Database connection error. Please restart the server.',
      });
    }

    const startDate = parseDateValue(start) ?? new Date(Date.now() - 24 * 60 * 60 * 1000);
    const endDate = parseDateValue(end) ?? new Date();

    console.log(`🔍 Loading route for employeeId: ${employeeId}, from ${startDate} to ${endDate}`);
    if (attendanceId) {
      console.log(`   Filtering by attendanceId: ${attendanceId}`);
    }

    // First, check if there are any tracking points for this employee at all
    const totalPoints = await prisma.salesmanTrackingPoint.count({
      where: {
        employeeId: employeeId.toString(),
      },
    });
    console.log(`   Total tracking points for employee ${employeeId}: ${totalPoints}`);

    const points = await prisma.salesmanTrackingPoint.findMany({
      where: {
        employeeId: employeeId.toString(),
        ...(attendanceId ? { attendanceId: attendanceId.toString() } : {}),
        recordedAt: {
          gte: startDate,
          lte: endDate,
        },
      },
      orderBy: { recordedAt: 'asc' },
      take: limit ? Number(limit) : undefined,
    });

    console.log(`✅ Found ${points.length} tracking points for route (filtered by date range)`);
    if (points.length === 0 && totalPoints > 0) {
      console.log(`⚠️ No points in date range, but ${totalPoints} total points exist. Consider expanding date range.`);
      // Get the earliest and latest points to help with date range debugging
      const earliestPoint = await prisma.salesmanTrackingPoint.findFirst({
        where: { employeeId: employeeId.toString() },
        orderBy: { recordedAt: 'asc' },
      });
      const latestPoint = await prisma.salesmanTrackingPoint.findFirst({
        where: { employeeId: employeeId.toString() },
        orderBy: { recordedAt: 'desc' },
      });
      if (earliestPoint && latestPoint) {
        console.log(`   Date range of existing points: ${earliestPoint.recordedAt} to ${latestPoint.recordedAt}`);
      }
    } else if (points.length === 0 && totalPoints === 0) {
      console.log(`⚠️ No tracking points exist for employee ${employeeId} at all. Make sure tracking is active and points are being saved.`);
    }

    return res.json({
      success: true,
      data: points,
      meta: {
        totalPointsForEmployee: totalPoints,
        dateRange: {
          start: startDate.toISOString(),
          end: endDate.toISOString(),
        },
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

    if (employeeId) {
      const latest = await prisma.salesmanTrackingPoint.findFirst({
        where: { employeeId: employeeId.toString() },
        orderBy: { recordedAt: 'desc' },
      });

      return res.json({
        success: true,
        data: latest,
      });
    }

    const latestPerEmployee = await prisma.$queryRaw`
      SELECT DISTINCT ON ("employeeId")
        "id",
        "employeeId",
        "attendanceId",
        "latitude",
        "longitude",
        "speed",
        "accuracy",
        "recordedAt"
      FROM "SalesmanTrackingPoint"
      ORDER BY "employeeId", "recordedAt" DESC;
    `;

    return res.json({
      success: true,
      data: latestPerEmployee,
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
