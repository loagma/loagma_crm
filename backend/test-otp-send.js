import { sendOtpSMS } from './src/utils/smsService.js';

console.log('📱 Testing OTP SMS Sending...\n');

// Test phone number (change this to your test number)
const testPhone = '9285543488'; // Without +91
const testOtp = '123456';

console.log(`📞 Test Phone: +91${testPhone}`);
console.log(`🔢 Test OTP: ${testOtp}\n`);

console.log('⏳ Sending SMS...\n');

try {
  const result = await sendOtpSMS(testPhone, testOtp);
  
  if (result) {
    console.log('\n✅ SUCCESS! OTP SMS sent successfully');
    console.log('📱 Check your phone for the message');
  } else {
    console.log('\n❌ FAILED! SMS was not sent');
    console.log('Check the error messages above');
  }
} catch (error) {
  console.error('\n❌ ERROR:', error.message);
}
