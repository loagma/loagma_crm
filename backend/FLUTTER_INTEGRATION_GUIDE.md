# Flutter Integration Guide

Quick reference for integrating the backend APIs with your Flutter app.

## 🔗 Base Configuration

### API Base URL
```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:5000';
  static const String locationsUrl = '$baseUrl/locations';
  static const String accountsUrl = '$baseUrl/accounts';
}
```

For Android Emulator, use: `http://10.0.2.2:5000`
For iOS Simulator, use: `http://localhost:5000`
For Physical Device, use: `http://YOUR_IP:5000`

---

## 📍 Location Master Integration

### 1. Fetch Countries
```dart
Future<List<Country>> fetchCountries() async {
  final response = await http.get(
    Uri.parse('${ApiConfig.locationsUrl}/countries'),
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return (data['data'] as List)
        .map((json) => Country.fromJson(json))
        .toList();
  }
  throw Exception('Failed to load countries');
}
```

### 2. Fetch States by Country
```dart
Future<List<State>> fetchStates(String countryId) async {
  final response = await http.get(
    Uri.parse('${ApiConfig.locationsUrl}/states?countryId=$countryId'),
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return (data['data'] as List)
        .map((json) => State.fromJson(json))
        .toList();
  }
  throw Exception('Failed to load states');
}
```

### 3. Fetch Districts by State
```dart
Future<List<District>> fetchDistricts(String stateId) async {
  final response = await http.get(
    Uri.parse('${ApiConfig.locationsUrl}/districts?stateId=$stateId'),
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return (data['data'] as List)
        .map((json) => District.fromJson(json))
        .toList();
  }
  throw Exception('Failed to load districts');
}
```

### 4. Fetch Cities by District
```dart
Future<List<City>> fetchCities(String districtId) async {
  final response = await http.get(
    Uri.parse('${ApiConfig.locationsUrl}/cities?districtId=$districtId'),
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return (data['data'] as List)
        .map((json) => City.fromJson(json))
        .toList();
  }
  throw Exception('Failed to load cities');
}
```

### 5. Fetch Zones by City
```dart
Future<List<Zone>> fetchZones(String cityId) async {
  final response = await http.get(
    Uri.parse('${ApiConfig.locationsUrl}/zones?cityId=$cityId'),
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return (data['data'] as List)
        .map((json) => Zone.fromJson(json))
        .toList();
  }
  throw Exception('Failed to load zones');
}
```

### 6. Fetch Areas by Zone
```dart
Future<List<Area>> fetchAreas(String zoneId) async {
  final response = await http.get(
    Uri.parse('${ApiConfig.locationsUrl}/areas?zoneId=$zoneId'),
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return (data['data'] as List)
        .map((json) => Area.fromJson(json))
        .toList();
  }
  throw Exception('Failed to load areas');
}
```

---

## 👤 Account Master Integration

### 1. Create Account
```dart
Future<Account> createAccount({
  required String personName,
  required String contactNumber,
  String? dateOfBirth,
  String? businessType,
  String? customerStage,
  String? funnelStage,
  String? assignedToId,
  String? areaId,
}) async {
  final response = await http.post(
    Uri.parse(ApiConfig.accountsUrl),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'personName': personName,
      'contactNumber': contactNumber,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (businessType != null) 'businessType': businessType,
      if (customerStage != null) 'customerStage': customerStage,
      if (funnelStage != null) 'funnelStage': funnelStage,
      if (assignedToId != null) 'assignedToId': assignedToId,
      if (areaId != null) 'areaId': areaId,
    }),
  );
  
  if (response.statusCode == 201) {
    final data = json.decode(response.body);
    return Account.fromJson(data['data']);
  }
  throw Exception('Failed to create account');
}
```

### 2. Fetch All Accounts
```dart
Future<AccountListResponse> fetchAccounts({
  int page = 1,
  int limit = 50,
  String? areaId,
  String? assignedToId,
  String? customerStage,
  String? funnelStage,
  String? search,
}) async {
  final queryParams = {
    'page': page.toString(),
    'limit': limit.toString(),
    if (areaId != null) 'areaId': areaId,
    if (assignedToId != null) 'assignedToId': assignedToId,
    if (customerStage != null) 'customerStage': customerStage,
    if (funnelStage != null) 'funnelStage': funnelStage,
    if (search != null) 'search': search,
  };
  
  final uri = Uri.parse(ApiConfig.accountsUrl).replace(
    queryParameters: queryParams,
  );
  
  final response = await http.get(uri);
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return AccountListResponse.fromJson(data);
  }
  throw Exception('Failed to load accounts');
}
```

