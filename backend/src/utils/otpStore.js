// Temporary in-memory OTP storage for new users
// In production, use Redis or similar
const otpStore = new Map();

export const storeOTP = (contactNumber, otp, expiryTime) => {
  otpStore.set(contactNumber, { otp, expiryTime });
};

export const getOTP = (contactNumber) => {
  return otpStore.get(contactNumber);
};

export const deleteOTP = (contactNumber) => {
  otpStore.delete(contactNumber);
};

export const cleanExpiredOTPs = () => {
  const now = Date.now();
  for (const [number, data] of otpStore.entries()) {
    if (now > data.expiryTime) {
      otpStore.delete(number);
    }
  }
};

// Clean expired OTPs every 5 minutes
setInterval(cleanExpiredOTPs, 5 * 60 * 1000);
