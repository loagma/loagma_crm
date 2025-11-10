/**
 * Clean and normalize phone numbers
 * Removes spaces, dashes, and other non-digit characters
 */
export const cleanPhoneNumber = (phoneNumber) => {
  if (!phoneNumber) return '';
  
  // Remove all non-digit characters except +
  let cleaned = phoneNumber.replace(/[^\d+]/g, '');
  
  // Remove leading + if present
  if (cleaned.startsWith('+')) {
    cleaned = cleaned.substring(1);
  }
  
  // Remove country code if it's 91 (India) and number is 12 digits
  if (cleaned.startsWith('91') && cleaned.length === 12) {
    cleaned = cleaned.substring(2);
  }
  
  return cleaned;
};
