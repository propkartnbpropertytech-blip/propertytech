import 'package:intl/intl.dart';

class PropertyInventoryItem {
  final String id;
  final String propertyCode;
  final String title;
  final num price;
  final DateTime? createdAt;
  final DateTime? possessionDate;
  final String categoryName;
  final String listingType;
  final String statusName;
  final String locality;
  final String cityName;
  final String configurationName;
  final int imageCount;
  final bool hasImages;
  final String? coverImageUrl;

  const PropertyInventoryItem({
    required this.id,
    required this.propertyCode,
    required this.title,
    required this.price,
    this.createdAt,
    this.possessionDate,
    required this.categoryName,
    required this.listingType,
    required this.statusName,
    required this.locality,
    required this.cityName,
    required this.configurationName,
    required this.imageCount,
    required this.hasImages,
    this.coverImageUrl,
  });

  factory PropertyInventoryItem.fromJson(Map<String, dynamic> json) {
    num parsedPrice = 0;
    if (json['price'] != null) {
      if (json['price'] is num) {
        parsedPrice = json['price'] as num;
      } else {
        parsedPrice = num.tryParse(json['price'].toString()) ?? 0;
      }
    }

    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['created_at'].toString())?.toLocal();
    }

    DateTime? parsedPossessionDate;
    if (json['possession_date'] != null) {
      parsedPossessionDate = DateTime.tryParse(json['possession_date'].toString())?.toLocal();
    }

    return PropertyInventoryItem(
      id: json['id']?.toString() ?? '',
      propertyCode: json['property_code']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unnamed Property',
      price: parsedPrice,
      createdAt: parsedCreatedAt,
      possessionDate: parsedPossessionDate,
      categoryName: json['category_name']?.toString() ?? 'Residential',
      listingType: json['listing_type']?.toString() ?? 'Rent',
      statusName: json['status_name']?.toString() ?? 'Available',
      locality: json['locality']?.toString() ?? '',
      cityName: json['city_name']?.toString() ?? '',
      configurationName: json['configuration_name']?.toString() ?? '',
      imageCount: (json['image_count'] is num) ? (json['image_count'] as num).toInt() : 0,
      hasImages: json['has_images'] == true || ((json['image_count'] as num?)?.toInt() ?? 0) > 0,
      coverImageUrl: json['cover_image_url']?.toString(),
    );
  }

  String get formattedPrice {
    if (price <= 0) return '₹ 0';
    if (price >= 10000000) {
      final cr = price / 10000000;
      return '₹ ${cr.toStringAsFixed(cr.truncateToDouble() == cr ? 0 : 2)} Cr';
    } else if (price >= 100000) {
      final l = price / 100000;
      return '₹ ${l.toStringAsFixed(l.truncateToDouble() == l ? 0 : 2)} Lac';
    } else {
      final f = NumberFormat('#,##,###', 'en_IN');
      final p = f.format(price);
      return listingType.toUpperCase() == 'RENT' ? '₹ $p / mo' : '₹ $p';
    }
  }

  String get formattedCreatedAt {
    if (createdAt == null) return '—';
    return DateFormat('dd MMM yyyy, hh:mm a').format(createdAt!);
  }

  String get formattedDateShort {
    if (createdAt == null) return '—';
    return DateFormat('dd MMM yyyy').format(createdAt!);
  }
}

class PropertyInventoryKpis {
  final int total;
  final int availableInventory;
  final int readyWithImages;
  final int noImages;

  const PropertyInventoryKpis({
    this.total = 0,
    this.availableInventory = 0,
    this.readyWithImages = 0,
    this.noImages = 0,
  });

  factory PropertyInventoryKpis.fromJson(Map<String, dynamic> json) {
    return PropertyInventoryKpis(
      total: (json['total'] as num?)?.toInt() ?? 0,
      availableInventory: (json['available_inventory'] as num?)?.toInt() ?? 0,
      readyWithImages: (json['ready_with_images'] as num?)?.toInt() ?? 0,
      noImages: (json['no_images'] as num?)?.toInt() ?? 0,
    );
  }
}

class PropertyInventoryCategories {
  final int all;
  final int residential;
  final int commercial;
  final int industrial;
  final int landAndPlot;

  const PropertyInventoryCategories({
    this.all = 0,
    this.residential = 0,
    this.commercial = 0,
    this.industrial = 0,
    this.landAndPlot = 0,
  });

  factory PropertyInventoryCategories.fromJson(Map<String, dynamic> json) {
    return PropertyInventoryCategories(
      all: (json['All'] as num?)?.toInt() ?? 0,
      residential: (json['Residential'] as num?)?.toInt() ?? 0,
      commercial: (json['Commercial'] as num?)?.toInt() ?? 0,
      industrial: (json['Industrial'] as num?)?.toInt() ?? 0,
      landAndPlot: (json['Land & Plot'] as num?)?.toInt() ?? 0,
    );
  }

  int countFor(String category) {
    switch (category.toLowerCase()) {
      case 'residential':
        return residential;
      case 'commercial':
        return commercial;
      case 'industrial':
        return industrial;
      case 'land & plot':
      case 'land':
      case 'plot':
        return landAndPlot;
      case 'all':
      default:
        return all;
    }
  }
}

class PropertyInventoryTabs {
  final int rentCount;
  final int resaleCount;

  const PropertyInventoryTabs({
    this.rentCount = 0,
    this.resaleCount = 0,
  });

  factory PropertyInventoryTabs.fromJson(Map<String, dynamic> json) {
    return PropertyInventoryTabs(
      rentCount: (json['rent_count'] as num?)?.toInt() ?? 0,
      resaleCount: (json['resale_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class PropertyInventoryReportData {
  final PropertyInventoryTabs tabs;
  final PropertyInventoryCategories categories;
  final PropertyInventoryKpis kpis;
  final int total;
  final int filteredCount;
  final int page;
  final int limit;
  final List<PropertyInventoryItem> rows;

  const PropertyInventoryReportData({
    this.tabs = const PropertyInventoryTabs(),
    this.categories = const PropertyInventoryCategories(),
    this.kpis = const PropertyInventoryKpis(),
    this.total = 0,
    this.filteredCount = 0,
    this.page = 1,
    this.limit = 100,
    this.rows = const [],
  });

  factory PropertyInventoryReportData.fromJson(Map<String, dynamic> json) {
    final rawRows = json['rows'] as List<dynamic>? ?? [];
    return PropertyInventoryReportData(
      tabs: PropertyInventoryTabs.fromJson(json['tabs'] as Map<String, dynamic>? ?? {}),
      categories: PropertyInventoryCategories.fromJson(json['categories'] as Map<String, dynamic>? ?? {}),
      kpis: PropertyInventoryKpis.fromJson(json['kpis'] as Map<String, dynamic>? ?? {}),
      total: (json['total'] as num?)?.toInt() ?? 0,
      filteredCount: (json['filtered_count'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 100,
      rows: rawRows.map((e) => PropertyInventoryItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
