import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// ==================== SALESMAN REPORTS ====================

export const getSalesmanReports = async (req, res) => {
  try {
    const {
      salesmanId,
      startDate,
      endDate,
      period = 'today'
    } = req.query;

    // Calculate date range
    const { start, end } = calculateDateRange(period, startDate, endDate);

    console.log(`📊 Generating salesman reports for period: ${period}`);
    console.log(`📅 Date range: ${start.toISOString()} to ${end.toISOString()}`);

    // Get salesman info if specific salesman requested
    let salesmanInfo = null;
    if (salesmanId) {
      salesmanInfo = await prisma.user.findUnique({
        where: { id: salesmanId },
        select: {
          id: true,
          name: true,
          contactNumber: true,
          email: true,
          roleId: true,
          createdAt: true
        }
      });

      if (!salesmanInfo) {
        return res.status(404).json({
          success: false,
          message: 'Salesman not found'
        });
      }
    }

    // Build where clause for accounts
    const accountsWhere = {
      createdAt: {
        gte: start,
        lte: end
      }
    };

    if (salesmanId) {
      accountsWhere.createdById = salesmanId;
    }

    // Build where clause for attendance (visits)
    const attendanceWhere = {
      date: {
        gte: start,
        lte: end
      }
    };

    if (salesmanId) {
      attendanceWhere.employeeId = salesmanId;
    }

    // Fetch data in parallel
    const [
      // Account statistics
      totalAccountsCreated,
      approvedAccounts,
      pendingAccounts,
      accountsByStage,
      accountsByBusinessType,
      recentAccounts,

      // Attendance/Visit statistics
      totalVisits,
      attendanceRecords,

      // All salesmen for comparison (if not specific salesman)
      allSalesmen
    ] = await Promise.all([
      // Account queries
      prisma.account.count({ where: accountsWhere }),

      prisma.account.count({
        where: { ...accountsWhere, isApproved: true }
      }),

      prisma.account.count({
        where: { ...accountsWhere, isApproved: false }
      }),

      prisma.account.groupBy({
        by: ['customerStage'],
        where: accountsWhere,
        _count: true
      }),

      prisma.account.groupBy({
        by: ['businessType'],
        where: accountsWhere,
        _count: true
      }),

      prisma.account.findMany({
        where: accountsWhere,
        take: 10,
        orderBy: { createdAt: 'desc' },
        include: {
          createdBy: {
            select: { name: true, contactNumber: true }
          }
        }
      }),

      // Attendance queries
      prisma.attendance.count({ where: attendanceWhere }),

      prisma.attendance.findMany({
        where: attendanceWhere,
        orderBy: { date: 'desc' },
        take: 10,
        select: {
          id: true,
          employeeId: true,
          employeeName: true,
          date: true,
          punchInTime: true,
          punchOutTime: true,
          totalWorkHours: true,
          status: true
        }
      }),

      // All salesmen (if not specific salesman)
      salesmanId ? null : prisma.user.findMany({
        where: {
          isActive: true,
          OR: [
            {
              role: {
                name: {
                  in: ['salesman', 'Salesman', 'Sales', 'sales']
                }
              }
            },
            {
              roles: {
                hasSome: ['R002', 'salesman', 'Salesman', 'Sales', 'sales']
              }
            }
          ]
        },
        select: {
          id: true,
          name: true,
          contactNumber: true,
          createdAt: true,
          roles: true,
          roleId: true,
          role: {
            select: {
              name: true
            }
          }
        }
      })
    ]);

    // Calculate additional metrics
    const accountsCreatedToday = await prisma.account.count({
      where: {
        ...accountsWhere,
        createdAt: {
          gte: new Date(new Date().setHours(0, 0, 0, 0)),
          lte: new Date(new Date().setHours(23, 59, 59, 999))
        }
      }
    });

    const visitsToday = await prisma.attendance.count({
      where: {
        ...attendanceWhere,
        date: {
          gte: new Date(new Date().setHours(0, 0, 0, 0)),
          lte: new Date(new Date().setHours(23, 59, 59, 999))
        }
      }
    });

    // Calculate performance metrics
    const performanceMetrics = {
      accountsPerDay: totalAccountsCreated / Math.max(1, Math.ceil((end - start) / (1000 * 60 * 60 * 24))),
      visitsPerDay: totalVisits / Math.max(1, Math.ceil((end - start) / (1000 * 60 * 60 * 24))),
      approvalRate: totalAccountsCreated > 0 ? (approvedAccounts / totalAccountsCreated * 100) : 0,
      averageWorkHours: attendanceRecords.length > 0
        ? attendanceRecords.reduce((sum, record) => sum + (record.totalWorkHours || 0), 0) / attendanceRecords.length
        : 0
    };

    // If getting all salesmen reports, group by salesman
    let salesmenPerformance = [];
    if (!salesmanId && allSalesmen) {
      salesmenPerformance = await Promise.all(
        allSalesmen.map(async (salesman) => {
          const salesmanAccountsWhere = {
            ...accountsWhere,
            createdById: salesman.id
          };

          const salesmanAttendanceWhere = {
            ...attendanceWhere,
            employeeId: salesman.id
          };

          const [
            salesmanAccounts,
            salesmanApproved,
            salesmanVisits,
            salesmanAttendance
          ] = await Promise.all([
            prisma.account.count({ where: salesmanAccountsWhere }),
            prisma.account.count({ where: { ...salesmanAccountsWhere, isApproved: true } }),
            prisma.attendance.count({ where: salesmanAttendanceWhere }),
            prisma.attendance.findMany({
              where: salesmanAttendanceWhere,
              select: { totalWorkHours: true }
            })
          ]);

          const avgWorkHours = salesmanAttendance.length > 0
            ? salesmanAttendance.reduce((sum, record) => sum + (record.totalWorkHours || 0), 0) / salesmanAttendance.length
            : 0;

          return {
            ...salesman,
            accountsCreated: salesmanAccounts,
            accountsApproved: salesmanApproved,
            visits: salesmanVisits,
            averageWorkHours: avgWorkHours,
            approvalRate: salesmanAccounts > 0 ? (salesmanApproved / salesmanAccounts * 100) : 0
          };
        })
      );

      // Sort by performance
      salesmenPerformance.sort((a, b) => b.accountsCreated - a.accountsCreated);
    }

    const response = {
      success: true,
      data: {
        period,
        dateRange: { start, end },
        salesman: salesmanInfo,

        // Summary statistics
        summary: {
          totalAccountsCreated,
          accountsCreatedToday,
          approvedAccounts,
          pendingAccounts,
          totalVisits,
          visitsToday,
          performanceMetrics
        },

        // Detailed breakdowns
        accountsByStage: accountsByStage.map(item => ({
          stage: item.customerStage || 'Unknown',
          count: item._count
        })),

        accountsByBusinessType: accountsByBusinessType.map(item => ({
          type: item.businessType || 'Unknown',
          count: item._count
        })),

        // Recent data
        recentAccounts,
        recentAttendance: attendanceRecords,

        // All salesmen performance (if not specific salesman)
        salesmenPerformance
      }
    };

    console.log(`✅ Generated reports for ${salesmanId ? 'specific salesman' : 'all salesmen'}`);
    res.json(response);

  } catch (error) {
    console.error('❌ Error generating salesman reports:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const getSalesmanDailyReport = async (req, res) => {
  try {
    const { salesmanId, date } = req.query;

    if (!salesmanId) {
      return res.status(400).json({
        success: false,
        message: 'Salesman ID is required'
      });
    }

    // Parse date or use today
    const targetDate = date ? new Date(date) : new Date();
    const startOfDay = new Date(targetDate.setHours(0, 0, 0, 0));
    const endOfDay = new Date(targetDate.setHours(23, 59, 59, 999));

    console.log(`📊 Generating daily report for salesman ${salesmanId} on ${startOfDay.toDateString()}`);

    // Get salesman info
    const salesman = await prisma.user.findUnique({
      where: { id: salesmanId },
      select: {
        id: true,
        name: true,
        contactNumber: true,
        email: true
      }
    });

    if (!salesman) {
      return res.status(404).json({
        success: false,
        message: 'Salesman not found'
      });
    }

    // Fetch daily data
    const [
      accountsCreated,
      attendance,
      accountsDetails
    ] = await Promise.all([
      // Accounts created today
      prisma.account.count({
        where: {
          createdById: salesmanId,
          createdAt: {
            gte: startOfDay,
            lte: endOfDay
          }
        }
      }),

      // Attendance record for the day
      prisma.attendance.findFirst({
        where: {
          employeeId: salesmanId,
          date: {
            gte: startOfDay,
            lte: endOfDay
          }
        }
      }),

      // Detailed accounts created today
      prisma.account.findMany({
        where: {
          createdById: salesmanId,
          createdAt: {
            gte: startOfDay,
            lte: endOfDay
          }
        },
        orderBy: { createdAt: 'desc' }
      })
    ]);

    const response = {
      success: true,
      data: {
        date: startOfDay,
        salesman,
        summary: {
          accountsCreated,
          hasAttendance: !!attendance,
          workHours: attendance?.totalWorkHours || 0,
          punchInTime: attendance?.punchInTime,
          punchOutTime: attendance?.punchOutTime,
          status: attendance?.status || 'No attendance'
        },
        accountsDetails,
        attendance
      }
    };

    res.json(response);

  } catch (error) {
    console.error('❌ Error generating daily report:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

export const getAllSalesmenSummary = async (req, res) => {
  try {
    const { period = 'today', startDate, endDate } = req.query;

    // Calculate date range
    const { start, end } = calculateDateRange(period, startDate, endDate);

    console.log(`📊 Generating all salesmen summary for period: ${period}`);

    // Get all salesmen
    const salesmen = await prisma.user.findMany({
      where: {
        isActive: true,
        OR: [
          {
            role: {
              name: {
                in: ['salesman', 'Salesman', 'Sales', 'sales']
              }
            }
          },
          {
            roles: {
              hasSome: ['R002', 'salesman', 'Salesman', 'Sales', 'sales']
            }
          }
        ]
      },
      select: {
        id: true,
        name: true,
        contactNumber: true,
        email: true,
        createdAt: true,
        roles: true,
        roleId: true,
        role: {
          select: {
            name: true
          }
        }
      }
    });

    // Get performance data for each salesman
    const salesmenWithPerformance = await Promise.all(
      salesmen.map(async (salesman) => {
        const [
          accountsCreated,
          accountsApproved,
          attendanceCount,
          recentAttendance
        ] = await Promise.all([
          prisma.account.count({
            where: {
              createdById: salesman.id,
              createdAt: { gte: start, lte: end }
            }
          }),

          prisma.account.count({
            where: {
              createdById: salesman.id,
              createdAt: { gte: start, lte: end },
              isApproved: true
            }
          }),

          prisma.attendance.count({
            where: {
              employeeId: salesman.id,
              date: { gte: start, lte: end }
            }
          }),

          prisma.attendance.findMany({
            where: {
              employeeId: salesman.id,
              date: { gte: start, lte: end }
            },
            select: { totalWorkHours: true },
            orderBy: { date: 'desc' }
          })
        ]);

        const totalWorkHours = recentAttendance.reduce(
          (sum, record) => sum + (record.totalWorkHours || 0), 0
        );

        return {
          ...salesman,
          performance: {
            accountsCreated,
            accountsApproved,
            attendanceCount,
            totalWorkHours,
            approvalRate: accountsCreated > 0 ? (accountsApproved / accountsCreated * 100) : 0,
            averageWorkHours: attendanceCount > 0 ? totalWorkHours / attendanceCount : 0
          }
        };
      })
    );

    // Sort by accounts created
    salesmenWithPerformance.sort((a, b) => b.performance.accountsCreated - a.performance.accountsCreated);

    // Calculate overall statistics
    const overallStats = {
      totalSalesmen: salesmen.length,
      totalAccountsCreated: salesmenWithPerformance.reduce((sum, s) => sum + s.performance.accountsCreated, 0),
      totalAccountsApproved: salesmenWithPerformance.reduce((sum, s) => sum + s.performance.accountsApproved, 0),
      totalVisits: salesmenWithPerformance.reduce((sum, s) => sum + s.performance.attendanceCount, 0),
      averageAccountsPerSalesman: salesmenWithPerformance.length > 0
        ? salesmenWithPerformance.reduce((sum, s) => sum + s.performance.accountsCreated, 0) / salesmenWithPerformance.length
        : 0
    };

    res.json({
      success: true,
      data: {
        period,
        dateRange: { start, end },
        overallStats,
        salesmen: salesmenWithPerformance
      }
    });

  } catch (error) {
    console.error('❌ Error generating salesmen summary:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// ==================== HELPER FUNCTIONS ====================

function calculateDateRange(period, startDate, endDate) {
  let start, end;

  if (startDate && endDate) {
    start = new Date(startDate);
    end = new Date(endDate);
  } else {
    const now = new Date();

    switch (period) {
      case 'today':
        start = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
        end = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
        break;
      case 'yesterday':
        const yesterday = new Date(now);
        yesterday.setDate(yesterday.getDate() - 1);
        start = new Date(yesterday.getFullYear(), yesterday.getMonth(), yesterday.getDate(), 0, 0, 0, 0);
        end = new Date(yesterday.getFullYear(), yesterday.getMonth(), yesterday.getDate(), 23, 59, 59, 999);
        break;
      case 'week':
        start = new Date(now);
        start.setDate(start.getDate() - 7);
        start.setHours(0, 0, 0, 0);
        end = new Date(now);
        end.setHours(23, 59, 59, 999);
        break;
      case 'month':
        start = new Date(now);
        start.setMonth(start.getMonth() - 1);
        start.setHours(0, 0, 0, 0);
        end = new Date(now);
        end.setHours(23, 59, 59, 999);
        break;
      case 'quarter':
        start = new Date(now);
        start.setMonth(start.getMonth() - 3);
        start.setHours(0, 0, 0, 0);
        end = new Date(now);
        end.setHours(23, 59, 59, 999);
        break;
      case 'year':
        start = new Date(now);
        start.setFullYear(start.getFullYear() - 1);
        start.setHours(0, 0, 0, 0);
        end = new Date(now);
        end.setHours(23, 59, 59, 999);
        break;
      default:
        start = new Date(2020, 0, 1, 0, 0, 0, 0); // All time
        end = new Date();
        end.setHours(23, 59, 59, 999);
    }
  }

  // Add debug logging
  console.log(`📅 Date range calculation for period '${period}':`);
  console.log(`   Start: ${start.toISOString()}`);
  console.log(`   End: ${end.toISOString()}`);

  return { start, end };
}