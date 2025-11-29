import axios from 'axios';

const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY;
const PLACES_API_URL = 'https://maps.googleapis.com/maps/api/place';

/**
 * Business type mapping to Google Places types
 */
const BUSINESS_TYPE_MAPPING = {
  grocery: ['grocery_or_supermarket', 'supermarket'],
  cafe: ['cafe'],
  hotel: ['lodging', 'hotel'],
  dairy: ['store'],
  restaurant: ['restaurant'],
  bakery: ['bakery'],
  pharmacy: ['pharmacy', 'drugstore'],
  supermarket: ['supermarket'],
  others: ['store', 'establishment']
};

/**
 * Get coordinates for a pincode using Geocoding API
 */
export const getCoordinatesFromPincode = async (pincode, country = 'India') => {
  try {
    const response = await axios.get(`${PLACES_API_URL}/textsearch/json`, {
      params: {
        query: `${pincode}, ${country}`,
        key: GOOGLE_MAPS_API_KEY
      }
    });

    if (response.data.results && response.data.results.length > 0) {
      const location = response.data.results[0].geometry.location;
      return {
        success: true,
        latitude: location.lat,
        longitude: location.lng
      };
    }

    return { success: false, message: 'Location not found' };
  } catch (error) {
    console.error('Geocoding error:', error.message);
    return { success: false, message: 'Failed to get coordinates', error: error.message };
  }
};

/**
 * Search for businesses near a location
 */
export const searchBusinessesNearby = async (latitude, longitude, businessType, radius = 5000) => {
  try {
    const types = BUSINESS_TYPE_MAPPING[businessType] || ['store'];
    const allResults = [];

    for (const type of types) {
      const response = await axios.get(`${PLACES_API_URL}/nearbysearch/json`, {
        params: {
          location: `${latitude},${longitude}`,
          radius: radius,
          type: type,
          key: GOOGLE_MAPS_API_KEY
        }
      });

      if (response.data.results) {
        allResults.push(...response.data.results);
      }
    }

    // Remove duplicates based on place_id
    const uniqueResults = Array.from(
      new Map(allResults.map(item => [item.place_id, item])).values()
    );

    return {
      success: true,
      businesses: uniqueResults.map(place => ({
        placeId: place.place_id,
        name: place.name,
        address: place.vicinity,
        latitude: place.geometry.location.lat,
        longitude: place.geometry.location.lng,
        rating: place.rating,
        businessType: businessType
      }))
    };
  } catch (error) {
    console.error('Places search error:', error.message);
    return { success: false, message: 'Failed to search businesses', error: error.message };
  }
};

/**
 * Get place details by place ID
 */
export const getPlaceDetails = async (placeId) => {
  try {
    const response = await axios.get(`${PLACES_API_URL}/details/json`, {
      params: {
        place_id: placeId,
        fields: 'name,formatted_address,formatted_phone_number,geometry,rating,types',
        key: GOOGLE_MAPS_API_KEY
      }
    });

    if (response.data.result) {
      return {
        success: true,
        place: response.data.result
      };
    }

    return { success: false, message: 'Place not found' };
  } catch (error) {
    console.error('Place details error:', error.message);
    return { success: false, message: 'Failed to get place details', error: error.message };
  }
};

/**
 * Search businesses by pincode and business types
 */
export const searchBusinessesByPincode = async (pincode, businessTypes, areas = []) => {
  try {
    // Get coordinates for pincode
    const coordsResult = await getCoordinatesFromPincode(pincode);
    if (!coordsResult.success) {
      return coordsResult;
    }

    const { latitude, longitude } = coordsResult;
    const allBusinesses = [];
    const breakdown = {};

    // Search for each business type
    for (const businessType of businessTypes) {
      const result = await searchBusinessesNearby(latitude, longitude, businessType);
      if (result.success) {
        allBusinesses.push(...result.businesses);
        breakdown[businessType] = result.businesses.length;
      }
    }

    return {
      success: true,
      totalBusinesses: allBusinesses.length,
      breakdown: breakdown,
      businesses: allBusinesses,
      message: `Found ${allBusinesses.length} businesses in pincode ${pincode}`
    };
  } catch (error) {
    console.error('Business search error:', error.message);
    return { success: false, message: 'Failed to search businesses', error: error.message };
  }
};
