import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:io';
import '../../services/user_service.dart';
import '../../services/attendance_service.dart';
import '../../services/location_service.dart';
import '../../services/google_places_service.dart';
import '../../models/attendance_model.dart';
import '../../models/place_model.dart';
import '../../widgets/place_details_widget.dart';
import 'salesman_attendance_history_screen.dart';

class EnhancedPunchScreen extends StatefulWidget {
  const EnhancedPunchScreen({super.key});

  @override
  State<EnhancedPunchScreen> createState() => _EnhancedPunchScreenState();
}

class _EnhancedPunchScreenState extends State<EnhancedPunchScreen> {
  static const Color primaryColor = Color(0xFFD7BE69);

  // Punch status
  bool isPunchedIn = false;
  DateTime? punchInTime;
  DateTime? punchOutTime;
  Position? punchInLocation;
  Position? punchOutLocation;

  // Punch In data
  File? punchInPhoto;
  String? punchInPhotoBase64;
  String? bikeKilometers;

  // Current attendance record
  AttendanceModel? currentAttendance;
  bool isLoadingAttendance = false;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  // Current time
  String currentTime = '';
  String currentDate = '';
  Timer? _timer;

  // Location
  Position? _currentPosition;
  bool isLoadingLocation = false;
  String locationStatus = 'Getting location...';

  // Work duration
  Duration workDuration = Duration.zero;

  // Travel distance
  double totalDistanceKm = 0.0;

  // Google Map controller
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  // Google Places
  List<PlaceInfo> _nearbyPlaces = [];
  bool _isLoadingPlaces = false;
  PlaceInfo? _selectedPlace;
  bool _showPlaceDetailsOverlay = false;

