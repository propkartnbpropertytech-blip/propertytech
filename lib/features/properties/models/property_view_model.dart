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
    PropertyMetadataModel? metadata,
    String selectedPriceSortOrRange = 'all',
    double? minPrice,
    double? maxPrice,
    String searchQuery = '',
    bool myAddedOnly = false,
    String? currentUserId,
    String? currentUserName,
    String? currentUserEmail,
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
      } else if (f == 'fully furnished' || f.contains('full')) {
        normTargetFurnishing = 'fully furnished';
      } else {
        normTargetFurnishing = f;
      }
    }

    final isRentTab = activeListingTab == 'Rent';
    final lowerStatusFilter = selectedStatusFilter?.toLowerCase();

    // Pre-calculate selected area tokens ONCE outside the loop
    final bool hasAreaFilter = selectedAreas.isNotEmpty;
    final Set<String> targetAreaIds = hasAreaFilter ? selectedAreas : const {};
    final Set<String> targetAreaNamesLower = {};
    if (hasAreaFilter) {
      if (metadata != null && metadata.areas.isNotEmpty) {
        for (final area in metadata.areas) {
          if (targetAreaIds.contains(area.id) || targetAreaIds.contains(area.name)) {
            final nameClean = area.name.trim().toLowerCase();
            if (nameClean.isNotEmpty) {
              targetAreaNamesLower.add(nameClean);
            }
          }
        }
      }
      for (final id in targetAreaIds) {
        final idClean = id.trim().toLowerCase();
        if (idClean.isNotEmpty) {
          targetAreaNamesLower.add(idClean);
        }
      }
    }

    // Pre-calculate selected configuration / BHK tokens ONCE outside the loop
    final bool hasConfigFilter = selectedConfigurations.isNotEmpty;
    final Set<String> targetConfigIds = hasConfigFilter ? selectedConfigurations : const {};
    final Set<String> targetConfigNamesLower = {};
    if (hasConfigFilter) {
      if (metadata != null) {
        for (final cfg in metadata.configurations) {
          if (targetConfigIds.contains(cfg.id) || targetConfigIds.contains(cfg.name)) {
            final nameClean = cfg.name.trim().toLowerCase();
            if (nameClean.isNotEmpty) {
              targetConfigNamesLower.add(nameClean);
            }
          }
        }
        for (final t in metadata.types) {
          if (targetConfigIds.contains(t.id) || targetConfigIds.contains(t.name)) {
            final nameClean = t.name.trim().toLowerCase();
            if (nameClean.isNotEmpty) {
              targetConfigNamesLower.add(nameClean);
            }
          }
        }
      }
      for (final id in targetConfigIds) {
        final idClean = id.trim().toLowerCase();
        if (idClean.isNotEmpty) {
          targetConfigNamesLower.add(idClean);
        }
      }
    }

    final filtered = <PropertyListItemViewModel>[];
    final Set<String> seenPropertyIds = {};

    for (int i = 0; i < items.length; i++) {
      final vm = items[i];
      final p = vm.property;
      if (p.id.isNotEmpty && !seenPropertyIds.add(p.id)) {
        continue;
      }

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

      // 4. Area Filter
      if (hasAreaFilter) {
        bool matchesArea = false;
        // Direct ID match
        if (p.areaId.isNotEmpty && targetAreaIds.contains(p.areaId)) {
          matchesArea = true;
        }

        // Name, address, or landmark match
        if (!matchesArea && targetAreaNamesLower.isNotEmpty) {
          final pAreaLower = p.areaName.trim().toLowerCase();
          final pAddrLower = p.address.trim().toLowerCase();
          final pLandmarkLower = (p.landmark ?? '').trim().toLowerCase();

          for (final targetName in targetAreaNamesLower) {
            if (pAreaLower.isNotEmpty &&
                (pAreaLower == targetName ||
                    pAreaLower.contains(targetName) ||
                    targetName.contains(pAreaLower))) {
              matchesArea = true;
              break;
            }
            if (pAddrLower.isNotEmpty && pAddrLower.contains(targetName)) {
              matchesArea = true;
              break;
            }
            if (pLandmarkLower.isNotEmpty && pLandmarkLower.contains(targetName)) {
              matchesArea = true;
              break;
            }
          }
        }

        if (!matchesArea) continue;
      }

      // 4. Configuration filter
      if (hasConfigFilter) {
        bool matchesConfig = false;
        if ((p.configurationId != null && p.configurationId!.isNotEmpty && targetConfigIds.contains(p.configurationId)) ||
            (p.propertyTypeId.isNotEmpty && targetConfigIds.contains(p.propertyTypeId))) {
          matchesConfig = true;
        } else if (targetConfigNamesLower.isNotEmpty) {
          final pTypeLower = p.propertyTypeName.trim().toLowerCase();
          final pCfgLower = (p.configurationName ?? '').trim().toLowerCase();
          for (final targetName in targetConfigNamesLower) {
            if (pTypeLower.isNotEmpty &&
                (pTypeLower == targetName ||
                    pTypeLower.contains(targetName) ||
                    targetName.contains(pTypeLower))) {
              matchesConfig = true;
              break;
            }
            if (pCfgLower.isNotEmpty &&
                (pCfgLower == targetName ||
                    pCfgLower.contains(targetName) ||
                    targetName.contains(pCfgLower))) {
              matchesConfig = true;
              break;
            }
            if (targetName.startsWith('1') && (p.bedrooms == 1 || pCfgLower.contains('1'))) {
              matchesConfig = true;
              break;
            }
            if (targetName.startsWith('2') && (p.bedrooms == 2 || pCfgLower.contains('2'))) {
              matchesConfig = true;
              break;
            }
            if (targetName.startsWith('3') && (p.bedrooms == 3 || pCfgLower.contains('3'))) {
              matchesConfig = true;
              break;
            }
            if (targetName.startsWith('4') && (p.bedrooms == 4 || pCfgLower.contains('4'))) {
              matchesConfig = true;
              break;
            }
            if (targetName.startsWith('5') && (p.bedrooms >= 5 || pCfgLower.contains('5'))) {
              matchesConfig = true;
              break;
            }
          }
        }
        if (!matchesConfig) continue;
      }

      // 5. Price filter
      if (selectedPriceSortOrRange == 'custom') {
        if (minPrice != null && vm.price < minPrice) continue;
        if (maxPrice != null && vm.price > maxPrice) continue;
      }

      // 6. My Added filter
      if (myAddedOnly) {
        final uid = (currentUserId ?? '').trim().toLowerCase();
        final uname = (currentUserName ?? '').trim().toLowerCase();
        final uemail = (currentUserEmail ?? '').trim().toLowerCase();

        final pCreatedBy = p.createdBy.trim().toLowerCase();
        final pCreatedByName = p.createdByName.trim().toLowerCase();

        bool isMine = false;
        if (uid.isNotEmpty && pCreatedBy.isNotEmpty && pCreatedBy == uid) {
          isMine = true;
        } else if (uname.isNotEmpty && pCreatedByName.isNotEmpty && pCreatedByName == uname) {
          isMine = true;
        } else if (uemail.isNotEmpty) {
          if (pCreatedBy.isNotEmpty && pCreatedBy == uemail) {
            isMine = true;
          } else if (pCreatedByName.isNotEmpty && pCreatedByName == uemail) {
            isMine = true;
          }
        }

        if (!isMine) continue;
      }

      // 7. Archive filter
      final isArchived = archivedPropertyIds.contains(p.id);
      if (archiveTabOnly ? !isArchived : isArchived) continue;

      // 8. Status filter
      if (lowerStatusFilter != null && p.propertyStatusName.toLowerCase() != lowerStatusFilter) {
        continue;
      }

      // 9. BHK filter
      if (activeBhkFilter != null && activeBhkFilter != 'All BHK' && activeBhkFilter != 'All') {
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
