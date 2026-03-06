import prisma from '../config/db.js';

const CALL_STATUS = {
  DNP_NOT_REACHABLE: 'DNP_NOT_REACHABLE',
  DNP_RNR: 'DNP_RNR',
  FOLLOWUP_INTERESTED: 'FOLLOWUP_INTERESTED',
  WRONG_NUMBER: 'WRONG_NUMBER',
  NOT_INTERESTED: 'NOT_INTERESTED',
  CALL_BACK_LATER: 'CALL_BACK_LATER',
  SALE_CLOSED: 'SALE_CLOSED',
};

const startOfDay = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0, 0);
const endOfDay = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59, 999);

export const createTelecallerCallLog = async (req, res) => {
  try {
    const telecallerId = req.user?.id;
    if (!telecallerId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const { id } = req.params;
    const {
      status,
      durationSec,
      notes,
      recordingUrl,
      calledAt,
      nextFollowupAt,
      followupNotes,
    } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'status is required',
      });
    }

    const account = await prisma.account.findUnique({ where: { id } });
    if (!account) {
      return res.status(404).json({
        success: false,
        message: 'Lead not found',
      });
    }

    const calledAtDate = calledAt ? new Date(calledAt) : new Date();
    const nextFollowupDate = nextFollowupAt ? new Date(nextFollowupAt) : null;

    const log = await prisma.telecallerCallLog.create({
      data: {
        accountId: id,
        telecallerId,
        calledAt: calledAtDate,
        durationSec: durationSec != null ? Number(durationSec) : null,
        status,
        notes,
        recordingUrl,
        nextFollowupAt: nextFollowupDate,
        followupNotes,
      },
    });

    let customerStage = account.customerStage;
    let funnelStage = account.funnelStage;

    if (status === CALL_STATUS.SALE_CLOSED) {
      customerStage = customerStage || 'Customer';
      funnelStage = funnelStage || 'Won';
    }

    await prisma.account.update({
      where: { id },
      data: {
        customerStage,
        funnelStage,
      },
    });

    return res.status(201).json({
      success: true,
      message: 'Call log saved',
      data: log,
    });
  } catch (error) {
    console.error('❌ createTelecallerCallLog error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to save call log',
    });
  }
};

export const getTelecallerFollowups = async (req, res) => {
  try {
    const telecallerId = req.user?.id;
    if (!telecallerId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const now = new Date();
    const todayStart = startOfDay(now);
    const todayEnd = endOfDay(now);

    const followups = await prisma.telecallerCallLog.findMany({
      where: {
        telecallerId,
        nextFollowupAt: {
          not: null,
        },
      },
      include: {
        account: {
          select: {
            id: true,
            personName: true,
            businessName: true,
            contactNumber: true,
          },
        },
      },
      orderBy: {
        nextFollowupAt: 'asc',
      },
    });

    const today = [];
    const upcoming = [];
    const overdue = [];

    for (const item of followups) {
      const ts = item.nextFollowupAt;
      if (!ts) continue;
      if (ts >= todayStart && ts <= todayEnd) {
        today.push(item);
      } else if (ts < now) {
        overdue.push(item);
      } else {
        upcoming.push(item);
      }
    }

    return res.json({
      success: true,
      data: {
        today,
        upcoming,
        overdue,
      },
    });
  } catch (error) {
    console.error('❌ getTelecallerFollowups error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to load follow-ups',
    });
  }
};

export const getTelecallerDashboardSummary = async (req, res) => {
  try {
    const telecallerId = req.user?.id;
    if (!telecallerId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const now = new Date();
    const todayStart = startOfDay(now);
    const todayEnd = endOfDay(now);

    const [todayCalls, interestedToday, followupsToday, totalSalesClosed] =
      await Promise.all([
        prisma.telecallerCallLog.count({
          where: {
            telecallerId,
            calledAt: { gte: todayStart, lte: todayEnd },
          },
        }),
        prisma.telecallerCallLog.count({
          where: {
            telecallerId,
            calledAt: { gte: todayStart, lte: todayEnd },
            status: CALL_STATUS.FOLLOWUP_INTERESTED,
          },
        }),
        prisma.telecallerCallLog.count({
          where: {
            telecallerId,
            nextFollowupAt: {
              gte: todayStart,
              lte: todayEnd,
            },
          },
        }),
        prisma.telecallerCallLog.count({
          where: {
            telecallerId,
            status: CALL_STATUS.SALE_CLOSED,
          },
        }),
      ]);

    return res.json({
      success: true,
      data: {
        todayCalls,
        interestedLeads: interestedToday,
        followupsToday,
        salesClosed: totalSalesClosed,
      },
    });
  } catch (error) {
    console.error('❌ getTelecallerDashboardSummary error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to load dashboard summary',
    });
  }
};

export const getTelecallerCallHistory = async (req, res) => {
  try {
    const telecallerId = req.user?.id;
    if (!telecallerId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    const logs = await prisma.telecallerCallLog.findMany({
      where: { telecallerId },
      include: {
        account: {
          select: {
            id: true,
            personName: true,
            businessName: true,
            contactNumber: true,
          },
        },
      },
      orderBy: { calledAt: 'desc' },
      take: 200,
    });

    return res.json({
      success: true,
      data: logs,
    });
  } catch (error) {
    console.error('❌ getTelecallerCallHistory error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to load call history',
    });
  }
};

export default {
  createTelecallerCallLog,
  getTelecallerFollowups,
  getTelecallerDashboardSummary,
  getTelecallerCallHistory,
};

