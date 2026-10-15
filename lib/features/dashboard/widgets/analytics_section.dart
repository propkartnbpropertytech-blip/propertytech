import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/dashboard_summary.dart';
import '../models/kpi_models.dart';

/// Reusable utility functions for matching properties and leads against main dashboard filters
class DashboardFilterUtils {
  static bool matchesBusiness(String listingType, KpiFilterParams filters) {
    final bt = filters.businessType.trim().toLowerCase();
    final lt = listingType.trim().toLowerCase();
    final isResale = lt.contains('sale') || lt.contains('resale');
    final isRent = !isResale;
    if (bt == 'rent') {
      return isRent;
    }
    if (bt == 're-sale' || bt == 'resale' || bt == 'sale') {
      return isResale;
    }
    return true; // 'Both'
  }

  static bool matchesDate(DateTime? dt, KpiFilterParams filters) {
    if (dt == null) return true;
    final filter = filters.dateFilter.trim().toLowerCase();
    if (filter == 'all' ||
        filter == 'all time' ||
        filter == 'all-time' ||
        filter.isEmpty) {
      return true;
    }
    final localDt = dt.toLocal();
    final now = DateTime.now();

    if (filter == 'today') {
      return localDt.year == now.year &&
          localDt.month == now.month &&
          localDt.day == now.day;
    }
    if (filter == 'weekly') {
      final start = now.subtract(const Duration(days: 7));
      return localDt.isAfter(start) || localDt.isAtSameMomentAs(start);
    }
    if (filter == 'monthly') {
      final start = now.subtract(const Duration(days: 30));
      return localDt.isAfter(start) || localDt.isAtSameMomentAs(start);
    }
    if (filter == 'yearly') {
      final start = now.subtract(const Duration(days: 365));
      return localDt.isAfter(start) || localDt.isAtSameMomentAs(start);
    }
    if (filter.startsWith('custom')) {
      if (filters.startDate != null && filters.endDate != null) {
        final s = DateTime.tryParse(filters.startDate!);
        final e = DateTime.tryParse(filters.endDate!);
        if (s != null && e != null) {
          final start = DateTime(s.year, s.month, s.day);
          final end = DateTime(e.year, e.month, e.day, 23, 59, 59, 999);
          return (localDt.isAfter(start) || localDt.isAtSameMomentAs(start)) &&
              (localDt.isBefore(end) || localDt.isAtSameMomentAs(end));
        }
      }
    }
    return true;
  }

  static bool matchesCategory(String categoryName, String categoryTarget) {
    if (categoryTarget == 'All') return true;
    final cat = categoryName.trim().toLowerCase();
    if (categoryTarget == 'Residential') return cat.contains('residen');
    if (categoryTarget == 'Commercial') return cat.contains('commerc');
    if (categoryTarget == 'Industrial') return cat.contains('indust');
    if (categoryTarget == 'Land & Plot') {
      return cat.contains('land') || cat.contains('plot');
    }
    return true;
  }
}

/// Formatter for prices in Indian numbering format
String formatPrice(double price, bool isRent) {
  if (price <= 0) return 'Price on Request';
  if (isRent) {
    if (price >= 100000) {
      return '₹${(price / 100000).toStringAsFixed(1)}L/mo';
    }
    return '₹${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'), (m) => '${m[1]},')}/mo';
  } else {
    if (price >= 10000000) {
      return '₹${(price / 10000000).toStringAsFixed(2)} Cr';
    }
    if (price >= 100000) {
      return '₹${(price / 100000).toStringAsFixed(2)} L';
    }
    return '₹${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'), (m) => '${m[1]},')}';
  }
}

/// Normalizes city names for uniform grouping and display
String normalizeCityName(String? rawCity) {
  if (rawCity == null) return 'Ahmedabad';
  final trimmed = rawCity.trim();
  if (trimmed.isEmpty) return 'Ahmedabad';
  final lower = trimmed.toLowerCase().replaceAll(' ', '');
  if (lower.contains('ahmedabad')) return 'Ahmedabad';
  if (lower.contains('gandhinagar')) return 'Gandhinagar';
  if (lower.contains('surat')) return 'Surat';
  if (lower.contains('rajkot')) return 'Rajkot';
  if (lower.contains('bhavnagar')) return 'Bhavnagar';
  if (lower.contains('vadodara')) return 'Vadodara';
  if (lower.contains('jamnagar')) return 'Jamnagar';
  return trimmed;
}

/// Modern Analytics Section
/// 1. Rent & Re-sale Overview (Available Property and Lead counts with modern visual Pie / Donut Chart)
/// 2. City -> Area Analytics (Dynamic city tabs, all areas displayed separately with accurate counts)
class AnalyticsSection extends StatefulWidget {
  final DashboardData? data;
  final KpiFilterParams kpiFilters;
  final DashboardKpisResponse? kpis;
  final bool isRent;
  final Function(String)? onPropertyTap;

  const AnalyticsSection({
    super.key,
    this.data,
    this.kpiFilters = const KpiFilterParams(),
    this.kpis,
    this.isRent = false,
    this.onPropertyTap,
  });

