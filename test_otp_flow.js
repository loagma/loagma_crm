// Test script for OTP flow
const fetch = require('node-fetch');

const BASE_URL = 'http://localhost:5000';
const EMPLOYEE_ID = 'EMP001';

async function testOTPFlow() {
    console.log('🧪 Testing Late Punch Approval OTP Flow...\n');

    try {
        // 1. Check current status
        console.log('1. Checking current approval status...');
        const statusResponse = await fetch(`${BASE_URL}/late-punch-approval/employee/${EMPLOYEE_ID}/status`);
        const statusData = await statusResponse.json();
        console.log('Status Response:', JSON.stringify(statusData, null, 2));

        // 2. If no pending request, create one
        if (!statusData.data || statusData.data.status !== 'PENDING') {
            console.log('\n2. Creating approval request...');
            const requestResponse = await fetch(`${BASE_URL}/late-punch-approval/request`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    employeeId: EMPLOYEE_ID,
                    employeeName: 'Test Employee',
                    reason: 'Testing OTP flow - traffic jam caused delay'
                })
            });
            const requestData = await requestResponse.json();
            console.log('Request Response:', JSON.stringify(requestData, null, 2));
        }

        // 3. Test OTP validation with code 108767
        console.log('\n3. Testing OTP validation with code 108767...');
        const validateResponse = await fetch(`${BASE_URL}/late-punch-approval/validate-code`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                employeeId: EMPLOYEE_ID,
                approvalCode: '108767'
            })
        });
        const validateData = await validateResponse.json();
        console.log('Validation Response:', JSON.stringify(validateData, null, 2));

    } catch (error) {
        console.error('❌ Test failed:', error.message);
    }
}

testOTPFlow();