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
 * Fetch all areas for a given pincode
 * @param {string} pincode - 6-digit pincode
 * @returns {Promise<Object>} List of areas with location details
 */
export const getAreasByPincode = async (pincode) => {
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
      const postOffices = response.data[0].PostOffice;
      
      // Extract unique areas
      const areas = postOffices.map(po => ({
        name: po.Name,
        branchType: po.BranchType,
        deliveryStatus: po.DeliveryStatus,
      }));

      // Get common location data from first post office
      const firstOffice = postOffices[0];
      
      return {
        success: true,
        data: {
          pincode: pincode,
          country: firstOffice.Country || 'India',
          state: firstOffice.State || firstOffice.Circle,
          district: firstOffice.District,
          city: firstOffice.Division || firstOffice.District,
          region: firstOffice.Region,
          areas: areas,
        },
      };
    } else {
      return {
        success: false,
        message: 'Pincode not found or invalid',
      };
    }
  } catch (error) {
    console.error('Areas lookup error:', error.message);
    return {
      success: false,
      message: 'Failed to fetch areas',
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
