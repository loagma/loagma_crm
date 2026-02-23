import { PrismaClient } from '@prisma/client';
import { randomUUID } from 'crypto';
import { searchBusinessesByPincode } from '../services/googlePlacesService.js';

const prisma = new PrismaClient();

/**
 * Get all shops for a pincode - both existing accounts and Google Places
 */
export const getShopsByPincode = async (req, res) => {
    try {
        const { pincode } = req.params;
        let { businessTypes } = req.query;

        // Handle businessTypes parameter - can be comma-separated string or array
        if (typeof businessTypes === 'string') {
            businessTypes = businessTypes.split(',').map(type => type.trim());
        } else if (!Array.isArray(businessTypes)) {
            businessTypes = ['store', 'restaurant', 'supermarket', 'bakery', 'cafe'];
        }

        console.log(`🔍 Getting all shops for pincode: ${pincode}`);
        console.log(`📋 Business types: ${businessTypes.join(', ')}`);

        // Get existing accounts (salesman-created shops) for this pincode
        const existingAccounts = await prisma.account.findMany({
            where: {
                pincode: pincode
            },
            include: {
                assignedTo: {
                    select: {
                        id: true,
                        name: true,
                        contactNumber: true,
                        roleId: true
                    }
                },
                createdBy: {
                    select: {
                        id: true,
                        name: true,
                        contactNumber: true,
                        roleId: true
                    }
                }
            }
        });

        console.log(`✅ Found ${existingAccounts.length} existing accounts`);

        // Get Google Places shops for this pincode
        let googlePlacesShops = [];
        try {
            const googleResult = await searchBusinessesByPincode(pincode, businessTypes);

            if (googleResult.success) {
                googlePlacesShops = googleResult.businesses || [];
                console.log(`✅ Found ${googlePlacesShops.length} Google Places shops`);
            } else {
                console.log(`⚠️ Google Places search failed: ${googleResult.message}`);
            }
        } catch (error) {
            console.error('❌ Google Places error:', error.message);
        }

        // Format the response
        const response = {
            success: true,
            pincode: pincode,
            totalShops: existingAccounts.length + googlePlacesShops.length,
            existingAccounts: {
                count: existingAccounts.length,
                shops: existingAccounts.map(account => ({
                    id: account.id,
                    type: 'existing_account',
                    name: account.personName || account.businessName || 'Unknown',
                    businessName: account.businessName,
                    businessType: account.businessType,
                    address: account.address,
                    pincode: account.pincode,
                    latitude: account.latitude,
                    longitude: account.longitude,
                    contactNumber: account.contactNumber,
                    isApproved: account.isApproved,
                    salesmanName: account.createdBy?.name,
                    salesmanId: account.createdById,
                    assignedTo: account.assignedTo?.name,
                    customerStage: account.customerStage,
                    funnelStage: account.funnelStage,
                    createdAt: account.createdAt
                }))
            },
            googlePlacesShops: {
                count: googlePlacesShops.length,
                shops: googlePlacesShops.map(shop => ({
                    id: `google_${shop.placeId}`,
                    type: 'google_place',
                    placeId: shop.placeId,
                    name: shop.name,
                    businessType: shop.businessType,
                    address: shop.address,
                    pincode: pincode,
                    latitude: shop.latitude,
                    longitude: shop.longitude,
                    rating: shop.rating,
                    userRatingsTotal: shop.userRatingsTotal,
                    openNow: shop.openNow,
                    photos: shop.photos || [],
                    priceLevel: shop.priceLevel,
                    isGooglePlace: true
                }))
            }
        };

        res.json(response);
    } catch (error) {
        console.error('❌ Get shops by pincode error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get shops for pincode',
            error: error.message
        });
    }
};

/**
 * Get shop details from Google Places
 */
