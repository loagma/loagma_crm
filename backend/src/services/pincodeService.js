import axios from 'axios';

const PINCODE_LOOKUP_URL = 'https://api.postalpincode.in/pincode';
const GOOGLE_GEOCODE_URL = 'https://maps.googleapis.com/maps/api/geocode/json';
const PINCODE_CACHE_TTL_MS = 24 * 60 * 60 * 1000;
const pincodeCache = new Map();
const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY || '';

const RETRYABLE_ERROR_CODES = new Set([
  'ECONNRESET',
  'ETIMEDOUT',
  'ECONNABORTED',
  'ENOTFOUND',
  'EAI_AGAIN',
]);

const normalizePincode = (pincode) => String(pincode || '').trim();

const getCachedEntry = (pincode) => pincodeCache.get(pincode) || null;

const getCachedPayload = (pincode, { allowExpired = false } = {}) => {
  const cached = getCachedEntry(pincode);
  if (!cached) return null;
  if (!allowExpired && Date.now() - cached.cachedAt > PINCODE_CACHE_TTL_MS) {
    pincodeCache.delete(pincode);
    return null;
  }
  return cached.payload;
};

const setCachedPayload = (pincode, payload) => {
  pincodeCache.set(pincode, {
    payload,
    cachedAt: Date.now(),
  });
};

const isRetryableError = (error) => {
  const code = error?.code;
  return RETRYABLE_ERROR_CODES.has(code);
};

const logLookupFailure = (label, pincode, error) => {
  const code = error?.code || 'UNKNOWN';
  const message = error?.message || 'Unknown error';
  console.error(`${label} lookup error for ${pincode}: ${code} - ${message}`);
};

async function fetchIndiaPost(pincode, { retries = 0, timeoutMs = 3000 } = {}) {
  const normalizedPincode = normalizePincode(pincode);
  const freshCachedPayload = getCachedPayload(normalizedPincode);
  if (freshCachedPayload) {
    return { payload: freshCachedPayload, fromCache: true, staleFallback: false };
  }

  const url = `${PINCODE_LOOKUP_URL}/${normalizedPincode}`;
  let lastError;

  for (let attempt = 0; attempt <= retries; attempt += 1) {
    try {
      const response = await axios.get(url, { timeout: timeoutMs });
      const payload = response?.data;
      setCachedPayload(normalizedPincode, payload);
      return { payload, fromCache: false, staleFallback: false };
    } catch (error) {
      lastError = error;
      if (!isRetryableError(error) || attempt === retries) break;
      await new Promise((resolve) => setTimeout(resolve, 350 * (attempt + 1)));
    }
  }

  const staleCachedPayload = getCachedPayload(normalizedPincode, { allowExpired: true });
  if (staleCachedPayload) {
    return { payload: staleCachedPayload, fromCache: true, staleFallback: true };
  }

  throw lastError;
}

const parseAddressComponent = (components, wantedTypes) => {
  if (!Array.isArray(components)) return '';
  const match = components.find((component) =>
    Array.isArray(component.types) &&
    wantedTypes.some((type) => component.types.includes(type)),
  );
  return match?.long_name || '';
};

const buildGoogleFallbackData = (pincode, payload) => {
  const firstResult = payload?.results?.[0];
  if (!firstResult) return null;

  const components = firstResult.address_components || [];
  const state = parseAddressComponent(components, ['administrative_area_level_1']);
  const district = parseAddressComponent(components, [
    'administrative_area_level_2',
    'administrative_area_level_3',
  ]);
  const city =
    parseAddressComponent(components, ['locality']) ||
    parseAddressComponent(components, ['postal_town']) ||
    district;
  const sublocality =
    parseAddressComponent(components, ['sublocality', 'sublocality_level_1']) ||
    parseAddressComponent(components, ['neighborhood']);
  const country = parseAddressComponent(components, ['country']) || 'India';
  const areas = [sublocality, city, district].filter(Boolean);

  return {
    pincode,
    country,
    state,
    district,
    city,
    region: district || city,
    area: sublocality || city || district || pincode,
    areas: [...new Set(areas)].slice(0, 10),
    fallbackSource: 'google-geocode',
  };
};

async function fetchGooglePincodeFallback(pincode, { timeoutMs = 2500 } = {}) {
  if (!GOOGLE_MAPS_API_KEY) return null;

  const response = await axios.get(GOOGLE_GEOCODE_URL, {
    timeout: timeoutMs,
    params: {
      address: `${pincode}, India`,
      components: `country:IN|postal_code:${pincode}`,
      key: GOOGLE_MAPS_API_KEY,
    },
  });

  if (response?.data?.status !== 'OK') {
    return null;
  }

  return buildGoogleFallbackData(pincode, response.data);
}

const parseIndiaPostPayload = (payload, pincode) => {
  if (payload && payload[0]?.Status === 'Success' && Array.isArray(payload[0]?.PostOffice)) {
    const postOffices = payload[0].PostOffice.filter(Boolean);
    if (postOffices.length === 0) {
      return {
        success: false,
        httpStatus: 404,
        message: 'Pincode not found or invalid',
      };
    }

    const areas = [...new Set(postOffices.map((po) => po.Name).filter(Boolean))];
    const firstOffice = postOffices[0];
    return {
      success: true,
      data: {
        pincode,
        country: firstOffice.Country || 'India',
        state: firstOffice.State || firstOffice.Circle,
        district: firstOffice.District,
        city: firstOffice.Division || firstOffice.District,
        region: firstOffice.Region,
        areas,
        area: firstOffice.Name,
      },
    };
  }

  return {
    success: false,
    httpStatus: 404,
    message: 'Pincode not found or invalid',
  };
};

