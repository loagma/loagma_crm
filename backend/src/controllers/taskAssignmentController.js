import { PrismaClient } from '@prisma/client';
import { getAreasByPincode } from '../services/pincodeService.js';
import { searchBusinessesByPincode } from '../services/googlePlacesService.js';

const prisma = new PrismaClient();

/**
 * Get all salesmen (users with salesman role in primaryRole, otherRoles, roles array, or roleId)
 */
export const getAllSalesmen = async (req, res) => {
  try {
    const allUsers = await prisma.user.findMany({
      where: { isActive: true },
      select: {
        id: true,
        name: true,
        contactNumber: true,
        employeeCode: true,
        email: true,
        roles: true,
        roleId: true
      }
    });

    const salesmen = allUsers.filter(user => {
      const rId = user.roleId?.toLowerCase();
      const rArr = Array.isArray(user.roles)
        ? user.roles.map(r => r.toLowerCase())
        : [];

      return (
        rId === "salesman" ||
        rArr.includes("salesman")
      );
    });

    res.json({
      success: true,
      count: salesmen.length,
      salesmen
    });

  } catch (error) {
    console.error("Error fetching salesmen:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};



/**
 * Get location details by pincode
 */
export const getLocationByPincode = async (req, res) => {
  try {
    const { pincode } = req.params;

    // Validate pincode
    if (!/^\d{6}$/.test(pincode)) {
      return res.status(400).json({ 
        success: false, 
        message: 'Invalid pincode format. Must be 6 digits.' 
      });
    }

    // Fetch location details from pincode service
    const result = await getAreasByPincode(pincode);

    if (!result.success) {
      return res.status(404).json(result);
    }

    // Format response
    const location = {
      pincode: result.data.pincode,
      country: result.data.country,
      state: result.data.state,
      district: result.data.district,
      city: result.data.city,
      areas: result.data.areas.map(area => area.name)
    };

    res.json({ success: true, location });
  } catch (error) {
    console.error('Get location error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Assign areas to salesman
 */
export const assignAreasToSalesman = async (req, res) => {
  try {
    const {
      salesmanId,
      salesmanName,
      pincode,
      country,
      state,
      district,
      city,
      areas,
      businessTypes,
      totalBusinesses
    } = req.body;

    console.log('📥 Received assignment request:', {
      salesmanId,
      salesmanName,
      pincode,
      areasCount: areas?.length,
      businessTypes,
      totalBusinesses
    });

    // Validation
    if (!salesmanId || !pincode || !areas || areas.length === 0) {
      console.log('❌ Validation failed: Missing required fields');
      return res.status(400).json({
        success: false,
        message: 'salesmanId, pincode, and areas are required'
      });
    }

    // Check if salesman exists (only check basic fields)
    const salesman = await prisma.user.findUnique({
      where: { id: salesmanId },
      select: {
        id: true,
        name: true,
        employeeCode: true,
        isActive: true
      }
    });

    if (!salesman) {
      console.log('❌ Salesman not found:', salesmanId);
      return res.status(404).json({
        success: false,
        message: 'Salesman not found'
      });
    }

    if (!salesman.isActive) {
      console.log('❌ Salesman is not active:', salesmanId);
      return res.status(400).json({
        success: false,
        message: 'Salesman is not active'
      });
    }

    // Check if assignment already exists for this pincode and salesman
    const existingAssignment = await prisma.taskAssignment.findFirst({
      where: {
        salesmanId,
        pincode
      }
    });

    let assignment;
    if (existingAssignment) {
      // Update existing assignment
      assignment = await prisma.taskAssignment.update({
        where: { id: existingAssignment.id },
        data: {
          areas,
          businessTypes: businessTypes || [],
          totalBusinesses: totalBusinesses || 0,
          updatedAt: new Date()
        }
      });
      console.log(`✅ Updated assignment for ${salesmanName} in pincode ${pincode}`);
    } else {
      // Create new task assignment
      assignment = await prisma.taskAssignment.create({
        data: {
          salesmanId,
          salesmanName: salesmanName || salesman.name,
          pincode,
          country,
          state,
          district,
          city,
          areas,
          businessTypes: businessTypes || [],
          totalBusinesses: totalBusinesses || 0
        }
      });
      console.log(`✅ Created new assignment for ${salesmanName} in pincode ${pincode}`);
    }

    res.status(201).json({
      success: true,
      message: `Successfully assigned ${areas.length} areas to ${salesmanName || salesman.name}`,
      assignment
    });
  } catch (error) {
    console.error('Assign areas error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Get assignments by salesman ID
 */
export const getAssignmentsBySalesman = async (req, res) => {
  try {
    const { salesmanId } = req.params;

    const assignments = await prisma.taskAssignment.findMany({
      where: { salesmanId },
      orderBy: { assignedDate: 'desc' }
    });

    res.json({ success: true, assignments });
  } catch (error) {
    console.error('Get assignments error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Update assignment
 */
export const updateAssignment = async (req, res) => {
  try {
    const { assignmentId } = req.params;
    const { areas, businessTypes, totalBusinesses } = req.body;

    console.log('📝 Updating assignment:', assignmentId, req.body);

    // Build update data object
    const updateData = {};
    if (areas !== undefined) updateData.areas = areas;
    if (businessTypes !== undefined) updateData.businessTypes = businessTypes;
    if (totalBusinesses !== undefined) updateData.totalBusinesses = totalBusinesses;
    updateData.updatedAt = new Date();

    const assignment = await prisma.taskAssignment.update({
      where: { id: assignmentId },
      data: updateData
    });

    console.log('✅ Assignment updated successfully');
    res.json({ 
      success: true, 
      message: 'Assignment updated successfully',
      assignment 
    });
  } catch (error) {
    console.error('Update assignment error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Delete assignment
 */
export const deleteAssignment = async (req, res) => {
  try {
    const { assignmentId } = req.params;

    console.log('🗑️ Deleting assignment:', assignmentId);

    await prisma.taskAssignment.delete({
      where: { id: assignmentId }
    });

    console.log('✅ Assignment deleted successfully');
    res.json({ success: true, message: 'Assignment deleted successfully' });
  } catch (error) {
    console.error('Delete assignment error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Search businesses by pincode and business types
 */
export const searchBusinesses = async (req, res) => {
  try {
    const { pincode, areas, businessTypes } = req.body;

    if (!pincode || !businessTypes || businessTypes.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'pincode and businessTypes are required'
      });
    }

    // Search businesses using Google Places API
    const result = await searchBusinessesByPincode(pincode, businessTypes, areas);

    if (!result.success) {
      return res.status(500).json(result);
    }

    res.json(result);
  } catch (error) {
    console.error('Search businesses error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Save shops to database
 */
export const saveShops = async (req, res) => {
  try {
    const { shops, salesmanId } = req.body;

    if (!shops || shops.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'shops array is required'
      });
    }

    const savedShops = [];
    const shopsByPincode = {};

    for (const shop of shops) {
      // Check if shop already exists by placeId
      let existingShop = null;
      if (shop.placeId) {
        existingShop = await prisma.shop.findUnique({
          where: { placeId: shop.placeId }
        });
      }

      let savedShop;
      if (existingShop) {
        // Update existing shop
        savedShop = await prisma.shop.update({
          where: { id: existingShop.id },
          data: {
            assignedTo: salesmanId || existingShop.assignedTo,
            updatedAt: new Date()
          }
        });
      } else {
        // Create new shop
        savedShop = await prisma.shop.create({
          data: {
            placeId: shop.placeId,
            name: shop.name,
            businessType: shop.businessType,
            address: shop.address,
            pincode: shop.pincode,
            area: shop.area,
            city: shop.city,
            state: shop.state,
            country: shop.country,
            latitude: shop.latitude,
            longitude: shop.longitude,
            phoneNumber: shop.phoneNumber,
            rating: shop.rating,
            assignedTo: salesmanId,
            stage: 'new'
          }
        });
      }
      
      savedShops.push(savedShop);
      
      // Count shops by pincode
      const pincode = savedShop.pincode;
      shopsByPincode[pincode] = (shopsByPincode[pincode] || 0) + 1;
    }

    // Update totalBusinesses count in task assignments
    if (salesmanId) {
      for (const [pincode, count] of Object.entries(shopsByPincode)) {
        await prisma.taskAssignment.updateMany({
          where: {
            salesmanId,
            pincode
          },
          data: {
            totalBusinesses: count
          }
        });
        console.log(`✅ Updated assignment for pincode ${pincode}: ${count} businesses`);
      }
    }

    res.status(201).json({
      success: true,
      message: `Saved ${savedShops.length} shops`,
      shops: savedShops,
      breakdown: shopsByPincode
    });
  } catch (error) {
    console.error('Save shops error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Get shops by salesman
 */
export const getShopsBySalesman = async (req, res) => {
  try {
    const { salesmanId } = req.params;
    const { stage, businessType } = req.query;

    const where = { assignedTo: salesmanId };
    if (stage) where.stage = stage;
    if (businessType) where.businessType = businessType;

    const shops = await prisma.shop.findMany({
      where,
      orderBy: { createdAt: 'desc' }
    });

    res.json({ success: true, shops });
  } catch (error) {
    console.error('Get shops error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Update shop stage
 */
export const updateShopStage = async (req, res) => {
  try {
    const { shopId } = req.params;
    const { stage, notes } = req.body;

    const validStages = ['new', 'follow-up', 'converted', 'lost'];
    if (!validStages.includes(stage)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid stage. Must be: new, follow-up, converted, or lost'
      });
    }

    const shop = await prisma.shop.update({
      where: { id: shopId },
      data: {
        stage,
        notes: notes || undefined,
        lastContactDate: new Date()
      }
    });

    res.json({ success: true, shop });
  } catch (error) {
    console.error('Update shop stage error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

/**
 * Get shops by pincode with filters
 */
export const getShopsByPincode = async (req, res) => {
  try {
    const { pincode } = req.params;
    const { stage, businessType, assignedTo } = req.query;

    const where = { pincode };
    if (stage) where.stage = stage;
    if (businessType) where.businessType = businessType;
    if (assignedTo) where.assignedTo = assignedTo;

    const shops = await prisma.shop.findMany({
      where,
      orderBy: { createdAt: 'desc' }
    });

    res.json({ success: true, shops });
  } catch (error) {
    console.error('Get shops by pincode error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};
