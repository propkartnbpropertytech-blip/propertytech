import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/theme/theme_manager.dart';
import '../models/business_insight_summary.dart';
import '../services/business_insight_service.dart';

// ============================================================================
// 1. LEAD SOURCE GRID VIEW (Total Leads Click)
// ============================================================================
class _SourceCardChip {
  final String label;
  final String tabTarget;

  const _SourceCardChip(this.label, this.tabTarget);
}

// ============================================================================
// 1. LEAD SOURCE GRID VIEW (Total Leads Click)
// ============================================================================
class LeadSourceGridView extends StatelessWidget {
  final BusinessInsightSummary summary;
  final VoidCallback onBack;
  final void Function(String source, {String? initialTab}) onSelectSource;

  const LeadSourceGridView({
    super.key,
    required this.summary,
    required this.onBack,
    required this.onSelectSource,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = CRMColors.primary;

    final meta = summary.sources['meta'] ?? const SourceSummary(total: 0, propertyListing: 0, requirement: 0);
    final housing = summary.sources['housing'] ?? const SourceSummary(total: 0, propertyListing: 0, requirement: 0);
    final webhook = summary.sources['webhook'] ?? const SourceSummary(total: 0, propertyListing: 0, requirement: 0);
    final manual = summary.sources['manual'] ?? const SourceSummary(total: 0, propertyListing: 0, requirement: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb
        _buildBreadcrumb(context, 'Overall Business Insights', onBack),
        const SizedBox(height: CRMSpacing.m),

        // Header
        _buildDrilldownHeader(
          context: context,
          title: 'Total Leads by Source',
          subtitle: 'Overall: ${summary.totalLeads} total leads across all acquisition channels (including rejected & not interested).',
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Total Leads: ${summary.totalLeads}',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: CRMSpacing.l),

        // 4 Source Cards Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 700;
            final cardWidth = isSmall ? constraints.maxWidth : (constraints.maxWidth - 16) / 2;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                // Meta Card
                _buildSourceCard(
                  context,
                  width: cardWidth,
                  title: 'Meta',
                  subtitle: 'Facebook & Instagram Ad Campaigns',
                  count: meta.total,
                  icon: Icons.campaign_rounded,
                  color: const Color(0xFF1877F2),
                  chips: [
                    _SourceCardChip('Property Listing: ${meta.propertyListing}', 'Property Listing Leads'),
                    _SourceCardChip('Requirement: ${meta.requirement}', 'Requirement Leads'),
                    _SourceCardChip('Not Interested: ${meta.notInterested}', 'Not Interested'),
                  ],
                  onTap: () => onSelectSource('Meta'),
                  onChipTap: (target) => onSelectSource('Meta', initialTab: target),
                ),

                // Housing Card
                _buildSourceCard(
                  context,
                  width: cardWidth,
                  title: 'Housing',
                  subtitle: 'Housing.com Portal Inquiries',
                  count: housing.total,
                  icon: Icons.home_work_rounded,
                  color: const Color(0xFF0D9488),
                  chips: [
                    _SourceCardChip('Property Listing: ${housing.propertyListing}', 'Property Listing Leads'),
                    _SourceCardChip('Requirement: ${housing.requirement}', 'Requirement Leads'),
                    _SourceCardChip('Not Interested: ${housing.notInterested}', 'Not Interested'),
                  ],
                  onTap: () => onSelectSource('Housing'),
                  onChipTap: (target) => onSelectSource('Housing', initialTab: target),
                ),

                // Webhook Card
                _buildSourceCard(
                  context,
                  width: cardWidth,
                  title: 'Webhook',
                  subtitle: 'External API & Webhook Integrations',
                  count: webhook.total,
                  icon: Icons.webhook_rounded,
                  color: const Color(0xFF7C3AED),
                  chips: [
                    _SourceCardChip('Property Listing: ${webhook.propertyListing}', 'Property Listing Leads'),
                    _SourceCardChip('Requirement: ${webhook.requirement}', 'Requirement Leads'),
                    _SourceCardChip('Not Interested: ${webhook.notInterested}', 'Not Interested'),
                  ],
                  onTap: () => onSelectSource('Webhook'),
                  onChipTap: (target) => onSelectSource('Webhook', initialTab: target),
                ),

                // Manually Added Card
                _buildSourceCard(
                  context,
                  width: cardWidth,
                  title: 'Manually Added',
                  subtitle: 'Direct CRM Entry & Internal Sourcing',
                  count: manual.total,
                  icon: Icons.person_add_alt_1_rounded,
                  color: const Color(0xFFEA580C),
                  chips: [
                    _SourceCardChip('Total Requirement: ${manual.requirement}', 'Requirement Leads'),
                    _SourceCardChip('Rejected Leads: ${manual.rejected}', 'Rejected Leads'),
                  ],
                  onTap: () => onSelectSource('Manually Added'),
                  onChipTap: (target) => onSelectSource('Manually Added', initialTab: target),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSourceCard(
    BuildContext context, {
    required double width,
    required String title,
    required String subtitle,
    required int count,
    required IconData icon,
    required Color color,
    required List<_SourceCardChip> chips,
    required VoidCallback onTap,
    required void Function(String tabName) onChipTap,
  }) {
    final isDark = ThemeManager().isDarkMode;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips.map((c) {
                return InkWell(
                  onTap: () => onChipTap(c.tabTarget),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      c.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View $title Leads',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. SOURCE-LEVEL LEAD DETAIL VIEW (Meta / Housing / Webhook / Manually Added)
// ============================================================================
class _SourceTabItem {
  final String label;
  final int count;
  final IconData icon;
  final String? leadType;
  final String? kpi;

  const _SourceTabItem({
    required this.label,
    required this.count,
    required this.icon,
    this.leadType,
    this.kpi,
  });
}

class SourceLeadsDetailView extends StatefulWidget {
  final String source;
  final BusinessInsightSummary summary;
  final VoidCallback onBack;
  final String? initialTab;
  final DateTime? from;
  final DateTime? to;

  const SourceLeadsDetailView({
    super.key,
    required this.source,
    required this.summary,
    required this.onBack,
    this.initialTab,
    this.from,
    this.to,
  });

  @override
  State<SourceLeadsDetailView> createState() => _SourceLeadsDetailViewState();
}

class _SourceLeadsDetailViewState extends State<SourceLeadsDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<_SourceTabItem> _tabs;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _initTabs();
  }

  @override
  void didUpdateWidget(covariant SourceLeadsDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.summary != widget.summary ||
        oldWidget.from != widget.from ||
        oldWidget.to != widget.to) {
      _tabController.dispose();
      _initTabs();
    }
  }

  void _initTabs() {
    final s = _sourceSummary;
    final isManual = widget.source.toLowerCase().contains('manual');

    if (isManual) {
      _tabs = [
        _SourceTabItem(
          label: 'Requirement Leads',
          count: s.requirement,
          icon: Icons.manage_search_rounded,
          leadType: 'Requirement',
        ),
        _SourceTabItem(
          label: 'Rejected Leads',
          count: s.rejected,
          icon: Icons.cancel_rounded,
          kpi: 'rejected',
        ),
      ];
    } else {
      _tabs = [
        _SourceTabItem(
          label: 'Property Listing Leads',
          count: s.propertyListing,
          icon: Icons.apartment_rounded,
          leadType: 'Property Listing',
        ),
        _SourceTabItem(
          label: 'Requirement Leads',
          count: s.requirement,
          icon: Icons.manage_search_rounded,
          leadType: 'Requirement',
        ),
        _SourceTabItem(
          label: 'Not Interested',
          count: s.notInterested,
          icon: Icons.thumb_down_rounded,
          kpi: 'not_interested',
        ),
      ];
    }

    int initialIndex = 0;
    if (widget.initialTab != null && widget.initialTab!.isNotEmpty) {
      final target = widget.initialTab!.toLowerCase();
      final idx = _tabs.indexWhere((t) {
        final l = t.label.toLowerCase();
        return l == target ||
            (target.contains('not interested') && l.contains('not interested')) ||
            (target.contains('rejected') && l.contains('rejected')) ||
            (target.contains('listing') && l.contains('listing')) ||
            (target.contains('requirement') && l.contains('requirement'));
      });
      if (idx != -1) {
        initialIndex = idx;
      }
    }

    _activeTabIndex = initialIndex;
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _activeTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  SourceSummary get _sourceSummary {
    final key = widget.source.toLowerCase().contains('meta')
        ? 'meta'
        : widget.source.toLowerCase().contains('housing')
            ? 'housing'
            : widget.source.toLowerCase().contains('webhook')
                ? 'webhook'
                : 'manual';
    return widget.summary.sources[key] ?? const SourceSummary(total: 0, propertyListing: 0, requirement: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;
    final s = _sourceSummary;
    final isManual = widget.source.toLowerCase().contains('manual');
    final activeTab = _tabs[_activeTabIndex.clamp(0, _tabs.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb
        _buildBreadcrumb(context, 'Lead Sources', widget.onBack),
        const SizedBox(height: CRMSpacing.m),

        // Title Row
        _buildDrilldownHeader(
          context: context,
          title: '${widget.source} Leads',
          subtitle: isManual
              ? 'Total: ${s.total} manually added leads (${s.requirement} Requirement, ${s.rejected} Rejected).'
              : 'Total: ${s.total} leads (${s.propertyListing} Property Listing, ${s.requirement} Requirement, ${s.notInterested} Not Interested).',
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Total: ${s.total}',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: CRMSpacing.m),

        // Tabs (Available for all sources including Manually Added)
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: primaryColor,
            unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            indicatorColor: primaryColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            tabs: _tabs.map((t) {
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.icon, size: 16),
                    const SizedBox(width: 8),
                    Text('${t.label} (${t.count})'),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: CRMSpacing.m),

        // Lead Table
        LeadRecordTableView(
          key: ValueKey('${widget.source}_${activeTab.label}_${activeTab.leadType}_${activeTab.kpi}_${widget.from}_${widget.to}'),
          source: widget.source,
          leadType: activeTab.leadType,
          kpi: activeTab.kpi,
          from: widget.from,
          to: widget.to,
        ),
      ],
    );
  }
}

// ============================================================================
// 3. PROPERTY LISTING LEADS DEDICATED VIEW (2nd KPI Click)
// ============================================================================
class PropertyListingLeadsView extends StatefulWidget {
  final BusinessInsightSummary summary;
  final VoidCallback onBack;
  final DateTime? from;
  final DateTime? to;

  const PropertyListingLeadsView({
    super.key,
    required this.summary,
    required this.onBack,
    this.from,
    this.to,
  });

  @override
  State<PropertyListingLeadsView> createState() => _PropertyListingLeadsViewState();
}

class _PropertyListingLeadsViewState extends State<PropertyListingLeadsView> {
  String _selectedSource = 'All';
  String _selectedKpi = 'all';

  @override
  Widget build(BuildContext context) {
    final prop = widget.summary.propertyListingLeads;
    final kpis = prop.getKpisForSource(_selectedSource);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb
        _buildBreadcrumb(context, 'Overall Business Insights', widget.onBack),
        const SizedBox(height: CRMSpacing.m),

        // Title
        _buildDrilldownHeader(
          context: context,
          title: 'Property Listing Leads',
          subtitle: 'Overall count from Meta (${prop.bySource['meta'] ?? 0}), Housing (${prop.bySource['housing'] ?? 0}), and Webhook (${prop.bySource['webhook'] ?? 0}).',
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
            ),
            child: Text(
              '${_selectedSource == 'All' ? 'Total' : _selectedSource} Listing: ${kpis.totalListingLeads}',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0284C7),
              ),
            ),
          ),
        ),
        const SizedBox(height: CRMSpacing.m),

        // Source Filter Chips
        Wrap(
          spacing: 8,
          children: [
            _buildSourceChip('All Sources', 'All', prop.total),
            _buildSourceChip('Meta', 'Meta', prop.bySource['meta'] ?? 0),
            _buildSourceChip('Housing', 'Housing', prop.bySource['housing'] ?? 0),
            _buildSourceChip('Webhook', 'Webhook', prop.bySource['webhook'] ?? 0),
          ],
        ),
        const SizedBox(height: CRMSpacing.m),

        // 8 Clickable KPI Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 600 ? 2 : (constraints.maxWidth < 1000 ? 4 : 4);
            final spacing = 10.0;
            final cardWidth = (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                _buildClickableKpi(
                  title: 'Total Listing Leads',
                  count: kpis.totalListingLeads,
                  kpiKey: 'all',
                  icon: Icons.apartment_rounded,
                  color: const Color(0xFF14213D),
                  width: cardWidth,
                ),
                _buildClickableKpi(
                  title: 'Call Outcomes',
                  count: kpis.callOutcomes,
                  kpiKey: 'call_outcomes',
                  icon: Icons.phone_callback_rounded,
                  color: const Color(0xFF0284C7),
                  width: cardWidth,
                ),
                _buildClickableKpi(
                  title: 'Follow-Ups',
                  count: kpis.followUps,
                  kpiKey: 'follow_ups',
                  icon: Icons.update_rounded,
                  color: const Color(0xFFD97706),
                  width: cardWidth,
                ),
                _buildClickableKpi(
                  title: 'CNR',
                  count: kpis.cnr,
                  kpiKey: 'cnr',
                  icon: Icons.phone_missed_rounded,
                  color: const Color(0xFFE11D48),
                  width: cardWidth,
                ),
                _buildClickableKpi(
                  title: 'Callback',
                  count: kpis.callback,
                  kpiKey: 'callback',
                  icon: Icons.call_end_rounded,
                  color: const Color(0xFF0D9488),
                  width: cardWidth,
                ),
                _buildClickableKpi(
                  title: 'Not Interested',
                  count: kpis.notInterested,
                  kpiKey: 'not_interested',
                  icon: Icons.thumb_down_alt_outlined,
                  color: const Color(0xFFDC2626),
                  width: cardWidth,
                ),
                _buildClickableKpi(
                  title: 'Archived Property',
                  count: kpis.archivedProperty,
                  kpiKey: 'archived_property',
                  icon: Icons.archive_outlined,
                  color: const Color(0xFF64748B),
                  width: cardWidth,
                ),
                _buildClickableKpi(
                  title: 'Wrong Lead',
                  count: kpis.wrongLead,
                  kpiKey: 'wrong_lead',
                  icon: Icons.error_outline_rounded,
                  color: const Color(0xFF9333EA),
                  width: cardWidth,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: CRMSpacing.m),

        // Lead Table
        LeadRecordTableView(
          key: ValueKey('prop_${_selectedSource}_${_selectedKpi}_${widget.from}_${widget.to}'),
          source: _selectedSource,
          leadType: 'Property Listing',
          kpi: _selectedKpi,
          from: widget.from,
          to: widget.to,
        ),
      ],
    );
  }

  Widget _buildSourceChip(String label, String value, int count) {
    final isSelected = _selectedSource == value;
    final primaryColor = CRMColors.primary;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedSource = value;
          _selectedKpi = 'all';
        });
      },
      selectedColor: primaryColor.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? primaryColor : null,
      ),
    );
  }

