import 'package:flutter/material.dart';
import '../../requirements/models/requirement_model.dart';
import '../../requirements/repository/requirements_repository.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/crm_page_header.dart';

class PipelineScreen extends StatefulWidget {
  const PipelineScreen({super.key});

  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> {
  final RequirementsRepository _requirementsRepo = RequirementsRepository();
  bool _isLoading = true;
  String? _errorMessage;
  List<RequirementModel> _requirements = [];

  final List<String> _stages = [
    'Lead Created',
    'Requirement Added',
    'Requirement Verified',
    'Matching Started',
    'Properties Matched',
    'Properties Shared',
    'Client Viewed',
    'Client Interested',
    'Site Visit Scheduled',
    'Site Visit Completed',
    'Negotiation',
    'Booking',
    'Documentation',
    'Payment',
    'Possession',
    'Closed'
  ];

  @override
  void initState() {
    super.initState();
    _loadPipelineData();
  }

  Future<void> _loadPipelineData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final reqs = await _requirementsRepo.getRequirements();
      setState(() {
        _requirements = reqs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, List<RequirementModel>> _groupRequirementsByStage() {
    final Map<String, List<RequirementModel>> grouped = {
      for (var stage in _stages) stage: []
    };
    for (var req in _requirements) {
      final stage = req.calculateClientStage();
      if (grouped.containsKey(stage)) {
        grouped[stage]!.add(req);
      } else {
        grouped['Lead Created']!.add(req);
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(CRMSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
                const SizedBox(height: CRMSpacing.m),
                Text("Error: $_errorMessage", style: CRMTypography.sectionTitle),
                const SizedBox(height: CRMSpacing.m),
                ElevatedButton(onPressed: _loadPipelineData, child: const Text("Retry")),
              ],
            ),
          ),
        ),
      );
    }

    final grouped = _groupRequirementsByStage();

    // Calculate quick metrics
    final totalActive = _requirements.where((r) {
      final s = r.status.toLowerCase().replaceAll('-', '');
      return s != 'won' && s != 'dead' && s != 'notinterested' && s != 'bin' && s != 'closed';
    }).length;
    final totalSiteVisits = _requirements.where((r) {
      final stage = r.calculateClientStage();
      return stage.contains('Site Visit') || stage == 'Negotiation' || stage == 'Booking' || stage == 'Closed';
    }).length;
    final conversionRate = _requirements.isEmpty ? 0.0 : (totalSiteVisits / _requirements.length) * 100;

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(CRMSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              CRMPageHeader(
                eyebrow: 'Deals',
                title: 'Client Pipeline',
                benefit:
                    'See every deal stage at a glance and push stalled leads forward',
                trailing: IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadPipelineData,
                  tooltip: 'Refresh Data',
                ),
              ),
              const SizedBox(height: CRMSpacing.l),

              // KPI Metric Cards Row
              SizedBox(
                height: 130,
                child: Row(
                  children: [
                    Expanded(
                      child: CRMKPICard(
                        title: 'Total Active Deals',
                        value: '$totalActive',
                        icon: Icons.handshake_rounded,
                        iconColor: CRMColors.info,
                        benefit: 'Live deals still moving through your funnel',
                      ),
                    ),
                    const SizedBox(width: CRMSpacing.m),
                    Expanded(
                      child: CRMKPICard(
                        title: 'Site Visit Ratio',
                        value: '${conversionRate.toStringAsFixed(1)}%',
                        icon: Icons.directions_walk_rounded,
                        iconColor: CRMColors.success,
                        benefit: 'How often leads turn into real site visits',
                      ),
                    ),
                    const SizedBox(width: CRMSpacing.m),
                    Expanded(
                      child: CRMKPICard(
                        title: 'Pipeline Volume',
                        value: '${_requirements.length} Leads',
                        icon: Icons.analytics_rounded,
                        iconColor: CRMColors.warning,
                        benefit: 'Total demand load across every stage',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CRMSpacing.l),

              // Kanban Board Horizontal Scroll
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _stages.length,
                  itemBuilder: (context, index) {
                    final stageName = _stages[index];
                    final stageRequirements = grouped[stageName] ?? [];
                    return _buildKanbanColumn(stageName, stageRequirements);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKanbanColumn(String stageName, List<RequirementModel> items) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.all(CRMSpacing.m),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: CRMColors.borderOf(context))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    stageName,
                    style: CRMTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: CRMColors.textOf(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: CRMColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${items.length}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: CRMColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Column Body (Cards list)
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      "No deals",
                      style: CRMTypography.caption.copyWith(color: CRMColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(CRMSpacing.s),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildKanbanCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanCard(RequirementModel item) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: CRMSpacing.s),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: CRMColors.borderOf(context)),
      ),
      color: CRMColors.cardBgOf(context),
      child: Padding(
        padding: const EdgeInsets.all(CRMSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.clientName,
              style: CRMTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: CRMColors.textOf(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.requirementCode,
              style: CRMTypography.caption.copyWith(
                color: CRMColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.propertyTypeName,
                  style: CRMTypography.caption.copyWith(color: CRMColors.textMuted),
                ),
                Text(
                  "₹${item.maxBudget.toStringAsFixed(0)}L Max",
                  style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
