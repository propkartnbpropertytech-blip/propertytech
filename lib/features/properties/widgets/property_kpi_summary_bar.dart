import 'package:flutter/material.dart';
import '../../dashboard/widgets/stat_card.dart';
import '../models/property_model.dart';

class PropertyKpiSummaryBar extends StatelessWidget {
  final List<PropertyModel> properties;
  final String activeListingTab;
  final ValueChanged<String> onListingTabChanged;
  final bool myAddedOnly;
  final VoidCallback onToggleMyAdded;
  final String? currentUserId;
  final bool isSalesOrTelecaller;

  const PropertyKpiSummaryBar({
    super.key,
    required this.properties,
    required this.activeListingTab,
    required this.onListingTabChanged,
    required this.myAddedOnly,
    required this.onToggleMyAdded,
    this.currentUserId,
    this.isSalesOrTelecaller = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    int totalAvailable = 0;
    int rentCount = 0;
    int resaleCount = 0;
    int newThisWeek = 0;
    int withPhotosCount = 0;
    int myAddedCount = 0;

    for (final p in properties) {
      final statusLower = (p.propertyStatusName).toLowerCase();
      final ltLower = p.listingTypeName.toLowerCase();

      if (statusLower == 'available' || statusLower.isEmpty) {
        totalAvailable++;
      }
      if (ltLower.contains('rent')) {
        rentCount++;
      } else {
        resaleCount++;
      }

      if (p.createdAt.isAfter(sevenDaysAgo)) {
        newThisWeek++;
      }

      if (p.images.isNotEmpty) {
        withPhotosCount++;
      }

      if (currentUserId != null && p.createdBy == currentUserId) {
        myAddedCount++;
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;

    final cards = <Widget>[
      // 1. Total Available Inventory
      StatCard(
        title: 'Available Units',
        value: '$totalAvailable',
        subtitle: '${properties.length} total in portfolio',
        icon: Icons.domain_rounded,
        accentColor: const Color(0xFF10B981),
      ),
      // 2. Rental Listings
      StatCard(
        title: 'Rental Properties',
        value: '$rentCount',
        subtitle: activeListingTab == 'Rent' ? 'Active view' : 'Tap to switch',
        icon: Icons.vpn_key_rounded,
        accentColor: const Color(0xFF0EA5E9),
        onTap: () => onListingTabChanged('Rent'),
      ),
      // 3. Re-Sale Listings
      StatCard(
        title: 'Re-Sale Properties',
        value: '$resaleCount',
        subtitle: activeListingTab == 'Re-Sale' ? 'Active view' : 'Tap to switch',
        icon: Icons.sell_rounded,
        accentColor: const Color(0xFF6366F1),
        onTap: () => onListingTabChanged('Re-Sale'),
      ),
      // 4. Fresh Listings Added This Week
      StatCard(
        title: 'Added This Week',
        value: '$newThisWeek',
        subtitle: 'Last 7 days',
        icon: Icons.auto_awesome_rounded,
        accentColor: const Color(0xFFF59E0B),
      ),
      // 5. Ready with Photos
      StatCard(
        title: 'Ready with Photos',
        value: '$withPhotosCount',
        subtitle: '${properties.length - withPhotosCount} missing photos',
        icon: Icons.photo_library_rounded,
        accentColor: const Color(0xFF14B8A6),
      ),
      // 6. My Listings (if logged-in user has added or if sales/telecaller)
      if (isSalesOrTelecaller || myAddedCount > 0)
        StatCard(
          title: 'My Listings',
          value: '$myAddedCount',
          subtitle: myAddedOnly ? 'Filter active' : 'Tap to toggle',
          icon: Icons.person_pin_rounded,
          accentColor: const Color(0xFFEC4899),
          onTap: onToggleMyAdded,
        ),
    ];

    if (isMobile) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 10) / 2;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: cards.map((c) => SizedBox(width: itemWidth, child: c)).toList(),
          );
        },
      );
    }

    if (isTablet) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 20) / 3;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: cards.map((c) => SizedBox(width: itemWidth, child: c)).toList(),
          );
        },
      );
    }

    // Desktop: 5 or 6 columns
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = cards.length;
        const spacing = 12.0;
        return Row(
          children: cards.map((c) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: c == cards.last ? 0 : spacing,
                ),
                child: c,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
