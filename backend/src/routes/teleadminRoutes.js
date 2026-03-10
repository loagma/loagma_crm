import express from 'express';
import { authMiddleware } from '../middleware/authMiddleware.js';
import {
  getTelecallerPincodeAssignments,
  upsertTelecallerPincodeAssignments,
  getTelecallerPincodeAssignmentsSummary,
  upsertTelecallerPincodeAssignmentsForDay,
  upsertTelecallerPincodes,
} from '../controllers/telecallerAssignmentController.js';

const router = express.Router();

router.use(authMiddleware);

// Tele Admin – manage telecaller pincode assignments
router.get('/telecallers/:id/pincode-assignments', getTelecallerPincodeAssignments);
router.put('/telecallers/:id/pincode-assignments', upsertTelecallerPincodeAssignments);
router.put('/telecallers/:id/pincodes', upsertTelecallerPincodes);

// Per-day summary and updates
router.get(
  '/telecallers/:id/pincode-assignments/summary',
  getTelecallerPincodeAssignmentsSummary,
);
router.put(
  '/telecallers/:id/pincode-assignments/day/:day',
  upsertTelecallerPincodeAssignmentsForDay,
);

export default router;

