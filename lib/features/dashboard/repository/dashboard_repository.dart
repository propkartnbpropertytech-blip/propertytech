import '../models/dashboard_summary.dart';
import '../services/dashboard_service.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../../core/storage/model_mappers.dart';
import '../../../core/storage/performance_logger.dart';
import '../../../core/security/role_guard.dart';
import 'package:collection/collection.dart';

class DashboardRepository {
  final DashboardService _dashboardService = DashboardService();
  final RepositoryCoordinator _coordinator = RepositoryCoordinator();



  static List<DashboardLocationItem> _inMemoryLeadsLocations = [];
  static Map<String, List<String>> _inMemoryCityAreas = {};
  static Future<void>? _refreshInFlight;
  static DateTime? _lastRefreshAt;
  static const _minRefreshInterval = Duration(seconds: 45);

  Future<DashboardData> getDashboardData({
    bool backgroundRefresh = true,
    bool forceRefresh = false,
  }) async {
    final start = DateTime.now();
    
    DashboardData? cachedData;
    int jsonParseMs = 0;
    int isarReadMs = 0;

    if (!forceRefresh) {
      // Read from local Isar
      final localDashboard = await _coordinator.dashboardLocal.getDashboard();
      isarReadMs = DateTime.now().difference(start).inMilliseconds;
      if (localDashboard != null) {
        final parseStart = DateTime.now();
        cachedData = localDashboard.toModel();
        jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;
      }
    }

    bool usedNetworkKpis = false;
    if (forceRefresh || cachedData == null) {
      try {
        final response = await _dashboardService.getDashboardData();
        final authReport = await _dashboardService.getAuthoritativeReportMetrics();

        DashboardData freshData = DashboardData.fromJson(response);
        if (freshData.leadsLocations.isNotEmpty) {
          _inMemoryLeadsLocations = freshData.leadsLocations;
        }
        if (freshData.cityAreas.isNotEmpty) {
          _inMemoryCityAreas = freshData.cityAreas;
        }
        usedNetworkKpis = true;
        if (authReport.isNotEmpty && authReport['kpis'] is Map) {
          final kpis = authReport['kpis'] as Map<String, dynamic>;
          final totalReqs = (kpis['total_leads'] as num?)?.toInt() ?? freshData.summary.requirements;
          final wonCount = (kpis['closed_won'] as num?)?.toInt() ?? (freshData.summary.rentalWonRequirements + freshData.summary.resaleWonRequirements);

          freshData = DashboardData(
            summary: DashboardSummary(
              totalProperties: freshData.summary.totalProperties,
              available: freshData.summary.available,
              sold: freshData.summary.sold,
              rented: freshData.summary.rented,
              requirements: totalReqs,
              users: freshData.summary.users,
              rentalAvailable: freshData.summary.rentalAvailable,
              resaleAvailable: freshData.summary.resaleAvailable,
              rentalRented: freshData.summary.rentalRented,
              resaleSold: freshData.summary.resaleSold,
              rentalRequirements: freshData.summary.rentalRequirements,
              resaleRequirements: freshData.summary.resaleRequirements,
              rentalWonRequirements: wonCount > 0 ? wonCount : freshData.summary.rentalWonRequirements,
              resaleWonRequirements: freshData.summary.resaleWonRequirements,
              rentalActiveRequirements: freshData.summary.rentalActiveRequirements,
              resaleActiveRequirements: freshData.summary.resaleActiveRequirements,
              totalActiveRequirements: freshData.summary.totalActiveRequirements,
              totalWonRequirements: freshData.summary.totalWonRequirements,
              totalPropertiesTrend: freshData.summary.totalPropertiesTrend,
              availableTrend: freshData.summary.availableTrend,
              soldTrend: freshData.summary.soldTrend,
              rentedTrend: freshData.summary.rentedTrend,
              requirementsTrend: freshData.summary.requirementsTrend,
              topBroker: freshData.summary.topBroker,
              topArea: freshData.summary.topArea,
              topProperty: freshData.summary.topProperty,
              monthlyGrowth: freshData.summary.monthlyGrowth,
            ),
            activity: freshData.activity,
            recentProperties: freshData.recentProperties,
            checklist: freshData.checklist,
            followups: freshData.followups,
            siteVisits: freshData.siteVisits,
            inventoryLocations: freshData.inventoryLocations,
            leadsLocations: freshData.leadsLocations.isNotEmpty
                ? freshData.leadsLocations
                : _inMemoryLeadsLocations,
            cityAreas: freshData.cityAreas.isNotEmpty
                ? freshData.cityAreas
                : _inMemoryCityAreas,
          );
        }

        await _coordinator.dashboardLocal.saveDashboard(freshData.toLocal());
        final listData = (response['followups'] is List)
            ? response['followups'] as List
            : ((response['followupsList'] is List) ? response['followupsList'] as List : []);
        final freshFollowups = listData
            .map((item) => DashboardFollowup.fromJson(item))
            .toList();
        final localEntities = freshFollowups
            .map((f) => f.toLocal('System'))
            .toList();
        await _coordinator.followupLocal.saveFollowups(localEntities);
        cachedData = freshData;
      } catch (_) {
        if (cachedData == null) {
          final localDashboard = await _coordinator.dashboardLocal.getDashboard();
          if (localDashboard != null) {
            cachedData = localDashboard.toModel();
          }
        }
      }
    } else if (backgroundRefresh) {
      _triggerBackgroundDashboardRefresh();
    }

    final totalMs = DateTime.now().difference(start).inMilliseconds;
    PerformanceLogger().logMetric(
      operation: 'DashboardRepository.getDashboardData (local)',
      isarReadMs: isarReadMs,
      jsonParseMs: jsonParseMs,
      totalMs: totalMs,
    );

    if (usedNetworkKpis && cachedData != null) {
      return cachedData;
    }

    // Offline only: reconstruct counts from local cache
    var localReqs = await _coordinator.requirementLocal.getRequirements();
    final currentUser = RoleGuard.currentUser;
    if (currentUser != null) {
      final role = currentUser.role;
      final uName = currentUser.fullName.trim().toLowerCase();
      if (role == 'Admin') {
        localReqs = localReqs.where((r) {
          final isCreator = r.createdBy == currentUser.id ||
              (r.createdBy != null && uName.isNotEmpty && r.createdBy!.trim().toLowerCase() == uName) ||
              (r.creatorName != null && uName.isNotEmpty && r.creatorName!.trim().toLowerCase() == uName);
          return isCreator || r.adminId == currentUser.id;
        }).toList();
      } else if (role == 'Telecaller') {
        localReqs = localReqs.where((r) {
          final isCreator = r.createdBy == currentUser.id ||
              (r.createdBy != null && uName.isNotEmpty && r.createdBy!.trim().toLowerCase() == uName) ||
              (r.creatorName != null && uName.isNotEmpty && r.creatorName!.trim().toLowerCase() == uName);
          return isCreator || r.adminId == currentUser.adminId;
        }).toList();
      } else if (role != 'Super Admin') {
        localReqs = localReqs.where((r) {
          final isCreator = r.createdBy == currentUser.id ||
              (r.createdBy != null && uName.isNotEmpty && r.createdBy!.trim().toLowerCase() == uName) ||
              (r.creatorName != null && uName.isNotEmpty && r.creatorName!.trim().toLowerCase() == uName);
          final isAssignee = (r.assignedTo != null && (r.assignedTo == currentUser.id || (uName.isNotEmpty && r.assignedTo!.trim().toLowerCase() == uName))) ||
              (r.assigneeName != null && uName.isNotEmpty && r.assigneeName!.trim().toLowerCase() == uName);
          return isCreator || isAssignee;
        }).toList();
      }
    }
    int rentalReqs = 0;
    int resaleReqs = 0;
    int rentalWonReqs = 0;
    int resaleWonReqs = 0;
    int rentalSiteVisits = 0;
    int resaleSiteVisits = 0;
    for (final item in localReqs) {
      final statusLower = (item.status ?? '').trim().toLowerCase();
      if (statusLower == 'bin' ||
          statusLower == 'dead' ||
          statusLower == 'suspended' ||
          statusLower == 'not interested' ||
          statusLower.startsWith('rejected')) {
        continue;
      }

      final name = item.listingTypeName ?? '';
      final id = item.listingTypeId ?? '';
      final combined = '$name $id'.toLowerCase();
      final isWon = statusLower == 'won' || statusLower == 'deal won' || statusLower == 'closed';
      final isSiteVisit = item.status == 'Site Visit Done' ||
          item.status == 'Negotiation' ||
          isWon;

      final isResale = combined.contains('sale') || combined.contains('resale');
      final isRent = !isResale;

      if (isRent) {
        if (isWon) {
          rentalWonReqs++;
        } else {
          rentalReqs++;
        }
        if (isSiteVisit) {
          rentalSiteVisits++;
        }
      } else {
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
      allRecentPropsFromLocal = sortedProps.take(16).map((p) => RecentProperty(
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

    final localLocationItems = allLocalProps.map((p) => DashboardLocationItem(
      id: p.id,
      code: p.propertyCode,
      title: p.title,
      cityName: (p.cityName != null && p.cityName!.trim().isNotEmpty && p.cityName != 'N/A')
          ? p.cityName!.trim()
          : 'Ahmedabad',
      areaName: (p.areaName != null && p.areaName!.trim().isNotEmpty && p.areaName != 'N/A')
          ? p.areaName!.trim()
          : 'Ahmedabad',
      categoryName: (p.categoryName != null && p.categoryName!.trim().isNotEmpty)
          ? p.categoryName!.trim()
          : 'Residential',
      listingType: (p.listingTypeName != null && p.listingTypeName!.trim().isNotEmpty)
          ? p.listingTypeName!.trim()
          : 'Rent',
      status: (p.propertyStatusName != null && p.propertyStatusName!.trim().isNotEmpty)
          ? p.propertyStatusName!.trim()
          : 'Available',
      price: p.price ?? 0.0,
      createdAt: p.createdAt,
      configurationName: p.configurationName ?? '',
      propertyTypeName: p.propertyTypeName,
      bedrooms: p.bedrooms,
    )).toList();

    final localLeadLocationItems = <DashboardLocationItem>[];
    for (final r in localReqs) {
      final validAreas = r.areaNames
          .where((a) => a.trim().isNotEmpty && a != 'N/A' && a.toLowerCase() != 'null')
          .map((a) => a.trim())
          .toList();
      final areas = validAreas.isNotEmpty ? validAreas : ['Ahmedabad'];
      final leadPrice = (r.budget != null && r.budget! > 0)
          ? r.budget!
          : (r.maxBudget > 0 ? r.maxBudget : (r.minBudget > 0 ? r.minBudget : 0.0));
      for (final area in areas) {
        localLeadLocationItems.add(DashboardLocationItem(
          id: r.id,
          code: '',
          title: r.clientName,
          cityName: 'Ahmedabad',
          areaName: area,
          categoryName: r.categoryName.trim().isNotEmpty
              ? r.categoryName.trim()
              : 'Residential',
          listingType: (r.listingTypeName != null && r.listingTypeName!.trim().isNotEmpty)
              ? r.listingTypeName!.trim()
              : 'Rent',
          status: r.status.trim().isNotEmpty
              ? r.status.trim()
              : 'Active',
          price: leadPrice,
          createdAt: r.createdAt,
          configurationName: r.configurationName ?? '',
          propertyTypeName: r.propertyTypeName ?? '',
          bedrooms: 0,
        ));
      }
    }

    final allowedReqIds = <String>{};
    final allowedClientNames = <String>{};
    final binnedReqIds = <String>{};
    final binnedClientNames = <String>{};
    final reqStatusById = <String, String>{};
    final reqStatusByName = <String, String>{};

    for (final r in localReqs) {
      final status = (r.status ?? '').trim();
      final name = (r.clientName ?? '').toLowerCase().trim();

      if (status == 'Bin' || status == 'Rejected' || status.startsWith('Rejected') || status == 'Dead') {
        binnedReqIds.add(r.id);
        if (name.isNotEmpty) binnedClientNames.add(name);
        reqStatusById[r.id] = status;
        if (name.isNotEmpty) reqStatusByName[name] = status;
        continue;
      }

      allowedReqIds.add(r.id);
      if (name.isNotEmpty) allowedClientNames.add(name);
      reqStatusById[r.id] = status;
      if (name.isNotEmpty) reqStatusByName[name] = status;
    }

    bool isAllowedItem(String? reqId, String? clientName) {
      if (reqId != null && reqId.isNotEmpty) {
        if (binnedReqIds.contains(reqId)) return false;
        return allowedReqIds.contains(reqId);
      }
      if (clientName != null && clientName.isNotEmpty) {
        final cName = clientName.toLowerCase().trim();
        if (binnedClientNames.contains(cName)) return false;
        return allowedClientNames.contains(cName);
      }
      return false;
    }

    final userRole = (currentUser?.role ?? '').toLowerCase();
    final isFullAccessUser = userRole == 'admin' || userRole == 'super admin';

    bool isFollowupAllowedItem(DashboardFollowup f) {
      // Reject followups belonging to deleted or Bin/Rejected requirements
      if (f.requirementId != null && f.requirementId!.isNotEmpty) {
        final reqId = f.requirementId!;
        if (binnedReqIds.contains(reqId) || reqStatusById[reqId] == 'Bin') {
          return false;
        }
        if (!allowedReqIds.contains(reqId)) {
          return false;
        }
      } else if (f.requirementCustomerName != null && f.requirementCustomerName!.isNotEmpty) {
        final cName = f.requirementCustomerName!.toLowerCase().trim();
        if (binnedClientNames.contains(cName) && !allowedClientNames.contains(cName)) {
          return false;
        }
      } else if (f.clientName.isNotEmpty) {
        final cName = f.clientName.toLowerCase().trim();
        if (binnedClientNames.contains(cName) && !allowedClientNames.contains(cName)) {
          return false;
        }
      }

      // Role-based access check
      if (isFullAccessUser) return true;

      if (currentUser != null) {
        final userId = currentUser.id.toLowerCase();
        final userName = currentUser.fullName.toLowerCase();
        final creator = (f.creatorName ?? '').toLowerCase();
        if (creator == userId || creator == userName) {
          return true;
        }
      }

      if (f.requirementId != null && f.requirementId!.isNotEmpty) {
        return allowedReqIds.contains(f.requirementId);
      }
      if (f.requirementCustomerName != null && f.requirementCustomerName!.isNotEmpty) {
        return allowedClientNames.contains(f.requirementCustomerName!.toLowerCase().trim());
      }
      return false;
    }

    if (cachedData != null) {
      int localRentalAvail = 0;
      int localResaleAvail = 0;
      for (final p in allLocalProps) {
        final st = (p.propertyStatusName ?? '').trim().toLowerCase();
        if (st == 'available' || st == 'to be available') {
          final lt = (p.listingTypeName ?? '').trim().toLowerCase();
          if (lt.contains('rent')) {
            localRentalAvail++;
          } else {
            localResaleAvail++;
          }
        }
      }

      final rentalAvail = cachedData.summary.rentalAvailable > 0
          ? cachedData.summary.rentalAvailable
          : localRentalAvail;
      final resaleAvail = cachedData.summary.resaleAvailable > 0
          ? cachedData.summary.resaleAvailable
          : localResaleAvail;
      final totalAvail = cachedData.summary.available > 0
          ? cachedData.summary.available
          : (rentalAvail + resaleAvail);

      final updatedSummary = DashboardSummary(
        totalProperties: cachedData.summary.totalProperties > 0
            ? cachedData.summary.totalProperties
            : allLocalProps.length,
        available: totalAvail,
        sold: resaleSiteVisits,
        rented: rentalSiteVisits,
        requirements: rentalReqs + resaleReqs,
        users: cachedData.summary.users,
        rentalAvailable: rentalAvail,
        resaleAvailable: resaleAvail,
        rentalRented: rentalSiteVisits,
        resaleSold: resaleSiteVisits,
        rentalRequirements: rentalReqs,
        resaleRequirements: resaleReqs,
        rentalWonRequirements: rentalWonReqs,
        resaleWonRequirements: resaleWonReqs,
        rentalActiveRequirements: cachedData.summary.rentalActiveRequirements > 0
            ? cachedData.summary.rentalActiveRequirements
            : rentalReqs,
        resaleActiveRequirements: cachedData.summary.resaleActiveRequirements > 0
            ? cachedData.summary.resaleActiveRequirements
            : resaleReqs,
        totalActiveRequirements: cachedData.summary.totalActiveRequirements > 0
            ? cachedData.summary.totalActiveRequirements
            : (rentalReqs + resaleReqs),
        totalWonRequirements: cachedData.summary.totalWonRequirements > 0
            ? cachedData.summary.totalWonRequirements
            : (rentalWonReqs + resaleWonReqs),
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

      final allLocalFollowups = await _coordinator.followupLocal.getAllFollowups();
      final localDashFollowups = allLocalFollowups.map((lf) => DashboardFollowup(
        id: lf.id,
        followupDate: lf.followupDate.toIso8601String(),
        clientName: lf.clientName,
        mobile: lf.mobile,
        propertyTitle: lf.propertyTitle,
        propertyCode: lf.propertyCode,
        requirementCustomerName: lf.requirementCustomerName ?? lf.clientName,
        requirementId: lf.requirementId,
        notes: lf.notes,
        status: lf.status,
        creatorName: lf.createdBy,
      )).toList();

      final activeReqModels = localReqs.map((r) => r.toModel()).toList();

      final combinedFollowupsMap = <String, DashboardFollowup>{};

      void addFollowupToMap(DashboardFollowup f) {
        if (!isFollowupAllowedItem(f)) return;

        final req = activeReqModels.firstWhereOrNull((r) =>
            (f.requirementId != null && f.requirementId!.isNotEmpty && r.id == f.requirementId) ||
            (f.mobile.isNotEmpty && r.clientMobile.replaceAll(RegExp(r'\D'), '') == f.mobile.replaceAll(RegExp(r'\D'), '')) ||
            (f.clientName.isNotEmpty && r.clientName.trim().toLowerCase() == f.clientName.trim().toLowerCase()));

        if (req == null) return;
        final reqStatus = req.status;
        if (reqStatus == 'Bin' || reqStatus == 'Won' || reqStatus == 'Closed' || reqStatus.startsWith('Rejected') || reqStatus == 'Dead') {
          return;
        }

        final key = req.id;
        final existing = combinedFollowupsMap[key];
        if (existing == null) {
          combinedFollowupsMap[key] = f;
        } else {
          if (f.id.startsWith('local_') && !existing.id.startsWith('local_')) {
            combinedFollowupsMap[key] = f;
          } else if (!f.id.startsWith('local_') && existing.id.startsWith('local_')) {
            // Keep existing local entry
          } else {
            combinedFollowupsMap[key] = f;
          }
        }
      }

      for (final f in cachedData.followups) {
        addFollowupToMap(f);
      }
      for (final f in localDashFollowups) {
        addFollowupToMap(f);
      }

      // Process followups strictly from the followups table (cached and local offline)

      // Purge any followups tied to binned/deleted requirements, and assign exact listingTypeName to propertyTitle
      final List<String> keysToRemove = [];
      combinedFollowupsMap.forEach((key, f) {
        final req = activeReqModels.firstWhereOrNull((r) =>
            (f.requirementId != null && f.requirementId!.isNotEmpty && r.id == f.requirementId) ||
            (f.mobile.isNotEmpty && r.clientMobile.replaceAll(RegExp(r'\D'), '') == f.mobile.replaceAll(RegExp(r'\D'), '')) ||
            (f.clientName.isNotEmpty && r.clientName.trim().toLowerCase() == f.clientName.trim().toLowerCase()));

        if (req == null) {
          keysToRemove.add(key);
        } else {
          final reqStatus = req.status;
          if (reqStatus == 'Bin' || reqStatus == 'Won' || reqStatus == 'Closed' || reqStatus.startsWith('Rejected') || reqStatus == 'Dead') {
            keysToRemove.add(key);
          } else {
            final listingType = (req.listingTypeName != null && req.listingTypeName!.isNotEmpty)
                ? req.listingTypeName!
                : 'Rent';
            combinedFollowupsMap[key] = DashboardFollowup(
              id: f.id,
              requirementId: req.id,
              clientName: f.clientName.isNotEmpty ? f.clientName : req.clientName,
              mobile: f.mobile.isNotEmpty ? f.mobile : req.clientMobile,
              propertyTitle: listingType,
              propertyCode: f.propertyCode,
              requirementCustomerName: f.requirementCustomerName ?? req.clientName,
              followupDate: f.followupDate,
              notes: f.notes,
              status: f.status,
              creatorName: f.creatorName ?? req.creatorName ?? req.assigneeName,
            );
          }
        }
      });
      for (final k in keysToRemove) {
        combinedFollowupsMap.remove(k);
      }

      final filteredFollowups = combinedFollowupsMap.values.toList();

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
        inventoryLocations: cachedData.inventoryLocations.isNotEmpty
            ? cachedData.inventoryLocations
            : localLocationItems,
        leadsLocations: _inMemoryLeadsLocations.isNotEmpty
            ? _inMemoryLeadsLocations
            : (cachedData.leadsLocations.isNotEmpty
                ? cachedData.leadsLocations
                : localLeadLocationItems),
        cityAreas: _inMemoryCityAreas.isNotEmpty
            ? _inMemoryCityAreas
            : cachedData.cityAreas,
      );
    }

    // Fallback if cache is completely empty on first launch
    final data = await _dashboardService.getDashboardData();
    final model = DashboardData.fromJson(data);
    if (model.leadsLocations.isNotEmpty) {
      _inMemoryLeadsLocations = model.leadsLocations;
    }
    if (model.cityAreas.isNotEmpty) {
      _inMemoryCityAreas = model.cityAreas;
    }
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
      rentalActiveRequirements: model.summary.rentalActiveRequirements > 0
          ? model.summary.rentalActiveRequirements
          : rentalReqs,
      resaleActiveRequirements: model.summary.resaleActiveRequirements > 0
          ? model.summary.resaleActiveRequirements
          : resaleReqs,
      totalActiveRequirements: model.summary.totalActiveRequirements > 0
          ? model.summary.totalActiveRequirements
          : (rentalReqs + resaleReqs),
      totalWonRequirements: model.summary.totalWonRequirements > 0
          ? model.summary.totalWonRequirements
          : (rentalWonReqs + resaleWonReqs),
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
      isFollowupAllowedItem(f)
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
      inventoryLocations: model.inventoryLocations.isNotEmpty
          ? model.inventoryLocations
          : localLocationItems,
      leadsLocations: _inMemoryLeadsLocations.isNotEmpty
          ? _inMemoryLeadsLocations
          : (model.leadsLocations.isNotEmpty
              ? model.leadsLocations
              : localLeadLocationItems),
      cityAreas: _inMemoryCityAreas.isNotEmpty
          ? _inMemoryCityAreas
          : model.cityAreas,
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
      if (freshData.leadsLocations.isNotEmpty) {
        _inMemoryLeadsLocations = freshData.leadsLocations;
      }
      if (freshData.cityAreas.isNotEmpty) {
        _inMemoryCityAreas = freshData.cityAreas;
      }
      final jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;

      final writeStart = DateTime.now();
      // Save locally to dashboard local table
      await _coordinator.dashboardLocal.saveDashboard(freshData.toLocal());
      
      // Also synchronize structured followups table inside Isar
      final listData = (response['followups'] is List)
          ? response['followups'] as List
          : ((response['followupsList'] is List) ? response['followupsList'] as List : []);
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
