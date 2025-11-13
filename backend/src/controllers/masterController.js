import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Get all departments
export const getAllDepartments = async (req, res) => {
  try {
    const departments = await prisma.department.findMany({
      orderBy: { name: 'asc' }
    });
    res.json({ success: true, data: departments });
  } catch (error) {
    console.error('Get Departments Error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get all functional roles
export const getAllFunctionalRoles = async (req, res) => {
  try {
    const { departmentId } = req.query;
    
    const where = departmentId ? { departmentId } : {};
    
    const roles = await prisma.functionalRole.findMany({
      where,
      include: {
        department: true
      },
      orderBy: { name: 'asc' }
    });
    res.json({ success: true, data: roles });
  } catch (error) {
    console.error('Get Functional Roles Error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get all roles
export const getAllRoles = async (req, res) => {
  try {
    const roles = await prisma.role.findMany({
      orderBy: { level: 'asc' }
    });
    res.json({ success: true, data: roles });
  } catch (error) {
    console.error('Get Roles Error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};
