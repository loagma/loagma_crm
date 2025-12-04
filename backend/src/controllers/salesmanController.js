import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// ==================== TASK ASSIGNMENTS ====================

export const getMyTaskAssignments = async (req, res) => {
  try {
    const userId = req.user?.id;
    
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated'
      });
    }

    const { status, page = 1, limit = 50 } = req.query;
    
    const where = {
      salesmanId: userId
    };
    
    if (status) {
      where.status = status;
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);

    const [assignments, total] = await Promise.all([
      prisma.taskAssignment.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: {
          salesman: {
            select: {
              id: true,
              name: true,
              contactNumber: true
            }
          },
          area: {
            include: {
              zone: {
                include: {
                  city: {
                    include: {
                      district: {
                        include: {
                          region: {
                            include: {
                              state: true
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          createdBy: {
            select: {
              id: true,
              name: true,
              contactNumber: true
            }
          }
        }
      }),
      prisma.taskAssignment.count({ where })
    ]);

    res.json({
      success: true,
      data: assignments,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get my task assignments error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getTaskAssignmentStats = async (req, res) => {
  try {
    const userId = req.user?.id;
    
    if (!userId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated'
      });
    }

    const where = {
      salesmanId: userId
    };

    const [
      totalAssignments,
      activeAssignments,
      completedAssignments,
      byStatus,
      recentAssignments
    ] = await Promise.all([
      prisma.taskAssignment.count({ where }),
      
      prisma.taskAssignment.count({ 
        where: { ...where, status: 'Active' } 
      }),
      
      prisma.taskAssignment.count({ 
        where: { ...where, status: 'Completed' } 
      }),
      
      prisma.taskAssignment.groupBy({
        by: ['status'],
        where,
        _count: true
      }),
      
      prisma.taskAssignment.findMany({
        where,
        take: 10,
        orderBy: { createdAt: 'desc' },
        include: {
          area: {
            select: {
              name: true,
              zone: {
                select: {
                  name: true,
                  city: {
                    select: {
                      name: true
                    }
                  }
                }
              }
            }
          }
        }
      })
    ]);

    res.json({
      success: true,
      data: {
        totalAssignments,
        activeAssignments,
        completedAssignments,
        byStatus,
        recentAssignments
      }
    });
  } catch (error) {
    console.error('Get task assignment stats error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};
