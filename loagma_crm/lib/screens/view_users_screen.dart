import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:loagma_crm/services/api_config.dart';
import '../services/api_service.dart';

class ViewUsersScreen extends StatefulWidget {
  const ViewUsersScreen({super.key});

  @override
  State<ViewUsersScreen> createState() => _ViewUsersScreenState();
}

class _ViewUsersScreenState extends State<ViewUsersScreen> {
  bool isLoading = true;
  List users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => isLoading = true);

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users'); // Get all users API
      if (kDebugMode) print('📡 Fetching users from $url');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          users = data['users'];
        });
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? "Failed to fetch users");
      }
    } catch (e) {
      if (e is TimeoutException) {
        Fluttertoast.showToast(msg: "Request timed out while fetching users.");
        if (kDebugMode) print('❌ Fetch users timeout: $e');
      } else {
        if (kDebugMode) print('❌ Error fetching users: $e');
        Fluttertoast.showToast(msg: "Error: $e");
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/users/$userId'); // Delete user API
      if (kDebugMode) print('📡 Deleting user via $url');
      final response = await http.delete(url).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Fluttertoast.showToast(msg: data['message'] ?? "User deleted");
        fetchUsers(); // Refresh list
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? "Failed to delete user");
      }
    } catch (e) {
      if (e is TimeoutException) {
        Fluttertoast.showToast(msg: "Request timed out while deleting user.");
        if (kDebugMode) print('❌ Delete user timeout: $e');
      } else {
        if (kDebugMode) print('❌ Error deleting user: $e');
        Fluttertoast.showToast(msg: "Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Users"),
        backgroundColor: const Color(0xFFD7BE69),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD7BE69)))
          : users.isEmpty
              ? const Center(child: Text("No users found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(user['name'] ?? ""),
                        subtitle: Text("${user['email']} \n${user['contactNumber']}"),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                // TODO: Implement Edit functionality
                                Fluttertoast.showToast(msg: "Edit feature coming soon");
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Delete User"),
                                    content: const Text("Are you sure you want to delete this user?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          deleteUser(user['id']);
                                        },
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
