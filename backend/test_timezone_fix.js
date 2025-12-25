/**
 * Test script to verify timezone fix for punch-in time mismatch
 */

import {
    getCurrentISTTime,
    convertUTCToIST,
    convertISTToUTC,
    formatISTTime,
    getISTDateRange
} from './src/utils/timezone.js';

console.log('🧪 Testing Timezone Fix for Punch-In Time Mismatch');
console.log('='.repeat(60));

// Simulate the old behavior (storing IST as if it were UTC)
const currentIST = getCurrentISTTime();
console.log('1. Current IST Time:', formatISTTime(currentIST, 'datetime'));

// New behavior: Convert IST to UTC for storage
const utcForStorage = convertISTToUTC(currentIST);
console.log('2. UTC Time for Database Storage:', utcForStorage.toISOString());

// When reading from database, convert back to IST for display
const istForDisplay = convertUTCToIST(utcForStorage);
console.log('3. IST Time for Display:', formatISTTime(istForDisplay, 'datetime'));

// Verify they match
const timesMatch = Math.abs(currentIST.getTime() - istForDisplay.getTime()) < 1000; // Within 1 second
console.log('4. Times Match:', timesMatch ? '✅ YES' : '❌ NO');

console.log('\n📅 Testing Date Range for Database Queries:');
const { startOfDay, endOfDay } = getISTDateRange();
console.log('Start of Day (UTC for DB):', startOfDay.toISOString());
console.log('End of Day (UTC for DB):', endOfDay.toISOString());
console.log('Start of Day (IST Display):', formatISTTime(convertUTCToIST(startOfDay), 'datetime'));
console.log('End of Day (IST Display):', formatISTTime(convertUTCToIST(endOfDay), 'datetime'));

console.log('\n🎯 Expected Result:');
console.log('- Backend stores UTC timestamps in database');
console.log('- Frontend receives UTC timestamps and displays them correctly in local time');
console.log('- No more 5.5 hour offset mismatch');
console.log('- Punch-in time and created time should now be consistent');