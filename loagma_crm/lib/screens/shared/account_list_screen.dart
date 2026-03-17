import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../../models/account_model.dart';
import '../../services/account_service.dart';
import '../../services/user_service.dart';
import '../../services/network_service.dart';
import 'edit_account_master_screen.dart';
import '../admin/customer_beat_plan_screen.dart';

class AccountListScreen extends StatefulWidget {
  /// When true, this screen will show only telecaller‑approved
  /// accounts by default (used for the Admin "Customer List" panel).
  final bool onlyApproved;

  /// Optional custom title for the AppBar. Falls back to "Accounts".
  final String? appBarTitle;

  /// When true, used from Beat Plan module: allot assigns without day selection
  /// and then opens CustomerBeatPlanScreen to distribute and save.
  final bool forBeatPlan;

  const AccountListScreen({
    super.key,
    this.onlyApproved = false,
    this.appBarTitle,
    this.forBeatPlan = false,
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

  // Selection mode for allotment (admin only)
  bool _selectionMode = false;
  final Set<String> _selectedAccountIds = {};

  // Range selection (by list index) for allotment
  final TextEditingController _rangeFromController = TextEditingController();
  final TextEditingController _rangeToController = TextEditingController();
  String? _rangeErrorText;

  // Beat plan – pincode filter (beat-plan-only flow)
  String? _beatPlanPincodeFilter;
  final TextEditingController _beatPlanPincodeController =
      TextEditingController();
  int? _beatPlanPincodeTotal;
  final TextEditingController _beatPlanSelectCountController =
      TextEditingController();
  final List<String> _beatPlanPincodes = [];
  int _beatPlanActivePincodeIndex = -1;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  // Determines whether we should pass createdBy filter (admin/manager see all)
  bool get _shouldFilterByOwner {
    final role = UserService.currentRole?.toLowerCase();
    return role != null && role != 'admin' && role != 'manager';
  }

  String? get _currentUserId => UserService.currentUserId;

  bool get _isAdmin => UserService.currentRole?.toLowerCase() == 'admin';

  /// Salesmen only (for allotment dropdown)
  List<Map<String, dynamic>> get _salesmenForAllotment {
    return _salesmen.where((u) {
      final role = (u['role'] ?? u['roleId'] ?? '').toString().toLowerCase();
      return role.contains('salesman') || role.contains('sales');
    }).toList();
  }

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
    _rangeFromController.dispose();
    _rangeToController.dispose();
    _beatPlanPincodeController.dispose();
    _beatPlanSelectCountController.dispose();
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

      // result expected: { 'accounts': List<Account>, 'pagination': {'totalPages': n, 'total': m} }
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
        if (widget.forBeatPlan) {
          _beatPlanPincodeTotal = (pagination['total'] as int?) ?? fetched.length;
        }
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
      // Load a larger chunk so admin can select more than 20 at once
      limit: 200,
      search: _searchQuery,
      // For "Customer List", enforce final customer stage = Customer,
      // otherwise use whatever filter user selected.
      customerStage: widget.onlyApproved ? 'Customer' : _filterCustomerStage,
      // If this screen is used as "Customer List" in admin,
      // hard‑enforce isApproved = true so only verified accounts load.
      isApproved: widget.onlyApproved ? true : _filterIsApproved,
      // Beat plan account-first flow: allow filtering by pincode
      pincode: widget.forBeatPlan ? _beatPlanPincodeFilter : null,
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

  static const List<String> _weekDayLabels = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Step 1: Select salesman, then Next.
  Future<void> _showAllotToSalesmanDialog() async {
    if (_selectedAccountIds.isEmpty) return;

    String? selectedSalesmanId;
    String? selectedSalesmanName;
    final salesmenList = _salesmenForAllotment;

    if (!mounted) return;
    final step1 = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.person_add, color: Color(0xFFD7BE69), size: 26),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Allot customers to salesman',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${_selectedAccountIds.length} account(s) selected. First select the salesman.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Salesman',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedSalesmanId,
                      decoration: InputDecoration(
                        hintText: 'Select salesman',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('-- Select salesman --'),
                        ),
                        ...salesmenList.map((u) {
                          final id = u['id'] ?? u['_id'];
                          final name = u['name'] ?? 'Unknown';
                          return DropdownMenuItem<String>(
                            value: id?.toString(),
                            child: Text(name.toString()),
                          );
                        }),
                      ],
                      onChanged: (v) {
                        setDialogState(() {
                          selectedSalesmanId = v;
                          if (v != null) {
                            Map<String, dynamic>? found;
                            for (final e in salesmenList) {
                              if ((e['id'] ?? e['_id']).toString() == v) {
                                found = e;
                                break;
                              }
                            }
                            selectedSalesmanName =
                                found?['name']?.toString() ?? 'Salesman';
                          } else {
                            selectedSalesmanName = null;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selectedSalesmanId == null
                      ? null
                      : () => Navigator.of(ctx).pop({
                          'salesmanId': selectedSalesmanId,
                          'salesmanName': selectedSalesmanName ?? 'Salesman',
                        }),
                  style: FilledButton.styleFrom(
                    backgroundColor: Color(0xFFD7BE69),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Next'),
                ),
              ],
            );
          },
        );
      },
    );

    if (step1 == null || !mounted) return;
    final salesmanId = step1['salesmanId'] as String?;
    final salesmanName = step1['salesmanName'] as String?;
    if (salesmanId == null) return;

    if (widget.forBeatPlan) {
      try {
        final count = await AccountService.bulkAssignAccounts(
          accountIds: _selectedAccountIds.toList(),
          assignedToId: salesmanId,
          assignedDays: null,
        );
        if (!mounted) return;
        _showSuccess('$count customer(s) allotted to ${salesmanName ?? 'Salesman'}. Set week and distribute days below.');
        setState(() {
          _selectionMode = false;
          _selectedAccountIds.clear();
          _rangeFromController.clear();
          _rangeToController.clear();
          _rangeErrorText = null;
        });
        _refreshAccounts();
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerBeatPlanScreen(
              salesmanId: salesmanId,
              salesmanName: salesmanName ?? 'Salesman',
              allottedCount: count,
            ),
          ),
        );
        if (mounted) _refreshAccounts();
      } catch (e) {
        if (mounted) _showError('Failed to allot: $e');
      }
      return;
    }

    // Step 2: Beat plan – select week days, then Allot.
    await _showBeatPlanSelectDaysDialog(
      salesmanId: salesmanId,
      salesmanName: salesmanName ?? 'Salesman',
    );
  }

  /// Step 2: Beat plan screen – show all week days, select days, then Allot.
  Future<void> _showBeatPlanSelectDaysDialog({
    required String salesmanId,
    required String salesmanName,
  }) async {
    final selectedDays = <int>{};

    if (!mounted) return;
    final result = await showDialog<Set<int>?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.calendar_view_week,
                    color: Color(0xFFD7BE69),
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Beat plan – Select days',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Allotment for $salesmanName. Select the week day(s) for this beat plan.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(7, (index) {
                      final dayIndex = index + 1;
                      final label = _weekDayLabels[index];
                      final isSelected = selectedDays.contains(dayIndex);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: isSelected
                              ? Color(0xFFD7BE69).withValues(alpha: 0.15)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                if (isSelected) {
                                  selectedDays.remove(dayIndex);
                                } else {
                                  selectedDays.add(dayIndex);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? Color(0xFFD7BE69)
                                        : Colors.grey.shade600,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Color(0xFF8B7355)
                                          : Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Back'),
                ),
                FilledButton(
                  onPressed: selectedDays.isEmpty
                      ? null
                      : () =>
                            Navigator.of(ctx).pop(Set<int>.from(selectedDays)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Color(0xFFD7BE69),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Allot'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;
    if (result.isEmpty) return;

    try {
      final count = await AccountService.bulkAssignAccounts(
        accountIds: _selectedAccountIds.toList(),
        assignedToId: salesmanId,
        assignedDays: result.toList(),
      );
      if (!mounted) return;
      final daysStr = result.toList()..sort();
      final dayLabels = daysStr.map((d) => _weekDayLabels[d - 1]).join(', ');
      _showSuccess(
        '$count customer(s) allotted to $salesmanName for: $dayLabels',
      );
      setState(() {
        _selectionMode = false;
        _selectedAccountIds.clear();
      });
      _refreshAccounts();
    } catch (e) {
      if (mounted) _showError('Failed to allot: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.appBarTitle ??
              (widget.forBeatPlan ? 'Beat Plan – Select accounts' : 'Accounts'),
        ),
        backgroundColor: const Color(0xFFD7BE69),
        actions: [
          if (widget.forBeatPlan)
            IconButton(
              icon: const Icon(Icons.calendar_view_week),
              onPressed: () => context.push('/dashboard/admin/beat-plans'),
              tooltip: 'Existing beat plans',
            ),
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
          if (_isAdmin && !_selectionMode)
            TextButton.icon(
              onPressed: () => setState(() {
                _selectionMode = true;
                _selectedAccountIds.clear();
              }),
              icon: const Icon(Icons.checklist_rtl, size: 20),
              label: const Text('Select'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          if (_selectionMode) ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _selectionMode = false;
                  _selectedAccountIds.clear();
                  _rangeFromController.clear();
                  _rangeToController.clear();
                  _rangeErrorText = null;
                  _beatPlanPincodeController.clear();
                  _beatPlanPincodeFilter = null;
                  _beatPlanPincodeTotal = null;
                  _beatPlanSelectCountController.clear();
                  _beatPlanPincodes.clear();
                  _beatPlanActivePincodeIndex = -1;
                });
                _refreshAccounts();
              },
              child: const Text('Cancel'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
            TextButton.icon(
              onPressed: _selectedAccountIds.isEmpty
                  ? null
                  : _showAllotToSalesmanDialog,
              icon: const Icon(Icons.person_add, size: 20),
              label: Text('Allot (${_selectedAccountIds.length})'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _selectedAccountIds.isEmpty
                    ? Colors.grey
                    : Colors.green.shade700,
              ),
            ),
          ],
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

          // Selection mode banner (admin allotment)
          if (_selectionMode && _isAdmin)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 15),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFD7BE69).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFD7BE69).withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.checklist_rtl,
                        color: Color(0xFFD7BE69),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Select accounts, then tap Allot to assign to a salesman (day-wise).',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total in this list: ${_accounts.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedAccountIds.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Selected: ${_selectedAccountIds.length} account(s)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (widget.forBeatPlan) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _beatPlanPincodeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'Add pincode',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final value =
                                _beatPlanPincodeController.text.trim();
                            if (value.length != 6 ||
                                int.tryParse(value) == null) {
                              _showError('Enter a valid 6-digit pincode');
                              return;
                            }
                            setState(() {
                              final existingIndex =
                                  _beatPlanPincodes.indexOf(value);
                              if (existingIndex != -1) {
                                _beatPlanActivePincodeIndex = existingIndex;
                                _beatPlanPincodeFilter =
                                    _beatPlanPincodes[existingIndex];
                              } else {
                                _beatPlanPincodes.add(value);
                                _beatPlanActivePincodeIndex =
                                    _beatPlanPincodes.length - 1;
                                _beatPlanPincodeFilter = value;
                              }
                            });
                            _beatPlanPincodeController.clear();
                            _refreshAccounts();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            backgroundColor: const Color(0xFFD7BE69),
                            foregroundColor: Colors.white,
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    if (_beatPlanPincodes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(
                            _beatPlanPincodes.length,
                            (index) {
                              final pincode = _beatPlanPincodes[index];
                              final isActive =
                                  index == _beatPlanActivePincodeIndex;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InputChip(
                                  label: Text(
                                    pincode,
                                    style: TextStyle(
                                      fontWeight: isActive
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  selected: isActive,
                                  selectedColor: const Color(0xFFD7BE69)
                                      .withValues(alpha: 0.2),
                                  onPressed: () {
                                    setState(() {
                                      _beatPlanActivePincodeIndex = index;
                                      _beatPlanPincodeFilter = pincode;
                                    });
                                    _refreshAccounts();
                                  },
                                  onDeleted: () async {
                                    await _clearSelectionsForPincode(pincode);
                                    setState(() {
                                      _beatPlanPincodes.removeAt(index);
                                      if (_beatPlanPincodes.isEmpty) {
                                        _beatPlanActivePincodeIndex = -1;
                                        _beatPlanPincodeFilter = null;
                                        _beatPlanPincodeTotal = null;
                                      } else {
                                        if (_beatPlanActivePincodeIndex >=
                                            _beatPlanPincodes.length) {
                                          _beatPlanActivePincodeIndex =
                                              _beatPlanPincodes.length - 1;
                                        }
                                        if (_beatPlanActivePincodeIndex < 0) {
                                          _beatPlanActivePincodeIndex = 0;
                                        }
                                        _beatPlanPincodeFilter =
                                            _beatPlanPincodes[
                                                _beatPlanActivePincodeIndex];
                                      }
                                    });
                                    _refreshAccounts();
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    if (_beatPlanPincodeFilter != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Pincode $_beatPlanPincodeFilter – ${_beatPlanPincodeTotal ?? _accounts.length} account(s)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Checkbox(
                            value: _areAllCurrentPincodeAccountsSelected(),
                            onChanged: (v) =>
                                _toggleSelectAllCurrentPincode(v == true),
                            activeColor: const Color(0xFFD7BE69),
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'Select all accounts in this pincode',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _beatPlanSelectCountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                isDense: true,
                                labelText: 'N',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _accounts.isEmpty
                                ? null
                                : _addFirstNFromCurrentPincode,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              backgroundColor: const Color(0xFFD7BE69),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Add',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  if (!widget.forBeatPlan) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Select by range:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: _rangeFromController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'From',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: _rangeToController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText: 'To',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed:
                              _accounts.isEmpty ? null : _applyRangeSelection,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            backgroundColor: const Color(0xFFD7BE69),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on current list order (1 is top card).',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (_rangeErrorText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _rangeErrorText!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
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
      floatingActionButton: widget.forBeatPlan
          ? null
          : (_selectionMode
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    context.push("/dashboard/admin/account/master");
                  },
                  backgroundColor: const Color(0xFFD7BE69),
                  tooltip: "Create New Account",
                  shape: const CircleBorder(),
                  child: const Icon(Icons.add),
                )),
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

  void _applyRangeSelection() {
    setState(() {
      _rangeErrorText = null;
    });

    final fromText = _rangeFromController.text.trim();
    final toText = _rangeToController.text.trim();

    final from = int.tryParse(fromText);
    final to = int.tryParse(toText);

    if (from == null || to == null) {
      setState(() {
        _rangeErrorText = 'Enter valid numbers for From and To.';
      });
      return;
    }

    if (from < 1 || to < 1) {
      setState(() {
        _rangeErrorText = 'From and To must be at least 1.';
      });
      return;
    }

    if (from > to) {
      setState(() {
        _rangeErrorText = 'From cannot be greater than To.';
      });
      return;
    }

    if (_accounts.isEmpty) {
      setState(() {
        _rangeErrorText = 'No accounts in the current list.';
      });
      return;
    }

    if (from > _accounts.length || to > _accounts.length) {
      setState(() {
        _rangeErrorText = 'Max index is ${_accounts.length}.';
      });
      return;
    }

    setState(() {
      for (var i = from - 1; i <= to - 1; i++) {
        if (i >= 0 && i < _accounts.length) {
          _selectedAccountIds.add(_accounts[i].id);
        }
      }
      _rangeErrorText = null;
    });
  }

  bool _areAllCurrentPincodeAccountsSelected() {
    if (!widget.forBeatPlan || _beatPlanPincodeFilter == null) {
      return false;
    }
    if (_accounts.isEmpty) return false;
    for (final a in _accounts) {
      if (!_selectedAccountIds.contains(a.id)) {
        return false;
      }
    }
    return true;
  }

  void _toggleSelectAllCurrentPincode(bool value) {
    if (!widget.forBeatPlan || _beatPlanPincodeFilter == null) return;
    setState(() {
      if (value) {
        for (final a in _accounts) {
          _selectedAccountIds.add(a.id);
        }
      } else {
        for (final a in _accounts) {
          _selectedAccountIds.remove(a.id);
        }
      }
      // Keep the N field in sync with how many accounts
      // for the current pincode are selected.
      final selectedForCurrent = _accounts
          .where((a) => _selectedAccountIds.contains(a.id))
          .length;
      if (selectedForCurrent > 0) {
        _beatPlanSelectCountController.text = selectedForCurrent.toString();
      } else {
        _beatPlanSelectCountController.clear();
      }
    });
  }

  void _addFirstNFromCurrentPincode() {
    if (!widget.forBeatPlan || _beatPlanPincodeFilter == null) {
      _showError('Apply a pincode filter first.');
      return;
    }
    final raw = _beatPlanSelectCountController.text.trim();
    final n = int.tryParse(raw);
    if (n == null || n < 1) {
      _showError('Enter a valid number (at least 1).');
      return;
    }
    if (_accounts.isEmpty) {
      _showError('No accounts for this pincode.');
      return;
    }
    final available = _accounts
        .where((a) => !_selectedAccountIds.contains(a.id))
        .length;
    if (available == 0) {
      _showError('All accounts for this pincode are already selected.');
      return;
    }
    int added = 0;
    setState(() {
      for (final a in _accounts) {
        if (added >= n) break;
        if (!_selectedAccountIds.contains(a.id)) {
          _selectedAccountIds.add(a.id);
          added++;
        }
      }
      _beatPlanSelectCountController.clear();
    });
    if (added < n && available < n) {
      _showError('Only $available account(s) available for this pincode.');
    }
    if (added > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added $added account(s) from pincode $_beatPlanPincodeFilter',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _clearSelectionsForPincode(String pincode) async {
    // If this pincode is currently active, use the already loaded accounts list.
    if (_beatPlanPincodeFilter == pincode) {
      setState(() {
        for (final a in _accounts) {
          _selectedAccountIds.remove(a.id);
        }
        _beatPlanSelectCountController.clear();
      });
      return;
    }

    try {
      final result = await AccountService.fetchAccounts(
        page: 1,
        limit: 10000,
        search: _searchQuery,
        customerStage:
            widget.onlyApproved ? 'Customer' : _filterCustomerStage,
        isApproved: widget.onlyApproved ? true : _filterIsApproved,
        pincode: pincode,
        startDate: _filterStartDate,
        endDate: _filterEndDate,
        createdById:
            _filterSalesmanId ?? (_shouldFilterByOwner ? _currentUserId : null),
      );
      final fetched = List<Account>.from(result['accounts'] ?? []);
      setState(() {
        for (final a in fetched) {
          _selectedAccountIds.remove(a.id);
        }
      });
    } catch (_) {
      // If this cleanup fails, keep existing selections; avoid blocking the user.
    }
  }

  Widget _buildAccountCard(Account account) {
    final isSelected = _selectedAccountIds.contains(account.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (_selectionMode && _isAdmin) {
            setState(() {
              if (isSelected) {
                _selectedAccountIds.remove(account.id);
              } else {
                _selectedAccountIds.add(account.id);
              }
            });
          } else {
            _navigateToDetail(account.id);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_selectionMode && _isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedAccountIds.add(account.id);
                            } else {
                              _selectedAccountIds.remove(account.id);
                            }
                          });
                        },
                        activeColor: const Color(0xFFD7BE69),
                      ),
                    ),
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
