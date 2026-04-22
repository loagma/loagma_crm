// Quick test file to verify AuthService is working
// Run with: flutter run lib/test_auth_service.dart

import 'package:flutter/material.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const AuthServiceTestApp());
}

class AuthServiceTestApp extends StatelessWidget {
  const AuthServiceTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Service Test',
      home: const AuthServiceTestScreen(),
    );
  }
}

class AuthServiceTestScreen extends StatefulWidget {
  const AuthServiceTestScreen({super.key});

  @override
  State<AuthServiceTestScreen> createState() => _AuthServiceTestScreenState();
}

class _AuthServiceTestScreenState extends State<AuthServiceTestScreen> {
  String? _userId;
  String? _userName;
  String? _userRole;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final userId = await AuthService.getUserId();
    final userName = await AuthService.getUserName();
    final userRole = await AuthService.getUserRole();
    final isLoggedIn = await AuthService.isLoggedIn();

    setState(() {
      _userId = userId;
      _userName = userName;
      _userRole = userRole;
      _isLoggedIn = isLoggedIn;
    });
  }

  Future<void> _saveTestUser() async {
    await AuthService.saveUserData(
      userId: 'TEST_SALESMAN_001',
      userName: 'Test Salesman',
      userRole: 'SALESMAN',
    );
    _checkAuth();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Test user saved!')));
    }
  }

  Future<void> _clearUser() async {
    await AuthService.clearUserData();
    _checkAuth();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User data cleared!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Service Test'),
        backgroundColor: const Color(0xFFD7BE69),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current User Data',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Logged In:', _isLoggedIn ? 'Yes' : 'No'),
                    _buildInfoRow('User ID:', _userId ?? 'Not set'),
                    _buildInfoRow('User Name:', _userName ?? 'Not set'),
                    _buildInfoRow('User Role:', _userRole ?? 'Not set'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTestUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD7BE69),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Test User'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _clearUser,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Clear User Data'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checkAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Refresh'),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Instructions:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Click "Save Test User" to save a test salesman ID\n'
              '2. Check that User ID shows: TEST_SALESMAN_001\n'
              '3. Now Visit In/Out will work with this ID\n'
              '4. In production, your login flow should call:\n'
              '   AuthService.saveUserData() after successful login',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: value == 'Not set' ? Colors.red : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
