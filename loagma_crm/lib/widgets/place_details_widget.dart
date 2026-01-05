import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/place_model.dart';

class PlaceDetailsWidget extends StatelessWidget {
  final PlaceInfo place;
  final VoidCallback? onClose;

  const PlaceDetailsWidget({super.key, required this.place, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onClose != null)
                  IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Info
                  _buildBasicInfo(),
                  const SizedBox(height: 16),

                  // Photos
                  if (place.hasPhotos) ...[
                    _buildPhotosSection(),
                    const SizedBox(height: 16),
                  ],

                  // Contact Info
                  _buildContactInfo(),
                  const SizedBox(height: 16),

                  // Reviews
                  if (place.hasReviews) ...[
                    _buildReviewsSection(),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating and Status
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: place.rating > 4.0 ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                place.formattedRating,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: place.isOpenNow ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                place.statusDescription,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Address
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                place.address,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Price Level
        if (place.priceLevel > 0) ...[
          Row(
            children: [
              const Icon(Icons.attach_money, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text(
                place.priceDescription,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Business Type (improved display)
        if (place.types.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.business, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text(
                'Type: ${_getDisplayType(place.types)}',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Additional Types (filtered)
        if (_getFilteredTypes(place.types).isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _getFilteredTypes(place.types).map((type) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  _formatTypeName(type),
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  /// Get the most appropriate display type for the business
  String _getDisplayType(List<String> types) {
    // Priority order for business types (most specific first)
    const typeHierarchy = [
      // Specific business types
      'restaurant', 'cafe', 'bakery', 'bar', 'night_club',
      'hospital', 'pharmacy', 'doctor', 'dentist', 'veterinary_care',
      'bank', 'atm', 'insurance_agency', 'real_estate_agency',
      'gas_station', 'car_dealer', 'car_repair', 'car_wash',
      'supermarket', 'convenience_store', 'grocery_or_supermarket',
      'clothing_store', 'shoe_store', 'jewelry_store', 'electronics_store',
      'book_store', 'furniture_store', 'home_goods_store', 'hardware_store',
      'beauty_salon', 'hair_care', 'spa', 'gym',
      'school', 'university', 'library', 'museum',
      'church', 'mosque', 'synagogue', 'hindu_temple',
      'hotel', 'lodging', 'campground',
      'tourist_attraction', 'amusement_park', 'zoo', 'aquarium',
      // General types
      'store', 'food', 'health', 'finance',
    ];

    // Find the most specific type
    for (String priorityType in typeHierarchy) {
      if (types.contains(priorityType)) {
        return _formatTypeName(priorityType);
      }
    }

    // If no specific type found, use the first non-generic type
    final filteredTypes = types
        .where(
          (type) => ![
            'establishment',
            'point_of_interest',
            'premise',
            'geocode',
          ].contains(type),
        )
        .toList();

    if (filteredTypes.isNotEmpty) {
      return _formatTypeName(filteredTypes.first);
    }

    return 'Business';
  }

  /// Get filtered types for display (excluding generic ones and the main type)
  List<String> _getFilteredTypes(List<String> types) {
    final mainType = _getMainType(types);
    return types
        .where(
          (type) =>
              ![
                'establishment',
                'point_of_interest',
                'premise',
                'geocode',
              ].contains(type) &&
              type != mainType,
        )
        .take(2)
        .toList(); // Show max 2 additional types
  }

  /// Get the main type (used internally)
  String _getMainType(List<String> types) {
    const typeHierarchy = [
      'restaurant',
      'cafe',
      'bakery',
      'bar',
      'night_club',
      'hospital',
      'pharmacy',
      'doctor',
      'dentist',
      'veterinary_care',
      'bank',
      'atm',
      'insurance_agency',
      'real_estate_agency',
      'gas_station',
      'car_dealer',
      'car_repair',
      'car_wash',
      'supermarket',
      'convenience_store',
      'grocery_or_supermarket',
      'clothing_store',
      'shoe_store',
      'jewelry_store',
      'electronics_store',
      'book_store',
      'furniture_store',
      'home_goods_store',
      'hardware_store',
      'beauty_salon',
      'hair_care',
      'spa',
      'gym',
      'school',
      'university',
      'library',
      'museum',
      'church',
      'mosque',
      'synagogue',
      'hindu_temple',
      'hotel',
      'lodging',
      'campground',
      'tourist_attraction',
      'amusement_park',
      'zoo',
      'aquarium',
      'store',
      'food',
      'health',
      'finance',
    ];

    for (String priorityType in typeHierarchy) {
      if (types.contains(priorityType)) {
        return priorityType;
      }
    }

    final filteredTypes = types
        .where(
          (type) => ![
            'establishment',
            'point_of_interest',
            'premise',
            'geocode',
          ].contains(type),
        )
        .toList();

    return filteredTypes.isNotEmpty ? filteredTypes.first : 'establishment';
  }

  /// Format type name for display
  String _formatTypeName(String type) {
    // Custom mappings for better display names
    const typeDisplayNames = {
      'accounting': 'Accounting',
      'airport': 'Airport',
      'amusement_park': 'Amusement Park',
      'aquarium': 'Aquarium',
      'art_gallery': 'Art Gallery',
      'atm': 'ATM',
      'bakery': 'Bakery',
      'bank': 'Bank',
      'bar': 'Bar',
      'beauty_salon': 'Beauty Salon',
      'bicycle_store': 'Bicycle Store',
      'book_store': 'Book Store',
      'bowling_alley': 'Bowling Alley',
      'bus_station': 'Bus Station',
      'cafe': 'Cafe',
      'campground': 'Campground',
      'car_dealer': 'Car Dealer',
      'car_rental': 'Car Rental',
      'car_repair': 'Car Repair',
      'car_wash': 'Car Wash',
      'casino': 'Casino',
      'cemetery': 'Cemetery',
      'church': 'Church',
      'city_hall': 'City Hall',
      'clothing_store': 'Clothing Store',
      'convenience_store': 'Convenience Store',
      'courthouse': 'Courthouse',
      'dentist': 'Dentist',
      'department_store': 'Department Store',
      'doctor': 'Doctor',
      'drugstore': 'Drugstore',
      'electrician': 'Electrician',
      'electronics_store': 'Electronics Store',
      'embassy': 'Embassy',
      'fire_station': 'Fire Station',
      'florist': 'Florist',
      'funeral_home': 'Funeral Home',
      'furniture_store': 'Furniture Store',
      'gas_station': 'Gas Station',
      'grocery_or_supermarket': 'Grocery Store',
      'gym': 'Gym',
      'hair_care': 'Hair Care',
      'hardware_store': 'Hardware Store',
      'hindu_temple': 'Hindu Temple',
      'home_goods_store': 'Home Goods Store',
      'hospital': 'Hospital',
      'insurance_agency': 'Insurance Agency',
      'jewelry_store': 'Jewelry Store',
      'laundry': 'Laundry',
      'lawyer': 'Lawyer',
      'library': 'Library',
      'light_rail_station': 'Light Rail Station',
      'liquor_store': 'Liquor Store',
      'local_government_office': 'Government Office',
      'locksmith': 'Locksmith',
      'lodging': 'Lodging',
      'meal_delivery': 'Meal Delivery',
      'meal_takeaway': 'Takeaway',
      'mosque': 'Mosque',
      'movie_rental': 'Movie Rental',
      'movie_theater': 'Movie Theater',
      'moving_company': 'Moving Company',
      'museum': 'Museum',
      'night_club': 'Night Club',
      'painter': 'Painter',
      'park': 'Park',
      'parking': 'Parking',
      'pet_store': 'Pet Store',
      'pharmacy': 'Pharmacy',
      'physiotherapist': 'Physiotherapist',
      'plumber': 'Plumber',
      'police': 'Police',
      'post_office': 'Post Office',
      'primary_school': 'Primary School',
      'real_estate_agency': 'Real Estate Agency',
      'restaurant': 'Restaurant',
      'roofing_contractor': 'Roofing Contractor',
      'rv_park': 'RV Park',
      'school': 'School',
      'secondary_school': 'Secondary School',
      'shoe_store': 'Shoe Store',
      'shopping_mall': 'Shopping Mall',
      'spa': 'Spa',
      'stadium': 'Stadium',
      'storage': 'Storage',
      'store': 'Store',
      'subway_station': 'Subway Station',
      'supermarket': 'Supermarket',
      'synagogue': 'Synagogue',
      'taxi_stand': 'Taxi Stand',
      'tourist_attraction': 'Tourist Attraction',
      'train_station': 'Train Station',
      'transit_station': 'Transit Station',
      'travel_agency': 'Travel Agency',
      'university': 'University',
      'veterinary_care': 'Veterinary Care',
      'zoo': 'Zoo',
      // Additional common types
      'food': 'Food & Dining',
      'health': 'Health & Medical',
      'finance': 'Financial Services',
      'establishment': 'Business',
    };

    return typeDisplayNames[type] ??
        type
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) =>
                  word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
            )
            .join(' ');
  }

  Widget _buildPhotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photos',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: place.photoUrls.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    place.photoUrls[index],
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        if (place.phoneNumber != null) ...[
          _buildContactRow(
            Icons.phone,
            'Phone',
            place.phoneNumber!,
            () => _launchPhone(place.phoneNumber!),
          ),
        ],

        if (place.website != null) ...[
          _buildContactRow(
            Icons.web,
            'Website',
            place.website!,
            () => _launchUrl(place.website!),
          ),
        ],
      ],
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Reviews',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${place.reviewCount} reviews',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ...place.reviews.take(3).map((review) => _buildReviewItem(review)),

        if (place.reviews.length > 3) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '+ ${place.reviews.length - 3} more reviews',
              style: TextStyle(
                color: Colors.blue[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewItem(PlaceReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: review.authorPhotoUrl != null
                    ? NetworkImage(review.authorPhotoUrl!)
                    : null,
                child: review.authorPhotoUrl == null
                    ? Text(
                        review.author.isNotEmpty
                            ? review.author[0].toUpperCase()
                            : 'A',
                        style: const TextStyle(fontSize: 12),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.author,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          review.formattedRating,
                          style: const TextStyle(fontSize: 10),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          review.relativeTime,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.hasText) ...[
            const SizedBox(height: 8),
            Text(
              review.getTruncatedText(150),
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _launchDirections(),
            icon: const Icon(Icons.directions),
            label: const Text('Directions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _sharePlace(),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ),
      ],
    );
  }

  void _launchPhone(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchDirections() async {
    if (place.latitude != null && place.longitude != null) {
      final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  void _sharePlace() {
    // Implement share functionality
    // You can use the share_plus package for this
  }
}

/// Compact place card for list display
class PlaceCard extends StatelessWidget {
  final PlaceInfo place;
  final VoidCallback? onTap;

  const PlaceCard({super.key, required this.place, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: place.mainPhotoUrl != null
                    ? Image.network(
                        place.mainPhotoUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.shortAddress,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          place.formattedRating,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: place.isOpenNow ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            place.isOpenNow ? 'Open' : 'Closed',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[300],
      child: const Icon(Icons.store, color: Colors.grey, size: 30),
    );
  }
}
