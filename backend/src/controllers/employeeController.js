import { PrismaClient } from '@prisma/client';
import { randomUUID } from 'crypto';

const prisma = new PrismaClient();

// Create Employee
export const createEmployee = async (req, res) => {
  try {
    const {
      employeeCode,
      name,
      email,
      contactNumber,
      designation,
      dateOfBirth,
      gender,
      nationality,
      image,
      departmentId,
      postUnder,
      jobPost,
      joiningDate,
      preferredLanguages,
      jobPostCode,
      jobPostName,
      inchargeCode,
      inchargeName,
      isActive
    } = req.body;

    // Validation
    if (!name || !contactNumber || !email) {
      return res.status(400).json({
        success: false,
        message: 'Name, contact number, and email are required'
      });
    }

    const employee = await prisma.user.create({
      data: {
        id: randomUUID(),
        employeeCode,
        name,
        email,
        contactNumber,
        designation,
        dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : null,
        gender,
        nationality,
        image,
        departmentId,
        postUnder,
        jobPost,
        joiningDate: joiningDate ? new Date(joiningDate) : null,
        preferredLanguages: preferredLanguages || [],
        jobPostCode,
        jobPostName,
        isActive: isActive ?? true
      },
      include: {
        department: true,
        functionalRole: true
      }
    });

    res.status(201).json({ success: true, data: employee });
  } catch (error) {
    console.error('Create Employee Error:', error);
    if (error.code === 'P2002') {
      return res.status(400).json({
        success: false,
        message: 'Employee with this email or contact number already exists'
      });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get All Employees
export const getAllEmployees = async (req, res) => {
  try {
    const { 
      departmentId, 
      isActive,
      search,
      page = 1,
      limit = 50
    } = req.query;

    const where = {};
    
    if (departmentId) where.departmentId = departmentId;
    if (isActive !== undefined) where.isActive = isActive === 'true';
    
    if (search) {
      where.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { employeeCode: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
        { contactNumber: { contains: search } }
      ];
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);

    const [employees, total] = await Promise.all([
      prisma.user.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: {
          department: true,
          functionalRole: true,
          manager: {
            select: {
              id: true,
              name: true,
              employeeCode: true
            }
          }
        }
      }),
      prisma.user.count({ where })
    ]);

    res.json({
      success: true,
      data: employees,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get Employees Error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get Employee by ID
export const getEmployeeById = async (req, res) => {
  try {
    const { id } = req.params;

    const employee = await prisma.user.findUnique({
      where: { id },
      include: {
        department: true,
        functionalRole: true,
        manager: {
          select: {
            id: true,
            name: true,
            employeeCode: true
          }
        },
        subordinates: {
          select: {
            id: true,
            name: true,
            employeeCode: true
          }
        }
      }
    });

    if (!employee) {
      return res.status(404).json({ success: false, message: 'Employee not found' });
    }

    res.json({ success: true, data: employee });
  } catch (error) {
    console.error('Get Employee Error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// Update Employee
export const updateEmployee = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = { ...req.body };

    // Convert date strings to Date objects
    if (updateData.dateOfBirth) {
      updateData.dateOfBirth = new Date(updateData.dateOfBirth);
    }
    if (updateData.joiningDate) {
      updateData.joiningDate = new Date(updateData.joiningDate);
    }

    const employee = await prisma.user.update({
      where: { id },
      data: updateData,
      include: {
        department: true,
        functionalRole: true
      }
    });

    res.json({ success: true, data: employee });
  } catch (error) {
    console.error('Update Employee Error:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'Employee not found' });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

// Delete Employee
export const deleteEmployee = async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.user.delete({
      where: { id }
    });

    res.json({ success: true, message: 'Employee deleted successfully' });
  } catch (error) {
    console.error('Delete Employee Error:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'Employee not found' });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};