  Widget _buildClickableKpi({
    required String title,
    required int count,
    required String kpiKey,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    final isDark = ThemeManager().isDarkMode;
    final isSelected = _selectedKpi == kpiKey;

    return InkWell(
      onTap: () {
        setState(() => _selectedKpi = isSelected ? 'all' : kpiKey);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.25 : 0.1)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? color : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, size: 20, color: color),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 4. REQUIREMENT LEADS DEDICATED VIEW (3rd KPI Click)
// ============================================================================
class RequirementLeadsView extends StatefulWidget {
  final BusinessInsightSummary summary;
  final VoidCallback onBack;
  final DateTime? from;
  final DateTime? to;

  const RequirementLeadsView({
    super.key,
    required this.summary,
    required this.onBack,
    this.from,
    this.to,
  });

  @override
  State<RequirementLeadsView> createState() => _RequirementLeadsViewState();
}

class _RequirementLeadsViewState extends State<RequirementLeadsView> {
  String _selectedSource = 'All';
  String _selectedKpi = 'all';

  @override
  Widget build(BuildContext context) {
    final req = widget.summary.requirementLeads;
    final kpis = req.getKpisForSource(_selectedSource);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb
        _buildBreadcrumb(context, 'Overall Business Insights', widget.onBack),
        const SizedBox(height: CRMSpacing.m),

        // Title
        _buildDrilldownHeader(
          context: context,
          title: 'Requirement Leads',
          subtitle: 'Overall count from Meta (${req.bySource['meta'] ?? 0}), Housing (${req.bySource['housing'] ?? 0}), and Webhook (${req.bySource['webhook'] ?? 0}).',
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.3)),
            ),
            child: Text(
              '${_selectedSource == 'All' ? 'Total' : _selectedSource} Req: ${kpis.totalRequirementLeads}',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D9488),
              ),
            ),
          ),
        ),
        const SizedBox(height: CRMSpacing.m),

        // Source Filter Chips
        Wrap(
          spacing: 8,
          children: [
            _buildSourceChip('All Sources', 'All', req.total),
            _buildSourceChip('Meta', 'Meta', req.bySource['meta'] ?? 0),
            _buildSourceChip('Housing', 'Housing', req.bySource['housing'] ?? 0),
            _buildSourceChip('Webhook', 'Webhook', req.bySource['webhook'] ?? 0),
          ],
        ),
        const SizedBox(height: CRMSpacing.m),

        // 8 Clickable KPI Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 600 ? 2 : (constraints.maxWidth < 1000 ? 4 : 4);
            final spacing = 10.0;
            final cardWidth = (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                _buildClickableKpi(
                  title: 'Total Requirement Leads',
                  count: kpis.totalRequirementLeads,
                  kpiKey: 'all',
                  icon: Icons.manage_search_rounded,
                  color: const Color(0xFF14213D),
                  width: cardWidth,
                ),
                _buildClickableKpi(
                  title: 'Follow-Ups',
                  count: kpis.followUps,
                  kpiKey: 'follow_ups',
                  icon: Icons.update_rounded,
                  color: const Color(0xFFD97706),
                  width: cardWidth,
                ),
                _buildClickableKpi(
                  title: 'Wrong Lead',
                  count: kpis.wrongLead,
                  kpiKey: 'wrong_lead',
                  icon: Icons.error_outline_rounded,
                  color: const Color(0xFF9333EA),
                  width: cardWidth,
                ),
                _buildClickableKpi(
                  title: 'Not Interested',
                  count: kpis.notInterested,
                  kpiKey: 'not_interested',
                  icon: Icons.thumb_down_alt_outlined,
                  color: const Color(0xFFDC2626),
                  width: cardWidth,
                ),
                _buildClickableKpi(
                  title: 'Archived',
                  count: kpis.archived,
                  kpiKey: 'archived',
                  icon: Icons.archive_outlined,
                  color: const Color(0xFF64748B),
                  width: cardWidth,
                ),
                _buildClickableKpi(
                  title: 'Transfer / Picked Up',
                  count: kpis.transferPickedUp,
                  kpiKey: 'transfer_picked_up',
                  icon: Icons.move_up_rounded,
                  color: const Color(0xFF2563EB),
                  width: cardWidth,
                ),
                _buildClickableKpi(
                  title: 'Callback',
                  count: kpis.callback,
                  kpiKey: 'callback',
                  icon: Icons.call_end_rounded,
                  color: const Color(0xFF0D9488),
                  width: cardWidth,
                ),
                _buildClickableKpi(
                  title: 'CNR',
                  count: kpis.cnr,
                  kpiKey: 'cnr',
                  icon: Icons.phone_missed_rounded,
                  color: const Color(0xFFE11D48),
                  width: cardWidth,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: CRMSpacing.m),

        // Lead Table
        LeadRecordTableView(
          key: ValueKey('req_${_selectedSource}_${_selectedKpi}_${widget.from}_${widget.to}'),
          source: _selectedSource,
          leadType: 'Requirement',
          kpi: _selectedKpi,
          from: widget.from,
          to: widget.to,
        ),
      ],
    );
  }

  Widget _buildSourceChip(String label, String value, int count) {
    final isSelected = _selectedSource == value;
    final primaryColor = CRMColors.primary;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedSource = value;
          _selectedKpi = 'all';
        });
      },
      selectedColor: primaryColor.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? primaryColor : null,
      ),
    );
  }

  Widget _buildClickableKpi({
    required String title,
    required int count,
    required String kpiKey,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    final isDark = ThemeManager().isDarkMode;
    final isSelected = _selectedKpi == kpiKey;

    return InkWell(
      onTap: () {
        setState(() => _selectedKpi = isSelected ? 'all' : kpiKey);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.25 : 0.1)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? color : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, size: 20, color: color),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 5. TELECALLERS LIST VIEW (4th KPI Click)
// ============================================================================
class TelecallersListView extends StatelessWidget {
  final BusinessInsightSummary summary;
  final VoidCallback onBack;
  final Function(TelecallerSummaryItem telecaller) onSelectTelecaller;

  const TelecallersListView({
    super.key,
    required this.summary,
    required this.onBack,
    required this.onSelectTelecaller,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = CRMColors.primary;
    final telecallers = summary.telecallers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb
        _buildBreadcrumb(context, 'Overall Business Insights', onBack),
        const SizedBox(height: CRMSpacing.m),

        // Header
        _buildDrilldownHeader(
          context: context,
          title: 'Telecallers Performance & Leads',
          subtitle: 'Total Active Telecallers: ${telecallers.totalCount}. Select a telecaller to inspect assigned lead breakdowns.',
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              'Telecallers: ${telecallers.totalCount}',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: CRMSpacing.l),

        // Telecaller Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 700;
            final cardWidth = isSmall ? constraints.maxWidth : (constraints.maxWidth - 16) / 2;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: telecallers.list.map((tc) {
                return _buildTelecallerCard(context, cardWidth, tc);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTelecallerCard(BuildContext context, double width, TelecallerSummaryItem tc) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    return InkWell(
      onTap: () => onSelectTelecaller(tc),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: primaryColor.withValues(alpha: 0.15),
                        child: Text(
                          tc.name.isNotEmpty ? tc.name[0].toUpperCase() : 'T',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tc.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              tc.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${tc.totalLeads}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      'Assigned Leads',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Lead Type Breakdown
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Property Listing',
                          style: TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${tc.propListingLeads}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Requirement',
                          style: TextStyle(fontSize: 11, color: Color(0xFF0D9488), fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${tc.reqLeads}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status counts
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildStatusChip('Contacted: ${tc.statusCounts.contacted}', const Color(0xFF2563EB)),
                _buildStatusChip('CNR: ${tc.statusCounts.cnr}', const Color(0xFFE11D48)),
                _buildStatusChip('Callback: ${tc.statusCounts.callback}', const Color(0xFFD97706)),
                _buildStatusChip('Sales: ${tc.statusCounts.handedToSales}', const Color(0xFF16A34A)),
                _buildStatusChip('Not Interested: ${tc.statusCounts.notInterested}', const Color(0xFFDC2626)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View Detail Leads',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14, color: primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ============================================================================
// 6. TELECALLER DETAIL VIEW
// ============================================================================
class TelecallerDetailView extends StatefulWidget {
  final TelecallerSummaryItem telecaller;
  final VoidCallback onBack;
  final DateTime? from;
  final DateTime? to;

  const TelecallerDetailView({
    super.key,
    required this.telecaller,
    required this.onBack,
    this.from,
    this.to,
  });

  @override
  State<TelecallerDetailView> createState() => _TelecallerDetailViewState();
}

class _TelecallerDetailViewState extends State<TelecallerDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSource = 'All';
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _activeTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  TelecallerSourceBreakdown get _currentBreakdown {
    final key = _selectedSource == 'All'
        ? 'all'
        : _selectedSource.toLowerCase();
    return widget.telecaller.sources[key] ??
        const TelecallerSourceBreakdown(prop: 0, req: 0, total: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;
    final tc = widget.telecaller;
    final bd = _currentBreakdown;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb
        _buildBreadcrumb(context, 'Telecallers List', widget.onBack),
        const SizedBox(height: CRMSpacing.m),

        // Telecaller Header
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;

            return Container(
              padding: EdgeInsets.all(isMobile ? 14 : 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: isMobile ? 22 : 26,
                              backgroundColor: primaryColor.withValues(alpha: 0.15),
                              child: Text(
                                tc.name.isNotEmpty ? tc.name[0].toUpperCase() : 'T',
                                style: TextStyle(
                                  fontSize: isMobile ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            SizedBox(width: isMobile ? 10 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tc.name,
                                    style: TextStyle(
                                      fontSize: isMobile ? 17 : 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tc.email,
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 13,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: isMobile ? 6 : 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          isMobile ? 'Assigned: ${tc.totalLeads}' : 'Assigned Leads: ${tc.totalLeads}',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Source filters
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Source Filter:',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      _buildSourceFilterChip('All Sources', 'All', tc.sources['all']?.total ?? tc.totalLeads),
                      _buildSourceFilterChip('Meta', 'Meta', tc.sources['meta']?.total ?? 0),
                      _buildSourceFilterChip('Housing', 'Housing', tc.sources['housing']?.total ?? 0),
                      _buildSourceFilterChip('Webhook', 'Webhook', tc.sources['webhook']?.total ?? 0),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Status Counts Chips for this telecaller
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusChip('CNR: ${tc.statusCounts.cnr}', const Color(0xFFE11D48)),
                      _buildStatusChip('Callback: ${tc.statusCounts.callback}', const Color(0xFFD97706)),
                      _buildStatusChip('Contacted: ${tc.statusCounts.contacted}', const Color(0xFF2563EB)),
                      _buildStatusChip('Handed to Sales: ${tc.statusCounts.handedToSales}', const Color(0xFF16A34A)),
                      _buildStatusChip('Not Interested: ${tc.statusCounts.notInterested}', const Color(0xFFDC2626)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: CRMSpacing.m),

        // Two Tabs: Property Listing Leads vs Requirement Leads
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: primaryColor,
            unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            indicatorColor: primaryColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            tabs: [
              Tab(
                child: Row(
                  children: [
                    const Icon(Icons.apartment_rounded, size: 16),
                    const SizedBox(width: 8),
                    Text('Property Listing Leads (${bd.prop})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  children: [
                    const Icon(Icons.manage_search_rounded, size: 16),
                    const SizedBox(width: 8),
                    Text('Requirement Leads (${bd.req})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: CRMSpacing.m),

        // Lead Table for Telecaller
        LeadRecordTableView(
          key: ValueKey('tc_${tc.id}_${_selectedSource}_${_activeTabIndex}_${widget.from}_${widget.to}'),
          source: _selectedSource,
          leadType: _activeTabIndex == 0 ? 'Property Listing' : 'Requirement',
          telecallerId: tc.id,
          from: widget.from,
          to: widget.to,
        ),
      ],
    );
  }

  Widget _buildSourceFilterChip(String label, String value, int count) {
    final isSelected = _selectedSource == value;
    final primaryColor = CRMColors.primary;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedSource = value);
      },
      selectedColor: primaryColor.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? primaryColor : null,
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ============================================================================
// 7. REUSABLE LEAD RECORD TABLE VIEW (Fetches & Displays Actual DB Leads)
// ============================================================================
class LeadRecordTableView extends StatefulWidget {
  final String? source;
  final String? leadType;
  final String? kpi;
  final String? telecallerId;
  final DateTime? from;
  final DateTime? to;

  const LeadRecordTableView({
    super.key,
    this.source,
    this.leadType,
    this.kpi,
    this.telecallerId,
    this.from,
    this.to,
  });

  @override
  State<LeadRecordTableView> createState() => _LeadRecordTableViewState();
}

class _LeadRecordTableViewState extends State<LeadRecordTableView> {
  final TextEditingController _searchController = TextEditingController();
  List<BusinessInsightLead> _leads = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _page = 0;
  static const int _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  @override
  void didUpdateWidget(covariant LeadRecordTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.leadType != widget.leadType ||
        oldWidget.kpi != widget.kpi ||
        oldWidget.telecallerId != widget.telecallerId ||
        oldWidget.from != widget.from ||
        oldWidget.to != widget.to) {
      _page = 0;
      _fetchLeads();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeads() async {
    setState(() => _isLoading = true);
    final res = await BusinessInsightService.instance.fetchLeads(
      source: widget.source,
      leadType: widget.leadType,
      kpi: widget.kpi,
      telecallerId: widget.telecallerId,
      from: widget.from,
      to: widget.to,
      limit: 1000,
      offset: 0,
    );

    if (mounted) {
      setState(() {
        final rawLeads = res['leads'] as List<BusinessInsightLead>? ?? [];
        final seen = <String>{};
        _leads = rawLeads.where((l) => seen.add(l.id)).toList();
        _isLoading = false;
      });
    }
  }

  List<BusinessInsightLead> get _filteredLeads {
    if (_searchQuery.trim().isEmpty) return _leads;
    final q = _searchQuery.toLowerCase().trim();
    return _leads.where((l) {
      return l.customerName.toLowerCase().contains(q) ||
          l.phone.contains(q) ||
          l.email.toLowerCase().contains(q) ||
          l.source.toLowerCase().contains(q) ||
          l.stage.toLowerCase().contains(q) ||
          l.allocationStatus.toLowerCase().contains(q) ||
          (l.telecallerName != null && l.telecallerName!.toLowerCase().contains(q)) ||
          (l.salespersonName != null && l.salespersonName!.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;
    final filtered = _filteredLeads;
    final totalPages = (filtered.length / _pageSize).ceil();
    final startIdx = _page * _pageSize;
    final pageLeads = filtered.skip(startIdx).take(_pageSize).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Toolbar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _page = 0;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search leads by customer, phone, status, or assignee...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _page = 0;
                                });
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh Leads',
                  onPressed: _fetchLeads,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${filtered.length} Leads',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (pageLeads.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No leads matching "$_searchQuery"'
                          : 'No leads found for this selection.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                ),
                columnSpacing: 20,
                horizontalMargin: 16,
                columns: [
                  const DataColumn(label: Text('Customer / Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(label: Text('Source', style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(label: Text('Stage / Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  if (widget.kpi == 'not_interested' || widget.kpi == 'rejected')
                    DataColumn(label: Text(widget.kpi == 'not_interested' ? 'Not Interested Remark' : 'Rejection Reason / Remark', style: const TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(label: Text('Call Disposition', style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(label: Text('Assigned Telecaller', style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(label: Text('Assigned Salesperson', style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(label: Text('Created Date', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: pageLeads.map((lead) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              lead.customerName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            if (lead.phone.isNotEmpty)
                              Text(
                                lead.phone,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                      DataCell(
                        _buildSourceBadge(lead.source),
                      ),
                      DataCell(
                        Text(lead.leadType, style: const TextStyle(fontSize: 12.5)),
                      ),
                      DataCell(
                        _buildStageBadge(lead.stage, lead.rejectionReason),
                      ),
                      if (widget.kpi == 'not_interested' || widget.kpi == 'rejected')
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              widget.kpi == 'not_interested'
                                  ? (lead.notInterestedRemark ?? lead.rejectionReason ?? 'Not Interested')
                                  : (lead.rejectionReason ?? lead.notInterestedRemark ?? 'Rejected'),
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      DataCell(
                        Text(
                          lead.callDisposition.replaceAll('_', ' '),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.headset_mic_rounded, size: 14, color: primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              lead.telecallerName ?? '—',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: lead.telecallerName != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_rounded, size: 14, color: Color(0xFF2563EB)),
                            const SizedBox(width: 6),
                            Text(
                              lead.salespersonName ?? '—',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: lead.salespersonName != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          lead.createdAt != null
                              ? DateFormat('dd MMM yyyy, HH:mm').format(lead.createdAt!)
                              : '—',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

          // Pagination Bar
          if (totalPages > 1) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${startIdx + 1}–${(startIdx + _pageSize).clamp(0, filtered.length)} of ${filtered.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: _page > 0 ? () => setState(() => _page--) : null,
                      ),
                      Text(
                        'Page ${_page + 1} of $totalPages',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: _page < totalPages - 1 ? () => setState(() => _page++) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceBadge(String source) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    final s = source.toUpperCase();
    if (s.contains('META') || s.contains('FACEBOOK')) {
      bg = const Color(0xFF1877F2).withValues(alpha: 0.12);
      fg = const Color(0xFF1877F2);
    } else if (s.contains('HOUSING')) {
      bg = const Color(0xFF0D9488).withValues(alpha: 0.12);
      fg = const Color(0xFF0D9488);
    } else if (s.contains('WEBHOOK')) {
      bg = const Color(0xFF7C3AED).withValues(alpha: 0.12);
      fg = const Color(0xFF7C3AED);
    } else {
      bg = const Color(0xFFEA580C).withValues(alpha: 0.12);
      fg = const Color(0xFFEA580C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        source,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildStageBadge(String stage, String? rejectionReason) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    String label = stage.replaceAll('_', ' ');

    if (rejectionReason != null && rejectionReason.isNotEmpty) {
      bg = const Color(0xFFDC2626).withValues(alpha: 0.12);
      fg = const Color(0xFFDC2626);
      label = rejectionReason.replaceAll('_', ' ');
    } else if (stage == 'WON') {
      bg = const Color(0xFF16A34A).withValues(alpha: 0.12);
      fg = const Color(0xFF16A34A);
    } else if (stage == 'LOST') {
      bg = const Color(0xFFDC2626).withValues(alpha: 0.12);
      fg = const Color(0xFFDC2626);
    } else if (stage == 'NEW') {
      bg = const Color(0xFF0284C7).withValues(alpha: 0.12);
      fg = const Color(0xFF0284C7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

// Helper Breadcrumb Button
Widget _buildBreadcrumb(BuildContext context, String previousLabel, VoidCallback onBack) {
  final primaryColor = CRMColors.primary;

  return InkWell(
    onTap: onBack,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_rounded, size: 16, color: primaryColor),
          const SizedBox(width: 6),
          Text(
            'Back to $previousLabel',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ],
      ),
    ),
  );
}

// Helper Responsive Drilldown Header
Widget _buildDrilldownHeader({
  required BuildContext context,
  required String title,
  required String subtitle,
  required Widget badge,
}) {
  final isDark = ThemeManager().isDarkMode;

  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 650;
      if (isMobile) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                badge,
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          badge,
        ],
      );
    },
  );
}
