import axios from 'axios';

const BASE_URL = 'http://localhost:5000/api/admin';

// Test data
const testUser = {
  contactNumber: '9999888877',
  name: 'Test Employee',
  email: 'test.employee@example.com',
  salaryPerMonth: 45000,
  roleId: null, // Will be set after fetching roles
  departmentId: null, // Will be set after fetching departments
  gender: 'Male',
  preferredLanguages: ['English', 'Hindi'],
  isActive: true,
  password: 'Test@123',
  address: '123 Test Street',
  city: 'Mumbai',
  state: 'Maharashtra',
  pincode: '400001',
  country: 'India',
  district: 'Mumbai',
  aadharCard: '123456789012',
  panCard: 'ABCDE1234F',
  notes: 'Test employee for CRUD operations',
  image: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
};

let createdUserId = null;

async function testCreateUser() {
  console.log('\n📝 Testing CREATE User...');
  try {
    // First, get roles and departments
    const rolesRes = await axios.get('http://localhost:5000/api/roles');
    const depsRes = await axios.get('http://localhost:5000/api/departments');

    if (rolesRes.data.roles && rolesRes.data.roles.length > 0) {
      testUser.roleId = rolesRes.data.roles[0].id;
    }

    if (depsRes.data.departments && depsRes.data.departments.length > 0) {
      testUser.departmentId = depsRes.data.departments[0].id;
    }

    const response = await axios.post(`${BASE_URL}/users`, testUser);

    if (response.data.success) {
      createdUserId = response.data.user.id;
      console.log('✅ User created successfully');
      console.log('   User ID:', createdUserId);
      console.log('   Name:', response.data.user.name);
      console.log('   Email:', response.data.user.email);
      console.log('   Country:', response.data.user.country);
      console.log('   District:', response.data.user.district);
      console.log('   Image:', response.data.user.image ? 'Set' : 'Not set');
      return true;
    } else {
      console.log('❌ Failed to create user:', response.data.message);
      return false;
    }
  } catch (error) {
    console.log('❌ Error creating user:', error.response?.data?.message || error.message);
    return false;
  }
}

async function testGetAllUsers() {
  console.log('\n📋 Testing GET All Users...');
  try {
    const response = await axios.get(`${BASE_URL}/users`);

    if (response.data.success) {
      console.log('✅ Fetched users successfully');
      console.log('   Total users:', response.data.users.length);

      // Find our test user
      const testUserData = response.data.users.find(u => u.id === createdUserId);
      if (testUserData) {
        console.log('   Test user found in list');
        console.log('   Has image:', !!testUserData.image);
        console.log('   Has country:', !!testUserData.country);
        console.log('   Has district:', !!testUserData.district);
        console.log('   Has salary:', !!testUserData.salaryDetails);
      }
      return true;
    } else {
      console.log('❌ Failed to fetch users');
      return false;
    }
  } catch (error) {
    console.log('❌ Error fetching users:', error.response?.data?.message || error.message);
    return false;
  }
}

async function testCheckDuplicatePhone() {
  console.log('\n🔍 Testing Duplicate Phone Check...');
  try {
    const response = await axios.get(
      `${BASE_URL}/users?contactNumber=${testUser.contactNumber}`
    );

    if (response.data.success && response.data.users.length > 0) {
      console.log('✅ Duplicate check working');
      console.log('   Found user:', response.data.users[0].name);
      return true;
    } else {
      console.log('❌ Duplicate check failed');
      return false;
    }
  } catch (error) {
    console.log('❌ Error checking duplicate:', error.response?.data?.message || error.message);
    return false;
  }
}

async function testUpdateUser() {
  console.log('\n✏️  Testing UPDATE User...');
  try {
    const updateData = {
      name: 'Updated Test Employee',
      city: 'Pune',
      district: 'Pune',
      notes: 'Updated notes',
      image: 'https://res.cloudinary.com/demo/image/upload/updated.jpg',
    };

    const response = await axios.put(`${BASE_URL}/users/${createdUserId}`, updateData);

    if (response.data.success) {
      console.log('✅ User updated successfully');
      console.log('   Updated name:', response.data.user.name);
      return true;
    } else {
      console.log('❌ Failed to update user');
      return false;
    }
  } catch (error) {
    console.log('❌ Error updating user:', error.response?.data?.message || error.message);
    return false;
  }
}

async function testDeleteUser() {
  console.log('\n🗑️  Testing DELETE User...');
  try {
    const response = await axios.delete(`${BASE_URL}/users/${createdUserId}`);

    if (response.data.success) {
      console.log('✅ User deleted successfully');
      return true;
    } else {
      console.log('❌ Failed to delete user');
      return false;
    }
  } catch (error) {
    console.log('❌ Error deleting user:', error.response?.data?.message || error.message);
    return false;
  }
}

async function runAllTests() {
  console.log('🚀 Starting User CRUD Tests...');
  console.log('================================');

  const results = {
    create: await testCreateUser(),
    getAll: false,
    duplicateCheck: false,
    update: false,
    delete: false,
  };

  if (results.create && createdUserId) {
    results.getAll = await testGetAllUsers();
    results.duplicateCheck = await testCheckDuplicatePhone();
    results.update = await testUpdateUser();
    results.delete = await testDeleteUser();
  }

  console.log('\n================================');
  console.log('📊 Test Results:');
  console.log('================================');
  console.log('CREATE User:        ', results.create ? '✅ PASS' : '❌ FAIL');
  console.log('GET All Users:      ', results.getAll ? '✅ PASS' : '❌ FAIL');
  console.log('Duplicate Check:    ', results.duplicateCheck ? '✅ PASS' : '❌ FAIL');
  console.log('UPDATE User:        ', results.update ? '✅ PASS' : '❌ FAIL');
  console.log('DELETE User:        ', results.delete ? '✅ PASS' : '❌ FAIL');
  console.log('================================');

  const allPassed = Object.values(results).every(r => r === true);
  console.log(allPassed ? '✅ All tests passed!' : '❌ Some tests failed');
}

runAllTests();
