import prisma from '../config/db.js';
import { cleanPhoneNumber } from '../utils/phoneUtils.js';
import { uploadBase64Image } from '../services/cloudinaryService.js';
import { generateUserIdentifiers } from '../utils/idGenerator.js';
import { cascadeDeleteUser } from '../utils/userCascadeDelete.js';


async function createUserWithSalaryFromPayload(payload) {
  let {
    contactNumber,
    roleId,
    roles,
    name,
    email,
    alternativeNumber,
    gender,
    dateOfBirth,
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
    area,
    latitude,
    longitude,
    image,
    notes,
    aadharCard,
    panCard,
    salaryPerMonth,
  } = payload || {};

  const throwValidation = (message) => {
    const err = new Error(message);
    err.statusCode = 400;
    err.userMessage = message;
    return err;
  };

  // Validate required fields
  if (!contactNumber) {
    throw throwValidation('Contact number is required');
  }

  if (!salaryPerMonth || parseFloat(salaryPerMonth) <= 0) {
    throw throwValidation(
      'Salary per month is required and must be greater than 0',
    );
  }

  // Clean phone numbers
  contactNumber = cleanPhoneNumber(contactNumber);
  if (alternativeNumber) {
    alternativeNumber = cleanPhoneNumber(alternativeNumber);
  }

  // Check if user already exists by contact
  const existingUser = await prisma.user.findUnique({
    where: { contactNumber },
  });

  if (existingUser) {
    throw throwValidation('User with this contact number already exists');
  }

  // Check if email exists
  if (email) {
    const existingEmail = await prisma.user.findUnique({
      where: { email },
    });

    if (existingEmail) {
      throw throwValidation('User with this email already exists');
    }
  }

  // Upload image to Cloudinary if provided
  let imageUrl = null;
  if (image && image.startsWith('data:image')) {
    try {
      console.log('📸 Processing image upload...');
      console.log('📦 Image size:', image.length, 'characters');
      imageUrl = await uploadBase64Image(image, 'users');
      console.log('✅ Image uploaded to Cloudinary:', imageUrl);
    } catch (error) {
      console.error('❌ Image upload failed:', error.message);
      console.error('❌ Full error:', error);
      // Don't save base64 to database if upload fails
      imageUrl = null;
    }
  } else if (
    image &&
    !image.startsWith('data:image') &&
    !image.startsWith('http')
  ) {
    // If image is provided but not base64 or URL, don't save it
    console.log('⚠️ Invalid image format, skipping');
    imageUrl = null;
  } else if (image && image.startsWith('http')) {
    // If it's already a URL, keep it
    imageUrl = image;
  }

  // Create user with sequential ID and employee code using shared utility
  const { userId, employeeCode } = await generateUserIdentifiers();

  const user = await prisma.user.create({
    data: {
      id: userId,
      employeeCode,
      contactNumber,
      alternativeNumber,
      name,
      email,
      roleId,
      roles: roles || [],
      gender,
      dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : null,
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
      area,
      latitude: latitude ? parseFloat(latitude) : null,
      longitude: longitude ? parseFloat(longitude) : null,
      image: imageUrl, // Only save Cloudinary URL or existing URL
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

  return { user, salaryInfo };
}


// Admin creates a user with contact number and role
export const createUserByAdmin = async (req, res) => {
  try {
    const { user, salaryInfo } = await createUserWithSalaryFromPayload(
      req.body,
    );

    // Calculate salary totals
    const grossSalary = salaryInfo.basicSalary;
    const totalDeductions = 0;
    const netSalary = grossSalary - totalDeductions;

    res.json({
      success: true,
      message: 'User and salary information created successfully',
      user: {
        id: user.id,
        employeeCode: user.employeeCode,
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
        dateOfBirth: user.dateOfBirth,
        isActive: user.isActive,
        address: user.address,
        city: user.city,
        state: user.state,
        pincode: user.pincode,
        country: user.country,
        district: user.district,
        area: user.area,
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
    if (error.statusCode === 400) {
      return res.status(400).json({
        success: false,
        message: error.userMessage || error.message,
      });
    }
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
          employeeCode: u.employeeCode,
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
          dateOfBirth: u.dateOfBirth,
          preferredLanguages: u.preferredLanguages,
          isActive: u.isActive,
          address: u.address,
          city: u.city,
          state: u.state,
          pincode: u.pincode,
          country: u.country,
          district: u.district,
          area: u.area,
          latitude: u.latitude,
          longitude: u.longitude,
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

// Bulk create users (admin)
export const bulkCreateUsersByAdmin = async (req, res) => {
  try {
    const { users } = req.body || {};
    if (!Array.isArray(users) || users.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Body must include a non-empty \"users\" array',
      });
    }

    const results = [];
    let created = 0;

    for (let i = 0; i < users.length; i += 1) {
      const payload = users[i] || {};
      const contactNumber = payload.contactNumber;
      const email = payload.email;

      try {
        const { user } = await createUserWithSalaryFromPayload(payload);
        created += 1;
        results.push({
          index: i,
          contactNumber: user.contactNumber,
          email: user.email,
          success: true,
          userId: user.id,
          employeeCode: user.employeeCode,
        });
      } catch (err) {
        const reason =
          err?.userMessage || err?.message || 'Failed to create user';
        results.push({
          index: i,
          contactNumber,
          email,
          success: false,
          reason,
        });
      }
    }

    const failed = results.length - created;

    return res.json({
      success: failed === 0,
      message: 'Bulk user import completed',
      data: {
        created,
        failed,
        results,
      },
    });
  } catch (error) {
    console.error('❌ Bulk Create Users Error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to import users in bulk',
    });
  }
}

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
      dateOfBirth,
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
      area,
      latitude,
      longitude,
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
        console.log('📦 Image size:', image.length, 'characters');
        imageUrl = await uploadBase64Image(image, 'users');
        console.log('✅ Image uploaded to Cloudinary:', imageUrl);
      } catch (error) {
        console.error('❌ Image upload failed:', error.message);
        console.error('❌ Full error:', error);
        // Don't update image if upload fails
        imageUrl = undefined;
      }
    } else if (image && !image.startsWith('data:image') && !image.startsWith('http')) {
      // If image is provided but not base64 or URL, don't save it
      console.log('⚠️ Invalid image format, skipping');
      imageUrl = undefined;
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
        ...(dateOfBirth !== undefined && { dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : null }),
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
        ...(area !== undefined && { area }),
        ...(latitude !== undefined && { latitude: latitude ? parseFloat(latitude) : null }),
        ...(longitude !== undefined && { longitude: longitude ? parseFloat(longitude) : null }),
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
        employeeCode: user.employeeCode,
        name: user.name,
        email: user.email,
        contactNumber: user.contactNumber,
        alternativeNumber: user.alternativeNumber,
        role: user.role?.name,
        roles: user.roles,
        roleId: user.roleId,
        department: user.department?.name,
        gender: user.gender,
        dateOfBirth: user.dateOfBirth,
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

// Delete user with cascade deletion of all related data
export const deleteUserByAdmin = async (req, res) => {
  try {
    const { id } = req.params;

    // First, verify user exists
    const user = await prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        employeeCode: true,
      },
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    console.log(`🗑️ Starting cascade deletion for user: ${user.name} (${user.id})`);

    // Count records before deletion (for logging) - do this outside transaction
    const counts = {
      employeeArea: await prisma.employeeArea.count({ where: { employeeId: id } }),
      salaryInfo: await prisma.salaryInformation.count({ where: { employeeId: id } }),
      expenses: await prisma.expense.count({ where: { employeeId: id } }),
      areaAssignments: await prisma.areaAssignment.count({ where: { salesmanId: id } }),
      notifications: await prisma.notification.count({ where: { targetUserId: id } }),
      lateApprovals: await prisma.latePunchApproval.count({ where: { employeeId: id } }),
      earlyApprovals: await prisma.earlyPunchOutApproval.count({ where: { employeeId: id } }),
      leaves: await prisma.leave.count({ where: { employeeId: id } }),
      leaveBalance: await prisma.leaveBalance.count({ where: { employeeId: id } }),
      beatPlans: await prisma.weeklyBeatPlan.count({ where: { salesmanId: id } }),
      beatCompletions: await prisma.beatCompletion.count({ where: { salesmanId: id } }),
      trackingPoints: await prisma.salesmanTrackingPoint.count({ where: { employeeId: id } }),
    };

    console.log(`   📊 Records to be deleted:`);
    console.log(`      - EmployeeArea: ${counts.employeeArea}`);
    console.log(`      - SalaryInformation: ${counts.salaryInfo}`);
    console.log(`      - Expenses: ${counts.expenses}`);
    console.log(`      - AreaAssignments: ${counts.areaAssignments}`);
    console.log(`      - Notifications: ${counts.notifications}`);
    console.log(`      - LatePunchApprovals: ${counts.lateApprovals}`);
    console.log(`      - EarlyPunchOutApprovals: ${counts.earlyApprovals}`);
    console.log(`      - Leaves: ${counts.leaves}`);
    console.log(`      - LeaveBalance: ${counts.leaveBalance}`);
    console.log(`      - WeeklyBeatPlans: ${counts.beatPlans}`);
    console.log(`      - BeatCompletions: ${counts.beatCompletions}`);
    console.log(`      - TrackingPoints: ${counts.trackingPoints}`);

    // Use transaction to ensure atomic deletion
    // Set timeout to 60 seconds to handle large datasets
    await prisma.$transaction(
      async (tx) => {
      // 1. Handle Account relations (set foreign keys to null instead of deleting accounts)
      const accountsToUpdate = await tx.account.findMany({
        where: {
          OR: [
            { assignedToId: id },
            { createdById: id },
            { approvedById: id },
          ],
        },
        select: { id: true },
      });

      if (accountsToUpdate.length > 0) {
        console.log(`   📋 Updating ${accountsToUpdate.length} accounts (removing user references)`);
        await tx.account.updateMany({
          where: {
            OR: [
              { assignedToId: id },
              { createdById: id },
              { approvedById: id },
            ],
          },
          data: {
            assignedToId: null,
            createdById: null,
            approvedById: null,
          },
        });
      }

      // 2. Handle Expense approver relations (set approvedBy to null)
      const expensesToUpdate = await tx.expense.findMany({
        where: { approvedBy: id },
        select: { id: true },
      });

      if (expensesToUpdate.length > 0) {
        console.log(`   💰 Updating ${expensesToUpdate.length} expenses (removing approver references)`);
        await tx.expense.updateMany({
          where: { approvedBy: id },
          data: { approvedBy: null },
        });
      }

      // 3. Handle LatePunchApproval approver relations
      const lateApprovalsToUpdate = await tx.latePunchApproval.findMany({
        where: { approvedBy: id },
        select: { id: true },
      });

      if (lateApprovalsToUpdate.length > 0) {
        console.log(`   ⏰ Updating ${lateApprovalsToUpdate.length} late punch approvals (removing approver references)`);
        await tx.latePunchApproval.updateMany({
          where: { approvedBy: id },
          data: { approvedBy: null },
        });
      }

      // 4. Handle EarlyPunchOutApproval approver relations
      const earlyApprovalsToUpdate = await tx.earlyPunchOutApproval.findMany({
        where: { approvedBy: id },
        select: { id: true },
      });

      if (earlyApprovalsToUpdate.length > 0) {
        console.log(`   ⏰ Updating ${earlyApprovalsToUpdate.length} early punch-out approvals (removing approver references)`);
        await tx.earlyPunchOutApproval.updateMany({
          where: { approvedBy: id },
          data: { approvedBy: null },
        });
      }

      // 5. Handle Leave approver relations
      const leavesToUpdate = await tx.leave.findMany({
        where: { approvedBy: id },
        select: { id: true },
      });

      if (leavesToUpdate.length > 0) {
        console.log(`   🏖️ Updating ${leavesToUpdate.length} leave requests (removing approver references)`);
        await tx.leave.updateMany({
          where: { approvedBy: id },
          data: { approvedBy: null },
        });
      }

      // 6. Handle WeeklyBeatPlan generator/approver/locker relations
      const beatPlansToUpdate = await tx.weeklyBeatPlan.findMany({
        where: {
          OR: [
            { generatedBy: id },
            { approvedBy: id },
            { lockedBy: id },
          ],
        },
        select: { id: true },
      });

      if (beatPlansToUpdate.length > 0) {
        console.log(`   📅 Updating ${beatPlansToUpdate.length} beat plans (removing admin references)`);
        await tx.weeklyBeatPlan.updateMany({
          where: {
            OR: [
              { generatedBy: id },
              { approvedBy: id },
              { lockedBy: id },
            ],
          },
          data: {
            generatedBy: null,
            approvedBy: null,
            lockedBy: null,
          },
        });
      }

      // 7. Handle BeatCompletion verifier relations
      const beatCompletionsToUpdate = await tx.beatCompletion.findMany({
        where: { verifiedBy: id },
        select: { id: true },
      });

      if (beatCompletionsToUpdate.length > 0) {
        console.log(`   ✅ Updating ${beatCompletionsToUpdate.length} beat completions (removing verifier references)`);
        await tx.beatCompletion.updateMany({
          where: { verifiedBy: id },
          data: { verifiedBy: null },
        });
      }

      // 8. Finally, delete the user (this will cascade delete all records with onDelete: Cascade)
      console.log(`   🗑️ Deleting user record...`);
      await tx.user.delete({
        where: { id },
      });
      },
      {
        timeout: 60000, // 60 seconds timeout
        isolationLevel: 'ReadCommitted', // Use ReadCommitted for better performance
      }
    );

    console.log(`✅ User ${user.name} (${user.id}) and all related data deleted successfully`);

    res.json({
      success: true,
      message: 'User and all related data deleted successfully',
    });
  } catch (error) {
    console.error('❌ Delete User Error:', error);
    
    // Handle specific Prisma errors
    if (error.code === 'P2025') {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Handle foreign key constraint errors
    if (error.code === 'P2003') {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete user: There are still references to this user that need to be handled',
        error: error.meta,
      });
    }

    res.status(500).json({
      success: false,
      message: 'Failed to delete user',
      error: error.message,
    });
  }
};
