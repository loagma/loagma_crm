// Test API calls using fetch
import fetch from 'node-fetch';

const BASE_URL = 'http://localhost:5000';

async function testAPI() {
    try {
        console.log('🧪 Testing API endpoints...\n');

        // 1. Test health endpoint
        console.log('1. Testing health endpoint...');
        const healthResponse = await fetch(`${BASE_URL}/health`);
        const healthData = await healthResponse.json();
        console.log('Health:', healthData);

        // 2. Create approval request
        console.log('\n2. Creating approval request...');
        const requestResponse = await fetch(`${BASE_URL}/late-punch-approval/request`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                employeeId: 'EMP001',
                employeeName: 'Test Employee',
                reason: 'Testing OTP flow - traffic jam caused delay'
            })
        });
        const requestData = await requestResponse.json();
        console.log('Request result:', requestData);

        if (requestData.success && requestData.data?.requestId) {
            // 3. Approve the request
            console.log('\n3. Approving request...');
            const approveResponse = await fetch(`${BASE_URL}/late-punch-approval/approve/${requestData.data.requestId}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    adminId: 'ADMIN001',
                    adminRemarks: 'Approved for testing OTP flow'
                })
            });
            const approveData = await approveResponse.json();
            console.log('Approve result:', approveData);

            if (approveData.success) {
                console.log('\n🎉 Approval created successfully!');
                console.log('📱 Approval code:', approveData.data?.approvalCode);
                console.log('📱 You can now test this code in the Flutter app');
            }
        }

    } catch (error) {
        console.error('❌ Error:', error.message);
    }
}

testAPI();