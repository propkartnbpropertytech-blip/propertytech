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

class DashboardData {
  final DashboardSummary summary;
  final List<RecentActivity> activity;
  final List<RecentProperty> recentProperties;
  final List<ChecklistItem> checklist;
  final List<DashboardFollowup> followups;
  final List<DashboardSiteVisit> siteVisits;

  const DashboardData({
    required this.summary,
    required this.activity,
    required this.recentProperties,
    required this.checklist,
    required this.followups,
    required this.siteVisits,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      summary: DashboardSummary.fromJson(json['summary'] ?? {}),
      activity: (json['activity'] as List?)
              ?.map((item) => RecentActivity.fromJson(item))
              .toList() ??
          [],
      recentProperties: (json['recentProperties'] as List?)
              ?.map((item) => RecentProperty.fromJson(item))
              .toList() ??
          [],
      checklist: (json['checklist'] as List?)
              ?.map((item) => ChecklistItem.fromJson(item))
              .toList() ??
          [],
      followups: (json['followups'] as List?)
              ?.map((item) => DashboardFollowup.fromJson(item))
              .toList() ??
          [],
      siteVisits: (json['siteVisits'] as List?)
              ?.map((item) => DashboardSiteVisit.fromJson(item))
              .toList() ??
          [],
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
  });

  factory DashboardFollowup.fromJson(Map<String, dynamic> json) {
    final property = json['property'] as Map<String, dynamic>?;
    final requirement = json['requirement'] as Map<String, dynamic>?;
    final creator = json['creator'] as Map<String, dynamic>?;
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
  });

  factory DashboardSiteVisit.fromJson(Map<String, dynamic> json) {
    final property = json['property'] as Map<String, dynamic>?;
    final requirement = json['requirement'] as Map<String, dynamic>?;
    final creator = json['creator'] as Map<String, dynamic>?;
    final propertyId = (json['property_id'] ?? property?['id'])?.toString();
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
    );
  }
}
