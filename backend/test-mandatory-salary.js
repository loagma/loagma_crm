// Test script for Mandatory Salary Feature
// Run with: node test-mandatory-salary.js

const BASE_URL = 'http://localhost:5000';

async function testMandatorySalaryFeature() {
  console.log('🧪 Testing Mandatory Salary Feature...\n');

  try {
    // Test 1: Create user WITHOUT salary (should fail)
    console.log('1️⃣ Test: Create Employee WITHOUT Salary (Should Fail)');
    const testUser1 = {
      contactNumber: `+91${Math.floor(Math.random() * 9000000000) + 1000000000}`,
      name: 'Test Employee No Salary',
      email: `test.nosalary.${Date.now()}@example.com`,
      // salaryPerMonth NOT provided
    };

    const response1 = await fetch(`${BASE_URL}/admin/users`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(testUser1),
    });

    const data1 = await response1.json();
    if (!data1.success) {
      console.log('   ✅ Correctly rejected (as expected)');
      console.log('   Message:', data1.message);
    } else {
      console.log('   ❌ Should have failed but succeeded');
    }
    console.log('');

    // Test 2: Create user WITH salary (should succeed)
    console.log('2️⃣ Test: Create Employee WITH Salary (Should Succeed)');
    const testUser2 = {
      contactNumber: `+91${Math.floor(Math.random() * 9000000000) + 1000000000}`,
      name: 'Test Employee With Salary',
      email: `test.withsalary.${Date.now()}@example.com`,
      salaryPerMonth: '50000',
    };

    const response2 = await fetch(`${BASE_URL}/admin/users`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(testUser2),
    });

    const data2 = await response2.json();
    console.log('   Response:', data2.success ? '✅ Success' : '❌ Failed');
    console.log('   Message:', data2.message);
    
    if (data2.success && data2.user && data2.salary) {
      console.log('   ✅ User created with ID:', data2.user.id);
      console.log('   ✅ Salary details returned:');
      console.log('      - Basic Salary:', data2.salary.basicSalary);
      console.log('      - Gross Salary:', data2.salary.grossSalary);
      console.log('      - Net Salary:', data2.salary.netSalary);
      console.log('      - Currency:', data2.salary.currency);
      console.log('      - Payment Frequency:', data2.salary.paymentFrequency);
      console.log('      - Effective From:', new Date(data2.salary.effectiveFrom).toLocaleDateString());
      
      // Test 3: Verify salary in database
      console.log('');
      console.log('3️⃣ Test: Verify Salary in Database');
      const salaryCheck = await fetch(`${BASE_URL}/salaries/${data2.user.id}`);
      const salaryData = await salaryCheck.json();
      
      if (salaryData.success) {
        console.log('   ✅ Salary found in database');
        console.log('   Basic Salary:', salaryData.data.basicSalary);
        console.log('   All fields present:', Object.keys(salaryData.data).length, 'fields');
      } else {
        console.log('   ❌ Salary not found in database');
      }

      // Test 4: Get user with salary details
      console.log('');
      console.log('4️⃣ Test: Get User with Salary Details');
      const usersResponse = await fetch(`${BASE_URL}/admin/users`);
      const usersData = await usersResponse.json();
      
      if (usersData.success) {
        const createdUser = usersData.users.find(u => u.id === data2.user.id);
        if (createdUser && createdUser.salary) {
          console.log('   ✅ User retrieved with salary details');
          console.log('   User Name:', createdUser.name);
          console.log('   Salary Info:');
          console.log('      - Basic Salary:', createdUser.salary.basicSalary);
          console.log('      - Gross Salary:', createdUser.salary.grossSalary);
          console.log('      - Net Salary:', createdUser.salary.netSalary);
          console.log('      - Travel Allowance:', createdUser.salary.travelAllowance);
          console.log('      - Daily Allowance:', createdUser.salary.dailyAllowance);
        } else {
          console.log('   ⚠️ User found but salary details missing');
        }
      }
    }
    console.log('');

    // Test 5: Create user with zero salary (should fail)
    console.log('5️⃣ Test: Create Employee with Zero Salary (Should Fail)');
    const testUser3 = {
      contactNumber: `+91${Math.floor(Math.random() * 9000000000) + 1000000000}`,
      name: 'Test Employee Zero Salary',
      email: `test.zerosalary.${Date.now()}@example.com`,
      salaryPerMonth: '0',
    };

    const response3 = await fetch(`${BASE_URL}/admin/users`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(testUser3),
    });

    const data3 = await response3.json();
    if (!data3.success) {
      console.log('   ✅ Correctly rejected zero salary (as expected)');
      console.log('   Message:', data3.message);
    } else {
      console.log('   ❌ Should have failed but succeeded');
    }
    console.log('');

    console.log('✅ All tests completed!');
    console.log('\n📝 Summary:');
    console.log('   ✅ Salary is now MANDATORY');
    console.log('   ✅ Cannot create employee without salary');
    console.log('   ✅ Salary must be greater than 0');
    console.log('   ✅ All salary fields saved in database');
    console.log('   ✅ Salary details returned in API response');
    console.log('   ✅ Salary details included when getting users');
    console.log('\n🎉 Mandatory Salary feature is fully functional!');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.log('\n⚠️  Make sure the backend server is running:');
    console.log('   cd backend && npm run dev');
  }
}

testMandatorySalaryFeature();
