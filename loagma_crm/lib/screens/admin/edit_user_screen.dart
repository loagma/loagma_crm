import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_config.dart';

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

  // Geolocation
  double? _latitude;
  double? _longitude;
  bool isLoadingGeolocation = false;

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
  }

  @override
  void dispose() {
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
    super.dispose();
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

  Future<void> fetchDepartments() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/departments');
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          departments = List<Map<String, dynamic>>.from(data['departments']);
          isLoadingData = false;
        });
      } else {
        setState(() => isLoadingData = false);
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading departments: $e');
      setState(() => isLoadingData = false);
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

  // Image picker
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
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
            _cityController.text = locationData["city"] ?? "";
            _stateController.text = locationData["state"] ?? "";

            // Load areas
            _availableAreas = List<Map<String, dynamic>>.from(
              locationData["areas"] ?? [],
            );
            selectedArea = null;
          });
          Fluttertoast.showToast(msg: "Location fetched successfully");
        } else {
          Fluttertoast.showToast(msg: data["message"] ?? "Invalid pincode");
          setState(() {
            _availableAreas = [];
            selectedArea = null;
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching location: $e");
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

    final url =
        'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Fluttertoast.showToast(msg: 'Could not open Google Maps');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error opening Google Maps: $e');
    }
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

        Fluttertoast.showToast(
          msg: "User updated successfully",
          toastLength: Toast.LENGTH_LONG,
        );

        if (autoGeneratePassword && password.isNotEmpty) {
          Fluttertoast.showToast(
            msg: "Generated Password: $password",
            toastLength: Toast.LENGTH_LONG,
          );
        }

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
                    value: selectedGender,
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

                  // Country
                  TextFormField(
                    controller: _countryController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "Country",
                      prefixIcon: const Icon(Icons.public),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // State
                  TextFormField(
                    controller: _stateController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "State",
                      prefixIcon: const Icon(Icons.map),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // District
                  TextFormField(
                    controller: _districtController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "District",
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // City
                  TextFormField(
                    controller: _cityController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "City",
                      prefixIcon: const Icon(Icons.location_city),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Area Dropdown (if areas available)
                  if (_availableAreas.isNotEmpty)
                    Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedArea,
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

                          // Google Map Display
                          if (_latitude != null && _longitude != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              height: 250,
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
                                    GoogleMap(
                                      initialCameraPosition: CameraPosition(
                                        target: LatLng(_latitude!, _longitude!),
                                        zoom: 15,
                                      ),
                                      markers: {
                                        Marker(
                                          markerId: const MarkerId(
                                            'current_location',
                                          ),
                                          position: LatLng(
                                            _latitude!,
                                            _longitude!,
                                          ),
                                          infoWindow: const InfoWindow(
                                            title: 'Current Location',
                                          ),
                                        ),
                                      },
                                      myLocationButtonEnabled: false,
                                      zoomControlsEnabled: false,
                                      mapToolbarEnabled: false,
                                      onTap: (_) => _openInGoogleMaps(),
                                    ),
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Department
                  DropdownButtonFormField<String>(
                    value: selectedDepartmentId,
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
                    value: selectedRoleId,
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
