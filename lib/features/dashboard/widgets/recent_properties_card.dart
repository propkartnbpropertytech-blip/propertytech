import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/widgets/crm_network_image.dart';
import '../../../core/theme/theme_manager.dart';
import '../../properties/models/property_model.dart';
import '../models/dashboard_summary.dart';

class RecentPropertiesCard extends StatelessWidget {
  final List<RecentProperty> properties;
  final VoidCallback? onViewAll;
  final Function(RecentProperty)? onPropertyTap;
  final Future<PropertyModel?> Function(String id)? propertyDetailFuture;
  final VoidCallback? onFilterTap;
  final int activeFilterCount;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onNextPage;
  final VoidCallback? onPrevPage;

  const RecentPropertiesCard({
    super.key,
    required this.properties,
    this.onViewAll,
    this.onPropertyTap,
    this.propertyDetailFuture,
    this.onFilterTap,
    this.activeFilterCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onNextPage,
    this.onPrevPage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;

    return Container(
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
          // ── Card Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Recent Properties',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF14213D),
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (properties.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF243044)
                              : const Color(0xFFF1F4F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${properties.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF68738A),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onFilterTap != null)
                      InkWell(
                        onTap: onFilterTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: activeFilterCount > 0
                                ? ThemeManager().primaryColor.withValues(alpha: 0.15)
                                : (isDark
                                    ? const Color(0xFF243044)
                                    : const Color(0xFFF1F4F9)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: activeFilterCount > 0
                                  ? ThemeManager().primaryColor
                                  : (isDark
                                      ? const Color(0xFF334155)
                                      : Colors.transparent),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 14,
                                color: activeFilterCount > 0
                                    ? ThemeManager().primaryColor
                                    : (isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF68738A)),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                activeFilterCount > 0
                                    ? 'Filter ($activeFilterCount)'
                                    : 'Filter',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: activeFilterCount > 0
                                      ? ThemeManager().primaryColor
                                      : (isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF68738A)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: onViewAll ?? () => context.go('/properties'),
                      style: TextButton.styleFrom(
                        foregroundColor: ThemeManager().primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View All'),
                          SizedBox(width: 3),
                          Icon(Icons.arrow_forward_rounded, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
          ),

          if (properties.isNotEmpty) ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: properties.length.clamp(0, 5),
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
              ),
              itemBuilder: (context, index) {
                final prop = properties[index];
                return PropertyListItem(
                  property: prop,
                  detailFuture: propertyDetailFuture?.call(prop.id),
                  onTap: () =>
                      onPropertyTap?.call(prop) ??
                      context.go('/properties?openId=${prop.id}'),
                );
              },
            ),
            if (totalPages > 1) ...[
              Divider(
                height: 1,
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Page $currentPage of $totalPages',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF68738A),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            size: 18,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF68738A),
                          ),
                          onPressed: currentPage > 1 ? onPrevPage : null,
                          splashRadius: 16,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF68738A),
                          ),
                          onPressed: currentPage < totalPages
                              ? onNextPage
                              : null,
                          splashRadius: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.home_work_outlined,
                      size: 40,
                      color: const Color(0xFF68738A).withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No properties found',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF14213D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Properties matching the active filter will appear here.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF68738A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/properties'),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add Property'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ThemeManager().primaryColor,
                        side: BorderSide(color: ThemeManager().primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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

class PropertyListItem extends StatelessWidget {
  final RecentProperty property;
  final Future<PropertyModel?>? detailFuture;
  final VoidCallback? onTap;

  const PropertyListItem({
    super.key,
    required this.property,
    this.detailFuture,
    this.onTap,
  });

  String _formatPrice(double price, String type) {
    final isRent = type.toLowerCase() == 'rent';
    if (isRent) {
      final formatter = NumberFormat('#,##,###', 'en_IN');
      return '₹${formatter.format(price.toInt())} / mo';
    } else {
      if (price >= 10000000) {
        return '₹${(price / 10000000).toStringAsFixed(2)} Cr';
      } else if (price >= 100000) {
        return '₹${(price / 100000).toStringAsFixed(1)} L';
      } else {
        final formatter = NumberFormat('#,##,###', 'en_IN');
        return '₹${formatter.format(price.toInt())}';
      }
    }
  }

  String _timeAgo(String dateStr) {
    if (dateStr.isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return 'Recent';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRent = property.listingType.toLowerCase() == 'rent';

    if (detailFuture != null) {
      return FutureBuilder<PropertyModel?>(
        future: detailFuture,
        builder: (context, snapshot) {
          final fullProp = snapshot.data;
          final hasImage = fullProp != null && fullProp.images.isNotEmpty;
          final imageUrl = hasImage ? fullProp.images.first : '';
          final statusText = fullProp?.propertyStatusName ?? property.status;
          final isAvailable = statusText.toLowerCase() == 'available';

          // Collect specs
          final List<String> specs = [];
          if (fullProp != null && fullProp.bedrooms > 0) {
            specs.add('${fullProp.bedrooms} BHK');
          }
          if (fullProp != null && fullProp.bathrooms > 0) {
            specs.add('${fullProp.bathrooms} Bath');
          }
          if (fullProp?.superBuiltupArea != null &&
              fullProp!.superBuiltupArea! > 0) {
            specs.add('${fullProp.superBuiltupArea!.toInt()} sqft');
          } else if (fullProp?.carpetArea != null &&
              fullProp!.carpetArea! > 0) {
            specs.add('${fullProp.carpetArea!.toInt()} sqft');
          }

          return _buildContent(
            context,
            isRent: isRent,
            isAvailable: isAvailable,
            statusText: statusText,
            imageUrl: imageUrl,
            specsText: specs.join(' · '),
          );
        },
      );
    }

    final isAvailable = property.status.toLowerCase() == 'available';
    return _buildContent(
      context,
      isRent: isRent,
      isAvailable: isAvailable,
      statusText: property.status,
      imageUrl: '',
      specsText: '',
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required bool isRent,
    required bool isAvailable,
    required String statusText,
    required String imageUrl,
    required String specsText,
  }) {
    final isDark = ThemeManager().isDarkMode;

    return InkWell(
      onTap: onTap,
      hoverColor: isDark ? const Color(0xFF243044) : const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Property Thumbnail Image with Rent/Sale Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: isDark
                        ? const Color(0xFF243044)
                        : const Color(0xFFF1F4F9),
                    child: imageUrl.isNotEmpty
                        ? CrmNetworkImage(
                            url: imageUrl,
                            fit: BoxFit.cover,
                            cacheLogicalWidth: 64,
                            cacheLogicalHeight: 64,
                          )
                        : Center(
                            child: Icon(
                              Icons.apartment_rounded,
                              color: const Color(
                                0xFF68738A,
                              ).withValues(alpha: 0.5),
                              size: 26,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isRent
                          ? ThemeManager().primaryColor
                          : const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isRent ? 'RENT' : 'SALE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 14),

            // Middle Details: Name, Location, Spec
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFF14213D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (statusText.isNotEmpty && statusText != 'N/A')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? ThemeManager().primaryColor.withValues(alpha: 0.12)
                                : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: isAvailable
                                  ? ThemeManager().primaryColor
                                  : const Color(0xFFD97706),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF68738A),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          property.areaName,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF68738A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatPrice(property.price, property.listingType),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: ThemeManager().primaryColor,
                        ),
                      ),
                      if (specsText.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '·  $specsText',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF68738A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Text(
                        _timeAgo(property.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
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