export const getGooglePlaceDetails = async (req, res) => {
    try {
        const { placeId } = req.params;

        console.log(`🔍 Getting Google Place details for: ${placeId}`);

        const { getPlaceDetails } = await import('../services/googlePlacesService.js');
        const result = await getPlaceDetails(placeId);

        if (result.success) {
            res.json({
                success: true,
                place: result.place
            });
        } else {
            res.status(404).json({
                success: false,
                message: result.message || 'Place not found'
            });
        }
    } catch (error) {
        console.error('❌ Get Google Place details error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to get place details',
            error: error.message
        });
    }
};

/**
 * Create account from Google Place
 */
export const createAccountFromGooglePlace = async (req, res) => {
    try {
        const { placeId } = req.params;
        const {
            assignedToId,
            customerStage = 'Lead',
            funnelStage = 'Awareness',
            notes
        } = req.body;

        console.log(`🔍 Creating account from Google Place: ${placeId}`);

        // Get place details from Google
        const { getPlaceDetails } = await import('../services/googlePlacesService.js');
        const placeResult = await getPlaceDetails(placeId);

        if (!placeResult.success) {
            return res.status(404).json({
                success: false,
                message: 'Google Place not found'
            });
        }

        const place = placeResult.place;
        const userId = req.user?.id;

        // Extract address components
        const addressComponents = place.formatted_address?.split(',') || [];
        const pincode = addressComponents.find(comp => /^\d{6}$/.test(comp.trim()))?.trim();

        // Generate account code
        const accountCode = await generateAccountCode();

        // Create account
        const account = await prisma.account.create({
            data: {
                id: randomUUID(),
                accountCode,
                businessName: place.name,
                personName: place.name, // Use business name as person name for now
                businessType: 'others', // Default, can be updated later
                address: place.formatted_address,
                pincode: pincode,
                latitude: place.geometry?.location?.lat,
                longitude: place.geometry?.location?.lng,
                contactNumber: place.formatted_phone_number?.replace(/\D/g, '').slice(-10), // Extract 10 digits
                customerStage,
                funnelStage,
                notes: notes || `Created from Google Places (${placeId})`,
                assignedToId,
                createdById: userId,
                isApproved: false,
                isActive: true
            },
            include: {
                assignedTo: {
                    select: {
                        id: true,
                        name: true,
                        contactNumber: true,
                        roleId: true
                    }
                },
                createdBy: {
                    select: {
                        id: true,
                        name: true,
                        contactNumber: true,
                        roleId: true
                    }
                }
            }
        });

        console.log(`✅ Account created from Google Place: ${account.accountCode}`);

        res.status(201).json({
            success: true,
            message: 'Account created successfully from Google Place',
            data: account
        });
    } catch (error) {
        console.error('❌ Create account from Google Place error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create account from Google Place',
            error: error.message
        });
    }
};

// Helper function to generate account code
async function generateAccountCode() {
    const prefix = '000';
    const date = new Date();
    const year = date.getFullYear().toString().slice(-2);
    const month = (date.getMonth() + 1).toString().padStart(2, '0');

    // Try up to 10 times to generate a unique code
    for (let attempt = 0; attempt < 10; attempt++) {
        // Get count of all accounts with this year-month prefix
        const pattern = `${prefix}${year}${month}%`;
        const existingAccounts = await prisma.account.findMany({
            where: {
                accountCode: {
                    startsWith: `${prefix}${year}${month}`
                }
            },
            select: { accountCode: true },
            orderBy: { accountCode: 'desc' }
        });

        let sequence = 1;
        if (existingAccounts.length > 0) {
            // Extract the last sequence number and increment
            const lastCode = existingAccounts[0].accountCode;
            const lastSequence = parseInt(lastCode.slice(-4));
            sequence = lastSequence + 1;
        }

        const accountCode = `${prefix}${year}${month}${sequence.toString().padStart(4, '0')}`;

        // Check if this code already exists
        const exists = await prisma.account.findUnique({
            where: { accountCode }
        });

        if (!exists) {
            return accountCode;
        }

        // If exists, wait a bit and try again
        await new Promise(resolve => setTimeout(resolve, 100));
    }

    // Fallback: use timestamp to ensure uniqueness
    const timestamp = Date.now().toString().slice(-6);
    return `${prefix}${year}${month}${timestamp}`;
}