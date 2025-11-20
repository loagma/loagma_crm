import prisma from '../config/db.js';

// Create expense (by employee)
export const createExpense = async (req, res) => {
  try {
    const {
      expenseType,
      amount,
      expenseDate,
      description,
      billNumber,
      attachmentUrl,
    } = req.body;

    // Get employee ID from authenticated user
    const employeeId = req.user?.id;

    if (!employeeId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated',
      });
    }

    // Validate required fields
    if (!expenseType || !amount || !expenseDate) {
      return res.status(400).json({
        success: false,
        message: 'Expense type, amount, and date are required',
      });
    }

    if (parseFloat(amount) <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Amount must be greater than 0',
      });
    }

    // Create expense
    const expense = await prisma.expense.create({
      data: {
        employeeId,
        expenseType,
        amount: parseFloat(amount),
        expenseDate: new Date(expenseDate),
        description,
        billNumber,
        attachmentUrl,
        status: 'Pending',
      },
      include: {
        employee: {
          select: {
            id: true,
            name: true,
            email: true,
            contactNumber: true,
            department: { select: { name: true } },
          },
        },
      },
    });

    res.status(201).json({
      success: true,
      message: 'Expense created successfully',
      expense,
    });
  } catch (error) {
    console.error('❌ Create Expense Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create expense',
      error: error.message,
    });
  }
};

// Get my expenses (for logged-in employee)
export const getMyExpenses = async (req, res) => {
  try {
    const employeeId = req.user?.id;

    if (!employeeId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated',
      });
    }

    const { status, startDate, endDate, expenseType } = req.query;

    // Build filter
    const where = { employeeId };

    if (status) {
      where.status = status;
    }

    if (expenseType) {
      where.expenseType = expenseType;
    }

    if (startDate || endDate) {
      where.expenseDate = {};
      if (startDate) {
        where.expenseDate.gte = new Date(startDate);
      }
      if (endDate) {
        where.expenseDate.lte = new Date(endDate);
      }
    }

    const expenses = await prisma.expense.findMany({
      where,
      include: {
        approver: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
      orderBy: { expenseDate: 'desc' },
    });

    // Calculate totals
    const totalAmount = expenses.reduce((sum, exp) => sum + exp.amount, 0);
    const pendingAmount = expenses
      .filter((exp) => exp.status === 'Pending')
      .reduce((sum, exp) => sum + exp.amount, 0);
    const approvedAmount = expenses
      .filter((exp) => exp.status === 'Approved')
      .reduce((sum, exp) => sum + exp.amount, 0);
    const paidAmount = expenses
      .filter((exp) => exp.status === 'Paid')
      .reduce((sum, exp) => sum + exp.amount, 0);

    res.json({
      success: true,
      expenses,
      summary: {
        totalExpenses: expenses.length,
        totalAmount,
        pendingAmount,
        approvedAmount,
        paidAmount,
      },
    });
  } catch (error) {
    console.error('❌ Get My Expenses Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch expenses',
      error: error.message,
    });
  }
};

// Get all expenses (for admin/manager)
export const getAllExpenses = async (req, res) => {
  try {
    const { status, employeeId, startDate, endDate, expenseType } = req.query;

    // Build filter
    const where = {};

    if (status) {
      where.status = status;
    }

    if (employeeId) {
      where.employeeId = employeeId;
    }

    if (expenseType) {
      where.expenseType = expenseType;
    }

    if (startDate || endDate) {
      where.expenseDate = {};
      if (startDate) {
        where.expenseDate.gte = new Date(startDate);
      }
      if (endDate) {
        where.expenseDate.lte = new Date(endDate);
      }
    }

    const expenses = await prisma.expense.findMany({
      where,
      include: {
        employee: {
          select: {
            id: true,
            name: true,
            email: true,
            contactNumber: true,
            department: { select: { name: true } },
          },
        },
        approver: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
      orderBy: { expenseDate: 'desc' },
    });

    // Calculate totals
    const totalAmount = expenses.reduce((sum, exp) => sum + exp.amount, 0);
    const pendingAmount = expenses
      .filter((exp) => exp.status === 'Pending')
      .reduce((sum, exp) => sum + exp.amount, 0);
    const approvedAmount = expenses
      .filter((exp) => exp.status === 'Approved')
      .reduce((sum, exp) => sum + exp.amount, 0);

    res.json({
      success: true,
      expenses,
      summary: {
        totalExpenses: expenses.length,
        totalAmount,
        pendingAmount,
        approvedAmount,
      },
    });
  } catch (error) {
    console.error('❌ Get All Expenses Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch expenses',
      error: error.message,
    });
  }
};

