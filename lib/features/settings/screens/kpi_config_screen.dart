import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/theme_manager.dart';
import '../../dashboard/bloc/dashboard_bloc.dart';
import '../../dashboard/models/kpi_models.dart';
import '../../dashboard/services/dashboard_service.dart';

class KpiConfigScreen extends StatefulWidget {
  const KpiConfigScreen({super.key});

  @override
  State<KpiConfigScreen> createState() => _KpiConfigScreenState();
}

class _KpiConfigScreenState extends State<KpiConfigScreen> {
  final DashboardService _service = DashboardService();
  bool _isLoading = true;
  List<KpiConfigItem> _configs = [];
  bool _isSaving = false;

  final Map<String, String> _descriptions = {
    'available_inventory': 'Displays real-time available properties count and 2-level status breakdown.',
    'total_leads': 'Displays all ingested campaign and direct leads across dynamic sources.',
    'telecallers': 'Displays active telecaller team members and individual lead allocations.',
    'leads_allocated': 'Displays engine-allocated lead metrics and breakdown by telecaller.',
    'assigned_to_sales': 'Displays leads handed over to the sales closing team.',
    'site_visits_done': 'Displays completed site visits and detailed client visits list.',
    'deal_won': 'Displays successfully closed and won property deals.',
    'sales_users': 'Displays active sales users and full 10-status lifecycle performance.',
  };

  final Map<String, IconData> _icons = {
    'available_inventory': Icons.home_work_rounded,
    'total_leads': Icons.assignment_rounded,
    'telecallers': Icons.support_agent_rounded,
    'leads_allocated': Icons.assignment_ind_rounded,
    'assigned_to_sales': Icons.badge_rounded,
    'site_visits_done': Icons.location_on_rounded,
    'deal_won': Icons.emoji_events_rounded,
    'sales_users': Icons.groups_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    final list = await _service.getKpiConfig();
    if (mounted) {
      setState(() {
        _configs = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _onToggle(String kpiKey, bool isEnabled) async {
    setState(() {
      _configs = _configs.map((c) {
        if (c.kpiKey == kpiKey) return c.copyWith(isEnabled: isEnabled);
        return c;
      }).toList();
      _isSaving = true;
    });

    // Notify DashboardBloc so main dashboard updates reactively
    context.read<DashboardBloc>().add(ToggleKpiConfig(kpiKey: kpiKey, isEnabled: isEnabled));

    final payload = _configs.map((c) => c.toJson()).toList();
    final ok = await _service.updateKpiConfig(payload);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'KPI configuration updated.'
              : 'Failed to update KPI configuration.'),
          backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KPI Configuration'),
        centerTitle: false,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ThemeManager().primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ThemeManager().primaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.tune_rounded, color: ThemeManager().primaryColor, size: 28),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Admin KPI Visibility Control',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Toggle which KPI cards are evaluated and displayed on the main Admin Dashboard. Disabled KPIs skip backend queries.',
                                    style: TextStyle(fontSize: 13, color: subColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _configs.length,
                        separatorBuilder: (context, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final cfg = _configs[index];
                          final icon = _icons[cfg.kpiKey] ?? Icons.insights_rounded;
                          final desc = _descriptions[cfg.kpiKey] ?? 'Dashboard metric widget.';

                          return Container(
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cfg.isEnabled ? borderColor : borderColor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: SwitchListTile(
                              value: cfg.isEnabled,
                              onChanged: (val) => _onToggle(cfg.kpiKey, val),
                              activeThumbColor: ThemeManager().primaryColor,
                              secondary: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: cfg.isEnabled
                                      ? ThemeManager().primaryColor.withValues(alpha: 0.12)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  icon,
                                  color: cfg.isEnabled ? ThemeManager().primaryColor : Colors.grey,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                cfg.kpiLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: cfg.isEnabled ? textColor : subColor,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  desc,
                                  style: TextStyle(fontSize: 12, color: subColor),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
