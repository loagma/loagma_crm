import prisma from '../config/db.js';

// Get all roles
export const getAllRoles = async (req, res) => {
  try {
    const roles = await prisma.role.findMany({
      orderBy: { createdAt: 'desc' },
    });

    res.json({
      success: true,
      roles,
    });
  } catch (error) {
    console.error('❌ Get Roles Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch roles',
    });
  }
};

// Create a new role
export const createRole = async (req, res) => {
  try {
    const { id, name } = req.body;

    if (!id || !name) {
      return res.status(400).json({
        success: false,
        message: 'Role ID and name are required',
      });
    }

    const role = await prisma.role.create({
      data: { id, name },
    });

    res.json({
      success: true,
      message: 'Role created successfully',
      role,
    });
  } catch (error) {
    console.error('❌ Create Role Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create role',
    });
  }
};

// Update a role
export const updateRole = async (req, res) => {
  try {
    const { id } = req.params;
    const { name } = req.body;

    if (!name) {
      return res.status(400).json({
        success: false,
        message: 'Role name is required',
      });
    }

    const role = await prisma.role.update({
      where: { id },
      data: { name },
    });

    res.json({
      success: true,
      message: 'Role updated successfully',
      role,
    });
  } catch (error) {
    console.error('❌ Update Role Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update role',
    });
  }
};

// Delete a role
export const deleteRole = async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.role.delete({
      where: { id },
    });

    res.json({
      success: true,
      message: 'Role deleted successfully',
    });
  } catch (error) {
    console.error('❌ Delete Role Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete role',
    });
  }
};
