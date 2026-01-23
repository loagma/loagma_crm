import prisma from '../config/db.js';

/**
 * Cascade delete all user-related data
 * This function handles all relations that need manual cleanup before user deletion
 * Relations with onDelete: Cascade are automatically handled by Prisma
 * 
 * @param {string} userId - The ID of the user to delete
 * @param {object} tx - Prisma transaction client (optional, uses prisma if not provided)
 * @returns {Promise<object>} Summary of deleted/updated records
 */
export async function cascadeDeleteUser(userId, tx = null) {
  const client = tx || prisma;
  
  const summary = {
    accountsUpdated: 0,
    expensesUpdated: 0,
    lateApprovalsUpdated: 0,
    earlyApprovalsUpdated: 0,
    leavesUpdated: 0,
    beatPlansUpdated: 0,
    beatCompletionsUpdated: 0,
    cascadeDeleted: {
      employeeArea: 0,
      salaryInformation: 0,
      expenses: 0,
      areaAssignments: 0,
      notifications: 0,
      lateApprovals: 0,
      earlyApprovals: 0,
      leaves: 0,
      leaveBalance: 0,
      beatPlans: 0,
      beatCompletions: 0,
      trackingPoints: 0,
    },
  };

  // 1. Handle Account relations (set foreign keys to null instead of deleting accounts)
  const accountsResult = await client.account.updateMany({
    where: {
      OR: [
        { assignedToId: userId },
        { createdById: userId },
        { approvedById: userId },
      ],
    },
    data: {
      assignedToId: null,
      createdById: null,
      approvedById: null,
    },
  });
  summary.accountsUpdated = accountsResult.count;

  // 2. Handle Expense approver relations (set approvedBy to null)
  const expensesResult = await client.expense.updateMany({
    where: { approvedBy: userId },
    data: { approvedBy: null },
  });
  summary.expensesUpdated = expensesResult.count;

  // 3. Handle LatePunchApproval approver relations
  const lateApprovalsResult = await client.latePunchApproval.updateMany({
    where: { approvedBy: userId },
    data: { approvedBy: null },
  });
  summary.lateApprovalsUpdated = lateApprovalsResult.count;

  // 4. Handle EarlyPunchOutApproval approver relations
  const earlyApprovalsResult = await client.earlyPunchOutApproval.updateMany({
    where: { approvedBy: userId },
    data: { approvedBy: null },
  });
  summary.earlyApprovalsUpdated = earlyApprovalsResult.count;

  // 5. Handle Leave approver relations
  const leavesResult = await client.leave.updateMany({
    where: { approvedBy: userId },
    data: { approvedBy: null },
  });
  summary.leavesUpdated = leavesResult.count;

  // 6. Handle WeeklyBeatPlan generator/approver/locker relations
  const beatPlansResult = await client.weeklyBeatPlan.updateMany({
    where: {
      OR: [
        { generatedBy: userId },
        { approvedBy: userId },
        { lockedBy: userId },
      ],
    },
    data: {
      generatedBy: null,
      approvedBy: null,
      lockedBy: null,
    },
  });
  summary.beatPlansUpdated = beatPlansResult.count;

  // 7. Handle BeatCompletion verifier relations
  const beatCompletionsResult = await client.beatCompletion.updateMany({
    where: { verifiedBy: userId },
    data: { verifiedBy: null },
  });
  summary.beatCompletionsUpdated = beatCompletionsResult.count;

  // 8. Count cascade-deleted records (for logging)
  // These will be automatically deleted by Prisma due to onDelete: Cascade
  summary.cascadeDeleted.employeeArea = await client.employeeArea.count({ 
    where: { employeeId: userId } 
  });
  summary.cascadeDeleted.salaryInformation = await client.salaryInformation.count({ 
    where: { employeeId: userId } 
  });
  summary.cascadeDeleted.expenses = await client.expense.count({ 
    where: { employeeId: userId } 
  });
  summary.cascadeDeleted.areaAssignments = await client.areaAssignment.count({ 
    where: { salesmanId: userId } 
  });
  summary.cascadeDeleted.notifications = await client.notification.count({ 
    where: { targetUserId: userId } 
  });
  summary.cascadeDeleted.lateApprovals = await client.latePunchApproval.count({ 
    where: { employeeId: userId } 
  });
  summary.cascadeDeleted.earlyApprovals = await client.earlyPunchOutApproval.count({ 
    where: { employeeId: userId } 
  });
  summary.cascadeDeleted.leaves = await client.leave.count({ 
    where: { employeeId: userId } 
  });
  summary.cascadeDeleted.leaveBalance = await client.leaveBalance.count({ 
    where: { employeeId: userId } 
  });
  summary.cascadeDeleted.beatPlans = await client.weeklyBeatPlan.count({ 
    where: { salesmanId: userId } 
  });
  summary.cascadeDeleted.beatCompletions = await client.beatCompletion.count({ 
    where: { salesmanId: userId } 
  });
  summary.cascadeDeleted.trackingPoints = await client.salesmanTrackingPoint.count({ 
    where: { employeeId: userId } 
  });

  return summary;
}
