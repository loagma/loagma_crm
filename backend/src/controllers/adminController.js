import prisma from '../config/db.js';
import { randomUUID } from 'crypto';
import { cleanPhoneNumber } from '../utils/phoneUtils.js';

// Admin creates a user with contact number and role
export const createUserByAdmin = async (req, res) => {
  try {
    let { 
      contactNumber, 
      roleId, 
      roles,
      name, 
      email, 
      alternativeNumber,
      gender,
      preferredLanguages,
      departmentId,
      isActive,
      password,
      address,
      city,
      state,
      pincode,
      image,
      notes,
      aadharCard,
      panCard
    } = req.body;

    if (!contactNumber) {
      return res.status(400).json({
        success: false,
        message: 'Contact number is required',
      });
    }

    // Clean phone numbers
    contactNumber = cleanPhoneNumber(contactNumber);
    if (alternativeNumber) {
      alternativeNumber = cleanPhoneNumber(alternativeNumber);
    }

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

    // Check if email exists
    if (email) {
      const existingEmail = await prisma.user.findUnique({
        where: { email },
      });

      if (existingEmail) {
        return res.status(400).json({
          success: false,
          message: 'User with this email already exists',
        });
      }
    }

    // Create user
    const user = await prisma.user.create({
      data: {
        id: randomUUID(),
        contactNumber,
        alternativeNumber,
        name,
        email,
        roleId,
        roles: roles || [],
        gender,
        preferredLanguages: preferredLanguages || [],
        departmentId,
        isActive: isActive !== undefined ? isActive : true,
        password,
        address,
        city,
        state,
        pincode,
        image,
        notes,
        aadharCard,
        panCard,
      },
      include: {
        role: { select: { name: true } },
        department: { select: { name: true } },
      },
    });

    res.json({
      success: true,
      message: 'User created successfully',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        contactNumber: user.contactNumber,
        alternativeNumber: user.alternativeNumber,
        role: user.role?.name,
        roles: user.roles,
        department: user.department?.name,
        gender: user.gender,
        isActive: user.isActive,
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
        department: { select: { name: true } },
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
        alternativeNumber: u.alternativeNumber,
        role: u.role?.name,
        roles: u.roles,
        roleId: u.roleId,
        department: u.department?.name,
        departmentId: u.departmentId,
        gender: u.gender,
        preferredLanguages: u.preferredLanguages,
        isActive: u.isActive,
        address: u.address,
        city: u.city,
        state: u.state,
        pincode: u.pincode,
        image: u.image,
        notes: u.notes,
        aadharCard: u.aadharCard,
        panCard: u.panCard,
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
    let { 
      contactNumber, 
      alternativeNumber,
      roleId, 
      roles,
      name, 
      email,
      gender,
      preferredLanguages,
      departmentId,
      isActive,
      password,
      address,
      city,
      state,
      pincode,
      image,
      notes,
      aadharCard,
      panCard
    } = req.body;

    if (contactNumber) {
      contactNumber = cleanPhoneNumber(contactNumber);
    }

    if (alternativeNumber) {
      alternativeNumber = cleanPhoneNumber(alternativeNumber);
    }

    const user = await prisma.user.update({
      where: { id },
      data: {
        ...(contactNumber && { contactNumber }),
        ...(alternativeNumber !== undefined && { alternativeNumber }),
        ...(roleId !== undefined && { roleId }),
        ...(roles !== undefined && { roles }),
        ...(name !== undefined && { name }),
        ...(email !== undefined && { email }),
        ...(gender !== undefined && { gender }),
        ...(preferredLanguages !== undefined && { preferredLanguages }),
        ...(departmentId !== undefined && { departmentId }),
        ...(isActive !== undefined && { isActive }),
        ...(password !== undefined && { password }),
        ...(address !== undefined && { address }),
        ...(city !== undefined && { city }),
        ...(state !== undefined && { state }),
        ...(pincode !== undefined && { pincode }),
        ...(image !== undefined && { image }),
        ...(notes !== undefined && { notes }),
        ...(aadharCard !== undefined && { aadharCard }),
        ...(panCard !== undefined && { panCard }),
      },
      include: {
        role: { select: { name: true } },
        department: { select: { name: true } },
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
        alternativeNumber: user.alternativeNumber,
        role: user.role?.name,
        roles: user.roles,
        roleId: user.roleId,
        department: user.department?.name,
        gender: user.gender,
        isActive: user.isActive,
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
