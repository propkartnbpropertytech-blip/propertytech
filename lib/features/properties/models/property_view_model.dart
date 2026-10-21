import 'package:intl/intl.dart';
import '../models/property_model.dart';
import '../../../core/utils/currency.dart';
import '../../../core/network/crm_image_delivery.dart';

enum PropertyDateFilterPreset {
  today,
  yesterday,
  last7Days,
  thisMonth,
  customRange,
  allTime,
}

/// Pre-computed, immutable view model for a Property in lists and cards.
/// Eliminates repeated string lowercasing, regex splitting, date parsing,
/// and metadata lookups during build passes.
class PropertyListItemViewModel {
  final PropertyModel property;
  final String propertyTitle;
  final String addressText;
  final String bhkText;
  final String rawPriceFormatted;
  final String priceText;
  final String formattedDateText;
  final bool isCommercialOrLand;
  final bool isRent;
  final bool hasMedia;
  final String furnishingName;
  final String normalizedFurnishing; // 'unfurnished', 'semi furnished', 'fully furnished', or other
  final String categoryNameLower;
  final bool isResidential;
  final bool isCommercial;
  final bool isIndustrial;
  final bool isLandPlot;
  final String propertyCodeLower;
  final String propertyCodeClean; // Without hyphens
  final String normalizedSearchTokens; // Pre-lowercased, space-separated searchable string
  final DateTime createdAtLocal;
  final int createdAtMillis;
  final double price;
  final String optimizedThumbnailUrl;

  const PropertyListItemViewModel({
    required this.property,
    required this.propertyTitle,
    required this.addressText,
    required this.bhkText,
    required this.rawPriceFormatted,
    required this.priceText,
    required this.formattedDateText,
    required this.isCommercialOrLand,
    required this.isRent,
    required this.hasMedia,
    required this.furnishingName,
    required this.normalizedFurnishing,
    required this.categoryNameLower,
    required this.isResidential,
    required this.isCommercial,
    required this.isIndustrial,
    required this.isLandPlot,
    required this.propertyCodeLower,
    required this.propertyCodeClean,
    required this.normalizedSearchTokens,
    required this.createdAtLocal,
    required this.createdAtMillis,
    required this.price,
    this.optimizedThumbnailUrl = '',
  });

