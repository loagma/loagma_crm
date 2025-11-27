import prisma from '../config/db.js';

// Generate numeric user ID
async function generateNumericUserId() {
  // Get the count of existing users and add 1
  const userCount = await prisma.user.count();
  const nextId = userCount + 1;
  
  // Format as EMP followed by 6 digits (e.g., EMP000001, EMP000002)
  const userId = `EMP${String(nextId).padStart(6, '0')}`;
  
  // Check if ID already exists (in case of deletions)
  const existing = await prisma.user.findUnique({ where: { id: userId } });
  if (existing) {
    // If exists, find the highest numeric ID and increment
    const allUsers = await prisma.user.findMany({
      where: { id: { startsWith: 'EMP' } },
      select: { id: true },
      orderBy: { id: 'desc' },
      take: 1,
    });
    
    if (allUsers.length > 0) {
      const lastId = allUsers[0].id;
      const lastNumber = parseInt(lastId.replace('EMP', ''));
      return `EMP${String(lastNumber + 1).padStart(6, '0')}`;
    }
  }
  
  return userId;
}

export const createUser = async (req, res) => {
  try {
    const { name, email, contactNumber, roleId } = req.body;
    const userId = await generateNumericUserId();
    
    const user = await prisma.user.create({
      data: { 
        id: userId,
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
