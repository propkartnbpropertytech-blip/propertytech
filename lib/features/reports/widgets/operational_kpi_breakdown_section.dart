/// ============================================================================
/// ⚠️ PROPKART MASTER KPI GOVERNANCE RULE:
/// All Operational KPI cards in this section MUST strictly adhere to the
/// Master KPI Rulebook: `lib/core/constants/kpi_rulebook.dart` and `docs/KPIs.docx`.
/// Note: Inventory Added by Role displays Available count as primary stat,
/// and Total count in subtitle. Direct Leads are mapped to table `leads`.
/// ============================================================================
import 'package:flutter/material.dart';
import '../../../../core/constants/kpi_rulebook.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/design_system/tokens/app_typography.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../dashboard/models/kpi_models.dart';
import '../../dashboard/widgets/stat_card.dart';
import '../../dashboard/widgets/kpi_drilldown_dialogs.dart';

/// Comprehensive Operational KPI Breakdown Section for Reports
/// Encapsulates:
/// 1. Inventory Sourcing Breakdown (KPIs 1-7)
/// 2. Manual & Direct Leads Pipeline (KPIs 8-11)
/// 3. Sales Executive Pipeline (KPIs 12-14)
/// 4. Qualified & Interested Leads Lifecycle (KPIs 20-24)
class OperationalKpiBreakdownSection extends StatefulWidget {
  final DashboardKpisResponse? kpis;
  final KpiFilterParams kpiFilters;
  final VoidCallback? onRefresh;

  const OperationalKpiBreakdownSection({
    super.key,
    required this.kpis,
    this.kpiFilters = const KpiFilterParams(businessType: 'Both', dateFilter: 'All', leadType: 'Both'),
    this.onRefresh,
  });

  @override
  State<OperationalKpiBreakdownSection> createState() => _OperationalKpiBreakdownSectionState();
}

class _OperationalKpiBreakdownSectionState extends State<OperationalKpiBreakdownSection> {
  String _activeTab = 'all'; // 'all', 'sourcing', 'manual', 'pipeline', 'qualified'

