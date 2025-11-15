import prisma from '../config/db.js';
import { randomUUID } from 'crypto';
import { cleanPhoneNumber } from '../utils/phoneUtils.js';

// Admin creates a user with contact number and role
export const createUserByAdmin = async (req, res) => {
  try {
    let { contactNumber, roleId } = req.body;

    if (!contactNumber || !roleId) {
      return res.status(400).json({
        success: false,
        message: 'Contact number and role are required',
      });
    }

    // Clean phone number
    contactNumber = cleanPhoneNumber(contactNumber);

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { contactNumber },
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User with this contact number already exists',
      });
    }

    // Create user
    const user = await prisma.user.create({
      data: {
        id: randomUUID(),
        contactNumber,
        roleId,
        isActive: true,
      },
      include: {
        role: { select: { name: true } },
      },
    });

    res.json({
      success: true,
      message: 'User created successfully',
      user: {
        id: user.id,
        contactNumber: user.contactNumber,
        role: user.role?.name,
      },
    });
  } catch (error) {
    console.error('❌ Create User Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create user',
    });
  }
};

// Get all users (for admin view)
export const getAllUsersByAdmin = async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      include: {
        role: { select: { name: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({
      success: true,
      users: users.map((u) => ({
        id: u.id,
        name: u.name,
        email: u.email,
        contactNumber: u.contactNumber,
        role: u.role?.name,
        roleId: u.roleId,
        isActive: u.isActive,
        createdAt: u.createdAt,
      })),
    });
  } catch (error) {
    console.error('❌ Get Users Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch users',
    });
  }
};

// Update user
export const updateUserByAdmin = async (req, res) => {
  try {
    const { id } = req.params;
    let { contactNumber, roleId, name, email } = req.body;

    if (contactNumber) {
      contactNumber = cleanPhoneNumber(contactNumber);
    }

    const user = await prisma.user.update({
      where: { id },
      data: {
        ...(contactNumber && { contactNumber }),
        ...(roleId && { roleId }),
        ...(name && { name }),
        ...(email && { email }),
      },
      include: {
        role: { select: { name: true } },
      },
    });

    res.json({
      success: true,
      message: 'User updated successfully',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        contactNumber: user.contactNumber,
        role: user.role?.name,
        roleId: user.roleId,
      },
    });
  } catch (error) {
    console.error('❌ Update User Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update user',
    });
  }
};

// Delete user
export const deleteUserByAdmin = async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.user.delete({
      where: { id },
    });

    res.json({
      success: true,
      message: 'User deleted successfully',
    });
  } catch (error) {
    console.error('❌ Delete User Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete user',
    });
  }
};
