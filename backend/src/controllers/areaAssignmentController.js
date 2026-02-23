import prisma from '../config/db.js';


// Get all area assignments
const getAllAreaAssignments = async (req, res) => {
  try {
    const assignments = await prisma.areaAssignment.findMany({
      include: {
        salesman: {
          select: {
            id: true,
            name: true,
            email: true,
            contactNumber: true,
          },
        },
      },
      orderBy: {
        assignedDate: 'desc',
      },
    });

    res.json({
      success: true,
      assignments: assignments.map(assignment => ({
        id: assignment.id,
        salesmanId: assignment.salesmanId,
        salesmanName: assignment.salesman?.name || 'Unknown',
        pinCode: assignment.pinCode,
        country: assignment.country,
        state: assignment.state,
        district: assignment.district,
        city: assignment.city,
        areas: assignment.areas || [],
        businessTypes: assignment.businessTypes || [],
        assignedDate: assignment.assignedDate,
        totalBusinesses: assignment.totalBusinesses || 0,
      })),
    });
  } catch (error) {
    console.error('Error fetching area assignments:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch area assignments',
      error: error.message,
    });
  }
};

// Get area assignments for a specific salesman
const getSalesmanAreaAssignments = async (req, res) => {
  try {
    const { salesmanId } = req.params;

    console.log('🔍 Searching for area assignments with salesmanId:', salesmanId);
    console.log('🔍 salesmanId type:', typeof salesmanId);

    // First, let's check all area assignments to see what's in the database
    const allAssignments = await prisma.areaAssignment.findMany({
      select: {
        id: true,
        salesmanId: true,
        city: true,
        district: true,
      },
    });
    console.log('📊 All area assignments in database:', allAssignments);

    // Check if user exists
    const userExists = await prisma.user.findUnique({
      where: { id: salesmanId },
      select: { id: true, name: true }
    });
    console.log('👤 User exists check:', userExists);

    // Try different query approaches
    console.log('🔍 Trying exact match query...');
    const assignments = await prisma.areaAssignment.findMany({
      where: {
        salesmanId: salesmanId,
      },
      include: {
        salesman: {
          select: {
            id: true,
            name: true,
            email: true,
            contactNumber: true,
          },
        },
      },
      orderBy: {
        assignedDate: 'desc',
      },
    });

    console.log('📊 Found assignments:', assignments.length);
    console.log('📊 Assignment details:', assignments.map(a => ({
      id: a.id,
      salesmanId: a.salesmanId,
      salesmanIdType: typeof a.salesmanId,
      city: a.city
    })));

    res.json({
      success: true,
      assignments: assignments.map(assignment => ({
        id: assignment.id,
        salesmanId: assignment.salesmanId,
        salesmanName: assignment.salesman?.name || 'Unknown',
        pinCode: assignment.pinCode,
        country: assignment.country,
        state: assignment.state,
        district: assignment.district,
        city: assignment.city,
        areas: assignment.areas || [],
        businessTypes: assignment.businessTypes || [],
        assignedDate: assignment.assignedDate,
        totalBusinesses: assignment.totalBusinesses || 0,
      })),
    });
  } catch (error) {
    console.error('Error fetching salesman area assignments:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch salesman area assignments',
      error: error.message,
    });
  }
};

// Create new area assignment
const createAreaAssignment = async (req, res) => {
  try {
    console.log('🆕 Creating new area assignment...');
    console.log('📥 Request body:', JSON.stringify(req.body, null, 2));
    console.log('👤 Authenticated user:', req.user);

    const {
      salesmanId,
      pinCode,
      country,
      state,
      district,
      city,
      areas,
      businessTypes,
      totalBusinesses,
    } = req.body;

    console.log('🔍 Extracted fields:');
    console.log('  salesmanId:', salesmanId);
    console.log('  pinCode:', pinCode);
    console.log('  country:', country);
    console.log('  state:', state);
    console.log('  district:', district);
    console.log('  city:', city);
    console.log('  areas:', areas);
    console.log('  businessTypes:', businessTypes);
    console.log('  totalBusinesses:', totalBusinesses);

    // Validate required fields
    if (!salesmanId || !pinCode || !country || !state || !district || !city) {
      console.log('❌ Validation failed - missing required fields');
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: salesmanId, pinCode, country, state, district, city',
      });
    }

    // Check if salesman exists
    console.log('🔍 Checking if salesman exists...');
    const salesman = await prisma.user.findUnique({
      where: { id: salesmanId },
    });

    if (!salesman) {
      console.log('❌ Salesman not found:', salesmanId);
      return res.status(404).json({
        success: false,
        message: 'Salesman not found',
      });
    }

    console.log('✅ Salesman found:', salesman.name);

    console.log('💾 Creating area assignment in database...');
    const assignment = await prisma.areaAssignment.create({
      data: {
        salesmanId,
        pinCode,
        country,
        state,
        district,
        city,
        areas: areas || [],
        businessTypes: businessTypes || [],
        totalBusinesses: totalBusinesses || 0,
        assignedDate: new Date(),
      },
      include: {
        salesman: {
          select: {
            id: true,
            name: true,
            email: true,
            contactNumber: true,
          },
        },
      },
    });

    console.log('✅ Area assignment created successfully:', assignment.id);

    const responseData = {
      success: true,
      message: 'Area assignment created successfully',
      assignment: {
        id: assignment.id,
        salesmanId: assignment.salesmanId,
        salesmanName: assignment.salesman?.name || 'Unknown',
        pinCode: assignment.pinCode,
        country: assignment.country,
        state: assignment.state,
        district: assignment.district,
        city: assignment.city,
        areas: assignment.areas || [],
        businessTypes: assignment.businessTypes || [],
        assignedDate: assignment.assignedDate,
        totalBusinesses: assignment.totalBusinesses || 0,
      },
    };

    console.log('📤 Sending response:', JSON.stringify(responseData, null, 2));
    res.status(201).json(responseData);
  } catch (error) {
    console.error('❌ Error creating area assignment:', error);
    console.error('❌ Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Failed to create area assignment',
      error: error.message,
    });
  }
};