  factory PropertyListItemViewModel.fromProperty(
    PropertyModel p,
    PropertyMetadataModel? metadata, {
    DateTime? relativeNow,
  }) {
    final catLower = p.categoryName.toLowerCase();
    final isCommOrLand = catLower.contains('commercial') ||
        catLower.contains('industrial') ||
        catLower.contains('land') ||
        catLower.contains('plot');

    final bhk = isCommOrLand
        ? ((p.propertyTypeName.isNotEmpty && p.propertyTypeName != 'N/A')
            ? p.propertyTypeName
            : p.categoryName)
        : (p.configurationName ?? "${p.bedrooms} BHK");

    final title = "$bhk ${p.listingTypeName} in ${p.areaName}";
    final address = p.title.isNotEmpty ? p.title : p.areaName;
    final rent = p.listingTypeName.toLowerCase().contains('rent');
    final formattedPrice = CRMCurrencyFormatter.formatShort(p.price);
    final displayPrice = formattedPrice.startsWith('₹') ? formattedPrice : "₹ $formattedPrice";
    final media = p.images.isNotEmpty || p.videos.isNotEmpty;

    // Relative date formatting
    final now = relativeNow ?? DateTime.now();
    final localCreated = p.createdAt.toLocal();
    final diff = now.difference(p.createdAt);
    String dateStr;
    if (diff.inHours < 24 && !diff.isNegative) {
      if (diff.inMinutes < 1) {
        dateStr = "Just now";
      } else if (diff.inHours < 1) {
        dateStr = "${diff.inMinutes} mins ago";
      } else {
        dateStr = "${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago";
      }
    } else {
      dateStr = DateFormat('dd-MM-yyyy hh:mm a').format(p.createdAt);
    }

    // Resolve furnishing name from metadata if empty
    String fName = p.furnishingTypeName ?? '';
    if (fName.trim().isEmpty && metadata != null && p.furnishingTypeId != null) {
      try {
        final item = metadata.furnishings.firstWhere(
          (f) => f.id == p.furnishingTypeId,
          orElse: () => LookupItem(id: '', name: ''),
        );
        if (item.name.isNotEmpty) {
          fName = item.name;
        }
      } catch (_) {}
    }
    final lowerFName = fName.trim().toLowerCase().replaceAll('-', ' ');
    String normFurnishing = '';
    if (lowerFName.contains('unfurnish')) {
      normFurnishing = 'unfurnished';
    } else if (lowerFName.contains('semi')) {
      normFurnishing = 'semi furnished';
    } else if (lowerFName.contains('full') ||
        (lowerFName.contains('furnish') && !lowerFName.contains('un') && !lowerFName.contains('semi'))) {
      normFurnishing = 'fully furnished';
    } else {
      normFurnishing = lowerFName;
    }

    // Pre-calculate category booleans
    final isRes = catLower.contains('resident') ||
        catLower.contains('apartment') ||
        catLower.contains('flat') ||
        catLower.contains('villa') ||
        catLower.contains('house') ||
        catLower.contains('bhk') ||
        (!catLower.contains('commercial') &&
            !catLower.contains('industrial') &&
            !catLower.contains('land') &&
            !catLower.contains('plot'));
    final isComm = catLower.contains('commercial') ||
        catLower.contains('office') ||
        catLower.contains('shop') ||
        catLower.contains('showroom') ||
        catLower.contains('retail');
    final isInd = catLower.contains('industrial') ||
        catLower.contains('factory') ||
        catLower.contains('warehouse') ||
        catLower.contains('shed');
    final isLnd = catLower.contains('land') || catLower.contains('plot');

    final codeLower = p.propertyCode.toLowerCase();
    final codeClean = codeLower.replaceAll('-', '');

    // Pre-compute unified lowercase search tokens
    final searchTokensBuffer = StringBuffer()
      ..write(codeLower)..write(' ')
      ..write(p.title.toLowerCase())..write(' ')
      ..write(p.description?.toLowerCase() ?? '')..write(' ')
      ..write(p.ownerName.toLowerCase())..write(' ')
      ..write(p.ownerMobile.toLowerCase())..write(' ')
      ..write(p.areaName.toLowerCase())..write(' ')
      ..write(p.cityName.toLowerCase())..write(' ')
      ..write(catLower)..write(' ')
      ..write(p.configurationName?.toLowerCase() ?? '')..write(' ')
      ..write(p.propertyTypeName.toLowerCase())..write(' ');
    if (p.showsAddedBy) {
      searchTokensBuffer.write(p.createdByName.toLowerCase());
    }

    final rawThumbnail = p.images.isNotEmpty ? p.images.first : '';
    final optThumbnail = rawThumbnail.isNotEmpty
        ? CrmImageDelivery.transformUrl(rawThumbnail, variant: CrmImageVariant.thumbnail)
        : '';

    return PropertyListItemViewModel(
      property: p,
      propertyTitle: title,
      addressText: address,
      bhkText: bhk,
      rawPriceFormatted: formattedPrice,
      priceText: displayPrice,
      formattedDateText: dateStr,
      isCommercialOrLand: isCommOrLand,
      isRent: rent,
      hasMedia: media,
      furnishingName: fName,
      normalizedFurnishing: normFurnishing,
      categoryNameLower: catLower,
      isResidential: isRes,
      isCommercial: isComm,
      isIndustrial: isInd,
      isLandPlot: isLnd,
      propertyCodeLower: codeLower,
      propertyCodeClean: codeClean,
      normalizedSearchTokens: searchTokensBuffer.toString(),
      createdAtLocal: localCreated,
      createdAtMillis: p.createdAt.millisecondsSinceEpoch,
      price: p.price,
      optimizedThumbnailUrl: optThumbnail,
    );
  }
}

