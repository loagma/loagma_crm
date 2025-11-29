import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/account_model.dart';
import '../../services/account_service.dart';
import '../../services/pincode_service.dart';
import '../../services/user_service.dart';

class AccountDetailScreen extends StatefulWidget {
  // This screen is used by route: /account/:id
  final String accountId;

  const AccountDetailScreen({super.key, required this.accountId});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isEditing = false;
  bool _isCheckingOwnership = true;

  Account? _account;

  // Controllers
  final _businessNameController = TextEditingController();
  final _personNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _panCardController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  // Dropdown values
  String? _selectedBusinessType;
  String? _selectedBusinessSize;
  String? _selectedArea;
  String? _selectedCustomerStage;
  String? _selectedFunnelStage;
  DateTime? _dateOfBirth;
  bool _isActive = true;

  // Geolocation
  double? _latitude;
  double? _longitude;
  bool _isLoadingGeolocation = false;
  bool _isLookingUpPincode = false;

  // Images
  String? _ownerImageBase64;
  String? _shopImageBase64;
  File? _ownerImageFile;
  File? _shopImageFile;

  // Areas list
  List<Map<String, dynamic>> _availableAreas = [];

  // Options (you had these in the original)
  final List<String> _businessTypes = [
    'Kirana Store',
    'Sweet Shop',
    'Restaurant',
    'Bakery',
    'Caterer',
    'Hostel',
    'Hotel',
    'Cafe',
    'Other',
  ];
  final List<String> _businessSizes = [
    'Semi Retailer',
    'Retailer',
    'Semi Wholesaler',
    'Wholesaler',
    'Home Buyer',
  ];
  final List<String> _customerStages = [
    'Lead',
    'Prospect',
    'Customer',
    'Inactive',
  ];
  final List<String> _funnelStages = [
    'Awareness',
    'Interest',
    'Consideration',
    'Intent',
    'Evaluation',
    'Converted',
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _personNameController.dispose();
    _contactNumberController.dispose();
    _gstNumberController.dispose();
    _panCardController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // --------------------------
  //  Load account and enforce ownership rules
  // --------------------------
  Future<void> _loadAccount() async {
    setState(() {
      _isLoading = true;
      _isCheckingOwnership = true;
    });

    try {
      final account = await AccountService.fetchAccountById(widget.accountId);

      if (!mounted) return;

      // ownership check:
      final currentRole = UserService.currentRole;
      final currentUserId = UserService.currentUserId;

      final isAdmin =
          (currentRole != null && currentRole.toLowerCase() == 'admin');
      final isOwner =
          account.createdBy != null && account.createdBy == currentUserId;

      // If not admin AND not owner => unauthorized
      if (!isAdmin && !isOwner) {
        setState(() {
          _isLoading = false;
          _isCheckingOwnership = false;
          _account = account; // still store for debug, but mark unauthorized
        });
        return;
      }

      // populate form fields
      _populateFromAccount(account);

      // Debug: Print image URLs
      if (kDebugMode) {
        print('🖼️ Owner Image: ${account.ownerImage}');
        print('🖼️ Shop Image: ${account.shopImage}');
      }

      setState(() {
        _account = account;
        _isLoading = false;
        _isCheckingOwnership = false;
      });

      // If pincode exists, lookup areas
      if (account.pincode != null && account.pincode!.isNotEmpty) {
        _lookupPincode();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Failed to load account: $e');
    }
  }

  void _populateFromAccount(Account account) {
    _businessNameController.text = account.businessName ?? '';
    _personNameController.text = account.personName;
    _contactNumberController.text = account.contactNumber;
    _selectedBusinessType = account.businessType;
    _selectedBusinessSize = account.businessSize;
    _gstNumberController.text = account.gstNumber ?? '';
    _panCardController.text = account.panCard ?? '';
    _selectedCustomerStage = account.customerStage;
    _selectedFunnelStage = account.funnelStage;
    _dateOfBirth = account.dateOfBirth;
    _isActive = account.isActive ?? true;
    _pincodeController.text = account.pincode ?? '';
    _countryController.text = account.country ?? '';
    _stateController.text = account.state ?? '';
    _districtController.text = account.district ?? '';
    _cityController.text = account.city ?? '';
    _selectedArea = account.area;
    _addressController.text = account.address ?? '';
    _latitude = account.latitude;
    _longitude = account.longitude;
    _ownerImageBase64 = account.ownerImage;
    _shopImageBase64 = account.shopImage;
  }

  // --------------------------
  // Image picker (owner/shop)
  // --------------------------
  Future<void> _pickImage(bool isOwnerImage) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 75,
      );

      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);