### 3. Fetch Account by ID
```dart
Future<Account> fetchAccountById(String id) async {
  final response = await http.get(
    Uri.parse('${ApiConfig.accountsUrl}/$id'),
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return Account.fromJson(data['data']);
  }
  throw Exception('Failed to load account');
}
```

### 4. Update Account
```dart
Future<Account> updateAccount(String id, Map<String, dynamic> updates) async {
  final response = await http.put(
    Uri.parse('${ApiConfig.accountsUrl}/$id'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode(updates),
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return Account.fromJson(data['data']);
  }
  throw Exception('Failed to update account');
}
```

### 5. Delete Account
```dart
Future<void> deleteAccount(String id) async {
  final response = await http.delete(
    Uri.parse('${ApiConfig.accountsUrl}/$id'),
  );
  
  if (response.statusCode != 200) {
    throw Exception('Failed to delete account');
  }
}
```

### 6. Fetch Account Statistics
```dart
Future<AccountStats> fetchAccountStats({
  String? assignedToId,
  String? areaId,
}) async {
  final queryParams = {
    if (assignedToId != null) 'assignedToId': assignedToId,
    if (areaId != null) 'areaId': areaId,
  };
  
  final uri = Uri.parse('${ApiConfig.accountsUrl}/stats').replace(
    queryParameters: queryParams,
  );
  
  final response = await http.get(uri);
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return AccountStats.fromJson(data['data']);
  }
  throw Exception('Failed to load stats');
}
```

---

## 📦 Model Classes

### Location Models
```dart
class Country {
  final String id;
  final String name;
  final DateTime createdAt;
  
  Country({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  
  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class State {
  final String id;
  final String name;
  final String countryId;
  
  State({
    required this.id,
    required this.name,
    required this.countryId,
  });
  
  factory State.fromJson(Map<String, dynamic> json) {
    return State(
      id: json['id'],
      name: json['name'],
      countryId: json['countryId'],
    );
  }
}

// Similar for District, City, Zone, Area
```

### Account Model
```dart
class Account {
  final String id;
  final String accountCode;
  final String personName;
  final DateTime? dateOfBirth;
  final String contactNumber;
  final String? businessType;
  final String? customerStage;
  final String? funnelStage;
  final String? assignedToId;
  final String? areaId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Account({
    required this.id,
    required this.accountCode,
    required this.personName,
    this.dateOfBirth,
    required this.contactNumber,
    this.businessType,
    this.customerStage,
    this.funnelStage,
    this.assignedToId,
    this.areaId,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      accountCode: json['accountCode'],
      personName: json['personName'],
      dateOfBirth: json['dateOfBirth'] != null 
          ? DateTime.parse(json['dateOfBirth']) 
          : null,
      contactNumber: json['contactNumber'],
      businessType: json['businessType'],
      customerStage: json['customerStage'],
      funnelStage: json['funnelStage'],
      assignedToId: json['assignedToId'],
      areaId: json['areaId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class AccountListResponse {
  final List<Account> accounts;
  final Pagination pagination;
  
  AccountListResponse({
    required this.accounts,
    required this.pagination,
  });
  
  factory AccountListResponse.fromJson(Map<String, dynamic> json) {
    return AccountListResponse(
      accounts: (json['data'] as List)
          .map((item) => Account.fromJson(item))
          .toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }
}

class Pagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  
  Pagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });
  
  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'],
      page: json['page'],
      limit: json['limit'],
      totalPages: json['totalPages'],
    );
  }
}
```

---

## 🎯 Cascading Dropdown Implementation

