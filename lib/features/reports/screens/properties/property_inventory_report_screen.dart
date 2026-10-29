import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/theme/theme_manager.dart';

class PropertyInventoryReportScreen extends StatefulWidget {
  const PropertyInventoryReportScreen({super.key});

  @override
  State<PropertyInventoryReportScreen> createState() => _PropertyInventoryReportScreenState();
}

class _PropertyInventoryReportScreenState extends State<PropertyInventoryReportScreen> {
  late Future<Map<String, dynamic>> _report;

  @override
  void initState() {
    super.initState();
    _report = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final response = await DioClient.dio.get('/reports/properties');
    final data = response.data;
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    return const {};
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _report,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is DioException
                ? (error.response?.data is Map ? error.response?.data['message']?.toString() : null) ?? 'The property report could not be loaded.'
                : 'The property report could not be loaded.';
            return _Message(
              title: 'Property report unavailable',
              body: message,
              onRetry: () => setState(() => _report = _load()),
            );
          }
          final data = snapshot.data ?? const {};
          final summary = data['summary'] is List ? data['summary'] as List : const [];
          final rows = data['rows'] is List ? data['rows'] as List : const [];
          if (summary.isEmpty && rows.isEmpty) {
            return _Message(
              title: 'No properties',
              body: 'This organization has no properties for the current filters.',
              onBack: () => context.go('/reports/leads/overall-business-insight'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Property inventory', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Text('Total ${data['total'] ?? 0}. Counts are grouped by property status.', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: summary.map((item) {
                  final row = Map<String, dynamic>.from(item as Map);
                  return Chip(label: Text('${row['status']}: ${row['count']}'));
                }).toList(),
              ),
              const SizedBox(height: 16),
              ...rows.map((item) {
                final row = Map<String, dynamic>.from(item as Map);
                return Card(
                  child: ListTile(
                    title: Text(row['title']?.toString() ?? row['property_code']?.toString() ?? 'Property'),
                    subtitle: Text('${row['status'] ?? ''} · ${row['listing_type'] ?? ''} · ${row['locality'] ?? ''}'),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  const _Message({required this.title, required this.body, this.onRetry, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (onRetry != null) ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            if (onBack != null) TextButton(onPressed: onBack, child: const Text('Back to Leads Reports')),
          ],
        ),
      ),
    );
  }
}
