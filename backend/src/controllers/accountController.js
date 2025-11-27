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
      customerStage, 
      funnelStage,
      isApproved,
      createdById,
      search,
      page = 1,
      limit = 50
    } = req.query;

    const where = {};
    
    if (areaId) where.areaId = parseInt(areaId);
    if (assignedToId) where.assignedToId = assignedToId;
    if (customerStage) where.customerStage = customerStage;
    if (funnelStage) where.funnelStage = funnelStage;
    if (isApproved !== undefined) where.isApproved = isApproved === 'true';
    if (createdById) where.createdById = createdById;
    
    if (search) {
      where.OR = [
        { businessName: { contains: search, mode: 'insensitive' } },
        { personName: { contains: search, mode: 'insensitive' } },
        { accountCode: { contains: search, mode: 'insensitive' } },
        { contactNumber: { contains: search } },
        { gstNumber: { contains: search, mode: 'insensitive' } },
        { panCard: { contains: search, mode: 'insensitive' } }
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
      createdById
    } = req.body;

    console.log('📥 CREATE ACCOUNT REQUEST:', {
      personName,
      contactNumber,
      businessName
    });

    // Validation
    if (!personName || !contactNumber) {
      return res.status(400).json({
        success: false,
        message: 'Person name and contact number are required'
      });
    }

    // Validate contact number format (10 digits)
    if (!/^\d{10}$/.test(contactNumber)) {
      return res.status(400).json({
        success: false,
        message: 'Contact number must be exactly 10 digits'
      });
    }

    // Note: Duplicate contact numbers are allowed as per business requirements
    // Multiple accounts can share the same contact number
    console.log('✅ Validation passed, generating account code...');

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

    // Generate unique account code
    const accountCode = await generateAccountCode();
    console.log('✅ Generated account code:', accountCode);

    // Get user ID from auth middleware (req.user.id)
    const userId = req.user?.id || createdById;

    // Upload images to Cloudinary if provided
    let ownerImageUrl = null;
    let shopImageUrl = null;

    console.log('🖼️ Image upload check:');
    console.log('  - Owner image provided:', !!ownerImage);
    console.log('  - Shop image provided:', !!shopImage);
    if (ownerImage) {
      console.log('  - Owner image starts with data:image:', ownerImage.startsWith('data:image'));
      console.log('  - Owner image length:', ownerImage.length);
    }
    if (shopImage) {
      console.log('  - Shop image starts with data:image:', shopImage.startsWith('data:image'));
      console.log('  - Shop image length:', shopImage.length);
    }

    if (ownerImage && ownerImage.startsWith('data:image')) {
      try {
        console.log('📸 Uploading owner image to Cloudinary...');
        console.log('📦 Owner image size:', ownerImage.length, 'characters');
        ownerImageUrl = await uploadBase64Image(ownerImage, 'accounts/owners');
        console.log('✅ Owner image uploaded:', ownerImageUrl);
      } catch (error) {
        console.error('❌ Owner image upload failed:', error.message);
        console.error('❌ Full error:', error);
        ownerImageUrl = null;
      }
    } else if (ownerImage && ownerImage.startsWith('http')) {
      console.log('📎 Using existing owner image URL');
      ownerImageUrl = ownerImage;
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
        shopImageUrl = null;
      }
    } else if (shopImage && shopImage.startsWith('http')) {
      console.log('📎 Using existing shop image URL');
      shopImageUrl = shopImage;
    }

    console.log('🖼️ Final image URLs:');
    console.log('  - Owner image URL:', ownerImageUrl);
    console.log('  - Shop image URL:', shopImageUrl);

    console.log('✅ Creating account in database...');
    const account = await prisma.account.create({
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
        assignedToId,
        areaId: areaId ? parseInt(areaId) : null,
        createdById: userId,
        isApproved: false
      },
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

    console.log('✅ Account created successfully:', account.accountCode);
    res.status(201).json({ 
      success: true, 
      message: 'Account created successfully',
      data: account 
    });
  } catch (error) {
    console.error('❌ Create account error:', error.message);
    console.error('Error code:', error.code);
    console.error('Error meta:', error.meta);
    
    if (error.code === 'P2002') {
      // P2002 is Prisma's unique constraint violation error
      const field = error.meta?.target?.[0] || 'field';
      console.error(`Duplicate field detected: ${field}`);
      return res.status(400).json({
        success: false,
        message: `Duplicate ${field} - this value already exists`
      });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

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
      where: { id }
    });

    if (!existingAccount) {
      return res.status(404).json({ 
        success: false, 
        message: 'Account not found' 
      });
    }

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
        approvedAt: new Date()
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

    const account = await prisma.account.update({
      where: { id },
      data: {
        isApproved: false,
        approvedById: null,
        approvedAt: null
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

// ==================== CHECK CONTACT NUMBER ====================

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
