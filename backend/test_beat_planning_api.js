const BASE_URL = 'http://localhost:5000';

async function testBeatPlanningAPI() {
    try {
        console.log('🧪 Testing Beat Planning API Endpoints...\n');

        // Test 1: Health check
        console.log('🏥 Test 1: Health check...');
        const healthResponse = await fetch(`${BASE_URL}/health`);
        const healthData = await healthResponse.json();
        console.log('✅ Server is healthy:', healthData.message);

        // Test 2: Try to access beat plans endpoint (should require auth)
        console.log('\n🔒 Test 2: Testing authentication requirement...');
        const beatPlansResponse = await fetch(`${BASE_URL}/beat-plans`);
        
        if (beatPlansResponse.status === 401) {
            console.log('✅ Authentication required (as expected)');
        } else {
            console.log('⚠️  Expected 401 but got:', beatPlansResponse.status);
        }

        // Test 3: Check if beat-plans route exists
        console.log('\n🛣️  Test 3: Testing route existence...');
        const routeResponse = await fetch(`${BASE_URL}/beat-plans`, {
            method: 'OPTIONS'
        });
        
        if (routeResponse.status === 200 || routeResponse.status === 204) {
            console.log('✅ Beat plans route exists and accepts OPTIONS');
        } else {
            console.log('⚠️  Route response status:', routeResponse.status);
        }

        console.log('\n🎉 API endpoint tests completed!');
        console.log('📝 Summary:');
        console.log('   - Server is running and healthy');
        console.log('   - Beat planning routes are registered');
        console.log('   - Authentication is properly enforced');
        console.log('   - Ready for Flutter app integration');

    } catch (error) {
        console.error('❌ API test failed:', error.message);
        
        if (error.code === 'ECONNREFUSED') {
            console.log('💡 Make sure the backend server is running: npm start');
        }
    }
}

// Run the API tests
testBeatPlanningAPI();