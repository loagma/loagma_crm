import { PrismaClient } from '@prisma/client';
import { randomUUID } from 'crypto';
import { uploadBase64Image } from '../services/cloudinaryService.js';

const prisma = new PrismaClient();

// ==================== ACCOUNT CRUD ====================

export const getAllAccounts = async (req, res) => {
  try {
    const {
      areaId,
      assignedToId,
      assignedDay,
      customerStage,
      funnelStage,
      isApproved,
      createdById,
      approvedById,
      search,
      pincode,
      startDate,
      endDate,
      page = 1,
      limit = 20
    } = req.query;

    const where = {};

    if (areaId) where.areaId = parseInt(areaId);
    if (assignedToId) where.assignedToId = assignedToId;
    // Day-wise filter for salesman: 1=Mon .. 7=Sun
    if (assignedDay !== undefined && assignedDay !== '' && assignedDay !== null) {
      const day = parseInt(assignedDay, 10);
      if (day >= 1 && day <= 7) {
        // assignedDays is stored as JSON array of numbers in MySQL
        where.assignedDays = { array_contains: day };
      }
    }
    if (customerStage) where.customerStage = customerStage;
    if (funnelStage) where.funnelStage = funnelStage;
    if (isApproved !== undefined) where.isApproved = isApproved === 'true';
    if (createdById) where.createdById = createdById;
    if (approvedById) where.approvedById = approvedById;
    if (pincode && String(pincode).trim()) {
      const pin = String(pincode).trim();
      // Allow partial match so short prefixes still work, but index on pincode keeps it fast.
      where.pincode = { contains: pin };
    }

    // Date range filtering
    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) {
        const start = new Date(startDate);
        where.createdAt.gte = start;
        console.log('📅 Start date filter:', start.toISOString());
      }
      if (endDate) {
        const end = new Date(endDate);
        where.createdAt.lte = end;
        console.log('📅 End date filter:', end.toISOString());
      }
    }

    if (search) {
      where.OR = [
        { businessName: { contains: search } },
        { personName: { contains: search } },
        { accountCode: { contains: search } },
        { contactNumber: { contains: search } },
        { gstNumber: { contains: search } },
        { panCard: { contains: search } }
      ];
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);

    console.log('🔍 Account query filters:', {
      where,
      startDate,
      endDate,
      page,
      limit,
      dateFilter: where.createdAt
    });

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
              contactNumber: true,
              roleId: true
            }
          },
          createdBy: {
            select: {
              id: true,
              name: true,
              contactNumber: true,
              roleId: true
            }
          },
          approvedBy: {
            select: {
              id: true,
              name: true,
              contactNumber: true,
              roleId: true
            }
          },
          areaRelation: {
            include: {
              zone: {
                include: {
                  city: {
                    include: {
                      district: {
                        include: {
                          region: {
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
          }
        }
      }),
      prisma.account.count({ where })
    ]);

    console.log('✅ Found accounts:', accounts.length, 'of', total);
    if (accounts.length > 0) {
      console.log('📊 Account date range in results:');
      console.log('   First account:', accounts[0].personName, 'created at:', accounts[0].createdAt);
      console.log('   Last account:', accounts[accounts.length - 1].personName, 'created at:', accounts[accounts.length - 1].createdAt);
    }

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
    console.error('Get all accounts error:', error);
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
            email: true,
            roleId: true
          }
        },
        createdBy: {
          select: {
            id: true,
            name: true,
            contactNumber: true,
            email: true,
            roleId: true
          }
        },
        approvedBy: {
          select: {
            id: true,
            name: true,
            contactNumber: true,
            email: true,
            roleId: true
          }
        },
        areaRelation: {
          include: {
            zone: {
              include: {
                city: {
                  include: {
                    district: {
                      include: {
                        region: {
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
        }
      }
    });

    if (!account) {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }

    res.json({ success: true, data: account });
  } catch (error) {
    console.error('Get account by ID error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createAccount = async (req, res) => {
  try {
    console.log('📥 CREATE ACCOUNT REQUEST (single):', {
      personName: req.body?.personName,
      contactNumber: req.body?.contactNumber,
      businessName: req.body?.businessName,
    });

    const account = await createAccountFromPayload(req.body, req.user?.id, {
      includeRelations: true,
    });

    console.log('✅ Account created successfully:', account.accountCode);
    return res.status(201).json({
      success: true,
      message: 'Account created successfully',
      data: account,
    });
  } catch (error) {
    console.error('❌ Create account error:', error.message);
    console.error('Error code:', error.code);
    console.error('Error meta:', error.meta);

    if (error.statusCode === 400) {
      return res.status(400).json({
        success: false,
        message: error.userMessage || error.message,
      });
    }

    if (error.code === 'P2002') {
      // P2002 is Prisma's unique constraint violation error
      const field = error.meta?.target?.[0] || 'field';
      console.error(`Duplicate field detected: ${field}`);
      return res.status(400).json({
        success: false,
        message: `Duplicate ${field} - this value already exists`,
      });
    }

    return res
      .status(500)
      .json({ success: false, message: error.message || 'Failed to create account' });
  }
};

async function createAccountFromPayload(payload, authUserId, options = {}) {
  const {
    businessName,
    businessType,
    businessSize,
    personName,
    contactNumber,
    dateOfBirth,
    customerStage,
    funnelStage,
    gstNumber,
    panCard,
    ownerImage,
    shopImage,
    isActive,
    pincode,
    country,
    state,
    district,
    city,
    area,
    address,
    latitude,
    longitude,
    assignedToId,
    areaId,
    createdById,
  } = payload || {};

  const { includeRelations = false } = options;

  const validationError = (message) => {
    const err = new Error(message);
    err.statusCode = 400;
    err.userMessage = message;
    return err;
  };

  // Required fields
  if (!personName || !contactNumber) {
    throw validationError('Person name and contact number are required');
  }

  // Contact number: 10 digits
  if (!/^\d{10}$/.test(contactNumber)) {
    throw validationError('Contact number must be exactly 10 digits');
  }

  // PAN format if provided
  if (panCard && !/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/.test(panCard)) {
    throw validationError('Invalid PAN card format');
  }

  // Pincode format if provided
  if (pincode && !/^\d{6}$/.test(pincode)) {
    throw validationError('Pincode must be exactly 6 digits');
  }

  // Coordinates validation if provided
  if (latitude !== undefined && latitude !== null) {
    const lat = parseFloat(latitude);
    if (Number.isNaN(lat) || lat < -90 || lat > 90) {
      throw validationError('Invalid latitude. Must be between -90 and 90');
    }
  }

  if (longitude !== undefined && longitude !== null) {
    const lng = parseFloat(longitude);
    if (Number.isNaN(lng) || lng < -180 || lng > 180) {
      throw validationError('Invalid longitude. Must be between -180 and 180');
    }
  }

  // Both coordinates together or none
  if (
    (latitude !== undefined && latitude !== null) !==
    (longitude !== undefined && longitude !== null)
  ) {
    throw validationError('Both latitude and longitude must be provided together');
  }

  // Generate unique account code
  const accountCode = await generateAccountCode();

  // Determine creator
  const userId = authUserId || createdById || null;

  // Auto-assign telecaller based on pincode mapping (all days) when not explicitly provided
  let finalAssignedToId = assignedToId || null;
  try {
    if (!finalAssignedToId && pincode) {
      const mapping = await prisma.telecallerPincodeAssignment.findFirst({
        where: {
          pincode,
          isActive: true,
          dayOfWeek: 0,
        },
      });
      if (mapping) {
        finalAssignedToId = mapping.telecallerId;
      }
    }
  } catch (e) {
    console.error('⚠️ Telecaller pincode auto-assignment failed (helper):', e);
  }

  // Upload images if provided
  let ownerImageUrl = null;
  let shopImageUrl = null;

  if (ownerImage && ownerImage.startsWith('data:image')) {
    try {
      ownerImageUrl = await uploadBase64Image(ownerImage, 'accounts/owners');
    } catch (error) {
      console.error('❌ Owner image upload failed (helper):', error.message);
      ownerImageUrl = null;
    }
  } else if (ownerImage && ownerImage.startsWith('http')) {
    ownerImageUrl = ownerImage;
  }

  if (shopImage && shopImage.startsWith('data:image')) {
    try {
      shopImageUrl = await uploadBase64Image(shopImage, 'accounts/shops');
    } catch (error) {
      console.error('❌ Shop image upload failed (helper):', error.message);
      shopImageUrl = null;
    }
  } else if (shopImage && shopImage.startsWith('http')) {
    shopImageUrl = shopImage;
  }

  const prismaArgs = {
    data: {
      id: randomUUID(),
      accountCode,
      businessName,
      businessType,
      businessSize,
      personName,
      contactNumber,
      dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : null,
      customerStage,
      funnelStage,
      gstNumber: gstNumber?.toUpperCase(),
      panCard: panCard?.toUpperCase(),
      ownerImage: ownerImageUrl,
      shopImage: shopImageUrl,
      isActive: isActive !== undefined ? isActive : true,
      pincode,
      country,
      state,
      district,
      city,
      area,
      address,
      latitude: latitude ? parseFloat(latitude) : null,
      longitude: longitude ? parseFloat(longitude) : null,
      assignedToId: finalAssignedToId,
      areaId: areaId ? parseInt(areaId, 10) : null,
      createdById: userId,
      isApproved: false,
    },
  };

  if (includeRelations) {
    prismaArgs.include = {
      assignedTo: {
        select: {
          id: true,
          name: true,
          contactNumber: true,
          roleId: true,
        },
      },
      createdBy: {
        select: {
          id: true,
          name: true,
          contactNumber: true,
          roleId: true,
        },
      },
      areaRelation: {
        include: {
          zone: {
            include: {
              city: true,
            },
          },
        },
      },
    };
  }

  const account = await prisma.account.create(prismaArgs);
  return account;
}

export const updateAccount = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      businessName,
      businessType,
      businessSize,
      personName,
      contactNumber,
      dateOfBirth,
      customerStage,
      funnelStage,
      gstNumber,
      panCard,
      ownerImage,
      shopImage,
      isActive,
      pincode,
      country,
      state,
      district,
      city,
      area,
      address,
      latitude,
      longitude,
      assignedToId,
      areaId
    } = req.body;

    // Check if account exists
    const existingAccount = await prisma.account.findUnique({
      where: { id },
      include: {
        createdBy: {
          include: {
            role: true
          }
        }
      }
    });

    if (!existingAccount) {
      return res.status(404).json({
        success: false,
        message: 'Account not found'
      });
    }

    // NOTE: Previous version restricted edits to creator within a 2‑hour window
    // and blocked other users with "You do not have permission to edit this account".
    // For the CRM flows (telecaller verify + admin approve + customer list),
    // we now allow any authenticated user who reaches this controller to update.
    //
    // If you ever need fine‑grained permissions again, reintroduce checks here,
    // but make sure admin roles are always allowed to bypass them.

    // If updating contact number, check for duplicates
    if (contactNumber && contactNumber !== existingAccount.contactNumber) {
      const duplicate = await prisma.account.findFirst({
        where: {
          contactNumber,
          id: { not: id }
        }
      });

      if (duplicate) {
        return res.status(400).json({
          success: false,
          message: 'Contact number already exists for another account'
        });
      }

      // Validate contact number format
      if (!/^\d{10}$/.test(contactNumber)) {
        return res.status(400).json({
          success: false,
          message: 'Contact number must be exactly 10 digits'
        });
      }
    }

    // Validate GST format if provided
    // if (gstNumber && !/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/.test(gstNumber)) {
    //   return res.status(400).json({
    //     success: false,
    //     message: 'Invalid GST number format'
    //   });
    // }

    // Validate PAN format if provided
    if (panCard && !/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/.test(panCard)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid PAN card format'
      });
    }

    // Validate pincode format if provided
    if (pincode && !/^\d{6}$/.test(pincode)) {
      return res.status(400).json({
        success: false,
        message: 'Pincode must be exactly 6 digits'
      });
    }

    // Validate coordinates if provided
    if (latitude !== undefined && latitude !== null) {
      const lat = parseFloat(latitude);
      if (isNaN(lat) || lat < -90 || lat > 90) {
        return res.status(400).json({
          success: false,
          message: 'Invalid latitude. Must be between -90 and 90'
        });
      }
    }

    if (longitude !== undefined && longitude !== null) {
      const lng = parseFloat(longitude);
      if (isNaN(lng) || lng < -180 || lng > 180) {
        return res.status(400).json({
          success: false,
          message: 'Invalid longitude. Must be between -180 and 180'
        });
      }
    }

    // Ensure both coordinates are provided together or both are null
    if ((latitude !== undefined && latitude !== null) !== (longitude !== undefined && longitude !== null)) {
      return res.status(400).json({
        success: false,
        message: 'Both latitude and longitude must be provided together'
      });
    }

    // Upload images to Cloudinary if provided
    let ownerImageUrl = ownerImage;
    let shopImageUrl = shopImage;

    if (ownerImage && ownerImage.startsWith('data:image')) {
      try {
        console.log('📸 Uploading owner image to Cloudinary...');
        console.log('📦 Owner image size:', ownerImage.length, 'characters');
        ownerImageUrl = await uploadBase64Image(ownerImage, 'accounts/owners');
        console.log('✅ Owner image uploaded:', ownerImageUrl);
      } catch (error) {
        console.error('❌ Owner image upload failed:', error.message);
        console.error('❌ Full error:', error);
        ownerImageUrl = undefined; // Don't update if upload fails
      }
    } else if (ownerImage && !ownerImage.startsWith('http')) {
      ownerImageUrl = undefined;
    }

    if (shopImage && shopImage.startsWith('data:image')) {
      try {
        console.log('📸 Uploading shop image to Cloudinary...');
        console.log('📦 Shop image size:', shopImage.length, 'characters');
        shopImageUrl = await uploadBase64Image(shopImage, 'accounts/shops');
        console.log('✅ Shop image uploaded:', shopImageUrl);
      } catch (error) {
        console.error('❌ Shop image upload failed:', error.message);
        console.error('❌ Full error:', error);
        shopImageUrl = undefined; // Don't update if upload fails
      }
    } else if (shopImage && !shopImage.startsWith('http')) {
      shopImageUrl = undefined;
    }

    const updateData = {};

    if (businessName !== undefined) updateData.businessName = businessName;
    if (businessType !== undefined) updateData.businessType = businessType;
    if (businessSize !== undefined) updateData.businessSize = businessSize;
    if (personName !== undefined) updateData.personName = personName;
    if (contactNumber !== undefined) updateData.contactNumber = contactNumber;
    if (dateOfBirth !== undefined) updateData.dateOfBirth = dateOfBirth ? new Date(dateOfBirth) : null;
    if (customerStage !== undefined) updateData.customerStage = customerStage;
    if (funnelStage !== undefined) updateData.funnelStage = funnelStage;
    if (gstNumber !== undefined) updateData.gstNumber = gstNumber?.toUpperCase();
    if (panCard !== undefined) updateData.panCard = panCard?.toUpperCase();
    if (ownerImageUrl !== undefined) updateData.ownerImage = ownerImageUrl;
    if (shopImageUrl !== undefined) updateData.shopImage = shopImageUrl;
    if (isActive !== undefined) updateData.isActive = isActive;
    if (pincode !== undefined) updateData.pincode = pincode;
    if (country !== undefined) updateData.country = country;
    if (state !== undefined) updateData.state = state;
    if (district !== undefined) updateData.district = district;
    if (city !== undefined) updateData.city = city;
    if (area !== undefined) updateData.area = area;
    if (address !== undefined) updateData.address = address;
    if (latitude !== undefined) updateData.latitude = latitude ? parseFloat(latitude) : null;
    if (longitude !== undefined) updateData.longitude = longitude ? parseFloat(longitude) : null;
    if (assignedToId !== undefined) updateData.assignedToId = assignedToId;
    if (areaId !== undefined) updateData.areaId = areaId ? parseInt(areaId) : null;

    const account = await prisma.account.update({
      where: { id },
      data: updateData,
      include: {
        assignedTo: {
          select: {
            id: true,
            name: true,
            contactNumber: true,
            roleId: true
          }
        },
        createdBy: {
          select: {
            id: true,
            name: true,
            contactNumber: true,
            roleId: true
          }
        },
        approvedBy: {
          select: {
            id: true,
            name: true,
            contactNumber: true,
            roleId: true
          }
        },
        areaRelation: {
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

    res.json({
      success: true,
      message: 'Account updated successfully',
      data: account
    });
  } catch (error) {
    console.error('Update account error:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

export const deleteAccount = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if account exists
    const existingAccount = await prisma.account.findUnique({
      where: { id }
    });

    if (!existingAccount) {
      return res.status(404).json({
        success: false,
        message: 'Account not found'
      });
    }

    await prisma.account.delete({
      where: { id }
    });

    res.json({
      success: true,
      message: 'Account deleted successfully'
    });
  } catch (error) {
    console.error('Delete account error:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== APPROVAL OPERATIONS ====================

export const approveAccount = async (req, res) => {
  try {
    const { id } = req.params;
    const approvedById = req.user?.id || req.body.approvedById;
    const verificationNotes = req.body.verificationNotes ?? null;

    if (!approvedById) {
      return res.status(400).json({
        success: false,
        message: 'Approver ID is required'
      });
    }

    const account = await prisma.account.update({
      where: { id },
      data: {
        isApproved: true,
        approvedById,
        approvedAt: new Date(),
        verificationNotes: verificationNotes || null,
        rejectionNotes: null
      },
      include: {
        assignedTo: {
          select: {
            id: true,
            name: true,
            contactNumber: true
          }
        },
        createdBy: {
          select: {
            id: true,
            name: true,
            contactNumber: true
          }
        },
        approvedBy: {
          select: {
            id: true,
            name: true,
            contactNumber: true
          }
        }
      }
    });

    res.json({
      success: true,
      message: 'Account approved successfully',
      data: account
    });
  } catch (error) {
    console.error('Approve account error:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

export const rejectAccount = async (req, res) => {
  try {
    const { id } = req.params;
    const rejectionNotes = req.body.rejectionNotes ?? null;

    const account = await prisma.account.update({
      where: { id },
      data: {
        isApproved: false,
        approvedById: null,
        approvedAt: null,
        verificationNotes: null,
        rejectionNotes: rejectionNotes || null
      },
      include: {
        createdBy: {
          select: {
            id: true,
            name: true,
            contactNumber: true
          }
        }
      }
    });

    res.json({
      success: true,
      message: 'Account approval rejected',
      data: account
    });
  } catch (error) {
    console.error('Reject account error:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /accounts/pincode/:pincode/count
export const getAccountCountByPincode = async (req, res) => {
  try {
    const { pincode } = req.params;
    const pin = String(pincode || '').trim();
    if (!/^\d{6}$/.test(pin)) {
      return res.status(400).json({
        success: false,
        message: 'Pincode must be a 6-digit number',
      });
    }

    const count = await prisma.account.count({
      where: { pincode: pin },
    });

    return res.json({
      success: true,
      data: { pincode: pin, count },
    });
  } catch (error) {
    console.error('getAccountCountByPincode error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to get account count',
    });
  }
};

// ==================== HELPER FUNCTIONS ====================

async function generateAccountCode() {
  const prefix = '000';
  const date = new Date();
  const year = date.getFullYear().toString().slice(-2);
  const month = (date.getMonth() + 1).toString().padStart(2, '0');

  // Try up to 10 times to generate a unique code
  for (let attempt = 0; attempt < 10; attempt++) {
    // Get count of all accounts with this year-month prefix
    const pattern = `${prefix}${year}${month}%`;
    const existingAccounts = await prisma.account.findMany({
      where: {
        accountCode: {
          startsWith: `${prefix}${year}${month}`
        }
      },
      select: { accountCode: true },
      orderBy: { accountCode: 'desc' }
    });

    let sequence = 1;
    if (existingAccounts.length > 0) {
      // Extract the last sequence number and increment
      const lastCode = existingAccounts[0].accountCode;
      const lastSequence = parseInt(lastCode.slice(-4));
      sequence = lastSequence + 1;
    }

    const accountCode = `${prefix}${year}${month}${sequence.toString().padStart(4, '0')}`;

    // Check if this code already exists
    const exists = await prisma.account.findUnique({
      where: { accountCode }
    });

    if (!exists) {
      return accountCode;
    }

    // If exists, wait a bit and try again
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  // Fallback: use timestamp to ensure uniqueness
  const timestamp = Date.now().toString().slice(-6);
  return `${prefix}${year}${month}${timestamp}`;
}

// ==================== STATISTICS ====================

export const getAccountStats = async (req, res) => {
  try {
    const { assignedToId, areaId, createdById } = req.query;
    const where = {};

    if (assignedToId) where.assignedToId = assignedToId;
    if (areaId) where.areaId = parseInt(areaId);
    if (createdById) where.createdById = createdById;

    const [
      totalAccounts,
      approvedAccounts,
      pendingAccounts,
      byCustomerStage,
      byFunnelStage,
      recentAccounts
    ] = await Promise.all([
      prisma.account.count({ where }),

      prisma.account.count({
        where: { ...where, isApproved: true }
      }),

      prisma.account.count({
        where: { ...where, isApproved: false }
      }),

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
          isApproved: true,
          createdAt: true,
          createdBy: {
            select: {
              name: true,
              roleId: true
            }
          }
        }
      })
    ]);

    res.json({
      success: true,
      data: {
        totalAccounts,
        approvedAccounts,
        pendingAccounts,
        byCustomerStage,
        byFunnelStage,
        recentAccounts
      }
    });
  } catch (error) {
    console.error('Get account stats error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== BULK OPERATIONS ====================

export const bulkCreateAccounts = async (req, res) => {
  try {
    const { accounts } = req.body || {};
    if (!Array.isArray(accounts) || accounts.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Body must include a non-empty "accounts" array',
      });
    }

    const authUserId = req.user?.id;
    const results = [];
    let created = 0;

    for (let i = 0; i < accounts.length; i += 1) {
      const payload = accounts[i] || {};
      const personName = payload.personName;
      const contactNumber = payload.contactNumber;

      try {
        const account = await createAccountFromPayload(payload, authUserId);
        created += 1;
        results.push({
          index: i,
          success: true,
          accountId: account.id,
          accountCode: account.accountCode,
          personName: account.personName,
          contactNumber: account.contactNumber,
          pincode: account.pincode,
        });
      } catch (err) {
        let reason =
          err?.userMessage || err?.message || 'Failed to create account';
        if (err?.code === 'P2002') {
          const field = err.meta?.target?.[0] || 'field';
          reason = `Duplicate ${field} - this value already exists`;
        }
        results.push({
          index: i,
          success: false,
          personName,
          contactNumber,
          reason,
        });
      }
    }

    const failed = results.length - created;

    return res.status(201).json({
      success: failed === 0,
      message: 'Bulk account import completed',
      data: {
        created,
        failed,
        results,
      },
    });
  } catch (error) {
    console.error('Bulk create accounts error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to create accounts in bulk',
    });
  }
};

export const bulkAssignAccounts = async (req, res) => {
  try {
    const { accountIds, assignedToId, assignedDays } = req.body;

    if (!accountIds || !Array.isArray(accountIds) || accountIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'accountIds array is required'
      });
    }

    const data = { assignedToId };
    if (assignedDays && Array.isArray(assignedDays) && assignedDays.length > 0) {
      const days = assignedDays.map((d) => parseInt(d, 10)).filter((d) => d >= 1 && d <= 7);
      data.assignedDays = [...new Set(days)];
    } else {
      data.assignedDays = [];
    }

    const result = await prisma.account.updateMany({
      where: {
        id: { in: accountIds }
      },
      data
    });

    res.json({
      success: true,
      message: `${result.count} accounts assigned successfully`,
      count: result.count
    });
  } catch (error) {
    console.error('Bulk assign accounts error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const bulkApproveAccounts = async (req, res) => {
  try {
    const { accountIds } = req.body;
    const approvedById = req.user?.id || req.body.approvedById;

    if (!accountIds || !Array.isArray(accountIds) || accountIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'accountIds array is required'
      });
    }

    if (!approvedById) {
      return res.status(400).json({
        success: false,
        message: 'Approver ID is required'
      });
    }

    const result = await prisma.account.updateMany({
      where: {
        id: { in: accountIds }
      },
      data: {
        isApproved: true,
        approvedById,
        approvedAt: new Date()
      }
    });

    res.json({
      success: true,
      message: `${result.count} accounts approved successfully`,
      count: result.count
    });
  } catch (error) {
    console.error('Bulk approve accounts error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== DEBUG ENDPOINT (REMOVE IN PRODUCTION) ====================

export const debugDateFiltering = async (req, res) => {
  try {
    const { startDate, endDate, period } = req.query;

    console.log('🐛 DEBUG: Date filtering test');
    console.log('   Raw startDate:', startDate);
    console.log('   Raw endDate:', endDate);
    console.log('   Period:', period);

    const where = {};

    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) {
        const start = new Date(startDate);
        where.createdAt.gte = start;
        console.log('   Parsed startDate:', start.toISOString());
      }
      if (endDate) {
        const end = new Date(endDate);
        where.createdAt.lte = end;
        console.log('   Parsed endDate:', end.toISOString());
      }
    }

    const accounts = await prisma.account.findMany({
      where,
      take: 5,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        personName: true,
        createdAt: true
      }
    });

    console.log('   Found accounts:', accounts.length);
    accounts.forEach(account => {
      console.log(`     - ${account.personName}: ${account.createdAt.toISOString()}`);
    });

    res.json({
      success: true,
      debug: {
        rawStartDate: startDate,
        rawEndDate: endDate,
        parsedStartDate: startDate ? new Date(startDate).toISOString() : null,
        parsedEndDate: endDate ? new Date(endDate).toISOString() : null,
        whereClause: where,
        accountsFound: accounts.length,
        accounts: accounts.map(a => ({
          name: a.personName,
          createdAt: a.createdAt.toISOString()
        }))
      }
    });
  } catch (error) {
    console.error('Debug date filtering error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const checkContactNumber = async (req, res) => {
  try {
    const { contactNumber } = req.body;

    if (!contactNumber) {
      return res.status(400).json({
        success: false,
        message: 'Contact number is required'
      });
    }

    // Validate contact number format (10 digits)
    if (!/^\d{10}$/.test(contactNumber)) {
      return res.status(400).json({
        success: false,
        message: 'Contact number must be exactly 10 digits'
      });
    }

    // Check if contact number exists
    const existingAccount = await prisma.account.findFirst({
      where: { contactNumber },
      select: {
        id: true,
        accountCode: true,
        businessName: true,
        personName: true,
        contactNumber: true
      }
    });

    if (existingAccount) {
      return res.json({
        success: true,
        exists: true,
        message: 'Contact number already exists',
        data: existingAccount
      });
    }

    res.json({
      success: true,
      exists: false,
      message: 'Contact number is available'
    });
  } catch (error) {
    console.error('Check contact number error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};
