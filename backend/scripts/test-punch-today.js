#!/usr/bin/env node

/**
 * Test Punch System Today - Direct database test
 */

import '../src/config/env.js';
import { PrismaClient } from '@prisma/client';
import {
    getCurrentISTTime,
    getISTDateRange,
    formatISTTime,
    calculateWorkHoursIST,
    getCurrentWorkDurationIST,
    getISTTimezoneInfo
} from '../src/utils/timezone.js';

const prisma = new PrismaClient();

const TEST_EMPLOYEE_ID = 'test-punch-001';
const TEST_EMPLOYEE_NAME = 'Test Punch Employee';

// Test coordinates (Mumbai, India)
const TEST_COORDINATES = {
  latitude: 19.0760,
  longitude: 72.8777,
  address: 'Mumbai, Maharashtra, India'
};

async function testPunchSystem() {
    console.log('🥊 Testing Punch System with IST Timezone');
    console.log('═'.repeat(50));
    
    try {
        // Test database connection
        console.log('\n🔌 Testing database connection...');
        await prisma.$connect();
        console.log('✅ Database connected successfully');
        
        // Get current IST time and date range
        const currentISTTime = getCurrentISTTime();
        const { startOfDay, endOfDay } = getISTDateRange();
        
        console.log('\n🕐 Current Time Information:');
        console.log(`Current IST: ${formatISTTime(currentISTTime, 'datetime')}`);
        console.log(`Start of Day: ${startOfDay.toISOString()}`);
        console.log(`End of Day: ${endOfDay.toISOString()}`);
        
        // Check for existing active attendance
        console.log('\n🔍 Checking for active attendance...');
        const activeAttendance = await prisma.attendance.findFirst({
            where: {
                employeeId: TEST_EMPLOYEE_ID,
                status: 'active'
            }
        });
        
        if (activeAttendance) {
            console.log(`⚠️ Found active attendance: ${activeAttendance.id}`);
            console.log(`Punch In Time: ${formatISTTime(activeAttendance.punchInTime, 'datetime')}`);
            
            // Calculate current work duration
            const currentDuration = getCurrentWorkDurationIST(activeAttendance.punchInTime);
            console.log(`Current Work Duration: ${currentDuration.toFixed(2)} hours`);
            
            // Punch out
            console.log('\n🚪 Punching out...');
            const punchOutTime = getCurrentISTTime();
            const workHours = calculateWorkHoursIST(activeAttendance.punchInTime, punchOutTime);
            
            const updatedAttendance = await prisma.attendance.update({
                where: { id: activeAttendance.id },
                data: {
                    punchOutTime: punchOutTime,
                    punchOutLatitude: TEST_COORDINATES.latitude,
                    punchOutLongitude: TEST_COORDINATES.longitude,
                    punchOutAddress: TEST_COORDINATES.address,
                    totalWorkHours: workHours,
                    status: 'completed'
                }
            });
            
            console.log('✅ Punched out successfully!');
            console.log(`Total Work Hours: ${updatedAttendance.totalWorkHours}`);
            console.log(`Punch Out Time: ${formatISTTime(updatedAttendance.punchOutTime, 'datetime')}`);
            
        } else {
            console.log('✅ No active attendance found');
            
            // Create new punch in
            console.log('\n👋 Punching in...');
            const punchInTime = getCurrentISTTime();
            const istDateOnly = new Date(punchInTime.getFullYear(), punchInTime.getMonth(), punchInTime.getDate());
            
            const attendance = await prisma.attendance.create({
                data: {
                    employeeId: TEST_EMPLOYEE_ID,
                    employeeName: TEST_EMPLOYEE_NAME,
                    date: istDateOnly,
                    punchInTime: punchInTime,
                    punchInLatitude: TEST_COORDINATES.latitude,
                    punchInLongitude: TEST_COORDINATES.longitude,
                    punchInAddress: TEST_COORDINATES.address,
                    bikeKmStart: '12345',
                    status: 'active',
                    totalWorkHours: 0,
                    totalDistanceKm: 0
                }
            });
            
            console.log('✅ Punched in successfully!');
            console.log(`Attendance ID: ${attendance.id}`);
            console.log(`Punch In Time: ${formatISTTime(attendance.punchInTime, 'datetime')}`);
            console.log(`Status: ${attendance.status}`);
        }
        
        // Get today's attendance summary
        console.log('\n📊 Today\'s Attendance Summary:');
        const todayAttendances = await prisma.attendance.findMany({
            where: {
                employeeId: TEST_EMPLOYEE_ID,
                punchInTime: {
                    gte: startOfDay,
                    lt: endOfDay
                }
            },
            orderBy: {
                punchInTime: 'desc'
            }
        });
        
        console.log(`Total Sessions Today: ${todayAttendances.length}`);
        
        todayAttendances.forEach((att, index) => {
            console.log(`\nSession ${index + 1}:`);
            console.log(`  ID: ${att.id}`);
            console.log(`  Punch In: ${formatISTTime(att.punchInTime, 'datetime')}`);
            console.log(`  Punch Out: ${att.punchOutTime ? formatISTTime(att.punchOutTime, 'datetime') : 'Not punched out'}`);
            console.log(`  Status: ${att.status}`);
            console.log(`  Work Hours: ${att.totalWorkHours || 0}`);
            
            if (att.status === 'active') {
                const currentDuration = getCurrentWorkDurationIST(att.punchInTime);
                console.log(`  Current Duration: ${currentDuration.toFixed(2)} hours`);
            }
        });
        
        console.log('\n🎯 Timezone Validation:');
        const timezoneInfo = getISTTimezoneInfo();
        console.log(`Timezone: ${timezoneInfo.name} (${timezoneInfo.offset})`);
        console.log(`Current IST: ${formatISTTime(getCurrentISTTime(), 'datetime')}`);
        
        console.log('\n✅ Punch system test completed successfully!');
        
    } catch (error) {
        console.error('❌ Test failed:', error);
        throw error;
    } finally {
        await prisma.$disconnect();
        console.log('🔌 Database disconnected');
    }
}

// Run the test
testPunchSystem().catch(console.error);