import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kDebugMode, Factory;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_config.dart';
import '../../services/mapbox_service.dart';
import '../../config/mapbox_config.dart';
import '../../config/google_places_config.dart';
import '../../utils/custom_toast.dart';

class EditUserScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _alternativePhoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _countryController;
  late TextEditingController _districtController;
  late TextEditingController _aadharController;
  late TextEditingController _panController;
  late TextEditingController _passwordController;
  late TextEditingController _notesController;
  late TextEditingController _salaryController;
  late TextEditingController _locationSearchController;

  // Dropdown values
  String? selectedRoleId;
  String? selectedDepartmentId;
  String? selectedGender;
  DateTime? _selectedDateOfBirth;
  bool isActive = true;
  bool autoGeneratePassword = false;

  // Multiple selections
  List<String> selectedRoles = [];
  List<String> selectedLanguages = [];
  String? selectedArea;

  // Working Hours Configuration
  TimeOfDay? _workStartTime;
  TimeOfDay? _workEndTime;
  int _latePunchInGraceMinutes = 45;
  int _earlyPunchOutGraceMinutes = 30;
  bool isLoadingWorkingHours = false;

  // Geolocation
  double? _latitude;
  double? _longitude;
  bool isLoadingGeolocation = false;
  MapboxMap? _mapboxMap;
  final MapboxService _mapboxService = MapboxService();
  PointAnnotationManager? _pointAnnotationManager;
  Map<String, PointAnnotation> _markerAnnotations = {};

  // Data lists
  List<Map<String, dynamic>> roles = [];
  List<Map<String, dynamic>> departments = [];
  List<Map<String, dynamic>> _availableAreas = [];
  bool isLoadingAreas = false;
  bool fetchingPincode = false;

  // Image Upload
  File? _profileImage;
  String? _existingImageUrl;
  String? _uploadedImageUrl;
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;
  bool isLoadingData = true;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    _nameController = TextEditingController(text: widget.user['name'] ?? '');
    _emailController = TextEditingController(text: widget.user['email'] ?? '');
    _phoneController = TextEditingController(
      text: widget.user['contactNumber'] ?? '',
    );
    _alternativePhoneController = TextEditingController(
      text: widget.user['alternativeNumber'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.user['address'] ?? '',
    );
    _cityController = TextEditingController(text: widget.user['city'] ?? '');
    _stateController = TextEditingController(text: widget.user['state'] ?? '');
    _pincodeController = TextEditingController(
      text: widget.user['pincode'] ?? '',
    );
    _countryController = TextEditingController(
      text: widget.user['country'] ?? '',
    );
    _districtController = TextEditingController(
      text: widget.user['district'] ?? '',
    );
    _aadharController = TextEditingController(
      text: widget.user['aadharCard'] ?? '',
    );
    _panController = TextEditingController(text: widget.user['panCard'] ?? '');
    _passwordController = TextEditingController();
    _notesController = TextEditingController(text: widget.user['notes'] ?? '');
    _salaryController = TextEditingController(
      text: widget.user['salary'] != null
          ? widget.user['salary']['basicSalary'].toString()
          : '',
    );
    _locationSearchController = TextEditingController();

    // Initialize dropdown values
    selectedRoleId = widget.user['roleId'];
    selectedDepartmentId = widget.user['departmentId'];
    selectedGender = widget.user['gender'];
    isActive = widget.user['isActive'] ?? true;

    // Initialize date of birth
    if (widget.user['dateOfBirth'] != null) {
      try {
        _selectedDateOfBirth = DateTime.parse(widget.user['dateOfBirth']);
      } catch (e) {
        if (kDebugMode) print('Error parsing date of birth: $e');
      }
    }

    // Initialize multiple roles
    if (widget.user['roles'] != null && widget.user['roles'] is List) {
      selectedRoles = List<String>.from(widget.user['roles']);
    }

    // Initialize multiple languages
    if (widget.user['preferredLanguages'] != null &&
        widget.user['preferredLanguages'] is List) {
      selectedLanguages = List<String>.from(widget.user['preferredLanguages']);
    }

    // Initialize area and geolocation
    selectedArea = widget.user['area'];
    if (widget.user['latitude'] != null) {
      _latitude = widget.user['latitude'] is double
          ? widget.user['latitude']
          : double.tryParse(widget.user['latitude'].toString());
    }
    if (widget.user['longitude'] != null) {
      _longitude = widget.user['longitude'] is double
          ? widget.user['longitude']
          : double.tryParse(widget.user['longitude'].toString());
    }

    // Initialize existing image
    _existingImageUrl = widget.user['image'];

    fetchRoles();
    fetchDepartments();

    // Auto-fetch areas if pincode already exists
    if (_pincodeController.text.trim().length == 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchLocationFromPincode();
      });
    }

    // Load working hours for this employee
    _loadWorkingHours();
  }

  @override
  @override
  void dispose() {
    _mapboxService.dispose();
    _mapboxMap = null;
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _alternativePhoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _districtController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    _salaryController.dispose();
    _locationSearchController.dispose();
    _mapboxService.dispose();
    _mapboxMap = null;
    super.dispose();
  }
  
  // Build Mapbox map widget
  Widget _buildMapboxMap() {
    final initialPoint = _latitude != null && _longitude != null
        ? Position(_longitude!, _latitude!)
        : Position(78.9629, 20.5937); // India center
    
    return MapWidget(
      key: const ValueKey("edit_user_location_map"),
      cameraOptions: CameraOptions(
        center: Point(coordinates: initialPoint),
        zoom: _latitude != null ? 15.0 : 5.0,
      ),
      styleUri: MapboxConfig.defaultMapStyle,
      onMapCreated: _onMapCreated,
    );
  }
  
  Future<void> _onMapCreated(MapboxMap map) async {
    try {
      _mapboxMap = map;
      _mapboxService.initialize(map);
      
      // Create annotation manager
      _pointAnnotationManager = await map.annotations.createPointAnnotationManager();
      
      // Add marker if location is already set
      if (_latitude != null && _longitude != null) {
        await _updateLocationMarker(_latitude!, _longitude!);
      }
      
      print('✅ Mapbox map created for edit user location');
    } catch (e) {
      print('❌ Error creating Mapbox map: $e');
    }
  }

  Future<void> fetchRoles() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/roles');
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          roles = List<Map<String, dynamic>>.from(data['roles']);
        });
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading roles: $e');
    }
  }

  Future<void> _loadWorkingHours() async {
    setState(() => isLoadingWorkingHours = true);
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/employee-working-hours/${widget.user['id']}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final workingHours = data['data'];

        // Parse work start time (HH:MM:SS format)
        if (workingHours['workStartTime'] != null) {
          final parts = workingHours['workStartTime'].split(':');
          _workStartTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }

        // Parse work end time (HH:MM:SS format)
        if (workingHours['workEndTime'] != null) {
          final parts = workingHours['workEndTime'].split(':');
          _workEndTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }

        _latePunchInGraceMinutes =
            workingHours['latePunchInGraceMinutes'] ?? 45;
        _earlyPunchOutGraceMinutes =
            workingHours['earlyPunchOutGraceMinutes'] ?? 30;

        if (kDebugMode) {
          print('✅ Working hours loaded: $_workStartTime - $_workEndTime');
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading working hours: $e');
      // Use defaults if API fails
      _workStartTime = const TimeOfDay(hour: 9, minute: 0);
      _workEndTime = const TimeOfDay(hour: 18, minute: 0);
    } finally {
      if (mounted) {
        setState(() => isLoadingWorkingHours = false);
      }
    }
  }

  Future<void> _saveWorkingHours() async {
    try {
      final workStartTimeStr = _workStartTime != null
          ? '${_workStartTime!.hour.toString().padLeft(2, '0')}:${_workStartTime!.minute.toString().padLeft(2, '0')}:00'
          : '09:00:00';
      final workEndTimeStr = _workEndTime != null
          ? '${_workEndTime!.hour.toString().padLeft(2, '0')}:${_workEndTime!.minute.toString().padLeft(2, '0')}:00'
          : '18:00:00';

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/employee-working-hours/${widget.user['id']}',
      );
      final response = await http
          .put(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              'workStartTime': workStartTimeStr,
              'workEndTime': workEndTimeStr,
              'latePunchInGraceMinutes': _latePunchInGraceMinutes,
              'earlyPunchOutGraceMinutes': _earlyPunchOutGraceMinutes,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        if (kDebugMode) print('✅ Working hours saved successfully');
      } else {
        if (kDebugMode)
          print('❌ Failed to save working hours: ${data['message']}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error saving working hours: $e');
    }
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return 'Not set';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> fetchDepartments() async {
    try {
      if (kDebugMode)
        print('🔄 Fetching departments from: ${ApiConfig.baseUrl}/departments');

      final url = Uri.parse('${ApiConfig.baseUrl}/departments');
      final response = await http.get(url).timeout(const Duration(seconds: 30));

      if (kDebugMode) {
        print('📡 Departments API Response Status: ${response.statusCode}');
        print('📦 Departments API Response Body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final departmentsList = data['departments'] ?? data['data'] ?? [];

        if (kDebugMode) {
          print(
            '✅ Departments loaded successfully: ${departmentsList.length} departments',
          );
          for (var dept in departmentsList) {
            print('   - ${dept['name']} (ID: ${dept['id']})');
          }
        }

        setState(() {
          departments = List<Map<String, dynamic>>.from(departmentsList);
          isLoadingData = false;
        });

        // Show success message if departments loaded
        if (departmentsList.isNotEmpty) {
          Fluttertoast.showToast(
            msg: "✅ ${departmentsList.length} departments loaded",
            toastLength: Toast.LENGTH_SHORT,
          );
        }
      } else {
        if (kDebugMode)
          print(
            '❌ Departments API failed: ${data['message'] ?? 'Unknown error'}',
          );

        // Try alternative endpoint
        await _tryAlternativeDepartmentEndpoint();

        setState(() => isLoadingData = false);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading departments: $e');

      // Try alternative endpoint
      await _tryAlternativeDepartmentEndpoint();

      setState(() => isLoadingData = false);

      Fluttertoast.showToast(
        msg: "⚠️ Error loading departments: $e",
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  Future<void> _tryAlternativeDepartmentEndpoint() async {
    try {
      if (kDebugMode) print('🔄 Trying alternative department endpoint...');

      // Try different possible endpoints
      final alternativeEndpoints = [
        '${ApiConfig.baseUrl}/admin/departments',
        '${ApiConfig.baseUrl}/masters/departments',
        '${ApiConfig.baseUrl}/department',
      ];

      for (String endpoint in alternativeEndpoints) {
        try {
          if (kDebugMode) print('🔄 Trying: $endpoint');

          final response = await http
              .get(Uri.parse(endpoint), headers: {"Accept": "application/json"})
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            if (kDebugMode) print('📦 Alternative response: ${response.body}');

            // Try different response formats
            List<dynamic> departmentsList = [];

            if (data is List) {
              departmentsList = data;
            } else if (data['departments'] != null) {
              departmentsList = data['departments'];
            } else if (data['data'] != null) {
              departmentsList = data['data'];
            } else if (data['success'] == true && data['departments'] != null) {
              departmentsList = data['departments'];
            }

            if (departmentsList.isNotEmpty) {
              if (kDebugMode)
                print(
                  '✅ Found departments via alternative endpoint: ${departmentsList.length}',
                );

              setState(() {
                departments = List<Map<String, dynamic>>.from(departmentsList);
              });

              Fluttertoast.showToast(
                msg: "✅ Departments loaded via alternative endpoint",
                toastLength: Toast.LENGTH_SHORT,
              );
              return; // Success, exit the loop
            }
          }
        } catch (e) {
          if (kDebugMode) print('❌ Alternative endpoint $endpoint failed: $e');
          continue; // Try next endpoint
        }
      }

      // If all endpoints fail, create mock departments for testing
      if (kDebugMode)
        print('⚠️ All department endpoints failed, using mock data');

      setState(() {
        departments = [
          {'id': 'dept_001', 'name': 'Sales'},
          {'id': 'dept_002', 'name': 'Marketing'},
          {'id': 'dept_003', 'name': 'Operations'},
          {'id': 'dept_004', 'name': 'HR'},
          {'id': 'dept_005', 'name': 'Finance'},
        ];
      });

      Fluttertoast.showToast(
        msg: "⚠️ Using default departments (API unavailable)",
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Alternative department fetch failed: $e');
    }
  }

  String generatePassword() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(
      12,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contact number is required';
    }
    final phoneRegex = RegExp(r'^\d{10}$');
    final cleanedValue = value.replaceAll(RegExp(r'[^\d]'), '');
    if (!phoneRegex.hasMatch(cleanedValue)) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  String? validateAlternativePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final phoneRegex = RegExp(r'^\d{10}$');
    final cleanedValue = value.replaceAll(RegExp(r'[^\d]'), '');
    if (!phoneRegex.hasMatch(cleanedValue)) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  String? validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final pincodeRegex = RegExp(r'^\d{6}$');
    if (!pincodeRegex.hasMatch(value)) {
      return 'Please enter a valid 6-digit pincode';
    }
    return null;
  }

  String? validateAadhar(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final aadharRegex = RegExp(r'^\d{12}$');
    final cleanedValue = value.replaceAll(RegExp(r'[^\d]'), '');
    if (!aadharRegex.hasMatch(cleanedValue)) {
      return 'Please enter a valid 12-digit Aadhar number';
    }
    return null;
  }

  String? validatePAN(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    if (!panRegex.hasMatch(value.toUpperCase())) {
      return 'Please enter a valid PAN (e.g., ABCDE1234F)';
    }
    return null;
  }

  // Image picker with camera and gallery options
  Future<void> pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromSource(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  // Convert image to base64
  Future<String?> convertImageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64Image';
    } catch (e) {
      Fluttertoast.showToast(msg: "Error processing image: $e");
      return null;
    }
  }

  // Fetch location from pincode
  Future<void> fetchLocationFromPincode() async {
    final pincode = _pincodeController.text.trim();
    if (pincode.length != 6) {
      Fluttertoast.showToast(msg: "Enter valid 6-digit pincode");
      return;
    }

    setState(() {
      fetchingPincode = true;
      isLoadingAreas = true;
    });

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/masters/pincode/$pincode/areas"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          final locationData = data["data"];
          setState(() {
            // Auto-fill all location fields from pincode lookup
            _countryController.text = locationData["country"] ?? "India";
            _stateController.text = locationData["state"] ?? "";
            _districtController.text = locationData["district"] ?? "";
            _cityController.text = locationData["city"] ?? "";

            // Load areas and reset selection - convert string array to map array
            final areasData = locationData["areas"] ?? [];
            if (areasData is List) {
              _availableAreas = areasData.map((area) {
                if (area is String) {
                  return {'name': area};
                } else if (area is Map<String, dynamic>) {
                  return area;
                } else {
                  return {'name': area.toString()};
                }
              }).toList();
            } else {
              _availableAreas = [];
            }
            selectedArea = null; // Reset area selection when pincode changes
          });

          Fluttertoast.showToast(
            msg:
                "✅ Location details fetched successfully!\nCountry: ${locationData["country"] ?? "India"}\nState: ${locationData["state"] ?? ""}\nDistrict: ${locationData["district"] ?? ""}\nCity: ${locationData["city"] ?? ""}",
            toastLength: Toast.LENGTH_LONG,
          );
        } else {
          Fluttertoast.showToast(msg: data["message"] ?? "Invalid pincode");
          setState(() {
            // Clear location fields if pincode is invalid
            _countryController.text = "";
            _stateController.text = "";
            _districtController.text = "";
            _cityController.text = "";
            _availableAreas = [];
            selectedArea = null;
          });
        }
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "❌ Error fetching location: $e",
        toastLength: Toast.LENGTH_LONG,
      );
      setState(() {
        _availableAreas = [];
        selectedArea = null;
      });
    }

    setState(() {
      fetchingPincode = false;
      isLoadingAreas = false;
    });
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    setState(() => isLoadingGeolocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(msg: 'Location services are disabled');
        setState(() => isLoadingGeolocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(msg: 'Location permission denied');
          setState(() => isLoadingGeolocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(
          msg: 'Location permissions are permanently denied',
        );
        setState(() => isLoadingGeolocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      
      // Update marker and camera
      await _updateLocationMarker(position.latitude, position.longitude);
      if (_mapboxMap != null && _mapboxService.map != null) {
        await _mapboxService.animateCamera(
          center: Point(coordinates: Position(position.longitude, position.latitude)),
          zoom: 15.0,
        );
      }

      Fluttertoast.showToast(
        msg:
            'Location captured: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to get location: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingGeolocation = false);
      }
    }
  }

  Future<void> _openInGoogleMaps() async {
    if (_latitude == null || _longitude == null) return;

    // Open in external map app (Google Maps or default)
    final url =
        'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Fluttertoast.showToast(msg: 'Could not open map application');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error opening map: $e');
    }
  }
  
  // Update location marker on Mapbox map
  Future<void> _updateLocationMarker(double lat, double lng) async {
    if (_pointAnnotationManager == null) return;
    
    try {
      // Remove old marker
      final oldMarker = _markerAnnotations['selected_location'];
      if (oldMarker != null) {
        await _pointAnnotationManager!.delete(oldMarker);
        _markerAnnotations.remove('selected_location');
      }
      
      // Add new marker
      final options = PointAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        textField: 'Employee Location\nTap to change location',
        textOffset: [0.0, -2.0],
        textSize: 12.0,
        iconSize: 1.2,
      );
      
      final marker = await _pointAnnotationManager!.create(options);
      _markerAnnotations['selected_location'] = marker;
    } catch (e) {
      print('Error updating location marker: $e');
    }
  }

  // Location search functionality
  Future<void> _searchAndMoveToLocation(String query) async {
    setState(() => isLoadingGeolocation = true);

    try {
      double lat = 20.5937; // Default to India center
      double lng = 78.9629;
      String locationName = 'Location not found';
      bool foundLocation = false;

      // First, check if it's a pincode (6 digits)
      if (RegExp(r'^\d{6}$').hasMatch(query.trim())) {
        final response = await http.get(
          Uri.parse(
            "${ApiConfig.baseUrl}/masters/pincode/${query.trim()}/areas",
          ),
        );

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          if (result['success'] == true) {
            final data = result['data'];

            // Use real geocoding to get coordinates for the city
            final cityName = data['city'] ?? data['district'];
            final geocodingResult = await _performGeocodingSearch(cityName);

            if (geocodingResult != null) {
              lat = geocodingResult['lat'];
              lng = geocodingResult['lng'];
              locationName =
                  '${data['city'] ?? data['district']}, ${data['state']}, India';
              foundLocation = true;

              setState(() {
                _countryController.text = data['country'] ?? 'India';
                _stateController.text = data['state'] ?? '';
                _districtController.text = data['district'] ?? '';
                _cityController.text = data['city'] ?? '';
                _pincodeController.text = query.trim();
              });
            }
          }
        }
      }

      // If not found by pincode, try real geocoding search
      if (!foundLocation) {
        final geocodingResult = await _performGeocodingSearch(query);
        if (geocodingResult != null) {
          lat = geocodingResult['lat'];
          lng = geocodingResult['lng'];
          locationName = geocodingResult['name'];
          foundLocation = true;
        }
      }

      // Move map camera to the location with smooth animation
      if (_mapboxMap != null && foundLocation && _mapboxService.map != null) {
        await _mapboxService.animateCamera(
          center: Point(coordinates: Position(lng, lat)),
          zoom: _getAppropriateZoomLevel(locationName, query),
        );
      }

      setState(() {
        _latitude = lat;
        _longitude = lng;
      });
      
      // Update marker on map
      if (_latitude != null && _longitude != null) {
        await _updateLocationMarker(_latitude!, _longitude!);
      }

      if (foundLocation) {
        Fluttertoast.showToast(
          msg: 'Found: $locationName',
          toastLength: Toast.LENGTH_LONG,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Location not found. Try a different search term.',
          toastLength: Toast.LENGTH_LONG,
        );
      }

      // Clear search field
      _locationSearchController.clear();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to search location: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingGeolocation = false);
      }
    }
  }

  // Real geocoding search using OpenStreetMap Nominatim API
  Future<Map<String, dynamic>?> _performGeocodingSearch(String query) async {
    try {
      // Use OpenStreetMap Nominatim API for geocoding
      final encodedQuery = Uri.encodeComponent('$query, India');
      final url =
          'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=1&addressdetails=1';

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'LoagmaCRM/1.0 (Flutter App)',
              'Accept-Language': 'en',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          final result = results[0];
          final lat = double.parse(result['lat']);
          final lng = double.parse(result['lon']);
          final displayName = result['display_name'] ?? query;

          return {'lat': lat, 'lng': lng, 'name': displayName};
        }
      }
    } catch (e) {
      if (kDebugMode) print('Geocoding error: $e');
    }
    return null;
  }

  // Get appropriate zoom level based on location type
  double _getAppropriateZoomLevel(String locationName, String query) {
    final lowerName = locationName.toLowerCase();
    final lowerQuery = query.toLowerCase();

    // Very specific locations (buildings, shops, etc.)
    if (lowerName.contains('hotel') ||
        lowerName.contains('restaurant') ||
        lowerName.contains('shop') ||
        lowerName.contains('mall') ||
        lowerQuery.contains('nagar') ||
        lowerQuery.contains('colony')) {
      return 17.0; // Very high zoom for specific places
    }

    // Areas and localities
    if (lowerName.contains('area') ||
        lowerName.contains('sector') ||
        lowerQuery.contains('area') ||
        lowerQuery.contains('sector')) {
      return 15.0; // High zoom for areas
    }

    // Districts and suburbs
    if (lowerName.contains('district') || lowerName.contains('suburb')) {
      return 13.0; // Medium zoom for districts
    }

    // Cities
    if (lowerName.contains('city') || lowerName.contains(',')) {
      return 11.0; // Lower zoom for cities
    }

    // Default for localities
    return 14.0;
  }

  // Multi-select dialog
  Future<void> showMultiSelectDialog({
    required BuildContext context,
    required List<Map<String, dynamic>> items,
    required List<String> selectedValues,
    required Function(List<String>) onConfirm,
    String title = "Select Options",
  }) {
    List<String> tempSelected = List.from(selectedValues);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  SizedBox(
                    height: 300,
                    child: ListView(
                      children: items.map((item) {
                        final id = item['id'];
                        final name = item['name'];

                        return CheckboxListTile(
                          title: Text(name),
                          value: tempSelected.contains(id),
                          onChanged: (value) {
                            setModalState(() {
                              if (value == true) {
                                tempSelected.add(id);
                              } else {
                                tempSelected.remove(id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      onConfirm(tempSelected);
                      Navigator.pop(context);
                    },
                    child: const Text("Done"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> updateUser() async {
    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(msg: "Please fix all validation errors");
      return;
    }

    setState(() => isLoading = true);

    // Convert image to base64 if selected
    if (_profileImage != null) {
      if (kDebugMode) print("📸 Converting image to base64...");
      _uploadedImageUrl = await convertImageToBase64(_profileImage!);
      if (_uploadedImageUrl == null) {
        setState(() => isLoading = false);
        Fluttertoast.showToast(msg: "Failed to process image");
        return;
      }
      if (kDebugMode) print("✅ Image converted successfully");
    }

    try {
      String? password = _passwordController.text.trim();
      if (autoGeneratePassword) {
        password = generatePassword();
      }

      final body = {
        "contactNumber": _phoneController.text.trim(),
        if (_nameController.text.trim().isNotEmpty)
          "name": _nameController.text.trim(),
        if (_emailController.text.trim().isNotEmpty)
          "email": _emailController.text.trim(),
        if (_alternativePhoneController.text.trim().isNotEmpty)
          "alternativeNumber": _alternativePhoneController.text.trim(),
        if (selectedRoleId != null) "roleId": selectedRoleId,
        if (selectedRoles.isNotEmpty) "roles": selectedRoles,
        if (selectedDepartmentId != null) "departmentId": selectedDepartmentId,
        if (selectedGender != null) "gender": selectedGender,
        if (_selectedDateOfBirth != null)
          "dateOfBirth": _selectedDateOfBirth!.toIso8601String(),
        if (selectedLanguages.isNotEmpty)
          "preferredLanguages": selectedLanguages,
        "isActive": isActive,
        if (password.isNotEmpty) "password": password,
        if (_addressController.text.trim().isNotEmpty)
          "address": _addressController.text.trim(),
        if (_cityController.text.trim().isNotEmpty)
          "city": _cityController.text.trim(),
        if (_stateController.text.trim().isNotEmpty)
          "state": _stateController.text.trim(),
        if (_pincodeController.text.trim().isNotEmpty)
          "pincode": _pincodeController.text.trim(),
        if (_countryController.text.trim().isNotEmpty)
          "country": _countryController.text.trim(),
        if (_districtController.text.trim().isNotEmpty)
          "district": _districtController.text.trim(),
        if (selectedArea != null) "area": selectedArea,
        if (_latitude != null) "latitude": _latitude,
        if (_longitude != null) "longitude": _longitude,
        if (_aadharController.text.trim().isNotEmpty)
          "aadharCard": _aadharController.text.trim(),
        if (_panController.text.trim().isNotEmpty)
          "panCard": _panController.text.trim().toUpperCase(),
        if (_notesController.text.trim().isNotEmpty)
          "notes": _notesController.text.trim(),
        if (_uploadedImageUrl != null) "image": _uploadedImageUrl,
      };

      // Update user first
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/admin/users/${widget.user['id']}',
      );
      if (kDebugMode) print('📡 Updating user via $url');
      if (kDebugMode) print('📤 Request body: $body');

      final response = await http
          .put(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Update salary if changed
        if (_salaryController.text.trim().isNotEmpty) {
          final salaryBody = {
            "employeeId": widget.user['id'],
            "basicSalary": _salaryController.text.trim(),
            "effectiveFrom": DateTime.now().toIso8601String(),
          };

          final salaryUrl = Uri.parse('${ApiConfig.baseUrl}/salaries');
          await http.post(
            salaryUrl,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(salaryBody),
          );
        }

        // Save working hours
        await _saveWorkingHours();

        // Show success toast
        if (mounted) {
          CustomToast.showSuccess(context, "✅ Employee Updated Successfully!");
        }

        if (autoGeneratePassword && password.isNotEmpty) {
          Fluttertoast.showToast(
            msg: "Generated Password: $password",
            toastLength: Toast.LENGTH_LONG,
          );
        }

        // Wait for toast to show before popping
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? "Failed to update");
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error updating user: $e');
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Employee"),
        backgroundColor: const Color(0xFFD7BE69),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD7BE69)),
            )
          : Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  // Contact Number
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: "Contact Number *",
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      counterText: "",
                    ),
                    validator: validatePhone,
                  ),
                  const SizedBox(height: 15),

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          value.length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 15),

                  // Gender
                  DropdownButtonFormField<String>(
                    initialValue: selectedGender,
                    items: const [
                      DropdownMenuItem(value: "Male", child: Text("Male")),
                      DropdownMenuItem(value: "Female", child: Text("Female")),
                      DropdownMenuItem(value: "Other", child: Text("Other")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Gender",
                      prefixIcon: const Icon(Icons.wc),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Date of Birth
                  ListTile(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: const Icon(Icons.cake),
                    title: const Text("Date of Birth"),
                    subtitle: Text(
                      _selectedDateOfBirth == null
                          ? "Tap to select"
                          : "${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}",
                    ),
                    trailing: _selectedDateOfBirth != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: () {
                              setState(() => _selectedDateOfBirth = null);
                            },
                          )
                        : const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDateOfBirth ?? DateTime(2000),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFFD7BE69),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => _selectedDateOfBirth = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 15),

                  // Multi-Select Languages
                  ListTile(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: const Text("Preferred Languages"),
                    subtitle: Text(
                      selectedLanguages.isEmpty
                          ? "Tap to select"
                          : selectedLanguages.join(", "),
                    ),
                    leading: const Icon(Icons.language),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: () {
                      showMultiSelectDialog(
                        context: context,
                        title: "Select Preferred Languages",
                        items: const [
                          {"id": "English", "name": "English"},
                          {"id": "Hindi", "name": "Hindi"},
                          {"id": "Marathi", "name": "Marathi"},
                          {"id": "Gujarati", "name": "Gujarati"},
                          {"id": "Tamil", "name": "Tamil"},
                          {"id": "Telugu", "name": "Telugu"},
                          {"id": "Kannada", "name": "Kannada"},
                          {"id": "Bengali", "name": "Bengali"},
                        ],
                        selectedValues: selectedLanguages,
                        onConfirm: (values) {
                          setState(() => selectedLanguages = values);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 15),

                  // Alternative Number
                  TextFormField(
                    controller: _alternativePhoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: "Alternative Number",
                      prefixIcon: const Icon(Icons.phone_android),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      counterText: "",
                    ),
                    validator: validateAlternativePhone,
                  ),
                  const SizedBox(height: 15),

                  // Aadhar Card
                  TextFormField(
                    controller: _aadharController,
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    decoration: InputDecoration(
                      labelText: "Aadhar Card Number",
                      prefixIcon: const Icon(Icons.credit_card),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      counterText: "",
                      hintText: "XXXX XXXX XXXX",
                    ),
                    validator: validateAadhar,
                  ),
                  const SizedBox(height: 15),

                  // PAN Card
                  TextFormField(
                    controller: _panController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: "PAN Card Number",
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      counterText: "",
                      hintText: "ABCDE1234F",
                    ),
                    validator: validatePAN,
                  ),
                  const SizedBox(height: 15),

                  // Pincode with Lookup
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: "Pincode",
                            prefixIcon: const Icon(Icons.pin_drop),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            counterText: "",
                          ),
                          validator: validatePincode,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: fetchingPincode
                            ? null
                            : fetchLocationFromPincode,
                        icon: fetchingPincode
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search, size: 20),
                        label: const Text("Lookup"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD7BE69),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Country (Auto-filled from pincode, read-only)
                  TextFormField(
                    controller: _countryController,
                    enabled: false, // Disabled - only filled via pincode lookup
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "Country",
                      prefixIcon: const Icon(Icons.public),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      helperText: "Auto-filled from pincode lookup",
                      helperStyle: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // State (Auto-filled from pincode, read-only)
                  TextFormField(
                    controller: _stateController,
                    enabled: false, // Disabled - only filled via pincode lookup
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "State",
                      prefixIcon: const Icon(Icons.map),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      helperText: "Auto-filled from pincode lookup",
                      helperStyle: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // District (Auto-filled from pincode, read-only)
                  TextFormField(
                    controller: _districtController,
                    enabled: false, // Disabled - only filled via pincode lookup
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "District",
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      helperText: "Auto-filled from pincode lookup",
                      helperStyle: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // City (Auto-filled from pincode, read-only)
                  TextFormField(
                    controller: _cityController,
                    enabled: false, // Disabled - only filled via pincode lookup
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "City",
                      prefixIcon: const Icon(Icons.location_city),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      helperText: "Auto-filled from pincode lookup",
                      helperStyle: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Area Dropdown (if areas available)
                  if (_availableAreas.isNotEmpty)
                    Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: selectedArea,
                          decoration: InputDecoration(
                            labelText: "Area *",
                            prefixIcon: const Icon(Icons.place),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _availableAreas
                              .map(
                                (area) => DropdownMenuItem<String>(
                                  value: area['name'],
                                  child: Text(area['name']),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => selectedArea = v),
                        ),
                        const SizedBox(height: 15),
                      ],
                    )
                  else if (isLoadingAreas)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_pincodeController.text.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Text(
                        'No areas found for this pincode',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),

                  // Address
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "Address",
                      prefixIcon: const Icon(Icons.home),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Geolocation Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.my_location,
                                color: Color(0xFFD7BE69),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Geolocation",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (_latitude != null && _longitude != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Location Captured',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => setState(() {
                                      _latitude = null;
                                      _longitude = null;
                                    }),
                                  ),
                                ],
                              ),
                            ),

                          ElevatedButton.icon(
                            icon: isLoadingGeolocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.my_location),
                            label: Text(
                              isLoadingGeolocation
                                  ? 'Getting Location...'
                                  : 'Capture Current Location',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD7BE69),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: isLoadingGeolocation
                                ? null
                                : _getCurrentLocation,
                          ),

                          // Interactive Map for Location Selection
                          const SizedBox(height: 16),
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFD7BE69),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  GestureDetector(
                                    onTapUp: (details) async {
                                      // Handle map tap to select location
                                      // Note: Mapbox requires getting coordinates from screen point
                                      if (_mapboxMap != null) {
                                        try {
                                          final screenCoordinate = ScreenCoordinate(
                                            x: details.localPosition.dx,
                                            y: details.localPosition.dy,
                                          );
                                          final coordinate = await _mapboxMap!.coordinateForPixel(screenCoordinate);
                                          
                                          setState(() {
                                            _latitude = coordinate.latitude;
                                            _longitude = coordinate.longitude;
                                          });
                                          
                                          await _updateLocationMarker(_latitude!, _longitude!);
                                          
                                          Fluttertoast.showToast(
                                            msg:
                                                'Location selected: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                          );
                                        } catch (e) {
                                          print('Error handling map tap: $e');
                                        }
                                      }
                                    },
                                    child: _buildMapboxMap(),
                                  ),

                                  // Search overlay
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    right: 60, // Leave space for zoom controls
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller:
                                                  _locationSearchController,
                                              decoration: InputDecoration(
                                                hintText:
                                                    'Search places, hotels, shops, areas...',
                                                prefixIcon: const Icon(
                                                  Icons.search,
                                                ),
                                                suffixIcon: isLoadingGeolocation
                                                    ? const Padding(
                                                        padding: EdgeInsets.all(
                                                          12.0,
                                                        ),
                                                        child: SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                color: Color(
                                                                  0xFFD7BE69,
                                                                ),
                                                              ),
                                                        ),
                                                      )
                                                    : null,
                                                border: InputBorder.none,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12,
                                                    ),
                                              ),
                                              onSubmitted: (value) {
                                                if (value.trim().isNotEmpty) {
                                                  _searchAndMoveToLocation(
                                                    value.trim(),
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.search),
                                            onPressed: isLoadingGeolocation
                                                ? null
                                                : () {
                                                    final query =
                                                        _locationSearchController
                                                            .text
                                                            .trim();
                                                    if (query.isNotEmpty) {
                                                      _searchAndMoveToLocation(
                                                        query,
                                                      );
                                                    } else {
                                                      Fluttertoast.showToast(
                                                        msg:
                                                            'Enter city name or pincode to search',
                                                      );
                                                    }
                                                  },
                                            tooltip: 'Search location',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.my_location),
                                            onPressed: isLoadingGeolocation
                                                ? null
                                                : _getCurrentLocation,
                                            tooltip: 'Use current location',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Instructions overlay
                                  if (_latitude == null || _longitude == null)
                                    Positioned(
                                      bottom: 10,
                                      left: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'Tap on the map to select employee location or search above',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),

                                  // Open in Maps button (when location is set)
                                  if (_latitude != null && _longitude != null)
                                    Positioned(
                                      bottom: 10,
                                      right: 10,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.2,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: _openInGoogleMaps,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.open_in_new,
                                                    size: 18,
                                                    color: Color(0xFFD7BE69),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Open in Maps',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(0xFFD7BE69),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Department
                  DropdownButtonFormField<String>(
                    initialValue: selectedDepartmentId,
                    items: departments.map((dept) {
                      return DropdownMenuItem<String>(
                        value: dept['id'],
                        child: Text(dept['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDepartmentId = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Department",
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Primary Role
                  DropdownButtonFormField<String>(
                    initialValue: selectedRoleId,
                    items: roles.map((role) {
                      return DropdownMenuItem<String>(
                        value: role['id'],
                        child: Text(role['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedRoleId = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Primary Role",
                      prefixIcon: const Icon(Icons.badge),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Additional Roles
                  ListTile(
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: const Text("Additional Roles"),
                    subtitle: Text(
                      selectedRoles.isEmpty
                          ? "Tap to select"
                          : "${selectedRoles.length} roles selected",
                    ),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: () {
                      showMultiSelectDialog(
                        context: context,
                        title: "Select Additional Roles",
                        items: roles,
                        selectedValues: selectedRoles,
                        onConfirm: (values) {
                          setState(() => selectedRoles = values);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 25),

                  // Working Hours Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule,
                                color: Color(0xFFD7BE69),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Working Hours",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (isLoadingWorkingHours)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Set employee's work schedule for late punch-in and early punch-out rules",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Work Start Time
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.login,
                              color: Colors.green,
                            ),
                            title: const Text("Work Start Time"),
                            subtitle: Text(_formatTimeOfDay(_workStartTime)),
                            trailing: const Icon(Icons.edit),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime:
                                    _workStartTime ??
                                    const TimeOfDay(hour: 9, minute: 0),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFFD7BE69),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => _workStartTime = picked);
                              }
                            },
                          ),
                          const Divider(),

                          // Work End Time
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.logout,
                              color: Colors.red,
                            ),
                            title: const Text("Work End Time"),
                            subtitle: Text(_formatTimeOfDay(_workEndTime)),
                            trailing: const Icon(Icons.edit),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime:
                                    _workEndTime ??
                                    const TimeOfDay(hour: 18, minute: 0),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFFD7BE69),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => _workEndTime = picked);
                              }
                            },
                          ),
                          const Divider(),

                          // Late Punch-In Grace Minutes
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.timer,
                              color: Colors.orange,
                            ),
                            title: const Text("Late Punch-In Grace"),
                            subtitle: Text(
                              "$_latePunchInGraceMinutes minutes after start time",
                            ),
                            trailing: SizedBox(
                              width: 120,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    onPressed: _latePunchInGraceMinutes > 0
                                        ? () => setState(
                                            () => _latePunchInGraceMinutes -= 5,
                                          )
                                        : null,
                                  ),
                                  Text(
                                    '$_latePunchInGraceMinutes',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: _latePunchInGraceMinutes < 120
                                        ? () => setState(
                                            () => _latePunchInGraceMinutes += 5,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(),

                          // Early Punch-Out Grace Minutes
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.timer_off,
                              color: Colors.purple,
                            ),
                            title: const Text("Early Punch-Out Grace"),
                            subtitle: Text(
                              "$_earlyPunchOutGraceMinutes minutes before end time",
                            ),
                            trailing: SizedBox(
                              width: 120,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    onPressed: _earlyPunchOutGraceMinutes > 0
                                        ? () => setState(
                                            () =>
                                                _earlyPunchOutGraceMinutes -= 5,
                                          )
                                        : null,
                                  ),
                                  Text(
                                    '$_earlyPunchOutGraceMinutes',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: _earlyPunchOutGraceMinutes < 120
                                        ? () => setState(
                                            () =>
                                                _earlyPunchOutGraceMinutes += 5,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Summary
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Summary",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "• Late punch-in requires approval after ${_workStartTime != null ? _formatTimeOfDay(TimeOfDay(hour: _workStartTime!.hour + (_workStartTime!.minute + _latePunchInGraceMinutes) ~/ 60, minute: (_workStartTime!.minute + _latePunchInGraceMinutes) % 60)) : 'N/A'}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "• Early punch-out requires approval before ${_workEndTime != null ? _formatTimeOfDay(TimeOfDay(hour: _workEndTime!.hour - (_earlyPunchOutGraceMinutes ~/ 60) - ((_workEndTime!.minute - _earlyPunchOutGraceMinutes % 60) < 0 ? 1 : 0), minute: (_workEndTime!.minute - _earlyPunchOutGraceMinutes % 60 + 60) % 60)) : 'N/A'}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Status
                  SwitchListTile(
                    title: const Text("Status"),
                    subtitle: Text(isActive ? "Active" : "Inactive"),
                    value: isActive,
                    onChanged: (value) {
                      setState(() {
                        isActive = value;
                      });
                    },
                  ),
                  const SizedBox(height: 15),

                  // Password Section
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          enabled: !autoGeneratePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          const Text("Auto"),
                          Checkbox(
                            value: autoGeneratePassword,
                            onChanged: (value) {
                              setState(() {
                                autoGeneratePassword = value ?? false;
                                if (autoGeneratePassword) {
                                  _passwordController.clear();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Salary Per Month
                  TextFormField(
                    controller: _salaryController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: "Salary Per Month *",
                      prefixIcon: const Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: "e.g., 50000",
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Salary per month is required';
                      }
                      final salary = double.tryParse(value.trim());
                      if (salary == null || salary <= 0) {
                        return 'Please enter a valid salary amount greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: "Notes",
                      prefixIcon: const Icon(Icons.note),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // PROFILE PICTURE UPLOAD
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Profile Picture",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: const Color(0xFFD7BE69),
                                  backgroundImage: _profileImage != null
                                      ? FileImage(_profileImage!)
                                      : _existingImageUrl != null
                                      ? NetworkImage(_existingImageUrl!)
                                      : null,
                                  child:
                                      _profileImage == null &&
                                          _existingImageUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: pickImage,
                                      icon: const Icon(Icons.photo_library),
                                      label: const Text("Choose Photo"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFD7BE69,
                                        ),
                                      ),
                                    ),
                                    if (_profileImage != null ||
                                        _existingImageUrl != null) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _profileImage = null;
                                            _uploadedImageUrl = null;
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Update Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color(0xFFD7BE69),
                    ),
                    onPressed: isLoading ? null : updateUser,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Update Employee",
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
