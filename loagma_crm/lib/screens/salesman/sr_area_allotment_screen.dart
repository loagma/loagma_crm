import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../services/google_places_service.dart';
import '../../services/location_service.dart';
import '../../models/place_model.dart';
import '../../models/area_assignment_model.dart';
import '../../widgets/place_details_widget.dart';

class SRAreaAllotmentScreen extends StatefulWidget {
  final AreaAssignment? areaAssignment;

  const SRAreaAllotmentScreen({super.key, this.areaAssignment});

  @override
  State<SRAreaAllotmentScreen> createState() => _SRAreaAllotmentScreenState();
}

class _SRAreaAllotmentScreenState extends State<SRAreaAllotmentScreen> {
  static const Color primaryColor = Color(0xFFD7BE69);

  // Map and location
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String _locationStatus = 'Getting location...';

  // Places
  List<PlaceInfo> _nearbyPlaces = [];
  List<PlaceInfo> _filteredPlaces = [];
  bool _isLoadingPlaces = false;
  PlaceInfo? _selectedPlace;
  bool _showPlaceDetailsOverlay = false;

  // Markers and UI
  Set<Marker> _markers = {};
  String _selectedPlaceType = 'store';
  int _searchRadius = 1500;
  bool _isFullScreenMap = false;
  bool _showFilters = false;

  // Filters
  List<String> _selectedPincodes = [];
  List<String> _availablePincodes = [];
  String _selectedArea = '';
  List<String> _availableAreas = [];
  double _minRating = 0.0;
  bool _openNowOnly = false;
  String _searchQuery = '';

  // Controllers
  final TextEditingController _searchController = TextEditingController();

  // Place types for business discovery
  final List<Map<String, dynamic>> _placeTypes = [
    {'type': 'store', 'name': 'Stores', 'icon': Icons.store},
    {'type': 'restaurant', 'name': 'Restaurants', 'icon': Icons.restaurant},
    {'type': 'shopping_mall', 'name': 'Malls', 'icon': Icons.shopping_bag},
    {
      'type': 'supermarket',
      'name': 'Supermarkets',
      'icon': Icons.local_grocery_store,
    },
    {'type': 'bank', 'name': 'Banks', 'icon': Icons.account_balance},
    {
      'type': 'gas_station',
      'name': 'Gas Stations',
      'icon': Icons.local_gas_station,
    },
    {'type': 'pharmacy', 'name': 'Pharmacies', 'icon': Icons.local_pharmacy},
    {'type': 'hospital', 'name': 'Hospitals', 'icon': Icons.local_hospital},
    {'type': 'school', 'name': 'Schools', 'icon': Icons.school},
    {'type': 'cafe', 'name': 'Cafes', 'icon': Icons.local_cafe},
  ];

