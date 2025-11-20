import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Create or Update Salary Information
export const createOrUpdateSalary = async (req, res) => {
  try {
    const {
      employeeId,
      basicSalary,
      hra,
      travelAllowance,
      dailyAllowance,
      medicalAllowance,
      specialAllowance,
      otherAllowances,
      providentFund,
      professionalTax,
      incomeTax,
      otherDeductions,
      effectiveFrom,
      effectiveTo,
      currency,
      paymentFrequency,
      bankName,
      accountNumber,
      ifscCode,
      panNumber,
      remarks,
      isActive
    } = req.body;

    // Validate required fields
    if (!employeeId || !basicSalary || !effectiveFrom) {
      return res.status(400).json({
        success: false,
        message: 'Employee ID, Basic Salary, and Effective From date are required'
      });
    }

    // Check if employee exists
    const employee = await prisma.user.findUnique({
      where: { id: employeeId }
    });

    if (!employee) {
      return res.status(404).json({
        success: false,
        message: 'Employee not found'
      });
    }

    // Check if salary info already exists
    const existingSalary = await prisma.salaryInformation.findUnique({
      where: { employeeId }
    });

    let salaryInfo;

    if (existingSalary) {
      // Update existing salary information
      salaryInfo = await prisma.salaryInformation.update({
        where: { employeeId },
        data: {
          basicSalary: parseFloat(basicSalary),
          hra: hra ? parseFloat(hra) : 0,
          travelAllowance: travelAllowance ? parseFloat(travelAllowance) : 0,
          dailyAllowance: dailyAllowance ? parseFloat(dailyAllowance) : 0,
          medicalAllowance: medicalAllowance ? parseFloat(medicalAllowance) : 0,
          specialAllowance: specialAllowance ? parseFloat(specialAllowance) : 0,
          otherAllowances: otherAllowances ? parseFloat(otherAllowances) : 0,
          providentFund: providentFund ? parseFloat(providentFund) : 0,
          professionalTax: professionalTax ? parseFloat(professionalTax) : 0,
          incomeTax: incomeTax ? parseFloat(incomeTax) : 0,
          otherDeductions: otherDeductions ? parseFloat(otherDeductions) : 0,
          effectiveFrom: new Date(effectiveFrom),
          effectiveTo: effectiveTo ? new Date(effectiveTo) : null,
          currency: currency || 'INR',
          paymentFrequency: paymentFrequency || 'Monthly',
          bankName,
          accountNumber,
          ifscCode,
          panNumber,
          remarks,
          isActive: isActive !== undefined ? isActive : true
        },
        include: {
          employee: {
            select: {
              id: true,
              name: true,
              employeeCode: true,
              designation: true,
              department: true
            }
          }
        }
      });
    } else {
      // Create new salary information
      salaryInfo = await prisma.salaryInformation.create({
        data: {
          employeeId,
          basicSalary: parseFloat(basicSalary),
          hra: hra ? parseFloat(hra) : 0,
          travelAllowance: travelAllowance ? parseFloat(travelAllowance) : 0,
          dailyAllowance: dailyAllowance ? parseFloat(dailyAllowance) : 0,
          medicalAllowance: medicalAllowance ? parseFloat(medicalAllowance) : 0,
          specialAllowance: specialAllowance ? parseFloat(specialAllowance) : 0,
          otherAllowances: otherAllowances ? parseFloat(otherAllowances) : 0,
          providentFund: providentFund ? parseFloat(providentFund) : 0,
          professionalTax: professionalTax ? parseFloat(professionalTax) : 0,
          incomeTax: incomeTax ? parseFloat(incomeTax) : 0,
          otherDeductions: otherDeductions ? parseFloat(otherDeductions) : 0,
          effectiveFrom: new Date(effectiveFrom),
          effectiveTo: effectiveTo ? new Date(effectiveTo) : null,
          currency: currency || 'INR',
          paymentFrequency: paymentFrequency || 'Monthly',
          bankName,
          accountNumber,
          ifscCode,
          panNumber,
          remarks,
          isActive: isActive !== undefined ? isActive : true
        },
        include: {
          employee: {
            select: {
              id: true,
              name: true,
              employeeCode: true,
              designation: true,
              department: true
            }
          }
        }
      });
    }

    // Calculate totals
    const grossSalary = salaryInfo.basicSalary + 
                       (salaryInfo.hra || 0) + 
                       (salaryInfo.travelAllowance || 0) + 
                       (salaryInfo.dailyAllowance || 0) + 
                       (salaryInfo.medicalAllowance || 0) + 
                       (salaryInfo.specialAllowance || 0) + 
                       (salaryInfo.otherAllowances || 0);

    const totalDeductions = (salaryInfo.providentFund || 0) + 
                           (salaryInfo.professionalTax || 0) + 
                           (salaryInfo.incomeTax || 0) + 
                           (salaryInfo.otherDeductions || 0);

    const netSalary = grossSalary - totalDeductions;

    res.status(existingSalary ? 200 : 201).json({
      success: true,
      message: existingSalary ? 'Salary information updated successfully' : 'Salary information created successfully',
      data: {
        ...salaryInfo,
        grossSalary,
        totalDeductions,
        netSalary
      }
    });
  } catch (error) {
    console.error('Error creating/updating salary:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to save salary information',
      error: error.message
    });
  }
};

