import express from 'express';
import { createUser, getAllUsers } from '../controllers/userController.js';


const router = express.Router();

// Only NSM can create users
router.post('/', createUser);
router.get('/get-all', getAllUsers);

export default router;
