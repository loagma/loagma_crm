import axios from 'axios';

/**
 * Fetch location details from Indian Postal Pincode API
 * @param {string} pincode - 6-digit pincode
 * @returns {Promise<Object>} Location details
 */
export const getLocationByPincode = async (pincode) => {
  try {
    // Validate pincode format
    if (!/^\d{6}$/.test(pincode)) {
      throw new Error('Invalid pincode format. Must be 6 digits.');
    }

    // Use India Post API
    const response = await axios.get(
      `https://api.postalpincode.in/pincode/${pincode}`,
      { timeout: 5000 }
    );

    if (response.data && response.data[0]?.Status === 'Success') {
      const postOffice = response.data[0].PostOffice[0];
      
      return {
        success: true,
        data: {
          pincode: pincode,
          country: postOffice.Country || 'India',
          state: postOffice.State || postOffice.Circle,
          district: postOffice.District,
          city: postOffice.Division || postOffice.District,
          area: postOffice.Name,
          region: postOffice.Region,
        },
      };
    } else {
      return {
        success: false,
        message: 'Pincode not found or invalid',
      };
    }
  } catch (error) {
    console.error('Pincode lookup error:', error.message);
    return {
      success: false,
      message: 'Failed to fetch location details',
      error: error.message,
    };
  }
};

/**
 * Validate and format pincode
 * @param {string} pincode
 * @returns {string} Formatted pincode
 */
export const validatePincode = (pincode) => {
  const cleaned = pincode.replace(/\D/g, '');
  if (cleaned.length !== 6) {
    throw new Error('Pincode must be exactly 6 digits');
  }
  return cleaned;
};
