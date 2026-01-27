import 'package:flutter/material.dart';

class CustomerAllotmentScreen extends StatefulWidget {
  const CustomerAllotmentScreen({super.key});

  @override
  State<CustomerAllotmentScreen> createState() =>
      _CustomerAllotmentScreenState();
}

class _CustomerAllotmentScreenState extends State<CustomerAllotmentScreen> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // TODO: Initialize data loading
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SR Customer Allotment"),
        backgroundColor: const Color(0xFFD7BE69),
        automaticallyImplyLeading: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD7BE69)),
            )
          : _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to create/assign customer allotment
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create Customer Allotment - Coming Soon!'),
            ),
          );
        },
        backgroundColor: const Color(0xFFD7BE69),
        icon: const Icon(Icons.add),
        label: const Text('Assign Customer'),
      ),
    );
  }

  Widget _buildContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'SR Customer Allotment',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Assign customers to sales representatives for better territory management',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement customer allotment functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feature under development'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD7BE69),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            icon: const Icon(Icons.settings),
            label: const Text(
              'Configure Allotments',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
