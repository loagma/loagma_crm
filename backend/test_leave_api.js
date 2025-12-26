// Simple test script to verify Leave Management API endpoints
import fetch from 'node-fetch';

const BASE_URL = 'http://localhost:5000';
const TEST_TOKEN = 'your-test-jwt-token-here'; // Replace with actual token

const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${TEST_TOKEN}`
};

async function testLeaveAPI() {
    console.log('🧪 Testing Leave Management API...\n');

    try {
        // Test 1: Get leave balance
        console.log('1. Testing GET /leaves/balance');
        const balanceResponse = await fetch(`${BASE_URL}/leaves/balance`, {
            method: 'GET',
            headers
        });
        const balanceData = await balanceResponse.json();
        console.log('Response:', balanceData);
        console.log('Status:', balanceResponse.status);
        console.log('---\n');

        // Test 2: Get my leaves
        console.log('2. Testing GET /leaves/my');
        const myLeavesResponse = await fetch(`${BASE_URL}/leaves/my`, {
            method: 'GET',
            headers
        });
        const myLeavesData = await myLeavesResponse.json();
        console.log('Response:', myLeavesData);
        console.log('Status:', myLeavesResponse.status);
        console.log('---\n');

        // Test 3: Apply for leave
        console.log('3. Testing POST /leaves (Apply Leave)');
        const applyLeaveResponse = await fetch(`${BASE_URL}/leaves`, {
            method: 'POST',
            headers,
            body: JSON.stringify({
                leaveType: 'Sick',
                startDate: '2024-12-30',
                endDate: '2024-12-31',
                reason: 'Test leave application'
            })
        });
        const applyLeaveData = await applyLeaveResponse.json();
        console.log('Response:', applyLeaveData);
        console.log('Status:', applyLeaveResponse.status);
        console.log('---\n');

        // Test 4: Get pending leaves (Admin)
        console.log('4. Testing GET /leaves/pending (Admin)');
        const pendingResponse = await fetch(`${BASE_URL}/leaves/pending`, {
            method: 'GET',
            headers
        });
        const pendingData = await pendingResponse.json();
        console.log('Response:', pendingData);
        console.log('Status:', pendingResponse.status);
        console.log('---\n');

        console.log('✅ Leave API tests completed!');

    } catch (error) {
        console.error('❌ Error testing Leave API:', error);
    }
}

// Run tests
testLeaveAPI();