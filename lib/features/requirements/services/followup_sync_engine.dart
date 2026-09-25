import 'package:collection/collection.dart';
import '../../dashboard/models/dashboard_summary.dart';
import '../models/requirement_model.dart';
import '../../auth/models/user_model.dart';
import '../../users/models/user_model.dart' as users_model;

DateTime? parseFollowupDateTime(dynamic raw) {
  if (raw == null) return null;
  String str = raw.toString().trim();
  if (str.isEmpty) return null;

  final parsed = DateTime.tryParse(str);
  if (parsed != null) {
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  try {
    final parts = str.split(RegExp(r'[T\s]'));
    final dateParts = parts[0].split(RegExp(r'[/\\-]'));
    if (dateParts.length == 3) {
      int d, m, y;
      if (dateParts[0].length == 4) {
        y = int.parse(dateParts[0]);
        m = int.parse(dateParts[1]);
        d = int.parse(dateParts[2]);
      } else {
        d = int.parse(dateParts[0]);
        m = int.parse(dateParts[1]);
        y = int.parse(dateParts[2]);
      }
      int h = 0, min = 0, sec = 0;
      if (parts.length > 1 && parts[1].isNotEmpty) {
        final timeParts = parts[1].split(':');
        if (timeParts.length >= 2) {
          h = int.tryParse(timeParts[0]) ?? 0;
          min = int.tryParse(timeParts[1].replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
          if (timeParts.length >= 3) {
            sec = int.tryParse(timeParts[2].replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
          }
        }
      }
      return DateTime(y, m, d, h, min, sec);
    }
  } catch (_) {}

  return null;
}

bool isSameMobile(String m1, String m2) {
  final d1 = m1.replaceAll(RegExp(r'\D'), '');
  final d2 = m2.replaceAll(RegExp(r'\D'), '');
  if (d1.isEmpty || d2.isEmpty) return false;
  if (d1 == d2) return true;
  final s1 = d1.length >= 10 ? d1.substring(d1.length - 10) : d1;
  final s2 = d2.length >= 10 ? d2.substring(d2.length - 10) : d2;
  return s1 == s2;
}

bool isSiteVisitStatus(String? statusStr) {
  if (statusStr == null) return false;
  final s = statusStr.trim().toLowerCase();
  if (s.contains('done')) return false;
  return s.contains('site visit') || s.contains('sitevisit') || s == 'sv' || s.startsWith('site visit');
}

bool isFollowupStatus(String? statusStr) {
  if (statusStr == null) return false;
  final s = statusStr.trim().toLowerCase();
  return s == 'follow-up' || s == 'followup' || s == 're-followup' || s == 'refollowup' || s == 'pending';
}

bool isFollowupLeadStatus(String? statusStr) {
  if (statusStr == null) return false;
  final s = statusStr.trim().toLowerCase().replaceAll('-', '').replaceAll(' ', '');
  return s == 'followup' || s == 'refollowup';
}

String getListingTypeLabel(RequirementModel r) {
  final name = r.listingTypeName ?? '';
  final id = r.listingTypeId ?? '';
  final combined = '$name $id'.toLowerCase();
  if (combined.contains('rent')) {
    return 'Rent';
  } else if (combined.contains('sale') || combined.contains('resale')) {
    return 'Re-Sale';
  }
  return 'Rent';
}

bool _looksLikeUuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value.trim());
}

String? _matchUserName(dynamic u, String needle) {
  if (u == null) return null;
  String id = '';
  String fullName = '';
  if (u is users_model.UserModel) {
    id = u.id;
    fullName = u.fullName;
  } else if (u is UserModel) {
    id = u.id;
    fullName = u.fullName;
  } else if (u is Map) {
    id = u['id']?.toString() ?? '';
    fullName = u['full_name']?.toString() ?? u['fullName']?.toString() ?? '';
  }
  if (id.isNotEmpty && id == needle) {
    return fullName.trim();
  }
  if (fullName.trim().isNotEmpty && fullName.trim().toLowerCase() == needle.toLowerCase()) {
    return fullName.trim();
  }
  return null;
}

String resolveSalespersonName({
  RequirementModel? req,
  DashboardFollowup? followup,
  UserModel? currentUser,
  List<dynamic>? users,
}) {
  if (req != null) {
    if (req.assigneeName != null && req.assigneeName!.trim().isNotEmpty) {
      final name = req.assigneeName!.trim();
      if (name.toLowerCase() != 'unassigned' && name.toLowerCase() != 'system') {
        return name;
      }
    }
    if (req.assignedTo != null && req.assignedTo!.trim().isNotEmpty) {
      final needle = req.assignedTo!.trim();
      if (users != null && users.isNotEmpty) {
        for (final u in users) {
          final matched = _matchUserName(u, needle);
          if (matched != null && matched.isNotEmpty) return matched;
        }
      }
      if (needle.toLowerCase() != 'unassigned' && needle.toLowerCase() != 'system' && !_looksLikeUuid(needle)) {
        return needle;
      }
    }
    final reassignedByName = req.metaCustomFields?['reassigned_by_name']?.toString().trim();
    if (reassignedByName != null && reassignedByName.isNotEmpty && reassignedByName.toLowerCase() != 'system') {
      return reassignedByName;
    }
    if (req.creatorName != null && req.creatorName!.trim().isNotEmpty && req.creatorName!.trim().toLowerCase() != 'system') {
      final needle = req.creatorName!.trim();
      if (users != null && users.isNotEmpty) {
        for (final u in users) {
          final matched = _matchUserName(u, needle);
          if (matched != null && matched.isNotEmpty) return matched;
        }
      }
      if (!_looksLikeUuid(needle)) {
        return needle;
      }
    }
    if (currentUser != null && req.adminId != null && req.adminId == currentUser.id && currentUser.fullName.isNotEmpty) {
      return currentUser.fullName;
    }
    if (req.adminId != null && req.adminId!.isNotEmpty && users != null && users.isNotEmpty) {
      for (final u in users) {
        final matched = _matchUserName(u, req.adminId!);
        if (matched != null && matched.isNotEmpty) return matched;
      }
    }
    if (req.createdBy != null && req.createdBy!.isNotEmpty && users != null && users.isNotEmpty) {
      for (final u in users) {
        final matched = _matchUserName(u, req.createdBy!);
        if (matched != null && matched.isNotEmpty) return matched;
      }
    }
  }

  if (followup != null) {
    if (followup.salespersonName != null &&
        followup.salespersonName!.trim().isNotEmpty &&
        followup.salespersonName!.trim().toLowerCase() != 'system' &&
        followup.salespersonName!.trim().toLowerCase() != 'unassigned') {
      return followup.salespersonName!.trim();
    }
    if (followup.creatorName != null &&
        followup.creatorName!.trim().isNotEmpty &&
        followup.creatorName!.trim().toLowerCase() != 'system') {
      final needle = followup.creatorName!.trim();
      if (users != null && users.isNotEmpty) {
        for (final u in users) {
          final matched = _matchUserName(u, needle);
          if (matched != null && matched.isNotEmpty) return matched;
        }
      }
      if (!_looksLikeUuid(needle)) {
        return needle;
      }
    }
  }

  if (currentUser != null && currentUser.role == 'Sales' && currentUser.fullName.isNotEmpty) {
    return currentUser.fullName;
  }

  return 'Unassigned';
}

class CategorizedFollowupsResult {
  final List<DashboardFollowup> today;
  final List<DashboardFollowup> due;
  final List<DashboardFollowup> future;
  final List<DashboardFollowup> allClients;
  final Map<String, RequirementModel> followupToReqMap;
  final List<String> distinctSalespersons;

  const CategorizedFollowupsResult({
    required this.today,
    required this.due,
    required this.future,
    required this.allClients,
    required this.followupToReqMap,
    required this.distinctSalespersons,
  });
}

class FollowupSyncEngine {
  static RequirementModel? findMatchingRequirement(
    DashboardFollowup f,
    List<RequirementModel> reqsList,
  ) {
    return reqsList.firstWhereOrNull((r) =>
        (f.requirementId != null && f.requirementId!.isNotEmpty && r.id == f.requirementId) ||
        (f.mobile.isNotEmpty && r.clientMobile.isNotEmpty && isSameMobile(r.clientMobile, f.mobile)) ||
        (f.clientName.isNotEmpty && r.clientName.trim().toLowerCase() == f.clientName.trim().toLowerCase()));
  }

  static CategorizedFollowupsResult categorizeFollowups({
    required List<DashboardFollowup> serverFollowups,
    List<DashboardFollowup>? localFollowups,
    required List<RequirementModel> reqsList,
    List<DashboardSiteVisit>? siteVisits,
    required bool isSiteVisitSection,
    required String targetListingType,
    UserModel? currentUser,
    List<dynamic>? users,
    DateTime? customDateFilter,
    String? selectedSalesperson,
  }) {
    final allFollowups = [
      ...?localFollowups,
      ...serverFollowups,
    ];

    final now = DateTime.now();

    final Map<String, RequirementModel> followupToReqMap = {};
    final List<DashboardFollowup> unfilteredToday = [];
    final List<DashboardFollowup> unfilteredDue = [];
    final List<DashboardFollowup> unfilteredFuture = [];
    final List<DashboardFollowup> unfilteredAllClients = [];

    if (isSiteVisitSection) {
      final Map<String, DashboardFollowup> siteVisitsMap = {};

      // 1. Check reqsList for Site Visit status
      for (final req in reqsList) {
        final reqStatus = req.status;
        if (!isSiteVisitStatus(reqStatus)) continue;
        if (getListingTypeLabel(req) != targetListingType) continue;

        final matchingFollowups = allFollowups.where((f) =>
            (f.requirementId != null && f.requirementId!.isNotEmpty && req.id == f.requirementId) ||
            (f.mobile.isNotEmpty && req.clientMobile.isNotEmpty && isSameMobile(req.clientMobile, f.mobile)) ||
            (f.clientName.isNotEmpty && req.clientName.trim().toLowerCase() == req.clientName.trim().toLowerCase())
        ).toList();

        matchingFollowups.sort((a, b) {
          final isASV = isSiteVisitStatus(a.status) ? 1 : 0;
          final isBSV = isSiteVisitStatus(b.status) ? 1 : 0;
          final svComp = isBSV.compareTo(isASV);
          if (svComp != 0) return svComp;

          final dtA = parseFollowupDateTime(a.followupDate) ?? DateTime(1970);
          final dtB = parseFollowupDateTime(b.followupDate) ?? DateTime(1970);
          final comp = dtB.compareTo(dtA);
          if (comp != 0) return comp;

          final isALocal = a.id.startsWith('local_') ? 1 : 0;
          final isBLocal = b.id.startsWith('local_') ? 1 : 0;
          return isBLocal.compareTo(isALocal);
        });

        final matchingF = matchingFollowups.firstOrNull;

        final matchingSv = (siteVisits ?? []).firstWhereOrNull((sv) =>
            (sv.requirementId != null && sv.requirementId!.isNotEmpty && req.id == sv.requirementId) ||
            (sv.requirementCustomerName != null && req.clientName.trim().toLowerCase() == sv.requirementCustomerName!.trim().toLowerCase())
        );

        final dateStr = (req.nextFollowupDate != null && req.nextFollowupDate!.trim().isNotEmpty)
            ? req.nextFollowupDate!
            : (matchingF?.followupDate ?? matchingSv?.visitDate ?? req.createdAt.toIso8601String());
        final notesStr = (matchingF != null && matchingF.notes != null && matchingF.notes!.trim().isNotEmpty)
            ? matchingF.notes!
            : ((matchingSv != null && matchingSv.remarks != null && matchingSv.remarks!.trim().isNotEmpty)
                ? matchingSv.remarks!
                : 'Site visit scheduled');

        final salesman = resolveSalespersonName(
          req: req,
          followup: matchingF,
          currentUser: currentUser,
          users: users,
        );

        final fItem = DashboardFollowup(
          id: matchingF?.id ?? matchingSv?.id ?? 'sv_${req.id}',
          clientName: req.clientName,
          mobile: req.clientMobile,
          followupDate: dateStr,
          notes: notesStr,
          status: reqStatus,
          propertyTitle: matchingF?.propertyTitle ?? matchingSv?.propertyTitle,
          requirementCustomerName: req.clientName,
          requirementId: req.id,
          creatorName: matchingF?.creatorName ?? matchingSv?.creatorName,
          salespersonName: salesman,
        );

        siteVisitsMap[req.id] = fItem;
        followupToReqMap[fItem.id] = req;
        followupToReqMap[req.id] = req;
      }

      // 2. Check siteVisits
      for (final sv in (siteVisits ?? [])) {
        final req = reqsList.firstWhereOrNull((r) =>
            (sv.requirementId != null && sv.requirementId!.isNotEmpty && r.id == sv.requirementId) ||
            (sv.requirementCustomerName != null && r.clientName.trim().toLowerCase() == sv.requirementCustomerName!.trim().toLowerCase()));

        if (req != null) {
          final reqStatus = req.status;
          if (!isSiteVisitStatus(reqStatus)) continue;
          if (getListingTypeLabel(req) != targetListingType) continue;
        } else {
          if (!isSiteVisitStatus(sv.status)) continue;
        }

        final key = sv.requirementId ?? sv.id;
        if (!siteVisitsMap.containsKey(key)) {
          final salesman = resolveSalespersonName(
            req: req,
            currentUser: currentUser,
            users: users,
          );

          final fItem = DashboardFollowup(
            id: sv.id,
            clientName: sv.requirementCustomerName ?? 'Client Site Visit',
            mobile: req?.clientMobile ?? '',
            followupDate: sv.visitDate,
            notes: sv.remarks,
            status: sv.status,
            propertyTitle: sv.propertyTitle,
            requirementCustomerName: sv.requirementCustomerName,
            requirementId: sv.requirementId,
            creatorName: sv.creatorName,
            salespersonName: salesman,
          );

          siteVisitsMap[key] = fItem;
          if (req != null) {
            followupToReqMap[fItem.id] = req;
            followupToReqMap[req.id] = req;
          }
        }
      }

      for (final f in siteVisitsMap.values) {
        final req = reqsList.firstWhereOrNull((r) =>
            (f.requirementId != null && f.requirementId!.isNotEmpty && r.id == f.requirementId) ||
            (f.mobile.isNotEmpty && r.clientMobile.isNotEmpty && isSameMobile(r.clientMobile, f.mobile)) ||
            (f.clientName.isNotEmpty && r.clientName.trim().toLowerCase() == f.clientName.trim().toLowerCase()));

        if (req != null && currentUser != null && currentUser.role == 'Sales') {
          final currentUserName = currentUser.fullName.trim().toLowerCase();
          final isAssignedToUser = (req.assignedTo != null && (req.assignedTo == currentUser.id || (currentUserName.isNotEmpty && req.assignedTo!.trim().toLowerCase() == currentUserName))) ||
              (req.assigneeName != null && currentUserName.isNotEmpty && req.assigneeName!.trim().toLowerCase() == currentUserName);
          final isUnassignedCreatedByUser = (req.assignedTo == null || req.assignedTo!.trim().isEmpty || req.assignedTo!.trim().toLowerCase() == 'unassigned') &&
              (req.createdBy == currentUser.id || (req.creatorName != null && currentUserName.isNotEmpty && req.creatorName!.trim().toLowerCase() == currentUserName));

          if (!isAssignedToUser && !isUnassignedCreatedByUser) continue;
        } else if (currentUser != null && currentUser.role == 'Telecaller') {
          final creatorName = (f.creatorName ?? '').trim().toLowerCase();
          final currentUserName = currentUser.fullName.trim().toLowerCase();
          final matchesCreator = creatorName.isNotEmpty && creatorName == currentUserName;
          final matchesReqCreator = req != null && (req.createdBy == currentUser.id ||
              (req.creatorName ?? '').trim().toLowerCase() == currentUserName);
          if (!matchesCreator && !matchesReqCreator) continue;
        }

        unfilteredAllClients.add(f);

        DateTime? parsed = parseFollowupDateTime(f.followupDate);
        if (parsed != null) {
          final isSameDay = parsed.year == now.year && parsed.month == now.month && parsed.day == now.day;
          final isPending = f.status.toLowerCase() != 'completed' && f.status.toLowerCase() != 'cancelled';
          if (isSameDay) {
            unfilteredToday.add(f);
          }
          if (parsed.isBefore(now) && isPending) {
            unfilteredDue.add(f);
          }
          if (parsed.isAfter(now)) {
            unfilteredFuture.add(f);
          }
        }
      }
    } else {
      // Follow ups Section
      final List<DashboardFollowup> followupItems = [];
      final Set<String> handledReqIds = {};
      final Set<String> handledMobiles = {};

      // Sort allFollowups so the latest followup record comes first
      allFollowups.sort((a, b) {
        final dtA = parseFollowupDateTime(a.followupDate) ?? DateTime(1970);
        final dtB = parseFollowupDateTime(b.followupDate) ?? DateTime(1970);
        return dtB.compareTo(dtA);
      });

      for (final f in allFollowups) {
        if (isSiteVisitStatus(f.status)) continue;

        final req = reqsList.firstWhereOrNull((r) =>
            (f.requirementId != null && f.requirementId!.isNotEmpty && r.id == f.requirementId) ||
            (f.mobile.isNotEmpty && r.clientMobile.isNotEmpty && isSameMobile(r.clientMobile, f.mobile)) ||
            (f.clientName.isNotEmpty && r.clientName.trim().toLowerCase() == f.clientName.trim().toLowerCase()));

        // The Follow-Ups tab must show ONLY those clients who are currently present in the Leads tab.
        if (req == null) continue;

        // Listing type check (Rent vs Re-Sale)
        if (getListingTypeLabel(req) != targetListingType) continue;

        // From those leads, only clients whose current status is Follow-Up or Re-Follow-Up should appear.
        if (!isFollowupLeadStatus(req.status)) continue;

        // Prevent duplicate follow-up records for the same client
        final cleanMob = req.clientMobile.replaceAll(RegExp(r'\D'), '');
        if (handledReqIds.contains(req.id) || (cleanMob.isNotEmpty && handledMobiles.contains(cleanMob))) {
          continue;
        }

        // Role-based filtering for Salesperson:
        // For Sales Users (salespersons), they should see follow-ups only for clients present in their own Leads tab where they created the follow-up.
        if (currentUser != null && (currentUser.role == 'Sales' || currentUser.role == 'Employee')) {
          final currentUserName = currentUser.fullName.trim().toLowerCase();
          final currentUserId = currentUser.id.trim();

          final fCreator = (f.creatorName ?? '').trim().toLowerCase();
          final fSalesperson = (f.salespersonName ?? '').trim().toLowerCase();
          final matchesFCreator = (fCreator.isNotEmpty && fCreator == currentUserName) ||
              (fSalesperson.isNotEmpty && fSalesperson == currentUserName);

          final reqAssigned = (req.assignedTo ?? '').trim();
          final reqAssigneeName = (req.assigneeName ?? '').trim().toLowerCase();
          final reqCreatedBy = (req.createdBy ?? '').trim();
          final reqCreatorName = (req.creatorName ?? '').trim().toLowerCase();

          final matchesReq = (reqAssigned.isNotEmpty && reqAssigned == currentUserId) ||
              (reqAssigneeName.isNotEmpty && reqAssigneeName == currentUserName) ||
              ((reqAssigned.isEmpty || reqAssigned.toLowerCase() == 'unassigned') &&
                  (reqCreatedBy == currentUserId || reqCreatorName == currentUserName));

          if (!matchesReq) continue;
          if (!matchesFCreator && reqCreatedBy != currentUserId && reqCreatorName != currentUserName) {
            continue;
          }
        } else if (currentUser != null && currentUser.role == 'Telecaller') {
          final currentUserName = currentUser.fullName.trim().toLowerCase();
          final currentUserId = currentUser.id.trim();
          final fCreator = (f.creatorName ?? '').trim().toLowerCase();
          final matchesCreator = fCreator.isNotEmpty && fCreator == currentUserName;
          final matchesReqCreator = req.createdBy == currentUserId ||
              (req.creatorName ?? '').trim().toLowerCase() == currentUserName;
          if (!matchesCreator && !matchesReqCreator) continue;
        }

        final salesman = resolveSalespersonName(
          req: req,
          followup: f,
          currentUser: currentUser,
          users: users,
        );

        final itemWithSalesman = f.copyWith(
          salespersonName: salesman,
          followupDate: (req.nextFollowupDate != null && req.nextFollowupDate!.trim().isNotEmpty)
              ? req.nextFollowupDate!
              : f.followupDate,
          status: req.status.isNotEmpty
              ? req.status
              : f.status,
        );

        followupToReqMap[itemWithSalesman.id] = req;
        followupToReqMap[req.id] = req;
        if (itemWithSalesman.requirementId != null) {
          followupToReqMap[itemWithSalesman.requirementId!] = req;
        }
        handledReqIds.add(req.id);
        if (itemWithSalesman.requirementId != null && itemWithSalesman.requirementId!.isNotEmpty) {
          handledReqIds.add(itemWithSalesman.requirementId!);
        }
        if (cleanMob.isNotEmpty) {
          handledMobiles.add(cleanMob);
        }

        followupItems.add(itemWithSalesman);
      }

      // Ensure requirements in reqsList with Follow-up/Re-Followup status are also included
      for (final req in reqsList) {
        final reqStatus = req.status;
        if (!isFollowupLeadStatus(reqStatus)) continue;
        if (isSiteVisitStatus(reqStatus)) continue;
        if (getListingTypeLabel(req) != targetListingType) continue;

        final cleanMob = req.clientMobile.replaceAll(RegExp(r'\D'), '');
        if (handledReqIds.contains(req.id) || (cleanMob.isNotEmpty && handledMobiles.contains(cleanMob))) {
          continue;
        }

        if (currentUser != null && (currentUser.role == 'Sales' || currentUser.role == 'Employee')) {
          final currentUserName = currentUser.fullName.trim().toLowerCase();
          final currentUserId = currentUser.id.trim();
          final reqAssigned = (req.assignedTo ?? '').trim();
          final reqAssigneeName = (req.assigneeName ?? '').trim().toLowerCase();
          final reqCreatedBy = (req.createdBy ?? '').trim();
          final reqCreatorName = (req.creatorName ?? '').trim().toLowerCase();

          final matchesReq = (reqAssigned.isNotEmpty && reqAssigned == currentUserId) ||
              (reqAssigneeName.isNotEmpty && reqAssigneeName == currentUserName) ||
              ((reqAssigned.isEmpty || reqAssigned.toLowerCase() == 'unassigned') &&
                  (reqCreatedBy == currentUserId || reqCreatorName == currentUserName));
          if (!matchesReq) continue;
          if (reqCreatedBy != currentUserId && reqCreatorName != currentUserName) continue;
        } else if (currentUser != null && currentUser.role == 'Telecaller') {
          final currentUserName = currentUser.fullName.trim().toLowerCase();
          if (req.createdBy != currentUser.id && (req.creatorName ?? '').trim().toLowerCase() != currentUserName) {
            continue;
          }
        }

        final salesman = resolveSalespersonName(
          req: req,
          currentUser: currentUser,
          users: users,
        );

        final dateStr = (req.nextFollowupDate != null && req.nextFollowupDate!.trim().isNotEmpty)
            ? req.nextFollowupDate!
            : req.createdAt.toIso8601String();
        final notesStr = (req.remarks != null && req.remarks!.trim().isNotEmpty)
            ? req.remarks!
            : 'Follow-up scheduled';

        final synthItem = DashboardFollowup(
          id: 'fu_${req.id}',
          clientName: req.clientName,
          mobile: req.clientMobile,
          followupDate: dateStr,
          notes: notesStr,
          status: reqStatus,
          requirementCustomerName: req.clientName,
          requirementId: req.id,
          creatorName: req.creatorName,
          salespersonName: salesman,
        );

        followupToReqMap[synthItem.id] = req;
        followupToReqMap[req.id] = req;
        handledReqIds.add(req.id);
        if (cleanMob.isNotEmpty) handledMobiles.add(cleanMob);
        followupItems.add(synthItem);
      }

      // Classify all follow-up items
      for (final item in followupItems) {
        unfilteredAllClients.add(item);

        DateTime? parsed = parseFollowupDateTime(item.followupDate);
        if (parsed == null && item.followupDate.isNotEmpty) {
          try {
            final parts = item.followupDate.split(RegExp(r'[/\\-]'));
            if (parts.length >= 3) {
              final d = int.tryParse(parts[0]);
              final m = int.tryParse(parts[1]);
              final y = int.tryParse(parts[2]);
              if (d != null && m != null && y != null) {
                parsed = DateTime(y, m, d);
              }
            }
          } catch (_) {}
        }

        if (parsed == null) {
          final isPending = item.status.toLowerCase() != 'completed' &&
                            item.status.toLowerCase() != 'cancelled';
          if (isPending) {
            unfilteredDue.add(item);
          }
          continue;
        }

        final isSameDay = parsed.year == now.year && parsed.month == now.month && parsed.day == now.day;
        final isPending = item.status.toLowerCase() != 'completed' &&
                          item.status.toLowerCase() != 'cancelled';

        if (isSameDay) {
          unfilteredToday.add(item);
        }
        if (parsed.isBefore(now) && isPending) {
          unfilteredDue.add(item);
        }
        if (parsed.isAfter(now)) {
          unfilteredFuture.add(item);
        }
      }
    }

    // Sort Lists
    unfilteredToday.sort((a, b) {
      final dtA = parseFollowupDateTime(a.followupDate) ?? DateTime(1970);
      final dtB = parseFollowupDateTime(b.followupDate) ?? DateTime(1970);
      return dtA.compareTo(dtB);
    });

    unfilteredDue.sort((a, b) {
      final dtA = parseFollowupDateTime(a.followupDate) ?? DateTime(1970);
      final dtB = parseFollowupDateTime(b.followupDate) ?? DateTime(1970);
      return dtB.compareTo(dtA);
    });

    unfilteredFuture.sort((a, b) {
      final dtA = parseFollowupDateTime(a.followupDate) ?? DateTime(1970);
      final dtB = parseFollowupDateTime(b.followupDate) ?? DateTime(1970);
      return dtA.compareTo(dtB);
    });

    unfilteredAllClients.sort((a, b) {
      final dtA = parseFollowupDateTime(a.followupDate) ?? DateTime(1970);
      final dtB = parseFollowupDateTime(b.followupDate) ?? DateTime(1970);
      return dtB.compareTo(dtA);
    });

    // Extract Distinct Salespersons
    final Set<String> salespersonsSet = {};
    for (final f in unfilteredAllClients) {
      if (f.salespersonName != null &&
          f.salespersonName!.trim().isNotEmpty &&
          f.salespersonName != 'Unassigned' &&
          f.salespersonName != 'System') {
        salespersonsSet.add(f.salespersonName!.trim());
      }
    }
    final distinctSalespersons = salespersonsSet.toList()..sort();

    // Filter by Selected Salesperson if specified
    List<DashboardFollowup> today = unfilteredToday;
    List<DashboardFollowup> due = unfilteredDue;
    List<DashboardFollowup> future = unfilteredFuture;
    List<DashboardFollowup> allClients = unfilteredAllClients;

    if (selectedSalesperson != null &&
        selectedSalesperson.trim().isNotEmpty &&
        selectedSalesperson != 'ALL' &&
        selectedSalesperson != 'All Salespersons') {
      final targetSalesperson = selectedSalesperson.trim().toLowerCase();
      bool matchesSalesperson(DashboardFollowup f) {
        return (f.salespersonName ?? '').trim().toLowerCase() == targetSalesperson;
      }

      today = today.where(matchesSalesperson).toList();
      due = due.where(matchesSalesperson).toList();
      future = future.where(matchesSalesperson).toList();
      allClients = allClients.where(matchesSalesperson).toList();
    }

    // Filter Future by customDateFilter if specified
    if (customDateFilter != null) {
      future = future.where((f) {
        final parsed = parseFollowupDateTime(f.followupDate);
        if (parsed == null) return false;
        return parsed.year == customDateFilter.year &&
            parsed.month == customDateFilter.month &&
            parsed.day == customDateFilter.day;
      }).toList();
    }

    return CategorizedFollowupsResult(
      today: today,
      due: due,
      future: future,
      allClients: allClients,
      followupToReqMap: followupToReqMap,
      distinctSalespersons: distinctSalespersons,
    );
  }

  static List<DashboardFollowup> filterBySearch({
    required List<DashboardFollowup> items,
    required String query,
    required Map<String, RequirementModel> followupToReqMap,
  }) {
    if (query.trim().isEmpty) return items;
    final q = query.trim().toLowerCase();
    final cleanQ = q.replaceAll(RegExp(r'\D'), '');

    return items.where((f) {
      final name = f.clientName.toLowerCase();
      final mobileDigits = f.mobile.replaceAll(RegExp(r'\D'), '');
      final mobileRaw = f.mobile.toLowerCase();
      final notes = (f.notes ?? '').toLowerCase();
      final propTitle = (f.propertyTitle ?? '').toLowerCase();
      final propCode = (f.propertyCode ?? '').toLowerCase();
      final reqId = (f.requirementId ?? '').toLowerCase();
      final salesperson = (f.salespersonName ?? '').toLowerCase();
      final creator = (f.creatorName ?? '').toLowerCase();

      final req = followupToReqMap[f.id] ??
          (f.requirementId != null ? followupToReqMap[f.requirementId!] : null);

      final config = (req?.configurationName ?? '').toLowerCase();
      final pType = (req?.propertyTypeName ?? req?.categoryName ?? '').toLowerCase();
      final listing = (req?.listingTypeName ?? '').toLowerCase();
      final areas = (req?.displayAreasText ?? '').toLowerCase();
      final remarks = (req?.remarks ?? '').toLowerCase();
      final reqNotes = (req?.notes ?? '').toLowerCase();
      final reqClient = (req?.clientName ?? '').toLowerCase();
      final reqMobileDigits = (req?.clientMobile ?? '').replaceAll(RegExp(r'\D'), '');

      return name.contains(q) ||
          reqClient.contains(q) ||
          (cleanQ.isNotEmpty && (mobileDigits.contains(cleanQ) || reqMobileDigits.contains(cleanQ))) ||
          mobileRaw.contains(q) ||
          notes.contains(q) ||
          propTitle.contains(q) ||
          propCode.contains(q) ||
          reqId.contains(q) ||
          salesperson.contains(q) ||
          creator.contains(q) ||
          config.contains(q) ||
          pType.contains(q) ||
          listing.contains(q) ||
          areas.contains(q) ||
          remarks.contains(q) ||
          reqNotes.contains(q);
    }).toList();
  }
}
