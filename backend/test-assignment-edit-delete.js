/**
 * Test script for assignment edit and delete endpoints
 * Run: node test-assignment-edit-delete.js
 */

const BASE_URL = 'http://localhost:5000/api/task-assignments';

// Test data
let testAssignmentId = null;

async function testUpdateAssignment() {
  console.log('\n🧪 Testing UPDATE Assignment...');
  
  if (!testAssignmentId) {
    console.log('⚠️ No assignment ID available. Create an assignment first.');
    return;
  }

  try {
    const response = await fetch(`${BASE_URL}/assignments/${testAssignmentId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        areas: ['Updated Area 1', 'Updated Area 2'],
        businessTypes: ['grocery', 'pharmacy'],
        totalBusinesses: 25
      })
    });

    const data = await response.json();
    console.log('📡 Response:', data);

    if (data.success) {
      console.log('✅ Assignment updated successfully!');
      console.log('   Updated areas:', data.assignment.areas);
      console.log('   Updated business types:', data.assignment.businessTypes);
    } else {
      console.log('❌ Update failed:', data.message);
    }
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

async function testDeleteAssignment() {
  console.log('\n🧪 Testing DELETE Assignment...');
  
  if (!testAssignmentId) {
    console.log('⚠️ No assignment ID available. Create an assignment first.');
    return;
  }

  try {
    const response = await fetch(`${BASE_URL}/assignments/${testAssignmentId}`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
      }
    });

    const data = await response.json();
    console.log('📡 Response:', data);

    if (data.success) {
      console.log('✅ Assignment deleted successfully!');
      testAssignmentId = null;
    } else {
      console.log('❌ Delete failed:', data.message);
    }
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

async function getExistingAssignment() {
  console.log('\n🔍 Fetching existing assignments...');
  
  try {
    // First, get a salesman
    const salesmenResponse = await fetch(`${BASE_URL}/salesmen`);
    const salesmenData = await salesmenResponse.json();
    
    if (!salesmenData.success || salesmenData.salesmen.length === 0) {
      console.log('❌ No salesmen found');
      return;
    }

    const salesmanId = salesmenData.salesmen[0].id;
    console.log('👤 Using salesman:', salesmenData.salesmen[0].name);

    // Get assignments for this salesman
    const assignmentsResponse = await fetch(`${BASE_URL}/assignments/salesman/${salesmanId}`);
    const assignmentsData = await assignmentsResponse.json();

    if (assignmentsData.success && assignmentsData.assignments.length > 0) {
      testAssignmentId = assignmentsData.assignments[0].id;
      console.log('✅ Found assignment:', testAssignmentId);
      console.log('   Pincode:', assignmentsData.assignments[0].pincode);
      console.log('   City:', assignmentsData.assignments[0].city);
      return true;
    } else {
      console.log('⚠️ No assignments found for this salesman');
      return false;
    }
  } catch (error) {
    console.error('❌ Error:', error.message);
    return false;
  }
}

async function runTests() {
  console.log('🚀 Starting Assignment Edit/Delete API Tests...');
  console.log('📍 Base URL:', BASE_URL);
  
  // Get an existing assignment to test with
  const hasAssignment = await getExistingAssignment();
  
  if (!hasAssignment) {
    console.log('\n⚠️ Please create an assignment first using the app, then run this test again.');
    return;
  }

  // Test update
  await testUpdateAssignment();
  
  // Wait a bit
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  // Test delete (comment this out if you want to keep the assignment)
  // await testDeleteAssignment();
  
  console.log('\n✅ Tests completed!');
  console.log('\n💡 Note: Delete test is commented out to preserve data.');
  console.log('   Uncomment the delete test in the code if you want to test deletion.');
}

// Run the tests
runTests();
