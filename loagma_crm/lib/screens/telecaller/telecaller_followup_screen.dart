import 'package:flutter/material.dart';
import '../../services/telecaller_api_service.dart';

class TelecallerFollowupScreen extends StatefulWidget {
  const TelecallerFollowupScreen({super.key});

  @override
  State<TelecallerFollowupScreen> createState() =>
      _TelecallerFollowupScreenState();
}

class _TelecallerFollowupScreenState extends State<TelecallerFollowupScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _data = const {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await TelecallerApiService.getFollowups();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _data = result['data'] as Map<String, dynamic>? ?? const {};
      } else {
        _error = result['message']?.toString();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD7BE69);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow-up Management'),
        backgroundColor: primaryColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Overdue'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryColor),
              )
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_data['today'] as List? ?? const []),
                      _buildList(_data['upcoming'] as List? ?? const []),
                      _buildList(_data['overdue'] as List? ?? const []),
                    ],
                  ),
      ),
    );
  }

  Widget _buildList(List items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No follow-ups',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index] as Map<String, dynamic>;
        final account = item['account'] as Map<String, dynamic>? ?? const {};
        final leadName = (account['personName'] ??
                account['businessName'] ??
                'Unknown')
            .toString();
        final phone = account['contactNumber']?.toString() ?? '';
        final when = item['nextFollowupAt']?.toString();
        final notes = item['followupNotes']?.toString() ?? '';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(leadName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (phone.isNotEmpty) Text('📞 $phone'),
                if (when != null) Text('⏰ $when'),
                if (notes.isNotEmpty)
                  Text(
                    notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