// Get area assignment by ID
const getAreaAssignmentById = async (req, res) => {
  try {
    const { id } = req.params;

    const assignment = await prisma.areaAssignment.findUnique({
      where: { id },
      include: {
        salesman: {
          select: {
            id: true,
            name: true,
            email: true,
            contactNumber: true,
          },
        },
      },
    });

    if (!assignment) {
      return res.status(404).json({
        success: false,
        message: 'Area assignment not found',
      });
    }

    res.json({
      success: true,
      assignment: {
        id: assignment.id,
        salesmanId: assignment.salesmanId,
        salesmanName: assignment.salesman?.name || 'Unknown',
        pinCode: assignment.pinCode,
        country: assignment.country,
        state: assignment.state,
        district: assignment.district,
        city: assignment.city,
        areas: assignment.areas || [],
        businessTypes: assignment.businessTypes || [],
        assignedDate: assignment.assignedDate,
        totalBusinesses: assignment.totalBusinesses || 0,
      },
    });
  } catch (error) {
    console.error('Error fetching area assignment:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch area assignment',
      error: error.message,
    });
  }
};

// Update area assignment
const updateAreaAssignment = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      salesmanId,
      pinCode,
      country,
      state,
      district,
      city,
      areas,
      businessTypes,
      totalBusinesses,
    } = req.body;

    // Check if assignment exists
    const existingAssignment = await prisma.areaAssignment.findUnique({
      where: { id },
    });

    if (!existingAssignment) {
      return res.status(404).json({
        success: false,
        message: 'Area assignment not found',
      });
    }

    const assignment = await prisma.areaAssignment.update({
      where: { id },
      data: {
        ...(salesmanId && { salesmanId }),
        ...(pinCode && { pinCode }),
        ...(country && { country }),
        ...(state && { state }),
        ...(district && { district }),
        ...(city && { city }),
        ...(areas && { areas }),
        ...(businessTypes && { businessTypes }),
        ...(totalBusinesses !== undefined && { totalBusinesses }),
      },
      include: {
        salesman: {
          select: {
            id: true,
            name: true,
            email: true,
            contactNumber: true,
          },
        },
      },
    });

    res.json({
      success: true,
      message: 'Area assignment updated successfully',
      assignment: {
        id: assignment.id,
        salesmanId: assignment.salesmanId,
        salesmanName: assignment.salesman?.name || 'Unknown',
        pinCode: assignment.pinCode,
        country: assignment.country,
        state: assignment.state,
        district: assignment.district,
        city: assignment.city,
        areas: assignment.areas || [],
        businessTypes: assignment.businessTypes || [],
        assignedDate: assignment.assignedDate,
        totalBusinesses: assignment.totalBusinesses || 0,
      },
    });
  } catch (error) {
    console.error('Error updating area assignment:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update area assignment',
      error: error.message,
    });
  }
};

// Delete area assignment
const deleteAreaAssignment = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if assignment exists
    const existingAssignment = await prisma.areaAssignment.findUnique({
      where: { id },
    });

    if (!existingAssignment) {
      return res.status(404).json({
        success: false,
        message: 'Area assignment not found',
      });
    }

    await prisma.areaAssignment.delete({
      where: { id },
    });

    res.json({
      success: true,
      message: 'Area assignment deleted successfully',
    });
  } catch (error) {
    console.error('Error deleting area assignment:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete area assignment',
      error: error.message,
    });
  }
};

// Search area assignments by location
const searchAreaAssignments = async (req, res) => {
  try {
    const { pinCode, city, district, state } = req.query;

    const whereClause = {};
    if (pinCode) whereClause.pinCode = { contains: pinCode, mode: 'insensitive' };
    if (city) whereClause.city = { contains: city, mode: 'insensitive' };
    if (district) whereClause.district = { contains: district, mode: 'insensitive' };
    if (state) whereClause.state = { contains: state, mode: 'insensitive' };

    const assignments = await prisma.areaAssignment.findMany({
      where: whereClause,
      include: {
        salesman: {
          select: {
            id: true,
            name: true,
            email: true,
            contactNumber: true,
          },
        },
      },
      orderBy: {
        assignedDate: 'desc',
      },
    });

    res.json({
      success: true,
      assignments: assignments.map(assignment => ({
        id: assignment.id,
        salesmanId: assignment.salesmanId,
        salesmanName: assignment.salesman?.name || 'Unknown',
        pinCode: assignment.pinCode,
        country: assignment.country,
        state: assignment.state,
        district: assignment.district,
        city: assignment.city,
        areas: assignment.areas || [],
        businessTypes: assignment.businessTypes || [],
        assignedDate: assignment.assignedDate,
        totalBusinesses: assignment.totalBusinesses || 0,
      })),
    });
  } catch (error) {
    console.error('Error searching area assignments:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to search area assignments',
      error: error.message,
    });
  }
};

export {
  getAllAreaAssignments,
  getSalesmanAreaAssignments,
  getAreaAssignmentById,
  createAreaAssignment,
  updateAreaAssignment,
  deleteAreaAssignment,
  searchAreaAssignments,
};