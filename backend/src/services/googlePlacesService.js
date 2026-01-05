import axios from 'axios';

const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY;
const PLACES_API_URL = 'https://maps.googleapis.com/maps/api/place';

/**
 * Business type mapping to Google Places types
 * Reference: https://developers.google.com/maps/documentation/places/web-service/supported_types
 */
const BUSINESS_TYPE_MAPPING = {
  grocery: ['grocery_or_supermarket', 'supermarket'],
  cafe: ['cafe', 'coffee_shop'],
  hotel: ['lodging'],  // lodging covers hotels, motels, etc.
  dairy: ['grocery_or_supermarket', 'store'],
  restaurant: ['restaurant', 'meal_takeaway', 'meal_delivery'],
  bakery: ['bakery'],
  pharmacy: ['pharmacy'],
  supermarket: ['supermarket', 'grocery_or_supermarket'],
  hostel: ['lodging'],  // hostel is also lodging type
  schools: ['school', 'primary_school', 'secondary_school'],
  colleges: ['university'],
  hospitals: ['hospital', 'doctor'],
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
    // Validate API key
    if (!GOOGLE_MAPS_API_KEY) {
      return {
        success: false,
        message: 'Google Maps API key not configured',
        businesses: []
      };
    }

    const types = BUSINESS_TYPE_MAPPING[businessType.toLowerCase()] || ['store'];
    const allResults = [];

    console.log(`🔍 Searching for ${businessType} near (${latitude}, ${longitude})`);
    console.log(`📋 Using Google Places types: ${types.join(', ')}`);

    for (const type of types) {
      try {
        const response = await axios.get(`${PLACES_API_URL}/nearbysearch/json`, {
          params: {
            location: `${latitude},${longitude}`,
            radius: radius,
            type: type,
            key: GOOGLE_MAPS_API_KEY
          }
        });

        if (response.data.status === 'OK' && response.data.results) {
          console.log(`✅ Found ${response.data.results.length} results for type: ${type}`);
          allResults.push(...response.data.results);
        } else if (response.data.status === 'ZERO_RESULTS') {
          console.log(`⚠️ No results for type: ${type}`);
        } else {
          console.log(`⚠️ API error for type ${type}: ${response.data.status} - ${response.data.error_message || ''}`);
        }
      } catch (error) {
        console.error(`❌ Error searching type ${type}:`, error.message);
      }

      // Add delay to avoid rate limiting
      await new Promise(resolve => setTimeout(resolve, 200));
    }

    // Remove duplicates based on place_id
    const uniqueResults = Array.from(
      new Map(allResults.map(item => [item.place_id, item])).values()
    );

    console.log(`📊 Total unique results: ${uniqueResults.length}`);

    return {
      success: true,
      businesses: uniqueResults.map(place => ({
        placeId: place.place_id,
        name: place.name,
        address: place.vicinity,
        latitude: place.geometry?.location?.lat,
        longitude: place.geometry?.location?.lng,
        rating: place.rating,
        userRatingsTotal: place.user_ratings_total,
        businessType: businessType,
        openNow: place.opening_hours?.open_now,
        photos: place.photos?.map(p => ({ photoReference: p.photo_reference })) || [],
        priceLevel: place.price_level
      }))
    };
  } catch (error) {
    console.error('Places search error:', error.message);
    return {
      success: false,
      message: 'Failed to search businesses',
      error: error.message,
      businesses: []
    };
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
        fields: 'name,formatted_address,formatted_phone_number,geometry,rating,types,reviews,photos,opening_hours,user_ratings_total,price_level,website',
        key: GOOGLE_MAPS_API_KEY
      }
    });

    if (response.data.result) {
      const place = response.data.result;
      
      // Format photos with photo references
      const photos = place.photos?.map(photo => ({
        photoReference: photo.photo_reference,
        width: photo.width,
        height: photo.height
      })) || [];

      // Format reviews
      const reviews = place.reviews?.map(review => ({
        authorName: review.author_name,
        profilePhotoUrl: review.profile_photo_url,
        rating: review.rating,
        text: review.text,
        relativeTimeDescription: review.relative_time_description,
        time: review.time
      })) || [];

      return {
        success: true,
        place: {
          ...place,
          photos,
          reviews,
          userRatingsTotal: place.user_ratings_total,
          priceLevel: place.price_level,
          openNow: place.opening_hours?.open_now,
          openingHours: place.opening_hours?.weekday_text
        }
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
    console.log(`\n🔍 Searching businesses in pincode: ${pincode}`);
    console.log(`📋 Business types requested: ${businessTypes.join(', ')}`);

    // Validate API key
    if (!GOOGLE_MAPS_API_KEY) {
      console.error('❌ Google Maps API key not configured');
      return {
        success: false,
        message: 'Google Maps API key not configured',
        businesses: []
      };
    }

    // Get coordinates for pincode
    const coordsResult = await getCoordinatesFromPincode(pincode);
    if (!coordsResult.success) {
      console.log(`❌ Could not geocode pincode ${pincode}: ${coordsResult.message}`);
      return {
        success: false,
        message: `Could not find location for pincode ${pincode}`,
        businesses: []
      };
    }

    const { latitude, longitude } = coordsResult;
    console.log(`📍 Coordinates: ${latitude}, ${longitude}`);

    const allBusinesses = [];
    const breakdown = {};

    // Search for each business type (convert to lowercase for mapping)
    for (const businessType of businessTypes) {
      const normalizedType = businessType.toLowerCase();
      console.log(`\n🔎 Searching for: ${businessType} (normalized: ${normalizedType})`);

      try {
        const result = await searchBusinessesNearby(latitude, longitude, normalizedType);
        if (result.success && result.businesses) {
          allBusinesses.push(...result.businesses);
          breakdown[businessType] = result.businesses.length;
          console.log(`✅ Found ${result.businesses.length} ${businessType} businesses`);
        } else {
          console.log(`⚠️ Failed to search ${businessType}: ${result.message || 'Unknown error'}`);
          breakdown[businessType] = 0;
        }
      } catch (error) {
        console.error(`❌ Error searching ${businessType}:`, error.message);
        breakdown[businessType] = 0;
      }
    }

    // Remove duplicates based on placeId
    const uniqueBusinesses = [];
    const seenPlaceIds = new Set();

    for (const business of allBusinesses) {
      if (business.placeId && !seenPlaceIds.has(business.placeId)) {
        seenPlaceIds.add(business.placeId);
        uniqueBusinesses.push(business);
      }
    }

    console.log(`\n📊 Total businesses found: ${uniqueBusinesses.length}`);
    console.log(`📊 Breakdown:`, breakdown);

    return {
      success: true,
      totalBusinesses: uniqueBusinesses.length,
      breakdown: breakdown,
      businesses: uniqueBusinesses,
      message: `Found ${uniqueBusinesses.length} businesses in pincode ${pincode}`
    };
  } catch (error) {
    console.error('❌ Business search error:', error.message);
    return {
      success: false,
      message: 'Failed to search businesses',
      error: error.message,
      businesses: []
    };
  }
};
