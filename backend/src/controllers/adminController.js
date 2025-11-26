import prisma from '../config/db.js';
import { randomUUID } from 'crypto';
import { cleanPhoneNumber } from '../utils/phoneUtils.js';
import { uploadBase64Image } from '../services/cloudinaryService.js';

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
      country,
      district,
      image,
      notes,
      aadharCard,
      panCard,
      salaryPerMonth
    } = req.body;

    // Validate required fields
    if (!contactNumber) {
      return res.status(400).json({
        success: false,
        message: 'Contact number is required',
      });
    }

    if (!salaryPerMonth || parseFloat(salaryPerMonth) <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Salary per month is required and must be greater than 0',
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

    // Upload image to Cloudinary if provided
    let imageUrl = null;
    if (image && image.startsWith('data:image')) {
      try {
        console.log('📸 Processing image upload...');
        imageUrl = await uploadBase64Image(image, 'users');
        console.log('✅ Image uploaded to Cloudinary:', imageUrl);
      } catch (error) {
        console.error('❌ Image upload failed:', error.message);
        // Continue without image if upload fails
      }
    }

    // Create user
    const userId = randomUUID();
    const user = await prisma.user.create({
      data: {
        id: userId,
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
        country,
        district,
        image: imageUrl || image, // Use Cloudinary URL if uploaded, otherwise use original
        notes,
        aadharCard,
        panCard,
      },
      include: {
        role: { select: { name: true } },
        department: { select: { name: true } },
      },
    });

    // Create salary information (now mandatory)
    const salaryInfo = await prisma.salaryInformation.create({
      data: {
        employeeId: userId,
        basicSalary: parseFloat(salaryPerMonth),
        effectiveFrom: new Date(),
        currency: 'INR',
        paymentFrequency: 'Monthly',
        isActive: true,
      },
    });

    // Calculate salary totals
    const grossSalary = salaryInfo.basicSalary;
    const totalDeductions = 0;
    const netSalary = grossSalary - totalDeductions;

    res.json({
      success: true,
      message: 'User and salary information created successfully',
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
        departmentId: user.departmentId,
        gender: user.gender,
        isActive: user.isActive,
        address: user.address,
        city: user.city,
        state: user.state,
        pincode: user.pincode,
        aadharCard: user.aadharCard,
        panCard: user.panCard,
        createdAt: user.createdAt,
      },
      salary: {
        id: salaryInfo.id,
        employeeId: salaryInfo.employeeId,
        basicSalary: salaryInfo.basicSalary,
        hra: salaryInfo.hra || 0,
        travelAllowance: salaryInfo.travelAllowance || 0,
        dailyAllowance: salaryInfo.dailyAllowance || 0,
        medicalAllowance: salaryInfo.medicalAllowance || 0,
        specialAllowance: salaryInfo.specialAllowance || 0,
        otherAllowances: salaryInfo.otherAllowances || 0,
        providentFund: salaryInfo.providentFund || 0,
        professionalTax: salaryInfo.professionalTax || 0,
        incomeTax: salaryInfo.incomeTax || 0,
        otherDeductions: salaryInfo.otherDeductions || 0,
        grossSalary,
        totalDeductions,
        netSalary,
        effectiveFrom: salaryInfo.effectiveFrom,
        effectiveTo: salaryInfo.effectiveTo,
        currency: salaryInfo.currency,
        paymentFrequency: salaryInfo.paymentFrequency,
        isActive: salaryInfo.isActive,
        createdAt: salaryInfo.createdAt,
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
        salaryInformation: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({
      success: true,
      users: users.map((u) => {
        // Calculate salary totals if salary exists
        let salaryDetails = null;
        if (u.salaryInformation) {
          const grossSalary = u.salaryInformation.basicSalary + 
                             (u.salaryInformation.hra || 0) + 
                             (u.salaryInformation.travelAllowance || 0) + 
                             (u.salaryInformation.dailyAllowance || 0) + 
                             (u.salaryInformation.medicalAllowance || 0) + 
                             (u.salaryInformation.specialAllowance || 0) + 
                             (u.salaryInformation.otherAllowances || 0);

          const totalDeductions = (u.salaryInformation.providentFund || 0) + 
                                 (u.salaryInformation.professionalTax || 0) + 
                                 (u.salaryInformation.incomeTax || 0) + 
                                 (u.salaryInformation.otherDeductions || 0);

          const netSalary = grossSalary - totalDeductions;

          salaryDetails = {
            id: u.salaryInformation.id,
            basicSalary: u.salaryInformation.basicSalary,
            hra: u.salaryInformation.hra || 0,
            travelAllowance: u.salaryInformation.travelAllowance || 0,
            dailyAllowance: u.salaryInformation.dailyAllowance || 0,
            medicalAllowance: u.salaryInformation.medicalAllowance || 0,
            specialAllowance: u.salaryInformation.specialAllowance || 0,
            otherAllowances: u.salaryInformation.otherAllowances || 0,
            providentFund: u.salaryInformation.providentFund || 0,
            professionalTax: u.salaryInformation.professionalTax || 0,
            incomeTax: u.salaryInformation.incomeTax || 0,
            otherDeductions: u.salaryInformation.otherDeductions || 0,
            grossSalary,
            totalDeductions,
            netSalary,
            effectiveFrom: u.salaryInformation.effectiveFrom,
            currency: u.salaryInformation.currency,
            paymentFrequency: u.salaryInformation.paymentFrequency,
            isActive: u.salaryInformation.isActive,
          };
        }

        return {
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
          country: u.country,
          district: u.district,
          image: u.image,
          notes: u.notes,
          aadharCard: u.aadharCard,
          panCard: u.panCard,
          createdAt: u.createdAt,
          salaryDetails: salaryDetails,
          salary: salaryDetails, // Keep both for backward compatibility
        };
      }),
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
      country,
      district,
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

    // Upload image to Cloudinary if provided
    let imageUrl = image;
    if (image && image.startsWith('data:image')) {
      try {
        console.log('📸 Processing image upload for update...');
        imageUrl = await uploadBase64Image(image, 'users');
        console.log('✅ Image uploaded to Cloudinary:', imageUrl);
      } catch (error) {
        console.error('❌ Image upload failed:', error.message);
        // Use original image if upload fails
      }
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
        ...(country !== undefined && { country }),
        ...(district !== undefined && { district }),
        ...(imageUrl !== undefined && { image: imageUrl }),
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
