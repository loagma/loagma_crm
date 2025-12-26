// Comprehensive test for Leave Management System
import fetch from 'node-fetch';

const BASE_URL = 'http://localhost:5000';

// Test with a real user from the database
const TEST_USER = {
    contactNumber: '9876543210', // Replace with actual user contact
    otp: '123456' // Default OTP for testing
};

let authToken = null;
let testLeaveId = null;

async function authenticateUser() {
    console.log('🔐 Authenticating user...');

    try {
        // Step 1: Request OTP
        const otpResponse = await fetch(`${BASE_URL}/auth/request-otp`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ contactNumber: TEST_USER.contactNumber })
        });

        const otpData = await otpResponse.json();
        console.log('OTP Request:', otpData);

        // Step 2: Verify OTP
        const verifyResponse = await fetch(`${BASE_URL}/auth/verify-otp`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                contactNumber: TEST_USER.contactNumber,
                otp: TEST_USER.otp
            })
        });

        const verifyData = await verifyResponse.json();
        console.log('OTP Verify:', verifyData);

        if (verifyData.success && verifyData.token) {
            authToken = verifyData.token;
            console.log('✅ Authentication successful');
            return true;
        } else {
            console.log('❌ Authentication failed');
            return false;
        }
    } catch (error) {
        console.error('❌ Authentication error:', error);
        return false;
    }
}

async function testLeaveBalance() {
    console.log('\n📊 Testing Leave Balance...');

    try {
        const response = await fetch(`${BASE_URL}/leaves/balance`, {
            headers: { 'Authorization': `Bearer ${authToken}` }
        });

        const data = await response.json();
        console.log('Status:', response.status);
        console.log('Response:', JSON.stringify(data, null, 2));

        return response.status === 200 && data.success;
    } catch (error) {
        console.error('❌ Error:', error);
        return false;
    }
}

async function testApplyLeave() {
    console.log('\n📝 Testing Apply Leave...');

    try {
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);

        const dayAfter = new Date();
        dayAfter.setDate(dayAfter.getDate() + 2);

        const response = await fetch(`${BASE_URL}/leaves`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${authToken}`
            },
            body: JSON.stringify({
                leaveType: 'Sick',
                startDate: tomorrow.toISOString().split('T')[0],
                endDate: dayAfter.toISOString().split('T')[0],
                reason: 'Test leave application for system verification'
            })
        });

        const data = await response.json();
        console.log('Status:', response.status);
        console.log('Response:', JSON.stringify(data, null, 2));

        if (response.status === 201 && data.success && data.data?.id) {
            testLeaveId = data.data.id;
            console.log('✅ Leave application successful, ID:', testLeaveId);
            return true;
        }

        return false;
    } catch (error) {
        console.error('❌ Error:', error);
        return false;
    }
}

async function testGetMyLeaves() {
    console.log('\n📋 Testing Get My Leaves...');

    try {
        const response = await fetch(`${BASE_URL}/leaves/my`, {
            headers: { 'Authorization': `Bearer ${authToken}` }
        });

        const data = await response.json();
        console.log('Status:', response.status);
        console.log('Response:', JSON.stringify(data, null, 2));

        return response.status === 200 && data.success;
    } catch (error) {
        console.error('❌ Error:', error);
        return false;
    }
}

async function testGetPendingLeaves() {
    console.log('\n⏳ Testing Get Pending Leaves (Admin)...');

    try {
        const response = await fetch(`${BASE_URL}/leaves/pending`, {
            headers: { 'Authorization': `Bearer ${authToken}` }
        });

        const data = await response.json();
        console.log('Status:', response.status);
        console.log('Response:', JSON.stringify(data, null, 2));

        return response.status === 200 && data.success;
    } catch (error) {
        console.error('❌ Error:', error);
        return false;
    }
}

async function testCancelLeave() {
    if (!testLeaveId) {
        console.log('\n❌ No leave ID available for cancellation test');
        return false;
    }

    console.log('\n🚫 Testing Cancel Leave...');

    try {
        const response = await fetch(`${BASE_URL}/leaves/${testLeaveId}/cancel`, {
            method: 'PATCH',
            headers: { 'Authorization': `Bearer ${authToken}` }
        });

        const data = await response.json();
        console.log('Status:', response.status);
        console.log('Response:', JSON.stringify(data, null, 2));

        return response.status === 200 && data.success;
    } catch (error) {
        console.error('❌ Error:', error);
        return false;
    }
}

async function runCompleteTest() {
    console.log('🧪 Starting Complete Leave Management System Test\n');
    console.log('='.repeat(60));

    const results = {
        authentication: false,
        leaveBalance: false,
        applyLeave: false,
        getMyLeaves: false,
        getPendingLeaves: false,
        cancelLeave: false
    };

    // Test Authentication
    results.authentication = await authenticateUser();
    if (!results.authentication) {
        console.log('\n❌ Authentication failed - stopping tests');
        return results;
    }

    // Test Leave Balance
    results.leaveBalance = await testLeaveBalance();

    // Test Apply Leave
    results.applyLeave = await testApplyLeave();

    // Test Get My Leaves
    results.getMyLeaves = await testGetMyLeaves();

    // Test Get Pending Leaves (Admin function)
    results.getPendingLeaves = await testGetPendingLeaves();

    // Test Cancel Leave
    results.cancelLeave = await testCancelLeave();

    // Print Summary
    console.log('\n' + '='.repeat(60));
    console.log('📊 TEST RESULTS SUMMARY');
    console.log('='.repeat(60));

    Object.entries(results).forEach(([test, passed]) => {
        const status = passed ? '✅ PASS' : '❌ FAIL';
        console.log(`${status} ${test.padEnd(20)} ${passed ? 'Working correctly' : 'Needs attention'}`);
    });

    const passedTests = Object.values(results).filter(Boolean).length;
    const totalTests = Object.keys(results).length;

    console.log('\n📈 Overall Score:', `${passedTests}/${totalTests} tests passed`);

    if (passedTests === totalTests) {
        console.log('🎉 All tests passed! Leave Management System is working perfectly!');
    } else {
        console.log('⚠️  Some tests failed. Please check the implementation.');
    }

    return results;
}

// Run the complete test
runCompleteTest().catch(console.error);