  @override
  void initState() {
    super.initState();
    _updateCurrentTime();
    _startTimer();
    _loadTodayPunchData();

    // Initialize Google Places Service
    GooglePlacesService.instance.initialize();

    // Initialize location after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocationService();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    LocationService.instance.stopLocationTracking();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCurrentTime();

      // Update work duration if punched in
      if (isPunchedIn && punchInTime != null) {
        setState(() {
          final now = DateTime.now();
          final newDuration = now.difference(punchInTime!);

          if (!newDuration.isNegative && newDuration != workDuration) {
            workDuration = newDuration;
          }
        });
      }

      // Auto-refresh location every 30 seconds if not available
      if (_currentPosition == null && !isLoadingLocation) {
        if (timer.tick % 30 == 0) {
          _getCurrentLocation();
        }
      }
    });
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    setState(() {
      currentTime = DateFormat('hh:mm:ss a').format(now);
      currentDate = DateFormat('EEEE, MMMM dd, yyyy').format(now);
    });
  }

  Future<void> _initializeLocationService() async {
    if (!mounted) return;

    setState(() {
      isLoadingLocation = true;
      locationStatus = 'Initializing location services...';
    });

    try {
      final locationService = LocationService.instance;
      final hasPermission = await locationService.checkLocationPermission();

      if (!hasPermission) {
        if (mounted) {
          final shouldRequestPermission =
              await LocationService.showLocationPermissionDialog(context);

          if (!shouldRequestPermission) {
            if (mounted) {
              setState(() {
                locationStatus = 'Location permission required for attendance';
                isLoadingLocation = false;
              });
            }
            return;
          }
        }
      }

      final success = await locationService.startLocationTracking();

      if (success && mounted) {
        locationService.locationStream.listen(
          (Position position) {
            if (mounted) {
              setState(() {
                _currentPosition = position;
                locationStatus =
                    'Location active (±${position.accuracy.toStringAsFixed(0)}m)';
                isLoadingLocation = false;
                _markers = _buildMapMarkers();
              });

              // Update map camera and load nearby places
              if (_mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(position.latitude, position.longitude),
                  ),
                );
              }

              // Load nearby places when location is available
              _loadNearbyPlaces();
            }
          },
          onError: (error) {
            print('Location stream error: $error');
            if (mounted) {
              setState(() {
                locationStatus = 'Location error: ${error.toString()}';
                isLoadingLocation = false;
              });
            }
          },
        );

        final initialPosition = await locationService.getCurrentLocation();
        if (initialPosition != null && mounted) {
          setState(() {
            _currentPosition = initialPosition;
            locationStatus =
                'Location active (±${initialPosition.accuracy.toStringAsFixed(0)}m)';
            isLoadingLocation = false;
            _markers = _buildMapMarkers();
          });

          // Load nearby places
          _loadNearbyPlaces();
        }
      } else {
        if (mounted) {
          setState(() {
            locationStatus =
                'Failed to start location tracking. Tap refresh to retry.';
            isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      print('Location initialization error: $e');
      if (mounted) {
        setState(() {
          locationStatus = 'Location error. Tap refresh to retry.';
          isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      isLoadingLocation = true;
      locationStatus = 'Refreshing location...';
    });

    try {
      final locationService = LocationService.instance;
      final position = await locationService.getCurrentLocation(
        forceRefresh: true,
      );

      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          locationStatus =
              'Location active (±${position.accuracy.toStringAsFixed(0)}m)';
          isLoadingLocation = false;
          _markers = _buildMapMarkers();
        });

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude),
              16,
            ),
          );
        }

        // Reload nearby places with new location
        _loadNearbyPlaces();
        _showSuccess('Location updated successfully');
      } else {
        if (mounted) {
          setState(() {
            locationStatus = 'Failed to get location. Check GPS settings.';
            isLoadingLocation = false;
          });
        }
        _showError('Failed to get location. Please check your GPS settings.');
      }
    } catch (e) {
      print('Get location error: $e');
      if (mounted) {
        setState(() {
          locationStatus = 'Location error. Check permissions.';
          isLoadingLocation = false;
        });
      }
      _showError('Location error. Please check app permissions.');
    }
  }

  /// Load nearby places using Google Places API
  Future<void> _loadNearbyPlaces() async {
    if (_currentPosition == null || _isLoadingPlaces) return;

    setState(() {
      _isLoadingPlaces = true;
    });

    try {
      final nearbyResults = await GooglePlacesService.instance
          .fetchNearbyPlaces(
            lat: _currentPosition!.latitude,
            lng: _currentPosition!.longitude,
            radius: 1500,
            type: "store",
          );

      // Convert to PlaceInfo objects
      final places = nearbyResults
          .map((result) => PlaceInfo.fromNearbyResult(result))
          .toList();

      if (mounted) {
        setState(() {
          _nearbyPlaces = places;
          _isLoadingPlaces = false;
          _markers = _buildMapMarkers(); // Update markers with places
        });
      }

      print('✅ Loaded ${places.length} nearby places');
    } catch (e) {
      print('❌ Error loading nearby places: $e');
      if (mounted) {
        setState(() {
          _isLoadingPlaces = false;
        });
      }
    }
  }

  /// Show place details
  Future<void> _showPlaceDetails(PlaceInfo place) async {
    try {
      // Fetch detailed information
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
      print('Error fetching place details: $e');
      _showError('Failed to load place details');
    }
  }

  Future<void> _loadTodayPunchData() async {
    setState(() => isLoadingAttendance = true);

    try {
      final employeeId = UserService.currentUserId;
      if (employeeId == null) {
        _showError('Employee ID not found. Please login again.');
        return;
      }

      final attendance = await AttendanceService.getTodayAttendance(employeeId);

      if (attendance != null) {
        setState(() {
          currentAttendance = attendance;
          isPunchedIn = attendance.isPunchedIn;
          punchInTime = attendance.punchInTime;

          if (attendance.isPunchedIn) {
            final now = DateTime.now();
            final duration = now.difference(attendance.punchInTime);
            workDuration = duration.isNegative ? Duration.zero : duration;
          } else if (attendance.isPunchedOut &&
              attendance.punchOutTime != null) {
            final duration = attendance.punchOutTime!.difference(
              attendance.punchInTime,
            );
            workDuration = duration.isNegative ? Duration.zero : duration;
          } else {
            workDuration = Duration.zero;
          }

          punchInLocation = Position(
            latitude: attendance.punchInLatitude,
            longitude: attendance.punchInLongitude,
            timestamp: attendance.punchInTime,
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );

          if (attendance.isPunchedOut) {
            punchOutTime = attendance.punchOutTime;
            if (attendance.punchOutLatitude != null &&
                attendance.punchOutLongitude != null) {
              punchOutLocation = Position(
                latitude: attendance.punchOutLatitude!,
                longitude: attendance.punchOutLongitude!,
                timestamp: attendance.punchOutTime ?? DateTime.now(),
                accuracy: 0,
                altitude: 0,
                heading: 0,
                speed: 0,
                speedAccuracy: 0,
                altitudeAccuracy: 0,
                headingAccuracy: 0,
              );
            }
            totalDistanceKm = attendance.totalDistanceKm ?? 0.0;
          } else {
            punchOutTime = null;
            punchOutLocation = null;
            totalDistanceKm = 0.0;
          }

          _markers = _buildMapMarkers();
        });

        if (attendance.isPunchedIn) {
          final sessionDuration = workDuration.inMinutes;
          if (sessionDuration > 0) {
            print('Active session loaded: ${sessionDuration} minutes worked');
          }
        }
      } else {
        setState(() {
          currentAttendance = null;
          isPunchedIn = false;
          punchInTime = null;
          punchOutTime = null;
          punchInLocation = null;
          punchOutLocation = null;
          workDuration = Duration.zero;
          totalDistanceKm = 0.0;
          _markers = _buildMapMarkers();
        });
      }
    } catch (e) {
      print('Error loading attendance: $e');
      _showError('Failed to load attendance data. Please refresh.');
    } finally {
      setState(() => isLoadingAttendance = false);
    }
  }

  Set<Marker> _buildMapMarkers() {
    Set<Marker> markers = {};

    // Current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Current Location',
            snippet:
                'Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)}m',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Punch in location marker
    if (punchInLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('punch_in_location'),
          position: LatLng(
            punchInLocation!.latitude,
            punchInLocation!.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Punch In Location',
            snippet: punchInTime != null
                ? DateFormat('hh:mm a').format(punchInTime!)
                : 'Punch In',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    // Punch out location marker
    if (punchOutLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('punch_out_location'),
          position: LatLng(
            punchOutLocation!.latitude,
            punchOutLocation!.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Punch Out Location',
            snippet: punchOutTime != null
                ? DateFormat('hh:mm a').format(punchOutTime!)
                : 'Punch Out',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Nearby places markers
    for (int i = 0; i < _nearbyPlaces.length; i++) {
      final place = _nearbyPlaces[i];
      if (place.latitude != null && place.longitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId('place_$i'),
            position: LatLng(place.latitude!, place.longitude!),
            infoWindow: InfoWindow(
              title: place.name,
              snippet:
                  '${place.formattedRating} • ${place.isOpenNow ? "Open" : "Closed"}',
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
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
      appBar: AppBar(
        title: const Text('Enhanced Attendance'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Attendance History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SalesmanAttendanceHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Places',
            onPressed: _loadNearbyPlaces,
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await _getCurrentLocation();
              await _loadTodayPunchData();
              await _loadNearbyPlaces();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Current Time Card
                  _buildCurrentTimeCard(),

                  // Status Card
                  _buildStatusCard(),

                  // Enhanced Map with Places
                  _buildEnhancedMapSection(),

                  // Nearby Places List
                  _buildNearbyPlacesSection(),

                  // Punch Button
                  _buildPunchButton(),

                  // Today's Summary
                  _buildTodaySummary(),
                ],
              ),
            ),
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
      ),
    );
  }

  Widget _buildCurrentTimeCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            currentTime,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currentDate,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              UserService.name ?? 'Employee',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isPunchedIn ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isPunchedIn ? 'Currently Working' : 'Not Punched In',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPunchedIn ? Colors.green : Colors.grey[700],
                ),
              ),
            ],
          ),
          if (isPunchedIn && punchInTime != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeInfo(
                  'Punch In',
                  DateFormat('hh:mm a').format(punchInTime!),
                  Icons.login,
                  Colors.green,
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildTimeInfo(
                  'Duration',
                  _formatDuration(workDuration),
                  Icons.timer,
                  primaryColor,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeInfo(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildEnhancedMapSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.map, color: primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Location & Nearby Places',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPosition != null
                            ? Colors.green
                            : isLoadingLocation
                            ? Colors.orange
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentPosition != null
                          ? 'Active'
                          : isLoadingLocation
                          ? 'Loading...'
                          : 'Inactive',
                      style: TextStyle(
                        fontSize: 12,
                        color: _currentPosition != null
                            ? Colors.green
                            : isLoadingLocation
                            ? Colors.orange
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                if (isLoadingLocation || _isLoadingPlaces)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      _getCurrentLocation();
                      _loadNearbyPlaces();
                    },
                    tooltip: 'Refresh location & places',
                  ),
              ],
            ),
          ),

          // Map Section
          if (_currentPosition != null)
            Container(
              height: 250,
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    zoom: 16,
                  ),
                  markers: _markers,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  rotateGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                ),
              ),
            )
          else
            Container(
              height: 250,
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoadingLocation)
                      const CircularProgressIndicator()
                    else
                      Icon(
                        Icons.location_off,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    const SizedBox(height: 12),
                    Text(
                      isLoadingLocation
                          ? 'Getting location...'
                          : 'Location not available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        locationStatus,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (!isLoadingLocation) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNearbyPlacesSection() {
    if (_nearbyPlaces.isEmpty && !_isLoadingPlaces) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.store, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Nearby Places (${_nearbyPlaces.length})',
                  style: const TextStyle(
                    fontSize: 18,
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

          if (_isLoadingPlaces && _nearbyPlaces.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_nearbyPlaces.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _nearbyPlaces.length,
                itemBuilder: (context, index) {
                  final place = _nearbyPlaces[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12, bottom: 20),
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

  Widget _buildPunchButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (isLoadingLocation)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else
            InkWell(
              onTap: () {
                // Implement punch in/out logic here
                // This would be similar to your existing implementation
              },
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isPunchedIn
                        ? [Colors.red, Colors.red[700]!]
                        : [Colors.green, Colors.green[700]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isPunchedIn ? Colors.red : Colors.green)
                          .withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPunchedIn ? Icons.logout : Icons.login,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isPunchedIn ? 'PUNCH OUT' : 'PUNCH IN',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            isPunchedIn
                ? 'Tap to end your work day'
                : 'Tap to start your work day',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            Icons.login,
            'Punch In Time',
            punchInTime != null
                ? DateFormat('hh:mm a').format(punchInTime!)
                : '--:--',
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            Icons.logout,
            'Punch Out Time',
            punchOutTime != null
                ? DateFormat('hh:mm a').format(punchOutTime!)
                : '--:--',
            Colors.red,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            Icons.timer,
            'Total Duration',
            _formatDuration(workDuration),
            primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
}
