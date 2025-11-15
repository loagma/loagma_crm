import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../../services/api_config.dart';

class ManageRolesScreen extends StatefulWidget {
  const ManageRolesScreen({super.key});

  @override
  State<ManageRolesScreen> createState() => _ManageRolesScreenState();
}

class _ManageRolesScreenState extends State<ManageRolesScreen> {
  bool isLoading = true;
  List roles = [];

  @override
  void initState() {
    super.initState();
    fetchRoles();
  }

  Future<void> fetchRoles() async {
    setState(() => isLoading = true);

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/roles');
      if (kDebugMode) print('📡 Fetching roles from $url');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          roles = data['roles'];
        });
      } else {
        Fluttertoast.showToast(msg: "Failed to fetch roles");
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error fetching roles: $e');
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> createRole(String id, String name) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/roles');
      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"id": id, "name": name}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Fluttertoast.showToast(msg: "Role created successfully");
        fetchRoles();
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? "Failed to create role");
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error creating role: $e');
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  Future<void> updateRole(String id, String name) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/roles/$id');
      final response = await http
          .put(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"name": name}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Fluttertoast.showToast(msg: "Role updated successfully");
        fetchRoles();
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? "Failed to update role");
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error updating role: $e');
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  Future<void> deleteRole(String id) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/roles/$id');
      final response = await http
          .delete(url)
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        Fluttertoast.showToast(msg: "Role deleted successfully");
        fetchRoles();
      } else {
        Fluttertoast.showToast(msg: data['message'] ?? "Failed to delete role");
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting role: $e');
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

  void showCreateRoleDialog() {
    final idController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Role"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: "Role ID (e.g., nsm)",
              ),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Role Name (e.g., NSM)",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: "Create cancelled",
                backgroundColor: Colors.grey,
              );
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              createRole(idController.text.trim(), nameController.text.trim());
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void showEditRoleDialog(String id, String currentName) {
    final nameController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Role"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Role Name"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Fluttertoast.showToast(
                msg: "Edit cancelled",
                backgroundColor: Colors.grey,
              );
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              updateRole(id, nameController.text.trim());
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Roles"),
        backgroundColor: const Color(0xFFD7BE69),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showCreateRoleDialog,
        backgroundColor: const Color(0xFFD7BE69),
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD7BE69)),
            )
          : roles.isEmpty
          ? const Center(child: Text("No roles found"))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: roles.length,
              itemBuilder: (context, index) {
                final role = roles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(role['name']),
                    subtitle: Text("ID: ${role['id']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            showEditRoleDialog(role['id'], role['name']);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Delete Role"),
                                content: const Text("Are you sure?"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Fluttertoast.showToast(
                                        msg: "Delete cancelled",
                                        backgroundColor: Colors.grey,
                                      );
                                    },
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      deleteRole(role['id']);
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
