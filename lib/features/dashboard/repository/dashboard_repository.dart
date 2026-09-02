import 'package:propkart/features/dashboard/models/dashboard_summary.dart';
import 'package:propkart/features/dashboard/services/dashboard_service.dart';
import 'package:propkart/core/storage/repository_coordinator.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/core/storage/model_mappers.dart';
import 'package:propkart/core/storage/performance_logger.dart';
import 'package:propkart/core/security/role_guard.dart';

class DashboardRepository {
  final DashboardService _dashboardService = DashboardService();
  final RepositoryCoordinator _coordinator = RepositoryCoordinator();



  static Future<void>? _refreshInFlight;
  static DateTime? _lastRefreshAt;
  static const _minRefreshInterval = Duration(seconds: 45);

  Future<DashboardData> getDashboardData({
    bool backgroundRefresh = true,
  }) async {
    final start = DateTime.now();
    
    // Read from local Isar
    final localDashboard = await _coordinator.dashboardLocal.getDashboard();
    final isarReadMs = DateTime.now().difference(start).inMilliseconds;
    
    DashboardData? cachedData;
    int jsonParseMs = 0;
    if (localDashboard != null) {
      final parseStart = DateTime.now();
      cachedData = localDashboard.toModel();
      jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;
    }

    final totalMs = DateTime.now().difference(start).inMilliseconds;
    PerformanceLogger().logMetric(
      operation: 'DashboardRepository.getDashboardData (local)',
      isarReadMs: isarReadMs,
      jsonParseMs: jsonParseMs,
      totalMs: totalMs,
    );

    if (backgroundRefresh) {
      _triggerBackgroundDashboardRefresh();
    }

    // Get the dynamic counts of requirements to ensure they are always correct and in sync
    var localReqs = await _coordinator.requirementLocal.getRequirements();
    final currentUser = RoleGuard.currentUser;
    if (currentUser != null) {
      final role = currentUser.role;
      if (role == 'Admin') {
        localReqs = localReqs.where((r) =>
          r.createdBy == currentUser.id || r.adminId == currentUser.id
        ).toList();
      } else if (role == 'Telecaller') {
        localReqs = localReqs.where((r) =>
          r.createdBy == currentUser.id || r.adminId == currentUser.adminId
        ).toList();
      } else if (role != 'Super Admin') {
        localReqs = localReqs.where((r) =>
          r.createdBy == currentUser.id
        ).toList();
      }
    }
    int rentalReqs = 0;
    int resaleReqs = 0;
    int rentalWonReqs = 0;
    int resaleWonReqs = 0;
    int rentalSiteVisits = 0;
    int resaleSiteVisits = 0;
    for (final item in localReqs) {
      if (item.status == 'Bin') continue;

      final name = item.listingTypeName ?? '';
      final id = item.listingTypeId ?? '';
      final combined = '$name $id'.toLowerCase();
      final isWon = item.status == 'Won' || item.status == 'Closed';
      final isSiteVisit = item.status == 'Site Visit Done' ||
          item.status == 'Negotiation' ||
          item.status == 'Won' ||
          item.status == 'Closed';

      if (combined.contains('rent')) {
        if (isWon) {
          rentalWonReqs++;
        } else {
          rentalReqs++;
        }
        if (isSiteVisit) {
          rentalSiteVisits++;
        }
      } else if (combined.contains('sale') || combined.contains('resale')) {
        if (isWon) {
          resaleWonReqs++;
        } else {
          resaleReqs++;
        }
        if (isSiteVisit) {
          resaleSiteVisits++;
        }
      }
    }

    final allLocalProps = await _coordinator.propertyLocal.getProperties();
    List<RecentProperty> allRecentPropsFromLocal = [];
    if (allLocalProps.isNotEmpty) {
      final sortedProps = List.of(allLocalProps);
      sortedProps.sort((a, b) {
        final dtA = DateTime.tryParse(a.createdAt?.toString() ?? '') ?? DateTime(1970);
        final dtB = DateTime.tryParse(b.createdAt?.toString() ?? '') ?? DateTime(1970);
        return dtB.compareTo(dtA);
      });
      allRecentPropsFromLocal = sortedProps.map((p) => RecentProperty(
        id: p.id,
        code: p.propertyCode ?? '',
        title: p.title ?? '',
        area: p.areaId ?? '',
        price: p.price ?? 0.0,
        status: p.propertyStatusName ?? 'N/A',
        areaName: p.areaName ?? 'N/A',
        listingType: p.listingTypeName ?? 'Sale',
        createdBy: p.createdByName ?? 'System',
        createdAt: p.createdAt?.toString() ?? '',
      )).toList();
    }

    final allowedReqIds = localReqs.map((r) => r.id).toSet();
    final allowedClientNames = localReqs.map((r) => r.clientName.toLowerCase()).toSet();

    bool isAllowedItem(String? reqId, String? clientName) {
      if (reqId != null && reqId.isNotEmpty) return allowedReqIds.contains(reqId);
      if (clientName != null && clientName.isNotEmpty) return allowedClientNames.contains(clientName.toLowerCase());
      return false;
    }

    bool isFollowupAllowedItem(String? reqId, String? clientName) {
      if (!isAllowedItem(reqId, clientName)) return false;
      if (reqId != null && reqId.isNotEmpty) {
        final match = localReqs.where((r) => r.id == reqId).firstOrNull;
        if (match != null) {
          final s = match.status ?? '';
          return s == 'Follow-up' || s == 'Re-Followup';
        }
      }
      if (clientName != null && clientName.isNotEmpty) {
        final match = localReqs.where((r) => r.clientName.toLowerCase() == clientName.toLowerCase()).firstOrNull;
        if (match != null) {
          final s = match.status ?? '';
          return s == 'Follow-up' || s == 'Re-Followup';
        }
      }
      return true;
    }

    if (cachedData != null) {
      final updatedSummary = DashboardSummary(
        totalProperties: cachedData.summary.totalProperties,
        available: cachedData.summary.available,
        sold: resaleSiteVisits,
        rented: rentalSiteVisits,
        requirements: rentalReqs + resaleReqs,
        users: cachedData.summary.users,
        rentalAvailable: cachedData.summary.rentalAvailable,
        resaleAvailable: cachedData.summary.resaleAvailable,
        rentalRented: rentalSiteVisits,
        resaleSold: resaleSiteVisits,
        rentalRequirements: rentalReqs,
        resaleRequirements: resaleReqs,
        rentalWonRequirements: rentalWonReqs,
        resaleWonRequirements: resaleWonReqs,
        totalPropertiesTrend: cachedData.summary.totalPropertiesTrend,
        availableTrend: cachedData.summary.availableTrend,
        soldTrend: cachedData.summary.soldTrend,
        rentedTrend: cachedData.summary.rentedTrend,
        requirementsTrend: cachedData.summary.requirementsTrend,
        topBroker: cachedData.summary.topBroker,
        topArea: cachedData.summary.topArea,
        topProperty: cachedData.summary.topProperty,
        monthlyGrowth: cachedData.summary.monthlyGrowth,
      );

      final filteredFollowups = cachedData.followups.where((f) =>
        isFollowupAllowedItem(f.requirementId, f.requirementCustomerName)
      ).toList();

      final filteredSiteVisits = cachedData.siteVisits.where((sv) =>
        isAllowedItem(sv.requirementId, sv.requirementCustomerName)
      ).toList();

      return DashboardData(
        summary: updatedSummary,
        activity: cachedData.activity,
        recentProperties: allRecentPropsFromLocal.isNotEmpty ? allRecentPropsFromLocal : cachedData.recentProperties,
        checklist: cachedData.checklist,
        followups: filteredFollowups,
        siteVisits: filteredSiteVisits,
      );
    }

    // Fallback if cache is completely empty on first launch
    final data = await _dashboardService.getDashboardData();
    final model = DashboardData.fromJson(data);
    await _coordinator.dashboardLocal.saveDashboard(model.toLocal());

    final updatedSummary = DashboardSummary(
      totalProperties: model.summary.totalProperties,
      available: model.summary.available,
      sold: resaleSiteVisits,
      rented: rentalSiteVisits,
      requirements: rentalReqs + resaleReqs,
      users: model.summary.users,
      rentalAvailable: model.summary.rentalAvailable,
      resaleAvailable: model.summary.resaleAvailable,
      rentalRented: rentalSiteVisits,
      resaleSold: resaleSiteVisits,
      rentalRequirements: rentalReqs,
      resaleRequirements: resaleReqs,
      rentalWonRequirements: rentalWonReqs,
      resaleWonRequirements: resaleWonReqs,
      totalPropertiesTrend: model.summary.totalPropertiesTrend,
      availableTrend: model.summary.availableTrend,
      soldTrend: model.summary.soldTrend,
      rentedTrend: model.summary.rentedTrend,
      requirementsTrend: model.summary.requirementsTrend,
      topBroker: model.summary.topBroker,
      topArea: model.summary.topArea,
      topProperty: model.summary.topProperty,
      monthlyGrowth: model.summary.monthlyGrowth,
    );

    final filteredFollowups = model.followups.where((f) =>
      isAllowedItem(f.requirementId, f.requirementCustomerName)
    ).toList();

    final filteredSiteVisits = model.siteVisits.where((sv) =>
      isAllowedItem(sv.requirementId, sv.requirementCustomerName)
    ).toList();

    return DashboardData(
      summary: updatedSummary,
      activity: model.activity,
      recentProperties: allRecentPropsFromLocal.isNotEmpty ? allRecentPropsFromLocal : model.recentProperties,
      checklist: model.checklist,
      followups: filteredFollowups,
      siteVisits: filteredSiteVisits,
    );
  }

