import prisma from '../config/db.js';

/**
 * Generate sequential user ID in format: 00001, 00002, 00003, etc.
 * This function ensures consistency across all user creation flows.
 */
export async function generateSequentialUserId() {
  try {
    // Find all users and extract numeric IDs only
    const allUsers = await prisma.user.findMany({
      select: { id: true },
    });

    // Filter only numeric IDs and convert to numbers
    const numericIds = allUsers
      .map(u => {
        const parsed = parseInt(u.id);
        return isNaN(parsed) ? null : parsed;
      })
      .filter(id => id !== null);

    // Find the highest numeric ID, or start from 0
    const maxId = numericIds.length > 0 ? Math.max(...numericIds) : 0;

    // Generate next ID
    const nextId = maxId + 1;

    // Format as 5 digits (e.g., 00001, 00002)
    const formattedId = String(nextId).padStart(5, '0');

    console.log(`🆔 Generated sequential user ID: ${formattedId} (next after ${maxId})`);
    return formattedId;

  } catch (error) {
    console.error('❌ Error generating sequential user ID:', error);
    // Fallback: use timestamp-based ID
    const timestamp = Date.now();
    const fallbackId = String(timestamp % 100000).padStart(5, '0');
    console.log(`⚠️ Using fallback ID: ${fallbackId}`);
    return fallbackId;
  }
}

/**
 * Generate sequential employee code in format: 00001, 00002, 00003, etc.
 * This function ensures consistency across all user creation flows.
 */
export async function generateSequentialEmployeeCode() {
  try {
    // Find all users with employee codes
    const allUsers = await prisma.user.findMany({
      where: { employeeCode: { not: null } },
      select: { employeeCode: true },
    });

    // Filter only numeric employee codes and convert to numbers
    const numericCodes = allUsers
      .map(u => {
        const parsed = parseInt(u.employeeCode);
        return isNaN(parsed) ? null : parsed;
      })
      .filter(code => code !== null);

    // Find the highest numeric code, or start from 0
    const maxCode = numericCodes.length > 0 ? Math.max(...numericCodes) : 0;

    // Generate next code
    const nextCode = maxCode + 1;

    // Format as 5 digits (e.g., 00001, 00002)
    const formattedCode = String(nextCode).padStart(5, '0');

    console.log(`👔 Generated sequential employee code: ${formattedCode} (next after ${maxCode})`);
    return formattedCode;

  } catch (error) {
    console.error('❌ Error generating sequential employee code:', error);
    // Fallback: use timestamp-based code
    const timestamp = Date.now();
    const fallbackCode = String(timestamp % 100000).padStart(5, '0');
    console.log(`⚠️ Using fallback employee code: ${fallbackCode}`);
    return fallbackCode;
  }
}

/**
 * Generate both user ID and employee code in one call for consistency
 */
export async function generateUserIdentifiers() {
  const userId = await generateSequentialUserId();
  const employeeCode = await generateSequentialEmployeeCode();
  
  console.log(`🎯 Generated user identifiers - ID: ${userId}, Employee Code: ${employeeCode}`);
  
  return { userId, employeeCode };
}