```dart
class LocationDropdowns extends StatefulWidget {
  @override
  _LocationDropdownsState createState() => _LocationDropdownsState();
}

class _LocationDropdownsState extends State<LocationDropdowns> {
  String? selectedCountryId;
  String? selectedStateId;
  String? selectedDistrictId;
  String? selectedCityId;
  String? selectedZoneId;
  String? selectedAreaId;
  
  List<Country> countries = [];
  List<State> states = [];
  List<District> districts = [];
  List<City> cities = [];
  List<Zone> zones = [];
  List<Area> areas = [];
  
  @override
  void initState() {
    super.initState();
    loadCountries();
  }
  
  Future<void> loadCountries() async {
    final data = await fetchCountries();
    setState(() {
      countries = data;
    });
  }
  
  Future<void> loadStates(String countryId) async {
    final data = await fetchStates(countryId);
    setState(() {
      states = data;
      selectedStateId = null;
      districts = [];
      cities = [];
      zones = [];
      areas = [];
    });
  }
  
  Future<void> loadDistricts(String stateId) async {
    final data = await fetchDistricts(stateId);
    setState(() {
      districts = data;
      selectedDistrictId = null;
      cities = [];
      zones = [];
      areas = [];
    });
  }
  
  // Similar for cities, zones, areas
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButton<String>(
          hint: Text('Select Country'),
          value: selectedCountryId,
          items: countries.map((country) {
            return DropdownMenuItem(
              value: country.id,
              child: Text(country.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedCountryId = value;
            });
            if (value != null) loadStates(value);
          },
        ),
        
        if (states.isNotEmpty)
          DropdownButton<String>(
            hint: Text('Select State'),
            value: selectedStateId,
            items: states.map((state) {
              return DropdownMenuItem(
                value: state.id,
                child: Text(state.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedStateId = value;
              });
              if (value != null) loadDistricts(value);
            },
          ),
        
        // Similar for other dropdowns
      ],
    );
  }
}
```

---

## 🔍 Search & Filter Implementation

```dart
class AccountListScreen extends StatefulWidget {
  @override
  _AccountListScreenState createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  List<Account> accounts = [];
  int currentPage = 1;
  bool isLoading = false;
  String searchQuery = '';
  String? filterCustomerStage;
  
  @override
  void initState() {
    super.initState();
    loadAccounts();
  }
  
  Future<void> loadAccounts() async {
    setState(() {
      isLoading = true;
    });
    
    final response = await fetchAccounts(
      page: currentPage,
      limit: 20,
      search: searchQuery.isNotEmpty ? searchQuery : null,
      customerStage: filterCustomerStage,
    );
    
    setState(() {
      accounts = response.accounts;
      isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accounts'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // Show filter dialog
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search accounts...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
                loadAccounts();
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      return ListTile(
                        title: Text(account.personName),
                        subtitle: Text(account.accountCode),
                        trailing: Text(account.customerStage ?? ''),
                        onTap: () {
                          // Navigate to account detail
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // Navigate to create account
        },
      ),
    );
  }
}
```

---

## 📱 pubspec.yaml Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  provider: ^6.1.1  # For state management
```

---

## ✅ Testing Checklist

- [ ] Test country dropdown loads
- [ ] Test cascading dropdowns (country → state → district → city → zone → area)
- [ ] Test account creation with all fields
- [ ] Test account list with pagination
- [ ] Test search functionality
- [ ] Test filter by customer stage
- [ ] Test account update
- [ ] Test account delete
- [ ] Test error handling for network failures
- [ ] Test loading states

---

## 🚀 Quick Start

1. Ensure backend is running: `npm run dev`
2. Update `ApiConfig.baseUrl` with correct URL
3. Add http package to pubspec.yaml
4. Copy model classes to your project
5. Implement API service class
6. Use in your widgets

---

## 📝 Notes

- All API responses follow format: `{ success: bool, data: any }`
- Handle errors with try-catch blocks
- Show loading indicators during API calls
- Validate user input before sending to API
- Contact numbers must be 10 digits
- Account codes are auto-generated by backend

---

## 🐛 Common Issues

**Issue**: Network error on Android emulator
**Solution**: Use `http://10.0.2.2:5000` instead of `localhost`

**Issue**: CORS error
**Solution**: Backend already has CORS enabled, check URL

**Issue**: 400 Bad Request
**Solution**: Check required fields (personName, contactNumber)

**Issue**: 404 Not Found
**Solution**: Verify backend is running and URL is correct
