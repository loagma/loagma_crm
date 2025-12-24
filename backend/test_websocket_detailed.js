#!/usr/bin/env node

/**
 * Detailed WebSocket Test: Simulate Salesman Location Updates
 * 
 * This script simulates the exact flow that should happen:
 * 1. Salesman connects to WebSocket with their employee ID
 * 2. Salesman sends location updates
 * 3. Server stores location in database
 * 4. Admin receives real-time updates
 */

import { PrismaClient } from '@prisma/client';
import WebSocket from 'ws';

const prisma = new PrismaClient();

async function testDetailedWebSocket() {
    try {
        console.log('🧪 Detailed WebSocket Test Starting...\n');
        
        // Get an active attendance session to test with
        const activeAttendance = await prisma.attendance.findFirst({
            where: { status: 'active' },
            select: {
                id: true,
                employeeId: true,
                employeeName: true,
                punchInLatitude: true,
                punchInLongitude: true
            }
        });
        
        if (!activeAttendance) {
            console.log('❌ No active attendance found for testing');
            return;
        }
        
        console.log(`🎯 Testing with: ${activeAttendance.employeeName} (${activeAttendance.employeeId})`);
        console.log(`📍 Base location: ${activeAttendance.punchInLatitude}, ${activeAttendance.punchInLongitude}\n`);
        
        // Test 1: Connect as Admin
        console.log('📋 Test 1: Admin WebSocket Connection...');
        const adminWs = new WebSocket('wss://loagma-crm.onrender.com/ws?token=dev_mode_token&userType=admin');
        
        let adminConnected = false;
        let adminMessages = [];
        
        adminWs.on('open', () => {
            console.log('✅ Admin WebSocket connected');
            adminConnected = true;
        });
        
        adminWs.on('message', (data) => {
            const message = JSON.parse(data.toString());
            adminMessages.push(message);
            console.log('📨 Admin received:', message.type, message.salesmanId ? `from ${message.salesmanId}` : '');
        });
        
        adminWs.on('error', (error) => {
            console.error('❌ Admin WebSocket error:', error.message);
        });
        
        // Wait for admin connection
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        if (!adminConnected) {
            console.log('❌ Admin connection failed');
            return;
        }
        
        // Test 2: Connect as Salesman (simulate the salesman app)
        console.log('\n📋 Test 2: Salesman WebSocket Connection...');
        const salesmanWs = new WebSocket(`wss://loagma-crm.onrender.com/ws?token=dev_mode_token&userType=salesman&employeeId=${activeAttendance.employeeId}`);
        
        let salesmanConnected = false;
        
        salesmanWs.on('open', () => {
            console.log('✅ Salesman WebSocket connected');
            salesmanConnected = true;
        });
        
        salesmanWs.on('message', (data) => {
            const message = JSON.parse(data.toString());
            console.log('📨 Salesman received:', message);
        });
        
        salesmanWs.on('error', (error) => {
            console.error('❌ Salesman WebSocket error:', error.message);
        });
        
        // Wait for salesman connection
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        if (!salesmanConnected) {
            console.log('❌ Salesman connection failed');
            return;
        }
        
        // Test 3: Send location updates from salesman
        console.log('\n📋 Test 3: Sending Location Updates...');
        
        const baseLatitude = activeAttendance.punchInLatitude;
        const baseLongitude = activeAttendance.punchInLongitude;
        
        // Send 5 location updates with slight movement
        for (let i = 0; i < 5; i++) {
            const locationUpdate = {
                type: 'LOCATION',
                salesmanId: activeAttendance.employeeId,
                lat: baseLatitude + (i * 0.0001), // Move slightly north
                lng: baseLongitude + (i * 0.0001), // Move slightly east
                timestamp: Date.now()
            };
            
            console.log(`📍 Sending location ${i + 1}/5: ${locationUpdate.lat.toFixed(6)}, ${locationUpdate.lng.toFixed(6)}`);
            salesmanWs.send(JSON.stringify(locationUpdate));
            
            // Wait between updates
            await new Promise(resolve => setTimeout(resolve, 500));
        }
        
        // Wait for processing
        console.log('⏳ Waiting for server processing...');
        await new Promise(resolve => setTimeout(resolve, 3000));
        
        // Test 4: Check database for stored locations
        console.log('\n📋 Test 4: Checking Database Storage...');
        
        const storedLocations = await prisma.salesmanRouteLog.findMany({
            where: {
                attendanceId: activeAttendance.id,
                employeeId: activeAttendance.employeeId
            },
            orderBy: { recordedAt: 'desc' },
            take: 10
        });
        
        console.log(`📊 Found ${storedLocations.length} stored location points:`);
        storedLocations.forEach((location, index) => {
            console.log(`   ${index + 1}. ${location.latitude.toFixed(6)}, ${location.longitude.toFixed(6)} at ${location.recordedAt.toISOString()}`);
        });
        
        // Test 5: Check admin received updates
        console.log('\n📋 Test 5: Admin Message Summary...');
        console.log(`📨 Admin received ${adminMessages.length} messages:`);
        adminMessages.forEach((msg, index) => {
            console.log(`   ${index + 1}. ${msg.type} ${msg.salesmanId ? `from ${msg.salesmanId}` : ''}`);
        });
        
        // Test 6: Test the getCurrentPositions API
        console.log('\n📋 Test 6: Testing getCurrentPositions API...');
        
        try {
            const positions = await prisma.attendance.findMany({
                where: { status: 'active' },
                include: {
                    routeLogs: {
                        orderBy: { recordedAt: 'desc' },
                        take: 1
                    }
                }
            });
            
            console.log('📊 Current positions from database:');
            positions.forEach((attendance, index) => {
                const latestRoute = attendance.routeLogs[0];
                console.log(`   ${index + 1}. ${attendance.employeeName}:`);
                if (latestRoute) {
                    console.log(`      - Latest: ${latestRoute.latitude.toFixed(6)}, ${latestRoute.longitude.toFixed(6)}`);
                    console.log(`      - Time: ${latestRoute.recordedAt.toISOString()}`);
                } else {
                    console.log('      - No route data found');
                }
            });
        } catch (error) {
            console.error('❌ Error testing getCurrentPositions:', error.message);
        }
        
        // Cleanup
        adminWs.close();
        salesmanWs.close();
        
        console.log('\n✅ Detailed WebSocket test completed!');
        
        // Summary
        console.log('\n📋 Test Summary:');
        console.log(`   - Admin connection: ${adminConnected ? '✅' : '❌'}`);
        console.log(`   - Salesman connection: ${salesmanConnected ? '✅' : '❌'}`);
        console.log(`   - Location updates sent: 5`);
        console.log(`   - Locations stored in DB: ${storedLocations.length}`);
        console.log(`   - Admin messages received: ${adminMessages.length}`);
        
        if (storedLocations.length === 0) {
            console.log('\n🔍 Troubleshooting Tips:');
            console.log('   1. Check WebSocket server logs for authentication errors');
            console.log('   2. Verify the salesman ID matches the active attendance');
            console.log('   3. Check if the WebSocket server is properly handling location messages');
            console.log('   4. Ensure the database connection is working in the WebSocket server');
        }
        
    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        await prisma.$disconnect();
    }
}

// Run the test
testDetailedWebSocket();