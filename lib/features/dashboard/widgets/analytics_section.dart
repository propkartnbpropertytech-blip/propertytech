import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/dashboard_summary.dart';

class AnalyticsSection extends StatelessWidget {
  final DashboardData? data;
  final bool isRent;

  const AnalyticsSection({super.key, this.data, this.isRent = false});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: InventoryOverviewChartCard(
              summary: data?.summary,
              isRent: isRent,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: TopLocationsChartCard(
              locations: data?.inventoryLocations ?? const [],
              properties: data?.recentProperties ?? const [],
              topArea: data?.summary.topArea,
              isRent: isRent,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        InventoryOverviewChartCard(
          summary: data?.summary,
          isRent: isRent,
        ),
        const SizedBox(height: 20),
        TopLocationsChartCard(
          locations: data?.inventoryLocations ?? const [],
          properties: data?.recentProperties ?? const [],
          topArea: data?.summary.topArea,
          isRent: isRent,
        ),
      ],
    );
  }
}

// ── Inventory snapshot (horizontal comparison, not a fake trend) ──
class InventoryOverviewChartCard extends StatelessWidget {
  final DashboardSummary? summary;
  final bool isRent;

  const InventoryOverviewChartCard({
    super.key,
    this.summary,
    this.isRent = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primary = ThemeManager().primaryColor;
    final availableVal = (isRent
            ? summary?.rentalAvailable
            : summary?.resaleAvailable) ??
        0;
    final closedVal = (isRent ? summary?.rentalRented : summary?.resaleSold) ?? 0;
    final leadsVal = (isRent
            ? summary?.rentalRequirements
            : summary?.resaleRequirements) ??
        0;
    final wonVal = (isRent
            ? summary?.rentalWonRequirements
            : summary?.resaleWonRequirements) ??
        0;

    final listingTotal = availableVal + closedVal;
    final leadTotal = leadsVal + wonVal;
    final listingShare = listingTotal == 0
        ? 0
        : ((availableVal / listingTotal) * 100).round();
    final conversion = leadTotal == 0
        ? 0
        : ((wonVal / leadTotal) * 100).round();
    final closedLabel = isRent ? 'Rented' : 'Sold';

    final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRent ? 'Rental snapshot' : 'Re-sale snapshot',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: titleColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Open vs closed listings, and lead conversion',
            style: TextStyle(fontSize: 12, color: mutedColor),
          ),
          const SizedBox(height: 20),
          _SnapshotGroupLabel(
            label: 'Listings',
            hint: listingTotal == 0
                ? 'No listings yet'
                : '$listingShare% still available',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _SnapshotBar(
            label: 'Available',
            value: availableVal,
            maxValue: listingTotal,
            color: primary,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _SnapshotBar(
            label: closedLabel,
            value: closedVal,
            maxValue: listingTotal,
            color: const Color(0xFF64748B),
            isDark: isDark,
          ),
          const SizedBox(height: 18),
          _SnapshotGroupLabel(
            label: 'Leads',
            hint: leadTotal == 0
                ? 'No leads yet'
                : '$conversion% converted to won',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _SnapshotBar(
            label: 'Active',
            value: leadsVal,
            maxValue: leadTotal,
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _SnapshotBar(
            label: 'Won',
            value: wonVal,
            maxValue: leadTotal,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _SnapshotGroupLabel extends StatelessWidget {
  final String label;
  final String hint;
  final bool isDark;

  const _SnapshotGroupLabel({
    required this.label,
    required this.hint,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hint,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF68738A),
            ),
          ),
        ),
      ],
    );
  }
}

class _SnapshotBar extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final bool isDark;

  const _SnapshotBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    final track = isDark ? const Color(0xFF243044) : const Color(0xFFF1F4F9);
    final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Stack(
              children: [
                Container(color: track),
                FractionallySizedBox(
                  widthFactor: fraction == 0 ? 0 : math.max(fraction, 0.04),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Top Locations Donut Chart ───────────────────────────────
class TopLocationsChartCard extends StatefulWidget {
  final List<DashboardLocationItem> locations;
  final List<RecentProperty> properties;
  final String? topArea;
  final bool isRent;

  const TopLocationsChartCard({
    super.key,
    this.locations = const [],
    this.properties = const [],
    this.topArea,
    this.isRent = false,
  });

  @override
  State<TopLocationsChartCard> createState() => _TopLocationsChartCardState();
}

class _TopLocationsChartCardState extends State<TopLocationsChartCard> {
  String _selectedCategory = 'All'; // 'All', 'Residential', 'Commercial', 'Industrial', 'Land & Plot'
  String _selectedRange = 'All Time'; // 'All Time', 'This Month', 'This Week', 'This Quarter', 'This Year'
  String _selectedDesk = 'All Desks'; // 'All Desks', 'Rental', 'Re-Sale'

  static const _categories = [
    'All',
    'Residential',
    'Commercial',
    'Industrial',
    'Land & Plot',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = ThemeManager().primaryColor;
    final now = DateTime.now();

    // Helper to test if an item matches desk
    bool matchesDesk(String listingType) {
      if (_selectedDesk == 'Rental') {
        return listingType.toLowerCase().contains('rent');
      }
      if (_selectedDesk == 'Re-Sale') {
        return !listingType.toLowerCase().contains('rent');
      }
      return true; // 'All Desks'
    }

    // Helper to test if an item matches date range
    bool matchesRange(DateTime? createdAt) {
      if (createdAt == null || _selectedRange == 'All Time') return true;
      if (_selectedRange == 'This Month') {
        final startOfMonth = DateTime(now.year, now.month, 1);
        return createdAt.isAfter(startOfMonth) || createdAt.isAtSameMomentAs(startOfMonth);
      }
      if (_selectedRange == 'This Week') {
        final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        return createdAt.isAfter(startOfWeek) || createdAt.isAtSameMomentAs(startOfWeek);
      }
      if (_selectedRange == 'This Quarter') {
        final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        final startOfQuarter = DateTime(now.year, quarterStartMonth, 1);
        return createdAt.isAfter(startOfQuarter) || createdAt.isAtSameMomentAs(startOfQuarter);
      }
      if (_selectedRange == 'This Year') {
        final startOfYear = DateTime(now.year, 1, 1);
        return createdAt.isAfter(startOfYear) || createdAt.isAtSameMomentAs(startOfYear);
      }
      return true;
    }

    // Helper to test if an item matches category
    bool matchesCategory(String categoryName, String categoryTarget) {
      if (categoryTarget == 'All') return true;
      final cat = categoryName.trim().toLowerCase();
      if (categoryTarget == 'Residential') return cat.contains('residen');
      if (categoryTarget == 'Commercial') return cat.contains('commerc');
      if (categoryTarget == 'Industrial') return cat.contains('indust');
      if (categoryTarget == 'Land & Plot') return cat.contains('land') || cat.contains('plot');
      return true;
    }

    // Compute category counts for badge pills across current desk and range
    final Map<String, int> categoryBadgeCounts = {
      for (final cat in _categories) cat: 0,
    };

    if (widget.locations.isNotEmpty) {
      for (final loc in widget.locations) {
        if (!matchesDesk(loc.listingType)) continue;
        if (!matchesRange(loc.createdAt)) continue;

        categoryBadgeCounts['All'] = (categoryBadgeCounts['All'] ?? 0) + 1;
        for (final cat in _categories) {
          if (cat == 'All') continue;
          if (matchesCategory(loc.categoryName, cat)) {
            categoryBadgeCounts[cat] = (categoryBadgeCounts[cat] ?? 0) + 1;
          }
        }
      }
    } else {
      for (final p in widget.properties) {
        if (!matchesDesk(p.listingType)) continue;
        final dt = DateTime.tryParse(p.createdAt);
        if (!matchesRange(dt)) continue;

        categoryBadgeCounts['All'] = (categoryBadgeCounts['All'] ?? 0) + 1;
        categoryBadgeCounts['Residential'] = (categoryBadgeCounts['Residential'] ?? 0) + 1;
      }
    }

    // Filter items for the currently selected category
    final Map<String, int> areaCounts = {};
    int totalUnits = 0;

    if (widget.locations.isNotEmpty) {
      for (final loc in widget.locations) {
        if (!matchesDesk(loc.listingType)) continue;
        if (!matchesRange(loc.createdAt)) continue;
        if (!matchesCategory(loc.categoryName, _selectedCategory)) continue;

        totalUnits++;
        var area = loc.areaName.trim();
        if (area.isEmpty || area == 'N/A') area = 'Other';
        areaCounts[area] = (areaCounts[area] ?? 0) + 1;
      }
    } else {
      for (final p in widget.properties) {
        if (!matchesDesk(p.listingType)) continue;
        final dt = DateTime.tryParse(p.createdAt);
        if (!matchesRange(dt)) continue;

        totalUnits++;
        var area = p.areaName.trim();
        if (area.isEmpty || area == 'N/A') area = 'Other';
        areaCounts[area] = (areaCounts[area] ?? 0) + 1;
      }
    }

    final colors = [
      primaryColor,
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFF97316), // Orange
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF10B981), // Emerald
    ];

    final List<_LocationData> locations = [];
    if (areaCounts.isNotEmpty) {
      final sortedEntries = areaCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topEntries = sortedEntries.take(5).toList();
      int topSum = 0;
      for (int i = 0; i < topEntries.length; i++) {
        topSum += topEntries[i].value;
        locations.add(
          _LocationData(
            name: topEntries[i].key,
            count: topEntries[i].value,
            color: colors[i % colors.length],
          ),
        );
      }
      final remaining = totalUnits - topSum;
      if (remaining > 0) {
        locations.add(
          _LocationData(
            name: 'Others',
            count: remaining,
            color: const Color(0xFF94A3B8),
          ),
        );
      }
    } else if (totalUnits > 0 &&
        widget.topArea != null &&
        widget.topArea!.isNotEmpty &&
        widget.topArea != 'N/A') {
      locations.add(
        _LocationData(name: widget.topArea!, count: totalUnits, color: colors[0]),
      );
    }

    final int chartTotal = totalUnits;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Subtitle + Desk & Date dropdowns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Locations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF14213D),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Active listings by micro-market',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF68738A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Desk filter
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF243044)
                          : const Color(0xFFF1F4F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDesk,
                        dropdownColor:
                            isDark ? const Color(0xFF1E293B) : Colors.white,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF68738A),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFF8FAFC)
                              : const Color(0xFF14213D),
                        ),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDesk = val);
                        },
                        items: const [
                          'All Desks',
                          'Rental',
                          'Re-Sale',
                        ]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  // Date range filter
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF243044)
                          : const Color(0xFFF1F4F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRange,
                        dropdownColor:
                            isDark ? const Color(0xFF1E293B) : Colors.white,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF68738A),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFF8FAFC)
                              : const Color(0xFF14213D),
                        ),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRange = val);
                        },
                        items: const [
                          'All Time',
                          'This Month',
                          'This Week',
                          'This Quarter',
                          'This Year',
                        ]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Category Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                final badgeCount = categoryBadgeCounts[cat] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedCategory = cat),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.12)
                            : (isDark
                                ? const Color(0xFF243044)
                                : const Color(0xFFF1F4F9)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor
                              : (isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0)),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? Colors.white : primaryColor)
                                  : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor
                                  : (isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$badgeCount',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(0xFF475569)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          if (locations.isNotEmpty && chartTotal > 0)
            LayoutBuilder(
              builder: (context, cardConstraints) {
                final isNarrow = cardConstraints.maxWidth < 360;
                final chart = SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(130, 130),
                        painter: _DonutChartPainter(
                          locations: locations,
                          total: chartTotal,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$chartTotal',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFF14213D),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            chartTotal == 1 ? 'Unit' : 'Units',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF68738A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                final legend = Column(
                  children: locations.map((loc) {
                    final percent =
                        ((loc.count / chartTotal) * 100).toStringAsFixed(0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: loc.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loc.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFFF8FAFC)
                                    : const Color(0xFF14213D),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${loc.count} ($percent%)',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF68738A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      chart,
                      const SizedBox(height: 16),
                      legend,
                    ],
                  );
                }

                return Row(
                  children: [
                    chart,
                    const SizedBox(width: 20),
                    Expanded(child: legend),
                  ],
                );
              },
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_city_outlined,
                      size: 36,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFFCBD5E1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedCategory == 'All'
                          ? 'No active listings found for the selected filter'
                          : 'No active $_selectedCategory listings found',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF68738A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationData {
  final String name;
  final int count;
  final Color color;

  const _LocationData({
    required this.name,
    required this.count,
    required this.color,
  });
}

class _DonutChartPainter extends CustomPainter {
  final List<_LocationData> locations;
  final int total;

  _DonutChartPainter({required this.locations, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 16.0;

    double startAngle = -math.pi / 2;

    for (final loc in locations) {
      final sweepAngle = (loc.count / total) * 2 * math.pi;
      final paint = Paint()
        ..color = loc.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      // Inset to prevent clipping
      final rect = Rect.fromCircle(
        center: center,
        radius: radius - strokeWidth / 2,
      );
      canvas.drawArc(rect, startAngle, sweepAngle - 0.08, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
