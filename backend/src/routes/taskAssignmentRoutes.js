import express from 'express';
import {
  getAllSalesmen,
  getLocationByPincode,
  assignAreasToSalesman,
  getAssignmentsBySalesman,
  deleteAssignment,
  searchBusinesses,
  saveShops,
  getShopsBySalesman,
  updateShopStage,
  getShopsByPincode
} from '../controllers/taskAssignmentController.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = express.Router();

// All routes require authentication
router.use(authMiddleware);

// Salesmen routes
router.get('/salesmen', getAllSalesmen);

// Location routes
router.get('/location/pincode/:pincode', getLocationByPincode);

// Assignment routes
router.post('/assignments/areas', assignAreasToSalesman);
router.get('/assignments/salesman/:salesmanId', getAssignmentsBySalesman);
router.delete('/assignments/:assignmentId', deleteAssignment);

// Business search routes
router.post('/businesses/search', searchBusinesses);

// Shop routes
router.post('/shops', saveShops);
router.get('/shops/salesman/:salesmanId', getShopsBySalesman);
router.get('/shops/pincode/:pincode', getShopsByPincode);
router.patch('/shops/:shopId/stage', updateShopStage);

export default router;
