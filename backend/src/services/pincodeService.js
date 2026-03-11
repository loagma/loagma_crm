import axios from 'axios';

async function fetchIndiaPost(pincode, { retries = 3, timeoutMs = 12000 } = {}) {
  const url = `https://api.postalpincode.in/pincode/${pincode}`;
  let lastError;

  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      return await axios.get(url, { timeout: timeoutMs });
    } catch (e) {
      lastError = e;
      const code = e?.code;
      const isRetryable =
        code === 'ECONNRESET' || code === 'ETIMEDOUT' || code === 'ECONNABORTED';
      if (!isRetryable || attempt === retries) break;
      await new Promise((r) => setTimeout(r, 500 * (attempt + 1)));
    }
  }

  throw lastError;
}

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
    const response = await fetchIndiaPost(pincode, { retries: 2, timeoutMs: 7000 });

    if (response.data && response.data[0]?.Status === 'Success') {
      const postOffices = response.data[0].PostOffice;

      // Extract all unique area names
      const areas = [...new Set(postOffices.map(po => po.Name))];

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
          areas: areas, // Return all areas as array
          // Keep single area for backward compatibility
          area: firstOffice.Name,
        },
      };
    } else {
      return {
        success: false,
        message: 'Pincode not found or invalid',
      };
    }
  } catch (error) {
    const code = error?.code;
    console.error('Pincode lookup error:', code || error.message);
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
    const response = await fetchIndiaPost(pincode, { retries: 2, timeoutMs: 7000 });

    if (response.data && response.data[0]?.Status === 'Success') {
      const postOffices = response.data[0].PostOffice;

      // Extract unique area names
      const areas = [...new Set(postOffices.map(po => po.Name))];

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
    const code = error?.code;
    console.error('Areas lookup error:', code || error.message);
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