  @override
  void initState() {
    super.initState();
    GooglePlacesService.instance.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  @override
  void dispose() {
    LocationService.instance.stopLocationTracking();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    List<PlaceInfo> filtered = List.from(_nearbyPlaces);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (place) =>
                place.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (place.address?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    // Pincode filter
    if (_selectedPincodes.isNotEmpty) {
      filtered = filtered.where((place) {
        if (place.address == null) return false;
        return _selectedPincodes.any(
          (pincode) => place.address!.contains(pincode),
        );
      }).toList();
    }

    // Area filter
    if (_selectedArea.isNotEmpty) {
      filtered = filtered
          .where(
            (place) =>
                place.address?.toLowerCase().contains(
                  _selectedArea.toLowerCase(),
                ) ??
                false,
          )
          .toList();
    }

    // Rating filter
    if (_minRating > 0) {
      filtered = filtered
          .where((place) => (place.rating ?? 0) >= _minRating)
          .toList();
    }

    // Open now filter
    if (_openNowOnly) {
      filtered = filtered.where((place) => place.isOpenNow ?? false).toList();
    }

    setState(() {
      _filteredPlaces = filtered;
    });
    _updateMapMarkers();
  }

  void _extractPincodesAndAreas() {
    Set<String> pincodes = {};
    Set<String> areas = {};

    for (var place in _nearbyPlaces) {
      if (place.address != null) {
        // Extract pincode (assuming 6-digit pattern)
        RegExp pincodeRegex = RegExp(r'\b\d{6}\b');
        var matches = pincodeRegex.allMatches(place.address!);
        for (var match in matches) {
          pincodes.add(match.group(0)!);
        }

        // Extract area names (words before pincode or comma-separated)
        List<String> addressParts = place.address!.split(',');
        for (String part in addressParts) {
          String trimmed = part.trim();
          if (trimmed.isNotEmpty && !RegExp(r'^\d+$').hasMatch(trimmed)) {
            areas.add(trimmed);
          }
        }
      }
    }

    setState(() {
      _availablePincodes = pincodes.toList()..sort();
      _availableAreas = areas.toList()..sort();
    });
  }

  void _updateMapMarkers() {
    setState(() {
      _markers = _buildMapMarkers();
    });
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatus = 'Initializing location services...';
    });

    try {
      final locationService = LocationService.instance;
      final hasPermission = await locationService.checkLocationPermission();

      if (!hasPermission) {
        final shouldRequestPermission =
            await LocationService.showLocationPermissionDialog(context);
        if (!shouldRequestPermission) {
          setState(() {
            _locationStatus = 'Location permission required';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      final success = await locationService.startLocationTracking();
      if (success) {
        locationService.locationStream.listen((Position position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
              _locationStatus = 'Location active';
              _isLoadingLocation = false;
              _markers = _buildMapMarkers();
            });

            if (_mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLng(
                  LatLng(position.latitude, position.longitude),
                ),
              );
            }

            _loadNearbyPlaces();
          }
        });

        final initialPosition = await locationService.getCurrentLocation();
        if (initialPosition != null && mounted) {
          setState(() {
            _currentPosition = initialPosition;
            _locationStatus = 'Location active';
            _isLoadingLocation = false;
            _markers = _buildMapMarkers();
          });
          _loadNearbyPlaces();
        }
      }
    } catch (e) {
      setState(() {
        _locationStatus = 'Location error';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _loadNearbyPlaces() async {
    if (_currentPosition == null || _isLoadingPlaces) return;

    setState(() => _isLoadingPlaces = true);

    try {
      final nearbyResults = await GooglePlacesService.instance
          .fetchNearbyPlaces(
            lat: _currentPosition!.latitude,
            lng: _currentPosition!.longitude,
            radius: _searchRadius,
            type: _selectedPlaceType,
          );

      final places = nearbyResults
          .map((result) => PlaceInfo.fromNearbyResult(result))
          .toList();

      if (mounted) {
        setState(() {
          _nearbyPlaces = places;
          _filteredPlaces = places;
          _isLoadingPlaces = false;
        });
        _extractPincodesAndAreas();
        _applyFilters();
      }
    } catch (e) {
      print('Error loading places: $e');
      if (mounted) {
        setState(() => _isLoadingPlaces = false);
      }
    }
  }

  Future<void> _showPlaceDetails(PlaceInfo place) async {
    try {
      final details = await GooglePlacesService.instance.fetchPlaceDetails(
        place.placeId,
      );

      if (details != null) {
        final detailedPlace = PlaceInfo.fromPlaceDetails(details);
        setState(() {
          _selectedPlace = detailedPlace;
          _showPlaceDetailsOverlay = true;
        });
      }
    } catch (e) {
      _showError('Failed to load place details');
    }
  }

  Set<Marker> _buildMapMarkers() {
    Set<Marker> markers = {};

    // Current location
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Area assignment boundaries (if available)
    if (widget.areaAssignment != null) {
      // Add area boundary markers here if needed
    }

    // Nearby places (filtered)
    for (int i = 0; i < _filteredPlaces.length; i++) {
      final place = _filteredPlaces[i];
      if (place.latitude != null && place.longitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId('place_$i'),
            position: LatLng(place.latitude!, place.longitude!),
            infoWindow: InfoWindow(
              title: place.name,
              snippet: '${place.formattedRating} • ${place.statusDescription}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            onTap: () => _showPlaceDetails(place),
          ),
        );
      }
    }

    return markers;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _isFullScreenMap
          ? null
          : AppBar(
              title: const Text('SR Area Allotment'),
              backgroundColor: primaryColor,
              actions: [
                IconButton(
                  icon: Icon(
                    _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  ),
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  tooltip: 'Toggle Filters',
                ),
                IconButton(
                  icon: Icon(
                    _isFullScreenMap ? Icons.fullscreen_exit : Icons.fullscreen,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFullScreenMap = !_isFullScreenMap;
                    });
                  },
                  tooltip: _isFullScreenMap
                      ? 'Exit Full Screen'
                      : 'Full Screen Map',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadNearbyPlaces,
                  tooltip: 'Refresh Places',
                ),
              ],
            ),
      body: _isFullScreenMap ? _buildFullScreenMap() : _buildNormalView(),
    );
  }

