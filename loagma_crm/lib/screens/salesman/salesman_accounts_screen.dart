import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_config.dart';
import '../../services/user_service.dart';

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
                    ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
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

  void _editAccount(Map<String, dynamic> account) async {
    // Navigate to existing edit account master screen
    final accountId = account['id']?.toString();

    print('🔍 Navigating to edit account:');
    print('   Account ID: $accountId');
    print('   Person Name: ${account['personName']}');
    print('   Current User: ${UserService.currentUserId}');
    print('   Current Role: ${UserService.currentRole}');

    if (accountId != null) {
      // Navigate to existing edit account master screen
      final result = await context.push('/account/edit/$accountId');

      // Refresh the accounts list when returning from edit
      if (result == true || result == null) {
        fetchMyAccounts();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account ID not found'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewAccountDetails(Map<String, dynamic> account) {
    // Navigate to account detail screen
    final accountId = account['id']?.toString();

    print('🔍 Navigating to account details:');
    print('   Account ID: $accountId');
    print('   Person Name: ${account['personName']}');
    print('   Created By: ${account['createdById']}');
    print('   Current User: ${UserService.currentUserId}');
    print('   Current Role: ${UserService.currentRole}');

    if (accountId != null) {
      context.push('/account/$accountId');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account ID not found'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                          account['businessName'],
                          style: const TextStyle(
                            fontSize: 17,
                            color: textDark,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),
                        if (account['businessName'] != null)
                          Text(
                            account['personName'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w300,
                              color: textMuted,
                              letterSpacing: -0.3,
                            ),
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
