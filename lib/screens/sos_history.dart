import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/meditrack_theme.dart';
import '../core/models.dart';
import '../core/database_helper.dart';

class SosHistoryScreen extends StatefulWidget {
  const SosHistoryScreen({super.key});

  @override
  State<SosHistoryScreen> createState() => _SosHistoryScreenState();
}

class _SosHistoryScreenState extends State<SosHistoryScreen> {
  List<SosLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final list = await DatabaseHelper.instance.getSosLogs();
      setState(() {
        _logs = list;
      });
    } catch (e) {
      debugPrint("Error loading SOS logs: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(String timestampStr) {
    try {
      final parsed = DateTime.parse(timestampStr);
      return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
    } catch (_) {
      return timestampStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('SOS Alert History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return _buildLogCard(log);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 80, color: context.colors.textHint),
            const SizedBox(height: 16),
            Text(
              'No SOS logs recorded',
              style: context.titleLarge.copyWith(color: context.colors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Your emergency trigger history will be stored here.',
              style: context.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(SosLog log) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: context.colors.errorSos, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Emergency SOS Alert',
                      style: context.titleMedium.copyWith(fontWeight: FontWeight.bold, color: context.colors.errorSos),
                    ),
                  ],
                ),
                Text(
                  _formatDateTime(log.timestamp),
                  style: context.labelSmall.copyWith(color: context.colors.textSecondary),
                ),
              ],
            ),
            const Divider(height: 16),
            _buildDetailRow('Contact Notified:', log.contactNotified ?? 'Primary Contact'),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildStatusIndicator('Call Dialed', log.callInitiated),
                const SizedBox(width: 12),
                _buildStatusIndicator('SMS Dispatched', log.smsSent),
              ],
            ),
            if (log.notes != null && log.notes!.isNotEmpty) ...[
              const Divider(height: 16),
              Text(
                'Notes:',
                style: context.bodySmall.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                log.notes!,
                style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: context.bodySmall.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: context.bodyMedium)),
      ],
    );
  }

  Widget _buildStatusIndicator(String label, bool success) {
    return Row(
      children: [
        Icon(
          success ? Icons.check_circle : Icons.cancel,
          size: 14,
          color: success ? context.colors.success : context.colors.textHint,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: context.labelSmall.copyWith(
            color: success ? context.colors.success : context.colors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