  Widget _buildNormalView() {
    return Stack(
      children: [
        Column(
          children: [
            // Area Info Card
            if (widget.areaAssignment != null) _buildAreaInfoCard(),

            // Search Bar
            _buildSearchBar(),

            // Collapsible Filters
            if (_showFilters) _buildFiltersSection(),

            // Place Type Filter
            _buildPlaceTypeFilter(),

            // Map Section
            Expanded(child: _buildMapSection()),

            // Places List
            _buildPlacesListSection(),
          ],
        ),

        // Place Details Overlay
        if (_showPlaceDetailsOverlay && _selectedPlace != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: PlaceDetailsWidget(
                place: _selectedPlace!,
                onClose: () {
                  setState(() {
                    _showPlaceDetailsOverlay = false;
                    _selectedPlace = null;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFullScreenMap() {
    return Stack(
      children: [
        // Full screen map
        _currentPosition != null
            ? GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  zoom: 15,
                ),
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
              )
            : Container(
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoadingLocation)
                        const CircularProgressIndicator()
                      else
                        Icon(
                          Icons.location_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                      const SizedBox(height: 12),
                      Text(
                        _locationStatus,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),

        // Floating controls
        Positioned(
          top: 50,
          left: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: primaryColor,
            onPressed: () {
              setState(() {
                _isFullScreenMap = false;
              });
            },
            child: const Icon(Icons.fullscreen_exit, color: Colors.white),
          ),
        ),

        // Floating filter button
        Positioned(
          top: 50,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: primaryColor,
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            child: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.white,
            ),
          ),
        ),

        // Collapsible filters in full screen
        if (_showFilters)
          Positioned(
            top: 110,
            left: 16,
            right: 16,
            child: Card(child: _buildFiltersContent()),
          ),

        // Place count indicator
        Positioned(
          bottom: 100,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_filteredPlaces.length} places found',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAreaInfoCard() {
    final area = widget.areaAssignment!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.location_city, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned Area',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${area.city}, ${area.district}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(Icons.pin_drop, area.pinCode),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.business,
                '${area.totalBusinesses} businesses',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildPlaceTypeFilter() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _placeTypes.length,
        itemBuilder: (context, index) {
          final placeType = _placeTypes[index];
          final isSelected = _selectedPlaceType == placeType['type'];

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    placeType['icon'],
                    size: 16,
                    color: isSelected ? Colors.white : primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(placeType['name']),
                ],
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPlaceType = placeType['type'];
                  });
                  _loadNearbyPlaces();
                }
              },
              selectedColor: primaryColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search places...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _applyFilters();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _buildFiltersContent(),
    );
  }

  Widget _buildFiltersContent() {
    return ExpansionTile(
      title: const Text('Filters'),
      leading: const Icon(Icons.tune),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pincode Filter
              if (_availablePincodes.isNotEmpty) ...[
                const Text(
                  'Pincodes:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _availablePincodes.map((pincode) {
                    final isSelected = _selectedPincodes.contains(pincode);
                    return FilterChip(
                      label: Text(pincode),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedPincodes.add(pincode);
                          } else {
                            _selectedPincodes.remove(pincode);
                          }
                        });
                        _applyFilters();
                      },
                      selectedColor: primaryColor,
                      checkmarkColor: Colors.white,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Area Filter
              if (_availableAreas.isNotEmpty) ...[
                const Text(
                  'Areas:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedArea.isEmpty ? null : _selectedArea,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  hint: const Text('Select Area'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('All Areas'),
                    ),
                    ..._availableAreas.map(
                      (area) => DropdownMenuItem<String>(
                        value: area,
                        child: Text(area),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedArea = value ?? '';
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Rating Filter
              const Text(
                'Minimum Rating:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: _minRating,
                min: 0.0,
                max: 5.0,
                divisions: 10,
                label: _minRating == 0.0
                    ? 'Any'
                    : _minRating.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _minRating = value;
                  });
                  _applyFilters();
                },
                activeColor: primaryColor,
              ),

              // Open Now Filter
              SwitchListTile(
                title: const Text('Open Now Only'),
                value: _openNowOnly,
                onChanged: (value) {
                  setState(() {
                    _openNowOnly = value;
                  });
                  _applyFilters();
                },
                activeColor: primaryColor,
              ),

              // Clear Filters Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedPincodes.clear();
                      _selectedArea = '';
                      _minRating = 0.0;
                      _openNowOnly = false;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                    _applyFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                  ),
                  child: const Text('Clear All Filters'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _currentPosition != null
            ? GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  zoom: 15,
                ),
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                mapToolbarEnabled: false,
              )
            : Container(
                height: 300,
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoadingLocation)
                        const CircularProgressIndicator()
                      else
                        Icon(
                          Icons.location_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                      const SizedBox(height: 12),
                      Text(
                        _locationStatus,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPlacesListSection() {
    if (_filteredPlaces.isEmpty && !_isLoadingPlaces) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 140,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.store, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Nearby ${_placeTypes.firstWhere((p) => p['type'] == _selectedPlaceType)['name']} (${_filteredPlaces.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoadingPlaces)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          if (_isLoadingPlaces && _filteredPlaces.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_filteredPlaces.isNotEmpty)
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredPlaces.length,
                itemBuilder: (context, index) {
                  final place = _filteredPlaces[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12, bottom: 16),
                    child: PlaceCard(
                      place: place,
                      onTap: () => _showPlaceDetails(place),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
