// ---------------------------------------------------
// ADMIN CREATE USER SCREEN (Fully Refactored)
// ---------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_config.dart';
import 'user_detail_screen.dart';
import 'edit_user_screen.dart';

// ⬇️ Add multi-select helper widget ABOVE this class
// (already given above)

class AdminCreateUserScreen extends StatefulWidget {
  const AdminCreateUserScreen({super.key});

  @override
  State<AdminCreateUserScreen> createState() => _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends State<AdminCreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // ---------------- Controllers ----------------
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _altPhone = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final TextEditingController _pincode = TextEditingController();
  final TextEditingController _aadhar = TextEditingController();
  final TextEditingController _pan = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _salary = TextEditingController();
  final TextEditingController _country = TextEditingController();
  final TextEditingController _district = TextEditingController();

  DateTime? _selectedDateOfBirth;

  // ---------------- Dropdown Selections ----------------
  String? selectedRoleId;
  String? selectedDepartmentId;
  String? selectedGender;
  bool isActive = true;
  bool autoGeneratePassword = false;
  bool manualAddress = false;
  bool fetchingPincode = false;

  List<String> selectedRoles = []; // MULTI SELECT
  List<String> selectedLanguages = []; // MULTI SELECT LANGUAGES
  String? selectedArea; // AREA SELECTION

  // Geolocation
  double? _latitude;
  double? _longitude;
  bool isLoadingGeolocation = false;

  // ---------------- Data from API ----------------
  List<Map<String, dynamic>> roles = [];
  List<Map<String, dynamic>> departments = [];
  List<Map<String, dynamic>> _availableAreas = [];
  bool isLoadingAreas = false;

  // ---------------- Image Upload ----------------
  File? _profileImage;
  String? _uploadedImageUrl;
  bool isUploadingImage = false;

