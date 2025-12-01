import dotenv from 'dotenv';
import twilio from 'twilio';

dotenv.config();

console.log('🔍 Testing Twilio Configuration...\n');

// Check environment variables
const accountSid = process.env.TWILIO_SID || process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const twilioPhone = process.env.TWILIO_PHONE || process.env.TWILIO_PHONE_NUMBER;

console.log('📋 Environment Variables:');
console.log(`   TWILIO_SID: ${accountSid ? '✅ Set (' + accountSid.substring(0, 10) + '...)' : '❌ Missing'}`);
console.log(`   TWILIO_AUTH_TOKEN: ${authToken ? '✅ Set (' + authToken.substring(0, 5) + '...)' : '❌ Missing'}`);
console.log(`   TWILIO_PHONE: ${twilioPhone ? '✅ Set (' + twilioPhone + ')' : '❌ Missing'}`);
console.log('');

if (!accountSid || !authToken || !twilioPhone) {
  console.error('❌ Missing required Twilio credentials!');
  console.error('Please check your .env file has:');
  console.error('   TWILIO_SID=your_account_sid');
  console.error('   TWILIO_AUTH_TOKEN=your_auth_token');
  console.error('   TWILIO_PHONE=your_phone_number');
  process.exit(1);
}

// Test Twilio client initialization
try {
  console.log('🔧 Initializing Twilio client...');
  const client = twilio(accountSid, authToken);
  console.log('✅ Twilio client initialized successfully\n');

  // Test account validation
  console.log('🔐 Validating Twilio account...');
  const account = await client.api.accounts(accountSid).fetch();
  console.log(`✅ Account validated: ${account.friendlyName}`);
  console.log(`   Status: ${account.status}`);
  console.log(`   Type: ${account.type}\n`);

  console.log('✅ All Twilio checks passed!');
  console.log('🎉 Your Twilio configuration is working properly\n');
  
} catch (error) {
  console.error('❌ Twilio Authentication Error:', error.message);
  if (error.code) {
    console.error(`   Error Code: ${error.code}`);
  }
  if (error.status === 401) {
    console.error('\n💡 This is an authentication error. Please check:');
    console.error('   1. Your TWILIO_SID is correct (starts with AC)');
    console.error('   2. Your TWILIO_AUTH_TOKEN is correct');
    console.error('   3. The credentials match your Twilio account');
  }
  process.exit(1);
}
