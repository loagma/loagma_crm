#!/usr/bin/env node

/**
 * Test JWT WebSocket Authentication
 * 
 * This script tests the WebSocket system with real JWT tokens:
 * 1. Gets active users from database
 * 2. Generates JWT tokens for admin and salesman
 * 3. Tests WebSocket connections with real authentication
 * 4. Simulates location updates
 * 5. Verifies database storage
 */

import { PrismaClient } from '@prisma/client';
import jwt from 'jsonwebtoken';
import WebSocket from 'ws';
import dotenv from 'dotenv';

dotenv.config();

const prisma = new PrismaClient();

// Generate JWT token (same as backend)
function generateToken(payload) {
    return jwt.sign(payload, process.env.JWT_SECRET || 'your-secret-key', { expiresIn: '7d' });
}

async function testJWTWebSocket() {
    try {
        console.log('🧪 Testing JWT WebSocket Authentication...\n');
        
        // Step 1: Get active users from database
        console.log('📋 Step 1: Getting active users...');
        
        const adminUser = await prisma.user.findFirst({
            where: {
                roles: { has: 'R001' }, // R001 = admin
                isActive: true
            },
            select: { id: true, name: true, roles: true }
        });
        
        const salesmanUser = await prisma.user.findFirst({
            where: {
                roles: { has: 'R002' }, // R002 = salesman
                isActive: true
            },
            select: { id: true, name: true, roles: true }
        });
        
        if (!adminUser) {
            console.log('❌ No active admin user found');
            return;
        }
        
        if (!salesmanUser) {
            console.log('❌ No active salesman user found');
            return;
        }
        
        console.log(`✅ Found admin: ${adminUser.name} (${adminUser.id})`);
        console.log(`✅ Found salesman: ${salesmanUser.name} (${salesmanUser.id})`);
        
        // Step 2: Generate JWT tokens
        console.log('\n📋 Step 2: Generating JWT tokens...');
        
        const adminToken = generateToken({
            id: adminUser.id,
            roleId: 'admin'
        });
        
        const salesmanToken = generateToken({
            id: salesmanUser.id,
            roleId: 'salesman'
        });
        
        console.log(`✅ Admin JWT generated: ${adminToken.substring(0, 50)}...`);
        console.log(`✅ Salesman JWT generated: ${salesmanToken.substring(0, 50)}...`);
        
        // Step 3: Test admin WebSocket connection
        console.log('\n📋 Step 3: Testing Admin WebSocket Connection...');
        
        const adminWs = new WebSocket(`wss://loagma-crm.onrender.com/ws?token=${adminToken}`);
        
        let adminConnected = false;
        let adminMessages = [];
        
        adminWs.on('open', () => {
            console.log('✅ Admin WebSocket connected with JWT');
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
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        if (!adminConnected) {
            console.log('❌ Admin JWT connection failed');
            return;
        }
        
        // Step 4: Test salesman WebSocket connection
        console.log('\n📋 Step 4: Testing Salesman WebSocket Connection...');
        
        const salesmanWs = new WebSocket(`wss://loagma-crm.onrender.com/ws?token=${salesmanToken}`);
        
        let salesmanConnected = false;
        
        salesmanWs.on('open', () => {
            console.log('✅ Salesman WebSocket connected with JWT');
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
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        if (!salesmanConnected) {
            console.log('❌ Salesman JWT connection failed');
            return;
        }
        
        // Step 5: Get active attendance for the salesman
        console.log('\n📋 Step 5: Getting active attendance...');
        
        const activeAttendance = await prisma.attendance.findFirst({
            where: {
                employeeId: salesmanUser.id,
                status: 'active'
            },
            select: {
                id: true,
                punchInLatitude: true,
                punchInLongitude: true
            }
        });
        
        if (!activeAttendance) {
            console.log('❌ No active attendance found for salesman');
            console.log('💡 The salesman needs to punch in first for location tracking to work');
            
            // Close connections
            adminWs.close();
            salesmanWs.close();
            return;
        }
        
        console.log(`✅ Found active attendance: ${activeAttendance.id}`);
        
        // Step 6: Send location updates from salesman
        console.log('\n📋 Step 6: Sending Location Updates with JWT...');
        
        const baseLatitude = activeAttendance.punchInLatitude;
        const baseLongitude = activeAttendance.punchInLongitude;
        
        // Send 5 location updates with slight movement
        for (let i = 0; i < 5; i++) {
            const locationUpdate = {
                type: 'LOCATION',
                salesmanId: salesmanUser.id,
                lat: baseLatitude + (i * 0.0001), // Move slightly north
                lng: baseLongitude + (i * 0.0001), // Move slightly east
                timestamp: Date.now()
            };
            
            console.log(`📍 Sending location ${i + 1}/5: ${locationUpdate.lat.toFixed(6)}, ${locationUpdate.lng.toFixed(6)}`);
            salesmanWs.send(JSON.stringify(locationUpdate));
            
            // Wait between updates
            await new Promise(resolve => setTimeout(resolve, 1000));
        }
        
        // Wait for processing
        console.log('⏳ Waiting for server processing...');
        await new Promise(resolve => setTimeout(resolve, 5000));
        
        // Step 7: Check database for stored locations
        console.log('\n📋 Step 7: Checking Database Storage...');
        
        const storedLocations = await prisma.salesmanRouteLog.findMany({
            where: {
                attendanceId: activeAttendance.id,
                employeeId: salesmanUser.id
            },
            orderBy: { recordedAt: 'desc' },
            take: 10
        });
        
        console.log(`📊 Found ${storedLocations.length} stored location points:`);
        storedLocations.slice(0, 5).forEach((location, index) => {
            console.log(`   ${index + 1}. ${location.latitude.toFixed(6)}, ${location.longitude.toFixed(6)} at ${location.recordedAt.toISOString()}`);
        });
        
        // Step 8: Check admin received updates
        console.log('\n📋 Step 8: Admin Message Summary...');
        console.log(`📨 Admin received ${adminMessages.length} messages:`);
        adminMessages.forEach((msg, index) => {
            console.log(`   ${index + 1}. ${msg.type} ${msg.salesmanId ? `from ${msg.salesmanId}` : ''}`);
        });
        
        // Step 9: Test getCurrentPositions API
        console.log('\n📋 Step 9: Testing getCurrentPositions API...');
        
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
        
        console.log('\n✅ JWT WebSocket test completed!');
        
        // Summary
        console.log('\n📋 Test Summary:');
        console.log(`   - Admin JWT connection: ${adminConnected ? '✅' : '❌'}`);
        console.log(`   - Salesman JWT connection: ${salesmanConnected ? '✅' : '❌'}`);
        console.log(`   - Location updates sent: 5`);
        console.log(`   - Locations stored in DB: ${storedLocations.length}`);
        console.log(`   - Admin messages received: ${adminMessages.length}`);
        
        if (storedLocations.length > 0 && adminMessages.length > 0) {
            console.log('\n🎉 SUCCESS: JWT WebSocket system is working!');
            console.log('   - Real-time location updates are being stored in database');
            console.log('   - Admin is receiving live location broadcasts');
            console.log('   - Route visualization should work in the app');
        } else {
            console.log('\n⚠️ PARTIAL SUCCESS: Connections work but data flow needs debugging');
            console.log('   - Check WebSocket server logs for message processing errors');
            console.log('   - Verify database permissions and connection');
        }
        
    } catch (error) {
        console.error('❌ Test failed:', error);
    } finally {
        await prisma.$disconnect();
    }
}

// Run the test
testJWTWebSocket();