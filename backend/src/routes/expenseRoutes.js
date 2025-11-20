import express from 'express';
import {
  createExpense,
  getMyExpenses,
  getAllExpenses,
  updateExpense,
  deleteExpense,
  updateExpenseStatus,
  getExpenseStatistics,
} from '../controllers/expenseController.js';
import { authenticateToken } from '../middleware/authMiddleware.js';

const router = express.Router();

// Employee routes (requires authentication)
router.post('/', authenticateToken, createExpense);
router.get('/my', authenticateToken, getMyExpenses);
router.get('/statistics', authenticateToken, getExpenseStatistics);
router.put('/:id', authenticateToken, updateExpense);
router.delete('/:id', authenticateToken, deleteExpense);

// Admin/Manager routes (requires authentication + admin role)
router.get('/all', authenticateToken, getAllExpenses);
router.patch('/:id/status', authenticateToken, updateExpenseStatus);

export default router;
