import express from 'express';
import { getLocationByPincode } from '../services/pincodeService.js';

const router = express.Router();

// GET /pincode/:pincode - Lookup location by pincode
router.get('/:pincode', async (req, res) => {
  try {
    const { pincode } = req.params;
    
    const result = await getLocationByPincode(pincode);
    
    if (result.success) {
      res.json(result);
    } else {
      res.status(404).json(result);
    }
  } catch (error) {
    console.error('Pincode route error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message,
    });
  }
});

export default router;
