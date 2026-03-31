import express from 'express';
import { getLocationByPincode, getAreasByPincode } from '../services/pincodeService.js';

const router = express.Router();

function isNotFoundResult(result) {
  const msg = (result?.message || '').toString().toLowerCase();
  return msg.includes('not found') || msg.includes('invalid');
}

// GET /pincode/:pincode - Lookup location by pincode
router.get('/:pincode', async (req, res) => {
  try {
    const { pincode } = req.params;
    
    const result = await getLocationByPincode(pincode);
    
    if (result.success) {
      res.json(result);
    } else {
      const status = result.httpStatus || (isNotFoundResult(result) ? 404 : 502);
      res.status(status).json(result);
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

// GET /pincode/:pincode/areas - Get all areas for a pincode
router.get('/:pincode/areas', async (req, res) => {
  try {
    const { pincode } = req.params;
    
    const result = await getAreasByPincode(pincode);
    
    if (result.success) {
      res.json(result);
    } else {
      const status = result.httpStatus || (isNotFoundResult(result) ? 404 : 502);
      res.status(status).json(result);
    }
  } catch (error) {
    console.error('Areas route error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message,
    });
  }
});

export default router;
