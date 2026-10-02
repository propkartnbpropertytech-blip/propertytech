class DashboardSummary {
  final int totalProperties;
  final int available;
  final int sold;
  final int rented;
  final int requirements;
  final int users;

  final int rentalAvailable;
  final int resaleAvailable;
  final int rentalRented;
  final int resaleSold;
  final int rentalRequirements;
  final int resaleRequirements;
  final int rentalWonRequirements;
  final int resaleWonRequirements;
  final int rentalActiveRequirements;
  final int resaleActiveRequirements;
  final int totalActiveRequirements;
  final int totalWonRequirements;

  final double totalPropertiesTrend;
  final double availableTrend;
  final double soldTrend;
  final double rentedTrend;
  final double requirementsTrend;

  final String topBroker;
  final String topArea;
  final String topProperty;
  final String monthlyGrowth;

  const DashboardSummary({
    required this.totalProperties,
    required this.available,
    required this.sold,
    required this.rented,
    required this.requirements,
    required this.users,
    this.rentalAvailable = 0,
    this.resaleAvailable = 0,
    this.rentalRented = 0,
    this.resaleSold = 0,
    this.rentalRequirements = 0,
    this.resaleRequirements = 0,
    this.rentalWonRequirements = 0,
    this.resaleWonRequirements = 0,
    this.rentalActiveRequirements = 0,
    this.resaleActiveRequirements = 0,
    this.totalActiveRequirements = 0,
    this.totalWonRequirements = 0,
    this.totalPropertiesTrend = 0.0,
    this.availableTrend = 0.0,
    this.soldTrend = 0.0,
    this.rentedTrend = 0.0,
    this.requirementsTrend = 0.0,
    this.topBroker = 'N/A',
    this.topArea = 'N/A',
    this.topProperty = 'N/A',
    this.monthlyGrowth = '0.0%',
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final trends = json['trends'] as Map<String, dynamic>? ?? {};
    final perf = json['performance'] as Map<String, dynamic>? ?? {};

    return DashboardSummary(
      totalProperties: json['totalProperties'] ?? 0,
      available: json['available'] ?? 0,
      sold: json['sold'] ?? 0,
      rented: json['rented'] ?? 0,
      requirements: json['requirements'] ?? 0,
      users: json['users'] ?? 0,
      rentalAvailable: json['rentalAvailable'] ?? 0,
      resaleAvailable: json['resaleAvailable'] ?? 0,
      rentalRented: json['rentalRented'] ?? 0,
      resaleSold: json['resaleSold'] ?? 0,
      rentalRequirements: json['rentalRequirements'] ?? 0,
      resaleRequirements: json['resaleRequirements'] ?? 0,
      rentalWonRequirements: json['rentalWonRequirements'] ?? 0,
      resaleWonRequirements: json['resaleWonRequirements'] ?? 0,
      rentalActiveRequirements: json['rentalActiveRequirements'] ?? 0,
      resaleActiveRequirements: json['resaleActiveRequirements'] ?? 0,
      totalActiveRequirements: json['totalActiveRequirements'] ?? 0,
      totalWonRequirements: json['totalWonRequirements'] ?? 0,
      totalPropertiesTrend: (trends['totalProperties'] ?? 0.0).toDouble(),
      availableTrend: (trends['available'] ?? 0.0).toDouble(),
      soldTrend: (trends['sold'] ?? 0.0).toDouble(),
      rentedTrend: (trends['rented'] ?? 0.0).toDouble(),
      requirementsTrend: (trends['requirements'] ?? 0.0).toDouble(),
      topBroker: perf['topBroker'] ?? 'N/A',
      topArea: perf['topArea'] ?? 'N/A',
      topProperty: perf['topProperty'] ?? 'N/A',
      monthlyGrowth: perf['monthlyGrowth'] ?? '0.0%',
    );
  }
}

class RecentActivity {
  final String id;
  final String module;
  final String action;
  final String description;
  final String timestamp;
  final String user;

  const RecentActivity({
    required this.id,
    required this.module,
    required this.action,
    required this.description,
    required this.timestamp,
    required this.user,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'] ?? '',
      module: json['module'] ?? '',
      action: json['action'] ?? '',
      description: json['description'] ?? '',
      timestamp: json['timestamp'] ?? '',
      user: json['user'] ?? 'System',
    );
  }
}

class RecentProperty {
  final String id;
  final String code;
  final String title;
  final String area;
  final double price;
  final String status;
  final String areaName;
  final String listingType;
  final String createdBy;
  final String createdAt;

  const RecentProperty({
    required this.id,
    required this.code,
    required this.title,
    required this.area,
    required this.price,
    required this.status,
    required this.areaName,
    required this.listingType,
    required this.createdBy,
    required this.createdAt,
  });

  factory RecentProperty.fromJson(Map<String, dynamic> json) {
    return RecentProperty(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      title: json['title'] ?? '',
      area: json['area'] ?? 'N/A',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'N/A',
      areaName: json['areaName'] ?? 'N/A',
      listingType: json['listingType'] ?? 'Sale',
      createdBy: json['createdBy'] ?? 'System',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class DashboardLocationItem {
  final String id;
  final String code;
  final String title;
  final String cityName;
  final String areaName;
  final String categoryName;
  final String listingType;
  final String status;
  final double price;
  final DateTime? createdAt;

  final String configurationName;
  final String propertyTypeName;
  final int bedrooms;

  const DashboardLocationItem({
    required this.id,
    required this.code,
    this.title = '',
    this.cityName = 'Ahmedabad',
    required this.areaName,
    required this.categoryName,
    required this.listingType,
    this.status = 'Available',
    this.price = 0.0,
    this.createdAt,
    this.configurationName = '',
    this.propertyTypeName = '',
    this.bedrooms = 0,
  });

  bool get isAvailable {
    final s = status.trim().toLowerCase();
    return s == 'available' || s == 'to be available';
  }

  bool get isRented {
    final s = status.trim().toLowerCase();
    return s == 'rented out' || s == 'rented';
  }

  bool get isSold {
    final s = status.trim().toLowerCase();
    return s == 'sold out' || s == 'sold';
  }

  bool get isClosed => isRented || isSold;

  bool get isResale =>
      listingType.trim().toLowerCase().contains('sale') ||
      listingType.trim().toLowerCase().contains('resale');
  bool get isRent => !isResale;

  bool get isLeadWon {
    final s = status.trim().toLowerCase();
    return s == 'won' || s == 'deal won' || s == 'closed';
  }

  bool get isLeadActive {
    final s = status.trim().toLowerCase();
    return !isLeadWon &&
        !s.startsWith('rejected') &&
        s != 'dead' &&
        s != 'not interested' &&
        s != 'bin' &&
        s != 'suspended';
  }

  bool get isLeadRejected {
    final s = status.trim().toLowerCase();
    return s.startsWith('rejected') ||
        s == 'dead' ||
        s == 'not interested' ||
        s == 'bin' ||
        s == 'suspended' ||
        s == 'lost';
  }

  bool matchesCategory(String target) {
    if (target == 'All') return true;
    final cat = categoryName.trim().toLowerCase();
    if (target == 'Residential') return cat.contains('residen');
    if (target == 'Commercial') return cat.contains('commerc');
    if (target == 'Industrial') return cat.contains('indust');
    if (target == 'Land & Plot') return cat.contains('land') || cat.contains('plot');
    return true;
  }

  bool get isResidential => matchesCategory('Residential');
  bool get isCommercial => matchesCategory('Commercial');
  bool get isIndustrial => matchesCategory('Industrial');
  bool get isLandAndPlot => matchesCategory('Land & Plot');

  factory DashboardLocationItem.fromJson(Map<String, dynamic> json) {
    return DashboardLocationItem(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      title: json['title'] ?? '',
      cityName: json['cityName'] ?? json['city_name'] ?? 'Ahmedabad',
      areaName: json['areaName'] ?? json['area_name'] ?? 'Ahmedabad',
      categoryName: json['categoryName'] ?? json['category_name'] ?? 'Residential',
      listingType: json['listingType'] ?? json['listing_type'] ?? 'Rent',
      status: json['status'] ?? json['property_status']?['name'] ?? 'Available',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      configurationName: json['configurationName'] ?? json['configuration_name'] ?? '',
      propertyTypeName: json['propertyTypeName'] ?? json['property_type_name'] ?? '',
      bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'title': title,
    'cityName': cityName,
    'areaName': areaName,
    'categoryName': categoryName,
    'listingType': listingType,
    'status': status,
    'price': price,
    'createdAt': createdAt?.toIso8601String(),
    'configurationName': configurationName,
    'propertyTypeName': propertyTypeName,
    'bedrooms': bedrooms,
  };
}

class DashboardData {
  final DashboardSummary summary;
  final List<RecentActivity> activity;
  final List<RecentProperty> recentProperties;
  final List<ChecklistItem> checklist;
  final List<DashboardFollowup> followups;
  final List<DashboardSiteVisit> siteVisits;
  final List<DashboardLocationItem> inventoryLocations;
  final List<DashboardLocationItem> leadsLocations;
  final Map<String, List<String>> cityAreas;

  const DashboardData({
    required this.summary,
    required this.activity,
    required this.recentProperties,
    required this.checklist,
    required this.followups,
    required this.siteVisits,
    this.inventoryLocations = const [],
    this.leadsLocations = const [],
    this.cityAreas = const {},
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    List<T> safeList<T>(dynamic raw, T Function(dynamic) mapper) {
      if (raw is List) {
        return raw.map(mapper).toList();
      }
      return <T>[];
    }

    final rawFollowups = json['followups'] is List ? json['followups'] : json['followupsList'];

    Map<String, List<String>> parsedCityAreas = {};
    if (json['cityAreas'] is Map) {
      (json['cityAreas'] as Map).forEach((k, v) {
        if (v is List) {
          parsedCityAreas[k.toString()] = v.map((e) => e.toString()).toList();
        }
      });
    }

    return DashboardData(
      summary: DashboardSummary.fromJson(json['summary'] is Map ? json['summary'] as Map<String, dynamic> : {}),
      activity: safeList(json['activity'], (item) => RecentActivity.fromJson(item)),
      recentProperties: safeList(json['recentProperties'], (item) => RecentProperty.fromJson(item)),
      checklist: safeList(json['checklist'], (item) => ChecklistItem.fromJson(item)),
      followups: safeList(rawFollowups, (item) => DashboardFollowup.fromJson(item)),
      siteVisits: safeList(json['siteVisits'], (item) => DashboardSiteVisit.fromJson(item)),
      inventoryLocations: safeList(json['inventoryLocations'], (item) => DashboardLocationItem.fromJson(item)),
      leadsLocations: safeList(json['leadsLocations'], (item) => DashboardLocationItem.fromJson(item)),
      cityAreas: parsedCityAreas,
    );
  }
}

class ChecklistItem {
  final String id;
  final String title;
  final bool isCompleted;
  final String dueDate;

  const ChecklistItem({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.dueDate,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      isCompleted: json['is_completed'] ?? false,
      dueDate: json['due_date'] ?? '',
    );
  }
}

class DashboardFollowup {
  final String id;
  final String clientName;
  final String mobile;
  final String followupDate;
  final String? notes;
  final String status;
  final String? propertyCode;
  final String? propertyTitle;
  final String? requirementCustomerName;
  final String? requirementId;
  final String? creatorName;
  final String? salespersonName;

  const DashboardFollowup({
    required this.id,
    required this.clientName,
    required this.mobile,
    required this.followupDate,
    this.notes,
    required this.status,
    this.propertyCode,
    this.propertyTitle,
    this.requirementCustomerName,
    this.requirementId,
    this.creatorName,
    this.salespersonName,
  });

  DashboardFollowup copyWith({
    String? id,
    String? clientName,
    String? mobile,
    String? followupDate,
    String? notes,
    String? status,
    String? propertyCode,
    String? propertyTitle,
    String? requirementCustomerName,
    String? requirementId,
    String? creatorName,
    String? salespersonName,
  }) {
    return DashboardFollowup(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      mobile: mobile ?? this.mobile,
      followupDate: followupDate ?? this.followupDate,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      propertyCode: propertyCode ?? this.propertyCode,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      requirementCustomerName: requirementCustomerName ?? this.requirementCustomerName,
      requirementId: requirementId ?? this.requirementId,
      creatorName: creatorName ?? this.creatorName,
      salespersonName: salespersonName ?? this.salespersonName,
    );
  }

  factory DashboardFollowup.fromJson(Map<String, dynamic> json) {
    final property = json['property'] as Map<String, dynamic>?;
    final requirement = json['requirement'] as Map<String, dynamic>?;
    final creator = json['creator'] as Map<String, dynamic>?;
    final assignee = requirement?['assignee'] as Map<String, dynamic>?;
    final resolvedSalesperson = requirement?['assignee_name'] ??
        assignee?['full_name'] ??
        json['salesperson_name'] ??
        json['assignee_name'];

    return DashboardFollowup(
      id: json['id'] ?? '',
      clientName: json['client_name'] ?? '',
      mobile: json['mobile'] ?? '',
      followupDate: json['followup_date'] ?? '',
      notes: json['notes'],
      status: json['status'] ?? 'Pending',
      propertyCode: property?['property_code'],
      propertyTitle: property?['title'],
      requirementCustomerName: requirement?['customer_name'],
      requirementId: json['requirement_id'] ?? requirement?['id'],
      creatorName: creator?['full_name'],
      salespersonName: resolvedSalesperson?.toString(),
    );
  }
}

class DashboardSiteVisit {
  final String id;
  final String visitDate;
  final String? remarks;
  final String status;
  final String? propertyId;
  final String? propertyCode;
  final String? propertyTitle;
  final String? requirementCustomerName;
  final String? requirementId;
  final String? creatorName;
  final String? salespersonName;

  const DashboardSiteVisit({
    required this.id,
    required this.visitDate,
    this.remarks,
    required this.status,
    this.propertyId,
    this.propertyCode,
    this.propertyTitle,
    this.requirementCustomerName,
    this.requirementId,
    this.creatorName,
    this.salespersonName,
  });

  DashboardSiteVisit copyWith({
    String? id,
    String? visitDate,
    String? remarks,
    String? status,
    String? propertyId,
    String? propertyCode,
    String? propertyTitle,
    String? requirementCustomerName,
    String? requirementId,
    String? creatorName,
    String? salespersonName,
  }) {
    return DashboardSiteVisit(
      id: id ?? this.id,
      visitDate: visitDate ?? this.visitDate,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      propertyId: propertyId ?? this.propertyId,
      propertyCode: propertyCode ?? this.propertyCode,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      requirementCustomerName: requirementCustomerName ?? this.requirementCustomerName,
      requirementId: requirementId ?? this.requirementId,
      creatorName: creatorName ?? this.creatorName,
      salespersonName: salespersonName ?? this.salespersonName,
    );
  }

  factory DashboardSiteVisit.fromJson(Map<String, dynamic> json) {
    final property = json['property'] as Map<String, dynamic>?;
    final requirement = json['requirement'] as Map<String, dynamic>?;
    final creator = json['creator'] as Map<String, dynamic>?;
    final propertyId = (json['property_id'] ?? property?['id'])?.toString();
    final assignee = requirement?['assignee'] as Map<String, dynamic>?;
    final resolvedSalesperson = requirement?['assignee_name'] ??
        assignee?['full_name'] ??
        json['salesperson_name'] ??
        json['assignee_name'];

    return DashboardSiteVisit(
      id: json['id'] ?? '',
      visitDate: json['visit_date'] ?? '',
      remarks: json['remarks'],
      status: json['status'] ?? 'Pending',
      propertyId: (propertyId != null && propertyId.isNotEmpty) ? propertyId : null,
      propertyCode: property?['property_code'],
      propertyTitle: property?['title'],
      requirementCustomerName: requirement?['customer_name'],
      requirementId: json['requirement_id'] ?? requirement?['id'],
      creatorName: creator?['full_name'],
      salespersonName: resolvedSalesperson?.toString(),
    );
  }
}
