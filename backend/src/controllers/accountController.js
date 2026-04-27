import { PrismaClient } from '@prisma/client';
import { randomUUID } from 'crypto';
import { uploadBase64Image } from '../services/cloudinaryService.js';

const prisma = new PrismaClient();

const normalizeWeekStartDate = (input) => {
  const base = input ? new Date(input) : new Date();
  if (Number.isNaN(base.getTime())) return null;
  const date = new Date(base.getFullYear(), base.getMonth(), base.getDate());
  const day = date.getDay();
  const delta = day === 0 ? -6 : 1 - day; // Monday start
  date.setDate(date.getDate() + delta);
  date.setHours(0, 0, 0, 0);
  return date;
};

const buildWeekStartDateFilter = (weekStartDate) => {
  const start = toStartOfDay(weekStartDate);
  if (!start) return null;
  const end = new Date(start.getFullYear(), start.getMonth(), start.getDate() + 1);
  return {
    gte: start,
    lt: end,
  };
};

const buildWeekRange = (weekStartDate) => {
  const start = toStartOfDay(weekStartDate);
  if (!start) return null;
  const end = new Date(start.getFullYear(), start.getMonth(), start.getDate() + 6);
  return { start, end };
};

const getDueDaysInWeekForAfterDays = ({ anchorDate, afterDays, weekStartDate }) => {
  const normalizedAnchor = toStartOfDay(anchorDate);
  const weekStart = toStartOfDay(weekStartDate);
  if (!normalizedAnchor || !weekStart || !afterDays || afterDays <= 0) return [];

  const dueDays = [];
  for (let offset = 0; offset < 7; offset += 1) {
    const targetDate = new Date(
      weekStart.getFullYear(),
      weekStart.getMonth(),
      weekStart.getDate() + offset,
    );
    if (isAfterDaysDueOnDate(normalizedAnchor, afterDays, targetDate)) {
      dueDays.push(offset + 1);
    }
  }

  return dueDays;
};

const getDueDaysInWeekForWeekly = ({ assignedDays, recurrenceStartDate, weekStartDate }) => {
  const weekStart = toStartOfDay(weekStartDate);
  if (!weekStart) return [];

  const weeklyDays = parseAssignedDays(assignedDays);
  if (weeklyDays.length === 0) return [];

  const recurrenceStart = toStartOfDay(recurrenceStartDate);
  if (!recurrenceStart) return weeklyDays;

  return weeklyDays.filter((day) => {
    const targetDate = getDateForWeekday(weekStart, day);
    if (!targetDate) return false;
    return targetDate.getTime() >= recurrenceStart.getTime();
  });
};

const getDueDaysInWeekForMonthly = ({ anchorDate, weekStartDate }) => {
  const anchor = toStartOfDay(anchorDate);
  const weekStart = toStartOfDay(weekStartDate);
  if (!anchor || !weekStart) return [];

  const anchorDayOfMonth = anchor.getDate();
  const dueDays = [];

  for (let offset = 0; offset < 7; offset += 1) {
    const targetDate = new Date(
      weekStart.getFullYear(),
      weekStart.getMonth(),
      weekStart.getDate() + offset,
    );
    if (targetDate.getTime() < anchor.getTime()) continue;

    const lastDayOfMonth = new Date(
      targetDate.getFullYear(),
      targetDate.getMonth() + 1,
      0,
    ).getDate();
    const monthlyDueDate = Math.min(anchorDayOfMonth, lastDayOfMonth);

    if (targetDate.getDate() === monthlyDueDate) {
      dueDays.push(offset + 1);
    }
  }

  return dueDays;
};

const parseAssignedDays = (value) => {
  if (!Array.isArray(value)) return [];
  return [...new Set(value
    .map((d) => parseInt(d, 10))
    .filter((d) => d >= 1 && d <= 7))];
};

const parseAfterDays = (value) => {
  if (value === undefined || value === null || value === '') return null;
  const parsed = parseInt(value, 10);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : null;
};

const toStartOfDay = (input) => {
  const date = input instanceof Date ? input : new Date(input);
  if (Number.isNaN(date.getTime())) return null;
  const normalized = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  normalized.setHours(0, 0, 0, 0);
  return normalized;
};

const dayDiff = (from, to) => {
  const fromDate = toStartOfDay(from);
  const toDate = toStartOfDay(to);
  if (!fromDate || !toDate) return null;
  const ms = toDate.getTime() - fromDate.getTime();
  return Math.floor(ms / (24 * 60 * 60 * 1000));
};

const getDateForWeekday = (weekStartDate, day) => {
  const weekStart = toStartOfDay(weekStartDate);
  if (!weekStart || !(day >= 1 && day <= 7)) return null;
  return new Date(weekStart.getFullYear(), weekStart.getMonth(), weekStart.getDate() + (day - 1));
};

const computeFirstRecurrenceDate = (anchorDate, afterDays) => {
  const anchor = toStartOfDay(anchorDate);
  if (!anchor || !afterDays || afterDays <= 0) return null;
  return new Date(anchor.getFullYear(), anchor.getMonth(), anchor.getDate() + afterDays);
};

const isAfterDaysDueOnDate = (anchorDate, afterDays, targetDate) => {
  if (!afterDays || afterDays <= 0) return false;
  const diff = dayDiff(anchorDate, targetDate);
  if (diff === null) return false;
  if (diff < afterDays) return false;
  return diff % afterDays === 0;
};

const computeNextRecurrenceDate = (anchorDate, afterDays, referenceDate) => {
  if (!afterDays || afterDays <= 0) return null;
  const anchor = toStartOfDay(anchorDate);
  const reference = toStartOfDay(referenceDate);
  if (!anchor || !reference) return null;

  const first = computeFirstRecurrenceDate(anchor, afterDays);
  if (!first) return null;
  if (reference.getTime() < first.getTime()) return first;

  const diff = dayDiff(anchor, reference);
  if (diff === null) return first;
  const multiplier = Math.floor(diff / afterDays) + 1;
  return new Date(
    anchor.getFullYear(),
    anchor.getMonth(),
    anchor.getDate() + (multiplier * afterDays),
  );
};

const toAccountDtoWithAssignedDays = (account, assignedDays) => ({
  ...account,
  assignedDays,
});

const getWeeklyAssignmentDelegate = (client) => {
  if (!client) return null;
  const delegate = client.weeklyAccountAssignment;
  if (!delegate) return null;
  return typeof delegate.findMany === 'function' ? delegate : null;
};

const VISIT_FREQUENCY = {
  WEEKLY: 'WEEKLY',
  ONCE: 'ONCE',
  TWICE: 'TWICE',
  THRICE: 'THRICE',
  DAILY: 'DAILY',
  MONTHLY: 'MONTHLY',
  AFTER_DAYS: 'AFTER_DAYS',
};

const REQUIRED_DAY_COUNT_BY_FREQUENCY = {
  [VISIT_FREQUENCY.WEEKLY]: 1,
  [VISIT_FREQUENCY.ONCE]: 1,
  [VISIT_FREQUENCY.TWICE]: 2,
  [VISIT_FREQUENCY.THRICE]: 3,
  [VISIT_FREQUENCY.DAILY]: 7,
  [VISIT_FREQUENCY.MONTHLY]: 1,
  [VISIT_FREQUENCY.AFTER_DAYS]: 1,
};

const ADMIN_OVERRIDE_ROLES = new Set(['admin', 'manager', 'teleadmin']);

const deriveVisitFrequencyFromDays = (days) => {
  const count = Array.isArray(days) ? days.length : 0;
  return count > 0 ? VISIT_FREQUENCY.WEEKLY : null;
};

const normalizeVisitFrequency = (input, fallbackDays = []) => {
  if (!input || (typeof input === 'string' && input.trim().length === 0)) {
    return deriveVisitFrequencyFromDays(fallbackDays);
  }

  const raw = String(input).trim().toUpperCase();
  if (raw === 'WEEKLY' || raw === '1' || raw === 'ONCE') return VISIT_FREQUENCY.WEEKLY;
  if (raw === '2' || raw === 'TWICE') return VISIT_FREQUENCY.WEEKLY;
  if (raw === '3' || raw === 'THRICE') return VISIT_FREQUENCY.WEEKLY;
  if (raw === '7' || raw === 'DAILY') return VISIT_FREQUENCY.WEEKLY;
  if (raw === 'MONTHLY') return VISIT_FREQUENCY.MONTHLY;
  if (raw === 'AFTER_DAYS' || raw === 'AFTER DAYS') return VISIT_FREQUENCY.AFTER_DAYS;
  return null;
};

const validateDaysForFrequency = (days, frequency) => {
  const required = REQUIRED_DAY_COUNT_BY_FREQUENCY[frequency];
  if (!required) {
    return `Invalid visitFrequency '${frequency}'. Allowed: WEEKLY, MONTHLY, AFTER_DAYS`;
  }

  if (!Array.isArray(days) || days.length === 0) {
    return 'plannedDays is required';
  }

  if (frequency === VISIT_FREQUENCY.WEEKLY && days.length >= 1 && days.length <= 7) {
    return null;
  }

  if (days.length !== required) {
    return `visitFrequency ${frequency} requires exactly ${required} day(s)`;
  }

  return null;
};

const hasAdminOverrideAccess = (user) => {
  if (!user) return false;
  const primaryRole = String(user.role || '').toLowerCase().trim();
  const roleId = String(user.roleId || '').toLowerCase().trim();
  const rolesArray = Array.isArray(user.roles)
    ? user.roles.map((r) => String(r || '').toLowerCase().trim())
    : [];

  if (ADMIN_OVERRIDE_ROLES.has(primaryRole)) return true;
  if (ADMIN_OVERRIDE_ROLES.has(roleId)) return true;
  return rolesArray.some((r) => ADMIN_OVERRIDE_ROLES.has(r));
};

const resolveScopedAssigneeId = (req, requestedAssigneeId) => {
  const authUserId = req.user?.id || null;
  const requested = requestedAssigneeId ? String(requestedAssigneeId).trim() : '';

  if (hasAdminOverrideAccess(req.user)) {
    return {
      assigneeId: requested || authUserId,
      forbidden: false,
    };
  }

  if (!authUserId) {
    return { assigneeId: null, forbidden: false };
  }

  if (requested && requested !== authUserId) {
    return { assigneeId: null, forbidden: true };
  }

  return {
    assigneeId: requested || authUserId,
    forbidden: false,
  };
};

const getSalesmanPincodeRows = async (salesmanId) => {
  const [areaRows, taskRows, telecallerRows] = await Promise.all([
    prisma.areaAssignment.findMany({
      where: { salesmanId },
      select: { pinCode: true },
      orderBy: { assignedDate: 'desc' },
    }),
    prisma.taskAssignment.findMany({
      where: { salesmanId },
      select: { pincode: true },
      orderBy: { assignedDate: 'desc' },
    }),
    prisma.telecallerPincodeAssignment.findMany({
      where: {
        telecallerId: salesmanId,
        isActive: true,
      },
      select: { pincode: true },
      orderBy: [{ pincode: 'asc' }, { dayOfWeek: 'asc' }],
    }),
  ]);

  const areaPins = areaRows.map((r) => (r.pinCode || '').trim()).filter(Boolean);
  const taskPins = taskRows.map((r) => (r.pincode || '').trim()).filter(Boolean);
  const telecallerPins = telecallerRows
    .map((r) => (r.pincode || '').trim())
    .filter(Boolean);
  return [...new Set([...areaPins, ...taskPins, ...telecallerPins])];
};

const buildPlanningSummary = (weeklyRows, allAccounts) => {
  const plannedAccountIds = new Set(weeklyRows.map((r) => r.accountId));
  const byFrequency = {
    [VISIT_FREQUENCY.WEEKLY]: 0,
    [VISIT_FREQUENCY.MONTHLY]: 0,
    [VISIT_FREQUENCY.AFTER_DAYS]: 0,
    [VISIT_FREQUENCY.ONCE]: 0,
    [VISIT_FREQUENCY.TWICE]: 0,
    [VISIT_FREQUENCY.THRICE]: 0,
    [VISIT_FREQUENCY.DAILY]: 0,
  };

  for (const row of weeklyRows) {
    const frequency = normalizeVisitFrequency(row.visitFrequency, parseAssignedDays(row.assignedDays));
    if (frequency && byFrequency[frequency] !== undefined) {
      byFrequency[frequency] += 1;
    }
  }

  return {
    totalAccounts: allAccounts.length,
    plannedAccounts: plannedAccountIds.size,
    unplannedAccounts: Math.max(0, allAccounts.length - plannedAccountIds.size),
    frequencyCounts: byFrequency,
  };
};