const buildTransientFailureResult = (baseMessage, error, fallbackData = null) => {
  const code = error?.code;
  const isTimeout = code === 'ECONNABORTED' || code === 'ETIMEDOUT';
  const isTransient = isRetryableError(error);

  if (fallbackData) {
    return {
      success: true,
      data: {
        ...fallbackData,
        stale: true,
      },
      message: 'Returned cached pincode data because the postal service is temporarily unavailable.',
      fromCache: true,
      stale: true,
    };
  }

  return {
    success: false,
    httpStatus: isTransient ? 200 : 502,
    temporary: isTransient,
    message: isTimeout
      ? `${baseMessage} The postal service is currently slow or unavailable. Please try again later.`
      : baseMessage,
    error: error?.message || 'Unknown error',
  };
};

/**
 * Fetch location details from Indian Postal Pincode API
 * @param {string} pincode - 6-digit pincode
 * @returns {Promise<Object>} Location details
 */
export const getLocationByPincode = async (pincode) => {
  const normalizedPincode = normalizePincode(pincode);
  try {
    // Validate pincode format
    if (!/^\d{6}$/.test(normalizedPincode)) {
      return {
        success: false,
        httpStatus: 400,
        message: 'Invalid pincode format. Must be 6 digits.',
      };
    }

    const { payload, fromCache, staleFallback } = await fetchIndiaPost(normalizedPincode);
    const result = parseIndiaPostPayload(payload, normalizedPincode);
    if (result.success) {
      return {
        ...result,
        fromCache,
        stale: staleFallback,
      };
    }
    return result;
  } catch (error) {
    try {
      const fallbackData = await fetchGooglePincodeFallback(normalizedPincode);
      if (fallbackData) {
        console.warn(
          `Pincode lookup fallback used for ${normalizedPincode}: primary provider ${error?.code || error?.message || 'failed'}`,
        );
        return {
          success: true,
          data: fallbackData,
          fallbackSource: 'google-geocode',
          stale: false,
        };
      }
    } catch (fallbackError) {
      console.warn(
        `Pincode fallback failed for ${normalizedPincode}: ${fallbackError?.code || fallbackError?.message || 'unknown error'}`,
      );
    }

    logLookupFailure('Pincode', normalizedPincode, error);
    return buildTransientFailureResult(
      'Failed to fetch location details.',
      error,
      getCachedPayload(normalizedPincode, { allowExpired: true })
        ? parseIndiaPostPayload(
            getCachedPayload(normalizedPincode, { allowExpired: true }),
            normalizedPincode,
          ).data
        : null,
    );
  }
};

/**
 * Fetch all areas for a given pincode
 * @param {string} pincode - 6-digit pincode
 * @returns {Promise<Object>} List of areas with location details
 */
export const getAreasByPincode = async (pincode) => {
  const normalizedPincode = normalizePincode(pincode);
  try {
    // Validate pincode format
    if (!/^\d{6}$/.test(normalizedPincode)) {
      return {
        success: false,
        httpStatus: 400,
        message: 'Invalid pincode format. Must be 6 digits.',
      };
    }

    const { payload, fromCache, staleFallback } = await fetchIndiaPost(normalizedPincode);
    const parsed = parseIndiaPostPayload(payload, normalizedPincode);
    if (!parsed.success) {
      return parsed;
    }

    return {
      success: true,
      data: {
        pincode: parsed.data.pincode,
        country: parsed.data.country,
        state: parsed.data.state,
        district: parsed.data.district,
        city: parsed.data.city,
        region: parsed.data.region,
        areas: parsed.data.areas,
      },
      fromCache,
      stale: staleFallback,
    };
  } catch (error) {
    try {
      const fallbackData = await fetchGooglePincodeFallback(normalizedPincode);
      if (fallbackData) {
        console.warn(
          `Areas lookup fallback used for ${normalizedPincode}: primary provider ${error?.code || error?.message || 'failed'}`,
        );
        return {
          success: true,
          data: {
            pincode: fallbackData.pincode,
            country: fallbackData.country,
            state: fallbackData.state,
            district: fallbackData.district,
            city: fallbackData.city,
            region: fallbackData.region,
            areas: fallbackData.areas,
          },
          fallbackSource: 'google-geocode',
          stale: false,
        };
      }
    } catch (fallbackError) {
      console.warn(
        `Areas fallback failed for ${normalizedPincode}: ${fallbackError?.code || fallbackError?.message || 'unknown error'}`,
      );
    }

    logLookupFailure('Areas', normalizedPincode, error);
    const cachedPayload = getCachedPayload(normalizedPincode, { allowExpired: true });
    const cachedData = cachedPayload
      ? parseIndiaPostPayload(cachedPayload, normalizedPincode).data
      : null;
    const fallbackData = cachedData
      ? {
          pincode: cachedData.pincode,
          country: cachedData.country,
          state: cachedData.state,
          district: cachedData.district,
          city: cachedData.city,
          region: cachedData.region,
          areas: cachedData.areas,
        }
      : null;

    return buildTransientFailureResult(
      'Failed to fetch areas.',
      error,
      fallbackData,
    );
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