  void _triggerBackgroundDashboardRefresh() {
    final last = _lastRefreshAt;
    if (_refreshInFlight != null) return;
    if (last != null && DateTime.now().difference(last) < _minRefreshInterval) {
      return;
    }

    _lastRefreshAt = DateTime.now();
    final start = DateTime.now();
    _refreshInFlight = _dashboardService.getDashboardData().then((response) async {
      final networkMs = DateTime.now().difference(start).inMilliseconds;

      final parseStart = DateTime.now();
      final freshData = DashboardData.fromJson(response);
      final jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;

      final writeStart = DateTime.now();
      // Save locally to dashboard local table
      await _coordinator.dashboardLocal.saveDashboard(freshData.toLocal());
      
      // Also synchronize structured followups table inside Isar
      final listData = response['followups'] as List? ?? [];
      final freshFollowups = listData.map((item) => DashboardFollowup.fromJson(item)).toList();
      final localEntities = freshFollowups.map((f) => f.toLocal('System')).toList();
      await _coordinator.followupLocal.saveFollowups(localEntities);
      final isarWriteMs = DateTime.now().difference(writeStart).inMilliseconds;

      final totalMs = DateTime.now().difference(start).inMilliseconds;
      PerformanceLogger().logMetric(
        operation: 'DashboardRepository.getDashboardData (background refresh)',
        networkMs: networkMs,
        jsonParseMs: jsonParseMs,
        isarWriteMs: isarWriteMs,
        totalMs: totalMs,
      );

      _coordinator.refreshDashboard();
    }).catchError((_) {}).whenComplete(() {
      _refreshInFlight = null;
    });
  }
}
