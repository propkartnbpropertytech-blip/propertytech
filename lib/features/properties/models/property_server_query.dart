import 'property_view_model.dart';

class PropertyServerQuery {
  static Map<String, String> parameters({
    String? categoryId,
    List<String> configurationIds = const [],
    List<String> areaIds = const [],
    String? listingTab,
    double? minPrice,
    double? maxPrice,
    String? statusName,
    String? furnishingName,
    String? bhkLabel,
    String? imageFilter,
    bool noImagesOnly = false,
    PropertyDateFilterPreset datePreset = PropertyDateFilterPreset.allTime,
    DateTime? customStart,
    DateTime? customEnd,
    String? sort,
    String? createdBy,
    DateTime? now,
  }) {
    final params = <String, String>{};
    if (categoryId != null && categoryId.isNotEmpty) params['categoryId'] = categoryId;
    if (configurationIds.isNotEmpty) params['configurationIds'] = configurationIds.join(',');
    if (areaIds.isNotEmpty) params['areaIds'] = areaIds.join(',');
    final listing = (listingTab ?? '').toLowerCase();
    if (listing.contains('rent')) {
      params['listingName'] = 'rent';
    } else if (listing.contains('sale')) {
      params['listingName'] = 'resale';
    }
    if (minPrice != null) params['minPrice'] = minPrice.toString();
    if (maxPrice != null) params['maxPrice'] = maxPrice.toString();
    if (statusName != null && statusName.isNotEmpty && statusName.toLowerCase() != 'all') {
      params['statusName'] = statusName;
    }
    if (furnishingName != null &&
        furnishingName.isNotEmpty &&
        !furnishingName.toLowerCase().startsWith('all')) {
      params['furnishingName'] = furnishingName;
    }
    final bhk = int.tryParse((bhkLabel ?? '').replaceAll(RegExp(r'[^0-9]'), ''));
    if (bhk != null && bhk > 0) params['bhk'] = '$bhk';
    if (imageFilter == 'with_images') params['hasImages'] = 'true';
    if (imageFilter == 'no_images' || noImagesOnly) params['hasImages'] = 'false';
    final range = _dateRange(datePreset, customStart, customEnd, now ?? DateTime.now());
    if (range != null) {
      params['dateFrom'] = range.$1.toUtc().toIso8601String();
      params['dateTo'] = range.$2.toUtc().toIso8601String();
    }
    if (sort == 'l2h' || sort == 'low_to_high') params['sort'] = 'price_asc';
    if (sort == 'h2l' || sort == 'high_to_low') params['sort'] = 'price_desc';
    if (createdBy != null && createdBy.isNotEmpty) params['createdBy'] = createdBy;
    return params;
  }

  static (DateTime, DateTime)? _dateRange(
    PropertyDateFilterPreset preset,
    DateTime? customStart,
    DateTime? customEnd,
    DateTime now,
  ) {
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    switch (preset) {
      case PropertyDateFilterPreset.today:
        return (todayStart, todayEnd);
      case PropertyDateFilterPreset.yesterday:
        final start = todayStart.subtract(const Duration(days: 1));
        return (start, DateTime(start.year, start.month, start.day, 23, 59, 59, 999));
      case PropertyDateFilterPreset.last7Days:
        return (todayStart.subtract(const Duration(days: 6)), todayEnd);
      case PropertyDateFilterPreset.thisMonth:
        return (DateTime(now.year, now.month, 1), todayEnd);
      case PropertyDateFilterPreset.customRange:
        if (customStart == null || customEnd == null) return null;
        return (
          DateTime(customStart.year, customStart.month, customStart.day),
          DateTime(customEnd.year, customEnd.month, customEnd.day, 23, 59, 59, 999),
        );
      case PropertyDateFilterPreset.allTime:
        return null;
    }
  }
}
