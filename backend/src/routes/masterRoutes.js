import express from 'express';
import {
  getAllDepartments,
  getAllFunctionalRoles,
  getAllRoles
} from '../controllers/masterController.js';

const router = express.Router();

router.get('/departments', getAllDepartments);
router.get('/functional-roles', getAllFunctionalRoles);
router.get('/roles', getAllRoles);

export default router;
