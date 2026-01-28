import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../../models/account_model.dart';
import '../../services/account_service.dart';
import '../../services/user_service.dart';
import '../../services/network_service.dart';
import 'edit_account_master_screen.dart';

class AccountListScreen extends StatefulWidget {
  /// When true, this screen will show only telecaller‑approved
  /// accounts by default (used for the Admin "Customer List" panel).
  final bool onlyApproved;

  /// Optional custom title for the AppBar. Falls back to "Accounts".
  final String? appBarTitle;

  const AccountListScreen({
    super.key,
    this.onlyApproved = false,
    this.appBarTitle,
  });

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  List<Account> _accounts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _searchQuery;
  String? _filterCustomerStage;
  bool? _filterIsApproved;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String? _filterSalesmanId;
  String? _filterDatePreset; // 'today', 'yesterday', 'custom'
  List<Map<String, dynamic>> _salesmen = [];
  bool _hasNetworkError = false;
  String? _lastErrorMessage;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  // Determines whether we should pass createdBy filter (non-admin)
  bool get _shouldFilterByOwner {
    final role = UserService.currentRole?.toLowerCase();
    return role != null && role != 'admin';
  }

  String? get _currentUserId => UserService.currentUserId;

  @override
  void initState() {
    super.initState();
    // If this screen is opened in "Customer List" mode for Admin,
    // pre‑apply filters so that only telecaller‑verified AND
    // admin‑approved customers are shown by default.
    if (widget.onlyApproved) {
      _filterIsApproved = true;
      _filterCustomerStage = 'Customer';
    }

    _scrollController.addListener(_onScroll);
    // Use post frame callback to avoid blocking initial render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _showNetworkErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Network Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_lastErrorMessage ?? 'Unable to connect to server'),
            SizedBox(height: 16),
            Text(
              'Troubleshooting tips:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Check your internet connection'),
            Text('• Wait 30-60 seconds if using free hosting'),
            Text('• Try refreshing the page'),
            Text('• Contact support if problem persists'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _retryConnection();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFD7BE69),
              foregroundColor: Colors.white,
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _retryConnection() async {
    setState(() {
      _hasNetworkError = false;
      _lastErrorMessage = null;
    });
    await _refreshAccounts();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      // Clean the phone number more thoroughly
      String cleanNumber = phoneNumber.trim();

      // Remove all non-digit characters except + at the beginning
      cleanNumber = cleanNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // Ensure the number starts with + for international format
      if (!cleanNumber.startsWith('+')) {
        // If it's an Indian number (10 digits), add +91
        if (cleanNumber.length == 10) {
          cleanNumber = '+91$cleanNumber';
        }
        // If it's already 12 digits starting with 91, add +
        else if (cleanNumber.length == 12 && cleanNumber.startsWith('91')) {
          cleanNumber = '+$cleanNumber';
        }
        // For other cases, just add +
        else if (cleanNumber.isNotEmpty && !cleanNumber.startsWith('+')) {
          cleanNumber = '+$cleanNumber';
        }
      }

      print('📞 Attempting to call: $cleanNumber (original: $phoneNumber)');

      final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

      // Try to launch the URL with different modes
      bool launched = false;

      // Try external application mode first
      try {
        launched = await launchUrl(
          phoneUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        print('External app launch failed: $e');
      }

      // If external app failed, try platform default
      if (!launched) {
        try {
          launched = await launchUrl(phoneUri);
        } catch (e) {
          print('Platform default launch failed: $e');
        }
      }

      if (!launched) {
        // Fallback: try with original number
        final Uri fallbackUri = Uri(scheme: 'tel', path: phoneNumber);
        launched = await launchUrl(
          fallbackUri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          _showError(
            'Unable to open phone dialer. Please check if a dialer app is installed.',
          );
        }
      }
    } catch (e) {
      print('❌ Phone call error: $e');
      _showError(
        'Error making phone call. Please try calling manually: $phoneNumber',
      );
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _searchQuery = value.isEmpty ? null : value);
        _refreshAccounts();
      }
    });
  }

  Future<void> _loadInitialData() async {
    // Load data in parallel but don't block UI
    await Future.wait([_loadAccounts(refresh: true), _loadSalesmen()]);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (_currentPage < _totalPages && !_isLoadingMore) {
        _loadMoreAccounts();
      }
    }
  }

  Future<void> _loadAccounts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
      });
    }

    try {
      // Use compute for heavy data processing to avoid blocking main thread
      final result = await _fetchAccountsInBackground();

      if (!mounted) return;

      // result expected: { 'accounts': List<Account>, 'pagination': {'totalPages': n} }
      final fetched = List<Account>.from(result['accounts'] ?? []);
      final pagination = result['pagination'] ?? {'totalPages': 1};

      setState(() {
        if (refresh) {
          _accounts = fetched;
        } else {
          _accounts.addAll(fetched);
        }
        _totalPages = (pagination['totalPages'] as int?) ?? 1;
        _isLoading = false;
        _isLoadingMore = false;
        // Clear network errors on successful load
        _hasNetworkError = false;
        _lastErrorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _hasNetworkError = true;
        _lastErrorMessage = e.toString();
      });
      _showError(e.toString());
    }
  }

  Future<Map<String, dynamic>> _fetchAccountsInBackground() async {
    return await AccountService.fetchAccounts(
      page: _currentPage,
      limit: 20,
      search: _searchQuery,
      // For "Customer List", enforce final customer stage = Customer,
      // otherwise use whatever filter user selected.
      customerStage: widget.onlyApproved ? 'Customer' : _filterCustomerStage,
      // If this screen is used as "Customer List" in admin,
      // hard‑enforce isApproved = true so only verified accounts load.
      isApproved: widget.onlyApproved ? true : _filterIsApproved,
      startDate: _filterStartDate,
      endDate: _filterEndDate,
      // For non-admin users, if no salesman filter is selected, show only their accounts
      // For admin users, show all accounts unless a specific salesman is selected
      createdById:
          _filterSalesmanId ?? (_shouldFilterByOwner ? _currentUserId : null),
    );
  }

  Future<void> _loadMoreAccounts() async {
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _loadAccounts();
  }

  Future<void> _refreshAccounts() async {
    // Clear any previous network errors
    if (_hasNetworkError) {
      setState(() {
        _hasNetworkError = false;
        _lastErrorMessage = null;
      });
    }
    await _loadAccounts(refresh: true);
  }

  Future<void> _loadSalesmen() async {
    try {
      // Check connectivity first
      final isConnected = await NetworkService.checkConnectivity();
      if (!isConnected) {
        if (mounted) {
          setState(() {
            _salesmen = [];
          });
        }
        return;
      }

      // Use a separate isolate or at least add delay to prevent blocking
      await Future.delayed(const Duration(milliseconds: 100));

      final result = await UserService.getAllUsers();

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _salesmen = List<Map<String, dynamic>>.from(result['data'] ?? []);
        });
      } else {
        // Show error message from the service
        if (result['message'] != null) {
          _showError(result['message']);
        }
      }
    } catch (e) {
      // Silently handle error - salesmen dropdown will just be empty
      if (mounted) {
        setState(() {
          _salesmen = [];
        });
      }
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

  Future<void> _deleteAccount(Account account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${account.personName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AccountService.deleteAccount(account.id);
        _showSuccess('Account deleted successfully');
        // refresh first page
        await _refreshAccounts();
      } catch (e) {
        _showError('Failed to delete account: $e');
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? tmpStage = _filterCustomerStage;
        bool? tmpApproved = _filterIsApproved;
        DateTime? tmpStartDate = _filterStartDate;
        DateTime? tmpEndDate = _filterEndDate;
        String? tmpSalesmanId = _filterSalesmanId;
        String? tmpDatePreset = _filterDatePreset;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Helper function to apply date preset
            void applyDatePreset(String preset) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final yesterday = today.subtract(Duration(days: 1));

              setDialogState(() {
                tmpDatePreset = preset;
                switch (preset) {
                  case 'today':
                    tmpStartDate = today;
                    tmpEndDate = today
                        .add(Duration(days: 1))
                        .subtract(Duration(milliseconds: 1));
                    break;
                  case 'yesterday':
                    tmpStartDate = yesterday;
                    tmpEndDate = yesterday
                        .add(Duration(days: 1))
                        .subtract(Duration(milliseconds: 1));
                    break;
                  case 'custom':
                    // Keep existing dates or clear them
                    if (tmpDatePreset != 'custom') {
                      tmpStartDate = null;
                      tmpEndDate = null;
                    }
                    break;
                }
              });
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.filter_list, color: Color(0xFFD7BE69)),
                  SizedBox(width: 8),
                  Text('Filter Accounts'),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: widget.onlyApproved
                            ? 'Customer'
                            : tmpStage,
                        decoration: const InputDecoration(
                          labelText: 'Customer Stage',
                        ),
                        items: widget.onlyApproved
                            ? const [
                                DropdownMenuItem<String>(
                                  value: 'Customer',
                                  child: Text('Customer'),
                                ),
                              ]
                            : [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Stages'),
                                ),
                                ...['Lead', 'Prospect', 'Customer'].map(
                                  (stage) => DropdownMenuItem(
                                    value: stage,
                                    child: Text(stage),
                                  ),
                                ),
                              ],
                        onChanged: widget.onlyApproved
                            ? null
                            : (value) => setDialogState(() => tmpStage = value),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<bool>(
                        initialValue: widget.onlyApproved ? true : tmpApproved,
                        decoration: const InputDecoration(
                          labelText: 'Approval Status',
                        ),
                        items: widget.onlyApproved
                            ? const [
                                DropdownMenuItem<bool>(
                                  value: true,
                                  child: Text('Verified'),
                                ),
                              ]
                            : const [
                                DropdownMenuItem<bool>(
                                  value: null,
                                  child: Text('All Status'),
                                ),
                                DropdownMenuItem(
                                  value: true,
                                  child: Text('Verified'),
                                ),
                                DropdownMenuItem(
                                  value: false,
                                  child: Text('Pending'),
                                ),
                              ],
                        onChanged: widget.onlyApproved
                            ? null
                            : (value) =>
                                  setDialogState(() => tmpApproved = value),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        initialValue: tmpSalesmanId,
                        decoration: const InputDecoration(
                          labelText: 'Salesman',
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Salesmen'),
                          ),
                          ..._salesmen.map(
                            (salesman) => DropdownMenuItem<String>(
                              value: salesman['id'] ?? salesman['_id'],
                              child: Text(salesman['name'] ?? 'Unknown'),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => tmpSalesmanId = value),
                      ),
                      const SizedBox(height: 20),

                      // Date Filter Section
                      Text(
                        'Date Filter',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD7BE69),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Quick Date Presets
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => applyDatePreset('today'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                minimumSize: const Size(0, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: tmpDatePreset == 'today'
                                    ? Color(0xFFD7BE69).withValues(alpha: 0.1)
                                    : null,
                                side: BorderSide(
                                  color: tmpDatePreset == 'today'
                                      ? Color(0xFFD7BE69)
                                      : Colors.grey,
                                ),
                              ),
                              child: Text(
                                'Today',
                                style: TextStyle(
                                  color: tmpDatePreset == 'today'
                                      ? Color(0xFFD7BE69)
                                      : Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => applyDatePreset('yesterday'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ), // 🔥 reduce height
                                minimumSize: const Size(
                                  0,
                                  32,
                                ), // 🔥 compact button
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: tmpDatePreset == 'yesterday'
                                    ? Color(0xFFD7BE69).withValues(alpha: 0.1)
                                    : null,
                                side: BorderSide(
                                  color: tmpDatePreset == 'yesterday'
                                      ? Color(0xFFD7BE69)
                                      : Colors.grey,
                                ),
                              ),
                              child: Text(
                                'Yesterday',
                                style: TextStyle(
                                  color: tmpDatePreset == 'yesterday'
                                      ? Color(0xFFD7BE69)
                                      : Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => applyDatePreset('custom'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ), // 🔥 reduce height
                                minimumSize: const Size(
                                  0,
                                  32,
                                ), // 🔥 compact button
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: tmpDatePreset == 'custom'
                                    ? Color(0xFFD7BE69).withValues(alpha: 0.1)
                                    : null,
                                side: BorderSide(
                                  color: tmpDatePreset == 'custom'
                                      ? Color(0xFFD7BE69)
                                      : Colors.grey,
                                ),
                              ),
                              child: Text(
                                'Custom',
                                style: TextStyle(
                                  color: tmpDatePreset == 'custom'
                                      ? Color(0xFFD7BE69)
                                      : Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Custom Date Range (only show when custom is selected)
                      if (tmpDatePreset == 'custom') ...[
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Start Date',
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                readOnly: true,
                                controller: TextEditingController(
                                  text: tmpStartDate != null
                                      ? '${tmpStartDate!.day}/${tmpStartDate!.month}/${tmpStartDate!.year}'
                                      : '',
                                ),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: tmpStartDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setDialogState(() => tmpStartDate = date);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'End Date',
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                readOnly: true,
                                controller: TextEditingController(
                                  text: tmpEndDate != null
                                      ? '${tmpEndDate!.day}/${tmpEndDate!.month}/${tmpEndDate!.year}'
                                      : '',
                                ),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: tmpEndDate ?? DateTime.now(),
                                    firstDate: tmpStartDate ?? DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setDialogState(() => tmpEndDate = date);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Show selected date range for presets
                      if (tmpDatePreset != null &&
                          tmpDatePreset != 'custom' &&
                          tmpStartDate != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFFD7BE69).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Color(0xFFD7BE69).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.date_range,
                                size: 16,
                                color: Color(0xFFD7BE69),
                              ),
                              SizedBox(width: 8),
                              Text(
                                tmpDatePreset == 'today'
                                    ? 'Today (${tmpStartDate!.day}/${tmpStartDate!.month}/${tmpStartDate!.year})'
                                    : 'Yesterday (${tmpStartDate!.day}/${tmpStartDate!.month}/${tmpStartDate!.year})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFD7BE69),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filterCustomerStage = widget.onlyApproved
                          ? 'Customer'
                          : null;
                      _filterIsApproved = widget.onlyApproved ? true : null;
                      _filterStartDate = null;
                      _filterEndDate = null;
                      _filterSalesmanId = null;
                      _filterDatePreset = null;
                    });
                    Navigator.pop(context);
                    _refreshAccounts();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  child: const Text('Clear All'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterCustomerStage = tmpStage;
                      _filterIsApproved = tmpApproved;
                      _filterStartDate = tmpStartDate;
                      _filterEndDate = tmpEndDate;
                      _filterSalesmanId = tmpSalesmanId;
                      _filterDatePreset = tmpDatePreset;
                    });
                    Navigator.pop(context);
                    _refreshAccounts();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD7BE69),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply Filters'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _hasActiveFilters() {
    return _filterCustomerStage != null ||
        _filterIsApproved != null ||
        _filterStartDate != null ||
        _filterEndDate != null ||
        _filterSalesmanId != null ||
        _filterDatePreset != null;
  }

  String _getActiveFiltersText() {
    List<String> activeFilters = [];

    if (_filterCustomerStage != null) {
      activeFilters.add(_filterCustomerStage!);
    }
    if (_filterIsApproved != null) {
      activeFilters.add(_filterIsApproved! ? 'Verified' : 'Pending');
    }
    if (_filterSalesmanId != null) {
      final salesman = _salesmen.firstWhere(
        (s) => (s['id'] ?? s['_id']) == _filterSalesmanId,
        orElse: () => {'name': 'Unknown Salesman'},
      );
      activeFilters.add('By: ${salesman['name'] ?? 'Unknown'}');
    }
    if (_filterDatePreset != null) {
      switch (_filterDatePreset) {
        case 'today':
          activeFilters.add('Today');
          break;
        case 'yesterday':
          activeFilters.add('Yesterday');
          break;
        case 'custom':
          if (_filterStartDate != null || _filterEndDate != null) {
            String dateRange = 'Date: ';
            if (_filterStartDate != null && _filterEndDate != null) {
              dateRange +=
                  '${_filterStartDate!.day}/${_filterStartDate!.month}/${_filterStartDate!.year} - ${_filterEndDate!.day}/${_filterEndDate!.month}/${_filterEndDate!.year}';
            } else if (_filterStartDate != null) {
              dateRange +=
                  'From ${_filterStartDate!.day}/${_filterStartDate!.month}/${_filterStartDate!.year}';
            } else if (_filterEndDate != null) {
              dateRange +=
                  'Until ${_filterEndDate!.day}/${_filterEndDate!.month}/${_filterEndDate!.year}';
            }
            activeFilters.add(dateRange);
          }
          break;
      }
    }

    return activeFilters.join(', ');
  }

  // Navigate to detail screen
  Future<void> _navigateToDetail(String accountId) async {
    context.push(
      "/dashboard/${UserService.currentRole!.toLowerCase()}/account/view/$accountId",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appBarTitle ?? 'Accounts'),
        backgroundColor: const Color(0xFFD7BE69),
        actions: [
          // Network status indicator
          if (_hasNetworkError)
            IconButton(
              icon: Icon(Icons.wifi_off, color: Colors.red),
              onPressed: () => _showNetworkErrorDialog(),
              tooltip: 'Network Error - Tap for details',
            ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
              ),
              if (_hasActiveFilters())
                Positioned(
                  right: 8,
                  top: 8,
                  child: SizedBox(
                    width: 8,
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAccounts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(15),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, code, or phone...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD7BE69)),
                suffixIcon: (_searchQuery != null && _searchQuery!.isNotEmpty)
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = null);
                          _refreshAccounts();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFD7BE69),
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: (value) {
                _onSearchChanged(value);
              },
              onChanged: (value) {
                _onSearchChanged(value);
              },
            ),
          ),

          // Network error banner
          if (_hasNetworkError)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connection lost. Some features may not work.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _retryConnection,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Active filters indicator
          if (_hasActiveFilters())
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 15),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFD7BE69).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color(0xFFD7BE69).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_alt, size: 16, color: Color(0xFFD7BE69)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filters active: ${_getActiveFiltersText()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD7BE69),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterCustomerStage = null;
                        _filterIsApproved = null;
                        _filterStartDate = null;
                        _filterEndDate = null;
                        _filterSalesmanId = null;
                      });
                      _refreshAccounts();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD7BE69),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Accounts List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _accounts.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _refreshAccounts,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(15),
                      itemCount: _accounts.length + (_isLoadingMore ? 1 : 0),
                      // Add caching for better performance
                      cacheExtent: 1000,
                      itemBuilder: (context, index) {
                        if (index == _accounts.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(15),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _buildAccountCard(_accounts[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push("/dashboard/admin/account/master");
        },
        backgroundColor: const Color(0xFFD7BE69),
        tooltip: "Create New Account",
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_hasNetworkError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 80, color: Colors.red[300]),
            const SizedBox(height: 20),
            Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 20,
                color: Colors.red[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _lastErrorMessage ?? 'Unable to connect to server',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _retryConnection,
              icon: Icon(Icons.refresh),
              label: Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD7BE69),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_box_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'No Accounts Found',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Create your first account to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Account account) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToDetail(account.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD7BE69).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFFD7BE69),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.businessName ?? account.personName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (account.businessName != null)
                          Text(
                            account.personName,
                            style: const TextStyle(fontSize: 15),
                          ),
                        const SizedBox(height: 5),
                        Text(
                          account.accountCode,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: account.isApproved
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          account.isApproved
                              ? Icons.check_circle
                              : Icons.pending,
                          size: 16,
                          color: account.isApproved
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          account.isApproved ? 'Verified' : 'Pending',
                          style: TextStyle(
                            fontSize: 12,
                            color: account.isApproved
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              _buildInfoRow(Icons.phone, account.contactNumber),
              if (account.businessType != null)
                _buildInfoRow(Icons.business, account.businessType!),
              if (account.customerStage != null)
                _buildInfoRow(Icons.stairs, account.customerStage!),
              if (account.createdByName != 'Unknown')
                _buildInfoRow(
                  Icons.person_add,
                  'Created by: ${account.createdByName}',
                ),
              _buildInfoRow(
                Icons.calendar_today,
                'Created: ${account.createdAt.day}/${account.createdAt.month}/${account.createdAt.year}',
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ///
                  TextButton.icon(
                    icon: const Icon(Icons.call, size: 20),
                    label: const Text(''),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    onPressed: () => _makePhoneCall(account.contactNumber),
                  ),

                  ///
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 20),
                    label: const Text(''),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditAccountMasterScreen(account: account),
                        ),
                      ).then((result) {
                        if (result == true) {
                          _loadAccounts(
                            refresh: true,
                          ); // Refresh list after edit
                        }
                      });
                    },
                  ),

                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 20),
                    label: const Text(''),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    onPressed: () => _deleteAccount(account),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
