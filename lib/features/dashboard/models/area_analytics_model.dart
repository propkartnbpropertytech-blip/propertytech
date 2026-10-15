class AreaCountItem {
  final String? areaId;
  final String area;
  final int count;
  final double latitude;
  final double longitude;

  const AreaCountItem({
    this.areaId,
    required this.area,
    required this.count,
    this.latitude = 23.0225,
    this.longitude = 72.5714,
  });

  factory AreaCountItem.fromJson(Map<String, dynamic> json) {
    return AreaCountItem(
      areaId: json['areaId']?.toString() ?? json['area_id']?.toString(),
      area: json['area']?.toString() ?? 'Unknown Area',
      count: (json['count'] as num?)?.toInt() ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 23.0225,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 72.5714,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (areaId != null) 'areaId': areaId,
      'area': area,
      'count': count,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class LocalityIntelligenceItem {
  final String? areaId;
  final String areaName;
  final double latitude;
  final double longitude;
  final int availableProperties;
  final int soldOutProperties;
  final int rentedOutProperties;
  final int totalProperties;
  final int totalLeads;
  final int listingLeads;
  final int requirementLeads;
  final int dealWonLeads;
  final Map<String, int> sources;

  const LocalityIntelligenceItem({
    this.areaId,
    required this.areaName,
    this.latitude = 23.0225,
    this.longitude = 72.5714,
    this.availableProperties = 0,
    this.soldOutProperties = 0,
    this.rentedOutProperties = 0,
    this.totalProperties = 0,
    this.totalLeads = 0,
    this.listingLeads = 0,
    this.requirementLeads = 0,
    this.dealWonLeads = 0,
    this.sources = const {},
  });

  /// Demand to inventory ratio: requirementLeads / availableProperties
  double get demandRatio {
    if (availableProperties <= 0) {
      return requirementLeads > 0 ? requirementLeads.toDouble() : 0.0;
    }
    return requirementLeads / availableProperties;
  }

  /// Demand status: High Demand (> 3.0x), Balanced (1.0x - 3.0x), High Supply (< 1.0x)
  String get demandStatus {
    if (requirementLeads == 0 && availableProperties == 0) return 'No Activity';
    if (availableProperties == 0 && requirementLeads > 0) return 'High Demand';
    if (demandRatio > 3.0) return 'High Demand';
    if (demandRatio >= 1.0) return 'Balanced';
    return 'High Supply';
  }

  factory LocalityIntelligenceItem.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'];
    final Map<String, int> parsedSources = {};
    if (rawSources is Map) {
      rawSources.forEach((k, v) {
        if (k != null && v != null) {
          parsedSources[k.toString().toUpperCase()] = (v as num).toInt();
        }
      });
    }

    final avail = (json['availableProperties'] as num?)?.toInt() ?? 0;
    final sold = (json['soldOutProperties'] as num?)?.toInt() ?? 0;
    final rented = (json['rentedOutProperties'] as num?)?.toInt() ?? 0;
    final totalProps = (json['totalProperties'] as num?)?.toInt() ?? (avail + sold + rented);

    final listing = (json['listingLeads'] as num?)?.toInt() ?? 0;
    final req = (json['requirementLeads'] as num?)?.toInt() ?? 0;
    final totalLds = (json['totalLeads'] as num?)?.toInt() ?? (listing + req);

    return LocalityIntelligenceItem(
      areaId: json['areaId']?.toString() ?? json['area_id']?.toString(),
      areaName: json['areaName']?.toString() ?? json['area']?.toString() ?? 'Unknown Area',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 23.0225,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 72.5714,
      availableProperties: avail,
      soldOutProperties: sold,
      rentedOutProperties: rented,
      totalProperties: totalProps,
      totalLeads: totalLds,
      listingLeads: listing,
      requirementLeads: req,
      dealWonLeads: (json['dealWonLeads'] as num?)?.toInt() ?? 0,
      sources: parsedSources,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (areaId != null) 'areaId': areaId,
      'areaName': areaName,
      'latitude': latitude,
      'longitude': longitude,
      'availableProperties': availableProperties,
      'soldOutProperties': soldOutProperties,
      'rentedOutProperties': rentedOutProperties,
      'totalProperties': totalProperties,
      'totalLeads': totalLeads,
      'listingLeads': listingLeads,
      'requirementLeads': requirementLeads,
      'dealWonLeads': dealWonLeads,
      'sources': sources,
    };
  }
}

class LocalityIntelligenceData {
  final int totalInventory;
  final int totalSoldOut;
  final int totalRentedOut;
  final int totalProperties;
  final int totalLeads;
  final int mappedLeads;
  final int unknownAreaLeads;
  final int totalListingLeads;
  final int totalRequirementLeads;
  final int totalDealWonLeads;
  final String businessType;
  final Map<String, int> leadSources;
  final Map<String, int> sourceDealWon;
  final Map<String, int> dataQuality;
  final List<LocalityIntelligenceItem> localities;
  final LocalityIntelligenceItem? unknownArea;

  const LocalityIntelligenceData({
    this.totalInventory = 0,
    this.totalSoldOut = 0,
    this.totalRentedOut = 0,
    this.totalProperties = 0,
    this.totalLeads = 0,
    this.mappedLeads = 0,
    this.unknownAreaLeads = 0,
    this.totalListingLeads = 0,
    this.totalRequirementLeads = 0,
    this.totalDealWonLeads = 0,
    this.businessType = 'Both',
    this.leadSources = const {},
    this.sourceDealWon = const {},
    this.dataQuality = const {},
    this.localities = const [],
    this.unknownArea,
  });

  factory LocalityIntelligenceData.fromJson(Map<String, dynamic> json) {
    final list = (json['localities'] as List?)
            ?.map((item) =>
                LocalityIntelligenceItem.fromJson(Map<String, dynamic>.from(item)))
            .toList() ??
        const [];

    final Map<String, int> parsedLeadSources = {};
    if (json['leadSources'] is Map) {
      (json['leadSources'] as Map).forEach((k, v) {
        if (k != null && v != null) {
          parsedLeadSources[k.toString().toUpperCase()] = (v as num).toInt();
        }
      });
    }

    final Map<String, int> parsedSourceDealWon = {};
    if (json['sourceDealWon'] is Map) {
      (json['sourceDealWon'] as Map).forEach((k, v) {
        if (k != null && v != null) {
          parsedSourceDealWon[k.toString().toUpperCase()] = (v as num).toInt();
        }
      });
    }

    final Map<String, int> parsedDataQuality = {};
    if (json['dataQuality'] is Map) {
      (json['dataQuality'] as Map).forEach((k, v) {
        if (k != null && v != null) {
          parsedDataQuality[k.toString()] = (v as num).toInt();
        }
      });
    }

    LocalityIntelligenceItem? parsedUnknownArea;
    if (json['unknownArea'] is Map) {
      parsedUnknownArea = LocalityIntelligenceItem.fromJson(
        Map<String, dynamic>.from(json['unknownArea'] as Map),
      );
    }

    final totalInv = (json['totalInventory'] as num?)?.toInt() ?? 0;
    final totalSold = (json['totalSoldOut'] as num?)?.toInt() ?? 0;
    final totalRented = (json['totalRentedOut'] as num?)?.toInt() ?? 0;
    final totalProps = (json['totalProperties'] as num?)?.toInt() ?? (totalInv + totalSold + totalRented);

    final mappedLds = (json['mappedLeads'] as num?)?.toInt() ??
        list.fold<int>(0, (s, l) => s + l.totalLeads);
    final unkLds = (json['unknownAreaLeads'] as num?)?.toInt() ??
        (parsedUnknownArea?.totalLeads ?? 0);
    final totalLds = (json['totalLeads'] as num?)?.toInt() ?? (mappedLds + unkLds);

    return LocalityIntelligenceData(
      totalInventory: totalInv,
      totalSoldOut: totalSold,
      totalRentedOut: totalRented,
      totalProperties: totalProps,
      totalLeads: totalLds,
      mappedLeads: mappedLds,
      unknownAreaLeads: unkLds,
      totalListingLeads: (json['totalListingLeads'] as num?)?.toInt() ?? 0,
      totalRequirementLeads: (json['totalRequirementLeads'] as num?)?.toInt() ?? 0,
      totalDealWonLeads: (json['totalDealWonLeads'] as num?)?.toInt() ?? 0,
      businessType: json['businessType']?.toString() ?? 'Both',
      leadSources: parsedLeadSources,
      sourceDealWon: parsedSourceDealWon,
      dataQuality: parsedDataQuality,
      localities: list,
      unknownArea: parsedUnknownArea,
    );
  }
}

