import prisma from '../config/db.js';

function isTeleAdmin(user) {
  // Normalize role: "Tele Admin", "teleadmin", etc.
  const role = (user?.role || '')
    .toString()
    .toLowerCase()
    .replace(/\s+/g, '');
  return role === 'admin' || role === 'teleadmin';
}

// GET /telecaller/pincode-assignments  (for logged‑in telecaller)
export const getMyPincodeAssignments = async (req, res) => {
  try {
    const telecallerId = req.user?.id;
    if (!telecallerId) {
      return res
        .status(401)
        .json({ success: false, message: 'Unauthorized' });
    }

    const rows = await prisma.telecallerPincodeAssignment.findMany({
      where: { telecallerId, isActive: true },
      orderBy: [{ pincode: 'asc' }, { dayOfWeek: 'asc' }],
    });

    return res.json({ success: true, data: rows });
  } catch (error) {
    console.error('❌ getMyPincodeAssignments error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to load pincode assignments',
    });
  }
};

// GET /teleadmin/telecallers/:id/pincode-assignments
export const getTelecallerPincodeAssignments = async (req, res) => {
  try {
    if (!isTeleAdmin(req.user)) {
      return res
        .status(403)
        .json({ success: false, message: 'Only Tele Admin / Admin can view assignments' });
    }

    const { id } = req.params;
    const assignments = await prisma.telecallerPincodeAssignment.findMany({
      where: { telecallerId: id, isActive: true },
      orderBy: [{ pincode: 'asc' }, { dayOfWeek: 'asc' }],
    });

    return res.json({ success: true, data: assignments });
  } catch (error) {
    console.error('❌ getTelecallerPincodeAssignments error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to load assignments',
    });
  }
};

// PUT /teleadmin/telecallers/:id/pincode-assignments
// Body: { assignments: [{ pincode: string, dayOfWeek: number }] }
export const upsertTelecallerPincodeAssignments = async (req, res) => {
  try {
    if (!isTeleAdmin(req.user)) {
      return res
        .status(403)
        .json({ success: false, message: 'Only Tele Admin / Admin can update assignments' });
    }

    const { id } = req.params;
    const { assignments } = req.body || {};

    if (!Array.isArray(assignments)) {
      return res.status(400).json({
        success: false,
        message: 'assignments must be an array of { pincode, dayOfWeek }',
      });
    }

    // Soft-disable existing assignments for this telecaller
    await prisma.telecallerPincodeAssignment.updateMany({
      where: { telecallerId: id, isActive: true },
      data: { isActive: false },
    });

    const cleaned = [];
    for (const item of assignments) {
      const pinRaw = String(item.pincode || '').trim();
      const day = Number(item.dayOfWeek ?? 0);
      if (!/^\d{6}$/.test(pinRaw)) continue;
      if (!Number.isInteger(day) || day < 0 || day > 7) continue;
      cleaned.push({ telecallerId: id, pincode: pinRaw, dayOfWeek: day });
    }

    if (cleaned.length === 0) {
      return res.json({
        success: true,
        message: 'All assignments cleared for telecaller',
        data: [],
      });
    }

    const created = await prisma.telecallerPincodeAssignment.createMany({
      data: cleaned,
    });

    return res.json({
      success: true,
      message: 'Assignments updated',
      data: { count: created.count },
    });
  } catch (error) {
    console.error('❌ upsertTelecallerPincodeAssignments error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to save assignments',
    });
  }
};

