import 'package:equatable/equatable.dart';

class SuperAdminPlatformSummary extends Equatable {
  final int organizationCount;
  final int adminWorkspaceCount;
  final int brokerWorkspaceCount;
  final int otherWorkspaceCount;
  final int activeSubscriptionCount;
  final int expiredSubscriptionCount;
  final int nearingExpiryCount;
  final int nearingExpiryDays;
  final int pendingOnboardingCount;
  final int openSupportCount;
  final int inProgressSupportCount;

  const SuperAdminPlatformSummary({
    required this.organizationCount,
    required this.adminWorkspaceCount,
    required this.brokerWorkspaceCount,
    required this.otherWorkspaceCount,
    required this.activeSubscriptionCount,
    required this.expiredSubscriptionCount,
    required this.nearingExpiryCount,
    required this.nearingExpiryDays,
    required this.pendingOnboardingCount,
    required this.openSupportCount,
    required this.inProgressSupportCount,
  });

  factory SuperAdminPlatformSummary.fromJson(Map<String, dynamic> json) {
    return SuperAdminPlatformSummary(
      organizationCount: _asInt(json['organizationCount']),
      adminWorkspaceCount: _asInt(json['adminWorkspaceCount']),
      brokerWorkspaceCount: _asInt(json['brokerWorkspaceCount']),
      otherWorkspaceCount: _asInt(json['otherWorkspaceCount']),
      activeSubscriptionCount: _asInt(json['activeSubscriptionCount']),
      expiredSubscriptionCount: _asInt(json['expiredSubscriptionCount']),
      nearingExpiryCount: _asInt(json['nearingExpiryCount']),
      nearingExpiryDays: _asInt(json['nearingExpiryDays']),
      pendingOnboardingCount: _asInt(json['pendingOnboardingCount']),
      openSupportCount: _asInt(json['openSupportCount']),
      inProgressSupportCount: _asInt(json['inProgressSupportCount']),
    );
  }

  @override
  List<Object?> get props => [
        organizationCount,
        adminWorkspaceCount,
        brokerWorkspaceCount,
        otherWorkspaceCount,
        activeSubscriptionCount,
        expiredSubscriptionCount,
        nearingExpiryCount,
        nearingExpiryDays,
        pendingOnboardingCount,
        openSupportCount,
        inProgressSupportCount,
      ];
}

class SuperAdminOrganizationRow extends Equatable {
  final String organizationId;
  final String organizationName;
  final String? ownerName;
  final String? ownerEmail;
  final String? ownerRole;
  final String workspaceKind;
  final String? planName;
  final String? subscriptionStatus;
  final String subscriptionState;
  final String? startDate;
  final String? expiryDate;

  const SuperAdminOrganizationRow({
    required this.organizationId,
    required this.organizationName,
    this.ownerName,
    this.ownerEmail,
    this.ownerRole,
    required this.workspaceKind,
    this.planName,
    this.subscriptionStatus,
    required this.subscriptionState,
    this.startDate,
    this.expiryDate,
  });

  factory SuperAdminOrganizationRow.fromJson(Map<String, dynamic> json) {
    return SuperAdminOrganizationRow(
      organizationId: json['organizationId']?.toString() ?? '',
      organizationName: json['organizationName']?.toString() ?? 'Workspace',
      ownerName: json['ownerName']?.toString(),
      ownerEmail: json['ownerEmail']?.toString(),
      ownerRole: json['ownerRole']?.toString(),
      workspaceKind: json['workspaceKind']?.toString() ?? 'other',
      planName: json['planName']?.toString(),
      subscriptionStatus: json['subscriptionStatus']?.toString(),
      subscriptionState: json['subscriptionState']?.toString() ?? 'none',
      startDate: json['startDate']?.toString(),
      expiryDate: json['expiryDate']?.toString(),
    );
  }

  String get workspaceLabel {
    switch (workspaceKind) {
      case 'admin':
        return 'Admin workspace';
      case 'broker':
        return 'Broker workspace';
      default:
        return 'Unclassified';
    }
  }

  String get subscriptionLabel {
    switch (subscriptionState) {
      case 'active':
        return 'Active';
      case 'nearing_expiry':
        return 'Nearing expiry';
      case 'expired':
        return 'Expired';
      default:
        return 'No subscription';
    }
  }

  @override
  List<Object?> get props => [
        organizationId,
        organizationName,
        ownerName,
        ownerRole,
        workspaceKind,
        planName,
        subscriptionStatus,
        subscriptionState,
        expiryDate,
      ];
}

class SuperAdminWorkspaceMetrics extends Equatable {
  final int availableInventory;
  final int totalLeads;
  final int activeUsers;
  final int telecallers;
  final int salesUsers;
  final int closedDeals;
  final int siteVisitsDone;

  const SuperAdminWorkspaceMetrics({
    required this.availableInventory,
    required this.totalLeads,
    required this.activeUsers,
    required this.telecallers,
    required this.salesUsers,
    required this.closedDeals,
    required this.siteVisitsDone,
  });