  @override
  State<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<AnalyticsSection> {
  String _selectedCity = 'Ahmedabad';
  String _areaSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _areaScrollController = ScrollController();
  int? _hoveredPieSegmentIndex;
  String? _selectedBreakdownMetricKey;
  String? _mobileActiveBreakdownKey;
  String? _expandedCategory;

  // City & Area Analytics Controls State
  String _activeAreaViewType = 'properties'; // 'properties' | 'requirements'
  String _areaRequirementFilter = 'All'; // 'All', '1 BHK', '2 BHK', '3 BHK', '4 BHK+', 'Commercial', 'Plot / Land', 'Others'
  String _areaBudgetFilter = 'All';
  String _areaListingTypeFilter = 'Both'; // 'Both', 'Rent', 'Re-Sale'

  @override
  void initState() {
    super.initState();
    final bt = widget.kpiFilters.businessType.trim().toLowerCase();
    if (bt == 'rent') {
      _areaListingTypeFilter = 'Rent';
    } else if (bt == 're-sale' || bt == 'resale' || bt == 'sale') {
      _areaListingTypeFilter = 'Re-Sale';
    } else {
      _areaListingTypeFilter = 'Both';
    }
  }

  bool _matchesBudget(double price, String filter) {
    if (filter == 'All') return true;
    if (price <= 0) return false;
    switch (filter) {
      case 'Under ₹25K':
        return price <= 25000;
      case '₹25K - ₹50K':
        return price >= 25000 && price <= 50000;
      case '₹50K - ₹1L':
        return price >= 50000 && price <= 100000;
      case 'Above ₹1L':
        return price >= 100000;
      case 'Under ₹30K':
        return price <= 30000;
      case '₹30K - ₹1L':
        return price >= 30000 && price <= 100000;
      case '₹1L - ₹50L':
        return price >= 100000 && price <= 5000000;
      case 'Under ₹50L':
        return price <= 5000000;
      case '₹50L - ₹1 Cr':
        return price >= 5000000 && price <= 10000000;
      case '₹50L - ₹1.5 Cr':
        return price >= 5000000 && price <= 15000000;
      case '₹1 Cr - ₹2.5 Cr':
        return price >= 10000000 && price <= 25000000;
      case 'Above ₹1.5 Cr':
        return price >= 15000000;
      case 'Above ₹2.5 Cr':
        return price >= 25000000;
      default:
        return true;
    }
  }

  bool _matchesRequirement(DashboardLocationItem item, String reqFilter) {
    if (reqFilter == 'All') return true;
    final cls = _classifyItem(item);
    if (cls.toLowerCase() == reqFilter.toLowerCase()) return true;
    final config = item.configurationName.toLowerCase();
    final type = item.propertyTypeName.toLowerCase();
    final cat = item.categoryName.toLowerCase();
    final f = reqFilter.toLowerCase();
    if (f == 'commercial') {
      return cat.contains('commerc') || type.contains('commerc') || cls == 'Commercial';
    }
    if (f == 'plot / land' || f == 'land & plot') {
      return cat.contains('land') || cat.contains('plot') || type.contains('land') || type.contains('plot');
    }
    if (f == '1 bhk') {
      return config.contains('1 bhk') || config.contains('1bhk') || cls == '1 BHK';
    }
    if (f == '2 bhk') {
      return config.contains('2 bhk') || config.contains('2bhk') || cls == '2 BHK';
    }
    if (f == '3 bhk') {
      return config.contains('3 bhk') || config.contains('3bhk') || cls == '3 BHK';
    }
    if (f == '4 bhk+') {
      return config.contains('4 bhk') || config.contains('4bhk') || config.contains('5') || cls == '4 BHK+';
    }
    if (f == 'others') {
      return cls == 'Others';
    }
    return false;
  }

  bool _matchesListingType(DashboardLocationItem item, String filter) {
    if (filter == 'Both') return true;
    if (filter == 'Rent') return item.isRent;
    if (filter == 'Re-Sale') return item.isResale;
    return true;
  }

  bool _itemMatchesSearch(DashboardLocationItem item, String q) {
    if (q.isEmpty) return true;
    if (item.areaName.toLowerCase().contains(q)) return true;
    if (item.title.toLowerCase().contains(q)) return true;
    if (item.code.toLowerCase().contains(q)) return true;
    if (item.categoryName.toLowerCase().contains(q)) return true;
    if (item.propertyTypeName.toLowerCase().contains(q)) return true;
    if (item.configurationName.toLowerCase().contains(q)) return true;
    return false;
  }

  List<String> _getBudgetOptions(String effectiveType) {
    if (effectiveType == 'Rent') {
      return const ['All', 'Under ₹25K', '₹25K - ₹50K', '₹50K - ₹1L', 'Above ₹1L'];
    } else if (effectiveType == 'Re-Sale') {
      return const ['All', 'Under ₹50L', '₹50L - ₹1 Cr', '₹1 Cr - ₹2.5 Cr', 'Above ₹2.5 Cr'];
    } else {
      return const ['All', 'Under ₹30K', '₹30K - ₹1L', '₹1L - ₹50L', '₹50L - ₹1.5 Cr', 'Above ₹1.5 Cr'];
    }
  }

  String _classifyItem(DashboardLocationItem item) {
    final cat = item.categoryName.trim().toLowerCase();
    final type = item.propertyTypeName.trim().toLowerCase();
    final config = item.configurationName.trim().toLowerCase();
    final title = item.title.trim().toLowerCase();

    // 1. Commercial / Office / Shop / Showroom
    if (cat.contains('commerc') ||
        cat.contains('office') ||
        cat.contains('shop') ||
        cat.contains('retail') ||
        cat.contains('showroom') ||
        type.contains('commerc') ||
        type.contains('office') ||
        type.contains('shop') ||
        title.contains('commercial') ||
        title.contains('office') ||
        title.contains('shop')) {
      return 'Commercial';
    }

    // 2. Exact bedroom count
    if (item.bedrooms == 1) return '1 BHK';
    if (item.bedrooms == 2) return '2 BHK';
    if (item.bedrooms == 3) return '3 BHK';
    if (item.bedrooms >= 4) return '4 BHK+';

    // 3. Configuration name
    if (config.isNotEmpty) {
      if (config.contains('1') && (config.contains('bhk') || config.contains('rk'))) return '1 BHK';
      if (config.contains('2') && config.contains('bhk')) return '2 BHK';
      if (config.contains('3') && config.contains('bhk')) return '3 BHK';
      if ((config.contains('4') || config.contains('5') || config.contains('6')) && config.contains('bhk')) return '4 BHK+';
    }

    // 4. Title / Regex pattern matching
    final bhkMatch = RegExp(r'(\d+)\s*(?:bhk|bedroom|bed|rk)', caseSensitive: false).firstMatch(title);
    if (bhkMatch != null) {
      final num = int.tryParse(bhkMatch.group(1) ?? '0') ?? 0;
      if (num == 1) return '1 BHK';
      if (num == 2) return '2 BHK';
      if (num == 3) return '3 BHK';
      if (num >= 4) return '4 BHK+';
    }

    if (title.contains('1 bhk') || title.contains('1bhk')) return '1 BHK';
    if (title.contains('2 bhk') || title.contains('2bhk')) return '2 BHK';
    if (title.contains('3 bhk') || title.contains('3bhk')) return '3 BHK';
    if (title.contains('4 bhk') || title.contains('4bhk') || title.contains('5 bhk')) return '4 BHK+';

    // 5. Industrial
    if (cat.contains('indust') || type.contains('indust')) {
      return 'Commercial';
    }

    return 'Others';
  }

  @override
  void didUpdateWidget(covariant AnalyticsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kpiFilters.businessType != widget.kpiFilters.businessType) {
      _selectedBreakdownMetricKey = null;
      _mobileActiveBreakdownKey = null;
      _expandedCategory = null;
      _hoveredPieSegmentIndex = null;
      final bt = widget.kpiFilters.businessType.trim().toLowerCase();
      if (bt == 'rent') {
        _areaListingTypeFilter = 'Rent';
      } else if (bt == 're-sale' || bt == 'resale' || bt == 'sale') {
        _areaListingTypeFilter = 'Re-Sale';
      } else {
        _areaListingTypeFilter = 'Both';
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _areaScrollController.dispose();
    super.dispose();
  }

  void _scrollAreas(bool forward) {
    if (!_areaScrollController.hasClients) return;
    final current = _areaScrollController.offset;
    final delta = forward ? 320.0 : -320.0;
    _areaScrollController.animateTo(
      (current + delta).clamp(0.0, _areaScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1100;

    final inventory = widget.data?.inventoryLocations ?? const [];
    final leads = widget.data?.leadsLocations ?? const [];

    // Filter properties according to top-level filters
    final filteredProps = inventory.where((p) {
      if (widget.kpiFilters.leadType == 'Requirement') return false;
      if (!DashboardFilterUtils.matchesBusiness(p.listingType, widget.kpiFilters)) return false;
      if (!DashboardFilterUtils.matchesDate(p.createdAt, widget.kpiFilters)) return false;
      return true;
    }).toList();

    // Filter leads according to top-level filters (exclude closed/won/rejected leads for active demand)
    final filteredLeads = leads.where((l) {
      if (widget.kpiFilters.leadType == 'Listing') return false;
      if (!DashboardFilterUtils.matchesBusiness(l.listingType, widget.kpiFilters)) return false;
      if (!DashboardFilterUtils.matchesDate(l.createdAt, widget.kpiFilters)) return false;
      return l.isLeadActive;
    }).toList();

    // All leads matching top-level filters (for Won & Rejected counts)
    final allScopeLeads = leads.where((l) {
      if (widget.kpiFilters.leadType == 'Listing') return false;
      if (!DashboardFilterUtils.matchesBusiness(l.listingType, widget.kpiFilters)) return false;
      if (!DashboardFilterUtils.matchesDate(l.createdAt, widget.kpiFilters)) return false;
      return true;
    }).toList();

    // Available properties
    final availableProps = filteredProps.where((p) => p.isAvailable).toList();
    final rentAvailableProps = availableProps.where((p) => p.isRent).toList();
    final resaleAvailableProps = availableProps.where((p) => p.isResale).toList();

    // Properties Rented Out & Sold Out
    final rentRentedProps = filteredProps.where((p) => p.isRent && p.isRented).toList();
    final resaleSoldProps = filteredProps.where((p) => p.isResale && p.isSold).toList();

    // Active leads
    final rentActiveLeads = filteredLeads.where((l) => l.isRent).toList();
    final resaleActiveLeads = filteredLeads.where((l) => l.isResale).toList();

    // Won leads
    final rentWonLeads = allScopeLeads.where((l) => l.isRent && l.isLeadWon).toList();
    final resaleWonLeads = allScopeLeads.where((l) => l.isResale && l.isLeadWon).toList();

    // Rejected leads
    final rentRejectedLeads = allScopeLeads.where((l) => l.isRent && l.isLeadRejected).toList();
    final resaleRejectedLeads = allScopeLeads.where((l) => l.isResale && l.isLeadRejected).toList();

    // Collect all available cities for selector
    const defaultCities = ['Ahmedabad', 'Bhavnagar', 'Gandhinagar', 'Rajkot', 'Surat', 'Vadodara'];
    final citiesSet = <String>{...defaultCities};
    widget.data?.cityAreas.forEach((city, _) {
      citiesSet.add(normalizeCityName(city));
    });
    for (final p in inventory) {
      citiesSet.add(normalizeCityName(p.cityName));
    }
    for (final l in leads) {
      citiesSet.add(normalizeCityName(l.cityName));
    }
    final allCities = citiesSet.toList()..sort();

    // Ensure selected city is valid
    if (!allCities.contains(_selectedCity)) {
      _selectedCity = allCities.first;
    }

    final normSelectedCity = normalizeCityName(_selectedCity).toLowerCase();

    // Filter properties and leads for selected city
    final cityProps = availableProps.where((p) {
      final pCity = normalizeCityName(p.cityName).toLowerCase();
      if (pCity == normSelectedCity) return true;
      final areasForSelectedCity = widget.data?.cityAreas[_selectedCity] ?? widget.data?.cityAreas[normSelectedCity];
      if (areasForSelectedCity != null && p.areaName.isNotEmpty) {
        return areasForSelectedCity.any((a) => a.trim().toLowerCase() == p.areaName.trim().toLowerCase());
      }
      return false;
    }).toList();

    final cityLeads = filteredLeads.where((l) {
      final leadCity = normalizeCityName(l.cityName).toLowerCase();
      if (leadCity == normSelectedCity && leadCity != 'ahmedabad') {
        return true;
      }
      // Check if lead's area belongs to _selectedCity
      final areasForSelectedCity = <String>{};
      widget.data?.cityAreas.forEach((c, aList) {
        if (normalizeCityName(c).toLowerCase() == normSelectedCity) {
          areasForSelectedCity.addAll(aList.map((a) => a.trim().toLowerCase()));
        }
      });
      if (normSelectedCity == 'gandhinagar') {
        areasForSelectedCity.addAll(['adalaj', 'khodiyar', 'moti bhoyan', 'randheja', 'sargasan', 'zundal', 'koba', 'bhaijipura', 'raysan', 'vavol', 'pethapur', 'chiloda', 'kudasan', 'infocity', 'gift city']);
      } else if (normSelectedCity == 'bhavnagar') {
        areasForSelectedCity.addAll(['bhadbhid', 'kaliyabid', 'ghogha circle', 'subhashnagar', 'sidsar', 'tarsamiya', 'chitra', 'vartaj']);
      } else if (normSelectedCity == 'surat') {
        areasForSelectedCity.addAll(['vesu', 'adajan', 'pal', 'varachha', 'katargam', 'piplod', 'althan', 'dindoli', 'udhana', 'rander']);
      } else if (normSelectedCity == 'vadodara') {
        areasForSelectedCity.addAll(['alkapuri', 'gotri', 'vasna', 'manjalpur', 'karelibaug', 'waghodia', 'sama', 'akota', 'bhilpur']);
      } else if (normSelectedCity == 'rajkot') {
        areasForSelectedCity.addAll(['kalawad road', '150 feet ring road', 'university road', 'madhapar', 'kothariya', 'mavdi', 'raiysa']);
      }

      final lArea = l.areaName.trim().toLowerCase();
      if (areasForSelectedCity.contains(lArea)) {
        return true;
      }
      if (normSelectedCity == 'ahmedabad') {
        if (leadCity == 'ahmedabad' || leadCity.isEmpty) {
          final otherCityAreas = {'sargasan', 'kudasan', 'raysan', 'bhadbhid', 'vesu', 'adajan', 'pal', 'alkapuri', 'gotri', 'kalawad road'};
          if (!otherCityAreas.contains(lArea)) {
            return true;
          }
        }
      }
      return leadCity == normSelectedCity;
    }).toList();

    // -------------------------------------------------------------------------
    // Collect all available areas for the selected city
    // -------------------------------------------------------------------------
    final Set<String> cityAreasSet = {};

    // 1. Backend database registered areas for this city
    widget.data?.cityAreas.forEach((cityName, areas) {
      if (normalizeCityName(cityName).toLowerCase() == _selectedCity.toLowerCase()) {
        for (final a in areas) {
          final trimmed = a.trim();
          if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'ahmedabad') {
            cityAreasSet.add(trimmed);
          }
        }
      }
    });

    // 2. Areas present in properties or leads for this city
    for (final p in cityProps) {
      final a = p.areaName.trim();
      if (a.isNotEmpty && a.toLowerCase() != 'ahmedabad') {
        cityAreasSet.add(a);
      }
    }
    for (final l in cityLeads) {
      final a = l.areaName.trim();
      if (a.isNotEmpty && a.toLowerCase() != 'ahmedabad') {
        cityAreasSet.add(a);
      }
    }

    // 3. Fallback standard areas if initial cache has not yet synchronized
    if (cityAreasSet.isEmpty) {
      if (_selectedCity == 'Ahmedabad') {
        cityAreasSet.addAll([
          'Adalaj', 'Akhbarnagar', 'Ambawadi (Ahmedabad)', 'Ambli', 'Amdavad',
          'Anandnagar (Ahmedabad)', 'Ashram Road', 'Azad Society', 'Bakrana',
          'Bhabhar', 'Bhadaj', 'Bodakdev', 'Bopal', 'Chanakyapuri', 'Chandkheda',
          'Chandlodia', 'Dholera city', 'Gandhinagar', 'Ghatlodia', 'Gota',
          'Gurukul', 'Jivraj Park', 'Jodhpur Char Rasta', 'K K Nagar', 'Makarba',
          'Mehsana', 'Memnagar', 'Motera', 'Naranpura', 'Naroda', 'Nava Vadaj',
          'Navrangpura', 'New Ranip', 'New Vadaj', 'Nikol', 'Ognaj', 'Other Area',
          'Prahladnagar', 'Ranip', 'Sanand', 'Satellite', 'Science city',
          'Science park', 'Sg Highway', 'Shela', 'Shilaj', 'Shyamal', 'Sindhu bhavan',
          'Sola', 'South Bopal', 'Thaltej', 'Tragad', 'Vaishnodevi', 'Vasna',
          'Vastrapur', 'viramgam', 'Wapa', 'West Ahmedabad', 'Zundal', 'jagatpur',
          'marigold', 'sarkhej'
        ]);
      } else if (_selectedCity == 'Gandhinagar') {
        cityAreasSet.addAll(['Adalaj', 'Khodiyar', 'Moti Bhoyan', 'Randheja', 'Sargasan', 'Zundal']);
      } else if (_selectedCity == 'Bhavnagar') {
        cityAreasSet.addAll(['Bhadbhid']);
      }
    }

    // Initialize all areas belonging to this city
    final areaMap = <String, _AreaAggregate>{};
    for (final aName in cityAreasSet) {
      areaMap[aName] = _AreaAggregate(name: aName);
    }

    // Distribute properties into matching area
    for (final p in cityProps) {
      final aName = p.areaName.trim();
      if (aName.isEmpty) continue;
      final match = areaMap.keys.firstWhere(
        (k) => k.toLowerCase() == aName.toLowerCase(),
        orElse: () => aName,
      );
      areaMap.putIfAbsent(match, () => _AreaAggregate(name: match));
      areaMap[match]!.properties.add(p);
    }

    // Distribute leads into matching area
    for (final l in cityLeads) {
      final aName = l.areaName.trim();
      if (aName.isEmpty) continue;
      final match = areaMap.keys.firstWhere(
        (k) => k.toLowerCase() == aName.toLowerCase(),
        orElse: () => aName,
      );
      areaMap.putIfAbsent(match, () => _AreaAggregate(name: match));
      areaMap[match]!.leads.add(l);
    }

    // Top-level filter sync and section-level filters
    final topBusinessType = widget.kpiFilters.businessType.trim().toLowerCase();
    final String effectiveListingType;
    if (topBusinessType == 'rent') {
      effectiveListingType = 'Rent';
    } else if (topBusinessType == 're-sale' || topBusinessType == 'resale' || topBusinessType == 'sale') {
      effectiveListingType = 'Re-Sale';
    } else {
      effectiveListingType = _areaListingTypeFilter;
    }

    final budgetOptions = _getBudgetOptions(effectiveListingType);
    if (!budgetOptions.contains(_areaBudgetFilter)) {
      _areaBudgetFilter = 'All';
    }

    final q = _areaSearchQuery.trim().toLowerCase();

    // Map filtered items for each area
    final Map<String, List<DashboardLocationItem>> areaDisplayProps = {};
    final Map<String, List<DashboardLocationItem>> areaDisplayLeads = {};

    for (final entry in areaMap.entries) {
      final area = entry.value;

      final dispProps = area.properties.where((p) {
        if (!_matchesListingType(p, effectiveListingType)) return false;
        if (!_matchesRequirement(p, _areaRequirementFilter)) return false;
        if (!_matchesBudget(p.price, _areaBudgetFilter)) return false;
        if (q.isNotEmpty && !area.name.toLowerCase().contains(q) && !_itemMatchesSearch(p, q)) return false;
        return true;
      }).toList();

      final dispLeads = area.leads.where((l) {
        if (!_matchesListingType(l, effectiveListingType)) return false;
        if (!_matchesRequirement(l, _areaRequirementFilter)) return false;
        if (!_matchesBudget(l.price, _areaBudgetFilter)) return false;
        if (q.isNotEmpty && !area.name.toLowerCase().contains(q) && !_itemMatchesSearch(l, q)) return false;
        return true;
      }).toList();

      areaDisplayProps[area.name] = dispProps;
      areaDisplayLeads[area.name] = dispLeads;
    }

    // Sort areas:
    // When active tab is properties, prioritize areas with matching properties;
    // When active tab is requirements, prioritize areas with matching leads;
    var areaList = areaMap.values.toList();
    if (q.isNotEmpty) {
      areaList = areaList.where((a) =>
        a.name.toLowerCase().contains(q) ||
        (areaDisplayProps[a.name]?.isNotEmpty ?? false) ||
        (areaDisplayLeads[a.name]?.isNotEmpty ?? false)
      ).toList();
    } else if (_areaRequirementFilter != 'All' || _areaBudgetFilter != 'All') {
      areaList = areaList.where((a) =>
        (areaDisplayProps[a.name]?.isNotEmpty ?? false) ||
        (areaDisplayLeads[a.name]?.isNotEmpty ?? false)
      ).toList();
    }

    areaList.sort((a, b) {
      final isProp = _activeAreaViewType == 'properties';
      final primaryA = isProp ? (areaDisplayProps[a.name]?.length ?? 0) : (areaDisplayLeads[a.name]?.length ?? 0);
      final primaryB = isProp ? (areaDisplayProps[b.name]?.length ?? 0) : (areaDisplayLeads[b.name]?.length ?? 0);

      if (primaryA > 0 && primaryB == 0) return -1;
      if (primaryB > 0 && primaryA == 0) return 1;
      if (primaryB != primaryA) return primaryB.compareTo(primaryA);

      final totalA = a.properties.length + a.leads.length;
      final totalB = b.properties.length + b.leads.length;
      if (totalA > 0 && totalB == 0) return -1;
      if (totalB > 0 && totalA == 0) return 1;
      if (totalB != totalA) return totalB.compareTo(totalA);

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    int cityFilteredPropsCount = 0;
    int cityFilteredLeadsCount = 0;
    for (final pList in areaDisplayProps.values) {
      cityFilteredPropsCount += pList.length;
    }
    for (final lList in areaDisplayLeads.values) {
      cityFilteredLeadsCount += lList.length;
    }

    final showRent = widget.kpiFilters.businessType != 'Re-sale';
    final showResale = widget.kpiFilters.businessType != 'Rent';

    // The 10 Metrics as requested
    final rentMetrics = <_BreakdownMetric>[
      _BreakdownMetric(
        key: 'rent_props',
        group: 'Rent',
        label: 'Properties',
        count: rentAvailableProps.length,
        color: const Color(0xFF3B82F6),
        isProperty: true,
        items: rentAvailableProps,
      ),
      _BreakdownMetric(
        key: 'rent_leads',
        group: 'Rent',
        label: 'Leads',
        count: rentActiveLeads.length,
        color: const Color(0xFF06B6D4),
        isProperty: false,
        items: rentActiveLeads,
      ),
      _BreakdownMetric(
        key: 'rent_rented',
        group: 'Rent',
        label: 'Properties Rented Out',
        count: rentRentedProps.length,
        color: const Color(0xFF8B5CF6),
        isProperty: true,
        items: rentRentedProps,
      ),
      _BreakdownMetric(
        key: 'rent_won',
        group: 'Rent',
        label: 'Won',
        count: rentWonLeads.length,
        color: const Color(0xFF10B981),
        isProperty: false,
        items: rentWonLeads,
      ),
      _BreakdownMetric(
        key: 'rent_rejected',
        group: 'Rent',
        label: 'Rent – Rejected',
        count: rentRejectedLeads.length,
        color: const Color(0xFFEF4444),
        isProperty: false,
        items: rentRejectedLeads,
      ),
    ];

    final resaleMetrics = <_BreakdownMetric>[
      _BreakdownMetric(
        key: 'resale_props',
        group: 'Re-Sale',
        label: 'Properties',
        count: resaleAvailableProps.length,
        color: const Color(0xFFF59E0B),
        isProperty: true,
        items: resaleAvailableProps,
      ),
      _BreakdownMetric(
        key: 'resale_leads',
        group: 'Re-Sale',
        label: 'Leads',
        count: resaleActiveLeads.length,
        color: const Color(0xFF10B981),
        isProperty: false,
        items: resaleActiveLeads,
      ),
      _BreakdownMetric(
        key: 'resale_sold',
        group: 'Re-Sale',
        label: 'Properties Sold Out',
        count: resaleSoldProps.length,
        color: const Color(0xFF8B5CF6),
        isProperty: true,
        items: resaleSoldProps,
      ),
      _BreakdownMetric(
        key: 'resale_won',
        group: 'Re-Sale',
        label: 'Won',
        count: resaleWonLeads.length,
        color: const Color(0xFF059669),
        isProperty: false,
        items: resaleWonLeads,
      ),
      _BreakdownMetric(
        key: 'resale_rejected',
        group: 'Re-Sale',
        label: 'Re-Sale – Rejected',
        count: resaleRejectedLeads.length,
        color: const Color(0xFFEF4444),
        isProperty: false,
        items: resaleRejectedLeads,
      ),
    ];

    // Invalidate selected metric key if current key is filtered out by business type
    String? effectiveSelectedKey = _selectedBreakdownMetricKey;
    if (widget.kpiFilters.businessType == 'Re-sale' && effectiveSelectedKey != null && effectiveSelectedKey.startsWith('rent_')) {
      effectiveSelectedKey = null;
    } else if (widget.kpiFilters.businessType == 'Rent' && effectiveSelectedKey != null && effectiveSelectedKey.startsWith('resale_')) {
      effectiveSelectedKey = null;
    }

    final allMetrics = [...rentMetrics, ...resaleMetrics];
    final _BreakdownMetric? selectedMetric = effectiveSelectedKey != null
        ? allMetrics.cast<_BreakdownMetric?>().firstWhere(
            (m) => m?.key == effectiveSelectedKey,
            orElse: () => null,
          )
        : null;

    // Default data according to top-level business filter
    final List<DashboardLocationItem> defaultItems;
    final String defaultTitle;
    final String defaultSubtitle;
    final String defaultBadgeText;
    final Color defaultAccentColor;
    final String defaultCenterLabel;

    final isMobileView = !isDesktop;
    if (isMobileView) {
      if (widget.kpiFilters.businessType == 'Rent') {
        defaultItems = rentAvailableProps;
        defaultTitle = 'Rent Property Distribution';
        defaultSubtitle = '${defaultItems.length} rent properties broken down by property type';
        defaultBadgeText = 'Rent • Properties';
        defaultAccentColor = const Color(0xFF3B82F6);
        defaultCenterLabel = 'Rent Properties';
      } else if (widget.kpiFilters.businessType == 'Re-sale') {
        defaultItems = resaleAvailableProps;
        defaultTitle = 'Re-Sale Property Distribution';
        defaultSubtitle = '${defaultItems.length} re-sale properties broken down by property type';
        defaultBadgeText = 'Re-Sale • Properties';
        defaultAccentColor = const Color(0xFFF59E0B);
        defaultCenterLabel = 'Re-Sale Properties';
      } else {
        defaultItems = availableProps;
        defaultTitle = 'Property Type Distribution';
        defaultSubtitle = '${defaultItems.length} properties broken down by property type';
        defaultBadgeText = 'Both • Properties';
        defaultAccentColor = const Color(0xFF10B981);
        defaultCenterLabel = 'Total Properties';
      }
    } else {
      if (widget.kpiFilters.businessType == 'Rent') {
        defaultItems = [...rentAvailableProps, ...rentActiveLeads];
        defaultTitle = 'Rent Distribution';
        defaultSubtitle = '${defaultItems.length} rent units broken down by property type';
        defaultBadgeText = 'Rent • Overview';
        defaultAccentColor = const Color(0xFF3B82F6);
        defaultCenterLabel = 'Rent Units';
      } else if (widget.kpiFilters.businessType == 'Re-sale') {
        defaultItems = [...resaleAvailableProps, ...resaleActiveLeads];
        defaultTitle = 'Re-Sale Distribution';
        defaultSubtitle = '${defaultItems.length} re-sale units broken down by property type';
        defaultBadgeText = 'Re-Sale • Overview';
        defaultAccentColor = const Color(0xFFF59E0B);
        defaultCenterLabel = 'Re-Sale Units';
      } else {
        defaultItems = [...availableProps, ...filteredLeads];
        defaultTitle = 'Property Type Distribution';
        defaultSubtitle = '${defaultItems.length} units broken down by property type';
        defaultBadgeText = 'Both • Overview';
        defaultAccentColor = const Color(0xFF10B981);
        defaultCenterLabel = 'Total Units';
      }
    }

    // Active items for the chart (selected metric if any, otherwise default items)
    final List<DashboardLocationItem> activeItems;
    final String chartTitle;
    final String chartSubtitle;
    final String chartBadgeText;
    final Color chartAccentColor;
    final String chartCenterLabel;

    if (selectedMetric != null) {
      activeItems = selectedMetric.items;
      chartTitle = '${selectedMetric.group} ${selectedMetric.label} Distribution';
      chartSubtitle = '${selectedMetric.count} ${selectedMetric.isProperty ? "properties" : "leads"} broken down by type';
      chartBadgeText = '${selectedMetric.group} • ${selectedMetric.label}';
      chartAccentColor = selectedMetric.color;
      chartCenterLabel = selectedMetric.isProperty ? 'Properties' : 'Leads';
    } else {
      activeItems = defaultItems;
      chartTitle = defaultTitle;
      chartSubtitle = defaultSubtitle;
      chartBadgeText = defaultBadgeText;
      chartAccentColor = defaultAccentColor;
      chartCenterLabel = defaultCenterLabel;
    }

    // Compute 6-category breakdown for activeItems
    int c1Bhk = 0;
    int c2Bhk = 0;
    int c3Bhk = 0;
    int c4BhkPlus = 0;
    int cCommercial = 0;
    int cOthers = 0;

    for (final item in activeItems) {
      final grp = _classifyItem(item);
      switch (grp) {
        case '1 BHK':
          c1Bhk++;
          break;
        case '2 BHK':
          c2Bhk++;
          break;
        case '3 BHK':
          c3Bhk++;
          break;
        case '4 BHK+':
          c4BhkPlus++;
          break;
        case 'Commercial':
          cCommercial++;
          break;
        default:
          cOthers++;
          break;
      }
    }

    final totalSelected = activeItems.length;
    int calcPercent(int count) => totalSelected > 0 ? ((count / totalSelected) * 100).round() : 0;

    final categorySegments = <_PieChartSegment>[
      _PieChartSegment(
        id: '1_bhk',
        label: '1 BHK',
        count: c1Bhk,
        percentage: calcPercent(c1Bhk),
        color: const Color(0xFF3B82F6),
      ),
      _PieChartSegment(
        id: '2_bhk',
        label: '2 BHK',
        count: c2Bhk,
        percentage: calcPercent(c2Bhk),
        color: const Color(0xFF06B6D4),
      ),
      _PieChartSegment(
        id: '3_bhk',
        label: '3 BHK',
        count: c3Bhk,
        percentage: calcPercent(c3Bhk),
        color: const Color(0xFFF59E0B),
      ),
      _PieChartSegment(
        id: '4_bhk_plus',
        label: '4 BHK+',
        count: c4BhkPlus,
        percentage: calcPercent(c4BhkPlus),
        color: const Color(0xFF8B5CF6),
      ),
      _PieChartSegment(
        id: 'commercial',
        label: 'Commercial',
        count: cCommercial,
        percentage: calcPercent(cCommercial),
        color: const Color(0xFFEF4444),
      ),
      _PieChartSegment(
        id: 'others',
        label: 'Others',
        count: cOthers,
        percentage: calcPercent(cOthers),
        color: const Color(0xFF94A3B8),
      ),
    ];

    final activeSlices = categorySegments.where((s) => s.count > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // -------------------------------------------------------------
        // SECTION 1: Unified Parent Section Container holding both inner cards
        // -------------------------------------------------------------
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_selectedBreakdownMetricKey != null) {
              setState(() {
                _selectedBreakdownMetricKey = null;
                _hoveredPieSegmentIndex = null;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Left Inner Container: Dedicated Pie Chart Section (Matching Image 2)
                      Expanded(
                        flex: 4,
                        child: _buildDedicatedPieChartCard(
                          isDark: isDark,
                          primary: primary,
                          title: chartTitle,
                          subtitle: chartSubtitle,
                          badgeText: chartBadgeText,
                          accentColor: chartAccentColor,
                          centerLabel: chartCenterLabel,
                          selectedMetric: selectedMetric,
                          segments: activeSlices,
                          totalUnits: totalSelected,
                          allCategories: categorySegments,
                        ),
                      ),

                      const SizedBox(width: 14),

                      // 2. Right Inner Container: Dedicated Rent & Re-Sale Container
                      Expanded(
                        flex: 5,
                        child: _buildDedicatedRentResaleCard(
                          isDark: isDark,
                          primary: primary,
                          rentMetrics: rentMetrics,
                          resaleMetrics: resaleMetrics,
                          rentTotal: rentAvailableProps.length + rentActiveLeads.length,
                          resaleTotal: resaleAvailableProps.length + resaleActiveLeads.length,
                          showRent: showRent,
                          showResale: showResale,
                          selectedMetricKey: effectiveSelectedKey,
                          isDesktop: true,
                          availableProps: availableProps,
                          rentAvailableProps: rentAvailableProps,
                          resaleAvailableProps: resaleAvailableProps,
                          filteredLeads: filteredLeads,
                          rentActiveLeads: rentActiveLeads,
                          resaleActiveLeads: resaleActiveLeads,
                          rentRentedProps: rentRentedProps,
                          resaleSoldProps: resaleSoldProps,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDedicatedPieChartCard(
                        isDark: isDark,
                        primary: primary,
                        title: chartTitle,
                        subtitle: chartSubtitle,
                        badgeText: chartBadgeText,
                        accentColor: chartAccentColor,
                        centerLabel: chartCenterLabel,
                        selectedMetric: selectedMetric,
                        segments: activeSlices,
                        totalUnits: totalSelected,
                        allCategories: categorySegments,
                      ),
                      const SizedBox(height: 14),
                      _buildDedicatedRentResaleCard(
                        isDark: isDark,
                        primary: primary,
                        rentMetrics: rentMetrics,
                        resaleMetrics: resaleMetrics,
                        rentTotal: rentAvailableProps.length + rentActiveLeads.length,
                        resaleTotal: resaleAvailableProps.length + resaleActiveLeads.length,
                        showRent: showRent,
                        showResale: showResale,
                        selectedMetricKey: effectiveSelectedKey,
                        isDesktop: false,
                        availableProps: availableProps,
                        rentAvailableProps: rentAvailableProps,
                        resaleAvailableProps: resaleAvailableProps,
                        filteredLeads: filteredLeads,
                        rentActiveLeads: rentActiveLeads,
                        resaleActiveLeads: resaleActiveLeads,
                        rentRentedProps: rentRentedProps,
                        resaleSoldProps: resaleSoldProps,
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 18),

        // -------------------------------------------------------------
        // SECTION 2: City -> Area Analytics
        // -------------------------------------------------------------
        _buildCityAreaAnalyticsSection(
          isDark: isDark,
          primary: primary,
          allCities: allCities,
          cityPropsCount: cityFilteredPropsCount,
          cityLeadsCount: cityFilteredLeadsCount,
          effectiveListingType: effectiveListingType,
          budgetOptions: budgetOptions,
          areas: areaList,
          areaDisplayProps: areaDisplayProps,
          areaDisplayLeads: areaDisplayLeads,
          isDesktop: isDesktop,
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION 1A: Dedicated Pie Chart Card (Left Side, Matching Image 2 Design)
  // ===========================================================================
  Widget _buildDedicatedPieChartCard({
    required bool isDark,
    required Color primary,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color accentColor,
    required String centerLabel,
    required List<_PieChartSegment> segments,
    required int totalUnits,
    required List<_PieChartSegment> allCategories,
    _BreakdownMetric? selectedMetric,
  }) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    _PieChartSegment? hoveredSegment;
    if (_hoveredPieSegmentIndex != null &&
        _hoveredPieSegmentIndex! >= 0 &&
        _hoveredPieSegmentIndex! < allCategories.length) {
      hoveredSegment = allCategories[_hoveredPieSegmentIndex!];
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row matching Image 2
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.donut_large_rounded,
                  size: 16,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Dynamic Mode Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Chart Body: Donut on Left, Categories Legend on Right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Donut Canvas
              _buildInteractivePieChartCanvas(
                segments: segments,
                totalUnits: totalUnits,
                hoveredSegment: hoveredSegment,
                centerLabel: centerLabel,
                allCategories: allCategories,
                isDark: isDark,
                titleColor: titleColor,
                subtitleColor: subtitleColor,
                sizeDimension: 150,
              ),

              const SizedBox(width: 12),

              // 2. Categories Legend List (Matching Image 2)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(allCategories.length, (index) {
                    final cat = allCategories[index];
                    final isHovered = _hoveredPieSegmentIndex == index;

                    return MouseRegion(
                      onEnter: (_) => setState(() => _hoveredPieSegmentIndex = index),
                      onExit: (_) {
                        if (_hoveredPieSegmentIndex == index) {
                          setState(() => _hoveredPieSegmentIndex = null);
                        }
                      },
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _hoveredPieSegmentIndex = isHovered ? null : index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                          margin: const EdgeInsets.symmetric(vertical: 1),
                          decoration: BoxDecoration(
                            color: isHovered
                                ? cat.color.withValues(alpha: isDark ? 0.22 : 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: cat.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  cat.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isHovered ? FontWeight.w700 : FontWeight.w600,
                                    color: isHovered
                                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                cat.count.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${cat.percentage}%)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 1B: Dedicated Rent & Re-Sale Container (Right Side)
  // ===========================================================================
  Widget _buildDedicatedRentResaleCard({
    required bool isDark,
    required Color primary,
    required List<_BreakdownMetric> rentMetrics,
    required List<_BreakdownMetric> resaleMetrics,
    required int rentTotal,
    required int resaleTotal,
    required bool showRent,
    required bool showResale,
    String? selectedMetricKey,
    required bool isDesktop,
    required List<DashboardLocationItem> availableProps,
    required List<DashboardLocationItem> rentAvailableProps,
    required List<DashboardLocationItem> resaleAvailableProps,
    required List<DashboardLocationItem> filteredLeads,
    required List<DashboardLocationItem> rentActiveLeads,
    required List<DashboardLocationItem> resaleActiveLeads,
    required List<DashboardLocationItem> rentRentedProps,
    required List<DashboardLocationItem> resaleSoldProps,
  }) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    // Active breakdown determination for mobile view
    final String breakdownTitle;
    final List<DashboardLocationItem> breakdownItems;
    final Color breakdownColor;

    if (selectedMetricKey == 'rent_props') {
      breakdownTitle = 'Rent Properties';
      breakdownItems = rentAvailableProps;
      breakdownColor = const Color(0xFF3B82F6);
    } else if (selectedMetricKey == 'rent_leads') {
      breakdownTitle = 'Rent Leads';
      breakdownItems = rentActiveLeads;
      breakdownColor = const Color(0xFF06B6D4);
    } else if (selectedMetricKey == 'rent_rented') {
      breakdownTitle = 'Properties Rented Out';
      breakdownItems = rentRentedProps;
      breakdownColor = const Color(0xFF8B5CF6);
    } else if (selectedMetricKey == 'resale_props') {
      breakdownTitle = 'Re-Sale Properties';
      breakdownItems = resaleAvailableProps;
      breakdownColor = const Color(0xFFF59E0B);
    } else if (selectedMetricKey == 'resale_leads') {
      breakdownTitle = 'Re-Sale Leads';
      breakdownItems = resaleActiveLeads;
      breakdownColor = const Color(0xFF10B981);
    } else if (selectedMetricKey == 'resale_sold') {
      breakdownTitle = 'Properties Sold Out';
      breakdownItems = resaleSoldProps;
      breakdownColor = const Color(0xFF8B5CF6);
    } else if (_mobileActiveBreakdownKey == 'both_leads' && widget.kpiFilters.businessType == 'Both') {
      breakdownTitle = 'Both Leads';
      breakdownItems = filteredLeads;
      breakdownColor = const Color(0xFF06B6D4);
    } else if (_mobileActiveBreakdownKey == 'both_props' && widget.kpiFilters.businessType == 'Both') {
      breakdownTitle = 'Both Properties';
      breakdownItems = availableProps;
      breakdownColor = const Color(0xFF10B981);
    } else {
      if (widget.kpiFilters.businessType == 'Rent') {
        breakdownTitle = 'Rent Properties';
        breakdownItems = rentAvailableProps;
        breakdownColor = const Color(0xFF3B82F6);
      } else if (widget.kpiFilters.businessType == 'Re-sale') {
        breakdownTitle = 'Re-Sale Properties';
        breakdownItems = resaleAvailableProps;
        breakdownColor = const Color(0xFFF59E0B);
      } else {
        breakdownTitle = 'Both Properties';
        breakdownItems = availableProps;
        breakdownColor = const Color(0xFF10B981);
      }
    }

    final resItems = breakdownItems.where((i) => _isItemInCategory(i, 'Residential')).toList();
    final comItems = breakdownItems.where((i) => _isItemInCategory(i, 'Commercial')).toList();
    final indItems = breakdownItems.where((i) => _isItemInCategory(i, 'Industrial')).toList();
    final landItems = breakdownItems.where((i) => _isItemInCategory(i, 'Land & Plot')).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.swap_horiz_rounded,
                  size: 16,
                  color: primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rent & Re-Sale Overview',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Click any metric to inspect its distribution in the pie chart',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${widget.kpiFilters.businessType} • ${widget.kpiFilters.dateFilter}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Two Sections: Rent (left) & Re-Sale (right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rent Box
              Expanded(
                child: _buildMetricSectionBox(
                  isDark: isDark,
                  borderColor: borderColor,
                  title: 'Rent',
                  icon: Icons.key_rounded,
                  accentColor: const Color(0xFF3B82F6),
                  totalCount: rentTotal,
                  isFilteredOut: !showRent,
                  metrics: rentMetrics,
                  selectedMetricKey: selectedMetricKey,
                ),
              ),

              const SizedBox(width: 10),

              // Re-Sale Box
              Expanded(
                child: _buildMetricSectionBox(
                  isDark: isDark,
                  borderColor: borderColor,
                  title: 'Re-Sale',
                  icon: Icons.real_estate_agent_rounded,
                  accentColor: const Color(0xFFF59E0B),
                  totalCount: resaleTotal,
                  isFilteredOut: !showResale,
                  metrics: resaleMetrics,
                  selectedMetricKey: selectedMetricKey,
                ),
              ),
            ],
          ),

          if (!isDesktop) ...[
            const SizedBox(height: 14),
            _buildMobileCategoryConfigSection(
              isDark: isDark,
              borderColor: borderColor,
              activeTitle: breakdownTitle,
              activeColor: breakdownColor,
              totalCount: breakdownItems.length,
              residentialItems: resItems,
              commercialItems: comItems,
              industrialItems: indItems,
              landPlotItems: landItems,
              availableProps: availableProps,
              rentAvailableProps: rentAvailableProps,
              resaleAvailableProps: resaleAvailableProps,
              filteredLeads: filteredLeads,
              rentActiveLeads: rentActiveLeads,
              resaleActiveLeads: resaleActiveLeads,
              rentRentedProps: rentRentedProps,
              resaleSoldProps: resaleSoldProps,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Metric Section Box (Rent / Re-Sale) with Clickable Metric Rows
  // ---------------------------------------------------------------------------
  Widget _buildMetricSectionBox({
    required bool isDark,
    required Color borderColor,
    required String title,
    required IconData icon,
    required Color accentColor,
    required int totalCount,
    required bool isFilteredOut,
    required List<_BreakdownMetric> metrics,
    String? selectedMetricKey,
  }) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final boxBg = isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC);

    return Opacity(
      opacity: isFilteredOut ? 0.35 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: boxBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFilteredOut ? borderColor : accentColor.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 13, color: accentColor),
                ),
                const SizedBox(width: 7),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isFilteredOut ? 'Filtered' : '$totalCount Total',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            Container(
              height: 1,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),

            const SizedBox(height: 4),

            // 5 Clickable Metric Rows
            ...metrics.map((metric) {
              final isSelected = selectedMetricKey == metric.key;

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedBreakdownMetricKey == metric.key) {
                        _selectedBreakdownMetricKey = null;
                      } else {
                        _selectedBreakdownMetricKey = metric.key;
                      }
                      _hoveredPieSegmentIndex = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(vertical: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? metric.color.withValues(alpha: isDark ? 0.25 : 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? metric.color : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6.5,
                          height: 6.5,
                          decoration: BoxDecoration(
                            color: metric.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            metric.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(right: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: metric.color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? metric.color.withValues(alpha: 0.25)
                                : metric.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            metric.count.toString(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: metric.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  bool _isItemInCategory(DashboardLocationItem item, String catName) {
    if (item.matchesCategory(catName)) return true;
    final type = item.propertyTypeName.trim().toLowerCase();
    final cat = item.categoryName.trim().toLowerCase();
    if (catName == 'Residential') {
      return cat.contains('residen') || type.contains('apart') || type.contains('flat') || type.contains('villa') || type.contains('tenament') || type.contains('bungal');
    } else if (catName == 'Commercial') {
      return cat.contains('commerc') || type.contains('office') || type.contains('shop') || type.contains('showroom');
    } else if (catName == 'Industrial') {
      return cat.contains('indust') || type.contains('warehouse') || type.contains('shed');
    } else if (catName == 'Land & Plot') {
      return cat.contains('land') || cat.contains('plot') || type.contains('plot') || type.contains('land');
    }
    return false;
  }

  Map<String, int> _computeResidentialConfigs(List<DashboardLocationItem> items) {
    final Map<String, int> counts = {
      '1 BHK': 0,
      '2 BHK': 0,
      '3 BHK': 0,
      '4 BHK+': 0,
      'Villa': 0,
      'Duplex': 0,
      'Penthouse': 0,
    };

    for (final item in items) {
      final config = item.configurationName.trim().toLowerCase();
      final type = item.propertyTypeName.trim().toLowerCase();
      final title = item.title.trim().toLowerCase();
      final beds = item.bedrooms;

      if (config.contains('villa') || type.contains('villa') || title.contains('villa')) {
        counts['Villa'] = (counts['Villa'] ?? 0) + 1;
      } else if (config.contains('duplex') || type.contains('duplex') || title.contains('duplex')) {
        counts['Duplex'] = (counts['Duplex'] ?? 0) + 1;
      } else if (config.contains('penthouse') || type.contains('penthouse') || title.contains('penthouse')) {
        counts['Penthouse'] = (counts['Penthouse'] ?? 0) + 1;
      } else if (beds == 1 ||
          config.contains('1 bhk') || config.contains('1bhk') || config.contains('1 rk') || config.contains('1rk') ||
          title.contains('1 bhk') || title.contains('1bhk') || title.contains('1 rk')) {
        counts['1 BHK'] = (counts['1 BHK'] ?? 0) + 1;
      } else if (beds == 2 ||
          config.contains('2 bhk') || config.contains('2bhk') || config.contains('2.5') ||
          title.contains('2 bhk') || title.contains('2bhk')) {
        counts['2 BHK'] = (counts['2 BHK'] ?? 0) + 1;
      } else if (beds == 3 ||
          config.contains('3 bhk') || config.contains('3bhk') ||
          title.contains('3 bhk') || title.contains('3bhk')) {
        counts['3 BHK'] = (counts['3 BHK'] ?? 0) + 1;
      } else if (beds >= 4 ||
          config.contains('4 bhk') || config.contains('4bhk') || config.contains('5 bhk') || config.contains('5bhk') ||
          title.contains('4 bhk') || title.contains('5 bhk')) {
        counts['4 BHK+'] = (counts['4 BHK+'] ?? 0) + 1;
      } else {
        String fallback = 'Other';
        if (config.isNotEmpty) {
          fallback = item.configurationName.trim();
        } else if (type.isNotEmpty) {
          fallback = item.propertyTypeName.trim();
        }
        counts[fallback] = (counts[fallback] ?? 0) + 1;
      }
    }
    return counts;
  }

  Map<String, int> _computeCommercialConfigs(List<DashboardLocationItem> items) {
    final Map<String, int> counts = {
      'Office': 0,
      'Shop': 0,
      'Showroom': 0,
    };
    for (final item in items) {
      final config = item.configurationName.trim().toLowerCase();
      final type = item.propertyTypeName.trim().toLowerCase();
      final title = item.title.trim().toLowerCase();

      if (type.contains('office') || config.contains('office') || title.contains('office')) {
        counts['Office'] = (counts['Office'] ?? 0) + 1;
      } else if (type.contains('shop') || config.contains('shop') || title.contains('shop')) {
        counts['Shop'] = (counts['Shop'] ?? 0) + 1;
      } else if (type.contains('showroom') || config.contains('showroom') || title.contains('showroom')) {
        counts['Showroom'] = (counts['Showroom'] ?? 0) + 1;
      } else {
        String fallback = 'Other Commercial';
        if (config.isNotEmpty) {
          fallback = item.configurationName.trim();
        } else if (type.isNotEmpty) {
          fallback = item.propertyTypeName.trim();
        }
        counts[fallback] = (counts[fallback] ?? 0) + 1;
      }
    }
    return counts;
  }

  Map<String, int> _computeIndustrialConfigs(List<DashboardLocationItem> items) {
    final Map<String, int> counts = {
      'Warehouse': 0,
      'Industrial Shed': 0,
    };
    for (final item in items) {
      final config = item.configurationName.trim().toLowerCase();
      final type = item.propertyTypeName.trim().toLowerCase();
      final title = item.title.trim().toLowerCase();

      if (type.contains('warehouse') || config.contains('warehouse') || title.contains('warehouse')) {
        counts['Warehouse'] = (counts['Warehouse'] ?? 0) + 1;
      } else if (type.contains('shed') || config.contains('shed') || title.contains('shed')) {
        counts['Industrial Shed'] = (counts['Industrial Shed'] ?? 0) + 1;
      } else {
        String fallback = 'Other Industrial';
        if (config.isNotEmpty) {
          fallback = item.configurationName.trim();
        } else if (type.isNotEmpty) {
          fallback = item.propertyTypeName.trim();
        }
        counts[fallback] = (counts[fallback] ?? 0) + 1;
      }
    }
    return counts;
  }

  Map<String, int> _computeLandPlotConfigs(List<DashboardLocationItem> items) {
    final Map<String, int> counts = {
      'Plot': 0,
      'Land': 0,
    };
    for (final item in items) {
      final config = item.configurationName.trim().toLowerCase();
      final type = item.propertyTypeName.trim().toLowerCase();
      final title = item.title.trim().toLowerCase();

      if (type.contains('plot') || config.contains('plot') || title.contains('plot')) {
        counts['Plot'] = (counts['Plot'] ?? 0) + 1;
      } else if (type.contains('land') || config.contains('land') || title.contains('land')) {
        counts['Land'] = (counts['Land'] ?? 0) + 1;
      } else {
        String fallback = 'Plot / Land';
        if (config.isNotEmpty) {
          fallback = item.configurationName.trim();
        } else if (type.isNotEmpty) {
          fallback = item.propertyTypeName.trim();
        }
        counts[fallback] = (counts[fallback] ?? 0) + 1;
      }
    }
    return counts;
  }

  Widget _buildMobileCategoryConfigSection({
    required bool isDark,
    required Color borderColor,
    required String activeTitle,
    required Color activeColor,
    required int totalCount,
    required List<DashboardLocationItem> residentialItems,
    required List<DashboardLocationItem> commercialItems,
    required List<DashboardLocationItem> industrialItems,
    required List<DashboardLocationItem> landPlotItems,
    required List<DashboardLocationItem> availableProps,
    required List<DashboardLocationItem> rentAvailableProps,
    required List<DashboardLocationItem> resaleAvailableProps,
    required List<DashboardLocationItem> filteredLeads,
    required List<DashboardLocationItem> rentActiveLeads,
    required List<DashboardLocationItem> resaleActiveLeads,
    required List<DashboardLocationItem> rentRentedProps,
    required List<DashboardLocationItem> resaleSoldProps,
  }) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final resConfigs = _computeResidentialConfigs(residentialItems);
    final comConfigs = _computeCommercialConfigs(commercialItems);
    final indConfigs = _computeIndustrialConfigs(industrialItems);
    final landConfigs = _computeLandPlotConfigs(landPlotItems);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.category_rounded, size: 14, color: activeColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Category & Configuration Breakdown',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: activeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$activeTitle ($totalCount)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: activeColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Quick selection pill tabs to quickly toggle breakdown view on mobile
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                if (widget.kpiFilters.businessType == 'Both') ...[
                  _buildQuickBreakdownPill(
                    label: 'Both Properties',
                    count: availableProps.length,
                    isSelected: activeTitle == 'Both Properties',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      setState(() {
                        _selectedBreakdownMetricKey = null;
                        _mobileActiveBreakdownKey = 'both_props';
                        _hoveredPieSegmentIndex = null;
                      });
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildQuickBreakdownPill(
                    label: 'Both Leads',
                    count: filteredLeads.length,
                    isSelected: activeTitle == 'Both Leads',
                    color: const Color(0xFF06B6D4),
                    onTap: () {
                      setState(() {
                        _selectedBreakdownMetricKey = null;
                        _mobileActiveBreakdownKey = 'both_leads';
                        _hoveredPieSegmentIndex = null;
                      });
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                ],
                if (widget.kpiFilters.businessType != 'Re-sale') ...[
                  _buildQuickBreakdownPill(
                    label: 'Rent Properties',
                    count: rentAvailableProps.length,
                    isSelected: activeTitle == 'Rent Properties',
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      setState(() {
                        _selectedBreakdownMetricKey = 'rent_props';
                        _mobileActiveBreakdownKey = null;
                        _hoveredPieSegmentIndex = null;
                      });
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildQuickBreakdownPill(
                    label: 'Rent Leads',
                    count: rentActiveLeads.length,
                    isSelected: activeTitle == 'Rent Leads',
                    color: const Color(0xFF06B6D4),
                    onTap: () {
                      setState(() {
                        _selectedBreakdownMetricKey = 'rent_leads';
                        _mobileActiveBreakdownKey = null;
                        _hoveredPieSegmentIndex = null;
                      });
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildQuickBreakdownPill(
                    label: 'Rented Out',
                    count: rentRentedProps.length,
                    isSelected: activeTitle == 'Properties Rented Out',
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      setState(() {
                        _selectedBreakdownMetricKey = 'rent_rented';
                        _mobileActiveBreakdownKey = null;
                        _hoveredPieSegmentIndex = null;
                      });
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                ],
                if (widget.kpiFilters.businessType != 'Rent') ...[
                  _buildQuickBreakdownPill(
                    label: 'Re-Sale Properties',
                    count: resaleAvailableProps.length,
                    isSelected: activeTitle == 'Re-Sale Properties',
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      setState(() {
                        _selectedBreakdownMetricKey = 'resale_props';
                        _mobileActiveBreakdownKey = null;
                        _hoveredPieSegmentIndex = null;
                      });
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildQuickBreakdownPill(
                    label: 'Re-Sale Leads',
                    count: resaleActiveLeads.length,
                    isSelected: activeTitle == 'Re-Sale Leads',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      setState(() {
                        _selectedBreakdownMetricKey = 'resale_leads';
                        _mobileActiveBreakdownKey = null;
                        _hoveredPieSegmentIndex = null;
                      });
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildQuickBreakdownPill(
                    label: 'Sold Out',
                    count: resaleSoldProps.length,
                    isSelected: activeTitle == 'Properties Sold Out',
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      setState(() {
                        _selectedBreakdownMetricKey = 'resale_sold';
                        _mobileActiveBreakdownKey = null;
                        _hoveredPieSegmentIndex = null;
                      });
                    },
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 4 Category Accordions
          _buildCategoryAccordion(
            title: 'Residential',
            count: residentialItems.length,
            icon: Icons.home_work_rounded,
            color: const Color(0xFF3B82F6),
            configCounts: resConfigs,
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 8),
          _buildCategoryAccordion(
            title: 'Commercial',
            count: commercialItems.length,
            icon: Icons.business_rounded,
            color: const Color(0xFFF59E0B),
            configCounts: comConfigs,
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 8),
          _buildCategoryAccordion(
            title: 'Industrial',
            count: industrialItems.length,
            icon: Icons.factory_rounded,
            color: const Color(0xFF8B5CF6),
            configCounts: indConfigs,
            isDark: isDark,
            borderColor: borderColor,
          ),
          const SizedBox(height: 8),
          _buildCategoryAccordion(
            title: 'Land & Plot',
            count: landPlotItems.length,
            icon: Icons.landscape_rounded,
            color: const Color(0xFF10B981),
            configCounts: landConfigs,
            isDark: isDark,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAccordion({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Map<String, int> configCounts,
    required bool isDark,
    required Color borderColor,
  }) {
    final isExpanded = _expandedCategory == title;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isExpanded ? color.withValues(alpha: 0.5) : borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (_expandedCategory == title) {
                  _expandedCategory = null;
                } else {
                  _expandedCategory = title;
                }
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: count > 0
                          ? color.withValues(alpha: 0.12)
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: count > 0 ? color : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(
              height: 1,
              color: borderColor,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: configCounts.entries.map((entry) {
                  final configName = entry.key;
                  final configCount = entry.value;
                  final hasItems = configCount > 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasItems
                          ? color.withValues(alpha: isDark ? 0.2 : 0.08)
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: hasItems
                            ? color.withValues(alpha: isDark ? 0.4 : 0.3)
                            : borderColor,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          configName,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: hasItems ? FontWeight.w700 : FontWeight.w500,
                            color: hasItems
                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: hasItems ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$configCount',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: hasItems ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickBreakdownPill({
    required String label,
    required int count,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Interactive Pie Chart Canvas
  // ---------------------------------------------------------------------------
  Widget _buildInteractivePieChartCanvas({
    required List<_PieChartSegment> segments,
    required int totalUnits,
    required _PieChartSegment? hoveredSegment,
    required String centerLabel,
    required List<_PieChartSegment> allCategories,
    required bool isDark,
    required Color titleColor,
    required Color subtitleColor,
    double sizeDimension = 150,
  }) {
    return SizedBox(
      width: sizeDimension,
      height: sizeDimension,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return MouseRegion(
            onHover: (event) {
              if (totalUnits == 0 || segments.isEmpty) return;
              final center = Offset(size.width / 2, size.height / 2);
              final pos = event.localPosition;
              final dx = pos.dx - center.dx;
              final dy = pos.dy - center.dy;
              final dist = math.sqrt(dx * dx + dy * dy);

              final radius = size.width / 2;
              if (dist < radius - 35 || dist > radius + 10) {
                if (_hoveredPieSegmentIndex != null) {
                  setState(() => _hoveredPieSegmentIndex = null);
                }
                return;
              }

              var angle = math.atan2(dy, dx);
              angle = (angle + math.pi / 2);
              if (angle < 0) angle += 2 * math.pi;

              double currentAngle = 0.0;
              int? matchedIndex;
              for (int i = 0; i < segments.length; i++) {
                final sweep = (segments[i].count / totalUnits) * 2 * math.pi;
                if (angle >= currentAngle && angle <= currentAngle + sweep) {
                  matchedIndex = i;
                  break;
                }
                currentAngle += sweep;
              }

              if (matchedIndex != null) {
                final seg = segments[matchedIndex];
                final globalIndex = allCategories.indexWhere((c) => c.label == seg.label);
                if (_hoveredPieSegmentIndex != globalIndex && globalIndex != -1) {
                  setState(() => _hoveredPieSegmentIndex = globalIndex);
                }
              }
            },
            onExit: (_) {
              if (_hoveredPieSegmentIndex != null) {
                setState(() => _hoveredPieSegmentIndex = null);
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: size,
                  painter: _ModernPieChartPainter(
                    segments: segments,
                    total: totalUnits,
                    hoveredIndex: hoveredSegment != null
                        ? segments.indexWhere((s) => s.label == hoveredSegment.label)
                        : null,
                    isDark: isDark,
                  ),
                ),
                // Center Content Readout matching Image 2
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hoveredSegment != null
                          ? hoveredSegment.count.toString()
                          : totalUnits.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: hoveredSegment != null
                            ? hoveredSegment.color
                            : titleColor,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hoveredSegment != null
                          ? '${hoveredSegment.percentage}%'
                          : centerLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: hoveredSegment != null
                            ? (isDark ? Colors.white70 : const Color(0xFF334155))
                            : subtitleColor,
                      ),
                    ),
                    if (hoveredSegment != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          hoveredSegment.label,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: subtitleColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // SECTION 2: City -> Area Analytics Section
  // ===========================================================================
  Widget _buildCityAreaAnalyticsSection({
    required bool isDark,
    required Color primary,
    required List<String> allCities,
    required int cityPropsCount,
    required int cityLeadsCount,
    required String effectiveListingType,
    required List<String> budgetOptions,
    required List<_AreaAggregate> areas,
    required Map<String, List<DashboardLocationItem>> areaDisplayProps,
    required Map<String, List<DashboardLocationItem>> areaDisplayLeads,
    required bool isDesktop,
  }) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final topBusinessType = widget.kpiFilters.businessType.trim().toLowerCase();

    final isFiltered = _areaSearchQuery.isNotEmpty ||
        _areaRequirementFilter != 'All' ||
        _areaBudgetFilter != 'All' ||
        (topBusinessType != 'rent' && topBusinessType != 're-sale' && topBusinessType != 'resale' && topBusinessType != 'sale' && _areaListingTypeFilter != 'Both');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Title & Controls Bar
          if (!isDesktop) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.location_city_rounded,
                    size: 18,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'City → Area Analytics',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Area-wise properties & requirements',
                        style: TextStyle(
                          fontSize: 11,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primary.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '$_selectedCity: $cityPropsCount Properties • $cityLeadsCount Leads',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.location_city_rounded,
                    size: 18,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'City → Area Analytics',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Area-wise properties and client requirements for $_selectedCity',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // City Totals Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primary.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    '$_selectedCity: $cityPropsCount Properties • $cityLeadsCount Leads',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // -----------------------------------------------------------
          // Row 1: Simple Filters Bar (City Dropdown, Search/Name, Req, Budget, Rent/Re-sale)
          // -----------------------------------------------------------
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 1. City Dropdown (Single dropdown, no horizontal chips)
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: allCities.contains(_selectedCity) ? _selectedCity : allCities.first,
                      icon: Icon(Icons.arrow_drop_down_rounded, size: 20, color: primary),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      items: allCities.map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_city_rounded, size: 14, color: primary),
                            const SizedBox(width: 6),
                            Text(c),
                          ],
                        ),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCity = val;
                            _areaSearchQuery = '';
                            _searchController.clear();
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 2. Search / Name field directly to the right of City Dropdown
                SizedBox(
                  width: 200,
                  height: 36,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _areaSearchQuery = val),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search area or name...',
                      hintStyle: TextStyle(
                        fontSize: 11,
                        color: subtitleColor,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 15,
                        color: subtitleColor,
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 28),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: primary),
                      ),
                      suffixIcon: _areaSearchQuery.isNotEmpty
                          ? InkWell(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _areaSearchQuery = '');
                              },
                              child: Icon(Icons.close_rounded, size: 14, color: subtitleColor),
                            )
                          : null,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 3. Requirement Dropdown
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _areaRequirementFilter != 'All' ? primary : borderColor,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _areaRequirementFilter,
                      icon: Icon(Icons.arrow_drop_down_rounded, size: 18, color: subtitleColor),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: _areaRequirementFilter != 'All' ? FontWeight.w700 : FontWeight.w600,
                        color: _areaRequirementFilter != 'All'
                            ? primary
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      items: const [
                        'All',
                        '1 BHK',
                        '2 BHK',
                        '3 BHK',
                        '4 BHK+',
                        'Commercial',
                        'Plot / Land',
                        'Others',
                      ].map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r == 'All' ? 'Requirement: All' : r),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _areaRequirementFilter = val);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 4. Budget Dropdown
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _areaBudgetFilter != 'All' ? primary : borderColor,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: budgetOptions.contains(_areaBudgetFilter) ? _areaBudgetFilter : 'All',
                      icon: Icon(Icons.arrow_drop_down_rounded, size: 18, color: subtitleColor),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: _areaBudgetFilter != 'All' ? FontWeight.w700 : FontWeight.w600,
                        color: _areaBudgetFilter != 'All'
                            ? primary
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      items: budgetOptions.map((b) => DropdownMenuItem(
                        value: b,
                        child: Text(b == 'All' ? 'Budget: All' : b),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _areaBudgetFilter = val);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 5. Rent / Re-Sale Dropdown
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: effectiveListingType != 'Both' ? primary : borderColor,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: effectiveListingType,
                      icon: Icon(Icons.arrow_drop_down_rounded, size: 18, color: subtitleColor),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: effectiveListingType != 'Both' ? FontWeight.w700 : FontWeight.w600,
                        color: effectiveListingType != 'Both'
                            ? primary
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      items: (topBusinessType == 'rent'
                              ? const ['Rent']
                              : ((topBusinessType == 're-sale' || topBusinessType == 'resale' || topBusinessType == 'sale')
                                  ? const ['Re-Sale']
                                  : const ['Both', 'Rent', 'Re-Sale']))
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text('Type: $t'),
                              ))
                          .toList(),
                      onChanged: (topBusinessType == 'rent' || topBusinessType == 're-sale' || topBusinessType == 'resale' || topBusinessType == 'sale')
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() => _areaListingTypeFilter = val);
                              }
                            },
                    ),
                  ),
                ),

                if (isFiltered) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _areaSearchQuery = '';
                        _searchController.clear();
                        _areaRequirementFilter = 'All';
                        _areaBudgetFilter = 'All';
                        if (topBusinessType != 'rent' && topBusinessType != 're-sale' && topBusinessType != 'resale' && topBusinessType != 'sale') {
                          _areaListingTypeFilter = 'Both';
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.restart_alt_rounded, size: 14, color: Color(0xFFEF4444)),
                          SizedBox(width: 4),
                          Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // -----------------------------------------------------------
          // Row 2: Properties / Requirements Clickable Tabs + Count + Controls
          // -----------------------------------------------------------
          if (!isDesktop) ...[
            // Mobile: Row 2a (Segmented Tabs full width)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  // Tab 1: Properties
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (_activeAreaViewType != 'properties') {
                          setState(() => _activeAreaViewType = 'properties');
                        }
                      },
                      borderRadius: BorderRadius.circular(7),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _activeAreaViewType == 'properties'
                              ? const Color(0xFF3B82F6)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: _activeAreaViewType == 'properties'
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.apartment_rounded,
                              size: 14,
                              color: _activeAreaViewType == 'properties'
                                  ? Colors.white
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Properties ($cityPropsCount)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: _activeAreaViewType == 'properties'
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: _activeAreaViewType == 'properties'
                                      ? Colors.white
                                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 3),

                  // Tab 2: Requirements / Leads
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (_activeAreaViewType != 'requirements') {
                          setState(() => _activeAreaViewType = 'requirements');
                        }
                      },
                      borderRadius: BorderRadius.circular(7),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _activeAreaViewType == 'requirements'
                              ? const Color(0xFF10B981)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          boxShadow: _activeAreaViewType == 'requirements'
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.group_rounded,
                              size: 14,
                              color: _activeAreaViewType == 'requirements'
                                  ? Colors.white
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Leads ($cityLeadsCount)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: _activeAreaViewType == 'requirements'
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: _activeAreaViewType == 'requirements'
                                      ? Colors.white
                                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Mobile: Row 2b (Areas count + Scroll Chevrons)
            Row(
              children: [
                Text(
                  '${areas.length} Areas in $_selectedCity',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _scrollAreas(false),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 18,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _scrollAreas(true),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                // Segmented Clickable Tabs (Properties vs Requirements)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tab 1: Properties
                      InkWell(
                        onTap: () {
                          if (_activeAreaViewType != 'properties') {
                            setState(() => _activeAreaViewType = 'properties');
                          }
                        },
                        borderRadius: BorderRadius.circular(7),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _activeAreaViewType == 'properties'
                                ? const Color(0xFF3B82F6)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: _activeAreaViewType == 'properties'
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.apartment_rounded,
                                size: 14,
                                color: _activeAreaViewType == 'properties'
                                    ? Colors.white
                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Properties ($cityPropsCount)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: _activeAreaViewType == 'properties'
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: _activeAreaViewType == 'properties'
                                      ? Colors.white
                                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 3),

                      // Tab 2: Requirements / Leads
                      InkWell(
                        onTap: () {
                          if (_activeAreaViewType != 'requirements') {
                            setState(() => _activeAreaViewType = 'requirements');
                          }
                        },
                        borderRadius: BorderRadius.circular(7),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _activeAreaViewType == 'requirements'
                                ? const Color(0xFF10B981)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: _activeAreaViewType == 'requirements'
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.group_rounded,
                                size: 14,
                                color: _activeAreaViewType == 'requirements'
                                    ? Colors.white
                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Leads ($cityLeadsCount)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: _activeAreaViewType == 'requirements'
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: _activeAreaViewType == 'requirements'
                                      ? Colors.white
                                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                Text(
                  '${areas.length} Areas in $_selectedCity',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  ),
                ),

                const Spacer(),

                // Left / Right Scroll Chevrons
                InkWell(
                  onTap: () => _scrollAreas(false),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 18,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _scrollAreas(true),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Horizontal scrollable strip of Area Cards
          if (areas.isEmpty)
            Container(
              height: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_off_rounded,
                    size: 28,
                    color: subtitleColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No areas found matching criteria in $_selectedCity',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 240,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: ListView.separated(
                  controller: _areaScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: areas.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final area = areas[index];
                    return _AreaCard(
                      area: area,
                      displayProperties: areaDisplayProps[area.name] ?? const [],
                      displayLeads: areaDisplayLeads[area.name] ?? const [],
                      activeViewType: _activeAreaViewType,
                      onViewTypeChanged: (newType) {
                        setState(() => _activeAreaViewType = newType);
                      },
                      isDark: isDark,
                      primary: primary,
                      onPropertyTap: widget.onPropertyTap,
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// HELPER CLASSES & MODELS
// =============================================================================

class _PieChartSegment {
  final String id;
  final String label;
  final int count;
  final int percentage;
  final Color color;

  const _PieChartSegment({
    required this.id,
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
  });
}

class _BreakdownMetric {
  final String key;
  final String group;
  final String label;
  final int count;
  final Color color;
  final bool isProperty;
  final List<DashboardLocationItem> items;

  const _BreakdownMetric({
    required this.key,
    required this.group,
    required this.label,
    required this.count,
    required this.color,
    required this.isProperty,
    required this.items,
  });
}

class _AreaAggregate {
  final String name;
  final List<DashboardLocationItem> properties = [];
  final List<DashboardLocationItem> leads = [];

  _AreaAggregate({required this.name});
}

// =============================================================================
// Modern Pie / Donut Chart Painter
// =============================================================================

class _ModernPieChartPainter extends CustomPainter {
  final List<_PieChartSegment> segments;
  final int total;
  final int? hoveredIndex;
  final bool isDark;

  _ModernPieChartPainter({
    required this.segments,
    required this.total,
    this.hoveredIndex,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 20.0;

    // Empty state ring
    if (total == 0 || segments.isEmpty) {
      final emptyPaint = Paint()
        ..color = isDark ? const Color(0xFF334155).withValues(alpha: 0.6) : const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawCircle(center, radius - strokeWidth / 2, emptyPaint);
      return;
    }

    double startAngle = -math.pi / 2;
    const gap = 0.04; // Space between donut slices in radians

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg.count <= 0) continue;
      final sweepAngle = (seg.count / total) * 2 * math.pi;
      final isHovered = hoveredIndex == i;

      final currentStroke = isHovered ? strokeWidth + 4.0 : strokeWidth;

      if (isHovered) {
        // Draw soft glow behind hovered segment
        final glowPaint = Paint()
          ..color = seg.color.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = currentStroke + 6.0
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true;

        final glowRect = Rect.fromCircle(
          center: center,
          radius: radius - strokeWidth / 2,
        );
        canvas.drawArc(
          glowRect,
          startAngle + gap / 2,
          (sweepAngle - gap).clamp(0.01, 2 * math.pi),
          false,
          glowPaint,
        );
      }

      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      final rect = Rect.fromCircle(
        center: center,
        radius: radius - strokeWidth / 2,
      );

      final effectiveSweep = segments.length > 1
          ? (sweepAngle - gap).clamp(0.01, 2 * math.pi)
          : sweepAngle;

      canvas.drawArc(rect, startAngle + (segments.length > 1 ? gap / 2 : 0.0), effectiveSweep, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _ModernPieChartPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.total != total ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.isDark != isDark;
  }
}

// =============================================================================
// Area Card Component
// =============================================================================

class _AreaCard extends StatelessWidget {
  final _AreaAggregate area;
  final List<DashboardLocationItem> displayProperties;
  final List<DashboardLocationItem> displayLeads;
  final String activeViewType; // 'properties' | 'requirements'
  final ValueChanged<String> onViewTypeChanged;
  final bool isDark;
  final Color primary;
  final Function(String)? onPropertyTap;

  const _AreaCard({
    required this.area,
    required this.displayProperties,
    required this.displayLeads,
    required this.activeViewType,
    required this.onViewTypeChanged,
    required this.isDark,
    required this.primary,
    this.onPropertyTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final rentProps = displayProperties.where((p) => p.isRent).length;
    final resaleProps = displayProperties.where((p) => p.isResale).length;
    final rentLeads = displayLeads.where((l) => l.isRent).length;
    final resaleLeads = displayLeads.where((l) => l.isResale).length;

    final isPropsActive = activeViewType == 'properties';

    return Container(
      width: 310,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
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
          // Header: Area Name
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 15,
                color: primary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  area.name,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          // Rent & Re-Sale sub-breakdown row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isPropsActive
                      ? 'Rent: $rentProps Properties'
                      : 'Rent: $rentLeads Leads',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                Text(
                  isPropsActive
                      ? 'Re-Sale: $resaleProps Properties'
                      : 'Re-Sale: $resaleLeads Leads',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Scrollable Dynamic Content Container: Properties OR Requirements
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: isPropsActive
                  ? _buildPropertiesList(context, borderColor, subtitleColor, titleColor)
                  : _buildRequirementsList(context, borderColor, subtitleColor, titleColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesList(
    BuildContext context,
    Color borderColor,
    Color subtitleColor,
    Color titleColor,
  ) {
    if (displayProperties.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 20,
              color: subtitleColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              'No listed properties',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: subtitleColor,
              ),
            ),
            Text(
              '0 properties in this area',
              style: TextStyle(
                fontSize: 9.5,
                color: subtitleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        itemCount: displayProperties.length,
        separatorBuilder: (context, index) => const SizedBox(height: 5),
        itemBuilder: (context, propIndex) {
          final prop = displayProperties[propIndex];
          final isRent = prop.isRent;
          return InkWell(
            onTap: () => onPropertyTap?.call(prop.id),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: borderColor.withValues(alpha: 0.8),
                ),
              ),
              child: Row(
                children: [
                  // Code Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      prop.code.isNotEmpty ? prop.code : 'PROP',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  // Title / Category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prop.title.isNotEmpty ? prop.title : prop.categoryName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Text(
                              isRent ? 'Rent' : 'Re-sale',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isRent
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFF59E0B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '• ${prop.categoryName}',
                              style: TextStyle(
                                fontSize: 9,
                                color: subtitleColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Price
                  Text(
                    formatPrice(prop.price, isRent),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequirementsList(
    BuildContext context,
    Color borderColor,
    Color subtitleColor,
    Color titleColor,
  ) {
    if (displayLeads.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 20,
              color: subtitleColor.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              'No active leads',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: subtitleColor,
              ),
            ),
            Text(
              '0 leads in this area',
              style: TextStyle(
                fontSize: 9.5,
                color: subtitleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        itemCount: displayLeads.length,
        separatorBuilder: (context, index) => const SizedBox(height: 5),
        itemBuilder: (context, leadIndex) {
          final lead = displayLeads[leadIndex];
          final isRent = lead.isRent;
          final clientName = lead.title.trim().isNotEmpty ? lead.title.trim() : 'Client Lead';
          final spec = lead.configurationName.trim().isNotEmpty
              ? lead.configurationName.trim()
              : (lead.propertyTypeName.trim().isNotEmpty
                  ? lead.propertyTypeName.trim()
                  : lead.categoryName.trim());

          return InkWell(
            onTap: () {
              context.push('/requirements');
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: borderColor.withValues(alpha: 0.8),
                ),
              ),
              child: Row(
                children: [
                  // REQ Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'REQ',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  // Client Name / Requirement Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: titleColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Text(
                              isRent ? 'Rent' : 'Re-sale',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isRent
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFF59E0B),
                              ),
                            ),
                            if (spec.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '• $spec',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: subtitleColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Budget Price
                  Text(
                    lead.price > 0 ? formatPrice(lead.price, isRent) : 'Budget Open',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: lead.price > 0
                          ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                          : subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
