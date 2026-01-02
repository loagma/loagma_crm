import express from 'express';
import {
    getShopsByPincode,
    getGooglePlaceDetails,
    createAccountFromGooglePlace
} from '../controllers/shopController.js';

const router = express.Router();

// ==================== SHOP ROUTES ====================
router.get('/pincode/:pincode', getShopsByPincode);
router.get('/google-place/:placeId', getGooglePlaceDetails);
router.post('/google-place/:placeId/create-account', createAccountFromGooglePlace);

export default router;