  factory SuperAdminWorkspaceMetrics.fromJson(Map<String, dynamic> json) {
    return SuperAdminWorkspaceMetrics(
      availableInventory: _asInt(json['availableInventory']),
      totalLeads: _asInt(json['totalLeads']),
      activeUsers: _asInt(json['activeUsers']),
      telecallers: _asInt(json['telecallers']),
      salesUsers: _asInt(json['salesUsers']),
      closedDeals: _asInt(json['closedDeals']),
      siteVisitsDone: _asInt(json['siteVisitsDone']),
    );
  }

  @override
  List<Object?> get props => [
        availableInventory,
        totalLeads,
        activeUsers,
        telecallers,
        salesUsers,
        closedDeals,
        siteVisitsDone,
      ];
}

class SuperAdminSelectedWorkspace extends Equatable {
  final SuperAdminOrganizationRow organization;
  final SuperAdminWorkspaceMetrics metrics;

  const SuperAdminSelectedWorkspace({
    required this.organization,
    required this.metrics,
  });

  factory SuperAdminSelectedWorkspace.fromJson(Map<String, dynamic> json) {
    return SuperAdminSelectedWorkspace(
      organization: SuperAdminOrganizationRow.fromJson(
        Map<String, dynamic>.from(json['organization'] as Map? ?? const {}),
      ),
      metrics: SuperAdminWorkspaceMetrics.fromJson(
        Map<String, dynamic>.from(json['metrics'] as Map? ?? const {}),
      ),
    );
  }

  @override
  List<Object?> get props => [organization, metrics];
}

class SuperAdminOnboardingRequest extends Equatable {
  final String id;
  final String brokerageName;
  final String fullName;
  final String email;
  final String status;
  final String? planName;

  const SuperAdminOnboardingRequest({
    required this.id,
    required this.brokerageName,
    required this.fullName,
    required this.email,
    required this.status,
    this.planName,
  });

  factory SuperAdminOnboardingRequest.fromJson(Map<String, dynamic> json) {
    return SuperAdminOnboardingRequest(
      id: json['id']?.toString() ?? '',
      brokerageName: json['brokerageName']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      planName: json['planName']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, brokerageName, fullName, email, status, planName];
}

class SuperAdminOpenIssue extends Equatable {
  final String id;
  final String ticketNumber;
  final String reporterName;
  final String pageName;
  final String status;
  final String priority;

  const SuperAdminOpenIssue({
    required this.id,
    required this.ticketNumber,
    required this.reporterName,
    required this.pageName,
    required this.status,
    required this.priority,
  });

  factory SuperAdminOpenIssue.fromJson(Map<String, dynamic> json) {
    return SuperAdminOpenIssue(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticketNumber']?.toString() ?? '',
      reporterName: json['reporterName']?.toString() ?? '',
      pageName: json['pageName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, ticketNumber, reporterName, pageName, status, priority];
}

class SuperAdminPlatformOverview extends Equatable {
  final SuperAdminPlatformSummary summary;
  final List<SuperAdminOrganizationRow> organizations;
  final bool organizationListTruncated;
  final List<SuperAdminOrganizationRow> attentionSubscriptions;
  final List<SuperAdminOnboardingRequest> pendingOnboarding;
  final List<SuperAdminOpenIssue> openIssues;
  final SuperAdminSelectedWorkspace? selectedWorkspace;

  const SuperAdminPlatformOverview({
    required this.summary,
    required this.organizations,
    required this.organizationListTruncated,
    required this.attentionSubscriptions,
    required this.pendingOnboarding,
    required this.openIssues,
    this.selectedWorkspace,
  });

  factory SuperAdminPlatformOverview.fromJson(Map<String, dynamic> json) {
    return SuperAdminPlatformOverview(
      summary: SuperAdminPlatformSummary.fromJson(
        Map<String, dynamic>.from(json['summary'] as Map? ?? const {}),
      ),
      organizations: _mapList(json['organizations'], SuperAdminOrganizationRow.fromJson),
      organizationListTruncated: json['organizationListTruncated'] == true,
      attentionSubscriptions: _mapList(
        json['attentionSubscriptions'],
        SuperAdminOrganizationRow.fromJson,
      ),
      pendingOnboarding: _mapList(
        json['pendingOnboarding'],
        SuperAdminOnboardingRequest.fromJson,
      ),
      openIssues: _mapList(json['openIssues'], SuperAdminOpenIssue.fromJson),
      selectedWorkspace: json['selectedWorkspace'] is Map
          ? SuperAdminSelectedWorkspace.fromJson(
              Map<String, dynamic>.from(json['selectedWorkspace'] as Map),
            )
          : null,
    );
  }

  @override
  List<Object?> get props => [
        summary,
        organizations,
        organizationListTruncated,
        attentionSubscriptions,
        pendingOnboarding,
        openIssues,
        selectedWorkspace,
      ];
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<T> _mapList<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((item) => parse(Map<String, dynamic>.from(item)))
      .toList();
}
