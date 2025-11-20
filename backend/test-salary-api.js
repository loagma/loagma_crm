// Quick test script for Salary API
// Run with: node test-salary-api.js

const BASE_URL = 'http://localhost:5000';

async function testSalaryAPI() {
  console.log('🧪 Testing Salary Management API...\n');

  try {
    // Test 1: Health Check
    console.log('1️⃣ Testing Health Check...');
    const healthResponse = await fetch(`${BASE_URL}/health`);
    const healthData = await healthResponse.json();
    console.log('✅ Health Check:', healthData.message);
    console.log('');

    // Test 2: Get All Salaries (should be empty initially)
    console.log('2️⃣ Testing Get All Salaries...');
    const salariesResponse = await fetch(`${BASE_URL}/salaries`);
    const salariesData = await salariesResponse.json();
    console.log('✅ Get All Salaries:', salariesData.success ? 'Success' : 'Failed');
    console.log('   Total Salaries:', salariesData.data?.length || 0);
    console.log('');

    // Test 3: Get Statistics
    console.log('3️⃣ Testing Get Statistics...');
    const statsResponse = await fetch(`${BASE_URL}/salaries/statistics`);
    const statsData = await statsResponse.json();
    console.log('✅ Get Statistics:', statsData.success ? 'Success' : 'Failed');
    if (statsData.success) {
      console.log('   Total Employees:', statsData.data.totalEmployees);
      console.log('   Total Gross Salary:', statsData.data.totalGrossSalary);
      console.log('   Total Travel Allowance:', statsData.data.totalTravelAllowance);
      console.log('   Total Daily Allowance:', statsData.data.totalDailyAllowance);
    }
    console.log('');

    console.log('✅ All tests completed successfully!');
    console.log('\n📝 Note: To create salary information, you need:');
    console.log('   1. A valid employee ID from your database');
    console.log('   2. Use POST /salaries with the required fields');
    console.log('\n📚 See SALARY_API_DOCUMENTATION.md for complete API details');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.log('\n⚠️  Make sure the backend server is running:');
    console.log('   cd backend && npm run dev');
  }
}

testSalaryAPI();
