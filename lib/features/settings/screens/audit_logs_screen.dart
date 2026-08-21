import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/skeletons.dart';
import '../../dashboard/models/dashboard_summary.dart';
import '../../dashboard/repository/dashboard_repository.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final DashboardRepository _repository = DashboardRepository();
  bool _isLoading = true;
  String? _errorMessage;
  List<RecentActivity> _allActivities = [];
  String _searchQuery = '';
  String _selectedModule = 'All';

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _repository.getDashboardData();
      setState(() {
        _allActivities = data.activity;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<String> get _availableModules {
    final modules = {'All'};
    for (final act in _allActivities) {
      if (act.module.isNotEmpty) {
        modules.add(act.module);
      }
    }
    return modules.toList();
  }

  List<RecentActivity> get _filteredActivities {
    return _allActivities.where((act) {
      final matchesSearch = _searchQuery.isEmpty ||
          act.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          act.user.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          act.module.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          act.action.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesModule = _selectedModule == 'All' ||
          act.module.toLowerCase() == _selectedModule.toLowerCase();

      return matchesSearch && matchesModule;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredActivities;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Audit Logs',
          style: CRMTypography.sectionTitle.copyWith(
            color: CRMColors.textOf(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: CRMColors.cardBgOf(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: CRMColors.shadow,
        iconTheme: IconThemeData(color: CRMColors.textOf(context)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAuditLogs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(CRMSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audit Activity History',
                style: CRMTypography.caption.copyWith(
                  color: CRMColors.textSecondaryOf(context),
                ),
              ),
              Text(
                'System Audit & Action Trace Logs',
                style: CRMTypography.pageTitle.copyWith(
                  color: CRMColors.textOf(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: CRMSpacing.m),

              // Search & Filter controls
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search audit logs by description, user, module...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: CRMColors.cardBgOf(context),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: CRMSpacing.m,
                          vertical: CRMSpacing.s,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                          borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                          borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                          borderSide: BorderSide(color: CRMColors.primaryOf(context), width: 1.5),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val.trim());
                      },
                    ),
                  ),
                  const SizedBox(width: CRMSpacing.s),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: CRMColors.primary),
                    onPressed: _loadAuditLogs,
                    tooltip: 'Reload Logs',
                  ),
                ],
              ),
              const SizedBox(height: CRMSpacing.m),

              // Module Filter Chips
              if (_allActivities.isNotEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _availableModules.map((mod) {
                      final isSelected = _selectedModule == mod;
                      return Padding(
                        padding: const EdgeInsets.only(right: CRMSpacing.xs),
                        child: ChoiceChip(
                          label: Text(mod),
                          selected: isSelected,
                          selectedColor: CRMColors.primary.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? CRMColors.primary : CRMColors.textSecondaryOf(context),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedModule = mod);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: CRMSpacing.m),
              ],

              // Content Body
              if (_isLoading)
                const CRMListSkeleton(count: 5)
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(CRMSpacing.xl),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline_rounded, color: CRMColors.danger, size: 48),
                        const SizedBox(height: CRMSpacing.s),
                        Text('Failed to load audit logs', style: CRMTypography.sectionTitle),
                        const SizedBox(height: 4),
                        Text(_errorMessage!, style: TextStyle(color: CRMColors.textSecondaryOf(context))),
                        const SizedBox(height: CRMSpacing.m),
                        ElevatedButton(onPressed: _loadAuditLogs, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(CRMSpacing.xl),
                    child: Column(
                      children: [
                        Icon(Icons.history_toggle_off_rounded, color: CRMColors.textMutedOf(context), size: 48),
                        const SizedBox(height: CRMSpacing.s),
                        Text(
                          'No audit activities found.',
                          style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: CRMSpacing.s),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildAuditLogCard(item);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuditLogCard(RecentActivity activity) {
    final dateStr = activity.timestamp.length >= 10
        ? activity.timestamp.substring(0, 10)
        : activity.timestamp;

    return CRMCard(
      elevated: true,
      child: Padding(
        padding: const EdgeInsets.all(CRMSpacing.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: CRMColors.primary.withOpacity(0.12),
              radius: 20,
              child: Icon(Icons.history_rounded, color: CRMColors.primary, size: 20),
            ),
            const SizedBox(width: CRMSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          activity.description,
                          style: CRMTypography.bodyMedium.copyWith(
                            color: CRMColors.textOf(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (activity.module.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: CRMColors.info.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                          ),
                          child: Text(
                            activity.module.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: CRMColors.info,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 14, color: CRMColors.textSecondaryOf(context)),
                      const SizedBox(width: 4),
                      Text(
                        'User: ${activity.user}',
                        style: CRMTypography.caption.copyWith(
                          color: CRMColors.textSecondaryOf(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time_rounded, size: 14, color: CRMColors.textSecondaryOf(context)),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: CRMTypography.caption.copyWith(
                          color: CRMColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
