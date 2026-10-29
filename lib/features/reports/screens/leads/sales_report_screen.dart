import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/theme/theme_manager.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  late Future<List<Map<String, dynamic>>> _report;

  @override
  void initState() {
    super.initState();
    _report = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final response = await DioClient.dio.get('/reports/sales');
    final data = response.data;
    final rows = data is Map && data['data'] is List ? data['data'] as List : const [];
    return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _report,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            final message = error is DioException
                ? (error.response?.data is Map ? error.response?.data['message']?.toString() : null) ?? 'The sales report could not be loaded.'
                : 'The sales report could not be loaded.';
            return _Message(
              title: 'Sales report unavailable',
              body: message,
              onRetry: () => setState(() => _report = _load()),
            );
          }
          final rows = snapshot.data ?? const [];
          if (rows.isEmpty) {
            return _Message(
              title: 'No sales assignments',
              body: 'No salesperson in this organization has assigned leads for the current filters.',
              onBack: () => context.go('/reports/leads/overall-business-insight'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Sales Team Report', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Text('Assigned leads, completed site visits, won and lost deals. Counts come from the report API.', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              const SizedBox(height: 16),
              ...rows.map((row) => Card(
                    child: ListTile(
                      title: Text(row['name']?.toString() ?? 'Sales'),
                      subtitle: Text(
                        'Assigned ${row['assigned_leads'] ?? 0} · Visits done ${row['site_visits_done'] ?? 0} · Won ${row['deals_won'] ?? 0} · Lost ${row['deals_lost'] ?? 0}',
                      ),
                      trailing: Text('${row['conversion_rate'] ?? 0}%'),
                    ),
                  )),
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
            if (onRetry != null)
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            if (onBack != null)
              TextButton(onPressed: onBack, child: const Text('Back to Overall Business Insight')),
          ],
        ),
      ),
    );
  }
}
