// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../../services/api_config.dart';
// import '../../services/auth_service.dart';

// class OrderDetailsScreen extends StatefulWidget {
//   const OrderDetailsScreen({super.key, this.account});

//   final Map<String, dynamic>? account;

//   @override
//   State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
// }

// class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
//   static const Color _primary = Color(0xFFD7BE69);
//   String? _expandedSection;
//   String? _selectedFunnelStage;
//   final List<XFile> _capturedImages = [];
//   final TextEditingController _notesController = TextEditingController();
//   String? _mistakeRelatedTo;
//   bool _isVisitedIn = false;
//   bool _isLoading = false;
//   int? _activeTransactionId;
//   DateTime? _visitInTime;
//   Duration _visitDuration = Duration.zero;
//   bool _isTimerRunning = false;
//   List<Map<String, dynamic>> _transactions = [];
//   bool _isLoadingTransactions = false;
//   bool _isFunnelUpdated = false;

//   static const List<String> _funnelStages = [
//     'Placed order',
//     'Next week',
//     'Shop closed',
//     'Not interested',
//     'New customer',
//     'Not buying',
//     'Negotiation',
//     'Interested',
//   ];

//   static const List<String> _mistakeOptions = [
//     'Customer',
//     'Salesman',
//     'Product',
//     'Delivery',
//     'Payment',
//     'Other',
//   ];

//   @override
//   void dispose() {
//     _notesController.dispose();
//     _stopTimer();
//     super.dispose();
//   }

//   @override
//   void initState() {
//     super.initState();
//     _checkActiveVisit();
//   }

//   void _startTimer() {
//     setState(() {
//       _isTimerRunning = true;
//       _visitDuration = Duration.zero;
//     });
//     _updateTimer();
//   }

//   void _updateTimer() {
//     if (_isTimerRunning && _visitInTime != null) {
//       Future.delayed(const Duration(seconds: 1), () {
//         if (_isTimerRunning && mounted) {
//           setState(() {
//             _visitDuration = DateTime.now().difference(_visitInTime!);
//           });
//           _updateTimer();
//         }
//       });
//     }
//   }

//   void _stopTimer() {
//     setState(() {
//       _isTimerRunning = false;
//     });
//   }

//   String _formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final hours = twoDigits(duration.inHours);
//     final minutes = twoDigits(duration.inMinutes.remainder(60));
//     final seconds = twoDigits(duration.inSeconds.remainder(60));
//     return '$hours:$minutes:$seconds';
//   }

//   String _formatDateTime(DateTime dateTime) {
//     final hour = dateTime.hour;
//     final period = hour >= 12 ? 'PM' : 'AM';
//     final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
//     return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${hour12}:${dateTime.minute.toString().padLeft(2, '0')} $period';
//   }

//   Widget _buildTransactionRow(
//     IconData icon,
//     String label,
//     String value,
//     Color color,
//   ) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 4),
//       child: Row(
//         children: [
//           Icon(icon, size: 16, color: color),

