import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_config.dart';
import '../../services/auth_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, this.account});

  final Map<String, dynamic>? account;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  static const Color _primary = Color(0xFFD7BE69);
  String? _expandedSection;
  String? _selectedFunnelStage;
  final List<XFile> _capturedImages = [];
  final TextEditingController _notesController = TextEditingController();
  String? _mistakeRelatedTo;
  bool _isVisitedIn = false;
  bool _isLoading = false;
  int? _activeTransactionId;
  DateTime? _visitInTime;
  Duration _visitDuration = Duration.zero;
  bool _isTimerRunning = false;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingTransactions = false;

  static const List<String> _funnelStages = [
    'Placed order',
    'Next week',
    'Shop closed',
    'Not interested',
    'New customer',
    'Not buying',
    'Negotiation',
    'Interested',
  ];

  static const List<String> _mistakeOptions = [
    'Customer',
    'Salesman',
    'Product',
    'Delivery',
    'Payment',
    'Other',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    _stopTimer();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkActiveVisit();
  }

  void _startTimer() {
    setState(() {
      _isTimerRunning = true;
      _visitDuration = Duration.zero;
    });
    _updateTimer();
  }

  void _updateTimer() {
    if (_isTimerRunning && _visitInTime != null) {
      Future.delayed(const Duration(seconds: 1), () {
        if (_isTimerRunning && mounted) {
          setState(() {
            _visitDuration = DateTime.now().difference(_visitInTime!);
          });
          _updateTimer();
        }
      });
    }
  }

  void _stopTimer() {
    setState(() {
      _isTimerRunning = false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTransactionRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkActiveVisit() async {
    final account = widget.account;
    if (account == null) return;

    final accountId =
        account['id']?.toString() ?? account['accountCode']?.toString();

    // Get salesman ID from auth service
    final salesmanId = await AuthService.getUserId();
    if (salesmanId == null) {
      print('No salesman ID found in auth service');
      return;
    }

    if (accountId == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/transaction-crm/active-visit/$accountId/$salesmanId',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['hasActiveVisit'] == true) {
          setState(() {
            _isVisitedIn = true;
            _activeTransactionId = data['activeVisit']['id'];
            _visitInTime = DateTime.parse(data['activeVisit']['visitInTime']);
          });
          _startTimer(); // Start timer for existing visit
        }
      }
    } catch (e) {
      print('Error checking active visit: $e');
    }

    // Load transactions
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final account = widget.account;
    if (account == null) {
      print('❌ Cannot load transactions: account is null');
      return;
    }

    final accountId =
        account['id']?.toString() ?? account['accountCode']?.toString();
    if (accountId == null) {
      print('❌ Cannot load transactions: accountId is null');
      return;
    }

    print('📊 Loading transactions for account: $accountId');
    setState(() => _isLoadingTransactions = true);

    try {
      final url = '${ApiConfig.baseUrl}/transaction-crm/history/$accountId';
      print('🌐 Fetching from: $url');

      final response = await http.get(Uri.parse(url));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Decoded data: $data');

        if (data['success'] == true) {
          final transactionsList = List<Map<String, dynamic>>.from(
            data['transactions'].map((t) => Map<String, dynamic>.from(t)),
          );

          print('✅ Loaded ${transactionsList.length} transactions');

          setState(() {
            _transactions = transactionsList;
          });

          print('✅ State updated with transactions');
        } else {
          print('⚠️ Success is false: ${data['message']}');
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading transactions: $e');
      print('Stack trace: $stackTrace');
    } finally {
      setState(() => _isLoadingTransactions = false);
      print('✅ Loading complete. Transactions count: ${_transactions.length}');
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Location services are disabled. Please enable them in Settings.',
              ),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission denied. Please grant permission to use this feature.',
                ),
                duration: Duration(seconds: 5),
              ),
            );
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Location permission permanently denied. Please enable in Settings.',
              ),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return null;
      }

      // Get location with timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Location request timed out. Please try again.');
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _handleVisitIn() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Visit In'),
        content: const Text('Are you sure you want to start this visit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: const Text('Yes, Start Visit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final account = widget.account;
      if (account == null) {
        throw Exception('Account data not available');
      }

      final accountId =
          account['id']?.toString() ?? account['accountCode']?.toString();
      final accountLat = account['latitude'];
      final accountLng = account['longitude'];

      if (accountId == null) {
        throw Exception('Account ID not available');
      }

      if (accountLat == null || accountLng == null) {
        throw Exception('Account location not available');
      }

      // Get current location
      final position = await _getCurrentLocation();
      if (position == null) {
        throw Exception('Could not get current location');
      }

      // Get salesman ID from auth service
      final salesmanId = await AuthService.getUserId();
      if (salesmanId == null) {
        throw Exception('User not logged in');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/transaction-crm/visit-in'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'accountId': accountId,
          'salesmanId': salesmanId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accountLatitude': accountLat,
          'accountLongitude': accountLng,
          'beatNo': 1,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _isVisitedIn = true;
          _activeTransactionId = data['transaction']['id'];
          _visitInTime = DateTime.now();
        });
        _startTimer(); // Start timer

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '✓ Visit In successful! Distance: ${data['distance']}m',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to record Visit In');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e.toString().replaceAll('Exception: ', '')),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVisitOut() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Visit Out'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to end this visit?'),
            const SizedBox(height: 12),
            if (_selectedFunnelStage != null)
              Text(
                '✓ Order Funnel: $_selectedFunnelStage',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (_capturedImages.isNotEmpty)
              Text(
                '✓ Merchandise: ${_capturedImages.length} images',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (_notesController.text.isNotEmpty)
              Text(
                '✓ Notes: ${_notesController.text.length} characters',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: const Text('Yes, End Visit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final account = widget.account;
      if (account == null) {
        throw Exception('Account data not available');
      }

      final accountId =
          account['id']?.toString() ?? account['accountCode']?.toString();
      final accountLat = account['latitude'];
      final accountLng = account['longitude'];

      if (accountId == null) {
        throw Exception('Account ID not available');
      }

      if (accountLat == null || accountLng == null) {
        throw Exception('Account location not available');
      }

      // Get current location
      final position = await _getCurrentLocation();
      if (position == null) {
        throw Exception('Could not get current location');
      }

      // Get salesman ID from auth service
      final salesmanId = await AuthService.getUserId();
      if (salesmanId == null) {
        throw Exception('User not logged in');
      }

      // Upload images if any
      String? image1Url;
      String? image2Url;
      if (_capturedImages.isNotEmpty) {
        image1Url = await _uploadImage(_capturedImages[0]);
      }
      if (_capturedImages.length > 1) {
        image2Url = await _uploadImage(_capturedImages[1]);
      }

      print('=== Visit Out Request ===');
      print('Account ID: $accountId');
      print('Salesman ID: $salesmanId');
      print('Order Funnel: $_selectedFunnelStage');
      print('Notes: ${_notesController.text}');
      print('Notes Related To: $_mistakeRelatedTo');
      print('Images: ${_capturedImages.length}');

      final requestBody = {
        'accountId': accountId,
        'salesmanId': salesmanId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accountLatitude': accountLat,
        'accountLongitude': accountLng,
        'orderFunnel': _selectedFunnelStage,
        'notes': _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
        'notesRelatedTo': _mistakeRelatedTo,
        'merchandiseImage1': image1Url,
        'merchandiseImage2': image2Url,
      };

      print('Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/transaction-crm/visit-out'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _stopTimer(); // Stop timer

        setState(() {
          _isVisitedIn = false;
          _activeTransactionId = null;
          _visitInTime = null;
          _visitDuration = Duration.zero;
          _selectedFunnelStage = null;
          _capturedImages.clear();
          _notesController.clear();
          _mistakeRelatedTo = null;
        });

        // Reload transactions
        _loadTransactions();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('✓ Visit Out successful! All data saved.'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to record Visit Out');
      }
    } catch (e) {
      print('Visit Out error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e.toString().replaceAll('Exception: ', '')),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _uploadImage(XFile image) async {
    // TODO: Implement actual image upload to your server
    // For now, return base64 encoded image
    try {
      final bytes = await image.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  String _dayLabel(int day) {
    const labels = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return labels[day] ?? 'Day $day';
  }

  List<int> _assignedDays(Map<String, dynamic> account) {
    final raw = (account['assignedDays'] as List?) ?? const [];
    return raw
        .map((e) => int.tryParse(e.toString()))
        .whereType<int>()
        .where((d) => d >= 1 && d <= 7)
        .toList();
  }

  List<int> _visibleDays(Map<String, dynamic> account) {
    final explicitDay = int.tryParse(
      (account['selectedDay'] ?? account['dayOfWeek'] ?? '').toString(),
    );
    if (explicitDay != null && explicitDay >= 1 && explicitDay <= 7) {
      return [explicitDay];
    }
    return _assignedDays(account);
  }

  String _visitType(Map<String, dynamic> account) {
    final freq = (account['visitFrequency']?.toString() ?? '')
        .trim()
        .toUpperCase();
    final recurrenceType = (account['recurrenceType']?.toString() ?? '')
        .trim()
        .toLowerCase();
    final afterDays = int.tryParse(account['afterDays']?.toString() ?? '');
    final days = _assignedDays(account);

    if (afterDays != null && afterDays > 0) return 'AFTER_DAYS';
    if (recurrenceType.contains('after')) return 'AFTER_DAYS';
    if (freq.isNotEmpty) return freq;
    if (days.isNotEmpty) return 'WEEKLY';
    return 'WEEKLY';
  }

  String _visitTypeLabel(Map<String, dynamic> account) {
    final type = _visitType(account);
    final afterDays = int.tryParse(account['afterDays']?.toString() ?? '');
    if (type == 'AFTER_DAYS') {
      if (afterDays != null && afterDays > 0) return 'AFTER $afterDays DAYS';
      return 'AFTER N DAYS';
    }
    return type.replaceAll('_', ' ');
  }

  Color _visitTypeBg(Map<String, dynamic> account) {
    switch (_visitType(account)) {
      case 'MONTHLY':
        return const Color(0xFFE8F1FF);
      case 'AFTER_DAYS':
        return const Color(0xFFFFEFE0);
      case 'DAILY':
        return const Color(0xFFE7F9EC);
      default:
        return const Color(0xFFE8F8EC);
    }
  }

  Color _visitTypeText(Map<String, dynamic> account) {
    switch (_visitType(account)) {
      case 'MONTHLY':
        return const Color(0xFF215DA8);
      case 'AFTER_DAYS':
        return const Color(0xFFA35A17);
      case 'DAILY':
        return const Color(0xFF1F8B46);
      default:
        return const Color(0xFF1E7A3C);
    }
  }

  Widget _buildVisitTypeChip(Map<String, dynamic> account) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _visitTypeBg(account),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _visitTypeText(account).withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        _visitTypeLabel(account),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _visitTypeText(account),
        ),
      ),
    );
  }

  Widget _buildDayChip(int day) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E5EA)),
      ),
      child: Text(
        _dayLabel(day),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF606873),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    // Remove any non-digit characters
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');

    // If number doesn't start with country code, assume India (+91)
    if (!cleanNumber.startsWith('91') && cleanNumber.length == 10) {
      cleanNumber = '91$cleanNumber';
    }

    // Try WhatsApp URL scheme first (works better on mobile)
    final Uri whatsappUri = Uri.parse('whatsapp://send?phone=$cleanNumber');

    try {
      final bool canLaunch = await canLaunchUrl(whatsappUri);
      if (canLaunch) {
        await launchUrl(whatsappUri);
      } else {
        // Fallback to web WhatsApp
        final Uri webWhatsappUri = Uri.parse('https://wa.me/$cleanNumber');
        await launchUrl(webWhatsappUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _openMap(String address) async {
    final account = widget.account;
    final lat = account?['latitude'];
    final lng = account?['longitude'];

    // If we have coordinates, use them for more accurate navigation
    Uri launchUri;
    if (lat != null && lng != null) {
      // Use geo: URI scheme which opens in Google Maps app
      launchUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    } else {
      // Fallback to address search
      final encodedAddress = Uri.encodeComponent(address);
      launchUri = Uri.parse('geo:0,0?q=$encodedAddress');
    }

    try {
      final bool canLaunch = await canLaunchUrl(launchUri);
      if (canLaunch) {
        await launchUrl(launchUri);
      } else {
        // Fallback to Google Maps web
        final encodedAddress = Uri.encodeComponent(address);
        final webUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
        );
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open maps: ${e.toString()}')),
        );
      }
    }
  }

  void _toggleSection(String section) {
    setState(() {
      _expandedSection = _expandedSection == section ? null : section;
    });
  }

  Future<void> _showMerchandiseDialog() async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Merchandise Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Capture Images (Max 2)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._capturedImages.asMap().entries.map((entry) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(entry.value.path),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              color: Colors.white,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () {
                                setState(() {
                                  _capturedImages.removeAt(entry.key);
                                });
                                setDialogState(() {});
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                    if (_capturedImages.length < 2)
                      InkWell(
                        onTap: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                            source: ImageSource.camera,
                            imageQuality: 75,
                          );
                          if (image != null) {
                            setState(() {
                              _capturedImages.add(image);
                            });
                            setDialogState(() {});
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: const Icon(Icons.add_a_photo, size: 32),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mistake Related To',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _mistakeRelatedTo,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  hint: const Text('Select'),
                  items: _mistakeOptions.map((option) {
                    return DropdownMenuItem(value: option, child: Text(option));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _mistakeRelatedTo = value;
                    });
                    setDialogState(() {});
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Notes',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Enter notes here...',
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '✓ Merchandise saved (${_capturedImages.length} images)',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionButton({required String id, required String label}) {
    final isOpen = _expandedSection == id;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _toggleSection(id),
        style: OutlinedButton.styleFrom(
          backgroundColor: isOpen ? _primary : Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(
            color: isOpen ? const Color(0xFF8A7631) : const Color(0xFFE1E5EA),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildExpandedBody() {
    if (_expandedSection == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E8EE)),
        ),
        child: const Text(
          'Tap any section above to open details.',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (_expandedSection == 'history') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E8EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Order History',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text('No historical orders available for this account yet.'),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            Text(
              'Product Order Summary',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text('Summary placeholders can be replaced with API data.'),
            SizedBox(height: 6),
            Text('Total Items: 0'),
            Text('Total Qty: 0'),
            Text('Total Value: Rs 0'),
          ],
        ),
      );
    }

    if (_expandedSection == 'funnel') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E8EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Funnel',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                if (_selectedFunnelStage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Submitted',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ..._funnelStages.map((stage) {
              return RadioListTile<String>(
                title: Text(
                  stage,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: stage,
                groupValue: _selectedFunnelStage,
                activeColor: _primary,
                contentPadding: EdgeInsets.zero,
                dense: true,
                onChanged: (value) {
                  setState(() {
                    _selectedFunnelStage = value;
                  });
                },
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedFunnelStage == null
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text('✓ Saved: $_selectedFunnelStage'),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_expandedSection == 'transaction') {
      print('🔍 Rendering transaction section');
      print('🔍 Transactions count: ${_transactions.length}');
      print('🔍 Is loading: $_isLoadingTransactions');

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E8EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaction History',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                if (_transactions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_transactions.length} visits',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoadingTransactions)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No transactions available yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final transaction = _transactions[index];
                  final visitIn = transaction['visitInTime'] != null
                      ? DateTime.parse(transaction['visitInTime'])
                      : null;
                  final visitOut = transaction['visitOutTime'] != null
                      ? DateTime.parse(transaction['visitOutTime'])
                      : null;
                  final duration = visitIn != null && visitOut != null
                      ? visitOut.difference(visitIn)
                      : null;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Visit #${transaction['transactionNo']}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (duration != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatDuration(duration),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (visitIn != null)
                          _buildTransactionRow(
                            Icons.login,
                            'Visit In',
                            _formatDateTime(visitIn),
                            Colors.green,
                          ),
                        if (visitOut != null)
                          _buildTransactionRow(
                            Icons.logout,
                            'Visit Out',
                            _formatDateTime(visitOut),
                            Colors.red,
                          ),
                        if (transaction['orderFunnel'] != null)
                          _buildTransactionRow(
                            Icons.filter_list,
                            'Order Funnel',
                            transaction['orderFunnel'],
                            _primary,
                          ),
                        if (transaction['notes'] != null)
                          _buildTransactionRow(
                            Icons.note,
                            'Notes',
                            transaction['notes'],
                            Colors.grey.shade700,
                          ),
                        if (transaction['merchandiseImage1'] != null ||
                            transaction['merchandiseImage2'] != null)
                          _buildTransactionRow(
                            Icons.photo_camera,
                            'Merchandise',
                            '${transaction['merchandiseImage1'] != null ? '1' : '0'} + ${transaction['merchandiseImage2'] != null ? '1' : '0'} images',
                            Colors.purple,
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account ?? const <String, dynamic>{};
    final shopName = (account['businessName']?.toString() ?? 'Order Details')
        .trim();
    final ownerName = (account['personName']?.toString() ?? '-').trim();
    final accountCode = (account['accountCode']?.toString() ?? '-').trim();
    final address = (account['address']?.toString() ?? '-').trim();
    final assignedDays = _visibleDays(account);
    final accountId = (accountCode.isNotEmpty && accountCode != '-')
        ? accountCode
        : (account['id']?.toString() ?? '-').trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: _primary,
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _showMerchandiseDialog,
        backgroundColor: _primary,
        child: const Icon(Icons.add_a_photo, size: 20),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primary.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            accountId,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildVisitTypeChip(account),
                              ...assignedDays.map(_buildDayChip),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          ownerName,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                onPressed: _isLoading || _isVisitedIn
                                    ? null
                                    : _handleVisitIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isVisitedIn
                                      ? Colors.grey
                                      : _primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                child: _isLoading && !_isVisitedIn
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isVisitedIn
                                            ? 'Visited In'
                                            : 'Visit In',
                                      ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              height: 30,
                              child: ElevatedButton(
                                onPressed: _isLoading || !_isVisitedIn
                                    ? null
                                    : _handleVisitOut,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !_isVisitedIn
                                      ? Colors.grey
                                      : _primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                child: _isLoading && _isVisitedIn
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Visit Out'),
                              ),
                            ),
                          ],
                        ),
                        if (_isVisitedIn && _isTimerRunning)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer,
                                    size: 16,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Duration: ${_formatDuration(_visitDuration)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  shopName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Address : ${address.isEmpty ? '-' : address}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        final phone =
                            account['phoneNumber']?.toString() ??
                            account['phone']?.toString() ??
                            account['contactNumber']?.toString() ??
                            '';
                        if (phone.isNotEmpty) {
                          _makePhoneCall(phone);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Phone number not available'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.call, color: Color(0xFF4CAF50)),
                      iconSize: 28,
                      tooltip: 'Call',
                    ),
                    IconButton(
                      onPressed: () {
                        final phone =
                            account['phoneNumber']?.toString() ??
                            account['phone']?.toString() ??
                            account['contactNumber']?.toString() ??
                            '';
                        if (phone.isNotEmpty) {
                          _openWhatsApp(phone);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Phone number not available'),
                            ),
                          );
                        }
                      },
                      icon: const FaIcon(
                        FontAwesomeIcons.whatsapp,
                        color: Color(0xFF25D366),
                      ),
                      iconSize: 28,
                      tooltip: 'WhatsApp',
                    ),
                    IconButton(
                      onPressed: () {
                        if (address.isNotEmpty && address != '-') {
                          _openMap(address);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Address not available'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.map, color: Color(0xFF2196F3)),
                      iconSize: 28,
                      tooltip: 'Open Map',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSectionButton(id: 'history', label: 'Order History'),
              const SizedBox(width: 8),
              _buildSectionButton(id: 'funnel', label: 'Order Funnel'),
              const SizedBox(width: 8),
              _buildSectionButton(id: 'transaction', label: 'Transaction'),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _buildExpandedBody(),
          ),
        ],
      ),
    );
  }
}
