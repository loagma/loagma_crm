import express from 'express';
import {
  getAllDepartments,
  getAllFunctionalRoles,
  getAllRoles
} from '../controllers/masterController.js';
import { getAreasByPincode } from '../services/pincodeService.js';

const router = express.Router();

router.get('/departments', getAllDepartments);
router.get('/functional-roles', getAllFunctionalRoles);
router.get('/roles', getAllRoles);

// Pincode lookup endpoint
router.get('/pincode/:pincode/areas', async (req, res) => {
  try {
    const { pincode } = req.params;
    const result = await getAreasByPincode(pincode);
    
    if (result.success) {
      res.json(result);
    } else {
      res.status(404).json(result);
    }
  } catch (error) {
    console.error('Pincode lookup error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch pincode data',
      error: error.message,
    });
  }
});

export default router;