/// Standalone filter and sorting pipeline for Property records.
/// Executes completely outside of widget build() methods.
class PropertyFilterEngine {
  static List<PropertyListItemViewModel> filterAndSort({
    required List<PropertyListItemViewModel> items,
    required String activeListingTab,
    String? selectedCategory,
    String activeCategoryTab = 'All',
    Set<String> selectedConfigurations = const {},
    Set<String> selectedAreas = const {},
    String selectedPriceSortOrRange = 'all',
    double? minPrice,
    double? maxPrice,
    String searchQuery = '',
    bool myAddedOnly = false,
    String? currentUserId,
    bool archiveTabOnly = false,
    Set<String> archivedPropertyIds = const {},
    String? selectedStatusFilter,
    String? activeBhkFilter,
    String? selectedFurnishingFilter,
    String imageFilter = 'all',
    bool noImagesOnly = false,
    PropertyDateFilterPreset datePreset = PropertyDateFilterPreset.allTime,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    if (items.isEmpty) return const [];

    // Pre-calculate date boundaries ONCE outside the loop
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final yestStart = todayStart.subtract(const Duration(days: 1));
    final yestEnd = DateTime(yestStart.year, yestStart.month, yestStart.day, 23, 59, 59, 999);
    final last7Start = todayStart.subtract(const Duration(days: 6));
    final monthStart = DateTime(now.year, now.month, 1);

    DateTime? customStart;
    DateTime? customEnd;
    if (datePreset == PropertyDateFilterPreset.customRange &&
        customStartDate != null &&
        customEndDate != null) {
      customStart = DateTime(customStartDate.year, customStartDate.month, customStartDate.day);
      customEnd = DateTime(customEndDate.year, customEndDate.month, customEndDate.day, 23, 59, 59, 999);
    }

    // Pre-parse search tokens ONCE outside the loop
    final trimmedQuery = searchQuery.trim().toLowerCase();
    final List<String> searchWords = trimmedQuery.isEmpty
        ? const []
        : trimmedQuery.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final bool hasSearch = searchWords.isNotEmpty;

    // Pre-normalize furnishing filter
    String? normTargetFurnishing;
    if (selectedFurnishingFilter != null &&
        selectedFurnishingFilter.trim().isNotEmpty &&
        selectedFurnishingFilter.toLowerCase() != 'all' &&
        selectedFurnishingFilter.toLowerCase() != 'all furnished') {
      final f = selectedFurnishingFilter.trim().toLowerCase().replaceAll('-', ' ');
      if (f == 'unfurnished' || f.contains('unfurnish')) {
        normTargetFurnishing = 'unfurnished';
      } else if (f == 'semi furnished' || f.contains('semi')) {
        normTargetFurnishing = 'semi furnished';
      } else if (f == 'fully furnished' ||
          f.contains('full') ||
          (f.contains('furnish') && !f.contains('un') && !f.contains('semi'))) {
        normTargetFurnishing = 'fully furnished';
      } else {
        normTargetFurnishing = f;
      }
    }

    final isRentTab = activeListingTab == 'Rent';
    final lowerStatusFilter = selectedStatusFilter?.toLowerCase();

    final filtered = <PropertyListItemViewModel>[];

    for (int i = 0; i < items.length; i++) {
      final vm = items[i];
      final p = vm.property;

      // 1. Listing tab (Rent vs Re-Sale)
      final ltName = p.listingTypeName.toLowerCase();
      final matchesListing = isRentTab
          ? ltName.contains('rent')
          : (ltName.contains('sale') || ltName.contains('resale') || !ltName.contains('rent'));
      if (!matchesListing) continue;

      // 2. Category Dropdown
      if (selectedCategory != null && p.categoryId != selectedCategory) {
        continue;
      }

      // 3. Category Tab
      bool matchesCategoryTab = true;
      if (activeCategoryTab == 'Residential') {
        matchesCategoryTab = vm.isResidential;
      } else if (activeCategoryTab == 'Commercial') {
        matchesCategoryTab = vm.isCommercial;
      } else if (activeCategoryTab == 'Industrial') {
        matchesCategoryTab = vm.isIndustrial;
      } else if (activeCategoryTab == 'Land & Plot') {
        matchesCategoryTab = vm.isLandPlot;
      }
      if (!matchesCategoryTab) continue;

      // 4. Configuration filter
      if (selectedConfigurations.isNotEmpty) {
        bool matchesConfig = false;
        for (final id in selectedConfigurations) {
          if (p.configurationId == id || p.propertyTypeId == id) {
            matchesConfig = true;
            break;
          }
          final idLower = id.toLowerCase();
          final pTypeLower = p.propertyTypeName.toLowerCase();
          final pCfgLower = (p.configurationName ?? '').toLowerCase();
          if (pTypeLower.isNotEmpty && (pTypeLower == idLower || pTypeLower.contains(idLower))) {
            matchesConfig = true;
            break;
          }
          if (pCfgLower.isNotEmpty && (pCfgLower == idLower || pCfgLower.contains(idLower))) {
            matchesConfig = true;
            break;
          }
        }
        if (!matchesConfig) continue;
      }

      // 4b. Area filter
      if (selectedAreas.isNotEmpty) {
        final pAreaId = p.areaId.toLowerCase();
        final pAreaName = p.areaName.toLowerCase();
        final matchesArea = selectedAreas.any((a) {
          final aLower = a.toLowerCase();
          return (pAreaId.isNotEmpty && pAreaId == aLower) ||
              (pAreaName.isNotEmpty && (pAreaName == aLower || pAreaName.contains(aLower)));
        });
        if (!matchesArea) continue;
      }

      // 5. Price filter
      if (selectedPriceSortOrRange == 'custom') {
        if (minPrice != null && vm.price < minPrice) continue;
        if (maxPrice != null && vm.price > maxPrice) continue;
      }

      // 6. My Added filter
      if (myAddedOnly && p.createdBy != currentUserId) continue;

      // 7. Archive filter
      final isArchived = archivedPropertyIds.contains(p.id);
      if (archiveTabOnly ? !isArchived : isArchived) continue;

      // 8. Status filter
      if (lowerStatusFilter != null && p.propertyStatusName.toLowerCase() != lowerStatusFilter) {
        continue;
      }

      // 9. BHK filter
      if (activeBhkFilter != null && activeBhkFilter != 'All BHK') {
        bool matchesBhk = true;
        if (activeBhkFilter == '1 BHK') {
          matchesBhk = p.bedrooms == 1 || (p.configurationName?.contains('1') ?? false);
        } else if (activeBhkFilter == '2 BHK') {
          matchesBhk = p.bedrooms == 2 || (p.configurationName?.contains('2') ?? false);
        } else if (activeBhkFilter == '3 BHK') {
          matchesBhk = p.bedrooms == 3 || (p.configurationName?.contains('3') ?? false);
        } else if (activeBhkFilter == '4 BHK') {
          matchesBhk = p.bedrooms == 4 || (p.configurationName?.contains('4') ?? false);
        } else if (activeBhkFilter == '5+ BHK') {
          matchesBhk = p.bedrooms >= 5 || (p.configurationName?.contains('5') ?? false);
        }
        if (!matchesBhk) continue;
      }

      // 10. Furnishing filter
      if (normTargetFurnishing != null) {
        if (vm.normalizedFurnishing.isEmpty) continue;
        if (normTargetFurnishing == 'unfurnished') {
          if (!vm.normalizedFurnishing.contains('unfurnish')) continue;
        } else if (normTargetFurnishing == 'semi furnished') {
          if (!vm.normalizedFurnishing.contains('semi')) continue;
        } else if (normTargetFurnishing == 'fully furnished') {
          if (!vm.normalizedFurnishing.contains('full') &&
              (!vm.normalizedFurnishing.contains('furnish') || vm.normalizedFurnishing.contains('un') || vm.normalizedFurnishing.contains('semi'))) {
            continue;
          }
        } else if (vm.normalizedFurnishing != normTargetFurnishing) {
          continue;
        }
      }

      // 11. Image filter
      if (imageFilter == 'with_images') {
        if (p.images.isEmpty) continue;
      } else if (imageFilter == 'no_images' || noImagesOnly) {
        if (p.images.isNotEmpty) continue;
      }

      // 12. Search filter
      bool isDirectMatch = false;
      if (hasSearch) {
        bool allWordsMatch = true;
        for (int w = 0; w < searchWords.length; w++) {
          final word = searchWords[w];
          if (!vm.normalizedSearchTokens.contains(word)) {
            allWordsMatch = false;
            break;
          }
        }
        if (!allWordsMatch) continue;

        for (int w = 0; w < searchWords.length; w++) {
          final word = searchWords[w];
          if (vm.propertyCodeLower == word ||
              (word.startsWith('pr') && vm.propertyCodeClean == word.replaceAll('-', ''))) {
            isDirectMatch = true;
            break;
          }
        }
      }

      // 13. Date filter
      final dt = vm.createdAtLocal;
      bool matchesDate = true;
      switch (datePreset) {
        case PropertyDateFilterPreset.today:
          matchesDate = !dt.isBefore(todayStart) && !dt.isAfter(todayEnd);
          break;
        case PropertyDateFilterPreset.yesterday:
          matchesDate = !dt.isBefore(yestStart) && !dt.isAfter(yestEnd);
          break;
        case PropertyDateFilterPreset.last7Days:
          matchesDate = !dt.isBefore(last7Start) && !dt.isAfter(todayEnd);
          break;
        case PropertyDateFilterPreset.thisMonth:
          matchesDate = !dt.isBefore(monthStart) && !dt.isAfter(todayEnd);
          break;
        case PropertyDateFilterPreset.customRange:
          if (customStart != null && customEnd != null) {
            matchesDate = !dt.isBefore(customStart) && !dt.isAfter(customEnd);
          }
          break;
        case PropertyDateFilterPreset.allTime:
          matchesDate = true;
          break;
      }

      if (isDirectMatch && hasSearch) {
        filtered.add(vm);
      } else if (matchesDate) {
        filtered.add(vm);
      }
    }

    // Sort: Default is newest first (latest createdAtMillis)
    if (selectedPriceSortOrRange == 'l2h' || selectedPriceSortOrRange == 'low_to_high') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (selectedPriceSortOrRange == 'h2l' || selectedPriceSortOrRange == 'high_to_low') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    } else {
      filtered.sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
    }

    return filtered;
  }
}
