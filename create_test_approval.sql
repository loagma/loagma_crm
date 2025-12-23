-- Create a test approval request for EMP001 with code 108767
-- First, delete any existing requests for today
DELETE FROM "LatePunchApproval" 
WHERE "employeeId" = 'EMP001' 
AND "requestDate" >= CURRENT_DATE 
AND "requestDate" < CURRENT_DATE + INTERVAL '1 day';

-- Insert a new approved request
INSERT INTO "LatePunchApproval" (
    id,
    "employeeId",
    "employeeName",
    "requestDate",
    "punchInDate",
    reason,
    status,
    "approvedBy",
    "approvedAt",
    "adminRemarks",
    "approvalCode",
    "codeExpiresAt",
    "codeUsed",
    "createdAt",
    "updatedAt"
) VALUES (
    'test_' || extract(epoch from now())::text,
    'EMP001',
    'Test Employee',
    NOW(),
    NOW(),
    'Testing OTP flow - traffic jam caused delay',
    'APPROVED',
    'ADMIN001',
    NOW(),
    'Approved for testing OTP flow',
    '108767',
    NOW() + INTERVAL '2 hours',
    false,
    NOW(),
    NOW()
);

-- Verify the insert
SELECT * FROM "LatePunchApproval" WHERE "employeeId" = 'EMP001' AND "approvalCode" = '108767';