  @override
  Widget build(BuildContext context) {
    if (widget.kpis == null) return const SizedBox.shrink();

    final isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header Banner
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(CRMBorderRadius.card),
            border: Border.all(
              color: CRMColors.borderOf(context).withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: CRMColors.primaryOf(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.analytics_rounded,
                      color: CRMColors.primaryOf(context),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Executive Operational KPIs & Pipeline Breakdown',
                          style: CRMTypography.sectionTitle.copyWith(
                            color: CRMColors.textOf(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Authoritative database metrics mapped from leads, properties, requirements and site visits.',
                          style: CRMTypography.caption.copyWith(
                            color: CRMColors.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Filter Tab Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabPill('all', 'All Modules (24 KPIs)', Icons.dashboard_customize_rounded),
                    const SizedBox(width: 8),
                    _buildTabPill('sourcing', 'Inventory Sourcing', Icons.add_home_work_rounded),
                    const SizedBox(width: 8),
                    _buildTabPill('manual', 'Manual & Direct Leads', Icons.person_add_alt_1_rounded),
                    const SizedBox(width: 8),
                    _buildTabPill('pipeline', 'Sales Pipeline', Icons.workspace_premium_rounded),
                    const SizedBox(width: 8),
                    _buildTabPill('qualified', 'Qualified Leads', Icons.verified_user_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Subsections based on active tab
        if (_activeTab == 'all' || _activeTab == 'sourcing') ...[
          _buildInventorySourcingSection(),
          const SizedBox(height: 20),
        ],
        if (_activeTab == 'all' || _activeTab == 'manual') ...[
          _buildManualDirectLeadsSection(),
          const SizedBox(height: 20),
        ],
        if (_activeTab == 'all' || _activeTab == 'pipeline') ...[
          _buildSalesPipelineSection(),
          const SizedBox(height: 20),
        ],
        if (_activeTab == 'all' || _activeTab == 'qualified') ...[
          _buildQualifiedLeadsSection(),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildTabPill(String tabId, String label, IconData icon) {
    final isSelected = _activeTab == tabId;
    final primary = CRMColors.primaryOf(context);

    return InkWell(
      onTap: () => setState(() => _activeTab = tabId),
      borderRadius: BorderRadius.circular(CRMBorderRadius.round),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? primary : CRMColors.cardBgOf(context),
          borderRadius: BorderRadius.circular(CRMBorderRadius.round),
          border: Border.all(
            color: isSelected ? primary : CRMColors.borderOf(context),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : CRMColors.textSecondaryOf(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: CRMTypography.captionBold.copyWith(
                color: isSelected ? Colors.white : CRMColors.textOf(context),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    int? count,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: CRMTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: CRMColors.textOf(context),
              ),
            ),
          ),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: CRMTypography.captionBold.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardGrid(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount;
        if (width >= 1100) {
          crossAxisCount = 4;
        } else if (width >= 750) {
          crossAxisCount = 3;
        } else if (width >= 480) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        final double spacing = 12;
        final double itemWidth = (width - ((crossAxisCount - 1) * spacing)) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((card) {
            return SizedBox(
              width: itemWidth,
              child: card,
            );
          }).toList(),
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // GROUP A: Inventory Sourcing Section (KPIs 1-7)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildInventorySourcingSection() {
    final c = widget.kpis!.counts;

    final cards = <Widget>[
      StatCard(
        title: 'Total Portfolio',
        value: '${c.totalPortfolio}',
        subtitle: 'Available: ${c.availableInventory} • Rented: ${c.rentedOutCount}',
        icon: Icons.holiday_village_rounded,
        accentColor: const Color(0xFF10B981),
        onTap: () async {
          await KpiDrilldownDialogs.showInventoryDrilldown(
            context,
            params: const KpiFilterParams(businessType: 'Both', dateFilter: 'All', leadType: 'Both'),
          );
          widget.onRefresh?.call();
        },
      ),
      StatCard(
        title: 'Added by Sales',
        value: '${c.propertiesBySalesAvailable}',
        subtitle: 'Available: ${c.propertiesBySalesAvailable} • Total: ${c.propertiesBySalesTotal}',
        icon: Icons.person_pin_rounded,
        accentColor: const Color(0xFF0EA5E9),
        onTap: () async {
          await KpiDrilldownDialogs.showInventoryDrilldown(
            context,
            params: const KpiFilterParams(businessType: 'Both', dateFilter: 'All', leadType: 'Both'),
          );
          widget.onRefresh?.call();
        },
      ),
      StatCard(
        title: 'Added by Telecaller',
        value: '${c.propertiesByTelecallerAvailable}',
        subtitle: 'Available: ${c.propertiesByTelecallerAvailable} • Total: ${c.propertiesByTelecallerTotal}',
        icon: Icons.headset_mic_rounded,
        accentColor: const Color(0xFF6366F1),
        onTap: () async {
          await KpiDrilldownDialogs.showInventoryDrilldown(
            context,
            params: const KpiFilterParams(businessType: 'Both', dateFilter: 'All', leadType: 'Both'),
          );
          widget.onRefresh?.call();
        },
      ),
      StatCard(
        title: 'Added by Admin',
        value: '${c.propertiesByAdminAvailable}',
        subtitle: 'Available: ${c.propertiesByAdminAvailable} • Total: ${c.propertiesByAdminTotal}',
        icon: Icons.admin_panel_settings_rounded,
        accentColor: const Color(0xFFF59E0B),
        onTap: () async {
          await KpiDrilldownDialogs.showInventoryDrilldown(
            context,
            params: const KpiFilterParams(businessType: 'Both', dateFilter: 'All', leadType: 'Both'),
          );
          widget.onRefresh?.call();
        },
      ),
      StatCard(
        title: 'Rental Properties',
        value: '${c.rentalCount}',
        subtitle: 'Portfolio for Rent',
        icon: Icons.apartment_rounded,
        accentColor: const Color(0xFF14B8A6),
        onTap: () async {
          await KpiDrilldownDialogs.showInventoryDrilldown(
            context,
            params: const KpiFilterParams(businessType: 'Rent', dateFilter: 'All', leadType: 'Both'),
          );
          widget.onRefresh?.call();
        },
      ),
      StatCard(
        title: 'Re-sale Properties',
        value: '${c.resaleCount}',
        subtitle: 'Portfolio for Sale',
        icon: Icons.real_estate_agent_rounded,
        accentColor: const Color(0xFFEC4899),
        onTap: () async {
          await KpiDrilldownDialogs.showInventoryDrilldown(
            context,
            params: const KpiFilterParams(businessType: 'Re-sale', dateFilter: 'All', leadType: 'Both'),
          );
          widget.onRefresh?.call();
        },
      ),
      StatCard(
        title: 'Rented / Sold Out',
        value: '${c.rentedOutCount + c.soldOutCount}',
        subtitle: 'Rented: ${c.rentedOutCount} • Sold: ${c.soldOutCount}',
        icon: Icons.check_circle_outline_rounded,
        accentColor: const Color(0xFF8B5CF6),
        onTap: () async {
          await KpiDrilldownDialogs.showInventoryDrilldown(
            context,
            params: const KpiFilterParams(businessType: 'Both', dateFilter: 'All', leadType: 'Both'),
          );
          widget.onRefresh?.call();
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          title: 'Inventory Sourcing & Portfolio Distribution',
          icon: Icons.add_home_work_rounded,
          color: const Color(0xFF10B981),
          count: c.totalPortfolio,
        ),
        _buildCardGrid(cards),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // GROUP B: Manual / Direct Leads Section (KPIs 8-11)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildManualDirectLeadsSection() {
    final c = widget.kpis!.counts;

    final cards = <Widget>[
      StatCard(
        title: 'Total Direct Leads',
        value: '${c.manualLeadsTotal}',
        subtitle: 'Direct walk-in & referrals',
        icon: Icons.post_add_rounded,
        accentColor: const Color(0xFF3B82F6),
        onTap: () async {
          await KpiDrilldownDialogs.showLeadsDrilldown(
            context,
            params: const KpiFilterParams(businessType: 'Both', dateFilter: 'All', leadType: 'Both'),
            initialSource: 'DIRECT',
          );
          widget.onRefresh?.call();
        },
      ),
      StatCard(
        title: 'Direct by Sales',
        value: '${c.manualLeadsBySales}',
        subtitle: 'Self-sourced by sales team',
        icon: Icons.badge_rounded,
        accentColor: const Color(0xFF0284C7),
        onTap: () async {
          await KpiDrilldownDialogs.showLeadsDrilldown(
            context,
            params: const KpiFilterParams(businessType: 'Both', dateFilter: 'All', leadType: 'Both'),
            initialSource: 'MANUAL',
          );
          widget.onRefresh?.call();
        },
      ),
      StatCard(
        title: 'Direct by Telecaller',
        value: '${c.manualLeadsByTelecaller}',
        subtitle: 'Manual inbound calls entered',
        icon: Icons.headset_mic_rounded,
        accentColor: const Color(0xFF8B5CF6),
        onTap: () async {
          await KpiDrilldownDialogs.showLeadsDrilldown(
            context,
            params: const KpiFilterParams(businessType: 'Both', dateFilter: 'All', leadType: 'Both'),
            initialSource: 'DIRECT',
          );
          widget.onRefresh?.call();
        },
      ),
      StatCard(
        title: 'Direct by Admin',
        value: '${c.manualLeadsByAdmin}',
        subtitle: 'System / executive added',
        icon: Icons.admin_panel_settings_rounded,
        accentColor: const Color(0xFF10B981),
        onTap: () async {
          await KpiDrilldownDialogs.showLeadsDrilldown(
            context,
            params: const KpiFilterParams(businessType: 'Both', dateFilter: 'All', leadType: 'Both'),
          );
          widget.onRefresh?.call();
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          title: 'Manual / Direct Leads Pipeline',
          icon: Icons.person_add_alt_1_rounded,
          color: const Color(0xFF3B82F6),
          count: c.manualLeadsTotal,
        ),
        _buildCardGrid(cards),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // GROUP C: Sales Pipeline Section (KPIs 12-14)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildSalesPipelineSection() {
    final c = widget.kpis!.counts;

    final cards = <Widget>[
      StatCard(
        title: 'Active In Pipeline',
        value: '${c.activeRequirements}',
        subtitle: 'Requirements with sales team',
        icon: Icons.work_history_rounded,
        accentColor: const Color(0xFF0D9488),
        onTap: () async {
          await KpiDrilldownDialogs.showAssignedToSalesDrilldown(
            context,
            params: widget.kpiFilters,
          );
          widget.onRefresh?.call();
        },
      ),
      StatCard(
        title: 'Site Visits Done',
        value: '${c.siteVisitsDoneReq}',
        subtitle: 'Completed physical visits',
        icon: Icons.domain_verification_rounded,
        accentColor: const Color(0xFF059669),
        onTap: () async {
          await KpiDrilldownDialogs.showSiteVisitsDrilldown(
            context,
            params: widget.kpiFilters,
          );
          widget.onRefresh?.call();
        },
      ),
      StatCard(
        title: 'Deals Won',
        value: '${c.dealsWonCount}',
        subtitle: 'Closed transactions',
        icon: Icons.emoji_events_rounded,
        accentColor: const Color(0xFF10B981),
        onTap: () async {
          await KpiDrilldownDialogs.showDealWonDrilldown(
            context,
            params: widget.kpiFilters,
          );
          widget.onRefresh?.call();
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          title: 'Sales Exec Pipeline & Site Visit Execution',
          icon: Icons.workspace_premium_rounded,
          color: const Color(0xFF0D9488),
          count: c.activeRequirements,
        ),
        _buildCardGrid(cards),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // GROUP D: Qualified Interested Leads Section (KPIs 20-24)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildQualifiedLeadsSection() {
    final c = widget.kpis!.counts;

    final cards = <Widget>[
      StatCard(
        title: 'Qualified Interested',
        value: '${c.qualifiedInterested}',
        subtitle: 'Filtered out CNR / NI',
        icon: Icons.verified_user_rounded,
        accentColor: const Color(0xFF10B981),
        onTap: () async {
          await KpiDrilldownDialogs.showLeadsDrilldown(
            context,
            params: const KpiFilterParams(businessType: 'Both', dateFilter: 'All', leadType: 'Both'),
          );
          widget.onRefresh?.call();
        },
      ),
      StatCard(
        title: 'Tenants (Want Rent)',
        value: '${c.wantRentCount}',
        subtitle: 'Looking to rent property',
        icon: Icons.home_rounded,
        accentColor: const Color(0xFF6366F1),
        onTap: () async {
          await KpiDrilldownDialogs.showLeadsDrilldown(
            context,
            params: const KpiFilterParams(businessType: 'Rent', dateFilter: 'All', leadType: 'Requirement'),
          );
          widget.onRefresh?.call();
        },
      ),
      StatCard(
        title: 'Owners (Want to List)',
        value: '${c.wantListCount}',
        subtitle: 'Looking to list property',
        icon: Icons.add_home_rounded,
        accentColor: const Color(0xFF0EA5E9),
        onTap: () async {
          await KpiDrilldownDialogs.showLeadsDrilldown(
            context,
            params: const KpiFilterParams(businessType: 'Both', dateFilter: 'All', leadType: 'Listing'),
          );
          widget.onRefresh?.call();
        },
      ),
      StatCard(
        title: 'Buyers (Re-sale)',
        value: '${c.wantResaleCount}',
        subtitle: 'Looking to buy property',
        icon: Icons.real_estate_agent_rounded,
        accentColor: const Color(0xFFEC4899),
        onTap: () async {
          await KpiDrilldownDialogs.showLeadsDrilldown(
            context,
            params: const KpiFilterParams(businessType: 'Re-sale', dateFilter: 'All', leadType: 'Requirement'),
          );
          widget.onRefresh?.call();
        },
      ),
      StatCard(
        title: 'Active in Sales',
        value: '${c.activeInSalesCount}',
        subtitle: 'With sales executive now',
        icon: Icons.handshake_rounded,
        accentColor: const Color(0xFFF59E0B),
        onTap: () async {
          await KpiDrilldownDialogs.showAssignedToSalesDrilldown(
            context,
            params: widget.kpiFilters,
          );
          widget.onRefresh?.call();
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader(
          title: 'Qualified Interested Leads & Intent Segmentation',
          icon: Icons.people_rounded,
          color: const Color(0xFF6366F1),
          count: c.qualifiedInterested,
        ),
        _buildCardGrid(cards),
      ],
    );
  }
}
