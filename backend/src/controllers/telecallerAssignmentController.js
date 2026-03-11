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
      where: { telecallerId },
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
      where: { telecallerId: id },
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

    // Normalize + validate + de-duplicate incoming payload
    const dedup = new Set();
    const cleaned = [];
    for (const item of assignments) {
      const pinRaw = String(item.pincode || '').trim();
      const day = Number(item.dayOfWeek);
      if (!/^\d{6}$/.test(pinRaw)) continue;
      // Tele Admin UI sends 1=Mon..7=Sun (we disallow 0 here for clarity)
      if (!Number.isInteger(day) || day < 1 || day > 7) continue;
      const key = `${pinRaw}-${day}`;
      if (dedup.has(key)) continue;
      dedup.add(key);
      cleaned.push({ telecallerId: id, pincode: pinRaw, dayOfWeek: day });
    }

    // Admin can assign any pincode to any telecaller; same pincode may be assigned to multiple telecallers.

    // Replace-all semantics, but done transactionally.
    const result = await prisma.$transaction(async (tx) => {
      await tx.telecallerPincodeAssignment.deleteMany({ where: { telecallerId: id } });
      if (cleaned.length === 0) return { createdCount: 0 };
      const created = await tx.telecallerPincodeAssignment.createMany({ data: cleaned });
      return { createdCount: created.count };
    });

    if (cleaned.length === 0) {
      return res.json({
        success: true,
        message: 'All assignments cleared for telecaller',
        data: [],
      });
    }

    return res.json({
      success: true,
      message: 'Assignments updated',
      data: { count: result.createdCount },
    });
  } catch (error) {
    console.error('❌ upsertTelecallerPincodeAssignments error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to save assignments',
    });
  }
};

// GET /teleadmin/telecallers/:id/pincode-assignments/summary
// Returns per-day counts and pincode lists for a telecaller
export const getTelecallerPincodeAssignmentsSummary = async (req, res) => {
  try {
    if (!isTeleAdmin(req.user)) {
      return res
        .status(403)
        .json({ success: false, message: 'Only Tele Admin / Admin can view assignments' });
    }

    const { id } = req.params;

    const rows = await prisma.telecallerPincodeAssignment.findMany({
      where: { telecallerId: id },
      orderBy: [{ dayOfWeek: 'asc' }, { pincode: 'asc' }],
    });

    const summary = {};
    for (const row of rows) {
      const day = row.dayOfWeek;
      if (!summary[day]) {
        summary[day] = { count: 0, pincodes: [] };
      }
      if (!summary[day].pincodes.includes(row.pincode)) {
        summary[day].pincodes.push(row.pincode);
        summary[day].count += 1;
      }
    }

    return res.json({ success: true, data: summary });
  } catch (error) {
    console.error('❌ getTelecallerPincodeAssignmentsSummary error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to load assignments summary',
    });
  }
};

// PUT /teleadmin/telecallers/:id/pincode-assignments/day/:day
// Body: { pincodes: string[] }
export const upsertTelecallerPincodeAssignmentsForDay = async (req, res) => {
  try {
    if (!isTeleAdmin(req.user)) {
      return res
        .status(403)
        .json({ success: false, message: 'Only Tele Admin / Admin can update assignments' });
    }

    const { id, day } = req.params;
    const numericDay = Number(day);
    if (!Number.isInteger(numericDay) || numericDay < 1 || numericDay > 7) {
      return res.status(400).json({
        success: false,
        message: 'day must be an integer between 1 and 7',
      });
    }

    const { pincodes } = req.body || {};
    if (!Array.isArray(pincodes)) {
      return res.status(400).json({
        success: false,
        message: 'pincodes must be an array of 6-digit strings',
      });
    }

    const dedupPins = new Set();
    const cleaned = [];
    for (const raw of pincodes) {
      const pinRaw = String(raw || '').trim();
      if (!/^\d{6}$/.test(pinRaw)) continue;
      if (dedupPins.has(pinRaw)) continue;
      dedupPins.add(pinRaw);
      cleaned.push({ telecallerId: id, pincode: pinRaw, dayOfWeek: numericDay });
    }

    // Admin can assign any pincode to any telecaller; same pincode may be assigned to multiple telecallers.

    const result = await prisma.$transaction(async (tx) => {
      await tx.telecallerPincodeAssignment.deleteMany({
        where: { telecallerId: id, dayOfWeek: numericDay },
      });
      if (cleaned.length === 0) return { createdCount: 0 };
      const created = await tx.telecallerPincodeAssignment.createMany({ data: cleaned });
      return { createdCount: created.count };
    });

    return res.json({
      success: true,
      message: 'Day assignments updated',
      data: { count: result.createdCount },
    });
  } catch (error) {
    console.error('❌ upsertTelecallerPincodeAssignmentsForDay error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to save day assignments',
    });
  }
};

// PUT /teleadmin/telecallers/:id/pincodes
// Body: { pincodes: string[] } – assign pincodes to telecaller for ALL days (dayOfWeek = 0)
export const upsertTelecallerPincodes = async (req, res) => {
  try {
    if (!isTeleAdmin(req.user)) {
      return res
        .status(403)
        .json({ success: false, message: 'Only Tele Admin / Admin can update assignments' });
    }

    const { id } = req.params;
    const { pincodes } = req.body || {};

    if (!Array.isArray(pincodes)) {
      return res.status(400).json({
        success: false,
        message: 'pincodes must be an array of 6-digit strings',
      });
    }

    const dedupPins = new Set();
    const cleaned = [];
    for (const raw of pincodes) {
      const pinRaw = String(raw || '').trim();
      if (!/^\d{6}$/.test(pinRaw)) continue;
      if (dedupPins.has(pinRaw)) continue;
      dedupPins.add(pinRaw);
      cleaned.push({ telecallerId: id, pincode: pinRaw, dayOfWeek: 0 });
    }

    // Admin can assign any pincode to any telecaller; same pincode may be assigned to multiple telecallers.

    const result = await prisma.$transaction(async (tx) => {
      await tx.telecallerPincodeAssignment.deleteMany({
        where: { telecallerId: id, dayOfWeek: 0 },
      });
      if (cleaned.length === 0) return { createdCount: 0 };
      const created = await tx.telecallerPincodeAssignment.createMany({ data: cleaned });
      return { createdCount: created.count };
    });

    return res.json({
      success: true,
      message: 'Pincode assignments updated',
      data: { count: result.createdCount },
    });
  } catch (error) {
    console.error('❌ upsertTelecallerPincodes error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to save assignments',
    });
  }
};

