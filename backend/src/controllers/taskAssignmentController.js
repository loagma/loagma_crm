import { PrismaClient } from '@prisma/client';
import { getAreasByPincode } from '../services/pincodeService.js';
import { searchBusinessesByPincode } from '../services/googlePlacesService.js';

const prisma = new PrismaClient();

/**
 * Get all salesmen (users with salesman role)
 */
export const getAllSalesmen = async (req, res) => {
  try {
    const salesmen = await prisma.user.findMany({
      where: {
        OR: [
          { roles: { has: 'salesman' } },
          { roles: { has: 'Salesman' } }
        ],
        isActive: true
      },
      select: {
        id: true,
        name: true,
        contactNumber: true,
        employeeCode: true,
        email: true
      },
      orderBy: { name: 'asc' }
    });

    res.json({ success: true, salesmen });
  } catch (error) {
    console.error('Get salesmen error:', error);
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
      businessTypes
    } = req.body;

    // Validation
    if (!salesmanId || !pincode || !areas || areas.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'salesmanId, pincode, and areas are required'
      });
    }

    // Check if salesman exists
    const salesman = await prisma.user.findUnique({
      where: { id: salesmanId }
    });

    if (!salesman) {
      return res.status(404).json({
        success: false,
        message: 'Salesman not found'
      });
    }

    // Create task assignment
    const assignment = await prisma.taskAssignment.create({
      data: {
        salesmanId,
        salesmanName: salesmanName || salesman.name,
        pincode,
        country,
        state,
        district,
        city,
        areas,
        businessTypes: businessTypes || []
      }
    });

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
 * Delete assignment
 */
export const deleteAssignment = async (req, res) => {
  try {
    const { assignmentId } = req.params;

    await prisma.taskAssignment.delete({
      where: { id: assignmentId }
    });

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

    for (const shop of shops) {
      // Check if shop already exists by placeId
      let existingShop = null;
      if (shop.placeId) {
        existingShop = await prisma.shop.findUnique({
          where: { placeId: shop.placeId }
        });
      }

      if (existingShop) {
        // Update existing shop
        const updated = await prisma.shop.update({
          where: { id: existingShop.id },
          data: {
            assignedTo: salesmanId || existingShop.assignedTo,
            updatedAt: new Date()
          }
        });
        savedShops.push(updated);
      } else {
        // Create new shop
        const created = await prisma.shop.create({
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
        savedShops.push(created);
      }
    }

    res.status(201).json({
      success: true,
      message: `Saved ${savedShops.length} shops`,
      shops: savedShops
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
