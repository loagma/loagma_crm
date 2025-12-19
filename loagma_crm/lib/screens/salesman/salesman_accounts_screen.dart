import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/api_config.dart';
import '../../services/user_service.dart';
import '../../services/pincode_service.dart';

class SalesmanAccountsScreen extends StatefulWidget {
  const SalesmanAccountsScreen({super.key});

  @override
  State<SalesmanAccountsScreen> createState() => _SalesmanAccountsScreenState();
}

class _SalesmanAccountsScreenState extends State<SalesmanAccountsScreen> {
  List<Map<String, dynamic>> accounts = [];
  bool isLoading = true;
  String searchQuery = '';

  // Filter states
  String? selectedStage;
  String? selectedBusinessType;
  String? selectedBusinessSize;
  String? selectedFunnelStage;
  String? selectedCity;
  String? selectedPincode;
  bool? selectedApprovalStatus;
  bool? selectedActiveStatus;
  bool isFilterExpanded = false;

  // Date filter states
  DateTime? selectedFromDate;
  DateTime? selectedToDate;

  @override
  void initState() {
    super.initState();
    fetchMyAccounts();
  }

  List<String> get availableBusinessTypes {
    final types = accounts
        .map((a) => a['businessType']?.toString())
        .where((type) => type != null && type.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    types.sort();
    return types;
  }

  List<String> get availableBusinessSizes {
    final sizes = accounts
        .map((a) => a['businessSize']?.toString())
        .where((size) => size != null && size.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    sizes.sort();
    return sizes;
  }

  List<String> get availableFunnelStages {
    final stages = accounts
        .map((a) => a['funnelStage']?.toString())
        .where((stage) => stage != null && stage.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    stages.sort();
    return stages;
  }

  List<String> get availableCities {
    final cities = accounts
        .map((a) => a['city']?.toString())
        .where((city) => city != null && city.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    cities.sort();
    return cities;
  }

  List<String> get availablePincodes {
    final pincodes = accounts
        .map((a) => a['pincode']?.toString())
        .where((pincode) => pincode != null && pincode.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    pincodes.sort();
    return pincodes;
  }

  Future<void> fetchMyAccounts() async {
    setState(() => isLoading = true);

    try {
      final userId = UserService.currentUserId;

      print('🔍 Fetching accounts for user: $userId');

      if (userId == null || userId.isEmpty) {
        print('❌ User ID is null or empty');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: User not logged in'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/accounts?createdById=$userId',
      );

      print('📡 Fetching from: $url');

      final response = await http.get(url);

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final accountsList = List<Map<String, dynamic>>.from(
          data['data'] ?? [],
        );
        print('✅ Fetched ${accountsList.length} accounts');

        setState(() {
          accounts = accountsList;
        });
      } else {
        print('❌ API returned success: false');
        print('   Message: ${data['message']}');
      }
    } catch (e, stackTrace) {
      print('❌ Error fetching accounts: $e');
      print('❌ Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading accounts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredAccounts {
    return accounts.where((account) {
      final matchesSearch =
          searchQuery.isEmpty ||
          account['personName']?.toString().toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ==
              true ||
          account['businessName']?.toString().toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ==
              true ||
          account['contactNumber']?.toString().contains(searchQuery) == true ||
          account['accountCode']?.toString().toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ==
              true;

      final matchesStage =
          selectedStage == null || account['customerStage'] == selectedStage;

      final matchesBusinessType =
          selectedBusinessType == null ||
          account['businessType'] == selectedBusinessType;

      final matchesBusinessSize =
          selectedBusinessSize == null ||
          account['businessSize'] == selectedBusinessSize;

      final matchesFunnelStage =
          selectedFunnelStage == null ||
          account['funnelStage'] == selectedFunnelStage;

      final matchesCity =
          selectedCity == null || account['city'] == selectedCity;

      final matchesPincode =
          selectedPincode == null || account['pincode'] == selectedPincode;

      final matchesApproval =
          selectedApprovalStatus == null ||
          account['isApproved'] == selectedApprovalStatus;

      final matchesActive =
          selectedActiveStatus == null ||
          account['isActive'] == selectedActiveStatus;

      // Date filter logic
      bool matchesDateRange = true;
      if (selectedFromDate != null || selectedToDate != null) {
        final createdAtStr = account['createdAt']?.toString();
        if (createdAtStr != null) {
          try {
            final createdAt = DateTime.parse(createdAtStr);
            final createdDate = DateTime(
              createdAt.year,
              createdAt.month,
              createdAt.day,
            );

            if (selectedFromDate != null) {
              final fromDate = DateTime(
                selectedFromDate!.year,
                selectedFromDate!.month,
                selectedFromDate!.day,
              );
              if (createdDate.isBefore(fromDate)) {
                matchesDateRange = false;
              }
            }

            if (selectedToDate != null && matchesDateRange) {
              final toDate = DateTime(
                selectedToDate!.year,
                selectedToDate!.month,
                selectedToDate!.day,
              );
              if (createdDate.isAfter(toDate)) {
                matchesDateRange = false;
              }
            }
          } catch (e) {
            // If date parsing fails, exclude from results when date filter is active
            matchesDateRange = false;
          }
        } else {
          // If no createdAt field, exclude from results when date filter is active
          matchesDateRange = false;
        }
      }

      return matchesSearch &&
          matchesStage &&
          matchesBusinessType &&
          matchesBusinessSize &&
          matchesFunnelStage &&
          matchesCity &&
          matchesPincode &&
          matchesApproval &&
          matchesActive &&
          matchesDateRange;
    }).toList();
  }

  int get activeFilterCount {
    int count = 0;
    if (selectedStage != null) count++;
    if (selectedBusinessType != null) count++;
    if (selectedBusinessSize != null) count++;
    if (selectedFunnelStage != null) count++;
    if (selectedCity != null) count++;
    if (selectedPincode != null) count++;
    if (selectedApprovalStatus != null) count++;
    if (selectedActiveStatus != null) count++;
    if (selectedFromDate != null || selectedToDate != null) count++;
    return count;
  }

  void clearAllFilters() {
    setState(() {
      selectedStage = null;
      selectedBusinessType = null;
      selectedBusinessSize = null;
      selectedFunnelStage = null;
      selectedCity = null;
      selectedPincode = null;
      selectedApprovalStatus = null;
      selectedActiveStatus = null;
      selectedFromDate = null;
      selectedToDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredAccounts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lists of Accounts'),
        backgroundColor: const Color(0xFFD7BE69),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchMyAccounts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Compact Search and Filter Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search accounts...',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 20),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                        onChanged: (value) {
                          setState(() => searchQuery = value);
                        },
                      ),
                      const SizedBox(height: 8),

                      // Filter Toggle and Stats Row
                      Row(
                        children: [
                          // Filter Toggle Button
                          InkWell(
                            onTap: () {
                              setState(() {
                                isFilterExpanded = !isFilterExpanded;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: activeFilterCount > 0
                                    ? const Color(0xFFD7BE69)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: activeFilterCount > 0
                                      ? const Color(0xFFD7BE69)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    size: 16,
                                    color: activeFilterCount > 0
                                        ? Colors.white
                                        : Colors.grey[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Filters',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: activeFilterCount > 0
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  if (activeFilterCount > 0) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        activeFilterCount.toString(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFD7BE69),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 2),
                                  Icon(
                                    isFilterExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 18,
                                    color: activeFilterCount > 0
                                        ? Colors.white
                                        : Colors.grey[700],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Compact Stats
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFD7BE69,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFD7BE69,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildCompactStat(
                                      filteredAccounts.length.toString(),
                                      'Showing',
                                    ),
                                    Container(
                                      width: 1,
                                      height: 20,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      color: Colors.grey[300],
                                    ),
                                    _buildCompactStat(
                                      accounts.length.toString(),
                                      'Total',
                                    ),
                                    Container(
                                      width: 1,
                                      height: 20,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      color: Colors.grey[300],
                                    ),
                                    _buildCompactStat(
                                      accounts
                                          .where((a) => a['isApproved'] == true)
                                          .length
                                          .toString(),
                                      'Approved',
                                      Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Collapsible Filter Section
                if (isFilterExpanded)
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Clear Filters Button
                        if (activeFilterCount > 0)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: clearAllFilters,
                              icon: const Icon(Icons.clear_all, size: 16),
                              label: const Text('Clear All'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),

                        // Customer Stage Filter
                        Text(
                          'Customer Stage',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildFilterChip('All', null, 'stage'),
                            _buildFilterChip('Lead', 'Lead', 'stage'),
                            _buildFilterChip('Prospect', 'Prospect', 'stage'),
                            _buildFilterChip('Customer', 'Customer', 'stage'),
                            _buildFilterChip('Inactive', 'Inactive', 'stage'),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Funnel Stage Filter
                        if (availableFunnelStages.isNotEmpty) ...[
                          Text(
                            'Funnel Stage',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildFilterChip('All', null, 'funnelStage'),
                              ...availableFunnelStages.map(
                                (stage) => _buildFilterChip(
                                  stage,
                                  stage,
                                  'funnelStage',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Business Type Filter
                        Text(
                          'Business Type',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 6),
                        availableBusinessTypes.isEmpty
                            ? Text(
                                'No business types available',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildFilterChip('All', null, 'businessType'),
                                  ...availableBusinessTypes.map(
                                    (type) => _buildFilterChip(
                                      type,
                                      type,
                                      'businessType',
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 12),

                        // Business Size Filter
                        if (availableBusinessSizes.isNotEmpty) ...[
                          Text(
                            'Business Size',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildFilterChip('All', null, 'businessSize'),
                              ...availableBusinessSizes.map(
                                (size) => _buildFilterChip(
                                  size,
                                  size,
                                  'businessSize',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // City Filter
                        if (availableCities.isNotEmpty) ...[
                          Text(
                            'City',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildFilterChip('All', null, 'city'),
                              ...availableCities
                                  .take(10)
                                  .map(
                                    (city) =>
                                        _buildFilterChip(city, city, 'city'),
                                  ),
                              if (availableCities.length > 10)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    '+${availableCities.length - 10} more',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Pincode Filter
                        if (availablePincodes.isNotEmpty) ...[
                          Text(
                            'Pincode',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildFilterChip('All', null, 'pincode'),
                              ...availablePincodes
                                  .take(10)
                                  .map(
                                    (pincode) => _buildFilterChip(
                                      pincode,
                                      pincode,
                                      'pincode',
                                    ),
                                  ),
                              if (availablePincodes.length > 10)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    '+${availablePincodes.length - 10} more',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Approval Status Filter
                        Text(
                          'Approval Status',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildApprovalFilterChip('All', null),
                            _buildApprovalFilterChip('Approved', true),
                            _buildApprovalFilterChip('Pending', false),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Active Status Filter
                        Text(
                          'Active Status',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildActiveFilterChip('All', null),
                            _buildActiveFilterChip('Active', true),
                            _buildActiveFilterChip('Inactive', false),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Date Range Filter
                        Text(
                          'Created Date Range',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateFilterButton(
                                'From Date',
                                selectedFromDate,
                                (date) =>
                                    setState(() => selectedFromDate = date),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDateFilterButton(
                                'To Date',
                                selectedToDate,
                                (date) => setState(() => selectedToDate = date),
                              ),
                            ),
                          ],
                        ),
                        if (selectedFromDate != null ||
                            selectedToDate != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getDateRangeText(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    selectedFromDate = null;
                                    selectedToDate = null;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Clear Dates',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Accounts List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD7BE69)),
                  )
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? 'No accounts created yet'
                              : 'No accounts found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchMyAccounts,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final account = filtered[index];
                        return _buildAccountCard(account);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String value, String label, [Color? color]) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color ?? const Color(0xFFD7BE69),
          ),
        ),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? value, String filterType) {
    bool isSelected = false;
    switch (filterType) {
      case 'stage':
        isSelected = selectedStage == value;
        break;
      case 'businessType':
        isSelected = selectedBusinessType == value;
        break;
      case 'businessSize':
        isSelected = selectedBusinessSize == value;
        break;
      case 'funnelStage':
        isSelected = selectedFunnelStage == value;
        break;
      case 'city':
        isSelected = selectedCity == value;
        break;
      case 'pincode':
        isSelected = selectedPincode == value;
        break;
    }

    return InkWell(
      onTap: () {
        setState(() {
          switch (filterType) {
            case 'stage':
              selectedStage = value;
              break;
            case 'businessType':
              selectedBusinessType = value;
              break;
            case 'businessSize':
              selectedBusinessSize = value;
              break;
            case 'funnelStage':
              selectedFunnelStage = value;
              break;
            case 'city':
              selectedCity = value;
              break;
            case 'pincode':
              selectedPincode = value;
              break;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD7BE69) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFD7BE69) : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, bool? value) {
    final isSelected = selectedActiveStatus == value;
    Color chipColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    Color textColor = Colors.grey[700]!;

    if (isSelected) {
      if (value == true) {
        chipColor = Colors.blue;
        borderColor = Colors.blue;
        textColor = Colors.white;
      } else if (value == false) {
        chipColor = Colors.grey;
        borderColor = Colors.grey;
        textColor = Colors.white;
      } else {
        chipColor = const Color(0xFFD7BE69);
        borderColor = const Color(0xFFD7BE69);
        textColor = Colors.white;
      }
    }

    return InkWell(
      onTap: () {
        setState(() {
          selectedActiveStatus = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected && value != null)
              Icon(
                value ? Icons.check_circle : Icons.cancel,
                size: 12,
                color: textColor,
              ),
            if (isSelected && value != null) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalFilterChip(String label, bool? value) {
    final isSelected = selectedApprovalStatus == value;
    Color chipColor = Colors.white;
    Color borderColor = Colors.grey[300]!;
    Color textColor = Colors.grey[700]!;

    if (isSelected) {
      if (value == true) {
        chipColor = Colors.green;
        borderColor = Colors.green;
        textColor = Colors.white;
      } else if (value == false) {
        chipColor = Colors.orange;
        borderColor = Colors.orange;
        textColor = Colors.white;
      } else {
        chipColor = const Color(0xFFD7BE69);
        borderColor = const Color(0xFFD7BE69);
        textColor = Colors.white;
      }
    }

    return InkWell(
      onTap: () {
        setState(() {
          selectedApprovalStatus = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected && value != null)
              Icon(
                value ? Icons.check_circle : Icons.schedule,
                size: 12,
                color: textColor,
              ),
            if (isSelected && value != null) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterButton(
    String label,
    DateTime? selectedDate,
    Function(DateTime?) onDateSelected,
  ) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(
                  context,
                ).colorScheme.copyWith(primary: const Color(0xFFD7BE69)),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selectedDate != null
              ? const Color(0xFFD7BE69).withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedDate != null
                ? const Color(0xFFD7BE69)
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: selectedDate != null
                  ? const Color(0xFFD7BE69)
                  : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                selectedDate != null
                    ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                    : label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selectedDate != null
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: selectedDate != null
                      ? const Color(0xFFD7BE69)
                      : Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDateRangeText() {
    if (selectedFromDate != null && selectedToDate != null) {
      return 'From ${selectedFromDate!.day}/${selectedFromDate!.month}/${selectedFromDate!.year} to ${selectedToDate!.day}/${selectedToDate!.month}/${selectedToDate!.year}';
    } else if (selectedFromDate != null) {
      return 'From ${selectedFromDate!.day}/${selectedFromDate!.month}/${selectedFromDate!.year}';
    } else if (selectedToDate != null) {
      return 'Up to ${selectedToDate!.day}/${selectedToDate!.month}/${selectedToDate!.year}';
    }
    return '';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Clean the phone number (remove spaces, dashes, etc.)
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid phone number'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final Uri phoneUri = Uri.parse('tel:$cleanNumber');

    try {
      // Launch directly without checking canLaunchUrl
      // This works better on Android devices
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error launching phone: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open phone dialer'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _editAccount(Map<String, dynamic> account) {
    // Show edit form in a bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _EditAccountForm(
          account: account,
          onSave: (updatedAccount) {
            _updateAccount(updatedAccount);
            Navigator.pop(context);
          },
          scrollController: scrollController,
        ),
      ),
    );
  }

  Future<void> _updateAccount(Map<String, dynamic> updatedAccount) async {
    try {
      final accountId = updatedAccount['id'];
      if (accountId == null) {
        throw Exception('Account ID is missing');
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/accounts/$accountId');

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedAccount),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        // Update the local accounts list
        setState(() {
          final index = accounts.indexWhere((a) => a['id'] == accountId);
          if (index != -1) {
            accounts[index] = {...accounts[index], ...updatedAccount};
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to update account');
      }
    } catch (e) {
      print('❌ Error updating account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewAccountDetails(Map<String, dynamic> account) {
    // Show account details in a bottom sheet instead of navigating
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account['personName'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (account['businessName'] != null)
                          Text(
                            account['businessName'],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 30),

              // Details
              _buildDetailRow(
                Icons.phone,
                'Contact',
                account['contactNumber'] ?? 'N/A',
              ),
              _buildDetailRow(
                Icons.code,
                'Account Code',
                account['accountCode'] ?? 'N/A',
              ),
              _buildDetailRow(
                Icons.flag,
                'Stage',
                account['customerStage'] ?? 'N/A',
              ),
              _buildDetailRow(
                Icons.business,
                'Business Type',
                account['businessType'] ?? 'N/A',
              ),
              if (account['address'] != null)
                _buildDetailRow(
                  Icons.location_on,
                  'Address',
                  account['address'],
                ),
              if (account['pincode'] != null)
                _buildDetailRow(Icons.pin_drop, 'Pincode', account['pincode']),
              _buildDetailRow(
                Icons.check_circle,
                'Status',
                account['isApproved'] == true ? 'Approved' : 'Pending',
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        if (account['contactNumber'] != null) {
                          _makePhoneCall(account['contactNumber']);
                        }
                      },
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFD7BE69)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    final hasPhone =
        account['contactNumber'] != null &&
        account['contactNumber'].toString().isNotEmpty;

    // Professional color scheme
    const primaryGold = Color(0xFFD7BE69);
    const callGreen = Color(0xFF059669);
    const textDark = Color(0xFF1F2937);
    const textMuted = Color(0xFF6B7280);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        onTap: () => _viewAccountDetails(account),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryGold.withOpacity(0.2),
                          primaryGold.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: primaryGold.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (account['personName'] ?? 'N')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryGold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account['personName'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (account['businessName'] != null)
                          Text(
                            account['businessName'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Action Buttons Row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit Button
                      Container(
                        decoration: BoxDecoration(
                          color: primaryGold,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primaryGold.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _editAccount(account),
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Call Button
                      if (hasPhone)
                        Container(
                          decoration: BoxDecoration(
                            color: callGreen,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: callGreen.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  _makePhoneCall(account['contactNumber']),
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(12),
                                child: Icon(
                                  Icons.call,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Divider
              Container(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 16),

              // Info Section
              Column(
                children: [
                  // Phone Number
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.phone_rounded,
                          size: 18,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact Number',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              account['contactNumber'] ?? 'N/A',
                              style: const TextStyle(
                                color: textDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Account Code & Stage
                  Row(
                    children: [
                      // Account Code
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.badge_rounded,
                                size: 18,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Code',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    account['accountCode'] ?? 'N/A',
                                    style: const TextStyle(
                                      color: textDark,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Customer Stage
                      if (account['customerStage'] != null)
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryGold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.flag_rounded,
                                  size: 18,
                                  color: primaryGold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Stage',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      account['customerStage'],
                                      style: const TextStyle(
                                        color: primaryGold,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditAccountForm extends StatefulWidget {
  final Map<String, dynamic> account;
  final Function(Map<String, dynamic>) onSave;
  final ScrollController scrollController;

  const _EditAccountForm({
    required this.account,
    required this.onSave,
    required this.scrollController,
  });

  @override
  State<_EditAccountForm> createState() => _EditAccountFormState();
}

class _EditAccountFormState extends State<_EditAccountForm> {
  final _formKey = GlobalKey<FormState>();
  bool isSubmitting = false;
  bool isLoadingLocation = false;
  bool isLoadingAreas = false;
  bool isLoadingGeolocation = false;

  // Controllers
  late TextEditingController _businessNameController;
  late TextEditingController _personNameController;
  late TextEditingController _contactNumberController;
  late TextEditingController _gstNumberController;
  late TextEditingController _panCardController;
  late TextEditingController _pincodeController;
  late TextEditingController _countryController;
  late TextEditingController _stateController;
  late TextEditingController _districtController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  late TextEditingController _areaController;

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

  // Images
  String? _ownerImageBase64;
  String? _shopImageBase64;
  File? _ownerImageFile;
  File? _shopImageFile;

  // Areas list
  List<Map<String, dynamic>> _availableAreas = [];

  final ImagePicker _picker = ImagePicker();

  // Business Type options
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

  // Business Size options
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

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize controllers with existing account data
    _businessNameController = TextEditingController(
      text: widget.account['businessName'] ?? '',
    );
    _personNameController = TextEditingController(
      text: widget.account['personName'] ?? '',
    );
    _contactNumberController = TextEditingController(
      text: widget.account['contactNumber'] ?? '',
    );
    _gstNumberController = TextEditingController(
      text: widget.account['gstNumber'] ?? '',
    );
    _panCardController = TextEditingController(
      text: widget.account['panCard'] ?? '',
    );
    _pincodeController = TextEditingController(
      text: widget.account['pincode'] ?? '',
    );
    _countryController = TextEditingController(
      text: widget.account['country'] ?? '',
    );
    _stateController = TextEditingController(
      text: widget.account['state'] ?? '',
    );
    _districtController = TextEditingController(
      text: widget.account['district'] ?? '',
    );
    _cityController = TextEditingController(text: widget.account['city'] ?? '');
    _areaController = TextEditingController(text: widget.account['area'] ?? '');
    _addressController = TextEditingController(
      text: widget.account['address'] ?? '',
    );

    // Only set dropdown values if they exist in our predefined lists
    final accountBusinessType = widget.account['businessType']?.toString();
    _selectedBusinessType = _businessTypes.contains(accountBusinessType)
        ? accountBusinessType
        : null;

    final accountBusinessSize = widget.account['businessSize']?.toString();
    _selectedBusinessSize = _businessSizes.contains(accountBusinessSize)
        ? accountBusinessSize
        : null;

    final accountCustomerStage = widget.account['customerStage']?.toString();
    _selectedCustomerStage = _customerStages.contains(accountCustomerStage)
        ? accountCustomerStage
        : null;

    final accountFunnelStage = widget.account['funnelStage']?.toString();
    _selectedFunnelStage = _funnelStages.contains(accountFunnelStage)
        ? accountFunnelStage
        : null;

    // Parse date of birth if available
    if (widget.account['dateOfBirth'] != null) {
      try {
        _dateOfBirth = DateTime.parse(widget.account['dateOfBirth']);
      } catch (e) {
        _dateOfBirth = null;
      }
    }

    _isActive = widget.account['isActive'] ?? true;

    _selectedArea = widget.account['area'];

    // Load existing geolocation
    _latitude = widget.account['latitude']?.toDouble();
    _longitude = widget.account['longitude']?.toDouble();

    // Load existing images if available
    _ownerImageBase64 = widget.account['ownerImage'];
    _shopImageBase64 = widget.account['shopImage'];

    // Load areas if pincode exists
    if (widget.account['pincode'] != null &&
        widget.account['pincode']!.isNotEmpty) {
      _loadAreasForPincode(widget.account['pincode']!);
    }
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
    _areaController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveAccount() {
    if (_formKey.currentState!.validate()) {
      setState(() => isSubmitting = true);

      final updatedAccount = {
        'id': widget.account['id'],
        'businessName': _businessNameController.text.trim(),
        'personName': _personNameController.text.trim(),
        'contactNumber': _contactNumberController.text.trim(),
        'businessType': _selectedBusinessType,
        'businessSize': _selectedBusinessSize,
        'customerStage': _selectedCustomerStage,
        'funnelStage': _selectedFunnelStage,
        'gstNumber': _gstNumberController.text.trim().toUpperCase(),
        'panCard': _panCardController.text.trim().toUpperCase(),
        'pincode': _pincodeController.text.trim(),
        'country': _countryController.text.trim(),
        'state': _stateController.text.trim(),
        'district': _districtController.text.trim(),
        'city': _cityController.text.trim(),
        'area': _selectedArea,
        'address': _addressController.text.trim(),
        'dateOfBirth': _dateOfBirth?.toIso8601String(),
        'isActive': _isActive,
        'latitude': _latitude,
        'longitude': _longitude,
        'ownerImage': _ownerImageBase64,
        'shopImage': _shopImageBase64,
      };

      widget.onSave(updatedAccount);
    }
  }

  Future<void> _loadAreasForPincode(String pincode) async {
    try {
      final result = await PincodeService.getAreasByPincode(pincode);
      if (result['success'] == true && mounted) {
        final data = result['data'];
        setState(() {
          final areasData = data['areas'] ?? [];
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
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _pickImage(bool isOwnerImage, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);

        setState(() {
          if (isOwnerImage) {
            if (!kIsWeb) _ownerImageFile = File(image.path);
            _ownerImageBase64 = 'data:image/jpeg;base64,$base64Image';
          } else {
            if (!kIsWeb) _shopImageFile = File(image.path);
            _shopImageBase64 = 'data:image/jpeg;base64,$base64Image';
          }
        });

        _showSuccess(
          isOwnerImage ? 'Shop Owner image updated' : 'Shop Image updated',
        );
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _showImageSourceDialog(bool isOwnerImage) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Image Source',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFD7BE69)),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(isOwnerImage, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFFD7BE69),
                ),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(isOwnerImage, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _lookupPincode() async {
    final pincode = _pincodeController.text.trim();

    if (pincode.isEmpty) {
      _showError('Please enter pincode');
      return;
    }

    if (!PincodeService.isValidPincode(pincode)) {
      _showError('Pincode must be exactly 6 digits');
      return;
    }

    setState(() {
      isLoadingLocation = true;
      isLoadingAreas = true;
    });

    try {
      final result = await PincodeService.getAreasByPincode(pincode);

      if (result['success'] == true) {
        final data = result['data'];
        setState(() {
          _countryController.text = data['country'] ?? '';
          _stateController.text = data['state'] ?? '';
          _districtController.text = data['district'] ?? '';
          _cityController.text = data['city'] ?? '';

          final areasData = data['areas'] ?? [];
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
          _selectedArea = null;
        });
        _showSuccess('Location details fetched successfully');
      } else {
        _showError(result['message'] ?? 'Failed to fetch location');
        setState(() {
          _availableAreas = [];
          _selectedArea = null;
        });
      }
    } catch (e) {
      _showError('Error: $e');
      setState(() {
        _availableAreas = [];
        _selectedArea = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoadingLocation = false;
          isLoadingAreas = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLoadingGeolocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled');
        setState(() => isLoadingGeolocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied');
          setState(() => isLoadingGeolocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions are permanently denied');
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

      _showSuccess(
        'Location captured: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
      );
    } catch (e) {
      _showError('Failed to get location: $e');
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
        _showError('Could not open Google Maps');
      }
    } catch (e) {
      _showError('Error opening Google Maps: $e');
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Edit Account Master',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 30),

            // Business Information Section
            _buildSectionHeader('Business Information', Icons.business),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _businessNameController,
              label: 'Business Name *',
              icon: Icons.store,
              hint: 'Enter business name',
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Business name is required' : null,
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              value: _selectedBusinessType,
              label: 'Business Type *',
              icon: Icons.category,
              items: _businessTypes,
              onChanged: (v) => setState(() => _selectedBusinessType = v),
              validator: (v) => v == null ? 'Business type is required' : null,
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              value: _selectedBusinessSize,
              label: 'Business Size *',
              icon: Icons.business_center,
              items: _businessSizes,
              onChanged: (v) => setState(() => _selectedBusinessSize = v),
              validator: (v) => v == null ? 'Business size is required' : null,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _personNameController,
              label: 'Person Name *',
              icon: Icons.person,
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Person name is required' : null,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _contactNumberController,
              label: 'Contact Number *',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Contact number is required';
                if (v!.length != 10) return 'Must be 10 digits';
                return null;
              },
            ),
            const SizedBox(height: 15),

            // Date of Birth
            ListTile(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              leading: const Icon(Icons.cake, color: Color(0xFFD7BE69)),
              title: const Text("Date of Birth"),
              subtitle: Text(
                _dateOfBirth == null
                    ? "Tap to select"
                    : "${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}",
              ),
              trailing: _dateOfBirth != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: () {
                        setState(() => _dateOfBirth = null);
                      },
                    )
                  : const Icon(Icons.calendar_today),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _dateOfBirth ?? DateTime(2000),
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
                  setState(() => _dateOfBirth = picked);
                }
              },
            ),
            const SizedBox(height: 15),

            _buildDropdown(
              value: _selectedCustomerStage,
              label: 'Customer Stage *',
              icon: Icons.stairs,
              items: _customerStages,
              onChanged: (v) => setState(() => _selectedCustomerStage = v),
              validator: (v) => v == null ? 'Customer stage is required' : null,
            ),
            const SizedBox(height: 15),
            _buildDropdown(
              value: _selectedFunnelStage,
              label: 'Funnel Stage *',
              icon: Icons.filter_list,
              items: _funnelStages,
              onChanged: (v) => setState(() => _selectedFunnelStage = v),
              validator: (v) => v == null ? 'Funnel stage is required' : null,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _gstNumberController,
              label: 'GST Number',
              icon: Icons.receipt_long,
              hint: '22AAAAA0000A1Z5',
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _panCardController,
              label: 'PAN Card',
              icon: Icons.credit_card,
              hint: 'ABCDE1234F',
              textCapitalization: TextCapitalization.characters,
              maxLength: 10,
            ),
            const SizedBox(height: 25),

            // Images Section
            _buildSectionHeader('Images', Icons.image),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildImagePicker(
                    label: 'Shop Owner *',
                    imageFile: _ownerImageFile,
                    imageBase64: _ownerImageBase64,
                    onTap: () => _showImageSourceDialog(true),
                    isRequired: true,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildImagePicker(
                    label: 'Shop Image *',
                    imageFile: _shopImageFile,
                    imageBase64: _shopImageBase64,
                    onTap: () => _showImageSourceDialog(false),
                    isRequired: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Status Section
            _buildSectionHeader('Status', Icons.toggle_on),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('Active Status'),
              subtitle: Text(_isActive ? 'Active' : 'Inactive'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              activeThumbColor: const Color(0xFFD7BE69),
              secondary: Icon(
                _isActive ? Icons.check_circle : Icons.cancel,
                color: _isActive ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 25),

            // Location Details Section
            _buildSectionHeader('Location Details', Icons.location_on),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _pincodeController,
                    label: 'Pincode *',
                    icon: Icons.pin_drop,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    hint: '400001',
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Pincode is required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: isLoadingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.search, size: 20),
                    label: const Text('Lookup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7BE69),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: isLoadingLocation ? null : _lookupPincode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _countryController,
              label: 'Country',
              icon: Icons.public,
              readOnly: true,
              filled: true,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _stateController,
              label: 'State',
              icon: Icons.map,
              readOnly: true,
              filled: true,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _districtController,
              label: 'District',
              icon: Icons.location_city,
              readOnly: true,
              filled: true,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              controller: _cityController,
              label: 'City',
              icon: Icons.apartment,
              readOnly: true,
              filled: true,
            ),
            const SizedBox(height: 15),
            // Area Dropdown (if areas available)
            if (_availableAreas.isNotEmpty)
              Column(
                children: [
                  _buildDropdown(
                    value: _selectedArea,
                    label: 'Area *',
                    icon: Icons.place,
                    items: _availableAreas
                        .map((a) => a['name'] as String)
                        .toList(),
                    onChanged: (v) => setState(() => _selectedArea = v),
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
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  'No areas found for this pincode',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            _buildTextField(
              controller: _addressController,
              label: 'Enter Main Area *',
              icon: Icons.home,
              maxLines: 3,
              hint: 'Enter complete address manually',
              validator: (v) =>
                  v?.isEmpty ?? true ? 'Address is required' : null,
            ),
            const SizedBox(height: 25),
            // Geolocation Section
            _buildSectionHeader('Geolocation *', Icons.my_location),
            const SizedBox(height: 15),
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
                            style: TextStyle(fontWeight: FontWeight.bold),
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
              onPressed: isLoadingGeolocation ? null : _getCurrentLocation,
            ),
            // Google Map Display
            if (_latitude != null && _longitude != null) ...[
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
                          target: LatLng(_latitude!, _longitude!),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('account_location'),
                            position: LatLng(_latitude!, _longitude!),
                            infoWindow: InfoWindow(
                              title: widget.account['personName'] ?? 'Account',
                              snippet: widget.account['businessName'],
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
            const SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(isSubmitting ? 'Updating...' : 'Update'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD7BE69),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isSubmitting ? null : _saveAccount,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD7BE69),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: Color(0xFFD7BE69)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD7BE69).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD7BE69).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD7BE69)),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD7BE69),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    int? maxLines,
    String? hint,
    String? Function(String?)? validator,
    bool readOnly = false,
    bool filled = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: maxLines ?? 1,
      readOnly: readOnly,
      enabled: true,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFFD7BE69)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD7BE69), width: 2),
        ),
        filled: filled,
        fillColor: filled ? Colors.grey[100] : null,
        counterText: maxLength != null ? '' : null,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    // Ensure the value is either null or exists in the items list
    final validValue = (value != null && items.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      value: validValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFD7BE69)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD7BE69), width: 2),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildImagePicker({
    required String label,
    required File? imageFile,
    required String? imageBase64,
    required VoidCallback onTap,
    bool isRequired = false,
  }) {
    final hasImage = (imageFile != null && !kIsWeb) || (imageBase64 != null);

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(
            color: isRequired && !hasImage
                ? Colors.red
                : const Color(0xFFD7BE69),
            width: isRequired && !hasImage ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[50],
        ),
        child: (imageFile != null && !kIsWeb)
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: onTap,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              )
            : (imageBase64 != null && kIsWeb)
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      base64Decode(imageBase64.split(',')[1]),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: onTap,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 40,
                    color: isRequired && !hasImage
                        ? Colors.red
                        : const Color(0xFFD7BE69),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isRequired && !hasImage
                          ? Colors.red
                          : const Color(0xFFD7BE69),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.photo_library,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to select',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