// Get Salary Information by Employee ID
export const getSalaryByEmployeeId = async (req, res) => {
  try {
    const { employeeId } = req.params;

    const salaryInfo = await prisma.salaryInformation.findUnique({
      where: { employeeId },
      include: {
        employee: {
          select: {
            id: true,
            name: true,
            employeeCode: true,
            designation: true,
            email: true,
            contactNumber: true,
            joiningDate: true,
            department: {
              select: {
                id: true,
                name: true
              }
            }
          }
        }
      }
    });

    if (!salaryInfo) {
      return res.status(404).json({
        success: false,
        message: 'Salary information not found for this employee'
      });
    }

    // Calculate totals
    const grossSalary = salaryInfo.basicSalary + 
                       (salaryInfo.hra || 0) + 
                       (salaryInfo.travelAllowance || 0) + 
                       (salaryInfo.dailyAllowance || 0) + 
                       (salaryInfo.medicalAllowance || 0) + 
                       (salaryInfo.specialAllowance || 0) + 
                       (salaryInfo.otherAllowances || 0);

    const totalDeductions = (salaryInfo.providentFund || 0) + 
                           (salaryInfo.professionalTax || 0) + 
                           (salaryInfo.incomeTax || 0) + 
                           (salaryInfo.otherDeductions || 0);

    const netSalary = grossSalary - totalDeductions;

    res.json({
      success: true,
      data: {
        ...salaryInfo,
        grossSalary,
        totalDeductions,
        netSalary
      }
    });
  } catch (error) {
    console.error('Error fetching salary:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch salary information',
      error: error.message
    });
  }
};

// Get All Salary Information with filters
export const getAllSalaries = async (req, res) => {
  try {
    const { 
      departmentId, 
      isActive, 
      minSalary, 
      maxSalary,
      search,
      page = 1,
      limit = 50
    } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);

    // Build where clause
    const where = {};
    
    if (isActive !== undefined) {
      where.isActive = isActive === 'true';
    }

    if (minSalary || maxSalary) {
      where.basicSalary = {};
      if (minSalary) where.basicSalary.gte = parseFloat(minSalary);
      if (maxSalary) where.basicSalary.lte = parseFloat(maxSalary);
    }

    if (departmentId || search) {
      where.employee = {};
      if (departmentId) where.employee.departmentId = departmentId;
      if (search) {
        where.employee.OR = [
          { name: { contains: search, mode: 'insensitive' } },
          { employeeCode: { contains: search, mode: 'insensitive' } },
          { email: { contains: search, mode: 'insensitive' } }
        ];
      }
    }

    const [salaries, total] = await Promise.all([
      prisma.salaryInformation.findMany({
        where,
        skip,
        take,
        include: {
          employee: {
            select: {
              id: true,
              name: true,
              employeeCode: true,
              designation: true,
              email: true,
              contactNumber: true,
              department: {
                select: {
                  id: true,
                  name: true
                }
              }
            }
          }
        },
        orderBy: {
          createdAt: 'desc'
        }
      }),
      prisma.salaryInformation.count({ where })
    ]);

    // Calculate totals for each salary
    const salariesWithTotals = salaries.map(salary => {
      const grossSalary = salary.basicSalary + 
                         (salary.hra || 0) + 
                         (salary.travelAllowance || 0) + 
                         (salary.dailyAllowance || 0) + 
                         (salary.medicalAllowance || 0) + 
                         (salary.specialAllowance || 0) + 
                         (salary.otherAllowances || 0);

      const totalDeductions = (salary.providentFund || 0) + 
                             (salary.professionalTax || 0) + 
                             (salary.incomeTax || 0) + 
                             (salary.otherDeductions || 0);

      const netSalary = grossSalary - totalDeductions;

      return {
        ...salary,
        grossSalary,
        totalDeductions,
        netSalary
      };
    });

    res.json({
      success: true,
      data: salariesWithTotals,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Error fetching salaries:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch salary information',
      error: error.message
    });
  }
};

