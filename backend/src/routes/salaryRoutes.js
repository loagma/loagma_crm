import express from 'express';
import {
  createOrUpdateSalary,
  getSalaryByEmployeeId,
  getAllSalaries,
  getSalaryStatistics,
  deleteSalary
} from '../controllers/salaryController.js';

const router = express.Router();

// Create or Update Salary Information
router.post('/', createOrUpdateSalary);

// Get All Salaries with filters
router.get('/', getAllSalaries);

// Get Salary Statistics
router.get('/statistics', getSalaryStatistics);

// Get Salary by Employee ID
router.get('/:employeeId', getSalaryByEmployeeId);

// Delete Salary Information
router.delete('/:employeeId', deleteSalary);

export default router;