  // ---------------- Existing User Check ----------------
  Map<String, dynamic>? existingUser;
  bool checkingPhone = false;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchRoles();
    fetchDepartments();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _phone.dispose();
    _name.dispose();
    _email.dispose();
    _altPhone.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    _aadhar.dispose();
    _pan.dispose();
    _password.dispose();
    _notes.dispose();
    _salary.dispose();
    _country.dispose();
    _district.dispose();
    super.dispose();
  }

  // ---------------- API Functions ----------------

  Future<void> fetchRoles() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/roles"),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // API returns {success: true, data: [...]}
          roles = List<Map<String, dynamic>>.from(
            data["data"] ?? data["roles"] ?? [],
          );
        });
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching roles: $e");
    }
  }

  Future<void> fetchDepartments() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/masters/departments"),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // API returns {success: true, data: [...]}
          departments = List<Map<String, dynamic>>.from(
            data["data"] ?? data["departments"] ?? [],
          );
        });
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching departments: $e");
    }
  }

  // ---------------- Validators ----------------

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return "Required";
    if (!RegExp(r'^\d{10}$').hasMatch(value)) return "Invalid phone";
    return null;
  }

  String? validateEmail(String? v) {
    if (v == null || v.isEmpty) return null;
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
      return "Invalid Email";
    }
    return null;
  }

  String? validatePincode(String? v) {
    if (v == null || v.isEmpty) return null;
    return RegExp(r'^\d{6}$').hasMatch(v) ? null : "Invalid pincode";
  }

  String? validateAadhar(String? v) {
    if (v == null || v.isEmpty) return null;
    return RegExp(r'^\d{12}$').hasMatch(v) ? null : "Invalid Aadhar";
  }

  String? validatePAN(String? v) {
    if (v == null || v.isEmpty) return null;
    return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(v)
        ? null
        : "Invalid PAN";
  }

  // ---------------- Check Existing User ----------------

  Future<void> checkExistingUser(String phone) async {
    if (phone.length != 10) {
      setState(() {
        existingUser = null;
      });
      return;
    }

    setState(() {
      checkingPhone = true;
      existingUser = null;
    });

    try {
      if (kDebugMode) print("🔍 Checking contact number: $phone");

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/admin/users"),
        headers: {"Accept": "application/json"},
      );

      if (kDebugMode) print("📡 Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (kDebugMode)
          print("📦 Response data: ${data.toString().substring(0, 200)}...");

        if (data["success"] == true && data["users"] != null) {
          final users = List<Map<String, dynamic>>.from(data["users"]);

          // Filter users by contact number
          final matchingUsers = users.where((user) {
            final userPhone = user['contactNumber']?.toString() ?? '';
            final cleanUserPhone = userPhone.replaceAll(RegExp(r'\D'), '');
            final cleanSearchPhone = phone.replaceAll(RegExp(r'\D'), '');

            if (kDebugMode) {
              print("Comparing: $cleanUserPhone == $cleanSearchPhone");
            }

            return cleanUserPhone == cleanSearchPhone;
          }).toList();

          if (matchingUsers.isNotEmpty) {
            if (kDebugMode)
              print("✅ Found existing user: ${matchingUsers[0]['name']}");
            setState(() => existingUser = matchingUsers[0]);
          } else {
            if (kDebugMode) print("✅ No existing user found");
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print("❌ Error checking user: $e");
    } finally {
      if (mounted) {
        setState(() => checkingPhone = false);
      }
    }
  }

  Future<void> _confirmDelete(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this employee?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteUser(userId);
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse("${ApiConfig.baseUrl}/admin/users/$userId"),
        headers: {"Accept": "application/json"},
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        Fluttertoast.showToast(msg: "Employee deleted successfully");
        setState(() => existingUser = null);
        _phone.clear();
      } else {
        Fluttertoast.showToast(msg: data["message"] ?? "Failed to delete");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  // ---------------- Fetch Location from Pincode ----------------

  Future<void> fetchLocationFromPincode() async {
    final pincode = _pincode.text.trim();
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
            _country.text = locationData["country"] ?? "India";
            _state.text = locationData["state"] ?? "";
            _district.text = locationData["district"] ?? "";
            _city.text = locationData["city"] ?? "";

            // Load areas
            _availableAreas = List<Map<String, dynamic>>.from(
              locationData["areas"] ?? [],
            );
            selectedArea = null; // Reset area selection
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

  // ---------------- Geolocation ----------------

  Future<void> _getCurrentLocation() async {
    setState(() => isLoadingGeolocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(msg: 'Location services are disabled');
        setState(() => isLoadingGeolocation = false);
        return;
      }

      // Check location permissions
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

      // Get current position
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

  // ---------------- Image Upload to Cloudinary ----------------

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

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

  // ---------------- Password Generator ----------------

  String generatePassword() {
    const chars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*";
    final random = Random.secure();

    return List.generate(12, (i) => chars[random.nextInt(chars.length)]).join();
  }

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

  // ---------------- Create User ----------------

  Future<void> createUser() async {
    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(msg: "Fix validation errors");
      return;
    }

    // Check if contact number already exists
    if (existingUser != null) {
      Fluttertoast.showToast(msg: "Please use a different contact number");
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

    String password = _password.text;
    if (autoGeneratePassword) {
      password = generatePassword();
    }

    final body = {
      "contactNumber": _phone.text.trim(),
      "salaryPerMonth": double.tryParse(_salary.text.trim()),

      if (_name.text.isNotEmpty) "name": _name.text.trim(),
      if (_email.text.isNotEmpty) "email": _email.text.trim(),
      if (_altPhone.text.isNotEmpty) "alternativeNumber": _altPhone.text.trim(),

      if (selectedRoleId != null) "roleId": selectedRoleId,
      if (selectedRoles.isNotEmpty) "roles": selectedRoles,

      if (selectedDepartmentId != null) "departmentId": selectedDepartmentId,
      if (selectedGender != null) "gender": selectedGender,
      if (_selectedDateOfBirth != null)
        "dateOfBirth": _selectedDateOfBirth!.toIso8601String(),
      if (selectedLanguages.isNotEmpty) "preferredLanguages": selectedLanguages,

      "isActive": isActive,

      if (password.isNotEmpty) "password": password,
      if (_address.text.isNotEmpty) "address": _address.text.trim(),
      if (_city.text.isNotEmpty) "city": _city.text.trim(),
      if (_state.text.isNotEmpty) "state": _state.text.trim(),
      if (_pincode.text.isNotEmpty) "pincode": _pincode.text.trim(),
      if (_country.text.isNotEmpty) "country": _country.text.trim(),
      if (_district.text.isNotEmpty) "district": _district.text.trim(),
      if (selectedArea != null) "area": selectedArea,
      if (_aadhar.text.isNotEmpty) "aadharCard": _aadhar.text.trim(),
      if (_pan.text.isNotEmpty) "panCard": _pan.text.trim().toUpperCase(),
      if (_notes.text.isNotEmpty) "notes": _notes.text.trim(),
      if (_uploadedImageUrl != null) "image": _uploadedImageUrl,
      if (_latitude != null) "latitude": _latitude,
      if (_longitude != null) "longitude": _longitude,
    };

    try {
      if (kDebugMode) print("📤 Sending create user request...");
      if (kDebugMode)
        print("📦 Request body: ${jsonEncode(body).substring(0, 200)}...");

      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/admin/users"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (kDebugMode) print("📡 Response status: ${response.statusCode}");

      final data = jsonDecode(response.body);

      if (kDebugMode)
        print("📦 Response: ${data.toString().substring(0, 200)}...");

      if (data["success"] == true) {
        Fluttertoast.showToast(msg: "User created successfully");

        if (autoGeneratePassword) {
          Fluttertoast.showToast(msg: "Password: $password");
        }

        // Reset form
        _formKey.currentState!.reset();
        _phone.clear();
        _name.clear();
        _email.clear();
        _altPhone.clear();
        _address.clear();
        _city.clear();
        _state.clear();
        _pincode.clear();
        _country.clear();
        _district.clear();
        _aadhar.clear();
        _pan.clear();
        _password.clear();
        _notes.clear();
        _salary.clear();

        setState(() {
          selectedRoles.clear();
          selectedLanguages.clear();
          selectedRoleId = null;
          selectedDepartmentId = null;
          selectedGender = null;
          selectedArea = null;
          _profileImage = null;
          _uploadedImageUrl = null;
          existingUser = null;
          _latitude = null;
          _longitude = null;
          _availableAreas = [];
          _selectedDateOfBirth = null;
        });

        // Scroll to top after successful submission
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      } else {
        Fluttertoast.showToast(msg: data["message"] ?? "Failed");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    }

    setState(() => isLoading = false);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Employee"),
        backgroundColor: const Color(0xFFD7BE69),
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            // PHONE WITH CHECK
            TextFormField(
              controller: _phone,
              maxLength: 10,
              keyboardType: TextInputType.phone,
              onChanged: (value) {
                if (value.length == 10) {
                  checkExistingUser(value);
                } else {
                  setState(() {
                    existingUser = null;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Contact Number *',
                prefixIcon: const Icon(Icons.phone, color: Color(0xFFD7BE69)),
                suffixIcon: checkingPhone
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFD7BE69),
                          ),
                        ),
                      )
                    : existingUser != null
                    ? const Icon(Icons.error, color: Colors.red)
                    : _phone.text.length == 10
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: existingUser != null
                        ? Colors.red
                        : const Color(0xFFD7BE69),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                counterText: '',
              ),
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Contact number is required';
                if (v!.length != 10) return 'Must be 10 digits';
                if (existingUser != null)
                  return 'Contact number already exists';
                return null;
              },
            ),

            // EXISTING USER WARNING
            if (existingUser != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Employee Already Exists',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Name: ${existingUser!['name'] ?? 'N/A'}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              if (existingUser!['email'] != null)
                                Text(
                                  'Email: ${existingUser!['email']}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              Text(
                                'Role: ${existingUser!['role'] ?? 'N/A'}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text(
                              'View',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: const BorderSide(color: Colors.blue),
                              foregroundColor: Colors.blue,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserDetailScreen(
                                    user: existingUser!,
                                    onUpdate: () {},
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text(
                              'Edit',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: const BorderSide(color: Colors.orange),
                              foregroundColor: Colors.orange,
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditUserScreen(user: existingUser!),
                                ),
                              );

                              // If edit was successful, clear the form
                              if (result == true) {
                                Fluttertoast.showToast(
                                  msg: 'Employee updated successfully',
                                );
                                setState(() {
                                  existingUser = null;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delete, size: 16),
                            label: const Text(
                              'Delete',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () =>
                                _confirmDelete(existingUser!['id']),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 15),

            // NAME
            TextFormField(
              controller: _name,
              decoration: _input("Full Name", Icons.person),
            ),

            const SizedBox(height: 15),

            // EMAIL
            TextFormField(
              controller: _email,
              decoration: _input("Email", Icons.email),
              validator: validateEmail,
            ),

            const SizedBox(height: 15),

            // GENDER
            DropdownButtonFormField(
              decoration: _input("Gender", Icons.wc),
              items: const [
                DropdownMenuItem(value: "Male", child: Text("Male")),
                DropdownMenuItem(value: "Female", child: Text("Female")),
                DropdownMenuItem(value: "Other", child: Text("Other")),
              ],
              onChanged: (v) => setState(() => selectedGender = v),
            ),

            const SizedBox(height: 15),

            // DATE OF BIRTH
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

            // MULTI-SELECT LANGUAGES
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
            // ALT PHONE
            TextFormField(
              controller: _altPhone,
              maxLength: 10,
              keyboardType: TextInputType.phone,
              decoration: _input("Alternative Number", Icons.phone_android),
            ),

            const SizedBox(height: 15),

            // AADHAR
            TextFormField(
              controller: _aadhar,
              maxLength: 12,
              keyboardType: TextInputType.number,
              decoration: _input("Aadhar Number", Icons.credit_card),
              validator: validateAadhar,
            ),

            const SizedBox(height: 15),

            // PAN
            TextFormField(
              controller: _pan,
              maxLength: 10,
              decoration: _input(
                "PAN Number (ABCDE1234F)",
                Icons.account_balance,
              ),
              validator: validatePAN,
            ),

            const SizedBox(height: 15),

            // PINCODE WITH LOOKUP
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pincode,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    decoration: _input("Pincode", Icons.pin_drop),
                    validator: validatePincode,
                    enabled: !manualAddress,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: fetchingPincode || manualAddress
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

            const SizedBox(height: 8),

            // MANUAL ADDRESS TOGGLE
            // CheckboxListTile(
            //   title: const Text("Enter address manually"),
            //   value: manualAddress,
            //   onChanged: (v) {
            //     setState(() {
            //       manualAddress = v ?? false;
            //       if (!manualAddress) {
            //         _country.clear();
            //         _district.clear();
            //         _city.clear();
            //         _state.clear();
            //       }
            //     });
            //   },
            //   controlAffinity: ListTileControlAffinity.leading,
            //   contentPadding: EdgeInsets.zero,
            // ),
            const SizedBox(height: 15),

            // COUNTRY
            TextFormField(
              controller: _country,
              decoration: _input("Country", Icons.public),
              enabled: manualAddress,
            ),

            const SizedBox(height: 15),

            // STATE
            TextFormField(
              controller: _state,
              decoration: _input("State", Icons.map),
              enabled: manualAddress,
            ),

            const SizedBox(height: 15),

            // DISTRICT
            TextFormField(
              controller: _district,
              decoration: _input("District", Icons.location_on),
              enabled: manualAddress,
            ),

            const SizedBox(height: 15),

            // CITY
            TextFormField(
              controller: _city,
              decoration: _input("City", Icons.location_city),
              enabled: manualAddress,
            ),

            const SizedBox(height: 15),

            // AREA DROPDOWN (if areas available)
            if (_availableAreas.isNotEmpty)
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedArea,
                    decoration: _input("Area *", Icons.place),
                    items: _availableAreas
                        .map(
                          (area) => DropdownMenuItem<String>(
                            value: area['name'],
                            child: Text(area['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedArea = v),
                    validator: (v) =>
                        v == null ? 'Please select an area' : null,
                  ),
                  const SizedBox(height: 15),
                ],
              )
            else if (isLoadingAreas)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_pincode.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  'No areas found for this pincode',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),

            // ADDRESS
            TextFormField(
              controller: _address,
              maxLines: 2,
              decoration: _input("Address", Icons.home),
            ),

            const SizedBox(height: 25),

            // GEOLOCATION SECTION
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
                        const Icon(Icons.my_location, color: Color(0xFFD7BE69)),
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
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                              icon: const Icon(Icons.close, color: Colors.red),
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
                                    position: LatLng(_latitude!, _longitude!),
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
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _openInGoogleMaps,
                                      borderRadius: BorderRadius.circular(8),
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
                                                fontWeight: FontWeight.w500,
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

            const SizedBox(height: 15),

            // DEPARTMENT
            DropdownButtonFormField(
              decoration: _input("Department", Icons.business),
              items: departments
                  .map(
                    (d) => DropdownMenuItem(
                      value: d["id"],
                      child: Text(d["name"]),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedDepartmentId = v as String?;
                });
              },
            ),

            const SizedBox(height: 15),

            // PRIMARY ROLE
            DropdownButtonFormField(
              decoration: _input("Primary Role", Icons.badge),
              items: roles
                  .map(
                    (r) => DropdownMenuItem(
                      value: r["id"],
                      child: Text(r["name"]),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedRoleId = v as String?;
                });
              },
            ),

            const SizedBox(height: 15),

            // MULTI SELECT DROPDOWN
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

            // STATUS
            SwitchListTile(
              title: const Text("Status"),
              subtitle: Text(isActive ? "Active" : "Inactive"),
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
            ),

            const SizedBox(height: 15),

            // PASSWORD
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _password,
                    obscureText: true,
                    enabled: !autoGeneratePassword,
                    decoration: _input("Password", Icons.lock),
                  ),
                ),
                Column(
                  children: [
                    const Text("Auto"),
                    Checkbox(
                      value: autoGeneratePassword,
                      onChanged: (v) {
                        setState(() {
                          autoGeneratePassword = v ?? false;
                          if (autoGeneratePassword) _password.clear();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 15),

            const SizedBox(height: 15),

            // SALARY
            TextFormField(
              controller: _salary,
              keyboardType: TextInputType.number,
              decoration: _input("Salary Per Month *", Icons.currency_rupee),
              validator: (v) {
                if (v == null || v.isEmpty) return "Required";
                return double.tryParse(v) == null ? "Invalid amount" : null;
              },
            ),

            const SizedBox(height: 15),

            // NOTES
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: _input("Notes", Icons.note),
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
                                : null,
                            child: _profileImage == null
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
                                  backgroundColor: const Color(0xFFD7BE69),
                                ),
                              ),
                              if (_profileImage != null) ...[
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

            // SUBMIT BUTTON
            ElevatedButton(
              onPressed: isLoading ? null : createUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD7BE69),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Create Employee"),
            ),
          ],
        ),
      ),
    );
  }

  // --------------- Input Decoration ----------------
  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
