import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// ==================== ACCOUNT CRUD ====================

export const getAllAccounts = async (req, res) => {
  try {
    const { 
      areaId, 
      assignedToId, 
      customerStage, 
      funnelStage,
      search,
      page = 1,
      limit = 50
    } = req.query;

    const where = {};
    
    if (areaId) where.areaId = areaId;
    if (assignedToId) where.assignedToId = assignedToId;
    if (customerStage) where.customerStage = customerStage;
    if (funnelStage) where.funnelStage = funnelStage;
    
    if (search) {
      where.OR = [
        { personName: { contains: search, mode: 'insensitive' } },
        { accountCode: { contains: search, mode: 'insensitive' } },
        { contactNumber: { contains: search } }
      ];
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);

    const [accounts, total] = await Promise.all([
      prisma.account.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: {
          assignedTo: {
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
                          state: {
                            include: { country: true }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }),
      prisma.account.count({ where })
    ]);

    res.json({
      success: true,
      data: accounts,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getAccountById = async (req, res) => {
  try {
    const { id } = req.params;

    const account = await prisma.account.findUnique({
      where: { id },
      include: {
        assignedTo: {
          select: {
            id: true,
            name: true,
            contactNumber: true,
            email: true
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
                        state: {
                          include: { country: true }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    });

    if (!account) {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }

    res.json({ success: true, data: account });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createAccount = async (req, res) => {
  try {
    const {
      personName,
      dateOfBirth,
      contactNumber,
      businessType,
      customerStage,
      funnelStage,
      assignedToId,
      areaId
    } = req.body;

    // Validation
    if (!personName || !contactNumber) {
      return res.status(400).json({
        success: false,
        message: 'Person name and contact number are required'
      });
    }

    // Generate unique account code
    const accountCode = await generateAccountCode();

    const account = await prisma.account.create({
      data: {
        accountCode,
        personName,
        dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : null,
        contactNumber,
        businessType,
        customerStage,
        funnelStage,
        assignedToId,
        areaId
      },
      include: {
        assignedTo: {
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
                city: true
              }
            }
          }
        }
      }
    });

    res.status(201).json({ success: true, data: account });
  } catch (error) {
    if (error.code === 'P2002') {
      return res.status(400).json({
        success: false,
        message: 'Account with this contact number already exists'
      });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

export const updateAccount = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      personName,
      dateOfBirth,
      contactNumber,
      businessType,
      customerStage,
      funnelStage,
      assignedToId,
      areaId
    } = req.body;

    const updateData = {};
    
    if (personName !== undefined) updateData.personName = personName;
    if (dateOfBirth !== undefined) updateData.dateOfBirth = dateOfBirth ? new Date(dateOfBirth) : null;
    if (contactNumber !== undefined) updateData.contactNumber = contactNumber;
    if (businessType !== undefined) updateData.businessType = businessType;
    if (customerStage !== undefined) updateData.customerStage = customerStage;
    if (funnelStage !== undefined) updateData.funnelStage = funnelStage;
    if (assignedToId !== undefined) updateData.assignedToId = assignedToId;
    if (areaId !== undefined) updateData.areaId = areaId;

    const account = await prisma.account.update({
      where: { id },
      data: updateData,
      include: {
        assignedTo: {
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
                city: true
              }
            }
          }
        }
      }
    });

    res.json({ success: true, data: account });
  } catch (error) {
    if (error.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

export const deleteAccount = async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.account.delete({
      where: { id }
    });

    res.json({ success: true, message: 'Account deleted successfully' });
  } catch (error) {
    if (error.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== HELPER FUNCTIONS ====================

async function generateAccountCode() {
  const prefix = 'ACC';
  const date = new Date();
  const year = date.getFullYear().toString().slice(-2);
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  
  // Get count of accounts created today
  const startOfDay = new Date(date.setHours(0, 0, 0, 0));
  const endOfDay = new Date(date.setHours(23, 59, 59, 999));
  
  const count = await prisma.account.count({
    where: {
      createdAt: {
        gte: startOfDay,
        lte: endOfDay
      }
    }
  });
  
  const sequence = (count + 1).toString().padStart(4, '0');
  return `${prefix}${year}${month}${sequence}`;
}

// ==================== STATISTICS ====================

export const getAccountStats = async (req, res) => {
  try {
    const { assignedToId, areaId } = req.query;
    const where = {};
    
    if (assignedToId) where.assignedToId = assignedToId;
    if (areaId) where.areaId = areaId;

    const [
      totalAccounts,
      byCustomerStage,
      byFunnelStage,
      recentAccounts
    ] = await Promise.all([
      prisma.account.count({ where }),
      
      prisma.account.groupBy({
        by: ['customerStage'],
        where,
        _count: true
      }),
      
      prisma.account.groupBy({
        by: ['funnelStage'],
        where,
        _count: true
      }),
      
      prisma.account.findMany({
        where,
        take: 10,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          accountCode: true,
          personName: true,
          contactNumber: true,
          customerStage: true,
          createdAt: true
        }
      })
    ]);

    res.json({
      success: true,
      data: {
        totalAccounts,
        byCustomerStage,
        byFunnelStage,
        recentAccounts
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== BULK OPERATIONS ====================

export const bulkAssignAccounts = async (req, res) => {
  try {
    const { accountIds, assignedToId } = req.body;

    if (!accountIds || !Array.isArray(accountIds) || accountIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'accountIds array is required'
      });
    }

    const result = await prisma.account.updateMany({
      where: {
        id: { in: accountIds }
      },
      data: {
        assignedToId
      }
    });

    res.json({
      success: true,
      message: `${result.count} accounts assigned successfully`,
      count: result.count
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
