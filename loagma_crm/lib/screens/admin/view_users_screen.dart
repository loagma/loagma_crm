import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../../services/api_config.dart';
import 'user_detail_screen.dart';

class AdminViewUsersScreen extends StatefulWidget {
  const AdminViewUsersScreen({super.key});

  @override
  State<AdminViewUsersScreen> createState() => _AdminViewUsersScreenState();
}

class _AdminViewUsersScreenState extends State<AdminViewUsersScreen> {
  bool isLoading = true;
  List users = [];
  List filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users.where((user) {
          final name = (user['name'] ?? '').toString().toLowerCase();
          final phone = (user['contactNumber'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? '').toString().toLowerCase();
          final role = (user['role'] ?? '').toString().toLowerCase();
          final department = (user['department'] ?? '')
              .toString()
              .toLowerCase();

          return name.contains(query) ||
              phone.contains(query) ||
              email.contains(query) ||
              role.contains(query) ||
              department.contains(query);
        }).toList();
      }
    });
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/users');
      if (kDebugMode) print('📡 Fetching users from $url');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          users = data['users'];
          filteredUsers = users;
        });
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? "Failed to fetch users");
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error fetching users: $e');
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId');
      if (kDebugMode) print('📡 Deleting user via $url');
      final response = await http
          .delete(url)
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Fluttertoast.showToast(msg: data['message'] ?? "User deleted");
        fetchUsers();
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? "Failed to delete user");
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting user: $e');
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    final value = number is String ? double.tryParse(number) ?? 0 : number;
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Employees"),
        backgroundColor: const Color(0xFFD7BE69),
        automaticallyImplyLeading: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, phone, email, role...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD7BE69)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD7BE69)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFD7BE69),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          // Results count
          if (!isLoading && users.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Showing ${filteredUsers.length} of ${users.length} employees',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Employee List
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD7BE69)),
                  )
                : users.isEmpty
                ? const Center(child: Text("No employee found"))
                : filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No employees found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserDetailScreen(
                                  user: user,
                                  onUpdate: fetchUsers,
                                ),
                              ),
                            );
                            if (result == true) {
                              fetchUsers();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Profile Image
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: const Color(0xFFD7BE69),
                                  backgroundImage:
                                      user['image'] != null &&
                                          user['image'].toString().isNotEmpty
                                      ? NetworkImage(user['image'])
                                      : null,
                                  child:
                                      user['image'] == null ||
                                          user['image'].toString().isEmpty
                                      ? Text(
                                          (user['name'] ?? 'U')[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),

                                // Employee Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Name
                                      Text(
                                        user['name'] ?? user['contactNumber'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),

                                      // Employee Code
                                      if (user['employeeCode'] != null)
                                        Text(
                                          'ID: ${user['employeeCode']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      const SizedBox(height: 4),

                                      // Role & Department
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.badge,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              user['role'] ?? 'No Role',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),

                                      // Contact
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            user['contactNumber'] ?? '',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Status Badge
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: user['isActive'] == true
                                            ? Colors.green.shade50
                                            : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: user['isActive'] == true
                                              ? Colors.green.shade300
                                              : Colors.red.shade300,
                                        ),
                                      ),
                                      child: Text(
                                        user['isActive'] == true
                                            ? 'Active'
                                            : 'Inactive',
                                        style: TextStyle(
                                          color: user['isActive'] == true
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Salary (if available)
                                    if (user['salaryDetails'] != null)
                                      Text(
                                        '₹${_formatNumber(user['salaryDetails']['netSalary'] ?? user['salaryDetails']['basicSalary'])}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFD7BE69),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
