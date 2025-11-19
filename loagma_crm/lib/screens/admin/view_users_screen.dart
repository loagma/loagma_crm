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

  @override
  void initState() {
    super.initState();
    fetchUsers();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Users"),
        backgroundColor: const Color(0xFFD7BE69),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD7BE69)),
            )
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
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFD7BE69),
                      backgroundImage: user['image'] != null
                          ? NetworkImage(user['image'])
                          : null,
                      child: user['image'] == null
                          ? Text(
                              (user['name'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            )
                          : null,
                    ),
                    title: Text(
                      user['name'] ?? user['contactNumber'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("📞 ${user['contactNumber']}"),
                        if (user['email'] != null) Text("📧 ${user['email']}"),
                        Text("👤 ${user['role'] ?? 'No Role'}"),
                        if (user['department'] != null)
                          Text("🏢 ${user['department']}"),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: user['isActive'] == true
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user['isActive'] == true ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: user['isActive'] == true
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                  ),
                );
              },
            ),
    );
  }
}
