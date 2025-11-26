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
import '../../services/api_config.dart';
import 'user_detail_screen.dart';

// ⬇️ Add multi-select helper widget ABOVE this class
// (already given above)

class AdminCreateUserScreen extends StatefulWidget {
  const AdminCreateUserScreen({super.key});

  @override
  State<AdminCreateUserScreen> createState() => _AdminCreateUserScreenState();
}

class _AdminCreateUserScreenState extends State<AdminCreateUserScreen> {
  final _formKey = GlobalKey<FormState>();

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

  // ---------------- Dropdown Selections ----------------
  String? selectedRoleId;
  String? selectedDepartmentId;
  String? selectedGender;
  String? selectedLanguage;
  bool isActive = true;
  bool autoGeneratePassword = false;
  bool manualAddress = false;
  bool fetchingPincode = false;

  List<String> selectedRoles = []; // MULTI SELECT

  // ---------------- Data from API ----------------
  List<Map<String, dynamic>> roles = [];
  List<Map<String, dynamic>> departments = [];

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
          roles = List<Map<String, dynamic>>.from(data["roles"]);
        });
      }
    } catch (_) {}
  }

  Future<void> fetchDepartments() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/departments"),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          departments = List<Map<String, dynamic>>.from(data["departments"]);
        });
      }
    } catch (_) {}
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
    if (phone.length != 10) return;

    setState(() {
      checkingPhone = true;
      existingUser = null;
    });

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/admin/users?contactNumber=$phone"),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true && data["users"] != null) {
          final users = List<Map<String, dynamic>>.from(data["users"]);
          if (users.isNotEmpty) {
            setState(() => existingUser = users[0]);
            _showExistingUserDialog();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print("Error checking user: $e");
    }

    setState(() => checkingPhone = false);
  }

  void _showExistingUserDialog() {
    if (existingUser == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            const Text("Employee Already Exists"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFD7BE69),
                  backgroundImage: existingUser!['image'] != null
                      ? NetworkImage(existingUser!['image'])
                      : null,
                  child: existingUser!['image'] == null
                      ? Text(
                          (existingUser!['name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              _detailRow("Name", existingUser!['name'] ?? 'N/A'),
              _detailRow("Phone", existingUser!['contactNumber'] ?? 'N/A'),
              _detailRow("Email", existingUser!['email'] ?? 'N/A'),
              _detailRow("Role", existingUser!['role'] ?? 'N/A'),
              _detailRow("Department", existingUser!['department'] ?? 'N/A'),
              _detailRow(
                "Status",
                existingUser!['isActive'] == true ? 'Active' : 'Inactive',
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.visibility),
            label: const Text("View"),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      UserDetailScreen(user: existingUser!, onUpdate: () {}),
                ),
              );
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text("Edit"),
            onPressed: () {
              Navigator.pop(context);
              // Navigate to edit screen
              Navigator.pushNamed(
                context,
                '/admin/edit-user',
                arguments: existingUser,
              );
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(existingUser!['id']);
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
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

    setState(() => fetchingPincode = true);

    try {
      final response = await http.get(
        Uri.parse("https://api.postalpincode.in/pincode/$pincode"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data[0]["Status"] == "Success") {
          final postOffice = data[0]["PostOffice"][0];
          setState(() {
            _city.text = postOffice["District"] ?? "";
            _state.text = postOffice["State"] ?? "";
            _country.text = postOffice["Country"] ?? "India";
            _district.text = postOffice["District"] ?? "";
          });
          Fluttertoast.showToast(msg: "Location fetched successfully");
        } else {
          Fluttertoast.showToast(msg: "Invalid pincode");
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching location: $e");
    }

    setState(() => fetchingPincode = false);
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

  Future<String?> uploadImageToCloudinary(File imageFile) async {
    setState(() => isUploadingImage = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dfncqhkl9/image/upload'),
      );

      request.fields['upload_preset'] = 'ml_default';
      request.fields['api_key'] = '652667859422493';
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonData = jsonDecode(responseString);

      if (response.statusCode == 200) {
        setState(() => isUploadingImage = false);
        return jsonData['secure_url'];
      } else {
        Fluttertoast.showToast(msg: "Image upload failed");
        setState(() => isUploadingImage = false);
        return null;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error uploading image: $e");
      setState(() => isUploadingImage = false);
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

    setState(() => isLoading = true);

    // Upload image first if selected
    if (_profileImage != null) {
      _uploadedImageUrl = await uploadImageToCloudinary(_profileImage!);
      if (_uploadedImageUrl == null) {
        setState(() => isLoading = false);
        Fluttertoast.showToast(msg: "Failed to upload image");
        return;
      }
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
      if (selectedLanguage != null) "preferredLanguages": [selectedLanguage],

      "isActive": isActive,

      if (password.isNotEmpty) "password": password,
      if (_address.text.isNotEmpty) "address": _address.text.trim(),
      if (_city.text.isNotEmpty) "city": _city.text.trim(),
      if (_state.text.isNotEmpty) "state": _state.text.trim(),
      if (_pincode.text.isNotEmpty) "pincode": _pincode.text.trim(),
      if (_country.text.isNotEmpty) "country": _country.text.trim(),
      if (_district.text.isNotEmpty) "district": _district.text.trim(),
      if (_aadhar.text.isNotEmpty) "aadharCard": _aadhar.text.trim(),
      if (_pan.text.isNotEmpty) "panCard": _pan.text.trim().toUpperCase(),
      if (_notes.text.isNotEmpty) "notes": _notes.text.trim(),
      if (_uploadedImageUrl != null) "image": _uploadedImageUrl,
    };

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/admin/users"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

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
          selectedRoleId = null;
          selectedDepartmentId = null;
          selectedGender = null;
          selectedLanguage = null;
          _profileImage = null;
          _uploadedImageUrl = null;
          existingUser = null;
        });
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
          padding: const EdgeInsets.all(20),
          children: [
            // PHONE WITH CHECK
            TextFormField(
              controller: _phone,
              maxLength: 10,
              keyboardType: TextInputType.phone,
              decoration: _input("Contact Number *", Icons.phone).copyWith(
                suffixIcon: checkingPhone
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              validator: validatePhone,
              onChanged: (value) {
                if (value.length == 10) {
                  checkExistingUser(value);
                }
              },
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

            // LANGUAGE
            DropdownButtonFormField(
              decoration: _input("Preferred Language", Icons.language),
              items: const [
                DropdownMenuItem(value: "English", child: Text("English")),
                DropdownMenuItem(value: "Hindi", child: Text("Hindi")),
                DropdownMenuItem(value: "Marathi", child: Text("Marathi")),
                DropdownMenuItem(value: "Gujarati", child: Text("Gujarati")),
              ],
              onChanged: (v) => setState(() => selectedLanguage = v),
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
            CheckboxListTile(
              title: const Text("Enter address manually"),
              value: manualAddress,
              onChanged: (v) {
                setState(() {
                  manualAddress = v ?? false;
                  if (!manualAddress) {
                    _country.clear();
                    _district.clear();
                    _city.clear();
                    _state.clear();
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

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

            // ADDRESS
            TextFormField(
              controller: _address,
              maxLines: 2,
              decoration: _input("Address", Icons.home),
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
