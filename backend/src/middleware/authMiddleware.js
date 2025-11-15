import jwt from 'jsonwebtoken';
import prisma from '../config/db.js';
import dotenv from 'dotenv';
dotenv.config();

export const authMiddleware = async (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ success: false, message: 'No token provided' });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Fetch user with role information
    const user = await prisma.user.findUnique({
      where: { id: decoded.id },
      include: { role: true },
    });

    if (!user) {
      return res.status(401).json({ success: false, message: 'User not found' });
    }

    req.user = {
      id: user.id,
      roleId: user.roleId,
      role: user.role?.name,
    };
    
    next();
  } catch {
    res.status(401).json({ success: false, message: 'Invalid token' });
  }
};
