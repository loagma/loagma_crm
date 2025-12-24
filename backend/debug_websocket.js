#!/usr/bin/env node

/**
 * Debug Script: WebSocket Live Tracking System
 * 
 * This script helps debug the WebSocket live tracking system by:
 * 1. Checking active attendance sessions
 * 2. Monitoring WebSocket connections
 * 3. Simulating location updates
 * 4. Verifying database storage
 */

import { PrismaClient } from '@prisma/client';
import WebSocket from 'ws';

const prisma = new PrismaClient();

async function debugWebSocketSystem() {
    try {
        console.log('🔍 Debugging WebSocket Live Tracking System...\n');
        
        // Step 1: Check active attendance sessions
        console.log('📋 Step 1: Checking active attendance sessions...');
        const activeAttendances = await prisma.attendance.findMany({
            where: { status: 'active' },
            select: {
                id: true,
                employeeId: true,
                employeeName: true,
                punchInTime: true,
                punchInLatitude: true,
                punchInLongitude: true
            },
            orderBy: { punchInTime: 'desc' }
        });
        
        console.log(`✅ Found ${activeAttendances.length} active attendance sessions:`);
        activeAttendances.forEach((attendance, index) => {
            console.log(`   ${index + 1}. ${attendance.employeeName} (${attendance.employeeId})`);
            console.log(`      - Session ID: ${attendance.id}`);
            console.log(`      - Started: ${attendance.punchInTime.toISOString()}`);
            console.log(`      - Location: ${attendance.punchInLatitude}, ${attendance.punchInLongitude}`);
        });
        
        if (activeAttendances.length === 0) {
            console.log('⚠️ No active attendance sessions found!');
            console.log('💡 Make sure a salesman has punched in before testing WebSocket tracking.');
            return;
        }
        
        // Step 2: Check existing route data
        console.log('\n📋 Step 2: Checking existing route data...');
        const routeStats = await prisma.$queryRaw`
            SELECT 
                a."employeeName",
                a."employeeId",
                COUNT(r.id) as route_points,
                MIN(r."recordedAt") as first_point,
                MAX(r."recordedAt") as last_point
            FROM "Attendance" a
            LEFT JOIN "SalesmanRouteLog" r ON a.id = r."attendanceId"
            WHERE a.status = 'active'
            GROUP BY a.id, a."employeeName", a."employeeId"
            ORDER BY route_points DESC
        `;
        
        console.log('📊 Route data for active sessions:');
        routeStats.forEach((stat, index) => {
            console.log(`   ${index + 1}. ${stat.employeeName}:`);
            console.log(`      - Route points: ${stat.route_points}`);
            if (stat.route_points > 0) {
                console.log(`      - First point: ${stat.first_point}`);
                console.log(`      - Last point: ${stat.last_point}`);
            } else {
                console.log('      - ⚠️ No route points recorded yet!');
            }
        });
        
        // Step 3: Test WebSocket connection
        console.log('\n📋 Step 3: Testing WebSocket connection...');
        
        const wsUrl = 'wss://loagma-crm.onrender.com/ws?token=dev_mode_token';
            
        console.log(`🔗 Connecting to: ${wsUrl}`);
        
        const ws = new WebSocket(wsUrl);
        
        ws.on('open', () => {
            console.log('✅ WebSocket connected successfully!');
            
            // Test sending a location update
            if (activeAttendances.length > 0) {
                const testEmployee = activeAttendances[0];
                console.log(`📍 Sending test location for ${testEmployee.employeeName}...`);
                
                const testLocation = {
                    type: 'LOCATION',
                    salesmanId: testEmployee.employeeId,
                    lat: testEmployee.punchInLatitude + 0.001, // Move slightly
                    lng: testEmployee.punchInLongitude + 0.001,
                    timestamp: Date.now()
                };
                
                ws.send(JSON.stringify(testLocation));
                
                // Send a few more points to simulate movement
                setTimeout(() => {
                    const testLocation2 = {
                        type: 'LOCATION',
                        salesmanId: testEmployee.employeeId,
                        lat: testEmployee.punchInLatitude + 0.002,
                        lng: testEmployee.punchInLongitude + 0.002,
                        timestamp: Date.now()
                    };
                    ws.send(JSON.stringify(testLocation2));
                }, 1000);
                
                setTimeout(() => {
                    const testLocation3 = {
                        type: 'LOCATION',
                        salesmanId: testEmployee.employeeId,
                        lat: testEmployee.punchInLatitude + 0.003,
                        lng: testEmployee.punchInLongitude + 0.003,
                        timestamp: Date.now()
                    };
                    ws.send(JSON.stringify(testLocation3));
                }, 2000);
            }
        });
        
        ws.on('message', (data) => {
            const message = JSON.parse(data.toString());
            console.log('📨 Received WebSocket message:', message);
        });
        
        ws.on('error', (error) => {
            console.error('❌ WebSocket error:', error);
        });
        
        ws.on('close', () => {
            console.log('🔌 WebSocket connection closed');
        });
        
        // Wait a bit for WebSocket test
        await new Promise(resolve => setTimeout(resolve, 5000));
        
        // Step 4: Check if test data was stored
        console.log('\n📋 Step 4: Checking if test data was stored...');
        const newRouteStats = await prisma.$queryRaw`
            SELECT 
                a."employeeName",
                COUNT(r.id) as route_points,
                MAX(r."recordedAt") as last_point
            FROM "Attendance" a
            LEFT JOIN "SalesmanRouteLog" r ON a.id = r."attendanceId"
            WHERE a.status = 'active'
            GROUP BY a.id, a."employeeName"
            ORDER BY route_points DESC
        `;
        
        console.log('📊 Updated route data:');
        newRouteStats.forEach((stat, index) => {
            console.log(`   ${index + 1}. ${stat.employeeName}: ${stat.route_points} points`);
            if (stat.last_point) {
                console.log(`      - Last update: ${stat.last_point}`);
            }
        });
        
        ws.close();
        
        console.log('\n✅ WebSocket debug completed!');
        
    } catch (error) {
        console.error('❌ Debug failed:', error);
    } finally {
        await prisma.$disconnect();
    }
}

// Run the debug
debugWebSocketSystem();