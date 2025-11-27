import prisma from '../config/db.js';

// Generate Numeric User ID (000001, 000002, 000003 ...)
async function generateNumericUserId() {
  // Count total users
  const userCount = await prisma.user.count();
  const nextId = userCount + 1;

  let userId = String(nextId).padStart(6, '0');

  // Check if this ID already exists (case: rows deleted)
  const existing = await prisma.user.findUnique({
    where: { id: userId }
  });

  if (existing) {
    // Fetch the highest existing user ID and increment
    const [latestUser] = await prisma.user.findMany({
      select: { id: true },
      orderBy: { id: 'desc' },
      take: 1,
    });

    if (latestUser) {
      const lastNumber = parseInt(latestUser.id, 10);
      userId = String(lastNumber + 1).padStart(6, '0');
    }
  }

  return userId;
}

// Create User
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
        roleId,
      }
    });

    res.json({
      success: true,
      message: "User created successfully",
      data: user
    });

  } catch (error) {
    console.error("Create user error:", error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// ------------------------------------------------------
// Get All Users
// ------------------------------------------------------
export const getAllUsers = async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      include: {
        role: true,
        department: true
      }
    });

    res.json({ success: true, data: users });

  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
