import axios from 'axios';

const BASE_URL = 'http://localhost:5000';

// Test with actual employee ID
const TEST_EMPLOYEE_ID = '000013'; // om's ID

async function testGetAssignments() {
    console.log('🔍 Testing Get Assignments...\n');
    console.log('Employee ID:', TEST_EMPLOYEE_ID);
    console.log('');

    try {
        const url = `${BASE_URL}/task-assignments/assignments/salesman/${TEST_EMPLOYEE_ID}`;
        console.log('📡 URL:', url);

        const response = await axios.get(url);

        console.log('✅ Response Status:', response.status);
        console.log('📥 Response Data:', JSON.stringify(response.data, null, 2));

        if (response.data.success) {
            const assignments = response.data.assignments || [];
            console.log(`\n✅ Found ${assignments.length} assignments`);

            assignments.forEach((assignment, index) => {
                console.log(`\n${index + 1}. Assignment:`);
                console.log(`   Pincode: ${assignment.pincode}`);
                console.log(`   City: ${assignment.city}`);
                console.log(`   State: ${assignment.state}`);
                console.log(`   Areas: ${assignment.areas?.length || 0}`);
                console.log(`   Business Types: ${assignment.businessTypes?.length || 0}`);
                console.log(`   Total Businesses: ${assignment.totalBusinesses || 0}`);
                console.log(`   Assigned Date: ${assignment.assignedDate}`);
            });
        }
    } catch (error) {
        console.error('❌ Error:', error.response?.data || error.message);
    }
}

async function testCreateAssignment() {
    console.log('\n📝 Testing Create Assignment...\n');

    try {
        const response = await axios.post(
            `${BASE_URL}/task-assignments/assignments/areas`,
            {
                salesmanId: TEST_EMPLOYEE_ID,
                salesmanName: 'om',
                pincode: '110001',
                country: 'India',
                state: 'Delhi',
                district: 'Central Delhi',
                city: 'New Delhi',
                areas: ['Connaught Place', 'Rajiv Chowk', 'Janpath'],
                businessTypes: ['grocery', 'restaurant', 'cafe'],
                totalBusinesses: 15
            }
        );

        console.log('✅ Assignment Created:', JSON.stringify(response.data, null, 2));
    } catch (error) {
        console.error('❌ Error:', error.response?.data || error.message);
    }
}

async function main() {
    console.log('🚀 Testing Task Assignments API\n');
    console.log('='.repeat(50));

    // Test getting assignments
    await testGetAssignments();

    console.log('\n' + '='.repeat(50));
    console.log('\n💡 If no assignments found, you can create one:');
    console.log('   Run: node scripts/test-assignments.js create\n');

    // Check if we should create a test assignment
    if (process.argv.includes('create')) {
        console.log('='.repeat(50));
        await testCreateAssignment();
        console.log('\n' + '='.repeat(50));
        console.log('\n✅ Now fetching assignments again...\n');
        console.log('='.repeat(50));
        await testGetAssignments();
    }

    console.log('\n' + '='.repeat(50));
    console.log('✅ Tests completed!');
}

main();
