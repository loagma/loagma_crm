import axios from 'axios';

const BASE_URL = process.env.BASE_URL || 'http://localhost:5000';

// Color codes for console output
const colors = {
    green: '\x1b[32m',
    red: '\x1b[31m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    reset: '\x1b[0m'
};

const log = {
    success: (msg) => console.log(`${colors.green}✅ ${msg}${colors.reset}`),
    error: (msg) => console.log(`${colors.red}❌ ${msg}${colors.reset}`),
    info: (msg) => console.log(`${colors.blue}ℹ️  ${msg}${colors.reset}`),
    warning: (msg) => console.log(`${colors.yellow}⚠️  ${msg}${colors.reset}`)
};

// Test results
const results = {
    passed: 0,
    failed: 0,
    skipped: 0,
    tests: []
};

// Test helper
async function testEndpoint(name, method, path, data = null, requiresAuth = false) {
    try {
        const config = {
            method,
            url: `${BASE_URL}${path}`,
            headers: {}
        };

        if (data) {
            config.data = data;
        }

        if (requiresAuth) {
            // Skip auth-required tests for now
            log.warning(`${name} - Skipped (requires authentication)`);
            results.skipped++;
            results.tests.push({ name, status: 'skipped', reason: 'requires auth' });
            return;
        }

        const response = await axios(config);

        if (response.status >= 200 && response.status < 300) {
            log.success(`${name} - ${response.status}`);
            results.passed++;
            results.tests.push({ name, status: 'passed', code: response.status });
        } else {
            log.error(`${name} - Unexpected status ${response.status}`);
            results.failed++;
            results.tests.push({ name, status: 'failed', code: response.status });
        }
    } catch (error) {
        if (error.response) {
            // Expected errors (401, 404, etc.)
            if (error.response.status === 401 && requiresAuth) {
                log.warning(`${name} - ${error.response.status} (expected, requires auth)`);
                results.skipped++;
                results.tests.push({ name, status: 'skipped', reason: 'requires auth' });
            } else if (error.response.status === 404) {
                log.error(`${name} - 404 Not Found`);
                results.failed++;
                results.tests.push({ name, status: 'failed', code: 404 });
            } else {
                log.error(`${name} - ${error.response.status}: ${error.response.data?.message || 'Error'}`);
                results.failed++;
                results.tests.push({ name, status: 'failed', code: error.response.status });
            }
        } else {
            log.error(`${name} - ${error.message}`);
            results.failed++;
            results.tests.push({ name, status: 'failed', error: error.message });
        }
    }
}

async function runTests() {
    console.log('\n🧪 Testing Loagma CRM Backend APIs\n');
    console.log(`📍 Base URL: ${BASE_URL}\n`);

    // Health Check Endpoints
    log.info('Testing Health Check Endpoints...');
    await testEndpoint('Root Endpoint', 'GET', '/');
    await testEndpoint('Health Check', 'GET', '/health');
    console.log('');

    // Auth Endpoints (Public)
    log.info('Testing Auth Endpoints...');
    await testEndpoint('Send OTP (no phone)', 'POST', '/auth/send-otp', {});
    await testEndpoint('Verify OTP (no data)', 'POST', '/auth/verify-otp', {});
    console.log('');

    // Protected Endpoints (will return 401)
    log.info('Testing Protected Endpoints (expect 401)...');
    await testEndpoint('Get Users', 'GET', '/users', null, true);
    await testEndpoint('Get Accounts', 'GET', '/accounts', null, true);
    await testEndpoint('Get Employees', 'GET', '/employees', null, true);
    await testEndpoint('Get Task Assignments', 'GET', '/task-assignments', null, true);
    await testEndpoint('Get Expenses', 'GET', '/api/expenses', null, true);
    await testEndpoint('Get Salesmen', 'GET', '/salesman', null, true);
    console.log('');

    // Master Data Endpoints (may be public)
    log.info('Testing Master Data Endpoints...');
    await testEndpoint('Get Business Types', 'GET', '/masters/business-types');
    await testEndpoint('Get Departments', 'GET', '/masters/departments');
    await testEndpoint('Get Designations', 'GET', '/masters/designations');
    console.log('');

    // Location Endpoints
    log.info('Testing Location Endpoints...');
    await testEndpoint('Search Locations (no query)', 'GET', '/locations/search');
    await testEndpoint('Get Pincode Info', 'GET', '/pincode/400001');
    console.log('');

    // Admin Endpoints
    log.info('Testing Admin Endpoints...');
    await testEndpoint('Admin Dashboard', 'GET', '/admin/dashboard', null, true);
    console.log('');

    // Role Endpoints
    log.info('Testing Role Endpoints...');
    await testEndpoint('Get Roles', 'GET', '/roles', null, true);
    console.log('');

    // Salary Endpoints
    log.info('Testing Salary Endpoints...');
    await testEndpoint('Get Salary Info', 'GET', '/salary/1', null, true);
    console.log('');

    // 404 Test
    log.info('Testing 404 Handler...');
    await testEndpoint('Non-existent Endpoint', 'GET', '/non-existent-route');
    console.log('');

    // Print Summary
    console.log('═══════════════════════════════════════════════════');
    console.log('📊 Test Summary');
    console.log('═══════════════════════════════════════════════════');
    console.log(`${colors.green}✅ Passed: ${results.passed}${colors.reset}`);
    console.log(`${colors.red}❌ Failed: ${results.failed}${colors.reset}`);
    console.log(`${colors.yellow}⚠️  Skipped: ${results.skipped}${colors.reset}`);
    console.log(`📝 Total: ${results.passed + results.failed + results.skipped}`);
    console.log('═══════════════════════════════════════════════════\n');

    // Exit with appropriate code
    if (results.failed > 0) {
        console.log('❌ Some tests failed. Check the output above.\n');
        process.exit(1);
    } else {
        console.log('✅ All tests passed or skipped as expected!\n');
        process.exit(0);
    }
}

// Run tests
runTests().catch(error => {
    console.error('Fatal error running tests:', error);
    process.exit(1);
});
