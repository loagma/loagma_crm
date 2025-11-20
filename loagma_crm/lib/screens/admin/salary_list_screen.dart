import 'package:flutter/material.dart';
import '../../services/salary_service.dart';
import '../../utils/currency_formatter.dart';
import 'salary_form_screen.dart';

class SalaryListScreen extends StatefulWidget {
  const SalaryListScreen({super.key});

  @override
  State<SalaryListScreen> createState() => _SalaryListScreenState();
}

class _SalaryListScreenState extends State<SalaryListScreen> {
  List<dynamic> salaries = [];
  Map<String, dynamic>? statistics;
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final results = await Future.wait([
      SalaryService.getAllSalaries(search: searchQuery),
      SalaryService.getSalaryStatistics(),
    ]);

    if (mounted) {
      setState(() {
        if (results[0]['success']) {
          salaries = results[0]['data'];
        }
        if (results[1]['success']) {
          statistics = results[1]['data'];
        }
        isLoading = false;
      });
    }
  }

  void _searchSalaries(String query) {
    setState(() => searchQuery = query);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Management'),
        backgroundColor: const Color(0xFFD7BE69),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics Cards
                if (statistics != null) _buildStatisticsCards(),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, code, or email...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _searchSalaries('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: _searchSalaries,
                  ),
                ),

                // Salary List
                Expanded(
                  child: salaries.isEmpty
                      ? const Center(
                          child: Text('No salary information found'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: salaries.length,
                          itemBuilder: (context, index) {
                            final salary = salaries[index];
                            return _buildSalaryCard(salary);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SalaryFormScreen(),
            ),
          );
          if (result == true) _loadData();
        },
        backgroundColor: const Color(0xFFD7BE69),
        icon: const Icon(Icons.add),
        label: const Text('Add Salary'),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Employees',
                  statistics!['totalEmployees'].toString(),
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Total Gross Salary',
                  CurrencyFormatter.format(statistics!['totalGrossSalary']),
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Travel Allowance',
                  CurrencyFormatter.format(statistics!['totalTravelAllowance']),
                  Icons.directions_car,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  'Daily Allowance',
                  CurrencyFormatter.format(statistics!['totalDailyAllowance']),
                  Icons.calendar_today,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryCard(Map<String, dynamic> salary) {
    final employee = salary['employee'];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          employee['name'] ?? 'N/A',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Code: ${employee['employeeCode'] ?? 'N/A'}'),
            Text('Designation: ${employee['designation'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChip('Basic', salary['basicSalary'], Colors.blue),
                const SizedBox(width: 8),
                _buildChip('Travel', salary['travelAllowance'], Colors.orange),
                const SizedBox(width: 8),
                _buildChip('Daily', salary['dailyAllowance'], Colors.purple),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Net Salary: ${CurrencyFormatter.format(salary['netSalary'])}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SalaryFormScreen(
                      employeeId: employee['id'],
                      existingSalary: salary,
                    ),
                  ),
                );
                if (result == true) _loadData();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(employee['id'], employee['name']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: ${CurrencyFormatter.format(value ?? 0)}',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String employeeId, String employeeName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
            'Are you sure you want to delete salary information for $employeeName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await SalaryService.deleteSalary(employeeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
        if (result['success']) _loadData();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
