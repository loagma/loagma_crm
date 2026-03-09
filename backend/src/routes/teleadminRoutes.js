import express from 'express';
import { authMiddleware } from '../middleware/authMiddleware.js';
import {
  getTelecallerPincodeAssignments,
  upsertTelecallerPincodeAssignments,
} from '../controllers/telecallerAssignmentController.js';

const router = express.Router();

router.use(authMiddleware);

// Tele Admin – manage telecaller pincode assignments
router.get('/telecallers/:id/pincode-assignments', getTelecallerPincodeAssignments);
router.put('/telecallers/:id/pincode-assignments', upsertTelecallerPincodeAssignments);

export default router;

