import prisma from '../config/db.js';
import { randomUUID } from 'crypto';

export const createUser = async (req, res) => {
  try {
    const { name, email, contactNumber, roleId } = req.body;
    const user = await prisma.user.create({
      data: { 
        id: randomUUID(),
        name, 
        email, 
        contactNumber, 
        roleId 
      },
    });
    res.json({ success: true, message: 'User created successfully', data: user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getAllUsers = async (req, res) => {
  const users = await prisma.user.findMany({
    include: { role: true, department: true },
  });
  res.json({ success: true, data: users });
};