// Get Salary Statistics
export const getSalaryStatistics = async (req, res) => {
  try {
    const { departmentId } = req.query;

    const where = { isActive: true };
    if (departmentId) {
      where.employee = { departmentId };
    }

    const salaries = await prisma.salaryInformation.findMany({
      where,
      include: {
        employee: {
          select: {
            department: {
              select: {
                name: true
              }
            }
          }
        }
      }
    });

    // Calculate statistics
    let totalBasicSalary = 0;
    let totalTravelAllowance = 0;
    let totalDailyAllowance = 0;
    let totalGrossSalary = 0;
    let totalDeductions = 0;
    let totalNetSalary = 0;

    const departmentWise = {};

    salaries.forEach(salary => {
      const grossSalary = salary.basicSalary + 
                         (salary.hra || 0) + 
                         (salary.travelAllowance || 0) + 
                         (salary.dailyAllowance || 0) + 
                         (salary.medicalAllowance || 0) + 
                         (salary.specialAllowance || 0) + 
                         (salary.otherAllowances || 0);

      const deductions = (salary.providentFund || 0) + 
                        (salary.professionalTax || 0) + 
                        (salary.incomeTax || 0) + 
                        (salary.otherDeductions || 0);

      const netSalary = grossSalary - deductions;

      totalBasicSalary += salary.basicSalary;
      totalTravelAllowance += salary.travelAllowance || 0;
      totalDailyAllowance += salary.dailyAllowance || 0;
      totalGrossSalary += grossSalary;
      totalDeductions += deductions;
      totalNetSalary += netSalary;

      // Department-wise breakdown
      const deptName = salary.employee?.department?.name || 'Unassigned';
      if (!departmentWise[deptName]) {
        departmentWise[deptName] = {
          count: 0,
          totalBasicSalary: 0,
          totalTravelAllowance: 0,
          totalDailyAllowance: 0,
          totalGrossSalary: 0,
          totalNetSalary: 0
        };
      }
      departmentWise[deptName].count++;
      departmentWise[deptName].totalBasicSalary += salary.basicSalary;
      departmentWise[deptName].totalTravelAllowance += salary.travelAllowance || 0;
      departmentWise[deptName].totalDailyAllowance += salary.dailyAllowance || 0;
      departmentWise[deptName].totalGrossSalary += grossSalary;
      departmentWise[deptName].totalNetSalary += netSalary;
    });

    res.json({
      success: true,
      data: {
        totalEmployees: salaries.length,
        totalBasicSalary: Math.round(totalBasicSalary * 100) / 100,
        totalTravelAllowance: Math.round(totalTravelAllowance * 100) / 100,
        totalDailyAllowance: Math.round(totalDailyAllowance * 100) / 100,
        totalGrossSalary: Math.round(totalGrossSalary * 100) / 100,
        totalDeductions: Math.round(totalDeductions * 100) / 100,
        totalNetSalary: Math.round(totalNetSalary * 100) / 100,
        averageBasicSalary: salaries.length > 0 ? Math.round((totalBasicSalary / salaries.length) * 100) / 100 : 0,
        averageGrossSalary: salaries.length > 0 ? Math.round((totalGrossSalary / salaries.length) * 100) / 100 : 0,
        averageNetSalary: salaries.length > 0 ? Math.round((totalNetSalary / salaries.length) * 100) / 100 : 0,
        departmentWise
      }
    });
  } catch (error) {
    console.error('Error fetching salary statistics:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch salary statistics',
      error: error.message
    });
  }
};

// Delete Salary Information
export const deleteSalary = async (req, res) => {
  try {
    const { employeeId } = req.params;

    const salaryInfo = await prisma.salaryInformation.findUnique({
      where: { employeeId }
    });

    if (!salaryInfo) {
      return res.status(404).json({
        success: false,
        message: 'Salary information not found'
      });
    }

    await prisma.salaryInformation.delete({
      where: { employeeId }
    });

    res.json({
      success: true,
      message: 'Salary information deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting salary:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete salary information',
      error: error.message
    });
  }
};