// Update expense (by employee - only if pending)
export const updateExpense = async (req, res) => {
  try {
    const { id } = req.params;
    const employeeId = req.user?.id;

    if (!employeeId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated',
      });
    }

    // Check if expense exists and belongs to user
    const existingExpense = await prisma.expense.findUnique({
      where: { id },
    });

    if (!existingExpense) {
      return res.status(404).json({
        success: false,
        message: 'Expense not found',
      });
    }

    if (existingExpense.employeeId !== employeeId) {
      return res.status(403).json({
        success: false,
        message: 'You can only update your own expenses',
      });
    }

    if (existingExpense.status !== 'Pending') {
      return res.status(400).json({
        success: false,
        message: 'Can only update pending expenses',
      });
    }

    const {
      expenseType,
      amount,
      expenseDate,
      description,
      billNumber,
      attachmentUrl,
    } = req.body;

    const expense = await prisma.expense.update({
      where: { id },
      data: {
        ...(expenseType && { expenseType }),
        ...(amount && { amount: parseFloat(amount) }),
        ...(expenseDate && { expenseDate: new Date(expenseDate) }),
        ...(description !== undefined && { description }),
        ...(billNumber !== undefined && { billNumber }),
        ...(attachmentUrl !== undefined && { attachmentUrl }),
      },
      include: {
        employee: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
    });

    res.json({
      success: true,
      message: 'Expense updated successfully',
      expense,
    });
  } catch (error) {
    console.error('❌ Update Expense Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update expense',
      error: error.message,
    });
  }
};

// Delete expense (by employee - only if pending)
export const deleteExpense = async (req, res) => {
  try {
    const { id } = req.params;
    const employeeId = req.user?.id;

    if (!employeeId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated',
      });
    }

    // Check if expense exists and belongs to user
    const existingExpense = await prisma.expense.findUnique({
      where: { id },
    });

    if (!existingExpense) {
      return res.status(404).json({
        success: false,
        message: 'Expense not found',
      });
    }

    if (existingExpense.employeeId !== employeeId) {
      return res.status(403).json({
        success: false,
        message: 'You can only delete your own expenses',
      });
    }

    if (existingExpense.status !== 'Pending') {
      return res.status(400).json({
        success: false,
        message: 'Can only delete pending expenses',
      });
    }

    await prisma.expense.delete({
      where: { id },
    });

    res.json({
      success: true,
      message: 'Expense deleted successfully',
    });
  } catch (error) {
    console.error('❌ Delete Expense Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete expense',
      error: error.message,
    });
  }
};

// Approve/Reject expense (by admin/manager)
export const updateExpenseStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, rejectionReason, remarks } = req.body;
    const approverId = req.user?.id;

    if (!approverId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated',
      });
    }

    if (!['Approved', 'Rejected', 'Paid'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status. Must be Approved, Rejected, or Paid',
      });
    }

    if (status === 'Rejected' && !rejectionReason) {
      return res.status(400).json({
        success: false,
        message: 'Rejection reason is required',
      });
    }

    const expense = await prisma.expense.update({
      where: { id },
      data: {
        status,
        approvedBy: approverId,
        approvedAt: new Date(),
        ...(rejectionReason && { rejectionReason }),
        ...(remarks && { remarks }),
        ...(status === 'Paid' && { paidAt: new Date() }),
      },
      include: {
        employee: {
          select: {
            id: true,
            name: true,
            email: true,
            contactNumber: true,
          },
        },
        approver: {
          select: {
            id: true,
            name: true,
            email: true,
          },
        },
      },
    });

    res.json({
      success: true,
      message: `Expense ${status.toLowerCase()} successfully`,
      expense,
    });
  } catch (error) {
    console.error('❌ Update Expense Status Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update expense status',
      error: error.message,
    });
  }
};

// Get expense statistics (for dashboard)
export const getExpenseStatistics = async (req, res) => {
  try {
    const employeeId = req.user?.id;

    if (!employeeId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated',
      });
    }

    // Get current month expenses
    const now = new Date();
    const firstDayOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const lastDayOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);

    const monthlyExpenses = await prisma.expense.findMany({
      where: {
        employeeId,
        expenseDate: {
          gte: firstDayOfMonth,
          lte: lastDayOfMonth,
        },
      },
    });

    // Group by expense type
    const byType = monthlyExpenses.reduce((acc, exp) => {
      if (!acc[exp.expenseType]) {
        acc[exp.expenseType] = { count: 0, amount: 0 };
      }
      acc[exp.expenseType].count++;
      acc[exp.expenseType].amount += exp.amount;
      return acc;
    }, {});

    // Group by status
    const byStatus = monthlyExpenses.reduce((acc, exp) => {
      if (!acc[exp.status]) {
        acc[exp.status] = { count: 0, amount: 0 };
      }
      acc[exp.status].count++;
      acc[exp.status].amount += exp.amount;
      return acc;
    }, {});

    res.json({
      success: true,
      statistics: {
        thisMonth: {
          total: monthlyExpenses.length,
          totalAmount: monthlyExpenses.reduce((sum, exp) => sum + exp.amount, 0),
          byType,
          byStatus,
        },
      },
    });
  } catch (error) {
    console.error('❌ Get Expense Statistics Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch statistics',
      error: error.message,
    });
  }
};