      if (!mounted) return;
      setState(() {
        if (isOwnerImage) {
          if (!kIsWeb) _ownerImageFile = File(picked.path);
          _ownerImageBase64 = 'data:image/jpeg;base64,$base64Image';
        } else {
          if (!kIsWeb) _shopImageFile = File(picked.path);
          _shopImageBase64 = 'data:image/jpeg;base64,$base64Image';
        }
      });

      _showSuccess(
        isOwnerImage ? 'Owner image selected' : 'Shop image selected',
      );
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  // --------------------------
  // Geolocation
  // --------------------------
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingGeolocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      _showSuccess(
        'Location captured: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
      );
    } catch (e) {
      _showError('Failed to get location: $e');
    } finally {
      if (mounted) setState(() => _isLoadingGeolocation = false);
    }
  }

  // --------------------------
  // Pincode lookup
  // --------------------------
  Future<void> _lookupPincode() async {
    final pincode = _pincodeController.text.trim();
    if (pincode.isEmpty || !PincodeService.isValidPincode(pincode)) {
      _showError('Enter a valid 6-digit pincode');
      return;
    }

    setState(() {
      _isLookingUpPincode = true;
    });

    try {
      final result = await PincodeService.getAreasByPincode(pincode);

      if (!mounted) return;
      if (result['success'] == true) {
        final data = result['data'];
        _countryController.text = data['country'] ?? '';
        _stateController.text = data['state'] ?? '';
        _districtController.text = data['district'] ?? '';
        _cityController.text = data['city'] ?? '';
        _availableAreas = List<Map<String, dynamic>>.from(data['areas'] ?? []);
        if (_selectedArea != null &&
            !_availableAreas.any((a) => a['name'] == _selectedArea)) {
          _selectedArea = null;
        }
        _showSuccess('Location fetched');
      } else {
        _availableAreas = [];
        _selectedArea = null;
        _showError(result['message'] ?? 'Failed to fetch location');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLookingUpPincode = false);
    }
  }

  // --------------------------
  // Update account
  // --------------------------
  Future<void> _updateAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final updates = {
      'businessName': _businessNameController.text.trim().isEmpty
          ? null
          : _businessNameController.text.trim(),
      'personName': _personNameController.text.trim(),
      'contactNumber': _contactNumberController.text.trim(),
      'businessType': _selectedBusinessType,
      'businessSize': _selectedBusinessSize,
      if (_dateOfBirth != null) 'dateOfBirth': _dateOfBirth!.toIso8601String(),
      'customerStage': _selectedCustomerStage,
      'funnelStage': _selectedFunnelStage,
      'gstNumber': _gstNumberController.text.trim().isEmpty
          ? null
          : _gstNumberController.text.trim().toUpperCase(),
      'panCard': _panCardController.text.trim().isEmpty
          ? null
          : _panCardController.text.trim().toUpperCase(),
      'ownerImage': _ownerImageBase64,
      'shopImage': _shopImageBase64,
      'isActive': _isActive,
      'pincode': _pincodeController.text.trim().isEmpty
          ? null
          : _pincodeController.text.trim(),
      'country': _countryController.text.trim().isEmpty
          ? null
          : _countryController.text.trim(),
      'state': _stateController.text.trim().isEmpty
          ? null
          : _stateController.text.trim(),
      'district': _districtController.text.trim().isEmpty
          ? null
          : _districtController.text.trim(),
      'city': _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      'area': _selectedArea,
      'address': _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
    };

    try {
      await AccountService.updateAccount(widget.accountId, updates);
      if (!mounted) return;
      _showSuccess('Account updated successfully');
      setState(() => _isEditing = false);
      await _loadAccount();
    } catch (e) {
      _showError('Failed to update account: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --------------------------
  // UI Helpers
  // --------------------------
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // --------------------------
  // Logout helper (resets to login)
  // --------------------------
  void _logout() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              UserService.logout();
              Navigator.pop(c);
              context.go('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // --------------------------
  // Build
  // --------------------------
  @override
  Widget build(BuildContext context) {
    // Show loading skeleton
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If ownership check is done and user is NOT authorized (non-admin & not owner)
    final currentRole = UserService.currentRole?.toLowerCase();
    final currentUserId = UserService.currentUserId;
    final isAdmin = currentRole == 'admin';
    final isOwner =
        _account?.createdBy != null && _account!.createdBy == currentUserId;

    if (!_isCheckingOwnership && !isAdmin && !isOwner) {
      // show 403 unauthorized
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account Details'),
          backgroundColor: const Color(0xFFD7BE69),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 72, color: Colors.orange),
                const SizedBox(height: 12),
                const Text(
                  'Access Denied',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You are not authorized to view this account.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go(
                    '/dashboard/${UserService.currentRole ?? 'dashboard'}',
                  ),
                  child: const Text('Back to Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD7BE69),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Normal authorized view
    return Scaffold(
      appBar: AppBar(
        title: Text(_account?.personName ?? 'Account Details'),
        backgroundColor: const Color(0xFFD7BE69),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isEditing ? _buildEditForm() : _buildViewMode(),
    );
  }

  // --------------------------
  // View mode UI
  // --------------------------
  Widget _buildViewMode() {
    if (_account == null) {
      return const Center(child: Text('Account not found'));
    }

    final acc = _account!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Images Section
                  if (acc.ownerImage != null || acc.shopImage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (acc.ownerImage != null)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showImageDialog(
                                  acc.ownerImage!,
                                  'Owner Image',
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFD7BE69),
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child:
                                            acc.ownerImage!.startsWith('http')
                                            ? Image.network(
                                                acc.ownerImage!,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Container(
                                                        color: const Color(
                                                          0xFFD7BE69,
                                                        ),
                                                        child: const Icon(
                                                          Icons.person,
                                                          size: 50,
                                                          color: Colors.white,
                                                        ),
                                                      );
                                                    },
                                                loadingBuilder:
                                                    (
                                                      context,
                                                      child,
                                                      loadingProgress,
                                                    ) {
                                                      if (loadingProgress ==
                                                          null)
                                                        return child;
                                                      return const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      );
                                                    },
                                              )
                                            : Container(
                                                color: const Color(0xFFD7BE69),
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 50,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Owner Photo',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Tap to view',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (acc.shopImage != null)
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showImageDialog(
                                  acc.shopImage!,
                                  'Shop Image',
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFD7BE69),
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: acc.shopImage!.startsWith('http')
                                            ? Image.network(
                                                acc.shopImage!,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Container(
                                                        color: const Color(
                                                          0xFFD7BE69,
                                                        ),
                                                        child: const Icon(
                                                          Icons.store,
                                                          size: 50,
                                                          color: Colors.white,
                                                        ),
                                                      );
                                                    },
                                                loadingBuilder:
                                                    (
                                                      context,
                                                      child,
                                                      loadingProgress,
                                                    ) {
                                                      if (loadingProgress ==
                                                          null)
                                                        return child;
                                                      return const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      );
                                                    },
                                              )
                                            : Container(
                                                color: const Color(0xFFD7BE69),
                                                child: const Icon(
                                                  Icons.store,
                                                  size: 50,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Shop Photo',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Tap to view',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  Text(
                    acc.personName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (acc.businessName != null)
                    Text(
                      acc.businessName!,
                      style: const TextStyle(fontSize: 18),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    acc.accountCode ?? '',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Chip(
                        label: Text(acc.isApproved ? 'Approved' : 'Pending'),
                        backgroundColor: acc.isApproved
                            ? Colors.green[100]
                            : Colors.orange[100],
                      ),
                      const SizedBox(width: 10),
                      Chip(
                        label: Text(acc.isActive! ? 'Active' : 'Inactive'),
                        backgroundColor: acc.isActive!
                            ? Colors.blue[100]
                            : Colors.red[100],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _infoCardSection(acc),
          if (acc.pincode != null ||
              acc.address != null ||
              acc.latitude != null) ...[
            const SizedBox(height: 20),
            _locationCard(acc),
          ],
        ],
      ),
    );
  }

  Widget _infoCardSection(Account acc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildDetailRow('Contact', acc.contactNumber),
            if (acc.businessType != null)
              _buildDetailRow('Business Type', acc.businessType!),
            if (acc.businessSize != null)
              _buildDetailRow('Business Size', acc.businessSize!),
            if (acc.gstNumber != null) _buildDetailRow('GST', acc.gstNumber!),
            if (acc.panCard != null) _buildDetailRow('PAN', acc.panCard!),
            if (acc.customerStage != null)
              _buildDetailRow('Customer Stage', acc.customerStage!),
            if (acc.funnelStage != null)
              _buildDetailRow('Funnel Stage', acc.funnelStage!),
          ],
        ),
      ),
    );
  }

  Widget _locationCard(Account acc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (acc.pincode != null) _buildDetailRow('Pincode', acc.pincode!),
            if (acc.area != null) _buildDetailRow('Area', acc.area!),
            if (acc.city != null) _buildDetailRow('City', acc.city!),
            if (acc.district != null)
              _buildDetailRow('District', acc.district!),
            if (acc.state != null) _buildDetailRow('State', acc.state!),
            if (acc.country != null) _buildDetailRow('Country', acc.country!),
            if (acc.address != null) _buildDetailRow('Address', acc.address!),

            // Google Map Display
            if (acc.latitude != null && acc.longitude != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
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
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Lat: ${acc.latitude!.toStringAsFixed(6)}, Lng: ${acc.longitude!.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD7BE69), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(acc.latitude!, acc.longitude!),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('account_location'),
                            position: LatLng(acc.latitude!, acc.longitude!),
                            infoWindow: InfoWindow(
                              title: acc.personName,
                              snippet: acc.businessName,
                            ),
                          ),
                        },
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        onTap: (_) =>
                            _openInGoogleMaps(acc.latitude!, acc.longitude!),
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
                              onTap: () => _openInGoogleMaps(
                                acc.latitude!,
                                acc.longitude!,
                              ),
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
    );
  }

  Future<void> _openInGoogleMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Could not open Google Maps');
      }
    } catch (e) {
      _showError('Error opening Google Maps: $e');
    }
  }

  void _showImageDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.startsWith('http')
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.error_outline,
                                    size: 50,
                                    color: Colors.red,
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------
  // Edit form UI (refactored)
  // --------------------------
  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              'Edit Account',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Business Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _personNameController,
              decoration: const InputDecoration(
                labelText: 'Person Name *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactNumberController,
              decoration: const InputDecoration(
                labelText: 'Contact Number *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              maxLength: 10,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length != 10) return 'Must be 10 digits';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedBusinessType,
              decoration: const InputDecoration(
                labelText: 'Business Type',
                border: OutlineInputBorder(),
              ),
              items: _businessTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedBusinessType = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedBusinessSize,
              decoration: const InputDecoration(
                labelText: 'Business Size',
                border: OutlineInputBorder(),
              ),
              items: _businessSizes
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedBusinessSize = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gstNumberController,
              decoration: const InputDecoration(
                labelText: 'GST Number',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _panCardController,
              decoration: const InputDecoration(
                labelText: 'PAN Card',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 10,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _pincodeController,
                    decoration: const InputDecoration(
                      labelText: 'Pincode',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLookingUpPincode ? null : _lookupPincode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD7BE69),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLookingUpPincode
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Lookup'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_availableAreas.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _selectedArea,
                decoration: const InputDecoration(
                  labelText: 'Area',
                  border: OutlineInputBorder(),
                ),
                items: _availableAreas
                    .map(
                      (a) => DropdownMenuItem(
                        value: a['name'] as String,
                        child: Text(a['name']),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedArea = v),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: _isLoadingGeolocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                _isLoadingGeolocation
                    ? 'Getting Location...'
                    : 'Capture Location',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD7BE69),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _isLoadingGeolocation ? null : _getCurrentLocation,
            ),
            if (_latitude != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Location: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Active Status'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSubmitting ? 'Saving...' : 'Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7BE69),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _isSubmitting ? null : _updateAccount,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    onPressed: () {
                      setState(() => _isEditing = false);
                      _loadAccount();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
