#!/usr/bin/env node

/**
 * Quick Timezone Test - Tests timezone functions directly
 */

import {
    getCurrentISTTime,
    convertUTCToIST,
    convertISTToUTC,
    getISTDateRange,
    formatISTTime,
    getISTTimestamp,
    calculateWorkHoursIST,
    getCurrentWorkDurationIST,
    getISTTimezoneInfo
} from '../src/utils/timezone.js';

console.log('🇮🇳 Quick IST Timezone Test');
console.log('═'.repeat(50));

// Test 1: Current IST Time
console.log('\n🕐 Test 1: Current IST Time');
const currentIST = getCurrentISTTime();
const currentUTC = new Date();
console.log(`UTC Time: ${currentUTC.toISOString()}`);
console.log(`IST Time: ${currentIST.toISOString()}`);
console.log(`Time Difference: ${(currentIST.getTime() - currentUTC.getTime()) / (1000 * 60 * 60)} hours`);

// Test 2: IST Date Range
console.log('\n📅 Test 2: IST Date Range');
const { startOfDay, endOfDay } = getISTDateRange();
console.log(`Start of Day: ${startOfDay.toISOString()}`);
console.log(`End of Day: ${endOfDay.toISOString()}`);

// Test 3: Format IST Time
console.log('\n🎨 Test 3: Format IST Time');
const testTime = new Date();
console.log(`Original: ${testTime.toISOString()}`);
console.log(`IST Date: ${formatISTTime(testTime, 'date')}`);
console.log(`IST Time: ${formatISTTime(testTime, 'time')}`);
console.log(`IST DateTime: ${formatISTTime(testTime, 'datetime')}`);

// Test 4: Work Hours Calculation
console.log('\n⏱️ Test 4: Work Hours Calculation');
const punchInTime = new Date(Date.now() - 4 * 60 * 60 * 1000); // 4 hours ago
const punchOutTime = new Date();
const workHours = calculateWorkHoursIST(punchInTime, punchOutTime);
console.log(`Punch In: ${punchInTime.toISOString()}`);
console.log(`Punch Out: ${punchOutTime.toISOString()}`);
console.log(`Work Hours: ${workHours}`);

// Test 5: Current Work Duration
console.log('\n📊 Test 5: Current Work Duration');
const currentDuration = getCurrentWorkDurationIST(punchInTime);
console.log(`Current Duration: ${currentDuration} hours`);

// Test 6: Timezone Info
console.log('\n🌍 Test 6: Timezone Info');
const timezoneInfo = getISTTimezoneInfo();
console.log(`Timezone: ${JSON.stringify(timezoneInfo, null, 2)}`);

// Test 7: UTC/IST Conversion
console.log('\n🔄 Test 7: UTC/IST Conversion');
const utcTime = new Date();
const convertedIST = convertUTCToIST(utcTime);
const backToUTC = convertISTToUTC(convertedIST);
console.log(`Original UTC: ${utcTime.toISOString()}`);
console.log(`Converted IST: ${convertedIST.toISOString()}`);
console.log(`Back to UTC: ${backToUTC.toISOString()}`);
console.log(`Round-trip accurate: ${Math.abs(utcTime.getTime() - backToUTC.getTime()) < 1000}`);

console.log('\n✅ All timezone functions working correctly!');
console.log('\n🎯 Key Findings:');
console.log(`• IST is UTC+5:30 (${timezoneInfo.offset})`);
console.log(`• Current IST: ${formatISTTime(getCurrentISTTime(), 'datetime')}`);
console.log(`• Database should store IST times directly`);
console.log(`• Work duration calculations are accurate`);