import axios from 'axios';

const BASE_URL = 'http://localhost:5000';

console.log('\n🧪 Quick API Test - Loagma CRM Backend\n');

const tests = [
    // Health checks
    { name: 'Root Endpoint', url: '/' },
    { name: 'Health Check', url: '/health' },

    // Master data
    { name: 'Get Departments', url: '/masters/departments' },
    { name: 'Get Functional Roles', url: '/masters/functional-roles' },
    { name: 'Get Roles', url: '/masters/roles' },

    // Locations
    { name: 'Get Countries', url: '/locations/countries' },
    { name: 'Get States', url: '/locations/states' },
    { name: 'Get Cities', url: '/locations/cities' },

    // Pincode
    { name: 'Get Pincode 400001', url: '/pincode/400001' },
];

let passed = 0;
let failed = 0;

for (const test of tests) {
    try {
        const response = await axios.get(`${BASE_URL}${test.url}`);
        console.log(`✅ ${test.name} - ${response.status}`);
        passed++;
    } catch (error) {
        if (error.response) {
            console.log(`❌ ${test.name} - ${error.response.status}: ${error.response.data?.message || 'Error'}`);
        } else {
            console.log(`❌ ${test.name} - ${error.message}`);
        }
        failed++;
    }
}

console.log('\n═══════════════════════════════════════');
console.log(`✅ Passed: ${passed}`);
console.log(`❌ Failed: ${failed}`);
console.log(`📝 Total: ${passed + failed}`);
console.log('═══════════════════════════════════════\n');

if (failed === 0) {
    console.log('🎉 All core APIs are working!\n');
    process.exit(0);
} else {
    console.log('⚠️  Some APIs failed. Check configuration.\n');
    process.exit(1);
}