// ==================== ACCOUNT CRUD ====================

export const getAllAccounts = async (req, res) => {
  try {
    const {
      areaId,
      assignedToId,
      assignedDay,
      customerStage,
      funnelStage,
      isApproved,
      createdById,
      approvedById,
      search,
      pincode,
      startDate,
      endDate,
      page = 1,
      limit = 20
    } = req.query;

    const where = {};

    if (areaId) where.areaId = parseInt(areaId);
    if (assignedToId) where.assignedToId = assignedToId;
    // Day-wise filter for salesman: 1=Mon .. 7=Sun
    if (assignedDay !== undefined && assignedDay !== '' && assignedDay !== null) {
      const day = parseInt(assignedDay, 10);
      if (day >= 1 && day <= 7) {
        // assignedDays is stored as JSON array of numbers in MySQL
        where.assignedDays = { array_contains: day };
      }
    }
    if (customerStage) where.customerStage = customerStage;
    if (funnelStage) where.funnelStage = funnelStage;
    if (isApproved !== undefined) where.isApproved = isApproved === 'true';
    if (createdById) where.createdById = createdById;
    if (approvedById) where.approvedById = approvedById;
    if (pincode && String(pincode).trim()) {
      const pin = String(pincode).trim();
      // Allow partial match so short prefixes still work, but index on pincode keeps it fast.
      where.pincode = { contains: pin };
    }

    // Date range filtering
    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) {
        const start = new Date(startDate);
        where.createdAt.gte = start;
        console.log('📅 Start date filter:', start.toISOString());
      }
      if (endDate) {
        const end = new Date(endDate);
        where.createdAt.lte = end;
        console.log('📅 End date filter:', end.toISOString());
      }
    }

    if (search) {
      where.OR = [
        { businessName: { contains: search } },
        { personName: { contains: search } },
        { accountCode: { contains: search } },
        { contactNumber: { contains: search } },
        { gstNumber: { contains: search } },
        { panCard: { contains: search } }
      ];
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const take = parseInt(limit);

    console.log('🔍 Account query filters:', {
      where,
      startDate,
      endDate,
      page,
      limit,
      dateFilter: where.createdAt
    });

    const [accounts, total] = await Promise.all([
      prisma.account.findMany({
        where,
        skip,
        take,
        orderBy: { createdAt: 'desc' },
        include: {
          assignedTo: {
            select: {
              id: true,
              name: true,
              contactNumber: true,
              roleId: true
            }
          },
          createdBy: {
            select: {
              id: true,
              name: true,
              contactNumber: true,
              roleId: true
            }
          },
          approvedBy: {
            select: {
              id: true,
              name: true,
              contactNumber: true,
              roleId: true
            }
          },
          areaRelation: {
            include: {
              zone: {
                include: {
                  city: {
                    include: {
                      district: {
                        include: {
                          region: {
                            include: {
                              state: {
                                include: { country: true }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }),
      prisma.account.count({ where })
    ]);

    console.log('✅ Found accounts:', accounts.length, 'of', total);
    if (accounts.length > 0) {
      console.log('📊 Account date range in results:');
      console.log('   First account:', accounts[0].personName, 'created at:', accounts[0].createdAt);
      console.log('   Last account:', accounts[accounts.length - 1].personName, 'created at:', accounts[accounts.length - 1].createdAt);
    }

    res.json({
      success: true,
      data: accounts,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get all accounts error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getAccountById = async (req, res) => {
  try {
    const { id } = req.params;

    const account = await prisma.account.findUnique({
      where: { id },
      include: {
        assignedTo: {
          select: {
            id: true,
            name: true,
            contactNumber: true,
            email: true,
            roleId: true
          }
        },
        createdBy: {
          select: {
            id: true,
            name: true,
            contactNumber: true,
            email: true,
            roleId: true
          }
        },
        approvedBy: {
          select: {
            id: true,
            name: true,
            contactNumber: true,
            email: true,
            roleId: true
          }
        },
        areaRelation: {
          include: {
            zone: {
              include: {
                city: {
                  include: {
                    district: {
                      include: {
                        region: {
                          include: {
                            state: {
                              include: { country: true }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    });

    if (!account) {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }

    res.json({ success: true, data: account });
  } catch (error) {
    console.error('Get account by ID error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const createAccount = async (req, res) => {
  try {
    console.log('📥 CREATE ACCOUNT REQUEST (single):', {
      personName: req.body?.personName,
      contactNumber: req.body?.contactNumber,
      businessName: req.body?.businessName,
    });

    const account = await createAccountFromPayload(req.body, req.user?.id, {
      includeRelations: true,
    });

    console.log('✅ Account created successfully:', account.accountCode);
    return res.status(201).json({
      success: true,
      message: 'Account created successfully',
      data: account,
    });
  } catch (error) {
    console.error('❌ Create account error:', error.message);
    console.error('Error code:', error.code);
    console.error('Error meta:', error.meta);

    if (error.statusCode === 400) {
      return res.status(400).json({
        success: false,
        message: error.userMessage || error.message,
      });
    }

    if (error.code === 'P2002') {
      // P2002 is Prisma's unique constraint violation error
      const field = error.meta?.target?.[0] || 'field';
      console.error(`Duplicate field detected: ${field}`);
      return res.status(400).json({
        success: false,
        message: `Duplicate ${field} - this value already exists`,
      });
    }

    return res
      .status(500)
      .json({ success: false, message: error.message || 'Failed to create account' });
  }
};

async function createAccountFromPayload(payload, authUserId, options = {}) {
  const {
    businessName,
    businessType,
    businessSize,
    personName,
    contactNumber,
    dateOfBirth,
    customerStage,
    funnelStage,
    gstNumber,
    panCard,
    ownerImage,
    shopImage,
    isActive,
    pincode,
    country,
    state,
    district,
    city,
    area,
    address,
    latitude,
    longitude,
    assignedToId,
    areaId,
    createdById,
  } = payload || {};

  const { includeRelations = false } = options;

  const validationError = (message) => {
    const err = new Error(message);
    err.statusCode = 400;
    err.userMessage = message;
    return err;
  };

  // Required fields
  if (!personName || !contactNumber) {
    throw validationError('Person name and contact number are required');
  }

  // Contact number: 10 digits
  if (!/^\d{10}$/.test(contactNumber)) {
    throw validationError('Contact number must be exactly 10 digits');
  }

  // PAN format if provided
  if (panCard && !/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/.test(panCard)) {
    throw validationError('Invalid PAN card format');
  }

  // Pincode format if provided
  if (pincode && !/^\d{6}$/.test(pincode)) {
    throw validationError('Pincode must be exactly 6 digits');
  }

  // Coordinates validation if provided
  if (latitude !== undefined && latitude !== null) {
    const lat = parseFloat(latitude);
    if (Number.isNaN(lat) || lat < -90 || lat > 90) {
      throw validationError('Invalid latitude. Must be between -90 and 90');
    }
  }

  if (longitude !== undefined && longitude !== null) {
    const lng = parseFloat(longitude);
    if (Number.isNaN(lng) || lng < -180 || lng > 180) {
      throw validationError('Invalid longitude. Must be between -180 and 180');
    }
  }

  // Both coordinates together or none
  if (
    (latitude !== undefined && latitude !== null) !==
    (longitude !== undefined && longitude !== null)
  ) {
    throw validationError('Both latitude and longitude must be provided together');
  }

  // Generate unique account code
  const accountCode = await generateAccountCode();

  // Determine creator
  const userId = authUserId || createdById || null;

  // Auto-assign telecaller based on pincode mapping (all days) when not explicitly provided
  let finalAssignedToId = assignedToId || null;
  try {
    if (!finalAssignedToId && pincode) {
      const mapping = await prisma.telecallerPincodeAssignment.findFirst({
        where: {
          pincode,
          isActive: true,
          dayOfWeek: 0,
        },
      });
      if (mapping) {
        finalAssignedToId = mapping.telecallerId;
      }
    }
  } catch (e) {
    console.error('⚠️ Telecaller pincode auto-assignment failed (helper):', e);
  }

  // Upload images if provided
  let ownerImageUrl = null;
  let shopImageUrl = null;

  if (ownerImage && ownerImage.startsWith('data:image')) {
    try {
      ownerImageUrl = await uploadBase64Image(ownerImage, 'accounts/owners');
    } catch (error) {
      console.error('❌ Owner image upload failed (helper):', error.message);
      ownerImageUrl = null;
    }
  } else if (ownerImage && ownerImage.startsWith('http')) {
    ownerImageUrl = ownerImage;
  }

  if (shopImage && shopImage.startsWith('data:image')) {
    try {
      shopImageUrl = await uploadBase64Image(shopImage, 'accounts/shops');
    } catch (error) {
      console.error('❌ Shop image upload failed (helper):', error.message);
      shopImageUrl = null;
    }
  } else if (shopImage && shopImage.startsWith('http')) {
    shopImageUrl = shopImage;
  }

  const prismaArgs = {
    data: {
      id: randomUUID(),
      accountCode,
      businessName,
      businessType,
      businessSize,
      personName,
      contactNumber,
      dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : null,
      customerStage,
      funnelStage,
      gstNumber: gstNumber?.toUpperCase(),
      panCard: panCard?.toUpperCase(),
      ownerImage: ownerImageUrl,
      shopImage: shopImageUrl,
      isActive: isActive !== undefined ? isActive : true,
      pincode,
      country,
      state,
      district,
      city,
      area,
      address,
      latitude: latitude ? parseFloat(latitude) : null,
      longitude: longitude ? parseFloat(longitude) : null,
      assignedToId: finalAssignedToId,
      areaId: areaId ? parseInt(areaId, 10) : null,
      createdById: userId,
      isApproved: false,
    },
  };

  if (includeRelations) {
    prismaArgs.include = {
      assignedTo: {
        select: {
          id: true,
          name: true,
          contactNumber: true,
          roleId: true,
        },
      },
      createdBy: {
        select: {
          id: true,
          name: true,
          contactNumber: true,
          roleId: true,
        },
      },
      areaRelation: {
        include: {
          zone: {
            include: {
              city: true,
            },
          },
        },
      },
    };
  }

  const account = await prisma.account.create(prismaArgs);
  return account;
}

export const updateAccount = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      businessName,
      businessType,
      businessSize,
      personName,
      contactNumber,
      dateOfBirth,
      customerStage,
      funnelStage,
      gstNumber,
      panCard,
      ownerImage,
      shopImage,
      isActive,
      pincode,
      country,
      state,
      district,
      city,
      area,
      address,
      latitude,
      longitude,
      assignedToId,
      areaId
    } = req.body;

    // Check if account exists
    const existingAccount = await prisma.account.findUnique({
      where: { id },
      include: {
        createdBy: {
          include: {
            role: true
          }
        }
      }
    });

    if (!existingAccount) {
      return res.status(404).json({
        success: false,
        message: 'Account not found'
      });
    }

    // NOTE: Previous version restricted edits to creator within a 2‑hour window
    // and blocked other users with "You do not have permission to edit this account".
    // For the CRM flows (telecaller verify + admin approve + customer list),
    // we now allow any authenticated user who reaches this controller to update.
    //
    // If you ever need fine‑grained permissions again, reintroduce checks here,
    // but make sure admin roles are always allowed to bypass them.

    // If updating contact number, check for duplicates
    if (contactNumber && contactNumber !== existingAccount.contactNumber) {
      const duplicate = await prisma.account.findFirst({
        where: {
          contactNumber,
          id: { not: id }
        }
      });

      if (duplicate) {
        return res.status(400).json({
          success: false,
          message: 'Contact number already exists for another account'
        });
      }

      // Validate contact number format
      if (!/^\d{10}$/.test(contactNumber)) {
        return res.status(400).json({
          success: false,
          message: 'Contact number must be exactly 10 digits'
        });
      }
    }

    // Validate GST format if provided
    // if (gstNumber && !/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/.test(gstNumber)) {
    //   return res.status(400).json({
    //     success: false,
    //     message: 'Invalid GST number format'
    //   });
    // }

    // Validate PAN format if provided
    if (panCard && !/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/.test(panCard)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid PAN card format'
      });
    }

    // Validate pincode format if provided
    if (pincode && !/^\d{6}$/.test(pincode)) {
      return res.status(400).json({
        success: false,
        message: 'Pincode must be exactly 6 digits'
      });
    }

    // Validate coordinates if provided
    if (latitude !== undefined && latitude !== null) {
      const lat = parseFloat(latitude);
      if (isNaN(lat) || lat < -90 || lat > 90) {
        return res.status(400).json({
          success: false,
          message: 'Invalid latitude. Must be between -90 and 90'
        });
      }
    }

    if (longitude !== undefined && longitude !== null) {
      const lng = parseFloat(longitude);
      if (isNaN(lng) || lng < -180 || lng > 180) {
        return res.status(400).json({
          success: false,
          message: 'Invalid longitude. Must be between -180 and 180'
        });
      }
    }

    // Ensure both coordinates are provided together or both are null
    if ((latitude !== undefined && latitude !== null) !== (longitude !== undefined && longitude !== null)) {
      return res.status(400).json({
        success: false,
        message: 'Both latitude and longitude must be provided together'
      });
    }

    // Upload images to Cloudinary if provided
    let ownerImageUrl = ownerImage;
    let shopImageUrl = shopImage;

    if (ownerImage && ownerImage.startsWith('data:image')) {
      try {
        console.log('📸 Uploading owner image to Cloudinary...');
        console.log('📦 Owner image size:', ownerImage.length, 'characters');
        ownerImageUrl = await uploadBase64Image(ownerImage, 'accounts/owners');
        console.log('✅ Owner image uploaded:', ownerImageUrl);
      } catch (error) {
        console.error('❌ Owner image upload failed:', error.message);
        console.error('❌ Full error:', error);
        ownerImageUrl = undefined; // Don't update if upload fails
      }
    } else if (ownerImage && !ownerImage.startsWith('http')) {
      ownerImageUrl = undefined;
    }

    if (shopImage && shopImage.startsWith('data:image')) {
      try {
        console.log('📸 Uploading shop image to Cloudinary...');
        console.log('📦 Shop image size:', shopImage.length, 'characters');
        shopImageUrl = await uploadBase64Image(shopImage, 'accounts/shops');
        console.log('✅ Shop image uploaded:', shopImageUrl);
      } catch (error) {
        console.error('❌ Shop image upload failed:', error.message);
        console.error('❌ Full error:', error);
        shopImageUrl = undefined; // Don't update if upload fails
      }
    } else if (shopImage && !shopImage.startsWith('http')) {
      shopImageUrl = undefined;
    }

    const updateData = {};

    if (businessName !== undefined) updateData.businessName = businessName;
    if (businessType !== undefined) updateData.businessType = businessType;
    if (businessSize !== undefined) updateData.businessSize = businessSize;
    if (personName !== undefined) updateData.personName = personName;
    if (contactNumber !== undefined) updateData.contactNumber = contactNumber;
    if (dateOfBirth !== undefined) updateData.dateOfBirth = dateOfBirth ? new Date(dateOfBirth) : null;
    if (customerStage !== undefined) updateData.customerStage = customerStage;
    if (funnelStage !== undefined) updateData.funnelStage = funnelStage;
    if (gstNumber !== undefined) updateData.gstNumber = gstNumber?.toUpperCase();
    if (panCard !== undefined) updateData.panCard = panCard?.toUpperCase();
    if (ownerImageUrl !== undefined) updateData.ownerImage = ownerImageUrl;
    if (shopImageUrl !== undefined) updateData.shopImage = shopImageUrl;
    if (isActive !== undefined) updateData.isActive = isActive;
    if (pincode !== undefined) updateData.pincode = pincode;
    if (country !== undefined) updateData.country = country;
    if (state !== undefined) updateData.state = state;
    if (district !== undefined) updateData.district = district;
    if (city !== undefined) updateData.city = city;
    if (area !== undefined) updateData.area = area;
    if (address !== undefined) updateData.address = address;
    if (latitude !== undefined) updateData.latitude = latitude ? parseFloat(latitude) : null;
    if (longitude !== undefined) updateData.longitude = longitude ? parseFloat(longitude) : null;
    if (assignedToId !== undefined) updateData.assignedToId = assignedToId;
    if (areaId !== undefined) updateData.areaId = areaId ? parseInt(areaId) : null;

    const account = await prisma.account.update({
      where: { id },
      data: updateData,
      include: {
        assignedTo: {
          select: {
            id: true,
            name: true,
            contactNumber: true,
            roleId: true
          }
        },
        createdBy: {
          select: {
            id: true,
            name: true,
            contactNumber: true,
            roleId: true
          }
        },
        approvedBy: {
          select: {
            id: true,
            name: true,
            contactNumber: true,
            roleId: true
          }
        },
        areaRelation: {
          include: {
            zone: {
              include: {
                city: true
              }
            }
          }
        }
      }
    });

    res.json({
      success: true,
      message: 'Account updated successfully',
      data: account
    });
  } catch (error) {
    console.error('Update account error:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

export const deleteAccount = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if account exists
    const existingAccount = await prisma.account.findUnique({
      where: { id }
    });

    if (!existingAccount) {
      return res.status(404).json({
        success: false,
        message: 'Account not found'
      });
    }

    await prisma.account.delete({
      where: { id }
    });

    res.json({
      success: true,
      message: 'Account deleted successfully'
    });
  } catch (error) {
    console.error('Delete account error:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== APPROVAL OPERATIONS ====================

export const approveAccount = async (req, res) => {
  try {
    const { id } = req.params;
    const approvedById = req.user?.id || req.body.approvedById;
    const verificationNotes = req.body.verificationNotes ?? null;

    if (!approvedById) {
      return res.status(400).json({
        success: false,
        message: 'Approver ID is required'
      });
    }

    const account = await prisma.account.update({
      where: { id },
      data: {
        isApproved: true,
        approvedById,
        approvedAt: new Date(),
        verificationNotes: verificationNotes || null,
        rejectionNotes: null
      },
      include: {
        assignedTo: {
          select: {
            id: true,
            name: true,
            contactNumber: true
          }
        },
        createdBy: {
          select: {
            id: true,
            name: true,
            contactNumber: true
          }
        },
        approvedBy: {
          select: {
            id: true,
            name: true,
            contactNumber: true
          }
        }
      }
    });

    res.json({
      success: true,
      message: 'Account approved successfully',
      data: account
    });
  } catch (error) {
    console.error('Approve account error:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

export const teleadminVerifyAccount = async (req, res) => {
  try {
    const { id } = req.params;
    const approvedById = req.user?.id || req.body.approvedById;
    const verificationNotes = req.body.verificationNotes ?? null;

    if (!approvedById) {
      return res.status(400).json({
        success: false,
        message: 'Approver ID is required'
      });
    }

    // Check if user is teleadmin
    const approver = await prisma.user.findUnique({
      where: { id: approvedById },
      include: { role: true }
    });

    if (!approver || approver.role?.name?.toLowerCase() !== 'teleadmin') {
      return res.status(403).json({
        success: false,
        message: 'Only teleadmin can use this verification endpoint'
      });
    }

    // Get the account to verify
    const existingAccount = await prisma.account.findUnique({
      where: { id }
    });

    if (!existingAccount) {
      return res.status(404).json({
        success: false,
        message: 'Account not found'
      });
    }

    // Check if customer user already exists with this contact number
    const existingCustomerUser = await prisma.customerUser.findFirst({
      where: { contactno: existingAccount.contactNumber }
    });

    if (existingCustomerUser) {
      return res.status(400).json({
        success: false,
        message: 'Customer user already exists with this contact number'
      });
    }

    // Start transaction to approve account and create user
    const result = await prisma.$transaction(async (tx) => {
      // 1. Approve the account
      const approvedAccount = await tx.account.update({
        where: { id },
        data: {
          isApproved: true,
          approvedById,
          approvedAt: new Date(),
          verificationNotes: verificationNotes || null,
          rejectionNotes: null
        },
        include: {
          assignedTo: {
            select: {
              id: true,
              name: true,
              contactNumber: true
            }
          },
          createdBy: {
            select: {
              id: true,
              name: true,
              contactNumber: true
            }
          },
          approvedBy: {
            select: {
              id: true,
              name: true,
              contactNumber: true
            }
          }
        }
      });

      // 2. Create customer user from account data
      // Generate a unique userid (timestamp + random)
      const userid = BigInt(Date.now().toString() + Math.floor(Math.random() * 1000).toString().padStart(3, '0'));

      const newCustomerUser = await tx.customerUser.create({
        data: {
          userid: userid,
          email: '', // Default empty email
          contactno: existingAccount.contactNumber,
          name: existingAccount.personName,
          account_state: 'complete', // Mark as complete since verified
          address: existingAccount.address || '',
          latitude: existingAccount.latitude || 0,
          longitude: existingAccount.longitude || 0,
          dob: existingAccount.dateOfBirth ? existingAccount.dateOfBirth.toISOString() : null,
          register_date: Math.floor(Date.now() / 1000), // Unix timestamp
          shop_name: existingAccount.businessName,
          shop_address: existingAccount.address,
          user_type: existingAccount.businessType === 'B2B' ? 'B2B' : 'B2C',
          adhar_card: null, // Not available in account
          shop_photo: existingAccount.shopImage,
          shop_licence: null, // Not available in account
          bussiness_pan_card: existingAccount.panCard,
          is_approved: 'YES', // Approved by teleadmin
          session_id: '', // Empty session initially
          last_activity: Math.floor(Date.now() / 1000),
          push_notif_id: '', // Empty initially
          is_first_login: 1,
          has_unread_comments: 0,
          password: `temp_${existingAccount.contactNumber}` // Temporary password
        }
      });

      return { approvedAccount, newCustomerUser };
    });

    res.json({
      success: true,
      message: 'Account verified and customer user created successfully',
      data: {
        account: result.approvedAccount,
        customerUser: {
          userid: result.newCustomerUser.userid.toString(), // Convert BigInt to string
          name: result.newCustomerUser.name,
          contactno: result.newCustomerUser.contactno,
          email: result.newCustomerUser.email,
          user_type: result.newCustomerUser.user_type,
          account_state: result.newCustomerUser.account_state,
          is_approved: result.newCustomerUser.is_approved
        }
      }
    });
  } catch (error) {
    console.error('Teleadmin verify account error:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }
    if (error.code === 'P2002') {
      return res.status(400).json({ success: false, message: 'Customer user with this contact number already exists' });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

export const rejectAccount = async (req, res) => {
  try {
    const { id } = req.params;
    const rejectionNotes = req.body.rejectionNotes ?? null;

    const account = await prisma.account.update({
      where: { id },
      data: {
        isApproved: false,
        approvedById: null,
        approvedAt: null,
        verificationNotes: null,
        rejectionNotes: rejectionNotes || null
      },
      include: {
        createdBy: {
          select: {
            id: true,
            name: true,
            contactNumber: true
          }
        }
      }
    });

    res.json({
      success: true,
      message: 'Account approval rejected',
      data: account
    });
  } catch (error) {
    console.error('Reject account error:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }
    res.status(500).json({ success: false, message: error.message });
  }
};

// GET /accounts/pincode/:pincode/count
export const getAccountCountByPincode = async (req, res) => {
  try {
    const { pincode } = req.params;
    const pin = String(pincode || '').trim();
    if (!/^\d{6}$/.test(pin)) {
      return res.status(400).json({
        success: false,
        message: 'Pincode must be a 6-digit number',
      });
    }

    const count = await prisma.account.count({
      where: { pincode: pin },
    });

    return res.json({
      success: true,
      data: { pincode: pin, count },
    });
  } catch (error) {
    console.error('getAccountCountByPincode error:', error);
    return res.status(500).json({
      success: false,
      message: error.message || 'Failed to get account count',
    });
  }
};

// ==================== HELPER FUNCTIONS ====================

async function generateAccountCode() {
  const prefix = '000';
  const date = new Date();
  const year = date.getFullYear().toString().slice(-2);
  const month = (date.getMonth() + 1).toString().padStart(2, '0');

  // Try up to 10 times to generate a unique code
  for (let attempt = 0; attempt < 10; attempt++) {
    // Get count of all accounts with this year-month prefix
    const pattern = `${prefix}${year}${month}%`;
    const existingAccounts = await prisma.account.findMany({
      where: {
        accountCode: {
          startsWith: `${prefix}${year}${month}`
        }
      },
      select: { accountCode: true },
      orderBy: { accountCode: 'desc' }
    });

    let sequence = 1;
    if (existingAccounts.length > 0) {
      // Extract the last sequence number and increment
      const lastCode = existingAccounts[0].accountCode;
      const lastSequence = parseInt(lastCode.slice(-4));
      sequence = lastSequence + 1;
    }

    const accountCode = `${prefix}${year}${month}${sequence.toString().padStart(4, '0')}`;

    // Check if this code already exists
    const exists = await prisma.account.findUnique({
      where: { accountCode }
    });

    if (!exists) {
      return accountCode;
    }

    // If exists, wait a bit and try again
    await new Promise(resolve => setTimeout(resolve, 100));
  }

  // Fallback: use timestamp to ensure uniqueness
  const timestamp = Date.now().toString().slice(-6);
  return `${prefix}${year}${month}${timestamp}`;
}

// ==================== STATISTICS ====================

export const getAccountStats = async (req, res) => {
  try {
    const { assignedToId, areaId, createdById } = req.query;
    const where = {};

    if (assignedToId) where.assignedToId = assignedToId;
    if (areaId) where.areaId = parseInt(areaId);
    if (createdById) where.createdById = createdById;

    const [
      totalAccounts,
      approvedAccounts,
      pendingAccounts,
      byCustomerStage,
      byFunnelStage,
      recentAccounts
    ] = await Promise.all([
      prisma.account.count({ where }),

      prisma.account.count({
        where: { ...where, isApproved: true }
      }),

      prisma.account.count({
        where: { ...where, isApproved: false }
      }),

      prisma.account.groupBy({
        by: ['customerStage'],
        where,
        _count: true
      }),

      prisma.account.groupBy({
        by: ['funnelStage'],
        where,
        _count: true
      }),

      prisma.account.findMany({
        where,
        take: 10,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          accountCode: true,
          personName: true,
          contactNumber: true,
          customerStage: true,
          isApproved: true,
          createdAt: true,
          createdBy: {
            select: {
              name: true,
              roleId: true
            }
          }
        }
      })
    ]);

    res.json({
      success: true,
      data: {
        totalAccounts,
        approvedAccounts,
        pendingAccounts,
        byCustomerStage,
        byFunnelStage,
        recentAccounts
      }
    });
  } catch (error) {
    console.error('Get account stats error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== BULK OPERATIONS ====================

export const bulkCreateAccounts = async (req, res) => {
  try {
    const { accounts } = req.body || {};
    if (!Array.isArray(accounts) || accounts.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Body must include a non-empty "accounts" array',
      });
    }

    const authUserId = req.user?.id;
    const results = [];
    let created = 0;

    for (let i = 0; i < accounts.length; i += 1) {
      const payload = accounts[i] || {};
      const personName = payload.personName;
      const contactNumber = payload.contactNumber;

      try {
        const account = await createAccountFromPayload(payload, authUserId);
        created += 1;
        results.push({
          index: i,
          success: true,
          accountId: account.id,
          accountCode: account.accountCode,
          personName: account.personName,
          contactNumber: account.contactNumber,
          pincode: account.pincode,
        });
      } catch (err) {
        let reason =
          err?.userMessage || err?.message || 'Failed to create account';
        if (err?.code === 'P2002') {
          const field = err.meta?.target?.[0] || 'field';
          reason = `Duplicate ${field} - this value already exists`;
        }
        results.push({
          index: i,
          success: false,
          personName,
          contactNumber,
          reason,
        });
      }
    }

    const failed = results.length - created;

    return res.status(201).json({
      success: failed === 0,
      message: 'Bulk account import completed',
      data: {
        created,
        failed,
        results,
      },
    });
  } catch (error) {
    console.error('Bulk create accounts error:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to create accounts in bulk',
    });
  }
};

export const bulkAssignAccounts = async (req, res) => {
  try {
    const {
      accountIds,
      assignedToId,
      assignedDays,
      weekStartDate,
      visitFrequency,
      createWeeklyAssignments = true,
    } = req.body;

    if (!accountIds || !Array.isArray(accountIds) || accountIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'accountIds array is required'
      });
    }

    const days = parseAssignedDays(assignedDays || []);
    const normalizedFrequency = normalizeVisitFrequency(visitFrequency, days);
    const frequencyError = validateDaysForFrequency(days, normalizedFrequency);
    if (frequencyError) {
      return res.status(400).json({ success: false, message: frequencyError });
    }

    const actorUserId = req.user?.id || assignedToId || null;

    const result = await prisma.$transaction(async (tx) => {
      const data = {
        assignedToId,
        assignedDays: days,
      };

      const updateResult = await tx.account.updateMany({
        where: {
          id: { in: accountIds },
        },
        data,
      });

      const weeklyDelegate = getWeeklyAssignmentDelegate(tx);
      const weekStart = normalizeWeekStartDate(weekStartDate);

      if (createWeeklyAssignments && weeklyDelegate && weekStart) {
        const accountRows = await tx.account.findMany({
          where: { id: { in: accountIds } },
          select: { id: true, pincode: true, createdAt: true },
          orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
        });

        const existingSequenceRows = await weeklyDelegate.findMany({
          where: { salesmanId: assignedToId, weekStartDate: weekStart },
          select: { pincode: true, sequenceNo: true },
        });

        const nextSequenceByPin = {};
        for (const row of existingSequenceRows) {
          const pin = (row.pincode || '').trim();
          nextSequenceByPin[pin] = Math.max(nextSequenceByPin[pin] || 0, row.sequenceNo || 0);
        }

        const rowsToCreate = [];
        for (const account of accountRows) {
          const pin = String(account.pincode || '').trim();
          if (!pin) continue;
          nextSequenceByPin[pin] = (nextSequenceByPin[pin] || 0) + 1;

          rowsToCreate.push({
            accountId: account.id,
            salesmanId: assignedToId,
            pincode: pin,
            weekStartDate: weekStart,
            assignedDays: days,
            visitFrequency: normalizedFrequency,
            plannedBy: actorUserId,
            plannedAt: new Date(),
            sequenceNo: nextSequenceByPin[pin],
            isManualOverride: false,
          });
        }

        if (rowsToCreate.length > 0) {
          await weeklyDelegate.createMany({ data: rowsToCreate, skipDuplicates: true });
        }
      }

      return updateResult;
    });

    res.json({
      success: true,
      message: `${result.count} accounts assigned successfully`,
      count: result.count,
      visitFrequency: normalizedFrequency,
    });
  } catch (error) {
    console.error('Bulk assign accounts error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getWeeklyAssignmentsView = async (req, res) => {
  try {
    const scope = resolveScopedAssigneeId(req, req.query.salesmanId);
    if (scope.forbidden) {
      return res.status(403).json({
        success: false,
        message: 'You can only access your own weekly assignments',
      });
    }

    const salesmanId = scope.assigneeId;
    const weekStartDate = normalizeWeekStartDate(req.query.weekStartDate);
    const weekStartFilter = buildWeekStartDateFilter(weekStartDate);
    const weekRange = buildWeekRange(weekStartDate);
    const pincodeFilter = req.query.pincode ? String(req.query.pincode).trim() : null;

    if (!salesmanId) {
      return res.status(400).json({ success: false, message: 'salesmanId is required' });
    }

    if (!weekStartDate) {
      return res.status(400).json({ success: false, message: 'Valid weekStartDate is required' });
    }

    if (!weekStartFilter) {
      return res.status(400).json({ success: false, message: 'Unable to normalize weekStartDate for query' });
    }

    if (!weekRange) {
      return res.status(400).json({ success: false, message: 'Unable to derive week range from weekStartDate' });
    }

    const assignedPincodes = await getSalesmanPincodeRows(salesmanId);

    const pincodes = pincodeFilter
      ? assignedPincodes.filter((p) => p === pincodeFilter)
      : assignedPincodes;

    const weeklyDelegate = getWeeklyAssignmentDelegate(prisma);

    const [allAccounts, weeklyRows, recurrenceRows] = await Promise.all([
      pincodes.length === 0
        ? Promise.resolve([])
        : prisma.account.findMany({
          where: { pincode: { in: pincodes } },
          orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
        }),
      weeklyDelegate
        ? weeklyDelegate.findMany({
          where: {
            salesmanId,
            weekStartDate: weekStartFilter,
            ...(pincodes.length > 0 ? { pincode: { in: pincodes } } : {}),
          },
          include: { account: true },
          orderBy: [{ pincode: 'asc' }, { sequenceNo: 'asc' }],
        })
        : Promise.resolve([]),
      weeklyDelegate
        ? weeklyDelegate.findMany({
          where: {
            salesmanId,
            AND: [
              {
                OR: [
                  { recurrenceStartDate: null },
                  { recurrenceStartDate: { lte: weekRange.end } },
                ],
              },
            ],
            ...(pincodes.length > 0 ? { pincode: { in: pincodes } } : {}),
          },
          include: { account: true },
          orderBy: [{ pincode: 'asc' }, { sequenceNo: 'asc' }],
        })
        : Promise.resolve([]),
    ]);

    const dayTotals = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0 };
    const accountDaysByPincode = {};
    const accountMetaByPincode = {};
    const accountFrequencyByPincode = {};

    const frequencyPriority = (frequency) => {
      if (frequency === VISIT_FREQUENCY.AFTER_DAYS) return 3;
      if (frequency === VISIT_FREQUENCY.MONTHLY) return 2;
      if (frequency === VISIT_FREQUENCY.WEEKLY) return 1;
      return 0;
    };

    const upsertAccountDays = (pin, account, days, frequency = VISIT_FREQUENCY.WEEKLY) => {
      if (!pin || !account || !account.id || !Array.isArray(days) || days.length === 0) {
        return;
      }

      if (!accountDaysByPincode[pin]) accountDaysByPincode[pin] = new Map();
      if (!accountMetaByPincode[pin]) accountMetaByPincode[pin] = new Map();
      if (!accountFrequencyByPincode[pin]) accountFrequencyByPincode[pin] = new Map();

      const byAccount = accountDaysByPincode[pin];
      const currentDays = byAccount.get(account.id) || new Set();
      for (const day of days) {
        if (day >= 1 && day <= 7) {
          currentDays.add(day);
        }
      }

      byAccount.set(account.id, currentDays);
      accountMetaByPincode[pin].set(account.id, account);

      const existingFrequency = accountFrequencyByPincode[pin].get(account.id);
      if (!existingFrequency || frequencyPriority(frequency) > frequencyPriority(existingFrequency)) {
        accountFrequencyByPincode[pin].set(account.id, frequency);
      }
    };

    const weeklyByPincode = {};

    if (weeklyDelegate) {
      for (const row of weeklyRows) {
        const pin = (row.pincode || '').trim();
        if (!pin) continue;

        const days = parseAssignedDays(row.assignedDays);
        const frequency = normalizeVisitFrequency(row.visitFrequency, days) || VISIT_FREQUENCY.WEEKLY;
        upsertAccountDays(pin, row.account, days, frequency);
      }

      for (const row of recurrenceRows) {
        const pin = (row.pincode || '').trim();
        if (!pin) continue;

        const rowFrequency = normalizeVisitFrequency(
          row.visitFrequency,
          parseAssignedDays(row.assignedDays),
        );

        if (rowFrequency === VISIT_FREQUENCY.WEEKLY) {
          const weeklyDays = getDueDaysInWeekForWeekly({
            assignedDays: row.assignedDays,
            recurrenceStartDate: row.recurrenceStartDate || row.weekStartDate,
            weekStartDate,
          });
          upsertAccountDays(pin, row.account, weeklyDays, VISIT_FREQUENCY.WEEKLY);
          continue;
        }

        if (rowFrequency === VISIT_FREQUENCY.MONTHLY) {
          const fallbackDays = parseAssignedDays(row.assignedDays);
          const fallbackAnchorDay = fallbackDays[0];
          const fallbackAnchorDate = fallbackAnchorDay
            ? getDateForWeekday(row.weekStartDate, fallbackAnchorDay)
            : null;
          const anchorDate = row.recurrenceStartDate || fallbackAnchorDate;
          if (!anchorDate) continue;

          const dueDays = getDueDaysInWeekForMonthly({
            anchorDate,
            weekStartDate,
          });

          upsertAccountDays(pin, row.account, dueDays, VISIT_FREQUENCY.MONTHLY);
          continue;
        }

        const normalizedAfterDays = parseAfterDays(row.recurrenceAfterDays);
        if (!normalizedAfterDays) continue;

        const fallbackDays = parseAssignedDays(row.assignedDays);
        const fallbackAnchorDay = fallbackDays[0];
        const fallbackAnchorDate = fallbackAnchorDay
          ? getDateForWeekday(row.weekStartDate, fallbackAnchorDay)
          : null;
        const anchorDate = row.recurrenceStartDate || fallbackAnchorDate;
        if (!anchorDate) continue;

        const dueDays = getDueDaysInWeekForAfterDays({
          anchorDate,
          afterDays: normalizedAfterDays,
          weekStartDate,
        });

        upsertAccountDays(pin, row.account, dueDays, VISIT_FREQUENCY.AFTER_DAYS);
      }

      for (const [pin, byAccount] of Object.entries(accountDaysByPincode)) {
        const meta = accountMetaByPincode[pin] || new Map();
        const assignedAccounts = [];

        for (const [accountId, daySet] of byAccount.entries()) {
          const account = meta.get(accountId);
          if (!account) continue;

          const assignedDays = [...daySet].filter((d) => d >= 1 && d <= 7).sort((a, b) => a - b);
          if (assignedDays.length === 0) continue;

          const frequency = accountFrequencyByPincode[pin]?.get(accountId) || VISIT_FREQUENCY.WEEKLY;
          assignedAccounts.push({
            ...toAccountDtoWithAssignedDays(account, assignedDays),
            visitFrequency: frequency,
          });
          for (const day of assignedDays) {
            dayTotals[day] = (dayTotals[day] || 0) + 1;
          }
        }

        weeklyByPincode[pin] = assignedAccounts;
      }
    } else {
      // Compatibility fallback for servers running an older Prisma client.
      for (const account of allAccounts) {
        const pin = (account.pincode || '').trim();
        if (!pin) continue;

        const days = parseAssignedDays(account.assignedDays || []);
        if (days.length === 0) continue;

        if (!weeklyByPincode[pin]) weeklyByPincode[pin] = [];
        weeklyByPincode[pin].push(toAccountDtoWithAssignedDays(account, days));

        for (const day of days) {
          dayTotals[day] = (dayTotals[day] || 0) + 1;
        }
      }
    }

    const allByPincode = {};
    for (const account of allAccounts) {
      const pin = (account.pincode || '').trim();
      if (!pin) continue;
      if (!allByPincode[pin]) allByPincode[pin] = [];
      allByPincode[pin].push(account);
    }

    const effectivePins = pincodes.length > 0 ? pincodes : Object.keys(weeklyByPincode);
    const pincodeGroups = effectivePins.map((pin) => {
      const allPinAccounts = allByPincode[pin] || [];
      const assignedAccounts = weeklyByPincode[pin] || [];
      const assignedIds = new Set(assignedAccounts.map((a) => a.id));
      const remainingAccounts = allPinAccounts.filter((a) => !assignedIds.has(a.id));
      const dayCounts = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0 };
      for (const account of assignedAccounts) {
        const days = parseAssignedDays(account.assignedDays || []);
        for (const day of days) {
          dayCounts[day] = (dayCounts[day] || 0) + 1;
        }
      }

      return {
        pincode: pin,
        totalAccounts: allPinAccounts.length,
        assignedAccounts: assignedAccounts.length,
        remainingAccounts: remainingAccounts.length,
        dayCounts,
        assigned: assignedAccounts,
        remaining: remainingAccounts,
      };
    });

    return res.json({
      success: true,
      data: {
        salesmanId,
        weekStartDate: weekStartDate.toISOString(),
        dayTotals,
        pincodes: pincodeGroups,
        usesLegacyFallback: !weeklyDelegate,
      },
    });
  } catch (error) {
    console.error('Get weekly assignments view error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

const getPlanningWeekData = async ({ salesmanId, weekStartDate, pincodeFilter = null }) => {
  const weekStart = normalizeWeekStartDate(weekStartDate);
  const weekStartFilter = buildWeekStartDateFilter(weekStart);
  const weekRange = buildWeekRange(weekStart);
  if (!salesmanId || !weekStart) {
    return { error: 'salesmanId and valid weekStartDate are required' };
  }

  if (!weekStartFilter || !weekRange) {
    return { error: 'Unable to normalize weekStartDate for query' };
  }

  const assignedPincodes = await getSalesmanPincodeRows(salesmanId);
  const effectivePincodes = pincodeFilter
    ? assignedPincodes.filter((p) => p === pincodeFilter)
    : assignedPincodes;

  const weeklyDelegate = getWeeklyAssignmentDelegate(prisma);
  if (!weeklyDelegate) {
    return { error: 'Weekly planning is not available on current server build' };
  }

  const [allAccounts, weeklyRows, recurrenceRows] = await Promise.all([
    effectivePincodes.length === 0
      ? Promise.resolve([])
      : prisma.account.findMany({
        where: { pincode: { in: effectivePincodes } },
        orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
      }),
    weeklyDelegate.findMany({
      where: {
        salesmanId,
        weekStartDate: weekStartFilter,
        ...(effectivePincodes.length > 0 ? { pincode: { in: effectivePincodes } } : {}),
      },
      include: { account: true },
      orderBy: [{ pincode: 'asc' }, { sequenceNo: 'asc' }],
    }),
    weeklyDelegate.findMany({
      where: {
        salesmanId,
        AND: [
          {
            OR: [
              { recurrenceStartDate: null },
              { recurrenceStartDate: { lte: weekRange.end } },
            ],
          },
        ],
        ...(effectivePincodes.length > 0 ? { pincode: { in: effectivePincodes } } : {}),
      },
      include: { account: true },
      orderBy: [{ pincode: 'asc' }, { sequenceNo: 'asc' }],
    }),
  ]);

  const byDay = { 1: [], 2: [], 3: [], 4: [], 5: [], 6: [], 7: [] };
  const byPincode = {};
  const plannedAccountIds = new Set();

  const plannedByPincode = new Map();
  const frequencyPriority = (frequency) => {
    if (frequency === VISIT_FREQUENCY.AFTER_DAYS) return 3;
    if (frequency === VISIT_FREQUENCY.MONTHLY) return 2;
    if (frequency === VISIT_FREQUENCY.WEEKLY) return 1;
    return 0;
  };

  const upsertPlanned = ({ row, dueDays, frequency }) => {
    const pin = (row.pincode || '').trim();
    const account = row.account;
    const accountId = account?.id;
    if (!pin || !accountId || !Array.isArray(dueDays) || dueDays.length === 0) return;

    if (!plannedByPincode.has(pin)) plannedByPincode.set(pin, new Map());
    const byAccount = plannedByPincode.get(pin);
    const existing = byAccount.get(accountId);

    if (!existing) {
      byAccount.set(accountId, {
        row,
        account,
        days: new Set(dueDays.filter((d) => d >= 1 && d <= 7)),
        frequency,
      });
      return;
    }

    for (const day of dueDays) {
      if (day >= 1 && day <= 7) existing.days.add(day);
    }

    if (frequencyPriority(frequency) > frequencyPriority(existing.frequency)) {
      existing.row = row;
      existing.frequency = frequency;
    }
  };

  for (const row of weeklyRows) {
    const days = parseAssignedDays(row.assignedDays);
    const frequency = normalizeVisitFrequency(row.visitFrequency, days);
    upsertPlanned({ row, dueDays: days, frequency });
  }

  for (const row of recurrenceRows) {
    const baseDays = parseAssignedDays(row.assignedDays);
    const frequency = normalizeVisitFrequency(row.visitFrequency, baseDays);
    const pin = (row.pincode || '').trim();
    if (!pin) continue;

    if (frequency === VISIT_FREQUENCY.WEEKLY) {
      const dueDays = getDueDaysInWeekForWeekly({
        assignedDays: row.assignedDays,
        recurrenceStartDate: row.recurrenceStartDate || row.weekStartDate,
        weekStartDate: weekStart,
      });
      upsertPlanned({ row, dueDays, frequency });
      continue;
    }

    if (frequency === VISIT_FREQUENCY.MONTHLY) {
      const fallbackAnchorDay = baseDays[0];
      const fallbackAnchorDate = fallbackAnchorDay
        ? getDateForWeekday(row.weekStartDate, fallbackAnchorDay)
        : null;
      const anchorDate = row.recurrenceStartDate || fallbackAnchorDate;
      if (!anchorDate) continue;
      const dueDays = getDueDaysInWeekForMonthly({
        anchorDate,
        weekStartDate: weekStart,
      });
      upsertPlanned({ row, dueDays, frequency });
      continue;
    }

    const after = parseAfterDays(row.recurrenceAfterDays);
    if (!after) continue;
    const fallbackAnchorDay = baseDays[0];
    const fallbackAnchorDate = fallbackAnchorDay
      ? getDateForWeekday(row.weekStartDate, fallbackAnchorDay)
      : null;
    const anchorDate = row.recurrenceStartDate || fallbackAnchorDate;
    if (!anchorDate) continue;
    const dueDays = getDueDaysInWeekForAfterDays({
      anchorDate,
      afterDays: after,
      weekStartDate: weekStart,
    });
    upsertPlanned({ row, dueDays, frequency: VISIT_FREQUENCY.AFTER_DAYS });
  }

  for (const [pin, byAccount] of plannedByPincode.entries()) {
    if (!byPincode[pin]) {
      byPincode[pin] = {
        pincode: pin,
        planned: [],
        unplanned: [],
        dayCounts: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0 },
      };
    }

    for (const item of byAccount.values()) {
      const orderedDays = [...item.days].sort((a, b) => a - b);
      if (orderedDays.length === 0) continue;

      const plannedDto = {
        ...toAccountDtoWithAssignedDays(item.account, orderedDays),
        weekStartDate: weekStart.toISOString(),
        visitFrequency: item.frequency,
        recurrenceAfterDays: item.row.recurrenceAfterDays ?? null,
        recurrenceStartDate: item.row.recurrenceStartDate || null,
        recurrenceNextDate: item.row.recurrenceNextDate || null,
        plannedBy: item.row.plannedBy || null,
        plannedAt: item.row.plannedAt || null,
        isManualOverride: !!item.row.isManualOverride,
        overrideBy: item.row.overrideBy || null,
        overrideReason: item.row.overrideReason || null,
        overriddenAt: item.row.overriddenAt || null,
        sequenceNo: item.row.sequenceNo || 0,
      };

      byPincode[pin].planned.push(plannedDto);
      plannedAccountIds.add(plannedDto.id);

      for (const day of orderedDays) {
        byPincode[pin].dayCounts[day] += 1;
        byDay[day].push(plannedDto);
      }
    }
  }

  for (const account of allAccounts) {
    if (plannedAccountIds.has(account.id)) continue;
    const pin = (account.pincode || '').trim();
    if (!byPincode[pin]) {
      byPincode[pin] = {
        pincode: pin,
        planned: [],
        unplanned: [],
        dayCounts: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0 },
      };
    }
    byPincode[pin].unplanned.push(account);
  }

  const pincodeGroups = (effectivePincodes.length > 0
    ? effectivePincodes
    : Object.keys(byPincode)).map((pin) => {
      const group = byPincode[pin] || {
        pincode: pin,
        planned: [],
        unplanned: [],
        dayCounts: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0 },
      };

      return {
        pincode: pin,
        totalAccounts: group.planned.length + group.unplanned.length,
        plannedAccounts: group.planned.length,
        unplannedAccounts: group.unplanned.length,
        dayCounts: group.dayCounts,
        planned: group.planned,
        unplanned: group.unplanned,
      };
    });

  const summary = {
    totalAccounts: allAccounts.length,
    plannedAccounts: plannedAccountIds.size,
    unplannedAccounts: Math.max(0, allAccounts.length - plannedAccountIds.size),
    frequencyCounts: {
      [VISIT_FREQUENCY.WEEKLY]: 0,
      [VISIT_FREQUENCY.MONTHLY]: 0,
      [VISIT_FREQUENCY.AFTER_DAYS]: 0,
      [VISIT_FREQUENCY.ONCE]: 0,
      [VISIT_FREQUENCY.TWICE]: 0,
      [VISIT_FREQUENCY.THRICE]: 0,
      [VISIT_FREQUENCY.DAILY]: 0,
    },
  };

  for (const pin of Object.keys(byPincode)) {
    for (const planned of byPincode[pin].planned) {
      const freq = normalizeVisitFrequency(planned.visitFrequency, planned.assignedDays);
      if (freq && summary.frequencyCounts[freq] !== undefined) {
        summary.frequencyCounts[freq] += 1;
      }
    }
  }

  return {
    data: {
      salesmanId,
      weekStartDate: weekStart.toISOString(),
      summary,
      byDay,
      pincodes: pincodeGroups,
      dataSource: 'canonical',
    },
  };
};

export const getPlanningWeekView = async (req, res) => {
  try {
    const scope = resolveScopedAssigneeId(req, req.query.salesmanId);
    if (scope.forbidden) {
      return res.status(403).json({
        success: false,
        message: 'You can only access your own planning week data',
      });
    }

    const salesmanId = scope.assigneeId;
    const weekStartDate = req.query.weekStartDate;
    const pincodeFilter = req.query.pincode ? String(req.query.pincode).trim() : null;

    const result = await getPlanningWeekData({
      salesmanId,
      weekStartDate,
      pincodeFilter,
    });

    if (result.error) {
      return res.status(400).json({ success: false, message: result.error });
    }

    return res.json({ success: true, data: result.data });
  } catch (error) {
    console.error('Get planning week view error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

export const assignPlanningWeekAccounts = async (req, res) => {
  try {
    const {
      salesmanId,
      weekStartDate,
      assignments,
      accountIds,
      assignedDays,
      visitFrequency,
      manualOverrideAccountIds = [],
      overrideReason = null,
    } = req.body;

    const effectiveSalesmanId = salesmanId || req.user?.id;
    const actorUserId = req.user?.id || effectiveSalesmanId || null;
    const weekStart = normalizeWeekStartDate(weekStartDate);
    if (!effectiveSalesmanId || !weekStart) {
      return res.status(400).json({ success: false, message: 'salesmanId and valid weekStartDate are required' });
    }

    const weeklyDelegate = getWeeklyAssignmentDelegate(prisma);
    if (!weeklyDelegate) {
      return res.status(500).json({ success: false, message: 'Weekly planning is not available on current server build' });
    }

    const overrideSet = new Set(Array.isArray(manualOverrideAccountIds) ? manualOverrideAccountIds : []);
    const canOverride = hasAdminOverrideAccess(req.user);
    if (!canOverride && overrideSet.size > 0) {
      return res.status(403).json({ success: false, message: 'Override is allowed only for admin/manager/teleadmin users' });
    }

    let normalizedAssignments = [];
    if (Array.isArray(assignments) && assignments.length > 0) {
      normalizedAssignments = assignments.map((entry) => {
        const days = parseAssignedDays(entry.plannedDays || entry.assignedDays || []);
        const frequency = normalizeVisitFrequency(entry.visitFrequency, days);
        return {
          accountId: entry.accountId,
          plannedDays: days,
          visitFrequency: frequency,
        };
      });
    } else {
      const ids = Array.isArray(accountIds) ? [...new Set(accountIds)] : [];
      const days = parseAssignedDays(assignedDays || []);
      const frequency = normalizeVisitFrequency(visitFrequency, days);
      normalizedAssignments = ids.map((id) => ({
        accountId: id,
        plannedDays: days,
        visitFrequency: frequency,
      }));
    }

    normalizedAssignments = normalizedAssignments.filter((a) => !!a.accountId);
    if (normalizedAssignments.length === 0) {
      return res.status(400).json({ success: false, message: 'At least one assignment is required' });
    }

    for (const assignment of normalizedAssignments) {
      const validationError = validateDaysForFrequency(assignment.plannedDays, assignment.visitFrequency);
      if (validationError) {
        return res.status(400).json({
          success: false,
          message: `Invalid assignment for account ${assignment.accountId}: ${validationError}`,
        });
      }
    }

    const allowedPincodes = await getSalesmanPincodeRows(effectiveSalesmanId);

    const result = await prisma.$transaction(async (tx) => {
      const txWeekly = getWeeklyAssignmentDelegate(tx);
      const targetIds = normalizedAssignments.map((a) => a.accountId);

      const [accounts, existingRows, existingSequenceRows] = await Promise.all([
        tx.account.findMany({
          where: { id: { in: targetIds } },
          select: { id: true, pincode: true, createdAt: true },
          orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
        }),
        txWeekly.findMany({
          where: { accountId: { in: targetIds }, weekStartDate: weekStart },
        }),
        txWeekly.findMany({
          where: { salesmanId: effectiveSalesmanId, weekStartDate: weekStart },
          select: { pincode: true, sequenceNo: true },
        }),
      ]);

      const accountMap = new Map(accounts.map((a) => [a.id, a]));
      const existingMap = new Map(existingRows.map((r) => [r.accountId, r]));
      const nextSequenceByPin = {};

      for (const row of existingSequenceRows) {
        const pin = (row.pincode || '').trim();
        nextSequenceByPin[pin] = Math.max(nextSequenceByPin[pin] || 0, row.sequenceNo || 0);
      }

      const createdIds = [];
      const updatedIds = [];

      for (const assignment of normalizedAssignments) {
        const account = accountMap.get(assignment.accountId);
        if (!account) continue;

        const pin = (account.pincode || '').trim();
        if (!pin) continue;
        if (allowedPincodes.length > 0 && !allowedPincodes.includes(pin)) {
          throw new Error(`Account ${assignment.accountId} pincode ${pin} is outside assigned territory`);
        }

        const existing = existingMap.get(assignment.accountId);
        const isOverride = overrideSet.has(assignment.accountId);

        if (!existing) {
          nextSequenceByPin[pin] = (nextSequenceByPin[pin] || 0) + 1;
          await txWeekly.create({
            data: {
              accountId: assignment.accountId,
              salesmanId: effectiveSalesmanId,
              pincode: pin,
              weekStartDate: weekStart,
              assignedDays: assignment.plannedDays,
              visitFrequency: assignment.visitFrequency,
              plannedBy: actorUserId,
              plannedAt: new Date(),
              isManualOverride: isOverride,
              overrideBy: isOverride ? actorUserId : null,
              overrideReason: isOverride ? overrideReason : null,
              overriddenAt: isOverride ? new Date() : null,
              sequenceNo: nextSequenceByPin[pin],
            },
          });
          createdIds.push(assignment.accountId);
        } else {
          await txWeekly.update({
            where: {
              accountId_weekStartDate: {
                accountId: assignment.accountId,
                weekStartDate: weekStart,
              },
            },
            data: {
              salesmanId: effectiveSalesmanId,
              pincode: pin,
              assignedDays: assignment.plannedDays,
              visitFrequency: assignment.visitFrequency,
              plannedBy: actorUserId,
              plannedAt: new Date(),
              isManualOverride: existing.isManualOverride || isOverride,
              overrideBy: (existing.isManualOverride || isOverride) ? actorUserId : existing.overrideBy,
              overrideReason: isOverride ? overrideReason : existing.overrideReason,
              overriddenAt: isOverride ? new Date() : existing.overriddenAt,
            },
          });
          updatedIds.push(assignment.accountId);
        }

        await tx.account.update({
          where: { id: assignment.accountId },
          data: {
            assignedToId: effectiveSalesmanId,
            assignedDays: assignment.plannedDays,
          },
        });
      }

      return {
        createdCount: createdIds.length,
        updatedCount: updatedIds.length,
        totalCount: createdIds.length + updatedIds.length,
      };
    }, { timeout: 30000, maxWait: 30000 });

    return res.json({
      success: true,
      message: `${result.totalCount} account(s) planned successfully`,
      data: {
        ...result,
        overrideReason,
      },
    });
  } catch (error) {
    console.error('Assign planning week accounts error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

export const updatePlanningWeekAccount = async (req, res) => {
  try {
    const { accountId } = req.params;
    const {
      salesmanId,
      weekStartDate,
      plannedDays,
      visitFrequency,
      isOverride = false,
      overrideReason = null,
    } = req.body;

    const effectiveSalesmanId = salesmanId || req.user?.id;
    const actorUserId = req.user?.id || effectiveSalesmanId || null;
    const weekStart = normalizeWeekStartDate(weekStartDate);
    const days = parseAssignedDays(plannedDays || []);
    const frequency = normalizeVisitFrequency(visitFrequency, days);

    if (!accountId || !effectiveSalesmanId || !weekStart) {
      return res.status(400).json({ success: false, message: 'accountId, salesmanId and valid weekStartDate are required' });
    }

    const frequencyError = validateDaysForFrequency(days, frequency);
    if (frequencyError) {
      return res.status(400).json({ success: false, message: frequencyError });
    }

    if (isOverride && !hasAdminOverrideAccess(req.user)) {
      return res.status(403).json({ success: false, message: 'Override is allowed only for admin/manager/teleadmin users' });
    }

    const weeklyDelegate = getWeeklyAssignmentDelegate(prisma);
    if (!weeklyDelegate) {
      return res.status(500).json({ success: false, message: 'Weekly planning is not available on current server build' });
    }

    const account = await prisma.account.findUnique({
      where: { id: accountId },
      select: { id: true, pincode: true },
    });

    if (!account) {
      return res.status(404).json({ success: false, message: 'Account not found' });
    }

    const pincode = String(account.pincode || '').trim();
    if (!pincode) {
      return res.status(400).json({ success: false, message: 'Account pincode is required for weekly planning' });
    }

    await prisma.$transaction(async (tx) => {
      const txWeekly = getWeeklyAssignmentDelegate(tx);
      const existing = await txWeekly.findUnique({
        where: {
          accountId_weekStartDate: {
            accountId,
            weekStartDate: weekStart,
          },
        },
      });

      if (!existing) {
        const existingRows = await txWeekly.findMany({
          where: { salesmanId: effectiveSalesmanId, weekStartDate: weekStart, pincode },
          select: { sequenceNo: true },
        });
        const nextSequence = existingRows.reduce((m, r) => Math.max(m, r.sequenceNo || 0), 0) + 1;

        await txWeekly.create({
          data: {
            accountId,
            salesmanId: effectiveSalesmanId,
            pincode,
            weekStartDate: weekStart,
            assignedDays: days,
            visitFrequency: frequency,
            plannedBy: actorUserId,
            plannedAt: new Date(),
            isManualOverride: !!isOverride,
            overrideBy: isOverride ? actorUserId : null,
            overrideReason: isOverride ? overrideReason : null,
            overriddenAt: isOverride ? new Date() : null,
            sequenceNo: nextSequence,
          },
        });
      } else {
        await txWeekly.update({
          where: {
            accountId_weekStartDate: {
              accountId,
              weekStartDate: weekStart,
            },
          },
          data: {
            salesmanId: effectiveSalesmanId,
            pincode,
            assignedDays: days,
            visitFrequency: frequency,
            plannedBy: actorUserId,
            plannedAt: new Date(),
            isManualOverride: existing.isManualOverride || !!isOverride,
            overrideBy: (existing.isManualOverride || !!isOverride) ? actorUserId : existing.overrideBy,
            overrideReason: isOverride ? overrideReason : existing.overrideReason,
            overriddenAt: isOverride ? new Date() : existing.overriddenAt,
          },
        });
      }

      await tx.account.update({
        where: { id: accountId },
        data: {
          assignedToId: effectiveSalesmanId,
          assignedDays: days,
        },
      });
    }, { timeout: 20000, maxWait: 20000 });

    return res.json({
      success: true,
      message: 'Planning updated successfully',
      data: {
        accountId,
        weekStartDate: weekStart.toISOString(),
        plannedDays: days,
        visitFrequency: frequency,
      },
    });
  } catch (error) {
    console.error('Update planning week account error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

export const getMultiVisitWeekAccounts = async (req, res) => {
  try {
    const salesmanId = req.query.salesmanId || req.user?.id;
    const weekStartDate = req.query.weekStartDate;
    const day = req.query.day ? parseInt(req.query.day, 10) : null;
    const requestedFrequency = normalizeVisitFrequency(req.query.frequency || req.query.visitFrequency, []);
    const allowedFrequencies = new Set([
      VISIT_FREQUENCY.WEEKLY,
      VISIT_FREQUENCY.MONTHLY,
      VISIT_FREQUENCY.AFTER_DAYS,
    ]);

    const result = await getPlanningWeekData({ salesmanId, weekStartDate });
    if (result.error) {
      return res.status(400).json({ success: false, message: result.error });
    }

    let accounts = [];
    for (const entry of Object.values(result.data.byDay)) {
      accounts.push(...entry);
    }

    accounts = [...new Map(accounts.map((a) => [a.id, a])).values()];
    accounts = accounts.filter((a) => allowedFrequencies.has(normalizeVisitFrequency(a.visitFrequency, a.assignedDays)));

    if (requestedFrequency && allowedFrequencies.has(requestedFrequency)) {
      accounts = accounts.filter(
        (a) => normalizeVisitFrequency(a.visitFrequency, a.assignedDays) === requestedFrequency,
      );
    }

    if (day && day >= 1 && day <= 7) {
      accounts = accounts.filter((a) => Array.isArray(a.assignedDays) && a.assignedDays.includes(day));
    }

    return res.json({
      success: true,
      data: {
        salesmanId,
        weekStartDate: normalizeWeekStartDate(weekStartDate).toISOString(),
        day: day || null,
        frequency: requestedFrequency || null,
        total: accounts.length,
        accounts,
      },
    });
  } catch (error) {
    console.error('Get multi-visit week accounts error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

export const getTodayPlannedAccounts = async (req, res) => {
  try {
    const salesmanId = req.query.salesmanId || req.user?.id;
    const today = req.query.date ? new Date(req.query.date) : new Date();
    if (Number.isNaN(today.getTime())) {
      return res.status(400).json({ success: false, message: 'Invalid date' });
    }

    const weekStart = normalizeWeekStartDate(today);
    const weekday = ((today.getDay() + 6) % 7) + 1; // 1=Mon..7=Sun

    const result = await getPlanningWeekData({
      salesmanId,
      weekStartDate: weekStart,
    });

    if (result.error) {
      return res.status(400).json({ success: false, message: result.error });
    }

    const todayAccounts = (result.data.byDay[weekday] || []).map((a) => ({
      ...a,
      visitFrequency: normalizeVisitFrequency(a.visitFrequency, a.assignedDays),
    }));

    const mergedTodayAccounts = [...new Map(todayAccounts.map((a) => [a.id, a])).values()];

    return res.json({
      success: true,
      data: {
        salesmanId,
        date: new Date(today.getFullYear(), today.getMonth(), today.getDate()).toISOString(),
        dayOfWeek: weekday,
        total: mergedTodayAccounts.length,
        accounts: mergedTodayAccounts,
      },
    });
  } catch (error) {
    console.error('Get today planned accounts error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

export const autoAssignNextUnassignedAccounts = async (req, res) => {
  try {
    const { salesmanId, pincode, weekStartDate, day, countN } = req.body;

    const effectiveSalesmanId = salesmanId || req.user?.id;
    const normalizedPin = String(pincode || '').trim();
    const weekStart = normalizeWeekStartDate(weekStartDate);
    const dayInt = parseInt(day, 10);
    const count = parseInt(countN, 10);

    if (!effectiveSalesmanId || !normalizedPin || !weekStart) {
      return res.status(400).json({
        success: false,
        message: 'salesmanId, pincode, and valid weekStartDate are required',
      });
    }

    if (!(dayInt >= 1 && dayInt <= 7) || !(count > 0)) {
      return res.status(400).json({
        success: false,
        message: 'day (1..7) and countN (>0) are required',
      });
    }

    const weeklyDelegate = getWeeklyAssignmentDelegate(prisma);
    if (!weeklyDelegate) {
      const nextAccounts = await prisma.account.findMany({
        where: {
          pincode: normalizedPin,
          OR: [{ assignedDays: null }, { assignedDays: { equals: [] } }],
        },
        orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
        take: count,
      });

      for (const account of nextAccounts) {
        await prisma.account.update({
          where: { id: account.id },
          data: {
            assignedToId: effectiveSalesmanId,
            assignedDays: [dayInt],
          },
        });
      }

      return res.json({
        success: true,
        data: {
          assignedCount: nextAccounts.length,
          assignedAccountIds: nextAccounts.map((a) => a.id),
          remainingRequested: Math.max(0, count - nextAccounts.length),
          usesLegacyFallback: true,
        },
      });
    }

    const result = await prisma.$transaction(async (tx) => {
      const txWeeklyDelegate = getWeeklyAssignmentDelegate(tx);
      const [existingRowsForSalesman, existingRowsForWeekAndPin] = await Promise.all([
        txWeeklyDelegate.findMany({
          where: {
            salesmanId: effectiveSalesmanId,
            weekStartDate: weekStart,
            pincode: normalizedPin,
          },
          select: { accountId: true, sequenceNo: true },
        }),
        txWeeklyDelegate.findMany({
          where: {
            weekStartDate: weekStart,
            pincode: normalizedPin,
          },
          select: { accountId: true },
        }),
      ]);

      const weekTakenIds = existingRowsForWeekAndPin.map((r) => r.accountId);
      const currentSequence = existingRowsForSalesman.reduce(
        (m, r) => Math.max(m, r.sequenceNo || 0),
        0,
      );

      const nextAccounts = await tx.account.findMany({
        where: {
          pincode: normalizedPin,
          ...(weekTakenIds.length > 0 ? { id: { notIn: weekTakenIds } } : {}),
        },
        orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
        take: count,
      });

      let insertedCount = 0;

      if (nextAccounts.length > 0) {
        const createResult = await txWeeklyDelegate.createMany({
          data: nextAccounts.map((account, idx) => ({
            accountId: account.id,
            salesmanId: effectiveSalesmanId,
            pincode: normalizedPin,
            weekStartDate: weekStart,
            assignedDays: [dayInt],
            visitFrequency: VISIT_FREQUENCY.ONCE,
            plannedBy: effectiveSalesmanId,
            plannedAt: new Date(),
            sequenceNo: currentSequence + idx + 1,
            isManualOverride: false,
          })),
          skipDuplicates: true,
        });
        insertedCount = (createResult?.count || 0);

        if (insertedCount > 0) {
          await tx.account.updateMany({
            where: { id: { in: nextAccounts.map((a) => a.id) } },
            data: {
              assignedToId: effectiveSalesmanId,
              assignedDays: [dayInt],
            },
          });
        }
      }

      return {
        assignedCount: insertedCount,
        assignedAccountIds: nextAccounts.map((a) => a.id),
        remainingRequested: Math.max(0, count - insertedCount),
      };
    }, { timeout: 20000, maxWait: 20000 });

    return res.json({ success: true, data: result });
  } catch (error) {
    console.error('Auto assign next unassigned accounts error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

export const manualAssignWeeklyAccounts = async (req, res) => {
  try {
    const {
      salesmanId,
      weekStartDate,
      accountIds,
      assignedDays,
      visitFrequency,
      afterDays,
      monthlyAnchorDate,
      manualOverrideAccountIds = [],
      overrideReason = null,
    } = req.body;

    const scope = resolveScopedAssigneeId(req, salesmanId);
    if (scope.forbidden) {
      return res.status(403).json({
        success: false,
        message: 'You can only assign weekly accounts for your own user',
      });
    }

    const effectiveSalesmanId = scope.assigneeId;
    const actorUserId = req.user?.id || effectiveSalesmanId || null;
    const weekStart = normalizeWeekStartDate(weekStartDate);
    const accountIdList = Array.isArray(accountIds) ? [...new Set(accountIds)] : [];
    const days = parseAssignedDays(assignedDays);
    const incomingFrequency = normalizeVisitFrequency(visitFrequency, days);
    const normalizedAfterDays = parseAfterDays(afterDays);
    const normalizedMonthlyAnchorDate = toStartOfDay(monthlyAnchorDate);
    const normalizedFrequency = normalizedAfterDays
      ? VISIT_FREQUENCY.AFTER_DAYS
      : (incomingFrequency === VISIT_FREQUENCY.MONTHLY
        ? VISIT_FREQUENCY.MONTHLY
        : VISIT_FREQUENCY.WEEKLY);
    const frequencyError = validateDaysForFrequency(days, normalizedFrequency);
    const isSingleDayMode = days.length === 1;
    const isMonthlyMode = normalizedFrequency === VISIT_FREQUENCY.MONTHLY;
    const singleDay = isSingleDayMode ? days[0] : null;
    const recurrenceStartDate = isMonthlyMode
      ? (normalizedMonthlyAnchorDate || getDateForWeekday(weekStart, singleDay))
      : (normalizedAfterDays
        ? getDateForWeekday(weekStart, singleDay)
        : weekStart);
    const recurrenceNextDate = normalizedAfterDays
      ? computeFirstRecurrenceDate(recurrenceStartDate, normalizedAfterDays)
      : null;
    const overrideSet = new Set(Array.isArray(manualOverrideAccountIds) ? manualOverrideAccountIds : []);

    if (!effectiveSalesmanId || !weekStart || accountIdList.length === 0 || days.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'salesmanId, valid weekStartDate, accountIds, and assignedDays are required',
      });
    }

    if (frequencyError) {
      return res.status(400).json({ success: false, message: frequencyError });
    }

    if (afterDays !== undefined && normalizedAfterDays === null) {
      return res.status(400).json({
        success: false,
        message: 'afterDays must be a positive integer',
      });
    }

    if (isMonthlyMode && monthlyAnchorDate !== undefined && monthlyAnchorDate !== null && !normalizedMonthlyAnchorDate) {
      return res.status(400).json({
        success: false,
        message: 'monthlyAnchorDate must be a valid date',
      });
    }

    if (normalizedAfterDays && !isSingleDayMode) {
      return res.status(400).json({
        success: false,
        message: 'After Days requires exactly one selected day',
      });
    }

    const weeklyDelegate = getWeeklyAssignmentDelegate(prisma);
    if (!weeklyDelegate) {
      const accounts = await prisma.account.findMany({
        where: { id: { in: accountIdList } },
        select: { id: true, assignedDays: true },
      });

      const blockedAccountIds = [];
      for (const account of accounts) {
        const existingDays = parseAssignedDays(account.assignedDays || []);
        const mergedDays = isSingleDayMode
          ? [singleDay]
          : [...new Set([...existingDays, ...days])];
        const isAddingNewDay = mergedDays.length > existingDays.length;
        if (!isSingleDayMode && isAddingNewDay && !overrideSet.has(account.id)) {
          blockedAccountIds.push(account.id);
        }
      }

      if (blockedAccountIds.length > 0) {
        return res.status(409).json({
          success: false,
          message: 'Some accounts are already assigned. Use manual override for multi-day assignment.',
          blockedAccountIds,
        });
      }

      for (const account of accounts) {
        const existingDays = parseAssignedDays(account.assignedDays || []);
        const mergedDays = isSingleDayMode
          ? [singleDay]
          : [...new Set([...existingDays, ...days])];
        await prisma.account.update({
          where: { id: account.id },
          data: {
            assignedToId: effectiveSalesmanId,
            assignedDays: mergedDays,
          },
        });
      }

      return res.json({
        success: true,
        message: `${accounts.length} account(s) assigned (legacy mode)`,
        count: accounts.length,
        usesLegacyFallback: true,
      });
    }

    const result = await prisma.$transaction(async (tx) => {
      const txWeeklyDelegate = getWeeklyAssignmentDelegate(tx);
      const [accounts, existingRows, existingSequenceRows] = await Promise.all([
        tx.account.findMany({
          where: { id: { in: accountIdList } },
          select: { id: true, pincode: true, createdAt: true },
          orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
        }),
        txWeeklyDelegate.findMany({
          where: {
            accountId: { in: accountIdList },
            weekStartDate: weekStart,
          },
        }),
        txWeeklyDelegate.findMany({
          where: {
            salesmanId: effectiveSalesmanId,
            weekStartDate: weekStart,
          },
          select: { pincode: true, sequenceNo: true },
        }),
      ]);

      const accountMap = new Map(accounts.map((a) => [a.id, a]));
      const existingMap = new Map(existingRows.map((r) => [r.accountId, r]));
      const nextSequenceByPin = {};

      for (const row of existingSequenceRows) {
        const pin = (row.pincode || '').trim();
        nextSequenceByPin[pin] = Math.max(nextSequenceByPin[pin] || 0, row.sequenceNo || 0);
      }

      const blockedAccountIds = [];
      const upsertTargets = [];

      for (const accountId of accountIdList) {
        const account = accountMap.get(accountId);
        if (!account) continue;

        const pin = (account.pincode || '').trim();
        if (!pin) continue;

        const existing = existingMap.get(accountId);
        const existingDays = parseAssignedDays(existing?.assignedDays || []);
        const mergedDays = isSingleDayMode
          ? [singleDay]
          : [...new Set([...existingDays, ...days])];

        const isAddingNewDay = mergedDays.length > existingDays.length;
        if (!isSingleDayMode && existing && isAddingNewDay && !overrideSet.has(accountId)) {
          blockedAccountIds.push(accountId);
          continue;
        }

        if (!existing) {
          nextSequenceByPin[pin] = (nextSequenceByPin[pin] || 0) + 1;
        }

        upsertTargets.push({
          accountId,
          pincode: pin,
          mergedDays,
          existing,
          isManualOverride: overrideSet.has(accountId),
          sequenceNo: existing ? existing.sequenceNo : nextSequenceByPin[pin],
        });
      }

      if (blockedAccountIds.length > 0) {
        return {
          blockedAccountIds,
          upsertedCount: 0,
        };
      }

      const createTargets = upsertTargets.filter((t) => !t.existing);
      const updateTargets = upsertTargets.filter((t) => t.existing);

      if (createTargets.length > 0) {
        await txWeeklyDelegate.createMany({
          data: createTargets.map((target) => ({
            accountId: target.accountId,
            salesmanId: effectiveSalesmanId,
            pincode: target.pincode,
            weekStartDate: weekStart,
            assignedDays: target.mergedDays,
            visitFrequency: normalizedFrequency,
            recurrenceAfterDays: normalizedAfterDays,
            recurrenceStartDate,
            recurrenceNextDate,
            plannedBy: actorUserId,
            plannedAt: new Date(),
            isManualOverride: target.isManualOverride,
            overrideBy: target.isManualOverride ? actorUserId : null,
            overrideReason: target.isManualOverride ? overrideReason : null,
            overriddenAt: target.isManualOverride ? new Date() : null,
            sequenceNo: target.sequenceNo,
          })),
          skipDuplicates: true,
        });
      }

      for (const target of updateTargets) {
        await txWeeklyDelegate.update({
          where: {
            accountId_weekStartDate: {
              accountId: target.accountId,
              weekStartDate: weekStart,
            },
          },
          data: {
            salesmanId: effectiveSalesmanId,
            pincode: target.pincode,
            assignedDays: target.mergedDays,
            visitFrequency: normalizedFrequency,
            recurrenceAfterDays: normalizedAfterDays,
            recurrenceStartDate,
            recurrenceNextDate,
            plannedBy: actorUserId,
            plannedAt: new Date(),
            isManualOverride:
              (target.existing?.isManualOverride || false) || target.isManualOverride,
            overrideBy: ((target.existing?.isManualOverride || false) || target.isManualOverride)
              ? actorUserId
              : target.existing?.overrideBy,
            overrideReason: target.isManualOverride ? overrideReason : target.existing?.overrideReason,
            overriddenAt: target.isManualOverride ? new Date() : target.existing?.overriddenAt,
          },
        });
      }

      return {
        blockedAccountIds: [],
        upsertedCount: upsertTargets.length,
      };
    }, { timeout: 30000, maxWait: 30000 });

    if (result.blockedAccountIds.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Some accounts are already assigned in this week. Use manual override for multi-day assignment.',
        blockedAccountIds: result.blockedAccountIds,
      });
    }

    return res.json({
      success: true,
      message: `${result.upsertedCount} account(s) assigned with recurrence`,
      count: result.upsertedCount,
      visitFrequency: normalizedFrequency,
      recurrenceAfterDays: normalizedAfterDays,
      recurrenceStartDate: recurrenceStartDate ? recurrenceStartDate.toISOString() : null,
      recurrenceNextDate: recurrenceNextDate ? recurrenceNextDate.toISOString() : null,
    });
  } catch (error) {
    console.error('Manual assign weekly accounts error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

export const unassignWeeklyAccountsGlobal = async (req, res) => {
  try {
    const { salesmanId, accountIds } = req.body;

    const scope = resolveScopedAssigneeId(req, salesmanId);
    if (scope.forbidden) {
      return res.status(403).json({
        success: false,
        message: 'You can only unassign weekly accounts for your own user',
      });
    }

    const effectiveSalesmanId = scope.assigneeId;
    const accountIdList = Array.isArray(accountIds)
      ? [...new Set(accountIds.map((id) => String(id || '').trim()).filter(Boolean))]
      : [];

    if (!effectiveSalesmanId || accountIdList.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'salesmanId and accountIds are required',
      });
    }

    const result = await prisma.$transaction(async (tx) => {
      const txWeeklyDelegate = getWeeklyAssignmentDelegate(tx);
      const salesmanPins = await getSalesmanPincodeRows(effectiveSalesmanId);
      const allowedPinSet = new Set(salesmanPins.map((p) => String(p || '').trim()).filter(Boolean));

      const accounts = await tx.account.findMany({
        where: { id: { in: accountIdList } },
        select: {
          id: true,
          pincode: true,
          assignedToId: true,
          assignedDays: true,
        },
      });

      const accountMap = new Map(accounts.map((a) => [a.id, a]));
      const inScopeAccounts = [];
      const missingAccountIds = [];
      const outOfScopeAccountIds = [];

      for (const accountId of accountIdList) {
        const account = accountMap.get(accountId);
        if (!account) {
          missingAccountIds.push(accountId);
          continue;
        }

        const pin = String(account.pincode || '').trim();
        const scopedByPin = pin.length > 0 && allowedPinSet.has(pin);
        const scopedByAssignment = account.assignedToId === effectiveSalesmanId;

        if (!scopedByPin && !scopedByAssignment) {
          outOfScopeAccountIds.push(accountId);
          continue;
        }

        inScopeAccounts.push(account);
      }

      const inScopeIds = inScopeAccounts.map((a) => a.id);
      if (inScopeIds.length === 0) {
        return {
          requestedCount: accountIdList.length,
          inScopeCount: 0,
          unassignedCount: 0,
          alreadyUnassignedCount: 0,
          missingAccountIds,
          outOfScopeAccountIds,
          unassignedAccountIds: [],
          alreadyUnassignedAccountIds: [],
          deletedWeeklyRows: 0,
        };
      }

      const weeklyAssignedIdSet = new Set();
      let deletedWeeklyRows = 0;

      if (txWeeklyDelegate) {
        const weeklyRows = await txWeeklyDelegate.findMany({
          where: {
            salesmanId: effectiveSalesmanId,
            accountId: { in: inScopeIds },
          },
          select: { accountId: true },
        });

        for (const row of weeklyRows) {
          weeklyAssignedIdSet.add(row.accountId);
        }

        const deleted = await txWeeklyDelegate.deleteMany({
          where: {
            salesmanId: effectiveSalesmanId,
            accountId: { in: inScopeIds },
          },
        });
        deletedWeeklyRows = deleted?.count || 0;
      }

      const hadAssignmentAccountIds = [];
      const alreadyUnassignedAccountIds = [];

      for (const account of inScopeAccounts) {
        const hadWeekly = weeklyAssignedIdSet.has(account.id);
        const hadLegacyDays = parseAssignedDays(account.assignedDays || []).length > 0;
        const hadAssignmentOwner = account.assignedToId === effectiveSalesmanId;

        if (hadWeekly || hadLegacyDays || hadAssignmentOwner) {
          hadAssignmentAccountIds.push(account.id);
        } else {
          alreadyUnassignedAccountIds.push(account.id);
        }
      }

      const idsAssignedToSalesman = inScopeAccounts
        .filter((a) => a.assignedToId === effectiveSalesmanId)
        .map((a) => a.id);
      const idsNotAssignedToSalesman = inScopeAccounts
        .filter((a) => a.assignedToId !== effectiveSalesmanId)
        .map((a) => a.id);

      if (idsAssignedToSalesman.length > 0) {
        await tx.account.updateMany({
          where: { id: { in: idsAssignedToSalesman } },
          data: {
            assignedToId: null,
            assignedDays: [],
          },
        });
      }

      if (idsNotAssignedToSalesman.length > 0) {
        await tx.account.updateMany({
          where: { id: { in: idsNotAssignedToSalesman } },
          data: {
            assignedDays: [],
          },
        });
      }

      return {
        requestedCount: accountIdList.length,
        inScopeCount: inScopeIds.length,
        unassignedCount: hadAssignmentAccountIds.length,
        alreadyUnassignedCount: alreadyUnassignedAccountIds.length,
        missingAccountIds,
        outOfScopeAccountIds,
        unassignedAccountIds: hadAssignmentAccountIds,
        alreadyUnassignedAccountIds,
        deletedWeeklyRows,
      };
    }, { timeout: 30000, maxWait: 30000 });

    return res.json({
      success: true,
      message: `${result.unassignedCount} account(s) unassigned`,
      data: result,
    });
  } catch (error) {
    console.error('Global unassign weekly accounts error:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

export const bulkApproveAccounts = async (req, res) => {
  try {
    const { accountIds } = req.body;
    const approvedById = req.user?.id || req.body.approvedById;

    if (!accountIds || !Array.isArray(accountIds) || accountIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'accountIds array is required'
      });
    }

    if (!approvedById) {
      return res.status(400).json({
        success: false,
        message: 'Approver ID is required'
      });
    }

    const result = await prisma.account.updateMany({
      where: {
        id: { in: accountIds }
      },
      data: {
        isApproved: true,
        approvedById,
        approvedAt: new Date()
      }
    });

    res.json({
      success: true,
      message: `${result.count} accounts approved successfully`,
      count: result.count
    });
  } catch (error) {
    console.error('Bulk approve accounts error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// ==================== DEBUG ENDPOINT (REMOVE IN PRODUCTION) ====================

export const debugDateFiltering = async (req, res) => {
  try {
    const { startDate, endDate, period } = req.query;

    console.log('🐛 DEBUG: Date filtering test');
    console.log('   Raw startDate:', startDate);
    console.log('   Raw endDate:', endDate);
    console.log('   Period:', period);

    const where = {};

    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) {
        const start = new Date(startDate);
        where.createdAt.gte = start;
        console.log('   Parsed startDate:', start.toISOString());
      }
      if (endDate) {
        const end = new Date(endDate);
        where.createdAt.lte = end;
        console.log('   Parsed endDate:', end.toISOString());
      }
    }

    const accounts = await prisma.account.findMany({
      where,
      take: 5,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        personName: true,
        createdAt: true
      }
    });

    console.log('   Found accounts:', accounts.length);
    accounts.forEach(account => {
      console.log(`     - ${account.personName}: ${account.createdAt.toISOString()}`);
    });

    res.json({
      success: true,
      debug: {
        rawStartDate: startDate,
        rawEndDate: endDate,
        parsedStartDate: startDate ? new Date(startDate).toISOString() : null,
        parsedEndDate: endDate ? new Date(endDate).toISOString() : null,
        whereClause: where,
        accountsFound: accounts.length,
        accounts: accounts.map(a => ({
          name: a.personName,
          createdAt: a.createdAt.toISOString()
        }))
      }
    });
  } catch (error) {
    console.error('Debug date filtering error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const checkContactNumber = async (req, res) => {
  try {
    const { contactNumber } = req.body;

    if (!contactNumber) {
      return res.status(400).json({
        success: false,
        message: 'Contact number is required'
      });
    }

    // Validate contact number format (10 digits)
    if (!/^\d{10}$/.test(contactNumber)) {
      return res.status(400).json({
        success: false,
        message: 'Contact number must be exactly 10 digits'
      });
    }

    // Check if contact number exists
    const existingAccount = await prisma.account.findFirst({
      where: { contactNumber },
      select: {
        id: true,
        accountCode: true,
        businessName: true,
        personName: true,
        contactNumber: true
      }
    });

    if (existingAccount) {
      return res.json({
        success: true,
        exists: true,
        message: 'Contact number already exists',
        data: existingAccount
      });
    }

    res.json({
      success: true,
      exists: false,
      message: 'Contact number is available'
    });
  } catch (error) {
    console.error('Check contact number error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};