//           Text(
//             '$label: ',
//             style: const TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey,
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _checkActiveVisit() async {
//     final account = widget.account;
//     if (account == null) return;

//     final accountId =
//         account['id']?.toString() ?? account['accountCode']?.toString();

//     // Get salesman ID from auth service
//     final salesmanId = await AuthService.getUserId();
//     if (salesmanId == null) {
//       print('No salesman ID found in auth service');
//       return;
//     }

//     if (accountId == null) return;

//     try {
//       final response = await http.get(
//         Uri.parse(
//           '${ApiConfig.baseUrl}/transaction-crm/active-visit/$accountId/$salesmanId',
//         ),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['hasActiveVisit'] == true) {
//           setState(() {
//             _isVisitedIn = true;
//             _activeTransactionId = data['activeVisit']['id'];
//             _visitInTime = DateTime.parse(data['activeVisit']['visitInTime']);
//           });
//           _startTimer(); // Start timer for existing visit
//         }
//       }
//     } catch (e) {
//       print('Error checking active visit: $e');
//     }

//     // Load transactions
//     _loadTransactions();
//   }

//   Future<void> _loadTransactions() async {
//     final account = widget.account;
//     if (account == null) {
//       print('❌ Cannot load transactions: account is null');
//       return;
//     }

//     final accountId =
//         account['id']?.toString() ?? account['accountCode']?.toString();
//     if (accountId == null) {
//       print('❌ Cannot load transactions: accountId is null');
//       return;
//     }

//     print('📊 Loading transactions for account: $accountId');
//     setState(() => _isLoadingTransactions = true);

//     try {
//       final url = '${ApiConfig.baseUrl}/transaction-crm/history/$accountId';
//       print('🌐 Fetching from: $url');

//       final response = await http.get(Uri.parse(url));

//       print('📡 Response status: ${response.statusCode}');
//       print('📡 Response body: ${response.body}');

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         print('✅ Decoded data: $data');

//         if (data['success'] == true) {
//           final transactionsList = List<Map<String, dynamic>>.from(
//             data['transactions'].map((t) => Map<String, dynamic>.from(t)),
//           );

//           print('✅ Loaded ${transactionsList.length} transactions');

//           setState(() {
//             _transactions = transactionsList;
//           });

//           print('✅ State updated with transactions');
//         } else {
//           print('⚠️ Success is false: ${data['message']}');
//         }
//       } else {
//         print('❌ HTTP error: ${response.statusCode}');
//       }
//     } catch (e, stackTrace) {
//       print('❌ Error loading transactions: $e');
//       print('Stack trace: $stackTrace');
//     } finally {
//       setState(() => _isLoadingTransactions = false);
//       print('✅ Loading complete. Transactions count: ${_transactions.length}');
//     }
//   }

//   Future<Position?> _getCurrentLocation() async {
//     try {
//       // Check if location services are enabled
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text(
//                 'Location services are disabled. Please enable them in Settings.',
//               ),
//               action: SnackBarAction(
//                 label: 'Settings',
//                 onPressed: () async {
//                   await Geolocator.openLocationSettings();
//                 },
//               ),
//               duration: const Duration(seconds: 5),
//             ),
//           );
//         }
//         return null;
//       }

//       // Check permission
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text(
//                   'Location permission denied. Please grant permission to use this feature.',
//                 ),
//                 duration: Duration(seconds: 5),
//               ),
//             );
//           }
//           return null;
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text(
//                 'Location permission permanently denied. Please enable in Settings.',
//               ),
//               action: SnackBarAction(
//                 label: 'Settings',
//                 onPressed: () async {
//                   await Geolocator.openAppSettings();
//                 },
//               ),
//               duration: const Duration(seconds: 5),
//             ),
//           );
//         }
//         return null;
//       }

//       // Get location with timeout
//       return await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       ).timeout(
//         const Duration(seconds: 10),
//         onTimeout: () {
//           throw Exception('Location request timed out. Please try again.');
//         },
//       );
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error getting location: ${e.toString()}'),
//             duration: const Duration(seconds: 5),
//           ),
//         );
//       }
//       return null;
//     }
//   }

//   Future<void> _handleVisitIn() async {
//     // Show confirmation dialog
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Visit In'),
//         content: const Text('Are you sure you want to start this visit?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(backgroundColor: _primary),
//             child: const Text('Yes, Start Visit'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed != true) return;

//     setState(() => _isLoading = true);

//     try {
//       final account = widget.account;
//       if (account == null) {
//         throw Exception('Account data not available');
//       }

//       final accountId =
//           account['id']?.toString() ?? account['accountCode']?.toString();
//       final accountLat = account['latitude'];
//       final accountLng = account['longitude'];

//       if (accountId == null) {
//         throw Exception('Account ID not available');
//       }

//       if (accountLat == null || accountLng == null) {
//         throw Exception('Account location not available');
//       }

//       // Get current location
//       final position = await _getCurrentLocation();
//       if (position == null) {
//         throw Exception('Could not get current location');
//       }

//       // Get salesman ID from auth service
//       final salesmanId = await AuthService.getUserId();
//       if (salesmanId == null) {
//         throw Exception('User not logged in');
//       }

//       final response = await http.post(
//         Uri.parse('${ApiConfig.baseUrl}/transaction-crm/visit-in'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'accountId': accountId,
//           'salesmanId': salesmanId,
//           'latitude': position.latitude,
//           'longitude': position.longitude,
//           'accountLatitude': accountLat,
//           'accountLongitude': accountLng,
//           'beatNo': 1,
//         }),
//       );

//       final data = json.decode(response.body);

//       if (response.statusCode == 200 && data['success'] == true) {
//         setState(() {
//           _isVisitedIn = true;
//           _activeTransactionId = data['transaction']['id'];
//           _visitInTime = DateTime.now();
//         });
//         _startTimer(); // Start timer

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: [
//                   const Icon(Icons.check_circle, color: Colors.white),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       '✓ Visit In successful! Distance: ${data['distance']}m',
//                     ),
//                   ),
//                 ],
//               ),
//               backgroundColor: Colors.green,
//               duration: const Duration(seconds: 2),
//               behavior: SnackBarBehavior.floating,
//               margin: const EdgeInsets.all(16),
//             ),
//           );
//         }
//       } else {
//         throw Exception(data['message'] ?? 'Failed to record Visit In');
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 const Icon(Icons.error, color: Colors.white),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(e.toString().replaceAll('Exception: ', '')),
//                 ),
//               ],
//             ),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 3),
//             behavior: SnackBarBehavior.floating,
//             margin: const EdgeInsets.all(16),
//           ),
//         );
//       }
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _handleUpdate() async {
//     if (_activeTransactionId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Row(
//             children: [
//               Icon(Icons.error, color: Colors.white),
//               SizedBox(width: 8),
//               Expanded(child: Text('No active visit found')),
//             ],
//           ),
//           backgroundColor: Colors.red,
//           duration: Duration(seconds: 2),
//           behavior: SnackBarBehavior.floating,
//           margin: EdgeInsets.all(16),
//         ),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       // Upload images if any
//       String? image1Url;
//       String? image2Url;
//       if (_capturedImages.isNotEmpty) {
//         image1Url = await _uploadImage(_capturedImages[0]);
//       }
//       if (_capturedImages.length > 1) {
//         image2Url = await _uploadImage(_capturedImages[1]);
//       }

//       final requestBody = {
//         'transactionId': _activeTransactionId,
//         'orderFunnel': _selectedFunnelStage,
//         'notes': _notesController.text.isNotEmpty
//             ? _notesController.text
//             : null,
//         'notesRelatedTo': _mistakeRelatedTo,
//         'merchandiseImage1': image1Url,
//         'merchandiseImage2': image2Url,
//       };

//       final response = await http.put(
//         Uri.parse('${ApiConfig.baseUrl}/transaction-crm/update'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode(requestBody),
//       );

//       final data = json.decode(response.body);

//       if (response.statusCode == 200 && data['success'] == true) {
//         setState(() => _isFunnelUpdated = true);

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: [
//                   const Icon(Icons.check_circle, color: Colors.white),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       '✓ Updated: $_selectedFunnelStage${_capturedImages.isNotEmpty ? " (${_capturedImages.length} images)" : ""}',
//                     ),
//                   ),
//                 ],
//               ),
//               backgroundColor: Colors.green,
//               duration: const Duration(seconds: 2),
//               behavior: SnackBarBehavior.floating,
//               margin: const EdgeInsets.all(16),
//             ),
//           );
//         }
//       } else {
//         throw Exception(data['message'] ?? 'Failed to update');
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 const Icon(Icons.error, color: Colors.white),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(e.toString().replaceAll('Exception: ', '')),
//                 ),
//               ],
//             ),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 3),
//             behavior: SnackBarBehavior.floating,
//             margin: const EdgeInsets.all(16),
//           ),
//         );
//       }
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _handleVisitOut() async {
//     // Show confirmation dialog
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Visit Out'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Are you sure you want to end this visit?'),
//             const SizedBox(height: 12),
//             if (_selectedFunnelStage != null)
//               Text(
//                 '✓ Order Funnel: $_selectedFunnelStage',
//                 style: const TextStyle(
//                   fontSize: 13,
//                   color: Colors.green,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             if (_capturedImages.isNotEmpty)
//               Text(
//                 '✓ Merchandise: ${_capturedImages.length} images',
//                 style: const TextStyle(
//                   fontSize: 13,
//                   color: Colors.green,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             if (_notesController.text.isNotEmpty)
//               Text(
//                 '✓ Notes: ${_notesController.text.length} characters',
//                 style: const TextStyle(
//                   fontSize: 13,
//                   color: Colors.green,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(backgroundColor: _primary),
//             child: const Text('Yes, End Visit'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed != true) return;

//     setState(() => _isLoading = true);

//     try {
//       final account = widget.account;
//       if (account == null) {
//         throw Exception('Account data not available');
//       }

//       final accountId =
//           account['id']?.toString() ?? account['accountCode']?.toString();
//       final accountLat = account['latitude'];
//       final accountLng = account['longitude'];

//       if (accountId == null) {
//         throw Exception('Account ID not available');
//       }

//       if (accountLat == null || accountLng == null) {
//         throw Exception('Account location not available');
//       }

//       // Get current location
//       final position = await _getCurrentLocation();
//       if (position == null) {
//         throw Exception('Could not get current location');
//       }

//       // Get salesman ID from auth service
//       final salesmanId = await AuthService.getUserId();
//       if (salesmanId == null) {
//         throw Exception('User not logged in');
//       }

//       // Upload images if any
//       String? image1Url;
//       String? image2Url;
//       if (_capturedImages.isNotEmpty) {
//         image1Url = await _uploadImage(_capturedImages[0]);
//       }
//       if (_capturedImages.length > 1) {
//         image2Url = await _uploadImage(_capturedImages[1]);
//       }

//       print('=== Visit Out Request ===');
//       print('Account ID: $accountId');
//       print('Salesman ID: $salesmanId');
//       print('Order Funnel: $_selectedFunnelStage');
//       print('Notes: ${_notesController.text}');
//       print('Notes Related To: $_mistakeRelatedTo');
//       print('Images: ${_capturedImages.length}');

//       final requestBody = {
//         'accountId': accountId,
//         'salesmanId': salesmanId,
//         'latitude': position.latitude,
//         'longitude': position.longitude,
//         'accountLatitude': accountLat,
//         'accountLongitude': accountLng,
//         'orderFunnel': _selectedFunnelStage,
//         'notes': _notesController.text.isNotEmpty
//             ? _notesController.text
//             : null,
//         'notesRelatedTo': _mistakeRelatedTo,
//         'merchandiseImage1': image1Url,
//         'merchandiseImage2': image2Url,
//       };

//       print('Request body: ${json.encode(requestBody)}');

//       final response = await http.post(
//         Uri.parse('${ApiConfig.baseUrl}/transaction-crm/visit-out'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode(requestBody),
//       );

//       print('Response status: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       final data = json.decode(response.body);

//       if (response.statusCode == 200 && data['success'] == true) {
//         _stopTimer(); // Stop timer

//         setState(() {
//           _isVisitedIn = false;
//           _activeTransactionId = null;
//           _visitInTime = null;
//           _visitDuration = Duration.zero;
//           _selectedFunnelStage = null;
//           _capturedImages.clear();
//           _notesController.clear();
//           _mistakeRelatedTo = null;
//           _isFunnelUpdated = false;
//         });

//         // Reload transactions
//         _loadTransactions();

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: [
//                   const Icon(Icons.check_circle, color: Colors.white),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text('✓ Visit Out successful! All data saved.'),
//                   ),
//                 ],
//               ),
//               backgroundColor: Colors.green,
//               duration: const Duration(seconds: 2),
//               behavior: SnackBarBehavior.floating,
//               margin: const EdgeInsets.all(16),
//             ),
//           );
//         }
//       } else {
//         throw Exception(data['message'] ?? 'Failed to record Visit Out');
//       }
//     } catch (e) {
//       print('Visit Out error: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 const Icon(Icons.error, color: Colors.white),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(e.toString().replaceAll('Exception: ', '')),
//                 ),
//               ],
//             ),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 3),
//             behavior: SnackBarBehavior.floating,
//             margin: const EdgeInsets.all(16),
//           ),
//         );
//       }
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<String?> _uploadImage(XFile image) async {
//     // TODO: Implement actual image upload to your server
//     // For now, return base64 encoded image
//     try {
//       final bytes = await image.readAsBytes();
//       return base64Encode(bytes);
//     } catch (e) {
//       print('Error uploading image: $e');
//       return null;
//     }
//   }

//   String _dayLabel(int day) {
//     const labels = {
//       1: 'Mon',
//       2: 'Tue',
//       3: 'Wed',
//       4: 'Thu',
//       5: 'Fri',
//       6: 'Sat',
//       7: 'Sun',
//     };
//     return labels[day] ?? 'Day $day';
//   }

//   List<int> _assignedDays(Map<String, dynamic> account) {
//     final raw = (account['assignedDays'] as List?) ?? const [];
//     return raw
//         .map((e) => int.tryParse(e.toString()))
//         .whereType<int>()
//         .where((d) => d >= 1 && d <= 7)
//         .toList();
//   }

//   List<int> _visibleDays(Map<String, dynamic> account) {
//     final explicitDay = int.tryParse(
//       (account['selectedDay'] ?? account['dayOfWeek'] ?? '').toString(),
//     );
//     if (explicitDay != null && explicitDay >= 1 && explicitDay <= 7) {
//       return [explicitDay];
//     }
//     return _assignedDays(account);
//   }

//   String _visitType(Map<String, dynamic> account) {
//     final freq = (account['visitFrequency']?.toString() ?? '')
//         .trim()
//         .toUpperCase();
//     final recurrenceType = (account['recurrenceType']?.toString() ?? '')
//         .trim()
//         .toLowerCase();
//     final afterDays = int.tryParse(account['afterDays']?.toString() ?? '');
//     final days = _assignedDays(account);

//     if (afterDays != null && afterDays > 0) return 'AFTER_DAYS';
//     if (recurrenceType.contains('after')) return 'AFTER_DAYS';
//     if (freq.isNotEmpty) return freq;
//     if (days.isNotEmpty) return 'WEEKLY';
//     return 'WEEKLY';
//   }

//   String _visitTypeLabel(Map<String, dynamic> account) {
//     final type = _visitType(account);
//     final afterDays = int.tryParse(account['afterDays']?.toString() ?? '');
//     if (type == 'AFTER_DAYS') {
//       if (afterDays != null && afterDays > 0) return 'AFTER $afterDays DAYS';
//       return 'AFTER N DAYS';
//     }
//     return type.replaceAll('_', ' ');
//   }

//   Color _visitTypeBg(Map<String, dynamic> account) {
//     switch (_visitType(account)) {
//       case 'MONTHLY':
//         return const Color(0xFFE8F1FF);
//       case 'AFTER_DAYS':
//         return const Color(0xFFFFEFE0);
//       case 'DAILY':
//         return const Color(0xFFE7F9EC);
//       default:
//         return const Color(0xFFE8F8EC);
//     }
//   }

//   Color _visitTypeText(Map<String, dynamic> account) {
//     switch (_visitType(account)) {
//       case 'MONTHLY':
//         return const Color(0xFF215DA8);
//       case 'AFTER_DAYS':
//         return const Color(0xFFA35A17);
//       case 'DAILY':
//         return const Color(0xFF1F8B46);
//       default:
//         return const Color(0xFF1E7A3C);
//     }
//   }

//   Widget _buildVisitTypeChip(Map<String, dynamic> account) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       decoration: BoxDecoration(
//         color: _visitTypeBg(account),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(
//           color: _visitTypeText(account).withValues(alpha: 0.25),
//         ),
//       ),
//       child: Text(
//         _visitTypeLabel(account),
//         style: TextStyle(
//           fontSize: 11,
//           fontWeight: FontWeight.w800,
//           color: _visitTypeText(account),
//         ),
//       ),
//     );
//   }

//   Widget _buildDayChip(int day) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF1F3F6),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: const Color(0xFFE1E5EA)),
//       ),
//       child: Text(
//         _dayLabel(day),
//         style: const TextStyle(
//           fontSize: 11,
//           fontWeight: FontWeight.w700,
//           color: Color(0xFF606873),
//         ),
//       ),
//     );
//   }

//   Future<void> _makePhoneCall(String phoneNumber) async {
//     final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
//     if (await canLaunchUrl(launchUri)) {
//       await launchUrl(launchUri);
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Could not launch phone dialer')),
//         );
//       }
//     }
//   }

//   Future<void> _openWhatsApp(String phoneNumber) async {
//     // Remove any non-digit characters
//     String cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');

//     // If number doesn't start with country code, assume India (+91)
//     if (!cleanNumber.startsWith('91') && cleanNumber.length == 10) {
//       cleanNumber = '91$cleanNumber';
//     }

//     // Try WhatsApp URL scheme first (works better on mobile)
//     final Uri whatsappUri = Uri.parse('whatsapp://send?phone=$cleanNumber');

//     try {
//       final bool canLaunch = await canLaunchUrl(whatsappUri);
//       if (canLaunch) {
//         await launchUrl(whatsappUri);
//       } else {
//         // Fallback to web WhatsApp
//         final Uri webWhatsappUri = Uri.parse('https://wa.me/$cleanNumber');
//         await launchUrl(webWhatsappUri, mode: LaunchMode.externalApplication);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Could not open WhatsApp: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<void> _openMap(String address) async {
//     final account = widget.account;
//     final lat = account?['latitude'];
//     final lng = account?['longitude'];

//     // If we have coordinates, use them for more accurate navigation
//     Uri launchUri;
//     if (lat != null && lng != null) {
//       // Use geo: URI scheme which opens in Google Maps app
//       launchUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
//     } else {
//       // Fallback to address search
//       final encodedAddress = Uri.encodeComponent(address);
//       launchUri = Uri.parse('geo:0,0?q=$encodedAddress');
//     }

//     try {
//       final bool canLaunch = await canLaunchUrl(launchUri);
//       if (canLaunch) {
//         await launchUrl(launchUri);
//       } else {
//         // Fallback to Google Maps web
//         final encodedAddress = Uri.encodeComponent(address);
//         final webUri = Uri.parse(
//           'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
//         );
//         await launchUrl(webUri, mode: LaunchMode.externalApplication);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Could not open maps: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   void _toggleSection(String section) {
//     setState(() {
//       _expandedSection = _expandedSection == section ? null : section;
//     });
//   }

//   void _showImageDialog(BuildContext context, String base64Image) {
//     showDialog(
//       context: context,
//       barrierColor: Colors.black87,
//       builder: (context) => Dialog(
//         backgroundColor: Colors.transparent,
//         insetPadding: const EdgeInsets.all(20),
//         child: Stack(
//           children: [
//             Center(
//               child: InteractiveViewer(
//                 minScale: 0.5,
//                 maxScale: 4.0,
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(12),
//                   child: Image.memory(
//                     base64Decode(base64Image),
//                     fit: BoxFit.contain,
//                     errorBuilder: (context, error, stackTrace) {
//                       return Container(
//                         padding: const EdgeInsets.all(40),
//                         color: Colors.grey.shade300,
//                         child: const Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(Icons.error, size: 48, color: Colors.red),
//                             SizedBox(height: 16),
//                             Text(
//                               'Failed to load image',
//                               style: TextStyle(color: Colors.black),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ),
//             Positioned(
//               top: 10,
//               right: 10,
//               child: IconButton(
//                 onPressed: () => Navigator.pop(context),
//                 icon: const Icon(Icons.close, color: Colors.white, size: 30),
//                 style: IconButton.styleFrom(
//                   backgroundColor: Colors.black54,
//                   padding: const EdgeInsets.all(8),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionButton({required String id, required String label}) {
//     final isOpen = _expandedSection == id;
//     return Expanded(
//       child: GestureDetector(
//         onTap: () => _toggleSection(id),
//         child: Container(
//           height: 34,
//           alignment: Alignment.center,
//           decoration: BoxDecoration(
//             color: isOpen ? _primary : Colors.white,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(
//               color: isOpen ? const Color(0xFF8A7631) : const Color(0xFFE1E5EA),
//               width: 1,
//             ),
//           ),
//           child: Text(
//             label,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 11,
//               fontWeight: FontWeight.w700,
//               color: isOpen ? Colors.white : Colors.black87,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildExpandedBody() {
//     if (_expandedSection == null) {
//       return Container(
//         width: double.infinity,
//         margin: const EdgeInsets.only(top: 10),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: const Color(0xFFE4E8EE)),
//         ),
//         child: const Text(
//           'Tap any section above to open details.',
//           style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
//         ),
//       );
//     }

//     if (_expandedSection == 'history') {
//       return Container(
//         width: double.infinity,
//         margin: const EdgeInsets.only(top: 10),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: const Color(0xFFE4E8EE)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: const [
//             Text(
//               'Order History',
//               style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
//             ),
//             SizedBox(height: 6),
//             Text('No historical orders available for this account yet.'),
//             SizedBox(height: 12),
//             Divider(),
//             SizedBox(height: 6),
//             Text(
//               'Product Order Summary',
//               style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
//             ),
//             SizedBox(height: 6),
//             Text('Summary placeholders can be replaced with API data.'),
//             SizedBox(height: 4),
//             Text('Total Items: 0'),
//             Text('Total Qty: 0'),
//             Text('Total Value: Rs 0'),
//           ],
//         ),
//       );
//     }

//     if (_expandedSection == 'funnel') {
//       return Container(
//         width: double.infinity,
//         margin: const EdgeInsets.only(top: 10),
//         padding: const EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//             color: _primary.withValues(alpha: 0.3),
//             width: 1.5,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Order Funnel',
//                   style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
//                 ),
//                 if (_isFunnelUpdated)
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 6,
//                       vertical: 3,
//                     ),
//                     decoration: BoxDecoration(
//                       color: _primary.withValues(alpha: 0.15),
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border.all(
//                         color: _primary.withValues(alpha: 0.4),
//                       ),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.check_circle, size: 12, color: _primary),
//                         const SizedBox(width: 3),
//                         Text(
//                           'Updated',
//                           style: TextStyle(
//                             fontSize: 10,
//                             fontWeight: FontWeight.w700,
//                             color: _primary,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             // Show message if visit not started
//             if (!_isVisitedIn)
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 margin: const EdgeInsets.only(bottom: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.shade50,
//                   borderRadius: BorderRadius.circular(6),
//                   border: Border.all(color: Colors.orange.shade200),
//                 ),
//                 child: Row(
//                   children: const [
//                     Icon(Icons.info_outline, size: 16, color: Colors.orange),
//                     SizedBox(width: 6),
//                     Expanded(
//                       child: Text(
//                         'Please click "Visit In" to start editing',
//                         style: TextStyle(
//                           fontSize: 11,
//                           color: Colors.orange,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             // Display funnel stages in 2 columns
//             ...List.generate((_funnelStages.length / 2).ceil(), (rowIndex) {
//               final startIndex = rowIndex * 2;
//               final endIndex = (startIndex + 2).clamp(0, _funnelStages.length);
//               final rowStages = _funnelStages.sublist(startIndex, endIndex);

//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 3),
//                 child: Row(
//                   children: rowStages.map((stage) {
//                     final isSelected = _selectedFunnelStage == stage;
//                     return Expanded(
//                       child: InkWell(
//                         onTap: _isVisitedIn
//                             ? () {
//                                 setState(() {
//                                   _selectedFunnelStage = stage;
//                                 });
//                               }
//                             : null,
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 3,
//                             vertical: 6,
//                           ),
//                           child: Row(
//                             children: [
//                               Radio<String>(
//                                 value: stage,
//                                 groupValue: _selectedFunnelStage,
//                                 activeColor: _primary,
//                                 onChanged: _isVisitedIn
//                                     ? (value) {
//                                         setState(() {
//                                           _selectedFunnelStage = value;
//                                         });
//                                       }
//                                     : null,
//                                 materialTapTargetSize:
//                                     MaterialTapTargetSize.shrinkWrap,
//                                 visualDensity: const VisualDensity(
//                                   horizontal: -4,
//                                   vertical: -4,
//                                 ),
//                               ),
//                               const SizedBox(width: 3),
//                               Expanded(
//                                 child: Text(
//                                   stage,
//                                   style: TextStyle(
//                                     fontSize: 11,
//                                     fontWeight: FontWeight.w600,
//                                     color: _isVisitedIn
//                                         ? (isSelected
//                                               ? _primary
//                                               : Colors.black87)
//                                         : Colors.grey,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               );
//             }),
//             const SizedBox(height: 8),
//             const Divider(height: 1),
//             const SizedBox(height: 8),
//             // Merchandise Section
//             const Text(
//               'Merchandise Details',
//               style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
//             ),
//             const SizedBox(height: 8),
//             // Image Capture
//             const Text(
//               'Capture Images (Max 2)',
//               style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
//             ),
//             const SizedBox(height: 6),
//             Wrap(
//               spacing: 6,
//               runSpacing: 6,
//               children: [
//                 ..._capturedImages.asMap().entries.map((entry) {
//                   return Stack(
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(6),
//                         child: Image.file(
//                           File(entry.value.path),
//                           width: 80,
//                           height: 80,
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                       if (_isVisitedIn)
//                         Positioned(
//                           top: 3,
//                           right: 3,
//                           child: InkWell(
//                             onTap: () {
//                               setState(() {
//                                 _capturedImages.removeAt(entry.key);
//                               });
//                             },
//                             child: Container(
//                               padding: const EdgeInsets.all(3),
//                               decoration: const BoxDecoration(
//                                 color: Colors.red,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: const Icon(
//                                 Icons.close,
//                                 size: 14,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   );
//                 }),
//                 if (_capturedImages.length < 2 && _isVisitedIn)
//                   InkWell(
//                     onTap: () async {
//                       final picker = ImagePicker();
//                       final image = await picker.pickImage(
//                         source: ImageSource.camera,
//                         imageQuality: 75,
//                       );
//                       if (image != null) {
//                         setState(() {
//                           _capturedImages.add(image);
//                         });
//                       }
//                     },
//                     child: Container(
//                       width: 80,
//                       height: 80,
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade200,
//                         borderRadius: BorderRadius.circular(6),
//                         border: Border.all(color: Colors.grey.shade400),
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: const [
//                           Icon(Icons.add_a_photo, size: 24, color: Colors.grey),
//                           SizedBox(height: 3),
//                           Text(
//                             'Add Photo',
//                             style: TextStyle(fontSize: 9, color: Colors.grey),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             //  Related To
//             const Text(
//               'Related To',
//               style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
//             ),
//             const SizedBox(height: 6),
//             DropdownButtonFormField<String>(
//               value: _mistakeRelatedTo,
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 8,
//                   vertical: 8,
//                 ),
//                 filled: !_isVisitedIn,
//                 fillColor: !_isVisitedIn ? Colors.grey.shade100 : null,
//               ),
//               hint: const Text('Select', style: TextStyle(fontSize: 11)),
//               style: TextStyle(
//                 fontSize: 11,
//                 color: _isVisitedIn ? Colors.black : Colors.grey,
//               ),
//               items: _mistakeOptions.map((option) {
//                 return DropdownMenuItem(value: option, child: Text(option));
//               }).toList(),
//               onChanged: _isVisitedIn
//                   ? (value) {
//                       setState(() {
//                         _mistakeRelatedTo = value;
//                       });
//                     }
//                   : null,
//             ),
//             const SizedBox(height: 8),
//             // Notes
//             const Text(
//               'Notes',
//               style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
//             ),
//             const SizedBox(height: 6),
//             TextField(
//               controller: _notesController,
//               maxLines: 3,
//               enabled: _isVisitedIn,
//               style: TextStyle(
//                 fontSize: 11,
//                 color: _isVisitedIn ? Colors.black : Colors.grey,
//               ),
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(6),
//                 ),
//                 hintText: 'Enter notes here...',
//                 hintStyle: const TextStyle(fontSize: 11),
//                 contentPadding: const EdgeInsets.all(8),
//                 filled: !_isVisitedIn,
//                 fillColor: !_isVisitedIn ? Colors.grey.shade100 : null,
//               ),
//             ),
//             const SizedBox(height: 10),
//             // Update Button (only visible when visit is active)
//             if (_isVisitedIn)
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _selectedFunnelStage == null
//                       ? null
//                       : _handleUpdate,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color.fromARGB(255, 230, 225, 93),
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(vertical: 10),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                   ),
//                   child: const Text(
//                     'Update',
//                     style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       );
//     }

//     if (_expandedSection == 'transaction') {
//       print('🔍 Rendering transaction section');
//       print('🔍 Transactions count: ${_transactions.length}');
//       print('🔍 Is loading: $_isLoadingTransactions');

//       return Container(
//         width: double.infinity,
//         margin: const EdgeInsets.only(top: 10),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(color: const Color(0xFFE4E8EE)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Transaction History',
//                   style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
//                 ),
//                 if (_transactions.isNotEmpty)
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 6,
//                       vertical: 3,
//                     ),
//                     decoration: BoxDecoration(
//                       color: _primary.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Text(
//                       '${_transactions.length} visits',
//                       style: TextStyle(
//                         fontSize: 10,
//                         fontWeight: FontWeight.w700,
//                         color: _primary,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             if (_isLoadingTransactions)
//               const Center(
//                 child: Padding(
//                   padding: EdgeInsets.all(16),
//                   child: CircularProgressIndicator(),
//                 ),
//               )
//             else if (_transactions.isEmpty)
//               const Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Center(
//                   child: Text(
//                     'No transactions available yet.',
//                     style: TextStyle(color: Colors.grey, fontSize: 12),
//                   ),
//                 ),
//               )
//             else
//               ListView.separated(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: _transactions.length,
//                 separatorBuilder: (context, index) => const Divider(height: 12),
//                 itemBuilder: (context, index) {
//                   final transaction = _transactions[index];
//                   final visitIn = transaction['visitInTime'] != null
//                       ? DateTime.parse(transaction['visitInTime']).toLocal()
//                       : null;
//                   final visitOut = transaction['visitOutTime'] != null
//                       ? DateTime.parse(transaction['visitOutTime']).toLocal()
//                       : null;
//                   final duration = visitIn != null && visitOut != null
//                       ? visitOut.difference(visitIn)
//                       : null;

//                   return Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade50,
//                       borderRadius: BorderRadius.circular(6),
//                       border: Border.all(color: Colors.grey.shade200),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               'Visit #${transaction['transactionNo']}',
//                               style: const TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w800,
//                               ),
//                             ),
//                             if (duration != null)
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 5,
//                                   vertical: 2,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.blue.shade50,
//                                   borderRadius: BorderRadius.circular(6),
//                                 ),
//                                 child: Text(
//                                   _formatDuration(duration),
//                                   style: TextStyle(
//                                     fontSize: 10,
//                                     fontWeight: FontWeight.w700,
//                                     color: Colors.blue.shade700,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         const SizedBox(height: 6),
//                         if (visitIn != null)
//                           _buildTransactionRow(
//                             Icons.login,
//                             'Visit In',
//                             _formatDateTime(visitIn),
//                             Colors.green,
//                           ),
//                         if (visitOut != null)
//                           _buildTransactionRow(
//                             Icons.logout,
//                             'Visit Out',
//                             _formatDateTime(visitOut),
//                             Colors.red,
//                           ),
//                         if (transaction['orderFunnel'] != null)
//                           _buildTransactionRow(
//                             Icons.filter_list,
//                             'Order Funnel',
//                             transaction['orderFunnel'],
//                             _primary,
//                           ),
//                         if (transaction['notes'] != null)
//                           _buildTransactionRow(
//                             Icons.note,
//                             'Notes',
//                             transaction['notes'],
//                             Colors.grey.shade700,
//                           ),
//                         if (transaction['merchandiseImage1'] != null ||
//                             transaction['merchandiseImage2'] != null)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 6),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Row(
//                                   children: [
//                                     Icon(
//                                       Icons.photo_camera,
//                                       size: 16,
//                                       color: Colors.purple,
//                                     ),
//                                     const SizedBox(width: 8),
//                                     const Text(
//                                       'Merchandise Images: ',
//                                       style: TextStyle(
//                                         fontSize: 12,
//                                         fontWeight: FontWeight.w600,
//                                         color: Colors.grey,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 8),
//                                 Row(
//                                   children: [
//                                     if (transaction['merchandiseImage1'] !=
//                                         null)
//                                       Padding(
//                                         padding: const EdgeInsets.only(
//                                           right: 8,
//                                         ),
//                                         child: GestureDetector(
//                                           onTap: () {
//                                             _showImageDialog(
//                                               context,
//                                               transaction['merchandiseImage1'],
//                                             );
//                                           },
//                                           child: ClipRRect(
//                                             borderRadius: BorderRadius.circular(
//                                               8,
//                                             ),
//                                             child: Image.memory(
//                                               base64Decode(
//                                                 transaction['merchandiseImage1'],
//                                               ),
//                                               width: 80,
//                                               height: 80,
//                                               fit: BoxFit.cover,
//                                               errorBuilder:
//                                                   (context, error, stackTrace) {
//                                                     return Container(
//                                                       width: 80,
//                                                       height: 80,
//                                                       color:
//                                                           Colors.grey.shade300,
//                                                       child: const Icon(
//                                                         Icons.error,
//                                                       ),
//                                                     );
//                                                   },
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     if (transaction['merchandiseImage2'] !=
//                                         null)
//                                       GestureDetector(
//                                         onTap: () {
//                                           _showImageDialog(
//                                             context,
//                                             transaction['merchandiseImage2'],
//                                           );
//                                         },
//                                         child: ClipRRect(
//                                           borderRadius: BorderRadius.circular(
//                                             8,
//                                           ),
//                                           child: Image.memory(
//                                             base64Decode(
//                                               transaction['merchandiseImage2'],
//                                             ),
//                                             width: 80,
//                                             height: 80,
//                                             fit: BoxFit.cover,
//                                             errorBuilder:
//                                                 (context, error, stackTrace) {
//                                                   return Container(
//                                                     width: 80,
//                                                     height: 80,
//                                                     color: Colors.grey.shade300,
//                                                     child: const Icon(
//                                                       Icons.error,
//                                                     ),
//                                                   );
//                                                 },
//                                           ),
//                                         ),
//                                       ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//           ],
//         ),
//       );
//     }

//     return const SizedBox.shrink();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final account = widget.account ?? const <String, dynamic>{};
//     final shopName = (account['businessName']?.toString() ?? 'Order Details')
//         .trim();
//     final ownerName = (account['personName']?.toString() ?? '-').trim();
//     final accountCode = (account['accountCode']?.toString() ?? '-').trim();
//     final address = (account['address']?.toString() ?? '-').trim();
//     final assignedDays = _visibleDays(account);
//     final accountId = (accountCode.isNotEmpty && accountCode != '-')
//         ? accountCode
//         : (account['id']?.toString() ?? '-').trim();

//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F7),
//       appBar: AppBar(
//         title: const Text('Order Details'),
//         backgroundColor: _primary,
//       ),
//       body: ListView(
//         padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
//         children: [
//           Container(
//             padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
//             decoration: BoxDecoration(
//               color: const Color(0xFFFFFFFF),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: _primary.withValues(alpha: 0.45)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             accountId,
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey.shade700,
//                               fontWeight: FontWeight.w700,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           const SizedBox(height: 4),
//                           Wrap(
//                             spacing: 4,
//                             runSpacing: 4,
//                             children: [
//                               _buildVisitTypeChip(account),
//                               ...assignedDays.map(_buildDayChip),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 6),
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         Text(
//                           ownerName,
//                           textAlign: TextAlign.right,
//                           style: const TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w700,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         const SizedBox(height: 6),
//                         Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             SizedBox(
//                               height: 28,
//                               child: ElevatedButton(
//                                 onPressed: _isLoading || _isVisitedIn
//                                     ? null
//                                     : _handleVisitIn,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: _isVisitedIn
//                                       ? Colors.grey
//                                       : _primary,
//                                   foregroundColor: Colors.white,
//                                   elevation: 0,
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 8,
//                                   ),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(6),
//                                   ),
//                                   textStyle: const TextStyle(
//                                     fontSize: 10,
//                                     fontWeight: FontWeight.w800,
//                                   ),
//                                 ),
//                                 child: _isLoading && !_isVisitedIn
//                                     ? const SizedBox(
//                                         width: 10,
//                                         height: 10,
//                                         child: CircularProgressIndicator(
//                                           strokeWidth: 2,
//                                           color: Colors.white,
//                                         ),
//                                       )
//                                     : Text(
//                                         _isVisitedIn
//                                             ? 'Visited In'
//                                             : 'Visit In',
//                                       ),
//                               ),
//                             ),
//                             const SizedBox(width: 4),
//                             SizedBox(
//                               height: 28,
//                               child: ElevatedButton(
//                                 onPressed: _isLoading || !_isVisitedIn
//                                     ? null
//                                     : _handleVisitOut,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: !_isVisitedIn
//                                       ? Colors.grey
//                                       : _primary,
//                                   foregroundColor: Colors.white,
//                                   elevation: 0,
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 8,
//                                   ),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(6),
//                                   ),
//                                   textStyle: const TextStyle(
//                                     fontSize: 10,
//                                     fontWeight: FontWeight.w800,
//                                   ),
//                                 ),
//                                 child: _isLoading && _isVisitedIn
//                                     ? const SizedBox(
//                                         width: 10,
//                                         height: 10,
//                                         child: CircularProgressIndicator(
//                                           strokeWidth: 2,
//                                           color: Colors.white,
//                                         ),
//                                       )
//                                     : const Text('Visit Out'),
//                               ),
//                             ),
//                           ],
//                         ),
//                         if (_isVisitedIn && _isTimerRunning)
//                           Padding(
//                             padding: const EdgeInsets.only(top: 6),
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 4,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: Colors.blue.shade50,
//                                 borderRadius: BorderRadius.circular(6),
//                                 border: Border.all(color: Colors.blue.shade200),
//                               ),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Icon(
//                                     Icons.timer,
//                                     size: 14,
//                                     color: Colors.blue.shade700,
//                                   ),
//                                   const SizedBox(width: 4),
//                                   Text(
//                                     _formatDuration(_visitDuration),
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       fontWeight: FontWeight.w700,
//                                       color: Colors.blue.shade700,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ],
//                 ),

//                 Text(
//                   shopName,
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w800,
//                     height: 1.1,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 2),
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Icon(
//                       Icons.place_outlined,
//                       size: 15,
//                       color: Colors.grey.shade700,
//                     ),
//                     const SizedBox(width: 6),
//                     Expanded(
//                       child: Text(
//                         'Address : ${address.isEmpty ? '-' : address}',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey.shade800,
//                           fontWeight: FontWeight.w600,
//                         ),
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(
//                       children: [
//                         IconButton(
//                           onPressed: () {
//                             final phone =
//                                 account['phoneNumber']?.toString() ??
//                                 account['phone']?.toString() ??
//                                 account['contactNumber']?.toString() ??
//                                 '';
//                             if (phone.isNotEmpty) {
//                               _makePhoneCall(phone);
//                             } else {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text('Phone number not available'),
//                                 ),
//                               );
//                             }
//                           },
//                           icon: const Icon(
//                             Icons.call,
//                             color: Color(0xFF4CAF50),
//                           ),
//                           iconSize: 26,
//                           tooltip: 'Call',
//                         ),
//                         IconButton(
//                           onPressed: () {
//                             final phone =
//                                 account['phoneNumber']?.toString() ??
//                                 account['phone']?.toString() ??
//                                 account['contactNumber']?.toString() ??
//                                 '';
//                             if (phone.isNotEmpty) {
//                               _openWhatsApp(phone);
//                             } else {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text('Phone number not available'),
//                                 ),
//                               );
//                             }
//                           },
//                           icon: const FaIcon(
//                             FontAwesomeIcons.whatsapp,
//                             color: Color(0xFF25D366),
//                           ),
//                           iconSize: 26,
//                           tooltip: 'WhatsApp',
//                         ),
//                         IconButton(
//                           onPressed: () {
//                             if (address.isNotEmpty && address != '-') {
//                               _openMap(address);
//                             } else {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text('Address not available'),
//                                 ),
//                               );
//                             }
//                           },
//                           icon: const Icon(Icons.map, color: Color(0xFF2196F3)),
//                           iconSize: 26,
//                           tooltip: 'Open Map',
//                         ),
//                       ],
//                     ),
//                     SizedBox(
//                       height: 32,
//                       child: ElevatedButton.icon(
//                         onPressed: () {
//                           // TODO: Implement Take Order functionality
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text('Take Order feature coming soon'),
//                               duration: Duration(seconds: 2),
//                             ),
//                           );
//                         },
//                         icon: const Icon(Icons.shopping_cart, size: 16),
//                         label: const Text('Take Order'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: _primary,
//                           foregroundColor: Colors.white,
//                           elevation: 0,
//                           padding: const EdgeInsets.symmetric(horizontal: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           textStyle: const TextStyle(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//               ],
//             ),
//           ),
//           const SizedBox(height: 10),
//           Row(
//             children: [
//               _buildSectionButton(id: 'history', label: 'Order History'),
//               const SizedBox(width: 4),
//               _buildSectionButton(id: 'funnel', label: 'Order Funnel'),
//               const SizedBox(width: 4),
//               _buildSectionButton(id: 'transaction', label: 'Transaction'),
//             ],
//           ),
//           AnimatedSwitcher(
//             duration: const Duration(milliseconds: 220),
//             child: _buildExpandedBody(),
//           ),
//         ],
//       ),
//     );
//   }
// }

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
  final List<Map<String, dynamic>> _capturedImages =
      []; // Changed to store image with metadata
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _notesFocusNode = FocusNode();
  String? _mistakeRelatedTo;
  bool _isVisitedIn = false;
  bool _isLoading = false;
  int? _activeTransactionId;
  DateTime? _visitInTime;
  Duration _visitDuration = Duration.zero;
  bool _isTimerRunning = false;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingTransactions = false;
  bool _isFunnelUpdated = false;

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

  static const List<String> _imageRelatedToOptions = [
    'Quality Issue',
    'Competitor working',
    'New Product in Market',
    'Document Issue',
    'Others',
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
  void deactivate() {
    // Unfocus before deactivation
    _notesFocusNode.unfocus();
    super.deactivate();
  }

  @override
  void dispose() {
    _isTimerRunning = false;
    _notesFocusNode.dispose();
    _notesController.dispose();
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
    _isTimerRunning = false;
    if (mounted) {
      setState(() {});
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${hour12}:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  Widget _buildTransactionRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
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
        if (data['hasActiveVisit'] == true && mounted) {
          setState(() {
            _isVisitedIn = true;
            _activeTransactionId = data['activeVisit']['id'];
            _visitInTime = DateTime.parse(data['activeVisit']['visitInTime']);
          });
          _startTimer();
        }
      }
    } catch (e) {
      print('Error checking active visit: $e');
    }

    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final account = widget.account;
    if (account == null) return;

    final accountId =
        account['id']?.toString() ?? account['accountCode']?.toString();
    if (accountId == null) return;

    if (mounted) {
      setState(() => _isLoadingTransactions = true);
    }

    try {
      final url = '${ApiConfig.baseUrl}/transaction-crm/history/$accountId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final transactionsList = List<Map<String, dynamic>>.from(
            data['transactions'].map((t) => Map<String, dynamic>.from(t)),
          );
          if (mounted) {
            setState(() {
              _transactions = transactionsList;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading transactions: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingTransactions = false);
      }
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
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

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final account = widget.account;
      if (account == null) throw Exception('Account data not available');

      final accountId =
          account['id']?.toString() ?? account['accountCode']?.toString();
      final accountLat = account['latitude'];
      final accountLng = account['longitude'];

      if (accountId == null) throw Exception('Account ID not available');
      if (accountLat == null || accountLng == null) {
        throw Exception('Account location not available');
      }

      final position = await _getCurrentLocation();
      if (position == null) throw Exception('Could not get current location');

      final salesmanId = await AuthService.getUserId();
      if (salesmanId == null) throw Exception('User not logged in');

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
        if (mounted) {
          setState(() {
            _isVisitedIn = true;
            _activeTransactionId = data['transaction']['id'];
            _visitInTime = DateTime.now();
          });
          _startTimer();
        }

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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleUpdate() async {
    if (_activeTransactionId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('No active visit found')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // Upload all images with metadata
      List<Map<String, dynamic>> uploadedImages = [];
      for (var imageData in _capturedImages) {
        final imageUrl = await _uploadImage(imageData['file']);
        if (imageUrl != null) {
          uploadedImages.add({
            'url': imageUrl,
            'relatedTo': imageData['relatedTo'],
            'notes': imageData['notes'],
          });
        }
      }

      final requestBody = {
        'transactionId': _activeTransactionId,
        'orderFunnel': _selectedFunnelStage,
        'notes': _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
        'notesRelatedTo': _mistakeRelatedTo,
        'merchandiseImages': uploadedImages, // Send all images with metadata
      };

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/transaction-crm/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          setState(() => _isFunnelUpdated = true);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '✓ Updated: $_selectedFunnelStage${_capturedImages.isNotEmpty ? " (${_capturedImages.length} images)" : ""}',
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
        throw Exception(data['message'] ?? 'Failed to update');
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleVisitOut() async {
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

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final account = widget.account;
      if (account == null) throw Exception('Account data not available');

      final accountId =
          account['id']?.toString() ?? account['accountCode']?.toString();
      final accountLat = account['latitude'];
      final accountLng = account['longitude'];

      if (accountId == null) throw Exception('Account ID not available');
      if (accountLat == null || accountLng == null) {
        throw Exception('Account location not available');
      }

      final position = await _getCurrentLocation();
      if (position == null) throw Exception('Could not get current location');

      final salesmanId = await AuthService.getUserId();
      if (salesmanId == null) throw Exception('User not logged in');

      // Upload all images with metadata
      List<Map<String, dynamic>> uploadedImages = [];
      for (var imageData in _capturedImages) {
        final imageUrl = await _uploadImage(imageData['file']);
        if (imageUrl != null) {
          uploadedImages.add({
            'url': imageUrl,
            'relatedTo': imageData['relatedTo'],
            'notes': imageData['notes'],
          });
        }
      }

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
        'merchandiseImages': uploadedImages, // Send all images with metadata
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/transaction-crm/visit-out'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _stopTimer();

        if (mounted) {
          setState(() {
            _isVisitedIn = false;
            _activeTransactionId = null;
            _visitInTime = null;
            _visitDuration = Duration.zero;
            _selectedFunnelStage = null;
            _capturedImages.clear();
            _notesController.clear();
            _mistakeRelatedTo = null;
            _isFunnelUpdated = false;
          });

          _loadTransactions();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>?> _showImageDetailsDialog({
    required String title,
    String? initialRelatedTo,
    String initialNotes = '',
    String confirmLabel = 'OK',
  }) async {
    String? tempRelatedTo = initialRelatedTo;
    final notesController = TextEditingController(text: initialNotes);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Related To',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: tempRelatedTo,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    isDense: true,
                  ),
                  hint: const Text('Select', style: TextStyle(fontSize: 13)),
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                  items: _imageRelatedToOptions.map((option) {
                    return DropdownMenuItem(value: option, child: Text(option));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      tempRelatedTo = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Notes',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    hintText: 'Enter notes for this image...',
                    contentPadding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, {
                  'relatedTo': tempRelatedTo,
                  'notes': notesController.text.trim(),
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ),
    );

    notesController.dispose();
    return result;
  }

  Future<void> _captureImageWithDetails() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
    );

    if (image == null) return;

    final details = await _showImageDetailsDialog(
      title: 'Image Details',
      confirmLabel: 'OK',
    );

    if (details == null) return;

    setState(() {
      _capturedImages.add({
        'file': image,
        'relatedTo': details['relatedTo'],
        'notes': details['notes'] ?? '',
      });
    });
  }

  Future<void> _showEditImageDialog(
    int index,
    Map<String, dynamic> imageData,
  ) async {
    final details = await _showImageDetailsDialog(
      title: 'Edit Image ${index + 1}',
      initialRelatedTo: imageData['relatedTo'],
      initialNotes: imageData['notes'] ?? '',
      confirmLabel: 'OK',
    );

    if (details == null) return;

    setState(() {
      _capturedImages[index]['relatedTo'] = details['relatedTo'];
      _capturedImages[index]['notes'] = details['notes'] ?? '';
    });
  }

  Future<String?> _uploadImage(XFile image) async {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (!cleanNumber.startsWith('91') && cleanNumber.length == 10) {
      cleanNumber = '91$cleanNumber';
    }

    final Uri whatsappUri = Uri.parse('whatsapp://send?phone=$cleanNumber');

    try {
      final bool canLaunch = await canLaunchUrl(whatsappUri);
      if (canLaunch) {
        await launchUrl(whatsappUri);
      } else {
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

    Uri launchUri;
    if (lat != null && lng != null) {
      launchUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    } else {
      final encodedAddress = Uri.encodeComponent(address);
      launchUri = Uri.parse('geo:0,0?q=$encodedAddress');
    }

    try {
      final bool canLaunch = await canLaunchUrl(launchUri);
      if (canLaunch) {
        await launchUrl(launchUri);
      } else {
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

  void _showImageDialog(BuildContext context, String base64Image) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(base64Image),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        padding: const EdgeInsets.all(40),
                        color: Colors.grey.shade300,
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error, size: 48, color: Colors.red),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FIXED: section toggle buttons, no excess padding ──────────────────────
  Widget _buildSectionButton({required String id, required String label}) {
    final isOpen = _expandedSection == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => _toggleSection(id),
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isOpen ? _primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isOpen ? const Color(0xFF8A7631) : const Color(0xFFE1E5EA),
              width: 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isOpen ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedBody() {
    if (_expandedSection == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE4E8EE)),
        ),
        child: const Text(
          'Tap any section above to open details.',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (_expandedSection == 'history') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE4E8EE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Order History',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4),
            Text('No historical orders available for this account yet.'),
            SizedBox(height: 10),
            Divider(),
            SizedBox(height: 4),
            Text(
              'Product Order Summary',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4),
            Text('Summary placeholders can be replaced with API data.'),
            SizedBox(height: 2),
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
        margin: const EdgeInsets.only(top: 8),
        // ── FIXED: tighter padding inside funnel card ────────────────────
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Funnel',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                if (_isFunnelUpdated)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 11, color: _primary),
                        const SizedBox(width: 3),
                        Text(
                          'Updated',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // ── Visit-not-started banner ──────────────────────────────────
            if (!_isVisitedIn)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, size: 14, color: Colors.orange),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Please click "Visit In" to start editing',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Funnel stage radio grid (2 columns) ───────────────────────
            ...List.generate((_funnelStages.length / 2).ceil(), (rowIndex) {
              final startIndex = rowIndex * 2;
              final endIndex = (startIndex + 2).clamp(0, _funnelStages.length);
              final rowStages = _funnelStages.sublist(startIndex, endIndex);

              return Padding(
                // ── FIXED: reduced row vertical padding ──────────────────
                padding: const EdgeInsets.only(bottom: 1),
                child: Row(
                  children: rowStages.map((stage) {
                    final isSelected = _selectedFunnelStage == stage;
                    return Expanded(
                      child: InkWell(
                        onTap: _isVisitedIn
                            ? () => setState(() => _selectedFunnelStage = stage)
                            : null,
                        child: Container(
                          // ── FIXED: tight row height ───────────────────
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 3,
                          ),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: stage,
                                groupValue: _selectedFunnelStage,
                                activeColor: _primary,
                                onChanged: _isVisitedIn
                                    ? (value) => setState(
                                        () => _selectedFunnelStage = value,
                                      )
                                    : null,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: const VisualDensity(
                                  horizontal: -4,
                                  vertical: -4,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  stage,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _isVisitedIn
                                        ? (isSelected
                                              ? _primary
                                              : Colors.black87)
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),

            // ── Divider ────────────────────────────────────────────────────
            const SizedBox(height: 4),
            const Divider(height: 1),
            const SizedBox(height: 6),

            // ── Merchandise section ────────────────────────────────────────
            const Text(
              'Details',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),

            // Add Image Button
            if (_isVisitedIn)
              InkWell(
                onTap: _captureImageWithDetails,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _primary, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: _primary, size: 20),
                      const SizedBox(width: 6),
                      Icon(Icons.camera_alt, color: _primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '+ Add Image',
                        style: TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Display captured images in card format
            ..._capturedImages.asMap().entries.map((entry) {
              final index = entry.key;
              final imageData = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image with delete button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(imageData['file'].path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Image ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (imageData['relatedTo'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    imageData['relatedTo'],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_isVisitedIn) ...[
                          // Edit button
                          IconButton(
                            onPressed: () {
                              _showEditImageDialog(index, imageData);
                            },
                            icon: Icon(Icons.edit, color: _primary),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          // Delete button
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _capturedImages.removeAt(index);
                              });
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Always show Related To and Notes as text labels (not input fields)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Related To: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            imageData['relatedTo'] ?? '-',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: imageData['relatedTo'] != null
                                  ? _primary
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes: ',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            (imageData['notes'] != null &&
                                    imageData['notes'].isNotEmpty)
                                ? imageData['notes']
                                : '-',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  (imageData['notes'] != null &&
                                      imageData['notes'].isNotEmpty)
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 6),
            // General Notes (separate from image notes)
            const Text(
              'General Notes',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _notesController,
              focusNode: _notesFocusNode,
              maxLines: 3,
              enabled: _isVisitedIn,
              style: TextStyle(
                fontSize: 11,
                color: _isVisitedIn ? Colors.black : Colors.grey,
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                hintText: 'Enter general notes here...',
                hintStyle: const TextStyle(fontSize: 11),
                contentPadding: const EdgeInsets.all(8),
                filled: !_isVisitedIn,
                fillColor: !_isVisitedIn ? Colors.grey.shade100 : null,
              ),
            ),

            const SizedBox(height: 6),
            // Related To for general notes
            const Text(
              'Notes Related To',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              value: _mistakeRelatedTo,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                filled: !_isVisitedIn,
                fillColor: !_isVisitedIn ? Colors.grey.shade100 : null,
                isDense: true,
              ),
              hint: const Text('Select', style: TextStyle(fontSize: 11)),
              style: TextStyle(
                fontSize: 11,
                color: _isVisitedIn ? Colors.black : Colors.grey,
              ),
              items: _mistakeOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option, style: const TextStyle(fontSize: 11)),
                );
              }).toList(),
              onChanged: _isVisitedIn
                  ? (value) => setState(() => _mistakeRelatedTo = value)
                  : null,
            ),

            // Update button
            if (_isVisitedIn) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedFunnelStage == null
                      ? null
                      : _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(211, 212, 176, 31),
                    foregroundColor: const Color.fromARGB(255, 5, 5, 5),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Update',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_expandedSection == 'transaction') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
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
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                if (_transactions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_transactions.length} visits',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingTransactions)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: Text(
                    'No transactions available yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length,
                separatorBuilder: (context, index) => const Divider(height: 10),
                itemBuilder: (context, index) {
                  final transaction = _transactions[index];
                  final visitIn = transaction['visitInTime'] != null
                      ? DateTime.parse(transaction['visitInTime']).toLocal()
                      : null;
                  final visitOut = transaction['visitOutTime'] != null
                      ? DateTime.parse(transaction['visitOutTime']).toLocal()
                      : null;
                  final duration = visitIn != null && visitOut != null
                      ? visitOut.difference(visitIn)
                      : null;

                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(6),
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
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (duration != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),

                                child: Text(
                                  _formatDuration(duration),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
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
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.photo_camera,
                                      size: 14,
                                      color: Colors.purple,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Merchandise Images:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (transaction['merchandiseImage1'] !=
                                        null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: GestureDetector(
                                          onTap: () => _showImageDialog(
                                            context,
                                            transaction['merchandiseImage1'],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: Image.memory(
                                              base64Decode(
                                                transaction['merchandiseImage1'],
                                              ),
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Container(
                                                    width: 70,
                                                    height: 70,
                                                    color: Colors.grey.shade300,
                                                    child: const Icon(
                                                      Icons.error,
                                                      size: 20,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (transaction['merchandiseImage2'] !=
                                        null)
                                      GestureDetector(
                                        onTap: () => _showImageDialog(
                                          context,
                                          transaction['merchandiseImage2'],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.memory(
                                            base64Decode(
                                              transaction['merchandiseImage2'],
                                            ),
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      width: 70,
                                                      height: 70,
                                                      color:
                                                          Colors.grey.shade300,
                                                      child: const Icon(
                                                        Icons.error,
                                                        size: 20,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
        children: [
          // ── MAIN CARD ─────────────────────────────────────────────────────
          Container(
            // ── FIXED: tighter overall padding ──────────────────────────
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primary.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: account code + chips | timer | owner + buttons ──────
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
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 4,
                            runSpacing: 3,
                            children: [
                              _buildVisitTypeChip(account),
                              ...assignedDays.map(_buildDayChip),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Timer in the middle
                    if (_isVisitedIn && _isTimerRunning)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),

                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer,
                              size: 13,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatDuration(_visitDuration),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_isVisitedIn && _isTimerRunning)
                      const SizedBox(width: 6),
                    // Right: owner name + Visit In/Out buttons
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Owner Name : $ownerName',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 28,
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
                                    horizontal: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                child: _isLoading && !_isVisitedIn
                                    ? const SizedBox(
                                        width: 10,
                                        height: 10,
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
                            const SizedBox(width: 4),
                            SizedBox(
                              height: 28,
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
                                    horizontal: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                child: _isLoading && _isVisitedIn
                                    ? const SizedBox(
                                        width: 10,
                                        height: 10,
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
                      ],
                    ),
                  ],
                ),

                // ── FIXED: less gap between chips row and shop name ──────
                const SizedBox(height: 4),
                Text(
                  'Shop Name : ${shopName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // ── FIXED: less gap before address ───────────────────────
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Address : ${address.isEmpty ? '-' : address}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),

                // ── FIXED: less gap before action icons ──────────────────
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Phone number not available'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.call,
                            color: Color(0xFF4CAF50),
                          ),
                          iconSize: 20,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: 'Call',
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () {
                            final phone =
                                account['phoneNumber']?.toString() ??
                                account['phone']?.toString() ??
                                account['contactNumber']?.toString() ??
                                '';
                            if (phone.isNotEmpty) {
                              _openWhatsApp(phone);
                            } else if (mounted) {
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
                          iconSize: 20,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: 'WhatsApp',
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () {
                            if (address.isNotEmpty && address != '-') {
                              _openMap(address);
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Address not available'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.map, color: Color(0xFF2196F3)),
                          iconSize: 20,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: 'Open Map',
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 30,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Take Order feature coming soon'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.shopping_cart, size: 14),
                        label: const Text('Take Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Section toggle buttons ─────────────────────────────────────
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSectionButton(id: 'history', label: 'Order History'),
              const SizedBox(width: 5),
              _buildSectionButton(id: 'funnel', label: 'Order Funnel'),
              const SizedBox(width: 5),
              _buildSectionButton(id: 'transaction', label: 'Transaction'),
            ],
          ),

          // Expanded body section
          if (_expandedSection != null) _buildExpandedBody(),
        ],
      ),
    );
  }
}
