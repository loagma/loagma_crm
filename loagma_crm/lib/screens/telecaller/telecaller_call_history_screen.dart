import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/telecaller_api_service.dart';

class TelecallerCallHistoryScreen extends StatefulWidget {
  const TelecallerCallHistoryScreen({super.key});

  @override
  State<TelecallerCallHistoryScreen> createState() =>
      _TelecallerCallHistoryScreenState();
}

class _TelecallerCallHistoryScreenState
    extends State<TelecallerCallHistoryScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = TelecallerApiService.getCallHistory();
  }

  String _formatDateTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return iso;
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '-';
    final d = Duration(seconds: seconds);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m == 0) return '${s}s';
    return '${m}m ${s}s';
  }

  Future<void> _openRecording(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFD7BE69);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call History'),
        backgroundColor: primaryColor,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }
          if (snapshot.hasError) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Failed to load call history.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          }

          final result = snapshot.data ?? const {'success': false, 'data': []};
          final success = result['success'] == true;
          final List<dynamic> items =
              (result['data'] as List<dynamic>? ?? const []);

          if (!success) {
            final message = result['message'] as String? ??
                'Failed to load call history';
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            );
          }

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No calls found yet.\nStart calling leads and the history will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return Container(
            color: const Color(0xFFFDF7F7),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index] as Map<String, dynamic>;
                final account = item['account'] as Map<String, dynamic>?;
                final name =
                    (account?['personName'] as String?)?.trim().isNotEmpty ==
                            true
                        ? account!['personName'] as String
                        : (account?['businessName'] as String?) ??
                            'Unknown Lead';
                final phone = account?['contactNumber'] as String? ?? '';
                final status = item['status'] as String? ?? '';
                final calledAt = item['calledAt'] as String? ?? '';
                final duration = item['durationSec'] as int?;
                final notes = item['notes'] as String? ?? '';
                final recordingUrl = item['recordingUrl'] as String? ?? '';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: Colors.white,
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (phone.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        phone,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (recordingUrl.isNotEmpty)
                              IconButton(
                                icon: const Icon(
                                  Icons.play_circle_outline,
                                  color: primaryColor,
                                ),
                                tooltip: 'Play recording',
                                onPressed: () => _openRecording(recordingUrl),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDateTime(calledAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: $status    Duration: ${_formatDuration(duration)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Notes: $notes',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

