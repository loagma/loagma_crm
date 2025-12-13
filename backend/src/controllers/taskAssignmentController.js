import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

// Get all task assignments
const getAllTaskAssignments = async (req, res) => {
  try {
    const assignments = await prisma.taskAssignment.findMany({
      orderBy: {
        assignedDate: 'desc',
      },
    });

    res.json({
      success: true,
      assignments: assignments.map(assignment => ({
        id: assignment.id,
        salesmanId: assignment.salesmanId,
        salesmanName: assignment.salesmanName,
        pincode: assignment.pincode,
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
    console.error('Error fetching task assignments:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch task assignments',
      error: error.message,
    });
  }
};

// Get task assignments for a specific salesman
const getSalesmanTaskAssignments = async (req, res) => {
  try {
    const { salesmanId } = req.params;

    const assignments = await prisma.taskAssignment.findMany({
      where: {
        salesmanId: salesmanId,
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
        salesmanName: assignment.salesmanName,
        pincode: assignment.pincode,
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
    console.error('Error fetching salesman task assignments:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch salesman task assignments',
      error: error.message,
    });
  }
};

// Get task assignments for current authenticated user
const getMyTaskAssignments = async (req, res) => {
  try {
    const salesmanId = req.user.id; // Get from authenticated token

    console.log('🔍 Loading task assignments for user:', salesmanId);

    const assignments = await prisma.taskAssignment.findMany({
      where: {
        salesmanId: salesmanId,
      },
      orderBy: {
        assignedDate: 'desc',
      },
    });

    console.log('📊 Found task assignments:', assignments.length);

    res.json({
      success: true,
      assignments: assignments.map(assignment => ({
        id: assignment.id,
        salesmanId: assignment.salesmanId,
        salesmanName: assignment.salesmanName,
        pincode: assignment.pincode,
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
    console.error('Error fetching my task assignments:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch task assignments',
      error: error.message,
    });
  }
};

// Create new task assignment
const createTaskAssignment = async (req, res) => {
  try {
    console.log('🆕 Creating new task assignment...');
    console.log('📥 Request body:', JSON.stringify(req.body, null, 2));

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
      totalBusinesses,
    } = req.body;

    console.log('🔍 Extracted fields:');
    console.log('  salesmanId:', salesmanId);
    console.log('  salesmanName:', salesmanName);
    console.log('  pincode:', pincode);
    console.log('  country:', country);
    console.log('  state:', state);
    console.log('  district:', district);
    console.log('  city:', city);
    console.log('  areas:', areas);
    console.log('  businessTypes:', businessTypes);
    console.log('  totalBusinesses:', totalBusinesses);

    // Validate required fields
    if (!salesmanId || !salesmanName || !pincode || !country || !state || !district || !city) {
      console.log('❌ Validation failed - missing required fields');
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: salesmanId, salesmanName, pincode, country, state, district, city',
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

    console.log('💾 Creating task assignment in database...');
    const assignment = await prisma.taskAssignment.create({
      data: {
        salesmanId,
        salesmanName,
        pincode,
        country,
        state,
        district,
        city,
        areas: areas || [],
        businessTypes: businessTypes || [],
        totalBusinesses: totalBusinesses || 0,
        assignedDate: new Date(),
      },
    });

    console.log('✅ Task assignment created successfully:', assignment.id);

    const responseData = {
      success: true,
      message: 'Task assignment created successfully',
      assignment: {
        id: assignment.id,
        salesmanId: assignment.salesmanId,
        salesmanName: assignment.salesmanName,
        pincode: assignment.pincode,
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
    console.error('❌ Error creating task assignment:', error);
    console.error('❌ Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Failed to create task assignment',
      error: error.message,
    });
  }
};

// Get task assignment by ID
const getTaskAssignmentById = async (req, res) => {
  try {
    const { id } = req.params;

    const assignment = await prisma.taskAssignment.findUnique({
      where: { id },
    });

    if (!assignment) {
      return res.status(404).json({
        success: false,
        message: 'Task assignment not found',
      });
    }

    res.json({
      success: true,
      assignment: {
        id: assignment.id,
        salesmanId: assignment.salesmanId,
        salesmanName: assignment.salesmanName,
        pincode: assignment.pincode,
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
    console.error('Error fetching task assignment:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch task assignment',
      error: error.message,
    });
  }
};

// Update task assignment
const updateTaskAssignment = async (req, res) => {
  try {
    const { id } = req.params;
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
      totalBusinesses,
    } = req.body;

    // Check if assignment exists
    const existingAssignment = await prisma.taskAssignment.findUnique({
      where: { id },
    });

    if (!existingAssignment) {
      return res.status(404).json({
        success: false,
        message: 'Task assignment not found',
      });
    }

    const assignment = await prisma.taskAssignment.update({
      where: { id },
      data: {
        ...(salesmanId && { salesmanId }),
        ...(salesmanName && { salesmanName }),
        ...(pincode && { pincode }),
        ...(country && { country }),
        ...(state && { state }),
        ...(district && { district }),
        ...(city && { city }),
        ...(areas && { areas }),
        ...(businessTypes && { businessTypes }),
        ...(totalBusinesses !== undefined && { totalBusinesses }),
      },
    });

    res.json({
      success: true,
      message: 'Task assignment updated successfully',
      assignment: {
        id: assignment.id,
        salesmanId: assignment.salesmanId,
        salesmanName: assignment.salesmanName,
        pincode: assignment.pincode,
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
    console.error('Error updating task assignment:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update task assignment',
      error: error.message,
    });
  }
};

// Delete task assignment
const deleteTaskAssignment = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if assignment exists
    const existingAssignment = await prisma.taskAssignment.findUnique({
      where: { id },
    });

    if (!existingAssignment) {
      return res.status(404).json({
        success: false,
        message: 'Task assignment not found',
      });
    }

    await prisma.taskAssignment.delete({
      where: { id },
    });

    res.json({
      success: true,
      message: 'Task assignment deleted successfully',
    });
  } catch (error) {
    console.error('Error deleting task assignment:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete task assignment',
      error: error.message,
    });
  }
};

// Search task assignments by location
const searchTaskAssignments = async (req, res) => {
  try {
    const { pincode, city, district, state } = req.query;

    const whereClause = {};
    if (pincode) whereClause.pincode = { contains: pincode, mode: 'insensitive' };
    if (city) whereClause.city = { contains: city, mode: 'insensitive' };
    if (district) whereClause.district = { contains: district, mode: 'insensitive' };
    if (state) whereClause.state = { contains: state, mode: 'insensitive' };

    const assignments = await prisma.taskAssignment.findMany({
      where: whereClause,
      orderBy: {
        assignedDate: 'desc',
      },
    });

    res.json({
      success: true,
      assignments: assignments.map(assignment => ({
        id: assignment.id,
        salesmanId: assignment.salesmanId,
        salesmanName: assignment.salesmanName,
        pincode: assignment.pincode,
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
    console.error('Error searching task assignments:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to search task assignments',
      error: error.message,
    });
  }
};

export {
  getAllTaskAssignments,
  getSalesmanTaskAssignments,
  getMyTaskAssignments,
  getTaskAssignmentById,
  createTaskAssignment,
  updateTaskAssignment,
  deleteTaskAssignment,
  searchTaskAssignments,
};