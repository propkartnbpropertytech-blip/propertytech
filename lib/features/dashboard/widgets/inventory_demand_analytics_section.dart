import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/widgets/skeletons.dart';
import '../models/area_analytics_model.dart';
import '../models/kpi_models.dart';
import '../services/dashboard_service.dart';
import 'kpi_drilldown_dialogs.dart';

class InventoryDemandAnalyticsSection extends StatefulWidget {
  final String businessType;
  final KpiFilterParams? filterParams;

  const InventoryDemandAnalyticsSection({
    super.key,
    required this.businessType,
    this.filterParams,
  });

  @override
  State<InventoryDemandAnalyticsSection> createState() =>
      _InventoryDemandAnalyticsSectionState();
}

class _InventoryDemandAnalyticsSectionState
    extends State<InventoryDemandAnalyticsSection> {
  final DashboardService _dashboardService = DashboardService();
  final MapController _mapController = MapController();

  // Unified Locality Intelligence state
  bool _isLocalityLoading = true;
  String? _localityError;
  LocalityIntelligenceData _localityData = const LocalityIntelligenceData();

  // Active mode: 'inventory' | 'listing' | 'requirement' | 'compare'
  String _activeMode = 'inventory';
  LocalityIntelligenceItem? _selectedLocality;

  // Preserved bottom Lead Area Demand state
  String _selectedLeadDemandType = 'listing'; // 'listing' or 'requirement'
  bool _isLeadDemandLoading = true;
  String? _leadDemandError;
  List<AreaCountItem> _leadDemandItems = [];

  // Palette tokens
  static const List<Color> _segmentColors = [
    Color(0xFF2563EB), // Royal Blue
    Color(0xFF0D9488), // Teal
    Color(0xFF7C3AED), // Violet
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF64748B), // Slate for Other
  ];

  KpiFilterParams get _filterParams =>
      widget.filterParams ??
      KpiFilterParams(
        businessType: widget.businessType,
        dateFilter: 'all',
        leadType: 'Both',
      );

  void _openInventoryDrilldown({
    String status = 'Available',
    String? areaId,
    String? areaName,
  }) {
    KpiDrilldownDialogs.showInventoryDrilldown(
      context,
      params: _filterParams,
      initialStatus: status,
      initialAreaId: areaId,
      initialAreaName: areaName,
    );
  }

  void _openLeadsDrilldown({
    String? source,
    String? areaId,
    String? areaName,
    String? leadType,
    String? stage,
    bool? isDealWon,
  }) {
    KpiDrilldownDialogs.showLeadsDrilldown(
      context,
      params: leadType != null ? _filterParams.copyWith(leadType: leadType) : _filterParams,
      initialSource: source,
      initialAreaId: areaId,
      initialAreaName: areaName,
      initialStage: stage,
      isDealWon: isDealWon,
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchLocalityData();
    _fetchLeadDemand();
  }

  @override
  void didUpdateWidget(covariant InventoryDemandAnalyticsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.businessType != widget.businessType) {
      _fetchLocalityData();
    }
  }

  Future<void> _fetchLocalityData() async {
    if (!mounted) return;
    setState(() {
      _isLocalityLoading = true;
      _localityError = null;
    });

    try {
      final data = await _dashboardService.getLocalityIntelligence(
        businessType: widget.businessType,
      );
      if (!mounted) return;
      setState(() {
        _localityData = data;
        _isLocalityLoading = false;
        // If selected locality is present, refresh it from new data
        if (_selectedLocality != null) {
          final matched = data.localities.firstWhere(
            (l) => l.areaName.toLowerCase() == _selectedLocality!.areaName.toLowerCase(),
            orElse: () => _selectedLocality!,
          );
          _selectedLocality = matched;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _localityError = 'Failed to load locality intelligence';
        _isLocalityLoading = false;
      });
    }
  }

  Future<void> _fetchLeadDemand() async {
    if (!mounted) return;
    setState(() {
      _isLeadDemandLoading = true;
      _leadDemandError = null;
    });

    try {
      final data = await _dashboardService.getLeadsByArea(
        type: _selectedLeadDemandType,
      );
      if (!mounted) return;
      setState(() {
        _leadDemandItems = data;
        _isLeadDemandLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _leadDemandError = 'Failed to load lead area demand';
        _isLeadDemandLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: ThemeManager().primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Locality Intelligence',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: ThemeManager().primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Supply vs Demand',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ThemeManager().primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // DATA QUALITY & RECONCILIATION + PERSISTENT LEGENDS BAR
        if (!_isLocalityLoading && _localityError == null)
          _buildReconciliationAndLegendsBar(isDark),

        // TOP SECTION: Locality Map + Dynamic Intelligence Side Card
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 980;

            final mapCard = _buildLocalityMapCard(isDark);
            final intelligenceCard = _buildDynamicIntelligenceCard(isDark);

            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: mapCard),
                  const SizedBox(width: 18),
                  Expanded(flex: 5, child: intelligenceCard),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  mapCard,
                  const SizedBox(height: 16),
                  intelligenceCard,
                ],
              );
            }
          },
        ),

        const SizedBox(height: 18),

        // BOTTOM SECTION: Preserved Lead Area Demand Card
        _buildLeadDemandCard(isDark),
      ],
    );
  }

  // ============================================================
  // RECONCILIATION & PERSISTENT LEGENDS BAR
  // ============================================================
  Widget _buildReconciliationAndLegendsBar(bool isDark) {
    final totalLeads = _localityData.totalLeads;
    final mappedLeads = _localityData.mappedLeads;
    final unknownLeads = _localityData.unknownAreaLeads;
    final mappedPct = totalLeads > 0 ? (mappedLeads / totalLeads) * 100.0 : 0.0;
    final unknownPct = totalLeads > 0 ? (unknownLeads / totalLeads) * 100.0 : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Data Quality & Reconciliation Strip
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Data Quality & Reconciliation:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$totalLeads Total Leads (100% Accounted)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$mappedLeads Mapped (${mappedPct.toStringAsFixed(0)}%)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D9488),
                ),
              ),
              const Spacer(),
              // Clickable Unknown Area Pill
              if (unknownLeads > 0)
                Tooltip(
                  message: 'Click to inspect and clean $unknownLeads broad/unmapped leads',
                  child: InkWell(
                    onTap: () => _openLeadsDrilldown(
                      areaId: 'unknown',
                      areaName: 'Unknown / Broad Area',
                    ),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.help_outline_rounded,
                            size: 13,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$unknownLeads Broad / Unmapped (${unknownPct.toStringAsFixed(0)}%) • Click to Inspect',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),
          const SizedBox(height: 10),
          // 2. Persistent Legends: Sources and Inventory
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              // Lead Sources
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lead Sources:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildSourceLegendChip('META', _localityData.leadSources['META'] ?? 0, const Color(0xFF1877F2), isDark),
                  const SizedBox(width: 6),
                  _buildSourceLegendChip('HOUSING', _localityData.leadSources['HOUSING'] ?? 0, const Color(0xFFE11D48), isDark),
                  const SizedBox(width: 6),
                  _buildSourceLegendChip('WEBHOOK', _localityData.leadSources['WEBHOOK'] ?? 0, const Color(0xFF8B5CF6), isDark),
                  const SizedBox(width: 6),
                  _buildSourceLegendChip('MANUAL', _localityData.leadSources['MANUAL'] ?? 0, const Color(0xFF10B981), isDark),
                ],
              ),
              // Inventory Statuses
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Inventory (${widget.businessType}):',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusLegendChip('Available', _localityData.totalInventory, const Color(0xFF2563EB), isDark),
                  const SizedBox(width: 6),
                  _buildStatusLegendChip('Rented Out', _localityData.totalRentedOut, const Color(0xFFD97706), isDark),
                  const SizedBox(width: 6),
                  _buildStatusLegendChip('Sold Out', _localityData.totalSoldOut, const Color(0xFFDC2626), isDark),
                  const SizedBox(width: 6),
                  _buildStatusLegendChip('Total', _localityData.totalProperties, const Color(0xFF475569), isDark, statusParam: 'All'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceLegendChip(String sourceKey, int count, Color color, bool isDark) {
    return Tooltip(
      message: 'Click to view $count $sourceKey leads',
      child: InkWell(
        onTap: () => _openLeadsDrilldown(source: sourceKey),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.22 : 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                '$sourceKey ($count)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusLegendChip(String statusName, int count, Color color, bool isDark, {String? statusParam}) {
    return Tooltip(
      message: 'Click to view $count $statusName properties',
      child: InkWell(
        onTap: () => _openInventoryDrilldown(status: statusParam ?? statusName),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.22 : 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                '$statusName ($count)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 1. LOCALITY MAP VISUALIZATION CARD
  // ============================================================
  Widget _buildLocalityMapCard(bool isDark) {
    Color modeAccent;
    String modeLabel;

    if (_activeMode == 'all_leads') {
      modeAccent = const Color(0xFF0284C7);
      modeLabel = 'All Leads';
    } else if (_activeMode == 'deal_won') {
      modeAccent = const Color(0xFF10B981);
      modeLabel = 'Deals Won';
    } else if (_activeMode == 'listing') {
      modeAccent = const Color(0xFF0D9488);
      modeLabel = 'Listing Leads';
    } else if (_activeMode == 'requirement') {
      modeAccent = const Color(0xFF7C3AED);
      modeLabel = 'Requirement Leads';
    } else if (_activeMode == 'compare') {
      modeAccent = const Color(0xFF6366F1);
      modeLabel = 'Supply & Demand';
    } else {
      modeAccent = const Color(0xFF2563EB);
      modeLabel = 'Available Properties';
    }

    // Filter localities that have activity in the current mode
    final localities = _localityData.localities;

    // Determine max count for proportional sizing
    int maxMetric = 1;
    for (final loc in localities) {
      int count = 0;
      if (_activeMode == 'inventory') {
        count = loc.availableProperties;
      } else if (_activeMode == 'all_leads') {
        count = loc.totalLeads;
      } else if (_activeMode == 'deal_won') {
        count = loc.dealWonLeads;
      } else if (_activeMode == 'listing') {
        count = loc.listingLeads;
      } else if (_activeMode == 'requirement') {
        count = loc.requirementLeads;
      } else {
        count = loc.availableProperties + loc.requirementLeads;
      }
      if (count > maxMetric) maxMetric = count;
    }

    // Calculate map centroid from localities
    LatLng mapCenter = const LatLng(23.0600, 72.5350);
    final validCoords = localities
        .where((l) => l.latitude != 23.0225 || l.longitude != 72.5714)
        .toList();
    if (validCoords.isNotEmpty) {
      final avgLat =
          validCoords.map((e) => e.latitude).reduce((a, b) => a + b) /
              validCoords.length;
      final avgLng =
          validCoords.map((e) => e.longitude).reduce((a, b) => a + b) /
              validCoords.length;
      mapCenter = LatLng(avgLat, avgLng);
    }

    return Container(
      height: 450,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // FlutterMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: 11.2,
              minZoom: 8.5,
              maxZoom: 17.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.propkart.crm',
              ),
              MarkerLayer(
                markers: localities.where((loc) {
                  if (_activeMode == 'inventory') return loc.availableProperties > 0;
                  if (_activeMode == 'all_leads') return loc.totalLeads > 0;
                  if (_activeMode == 'deal_won') return loc.dealWonLeads > 0;
                  if (_activeMode == 'listing') return loc.listingLeads > 0;
                  if (_activeMode == 'requirement') return loc.requirementLeads > 0;
                  return loc.availableProperties > 0 || loc.requirementLeads > 0 || loc.listingLeads > 0;
                }).map((item) {
                  int displayCount = 0;
                  Color bubbleColor = modeAccent;
                  String tooltipText = '';

                  if (_activeMode == 'inventory') {
                    displayCount = item.availableProperties;
                    final total = _localityData.totalInventory;
                    final pct = total > 0 ? (displayCount / total) * 100.0 : 0.0;
                    tooltipText =
                        '${item.areaName}\n$displayCount available properties\n${pct.toStringAsFixed(1)}% of inventory';
                  } else if (_activeMode == 'all_leads') {
                    displayCount = item.totalLeads;
                    final total = _localityData.totalLeads;
                    final pct = total > 0 ? (displayCount / total) * 100.0 : 0.0;
                    tooltipText =
                        '${item.areaName}\n$displayCount total leads\n${pct.toStringAsFixed(1)}% of all leads';
                  } else if (_activeMode == 'deal_won') {
                    displayCount = item.dealWonLeads;
                    final total = _localityData.totalDealWonLeads;
                    final pct = total > 0 ? (displayCount / total) * 100.0 : 0.0;
                    tooltipText =
                        '${item.areaName}\n$displayCount deals won\n${pct.toStringAsFixed(1)}% of won deals';
                  } else if (_activeMode == 'listing') {
                    displayCount = item.listingLeads;
                    final total = _localityData.totalListingLeads;
                    final pct = total > 0 ? (displayCount / total) * 100.0 : 0.0;
                    tooltipText =
                        '${item.areaName}\n$displayCount listing leads\n${pct.toStringAsFixed(1)}% of listings';
                  } else if (_activeMode == 'requirement') {
                    displayCount = item.requirementLeads;
                    final total = _localityData.totalRequirementLeads;
                    final pct = total > 0 ? (displayCount / total) * 100.0 : 0.0;
                    tooltipText =
                        '${item.areaName}\n$displayCount requirement leads\n${pct.toStringAsFixed(1)}% of requirements';
                  } else {
                    displayCount = item.requirementLeads;
                    if (item.demandStatus == 'High Demand') {
                      bubbleColor = const Color(0xFFEA580C);
                    } else if (item.demandStatus == 'Balanced') {
                      bubbleColor = const Color(0xFF0D9488);
                    } else {
                      bubbleColor = const Color(0xFF2563EB);
                    }
                    tooltipText =
                        '${item.areaName}\nAvailable: ${item.availableProperties}\nRequirements: ${item.requirementLeads}\nRatio: ${item.demandRatio.toStringAsFixed(1)}x (${item.demandStatus})';
                  }

                  final ratio = (displayCount / maxMetric).clamp(0.0, 1.0);
                  final isSelected = _selectedLocality?.areaName.toLowerCase() ==
                      item.areaName.toLowerCase();
                  final markerSize = (24.0 + ratio * 24.0).clamp(24.0, 48.0);

                  return Marker(
                    point: LatLng(item.latitude, item.longitude),
                    width: isSelected ? markerSize + 8 : markerSize,
                    height: isSelected ? markerSize + 8 : markerSize,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedLocality = item;
                        });
                        _mapController.move(
                          LatLng(item.latitude, item.longitude),
                          12.5,
                        );
                      },
                      child: Tooltip(
                        message: tooltipText,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFF475569),
                          ),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: bubbleColor.withValues(alpha: isSelected ? 1.0 : 0.92),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.amberAccent : Colors.white,
                              width: isSelected ? 3.0 : 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: bubbleColor.withValues(
                                  alpha: isSelected ? 0.75 : 0.40,
                                ),
                                blurRadius: isSelected ? 12 : 8,
                                spreadRadius: isSelected ? 3 : 1.5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _activeMode == 'compare'
                                  ? (item.availableProperties > 0
                                      ? '${item.demandRatio.toStringAsFixed(1)}x'
                                      : '${item.requirementLeads}')
                                  : '$displayCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: markerSize > 34 ? 11 : 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Map Header Overlay: Mode Selector
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF0F172A) : Colors.white)
                    .withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 16,
                      color: modeAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$modeLabel Map',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Selector Pills
                    Container(
                      height: 28,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModePill(
                            label: 'Inventory',
                            modeKey: 'inventory',
                            activeColor: const Color(0xFF2563EB),
                            isDark: isDark,
                          ),
                          _buildModePill(
                            label: 'All Leads',
                            modeKey: 'all_leads',
                            activeColor: const Color(0xFF0284C7),
                            isDark: isDark,
                          ),
                          _buildModePill(
                            label: 'Listing Leads',
                            modeKey: 'listing',
                            activeColor: const Color(0xFF0D9488),
                            isDark: isDark,
                          ),
                          _buildModePill(
                            label: 'Requirement Leads',
                            modeKey: 'requirement',
                            activeColor: const Color(0xFF7C3AED),
                            isDark: isDark,
                          ),
                          _buildModePill(
                            label: 'Deals Won',
                            modeKey: 'deal_won',
                            activeColor: const Color(0xFF10B981),
                            isDark: isDark,
                          ),
                          _buildModePill(
                            label: 'Compare',
                            modeKey: 'compare',
                            activeColor: const Color(0xFF6366F1),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Zoom & Recenter Controls Overlay
          Positioned(
            bottom: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapControlBtn(
                  icon: Icons.add,
                  onTap: () {
                    final z = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, z + 0.5);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 4),
                _buildMapControlBtn(
                  icon: Icons.remove,
                  onTap: () {
                    final z = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, z - 0.5);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 4),
                _buildMapControlBtn(
                  icon: Icons.my_location_rounded,
                  onTap: () {
                    _mapController.move(mapCenter, 11.2);
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Selected Locality Map Popup (Bottom Left)
          if (_selectedLocality != null)
            Positioned(
              bottom: 12,
              left: 12,
              right: 60,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF0F172A) : Colors.white)
                      .withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                _selectedLocality!.areaName,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFFF8FAFC)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(_selectedLocality!.demandStatus),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          onPressed: () => setState(() => _selectedLocality = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '🏠 ${_selectedLocality!.availableProperties} Available  •  📋 ${_selectedLocality!.listingLeads} Listings  •  🎯 ${_selectedLocality!.requirementLeads} Requirements  •  🏆 ${_selectedLocality!.dealWonLeads} Won',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (_selectedLocality!.availableProperties > 0)
                          InkWell(
                            onTap: () => _openInventoryDrilldown(
                              areaId: _selectedLocality!.areaId,
                              areaName: _selectedLocality!.areaName,
                              status: 'Available',
                            ),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.apartment_rounded, size: 12, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'View Properties (${_selectedLocality!.availableProperties})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_selectedLocality!.totalLeads > 0)
                          InkWell(
                            onTap: () => _openLeadsDrilldown(
                              areaId: _selectedLocality!.areaId,
                              areaName: _selectedLocality!.areaName,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.people_alt_rounded, size: 12, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'View Leads (${_selectedLocality!.totalLeads})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModePill({
    required String label,
    required String modeKey,
    required Color activeColor,
    required bool isDark,
  }) {
    final isSelected = _activeMode == modeKey;

    return GestureDetector(
      onTap: () {
        if (_activeMode != modeKey) {
          setState(() => _activeMode = modeKey);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F172A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 3,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? activeColor
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF0F172A) : Colors.white)
              .withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
        ),
      ),
    );
  }

  // ============================================================
  // 2. DYNAMIC INTELLIGENCE SIDE CARD
  // Changes dynamically based on _activeMode
  // ============================================================
  Widget _buildDynamicIntelligenceCard(bool isDark) {
    if (_isLocalityLoading) {
      return Container(
        height: 450,
        padding: const EdgeInsets.all(CRMSpacing.md),
        decoration: _cardBoxDecoration(isDark),
        child: Column(
          children: [
            const CRMSkeleton(width: 180, height: 16, borderRadius: 4),
            const SizedBox(height: 16),
            Expanded(child: _buildSkeletonList()),
          ],
        ),
      );
    }

    if (_localityError != null) {
      return Container(
        height: 450,
        padding: const EdgeInsets.all(CRMSpacing.md),
        decoration: _cardBoxDecoration(isDark),
        child: _buildErrorState(
          error: _localityError!,
          onRetry: _fetchLocalityData,
          isDark: isDark,
        ),
      );
    }

    switch (_activeMode) {
      case 'all_leads':
        return _buildAllLeadsIntelligence(isDark);
      case 'deal_won':
        return _buildDealWonIntelligence(isDark);
      case 'listing':
        return _buildListingLeadsIntelligence(isDark);
      case 'requirement':
        return _buildRequirementLeadsIntelligence(isDark);
      case 'compare':
        return _buildCompareIntelligence(isDark);
      case 'inventory':
      default:
        return _buildInventoryIntelligence(isDark);
    }
  }

  // A. INVENTORY MODE PANEL
  Widget _buildInventoryIntelligence(bool isDark) {
    final totalInventory = _localityData.totalInventory;
    final sorted = [..._localityData.localities]
      ..sort((a, b) => b.availableProperties.compareTo(a.availableProperties));

    final top5 = sorted.take(5).toList();
    final top5Sum = top5.fold<int>(0, (s, i) => s + i.availableProperties);
    final otherCount = totalInventory - top5Sum;

    return Container(
      height: 450,
      padding: const EdgeInsets.all(CRMSpacing.md),
      decoration: _cardBoxDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  size: 18,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Inventory by Area',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Active stock (${widget.businessType})',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (sorted.isNotEmpty)
                TextButton(
                  onPressed: () => _showAllLocalitiesDialog(
                    context: context,
                    title: 'Available Inventory by Area',
                    subtitle:
                        'All ${widget.businessType} available properties ranked by locality ($totalInventory total)',
                    localities: sorted,
                    metricGetter: (item) => item.availableProperties,
                    barColor: const Color(0xFF2563EB),
                    tooltipSuffix: 'available properties',
                    isDark: isDark,
                    onItemTap: (item) => _openInventoryDrilldown(
                      areaId: item.areaId,
                      areaName: item.areaName,
                      status: 'Available',
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF2563EB),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward_rounded, size: 13),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Total count (Clickable to open all available inventory drilldown)
          Tooltip(
            message: 'Click to view all $totalInventory available properties',
            child: InkWell(
              onTap: () => _openInventoryDrilldown(status: 'Available'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$totalInventory',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Available Properties',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 100% Stacked Distribution Bar
          _buildStackedDistributionBar(
            top5: top5,
            otherCount: otherCount,
            total: totalInventory,
            metricGetter: (item) => item.availableProperties,
            metricSuffix: 'available properties',
            isDark: isDark,
            onOtherTap: () => _openInventoryDrilldown(status: 'Available'),
          ),

          const SizedBox(height: 14),

          // Exact Ranked List (Top 5 + Other)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  ...List.generate(top5.length, (index) {
                    final item = top5[index];
                    final color =
                        _segmentColors[index % _segmentColors.length];
                    final pct = totalInventory > 0
                        ? (item.availableProperties / totalInventory) * 100.0
                        : 0.0;

                    return _buildRankedRow(
                      name: item.areaName,
                      count: item.availableProperties,
                      percentage: pct,
                      color: color,
                      onTap: () {
                        setState(() => _selectedLocality = item);
                        _mapController.move(
                          LatLng(item.latitude, item.longitude),
                          12.5,
                        );
                        _openInventoryDrilldown(
                          areaId: item.areaId,
                          areaName: item.areaName,
                          status: 'Available',
                        );
                      },
                      isDark: isDark,
                    );
                  }),
                  if (otherCount > 0) ...[
                    _buildRankedRow(
                      name: 'Other',
                      count: otherCount,
                      percentage: (otherCount / totalInventory) * 100.0,
                      color: _segmentColors.last,
                      onTap: () => _openInventoryDrilldown(status: 'Available'),
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // B. ALL LEADS MODE PANEL
  Widget _buildAllLeadsIntelligence(bool isDark) {
    final totalLeads = _localityData.totalLeads;
    final sorted = [..._localityData.localities]
      ..sort((a, b) => b.totalLeads.compareTo(a.totalLeads));

    final top5 = sorted.take(5).toList();
    final top5Sum = top5.fold<int>(0, (s, i) => s + i.totalLeads);
    final otherCount = totalLeads - top5Sum;

    return Container(
      height: 450,
      padding: const EdgeInsets.all(CRMSpacing.md),
      decoration: _cardBoxDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  size: 18,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All Inbound Leads by Area',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All channels & sources ($totalLeads total)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (sorted.isNotEmpty)
                TextButton(
                  onPressed: () => _showAllLocalitiesDialog(
                    context: context,
                    title: 'All Inbound Leads by Area',
                    subtitle:
                        'All buyer & listing inquiries ranked by locality ($totalLeads total)',
                    localities: sorted,
                    metricGetter: (item) => item.totalLeads,
                    barColor: const Color(0xFF0284C7),
                    tooltipSuffix: 'leads',
                    isDark: isDark,
                    onItemTap: (item) => _openLeadsDrilldown(
                      areaId: item.areaId,
                      areaName: item.areaName,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF0284C7),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward_rounded, size: 13),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Total count (Clickable to open all leads drilldown)
          Tooltip(
            message: 'Click to view all $totalLeads inbound leads',
            child: InkWell(
              onTap: () => _openLeadsDrilldown(),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$totalLeads',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total Inbound Leads',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0284C7)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 100% Stacked Distribution Bar
          _buildStackedDistributionBar(
            top5: top5,
            otherCount: otherCount,
            total: totalLeads,
            metricGetter: (item) => item.totalLeads,
            metricSuffix: 'leads',
            isDark: isDark,
            onOtherTap: () => _openLeadsDrilldown(),
          ),

          const SizedBox(height: 14),

          // Exact Ranked List (Top 5 + Other)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  ...List.generate(top5.length, (index) {
                    final item = top5[index];
                    final color =
                        _segmentColors[index % _segmentColors.length];
                    final pct = totalLeads > 0
                        ? (item.totalLeads / totalLeads) * 100.0
                        : 0.0;

                    return _buildRankedRow(
                      name: item.areaName,
                      count: item.totalLeads,
                      percentage: pct,
                      color: color,
                      onTap: () {
                        setState(() => _selectedLocality = item);
                        _mapController.move(
                          LatLng(item.latitude, item.longitude),
                          12.5,
                        );
                        _openLeadsDrilldown(
                          areaId: item.areaId,
                          areaName: item.areaName,
                        );
                      },
                      isDark: isDark,
                    );
                  }),
                  if (otherCount > 0) ...[
                    _buildRankedRow(
                      name: 'Other',
                      count: otherCount,
                      percentage: (otherCount / totalLeads) * 100.0,
                      color: _segmentColors.last,
                      onTap: () => _openLeadsDrilldown(),
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // C. DEALS WON MODE PANEL
  Widget _buildDealWonIntelligence(bool isDark) {
    final totalWon = _localityData.totalDealWonLeads;
    final sorted = [..._localityData.localities]
      ..sort((a, b) => b.dealWonLeads.compareTo(a.dealWonLeads));

    final wonLocalities = sorted.where((l) => l.dealWonLeads > 0).toList();

    return Container(
      height: 450,
      padding: const EdgeInsets.all(CRMSpacing.md),
      decoration: _cardBoxDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deals Won by Area',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Successfully closed transactions ($totalWon won)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (wonLocalities.isNotEmpty)
                TextButton(
                  onPressed: () => _showAllLocalitiesDialog(
                    context: context,
                    title: 'Deals Won by Area',
                    subtitle:
                        'All closed deals ranked by locality ($totalWon total)',
                    localities: wonLocalities,
                    metricGetter: (item) => item.dealWonLeads,
                    barColor: const Color(0xFF10B981),
                    tooltipSuffix: 'deals won',
                    isDark: isDark,
                    onItemTap: (item) => _openLeadsDrilldown(
                      areaId: item.areaId,
                      areaName: item.areaName,
                      isDealWon: true,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF10B981),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward_rounded, size: 13),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Total count (Clickable to open all deals won drilldown)
          Tooltip(
            message: 'Click to view all $totalWon deals won',
            child: InkWell(
              onTap: () => _openLeadsDrilldown(isDealWon: true),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$totalWon',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total Deals Won',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF10B981)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // List of localities with deals won
          Expanded(
            child: wonLocalities.isEmpty
                ? _buildEmptyState(
                    message: 'No deals won recorded across localities',
                    isDark: isDark,
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: wonLocalities.map((item) {
                        final pct = totalWon > 0
                            ? (item.dealWonLeads / totalWon) * 100.0
                            : 0.0;
                        final ratio = totalWon > 0
                            ? (item.dealWonLeads / totalWon).clamp(0.05, 1.0)
                            : 0.0;

                        return _buildMetricProgressBarRow(
                          name: item.areaName,
                          count: item.dealWonLeads,
                          ratio: ratio,
                          percentage: pct,
                          color: const Color(0xFF10B981),
                          onTap: () {
                            setState(() => _selectedLocality = item);
                            _mapController.move(
                              LatLng(item.latitude, item.longitude),
                              12.5,
                            );
                            _openLeadsDrilldown(
                              areaId: item.areaId,
                              areaName: item.areaName,
                              isDealWon: true,
                            );
                          },
                          isDark: isDark,
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // B. LISTING LEADS MODE PANEL
  Widget _buildListingLeadsIntelligence(bool isDark) {
    final totalListings = _localityData.totalListingLeads;
    final sorted = [..._localityData.localities]
      ..sort((a, b) => b.listingLeads.compareTo(a.listingLeads));

    final topItems = sorted.where((l) => l.listingLeads > 0).take(6).toList();
    final maxCount = topItems.isNotEmpty ? topItems.first.listingLeads : 1;

    return Container(
      height: 450,
      padding: const EdgeInsets.all(CRMSpacing.md),
      decoration: _cardBoxDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sell_outlined,
                  size: 18,
                  color: Color(0xFF0D9488),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Listing Leads by Area',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Seller & landlord listings',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (sorted.isNotEmpty)
                TextButton(
                  onPressed: () => _showAllLocalitiesDialog(
                    context: context,
                    title: 'Listing Leads by Area',
                    subtitle:
                        'All listing leads ranked by locality ($totalListings total)',
                    localities: sorted,
                    metricGetter: (item) => item.listingLeads,
                    barColor: const Color(0xFF0D9488),
                    tooltipSuffix: 'listing leads',
                    isDark: isDark,
                    onItemTap: (item) => _openLeadsDrilldown(
                      areaId: item.areaId,
                      areaName: item.areaName,
                      leadType: 'Listing',
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF0D9488),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward_rounded, size: 13),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Total count (Clickable to open all listing leads drilldown)
          Tooltip(
            message: 'Click to view all $totalListings listing leads',
            child: InkWell(
              onTap: () => _openLeadsDrilldown(leadType: 'Listing'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$totalListings',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total Listing Leads',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0D9488)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Ranked list with proportional bars
          Expanded(
            child: topItems.isEmpty
                ? _buildEmptyState(
                    message: 'No listing leads recorded by area',
                    isDark: isDark,
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: topItems.map((item) {
                        final ratio =
                            (item.listingLeads / maxCount).clamp(0.05, 1.0);
                        final pct = totalListings > 0
                            ? (item.listingLeads / totalListings) * 100.0
                            : 0.0;

                        return _buildMetricProgressBarRow(
                          name: item.areaName,
                          count: item.listingLeads,
                          ratio: ratio,
                          percentage: pct,
                          color: const Color(0xFF0D9488),
                          onTap: () {
                            setState(() => _selectedLocality = item);
                            _mapController.move(
                              LatLng(item.latitude, item.longitude),
                              12.5,
                            );
                            _openLeadsDrilldown(
                              areaId: item.areaId,
                              areaName: item.areaName,
                              leadType: 'Listing',
                            );
                          },
                          isDark: isDark,
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // C. REQUIREMENT LEADS MODE PANEL
  Widget _buildRequirementLeadsIntelligence(bool isDark) {
    final totalRequirements = _localityData.totalRequirementLeads;
    final sorted = [..._localityData.localities]
      ..sort((a, b) => b.requirementLeads.compareTo(a.requirementLeads));

    final topItems = sorted.where((l) => l.requirementLeads > 0).take(6).toList();
    final maxCount = topItems.isNotEmpty ? topItems.first.requirementLeads : 1;

    return Container(
      height: 450,
      padding: const EdgeInsets.all(CRMSpacing.md),
      decoration: _cardBoxDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_search_outlined,
                  size: 18,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requirement Leads by Area',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Buyer & tenant demand inquiries',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (sorted.isNotEmpty)
                TextButton(
                  onPressed: () => _showAllLocalitiesDialog(
                    context: context,
                    title: 'Requirement Leads by Area',
                    subtitle:
                        'All requirement leads ranked by locality ($totalRequirements total)',
                    localities: sorted,
                    metricGetter: (item) => item.requirementLeads,
                    barColor: const Color(0xFF7C3AED),
                    tooltipSuffix: 'requirement leads',
                    isDark: isDark,
                    onItemTap: (item) => _openLeadsDrilldown(
                      areaId: item.areaId,
                      areaName: item.areaName,
                      leadType: 'Requirement',
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF7C3AED),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward_rounded, size: 13),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Total count (Clickable to open all requirement leads drilldown)
          Tooltip(
            message: 'Click to view all $totalRequirements requirement leads',
            child: InkWell(
              onTap: () => _openLeadsDrilldown(leadType: 'Requirement'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$totalRequirements',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total Requirement Leads',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF7C3AED)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Ranked list with proportional bars
          Expanded(
            child: topItems.isEmpty
                ? _buildEmptyState(
                    message: 'No requirement leads recorded by area',
                    isDark: isDark,
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: topItems.map((item) {
                        final ratio =
                            (item.requirementLeads / maxCount).clamp(0.05, 1.0);
                        final pct = totalRequirements > 0
                            ? (item.requirementLeads / totalRequirements) * 100.0
                            : 0.0;

                        return _buildMetricProgressBarRow(
                          name: item.areaName,
                          count: item.requirementLeads,
                          ratio: ratio,
                          percentage: pct,
                          color: const Color(0xFF7C3AED),
                          onTap: () {
                            setState(() => _selectedLocality = item);
                            _mapController.move(
                              LatLng(item.latitude, item.longitude),
                              12.5,
                            );
                            _openLeadsDrilldown(
                              areaId: item.areaId,
                              areaName: item.areaName,
                              leadType: 'Requirement',
                            );
                          },
                          isDark: isDark,
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // D. COMPARE MODE PANEL
  Widget _buildCompareIntelligence(bool isDark) {
    final localities = [..._localityData.localities];
    localities.sort((a, b) {
      // Sort by high requirement leads or demand ratio
      return b.requirementLeads.compareTo(a.requirementLeads);
    });

    final selected = _selectedLocality;

    return Container(
      height: 450,
      padding: const EdgeInsets.all(CRMSpacing.md),
      decoration: _cardBoxDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 18,
                  color: Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Locality Demand vs Supply',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Supply vs Buyer Requirement Ratio',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (localities.isNotEmpty)
                TextButton(
                  onPressed: () => _showCompareTableDialog(
                    context: context,
                    localities: localities,
                    isDark: isDark,
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF6366F1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Compare Table',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward_rounded, size: 13),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Detail Card if locality is selected
          if (selected != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selected.areaName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFF8FAFC)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      Row(
                        children: [
                          _buildStatusBadge(selected.demandStatus),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => _selectedLocality = null),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactKpiBox(
                          label: 'Available',
                          value: '${selected.availableProperties}',
                          color: const Color(0xFF2563EB),
                          icon: Icons.apartment_rounded,
                          isDark: isDark,
                          onTap: () => _openInventoryDrilldown(
                            areaId: selected.areaId,
                            areaName: selected.areaName,
                            status: 'Available',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCompactKpiBox(
                          label: 'Listings',
                          value: '${selected.listingLeads}',
                          color: const Color(0xFF0D9488),
                          icon: Icons.sell_outlined,
                          isDark: isDark,
                          onTap: () => _openLeadsDrilldown(
                            areaId: selected.areaId,
                            areaName: selected.areaName,
                            leadType: 'Listing',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCompactKpiBox(
                          label: 'Demand',
                          value: '${selected.requirementLeads}',
                          color: const Color(0xFF7C3AED),
                          icon: Icons.person_search_outlined,
                          isDark: isDark,
                          onTap: () => _openLeadsDrilldown(
                            areaId: selected.areaId,
                            areaName: selected.areaName,
                            leadType: 'Requirement',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (selected.demandStatus == 'High Demand'
                              ? const Color(0xFFEA580C)
                              : (selected.demandStatus == 'Balanced'
                                  ? const Color(0xFF0D9488)
                                  : const Color(0xFF2563EB)))
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      selected.demandStatus == 'High Demand'
                          ? '⚡ High buyer demand (${selected.demandRatio.toStringAsFixed(1)}x ratio). Urgent need for new property listings!'
                          : (selected.demandStatus == 'Balanced'
                              ? '⚖️ Balanced market (${selected.demandRatio.toStringAsFixed(1)}x ratio). Supply matches buyer demand well.'
                              : '📦 Ample inventory (${selected.demandRatio.toStringAsFixed(1)}x ratio). Focus on generating buyer requirements.'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected.demandStatus == 'High Demand'
                            ? const Color(0xFFEA580C)
                            : (selected.demandStatus == 'Balanced'
                                ? const Color(0xFF0D9488)
                                : const Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Other Top Localities',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.touch_app_outlined,
                    size: 16,
                    color: Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Click any bubble on the map or row below to view detailed intelligence.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Ranked localities comparison rows
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: localities.take(selected != null ? 3 : 5).map((loc) {
                  final isCurrentSelected =
                      selected?.areaName.toLowerCase() == loc.areaName.toLowerCase();

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedLocality = loc);
                      _mapController.move(
                        LatLng(loc.latitude, loc.longitude),
                        12.5,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrentSelected
                            ? (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFEEF2FF))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrentSelected
                              ? const Color(0xFF6366F1)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              loc.areaName,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFF1F5F9)
                                    : const Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '🏠 ${loc.availableProperties}  🎯 ${loc.requirementLeads}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(loc.demandStatus),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 3. LEAD AREA DEMAND CARD (Preserved with Listing/Requirement toggle)
  // ============================================================
  Widget _buildLeadDemandCard(bool isDark) {
    final isListing = _selectedLeadDemandType == 'listing';
    final accentColor = isListing
        ? const Color(0xFF0D9488) // Teal
        : const Color(0xFF7C3AED); // Violet

    final totalLeads = _leadDemandItems.fold<int>(0, (s, i) => s + i.count);

    return Container(
      padding: const EdgeInsets.all(CRMSpacing.md),
      decoration: _cardBoxDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header + Segmented Toggle
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isListing
                      ? Icons.sell_outlined
                      : Icons.person_search_outlined,
                  size: 18,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lead Area Demand',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isListing
                          ? 'Localities with top seller/landlord listings'
                          : 'Localities with top buyer/tenant requirements',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Segmented Toggle
              Container(
                height: 30,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTogglePill(
                      label: 'Listing',
                      isSelected: isListing,
                      activeColor: const Color(0xFF0D9488),
                      onTap: () {
                        if (_selectedLeadDemandType != 'listing') {
                          setState(() => _selectedLeadDemandType = 'listing');
                          _fetchLeadDemand();
                        }
                      },
                      isDark: isDark,
                    ),
                    _buildTogglePill(
                      label: 'Requirement',
                      isSelected: !isListing,
                      activeColor: const Color(0xFF7C3AED),
                      onTap: () {
                        if (_selectedLeadDemandType != 'requirement') {
                          setState(() => _selectedLeadDemandType = 'requirement');
                          _fetchLeadDemand();
                        }
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sub-header with View All
          if (!_isLeadDemandLoading &&
              _leadDemandError == null &&
              _leadDemandItems.length > 6)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showAllAreasDialog(
                  context: context,
                  title: isListing
                      ? 'Listing Leads by Area'
                      : 'Requirement Leads by Area',
                  subtitle:
                      'All ${isListing ? "Listing" : "Requirement"} leads ranked by locality ($totalLeads total)',
                  items: _leadDemandItems,
                  barColor: accentColor,
                  tooltipSuffix:
                      isListing ? 'listing leads' : 'requirement leads',
                  isDark: isDark,
                  onItemTap: (item) => _openLeadsDrilldown(
                    areaId: item.areaId,
                    areaName: item.area,
                    leadType: isListing ? 'Listing' : 'Requirement',
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  visualDensity: VisualDensity.compact,
                  foregroundColor: accentColor,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All (${_leadDemandItems.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.arrow_forward_rounded, size: 13),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 4),

          // Content body
          if (_isLeadDemandLoading)
            _buildSkeletonList()
          else if (_leadDemandError != null)
            _buildErrorState(
              error: _leadDemandError!,
              onRetry: _fetchLeadDemand,
              isDark: isDark,
            )
          else if (_leadDemandItems.isEmpty)
            _buildEmptyState(
              message:
                  'No ${isListing ? "listing" : "requirement"} leads found',
              isDark: isDark,
            )
          else
            _buildHorizontalBars(
              items: _leadDemandItems.take(6).toList(),
              barColor: accentColor,
              tooltipSuffix:
                  isListing ? 'listing leads' : 'requirement leads',
              isDark: isDark,
              onItemTap: (item) => _openLeadsDrilldown(
                areaId: item.areaId,
                areaName: item.area,
                leadType: isListing ? 'Listing' : 'Requirement',
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // REUSABLE HELPER WIDGETS
  // ============================================================
  BoxDecoration _cardBoxDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(CRMBorderRadius.card),
      border: Border.all(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    if (status == 'High Demand') {
      bg = const Color(0xFFEA580C).withValues(alpha: 0.15);
      fg = const Color(0xFFEA580C);
    } else if (status == 'Balanced') {
      bg = const Color(0xFF0D9488).withValues(alpha: 0.15);
      fg = const Color(0xFF0D9488);
    } else if (status == 'High Supply') {
      bg = const Color(0xFF2563EB).withValues(alpha: 0.15);
      fg = const Color(0xFF2563EB);
    } else {
      bg = const Color(0xFF64748B).withValues(alpha: 0.15);
      fg = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildCompactKpiBox({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final boxContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: onTap != null ? Border.all(color: color.withValues(alpha: 0.25)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward_rounded, size: 10, color: color),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: boxContent,
      );
    }
    return boxContent;
  }

  Widget _buildStackedDistributionBar({
    required List<LocalityIntelligenceItem> top5,
    required int otherCount,
    required int total,
    required int Function(LocalityIntelligenceItem) metricGetter,
    required String metricSuffix,
    required bool isDark,
    VoidCallback? onOtherTap,
  }) {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...List.generate(top5.length, (index) {
            final item = top5[index];
            final count = metricGetter(item);
            final color = _segmentColors[index % _segmentColors.length];
            final pct =
                total > 0 ? (count / total) * 100.0 : 0.0;

            if (count <= 0) return const SizedBox.shrink();

            return Expanded(
              flex: count,
              child: Tooltip(
                message:
                    '${item.areaName}\n$count $metricSuffix\n${pct.toStringAsFixed(1)}% of total',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0.5),
                  color: color,
                ),
              ),
            );
          }),
          if (otherCount > 0)
            Expanded(
              flex: otherCount,
              child: Tooltip(
                message:
                    'Other\n$otherCount $metricSuffix\n${((otherCount / total) * 100.0).toStringAsFixed(1)}% of total',
                child: InkWell(
                  onTap: onOtherTap,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    color: _segmentColors.last,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRankedRow({
    required String name,
    required int count,
    required double percentage,
    required Color color,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.5, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 48,
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricProgressBarRow({
    required String name,
    required int count,
    required double ratio,
    required double percentage,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 2, left: 4, right: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),
            LayoutBuilder(
              builder: (context, constraints) {
                final targetWidth = constraints.maxWidth * ratio;
                return Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155).withValues(alpha: 0.5)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      height: 6,
                      width: targetWidth,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTogglePill({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? activeColor
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalBars({
    required List<AreaCountItem> items,
    required Color barColor,
    required String tooltipSuffix,
    required bool isDark,
    ValueChanged<AreaCountItem>? onItemTap,
  }) {
    final maxCount = items.map((e) => e.count).fold<int>(
          1,
          (prev, curr) => curr > prev ? curr : prev,
        );

    return Column(
      children: items.map((item) {
        final ratio = (item.count / maxCount).clamp(0.04, 1.0);

        return InkWell(
          onTap: onItemTap != null ? () => onItemTap(item) : null,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.area,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: barColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.count}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: barColor,
                        ),
                      ),
                    ),
                    if (onItemTap != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final targetWidth = constraints.maxWidth * ratio;

                    return Stack(
                      children: [
                        Container(
                          height: 7,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF334155).withValues(alpha: 0.5)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          height: 7,
                          width: targetWidth,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                barColor.withValues(alpha: 0.75),
                                barColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSkeletonList() {
    final mockWidths = [0.85, 0.70, 0.55, 0.45, 0.35];

    return Column(
      children: mockWidths.map((ratio) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CRMSkeleton(
                    width: 100 + (ratio * 50),
                    height: 12,
                    borderRadius: 4,
                  ),
                  const CRMSkeleton(
                    width: 32,
                    height: 14,
                    borderRadius: 6,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Container(
                        height: 7,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      CRMSkeleton(
                        width: constraints.maxWidth * ratio,
                        height: 7,
                        borderRadius: 4,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorState({
    required String error,
    required VoidCallback onRetry,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 32,
            color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text(
              'Retry',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required String message,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 32,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 4. DIALOGS
  // ============================================================
  void _showAllLocalitiesDialog({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<LocalityIntelligenceItem> localities,
    required int Function(LocalityIntelligenceItem) metricGetter,
    required Color barColor,
    required String tooltipSuffix,
    required bool isDark,
    ValueChanged<LocalityIntelligenceItem>? onItemTap,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return _AllLocalitiesDialog(
          title: title,
          subtitle: subtitle,
          localities: localities,
          metricGetter: metricGetter,
          barColor: barColor,
          tooltipSuffix: tooltipSuffix,
          isDark: isDark,
          onItemTap: onItemTap,
        );
      },
    );
  }

  void _showCompareTableDialog({
    required BuildContext context,
    required List<LocalityIntelligenceItem> localities,
    required bool isDark,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return _CompareTableDialog(
          localities: localities,
          isDark: isDark,
          onSelectLocality: (item) {
            setState(() {
              _selectedLocality = item;
            });
            _mapController.move(
              LatLng(item.latitude, item.longitude),
              12.5,
            );
          },
        );
      },
    );
  }

  void _showAllAreasDialog({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<AreaCountItem> items,
    required Color barColor,
    required String tooltipSuffix,
    required bool isDark,
    ValueChanged<AreaCountItem>? onItemTap,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return _AllAreasDialog(
          title: title,
          subtitle: subtitle,
          items: items,
          barColor: barColor,
          tooltipSuffix: tooltipSuffix,
          isDark: isDark,
          onItemTap: onItemTap,
        );
      },
    );
  }
}

// Dialog: All Localities Ranking for single metric
class _AllLocalitiesDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<LocalityIntelligenceItem> localities;
  final int Function(LocalityIntelligenceItem) metricGetter;
  final Color barColor;
  final String tooltipSuffix;
  final bool isDark;
  final ValueChanged<LocalityIntelligenceItem>? onItemTap;

  const _AllLocalitiesDialog({
    required this.title,
    required this.subtitle,
    required this.localities,
    required this.metricGetter,
    required this.barColor,
    required this.tooltipSuffix,
    required this.isDark,
    this.onItemTap,
  });

  @override
  State<_AllLocalitiesDialog> createState() => _AllLocalitiesDialogState();
}

class _AllLocalitiesDialogState extends State<_AllLocalitiesDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.localities.where((i) {
      if (_searchQuery.trim().isEmpty) return true;
      return i.areaName
          .toLowerCase()
          .contains(_searchQuery.trim().toLowerCase());
    }).toList();

    final totalCount = widget.localities
        .fold<int>(0, (s, i) => s + widget.metricGetter(i));
    final maxCount = widget.localities
        .map((e) => widget.metricGetter(e))
        .fold<int>(1, (prev, curr) => curr > prev ? curr : prev);

    final isDark = widget.isDark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search field
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search locality / area...',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: widget.barColor,
                      width: 1.5,
                    ),
                  ),
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),

              // Scrollable ranking list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No areas matching "$_searchQuery"',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, index) {
                          final item = filtered[index];
                          final count = widget.metricGetter(item);
                          final ratio = (count / maxCount).clamp(0.04, 1.0);
                          final pct =
                              totalCount > 0 ? (count / totalCount) * 100.0 : 0.0;

                          return InkWell(
                            onTap: widget.onItemTap != null
                                ? () {
                                    Navigator.of(context).pop();
                                    widget.onItemTap!(item);
                                  }
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '#${index + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.areaName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? const Color(0xFFF1F5F9)
                                                : const Color(0xFF1E293B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: widget.barColor.withValues(
                                            alpha: isDark ? 0.2 : 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$count',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: widget.barColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 44,
                                        child: Text(
                                          '${pct.toStringAsFixed(1)}%',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                      if (widget.onItemTap != null) ...[
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 14,
                                          color: isDark
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final targetWidth =
                                          constraints.maxWidth * ratio;
                                      return Stack(
                                        children: [
                                          Container(
                                            height: 7,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF334155)
                                                      .withValues(alpha: 0.5)
                                                  : const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          Container(
                                            height: 7,
                                            width: targetWidth,
                                            decoration: BoxDecoration(
                                              color: widget.barColor,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dialog: Locality Comparison Table (Compare mode modal)
class _CompareTableDialog extends StatefulWidget {
  final List<LocalityIntelligenceItem> localities;
  final bool isDark;
  final ValueChanged<LocalityIntelligenceItem> onSelectLocality;

  const _CompareTableDialog({
    required this.localities,
    required this.isDark,
    required this.onSelectLocality,
  });

  @override
  State<_CompareTableDialog> createState() => _CompareTableDialogState();
}

class _CompareTableDialogState extends State<_CompareTableDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final filtered = widget.localities.where((i) {
      if (_searchQuery.trim().isEmpty) return true;
      return i.areaName
          .toLowerCase()
          .contains(_searchQuery.trim().toLowerCase());
    }).toList();

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Locality Intelligence Comparison',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Compare available inventory, listing leads, and requirement demand',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search field
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search locality...',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),

              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 4,
                      child: Text(
                        'Locality',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Available',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Listings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Demand',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 3,
                      child: Text(
                        'Signal',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // List rows
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  itemBuilder: (ctx, index) {
                    final item = filtered[index];
                    return InkWell(
                      onTap: () {
                        widget.onSelectLocality(item);
                        Navigator.of(context).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                item.areaName,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFFF1F5F9)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${item.availableProperties}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${item.listingLeads}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0D9488),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${item.requirementLeads}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF7C3AED),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (item.demandStatus == 'High Demand'
                                            ? const Color(0xFFEA580C)
                                            : (item.demandStatus == 'Balanced'
                                                ? const Color(0xFF0D9488)
                                                : const Color(0xFF2563EB)))
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.demandStatus,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: item.demandStatus == 'High Demand'
                                          ? const Color(0xFFEA580C)
                                          : (item.demandStatus == 'Balanced'
                                              ? const Color(0xFF0D9488)
                                              : const Color(0xFF2563EB)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dialog: Original AreaCountItem ranking (for bottom card View All)
class _AllAreasDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<AreaCountItem> items;
  final Color barColor;
  final String tooltipSuffix;
  final bool isDark;
  final ValueChanged<AreaCountItem>? onItemTap;

  const _AllAreasDialog({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.barColor,
    required this.tooltipSuffix,
    required this.isDark,
    this.onItemTap,
  });

  @override
  State<_AllAreasDialog> createState() => _AllAreasDialogState();
}

class _AllAreasDialogState extends State<_AllAreasDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((i) {
      if (_searchQuery.trim().isEmpty) return true;
      return i.area.toLowerCase().contains(_searchQuery.trim().toLowerCase());
    }).toList();

    final totalCount = widget.items.fold<int>(0, (s, i) => s + i.count);
    final maxCount = widget.items.map((e) => e.count).fold<int>(
          1,
          (prev, curr) => curr > prev ? curr : prev,
        );

    final isDark = widget.isDark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search field
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search locality / area...',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  isDense: true,
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: widget.barColor,
                      width: 1.5,
                    ),
                  ),
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),

              // Scrollable ranking list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No areas matching "$_searchQuery"',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, index) {
                          final item = filtered[index];
                          final ratio =
                              (item.count / maxCount).clamp(0.04, 1.0);
                          final pct = totalCount > 0
                              ? (item.count / totalCount) * 100.0
                              : 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: widget.onItemTap != null
                                  ? () {
                                      Navigator.of(context).pop();
                                      widget.onItemTap!(item);
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 6,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '#${index + 1}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? const Color(0xFF64748B)
                                                : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.area,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? const Color(0xFFF1F5F9)
                                                  : const Color(0xFF1E293B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: widget.barColor.withValues(
                                              alpha: isDark ? 0.2 : 0.1,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${item.count}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: widget.barColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 44,
                                          child: Text(
                                            '${pct.toStringAsFixed(1)}%',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                        if (widget.onItemTap != null) ...[
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 14,
                                            color: isDark
                                                ? const Color(0xFF64748B)
                                                : const Color(0xFF94A3B8),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final targetWidth =
                                            constraints.maxWidth * ratio;
                                        return Stack(
                                          children: [
                                            Container(
                                              height: 7,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF334155)
                                                        .withValues(alpha: 0.5)
                                                    : const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                            Container(
                                              height: 7,
                                              width: targetWidth,
                                              decoration: BoxDecoration(
                                                color: widget.barColor,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
