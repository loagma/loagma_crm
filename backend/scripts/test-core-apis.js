import axios from 'axios';

const BASE_URL = 'http://localhost:5000';

console.log('\n🧪 Testing Core APIs After Cleanup\n');
console.log('═══════════════════════════════════════\n');

const tests = [
    // Critical health checks
    { name: 'Root Endpoint', url: '/', critical: true },
    { name: 'Health Check', url: '/health', critical: true },

    // Master data (should work)
    { name: 'Get Departments', url: '/masters/departments', critical: true },

    // Locations (basic)
    { name: 'Get Countries', url: '/locations/countries', critical: true },

    // Pincode service
    { name: 'Pincode Lookup', url: '/pincode/400001', critical: false },
];

let passed = 0;
let failed = 0;
let criticalFailed = 0;

for (const test of tests) {
    try {
        const response = await axios.get(`${BASE_URL}${test.url}`);
        console.log(`✅ ${test.name}`);
        console.log(`   Status: ${response.status}`);
        if (response.data) {
            console.log(`   Response: ${JSON.stringify(response.data).substring(0, 100)}...`);
        }
        console.log('');
        passed++;
    } catch (error) {
        const isCritical = test.critical ? '🔴 CRITICAL' : '⚠️ ';
        if (error.response) {
            console.log(`❌ ${isCritical} ${test.name}`);
            console.log(`   Status: ${error.response.status}`);
            console.log(`   Error: ${error.response.data?.message || 'Unknown error'}`);
        } else {
            console.log(`❌ ${isCritical} ${test.name}`);
            console.log(`   Error: ${error.message}`);
        }
        console.log('');
        failed++;
        if (test.critical) criticalFailed++;
    }
}

console.log('═══════════════════════════════════════');
console.log('📊 Test Results');
console.log('═══════════════════════════════════════');
console.log(`✅ Passed: ${passed}/${tests.length}`);
console.log(`❌ Failed: ${failed}/${tests.length}`);
if (criticalFailed > 0) {
    console.log(`🔴 Critical Failures: ${criticalFailed}`);
}
console.log('═══════════════════════════════════════\n');

if (criticalFailed === 0) {
    console.log('✅ All critical APIs are working!');
    console.log('🎉 Backend cleanup successful - functionality preserved!\n');
    process.exit(0);
} else {
    console.log('❌ Critical APIs failed. Please check the server.\n');
    process.exit(1);
}
