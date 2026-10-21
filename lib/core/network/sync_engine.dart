import 'package:flutter/foundation.dart';
import '../storage/isar_collections.dart';

/// Represents the result of a diff computation between incoming server data
/// and existing local storage.
class SyncDiffResult<T> {
  final List<T> toInsert;
  final List<T> toUpdate;
  final List<String> toDelete;
  final int unchangedCount;

  const SyncDiffResult({
    required this.toInsert,
    required this.toUpdate,
    required this.toDelete,
    required this.unchangedCount,
  });

  bool get hasChanges => toInsert.isNotEmpty || toUpdate.isNotEmpty || toDelete.isNotEmpty;
  int get totalChanges => toInsert.length + toUpdate.length + toDelete.length;

  @override
  String toString() =>
      'SyncDiffResult(toInsert: ${toInsert.length}, toUpdate: ${toUpdate.length}, toDelete: ${toDelete.length}, unchanged: $unchangedCount)';
}

/// Generic, high-performance incremental sync diffing and batching engine.
///
/// Prevents main-isolate UI freezing by:
/// 1. Skipping writes entirely when records are unchanged.
/// 2. Performing in-place updates without clearing tables.
/// 3. Chunking large writes into safe batches (default 100).
/// 4. Preserving existing Isar IDs for O(1) in-place row replacements.
/// 5. Respecting offline outbox mutations to prevent deleting local creations.
class SyncEngine {
  static const int defaultBatchSize = 100;

  /// Pure diff computation between server items and local repository items.
  static SyncDiffResult<T> computeDiff<T>({
    required List<T> serverItems,
    required Map<String, T> localItems,
    required String Function(T) getId,
    required bool Function(T a, T b) isEqual,
    Set<String> pendingOutboxIds = const {},
    void Function(T serverItem, T localItem)? preserveLocalMetadata,
    bool shouldReconcileDeletions = true,
  }) {
    final toInsert = <T>[];
    final toUpdate = <T>[];
    final serverIds = <String>{};
    int unchangedCount = 0;

    for (final sItem in serverItems) {
      final id = getId(sItem);
      serverIds.add(id);

      final localItem = localItems[id];
      if (localItem == null) {
        toInsert.add(sItem);
      } else {
        if (preserveLocalMetadata != null) {
          preserveLocalMetadata(sItem, localItem);
        }
        if (isEqual(localItem, sItem)) {
          unchangedCount++;
        } else {
          toUpdate.add(sItem);
        }
      }
    }

    final toDelete = <String>[];
    if (shouldReconcileDeletions && serverItems.isNotEmpty) {
      for (final localId in localItems.keys) {
        if (!serverIds.contains(localId) && !pendingOutboxIds.contains(localId)) {
          toDelete.add(localId);
        }
      }
    }

    return SyncDiffResult<T>(
      toInsert: toInsert,
      toUpdate: toUpdate,
      toDelete: toDelete,
      unchangedCount: unchangedCount,
    );
  }

  /// Applies the diff in batches to avoid holding write locks or freezing isolates.
  static Future<int> applyBatchedWrites<T>({
    required SyncDiffResult<T> diff,
    required Future<void> Function(List<T> batch) putBatch,
    required Future<void> Function(List<String> ids) deleteBatch,
    int batchSize = defaultBatchSize,
  }) async {
    if (!diff.hasChanges) return 0;

    final allToPut = [...diff.toInsert, ...diff.toUpdate];
    for (var i = 0; i < allToPut.length; i += batchSize) {
      final end = (i + batchSize < allToPut.length) ? i + batchSize : allToPut.length;
      final batch = allToPut.sublist(i, end);
      await putBatch(batch);
    }

    if (diff.toDelete.isNotEmpty) {
      for (var i = 0; i < diff.toDelete.length; i += batchSize) {
        final end = (i + batchSize < diff.toDelete.length) ? i + batchSize : diff.toDelete.length;
        final batch = diff.toDelete.sublist(i, end);
        await deleteBatch(batch);
      }
    }

    return diff.totalChanges;
  }

  // ==========================================
  // Dedicated Field-Level Entity Comparators
  // ==========================================

  static bool arePropertiesEqual(PropertyLocal a, PropertyLocal b) {
    if (identical(a, b)) return true;
    return a.id == b.id &&
        a.propertyCode == b.propertyCode &&
        a.title == b.title &&
        a.price == b.price &&
        a.deposit == b.deposit &&
        a.maintenance == b.maintenance &&
        a.listingTypeId == b.listingTypeId &&
        a.propertyStatusId == b.propertyStatusId &&
        a.categoryId == b.categoryId &&
        a.propertyTypeId == b.propertyTypeId &&
        a.configurationId == b.configurationId &&
        a.cityId == b.cityId &&
        a.areaId == b.areaId &&
        a.pincode == b.pincode &&
        a.address == b.address &&
        a.landmark == b.landmark &&
        a.superBuiltupArea == b.superBuiltupArea &&
        a.carpetArea == b.carpetArea &&
        a.plotArea == b.plotArea &&
        a.bedrooms == b.bedrooms &&
        a.bathrooms == b.bathrooms &&
        a.balconies == b.balconies &&
        a.parking == b.parking &&
        a.floorNo == b.floorNo &&
        a.totalFloor == b.totalFloor &&
        a.ageOfProperty == b.ageOfProperty &&
        a.possessionDate == b.possessionDate &&
        a.furnishingTypeId == b.furnishingTypeId &&
        a.facingTypeId == b.facingTypeId &&
        a.ownershipTypeId == b.ownershipTypeId &&
        a.ownerName == b.ownerName &&
        a.ownerMobile == b.ownerMobile &&
        a.brokerName == b.brokerName &&
        a.remarks == b.remarks &&
        a.blockWing == b.blockWing &&
        a.flatNo == b.flatNo &&
        a.isVerified == b.isVerified &&
        a.description == b.description &&
        a.portalStatus == b.portalStatus &&
        a.adminId == b.adminId &&
        a.organizationId == b.organizationId &&
        listEquals(a.images, b.images) &&
        listEquals(a.amenities, b.amenities) &&
        listEquals(a.videos, b.videos);
  }

  static bool areRequirementsEqual(RequirementLocal a, RequirementLocal b) {
    if (identical(a, b)) return true;
    return a.id == b.id &&
        a.clientName == b.clientName &&
        a.clientMobile == b.clientMobile &&
        a.categoryId == b.categoryId &&
        a.propertyTypeId == b.propertyTypeId &&
        a.configurationId == b.configurationId &&
        a.minBudget == b.minBudget &&
        a.maxBudget == b.maxBudget &&
        a.minArea == b.minArea &&
        a.maxArea == b.maxArea &&
        a.status == b.status &&
        a.notes == b.notes &&
        a.remarks == b.remarks &&
        a.budget == b.budget &&
        a.adminId == b.adminId &&
        a.assignedTo == b.assignedTo &&
        a.assigneeName == b.assigneeName &&
        a.createdBy == b.createdBy &&
        a.creatorName == b.creatorName &&
        a.organizationId == b.organizationId &&
        a.listingTypeId == b.listingTypeId &&
        a.leadSource == b.leadSource &&
        a.referralName == b.referralName &&
        a.nextFollowupDate == b.nextFollowupDate &&
        listEquals(a.areaIds, b.areaIds) &&
        listEquals(a.areaNames, b.areaNames) &&
        listEquals(a.configurationIds, b.configurationIds) &&
        listEquals(a.propertyTypeIds, b.propertyTypeIds) &&
        listEquals(a.furnishingIds, b.furnishingIds) &&
        listEquals(a.facingIds, b.facingIds);
  }

  static bool areBuildersEqual(BuilderLocal a, BuilderLocal b) {
    if (identical(a, b)) return true;
    return a.id == b.id &&
        a.companyName == b.companyName &&
        a.contactPerson == b.contactPerson &&
        a.mobile == b.mobile &&
        a.email == b.email &&
        a.tier == b.tier &&
        a.remarks == b.remarks &&
        listEquals(a.activeProjects, b.activeProjects);
  }

  static bool areOwnersEqual(OwnerLocal a, OwnerLocal b) {
    if (identical(a, b)) return true;
    return a.id == b.id &&
        a.name == b.name &&
        a.mobile == b.mobile &&
        a.email == b.email &&
        a.address == b.address &&
        a.remarks == b.remarks;
  }

  static bool areClientsEqual(ClientLocal a, ClientLocal b) {
    if (identical(a, b)) return true;
    return a.id == b.id &&
        a.name == b.name &&
        a.mobile == b.mobile &&
        a.email == b.email &&
        a.stage == b.stage &&
        a.source == b.source &&
        a.assignedAgent == b.assignedAgent &&
        a.remarks == b.remarks;
  }

  static bool areFollowupsEqual(FollowupLocal a, FollowupLocal b) {
    if (identical(a, b)) return true;
    return a.id == b.id &&
        a.propertyId == b.propertyId &&
        a.requirementId == b.requirementId &&
        a.clientName == b.clientName &&
        a.mobile == b.mobile &&
        a.followupDate == b.followupDate &&
        a.status == b.status &&
        a.notes == b.notes &&
        a.createdBy == b.createdBy;
  }

  static bool areDashboardsEqual(DashboardLocal a, DashboardLocal b) {
    if (identical(a, b)) return true;
    return a.activityJson == b.activityJson &&
        a.recentPropertiesJson == b.recentPropertiesJson &&
        a.checklistJson == b.checklistJson &&
        a.followupsJson == b.followupsJson &&
        a.siteVisitsJson == b.siteVisitsJson &&
        a.summary.totalProperties == b.summary.totalProperties &&
        a.summary.available == b.summary.available &&
        a.summary.sold == b.summary.sold &&
        a.summary.rented == b.summary.rented &&
        a.summary.requirements == b.summary.requirements &&
        a.summary.users == b.summary.users &&
        a.summary.rentalAvailable == b.summary.rentalAvailable &&
        a.summary.resaleAvailable == b.summary.resaleAvailable &&
        a.summary.rentalRented == b.summary.rentalRented &&
        a.summary.resaleSold == b.summary.resaleSold &&
        a.summary.rentalRequirements == b.summary.rentalRequirements &&
        a.summary.resaleRequirements == b.summary.resaleRequirements;
  }

  // ========================================================
  // Multi-Tier Deterministic Conflict Resolution Pipeline
  // ========================================================

  /// Resolves conflicts between a local uncommitted mutation and an incoming
  /// server update according to the canonical Step 9 pipeline:
  /// 1. Field-Level Merge (non-overlapping changes)
  /// 2. Version Counter Comparison (higher version counter wins)
  /// 3. Timestamp Fallback (LWW)
  /// 4. Deterministic Tie-Break (lexicographical comparison)
  static ConflictResolutionResult<PropertyLocal> resolvePropertyConflict({
    required PropertyLocal local,
    required PropertyLocal server,
    required Set<String> localModifiedFields,
    required Set<String> serverModifiedFields,
    int? localVersion,
    int? serverVersion,
    DateTime? localEditedAt,
    DateTime? serverUpdatedAt,
  }) {
    // Tier 1: Field-Level Merge if modified fields are disjoint
    final intersection = localModifiedFields.intersection(serverModifiedFields);
    if (intersection.isEmpty && localModifiedFields.isNotEmpty && serverModifiedFields.isNotEmpty) {
      final merged = _cloneProperty(server);
      final mergedFieldsList = <String>[];

      for (final field in localModifiedFields) {
        _copyPropertyField(from: local, to: merged, field: field);
        mergedFieldsList.add(field);
      }

      return ConflictResolutionResult<PropertyLocal>(
        winner: ConflictWinner.merged,
        tier: 'FIELD_MERGE',
        resolvedItem: merged,
        mergedFields: mergedFieldsList,
        reason: 'Clean field merge of non-overlapping changes: ${mergedFieldsList.join(", ")}',
      );
    }

    // Tier 2: Version Counter Comparison on colliding fields
    if (localVersion != null && serverVersion != null && localVersion != serverVersion) {
      if (serverVersion > localVersion) {
        return ConflictResolutionResult<PropertyLocal>(
          winner: ConflictWinner.server,
          tier: 'VERSION_COUNTER',
          resolvedItem: server,
          reason: 'Server version ($serverVersion) dominates local version ($localVersion)',
        );
      } else {
        return ConflictResolutionResult<PropertyLocal>(
          winner: ConflictWinner.local,
          tier: 'VERSION_COUNTER',
          resolvedItem: local,
          reason: 'Local version ($localVersion) dominates server version ($serverVersion)',
        );
      }
    }

    // Tier 3: Timestamp Fallback (Last-Write-Wins)
    final lTime = localEditedAt ?? local.createdAt;
    final sTime = serverUpdatedAt ?? server.createdAt;

    if (sTime.isAfter(lTime)) {
      return ConflictResolutionResult<PropertyLocal>(
        winner: ConflictWinner.server,
        tier: 'TIMESTAMP_LWW',
        resolvedItem: server,
        reason: 'Server timestamp ($sTime) is newer than local timestamp ($lTime)',
      );
    } else if (lTime.isAfter(sTime)) {
      return ConflictResolutionResult<PropertyLocal>(
        winner: ConflictWinner.local,
        tier: 'TIMESTAMP_LWW',
        resolvedItem: local,
        reason: 'Local timestamp ($lTime) is newer than server timestamp ($sTime)',
      );
    }

    // Tier 4: Deterministic Tie-Break (Equal timestamps)
    final tieBreakServerWins = server.id.compareTo(local.id) >= 0;
    return ConflictResolutionResult<PropertyLocal>(
      winner: tieBreakServerWins ? ConflictWinner.server : ConflictWinner.local,
      tier: 'TIE_BREAK',
      resolvedItem: tieBreakServerWins ? server : local,
      reason: 'Deterministic tie-break on equal timestamps (id comparison)',
    );
  }

  /// Resolves conflicts between a local requirement mutation and a server update.
  static ConflictResolutionResult<RequirementLocal> resolveRequirementConflict({
    required RequirementLocal local,
    required RequirementLocal server,
    required Set<String> localModifiedFields,
    required Set<String> serverModifiedFields,
    int? localVersion,
    int? serverVersion,
    DateTime? localEditedAt,
    DateTime? serverUpdatedAt,
  }) {
    // Tier 1: Field-Level Merge if modified fields are disjoint
    final intersection = localModifiedFields.intersection(serverModifiedFields);
    if (intersection.isEmpty && localModifiedFields.isNotEmpty && serverModifiedFields.isNotEmpty) {
      final merged = _cloneRequirement(server);
      final mergedFieldsList = <String>[];

      for (final field in localModifiedFields) {
        _copyRequirementField(from: local, to: merged, field: field);
        mergedFieldsList.add(field);
      }

      return ConflictResolutionResult<RequirementLocal>(
        winner: ConflictWinner.merged,
        tier: 'FIELD_MERGE',
        resolvedItem: merged,
        mergedFields: mergedFieldsList,
        reason: 'Clean field merge of non-overlapping changes: ${mergedFieldsList.join(", ")}',
      );
    }

    // Tier 2: Version Counter Comparison
    if (localVersion != null && serverVersion != null && localVersion != serverVersion) {
      if (serverVersion > localVersion) {
        return ConflictResolutionResult<RequirementLocal>(
          winner: ConflictWinner.server,
          tier: 'VERSION_COUNTER',
          resolvedItem: server,
          reason: 'Server version ($serverVersion) dominates local version ($localVersion)',
        );
      } else {
        return ConflictResolutionResult<RequirementLocal>(
          winner: ConflictWinner.local,
          tier: 'VERSION_COUNTER',
          resolvedItem: local,
          reason: 'Local version ($localVersion) dominates server version ($serverVersion)',
        );
      }
    }

    // Tier 3: Timestamp Fallback (Last-Write-Wins)
    final lTime = localEditedAt ?? local.createdAt;
    final sTime = serverUpdatedAt ?? server.createdAt;

    if (sTime.isAfter(lTime)) {
      return ConflictResolutionResult<RequirementLocal>(
        winner: ConflictWinner.server,
        tier: 'TIMESTAMP_LWW',
        resolvedItem: server,
        reason: 'Server timestamp ($sTime) is newer than local timestamp ($lTime)',
      );
    } else if (lTime.isAfter(sTime)) {
      return ConflictResolutionResult<RequirementLocal>(
        winner: ConflictWinner.local,
        tier: 'TIMESTAMP_LWW',
        resolvedItem: local,
        reason: 'Local timestamp ($lTime) is newer than server timestamp ($sTime)',
      );
    }

    // Tier 4: Deterministic Tie-Break (Equal timestamps)
    final tieBreakServerWins = server.id.compareTo(local.id) >= 0;
    return ConflictResolutionResult<RequirementLocal>(
      winner: tieBreakServerWins ? ConflictWinner.server : ConflictWinner.local,
      tier: 'TIE_BREAK',
      resolvedItem: tieBreakServerWins ? server : local,
      reason: 'Deterministic tie-break on equal timestamps (id comparison)',
    );
  }

  static PropertyLocal _cloneProperty(PropertyLocal s) {
    final p = PropertyLocal()..id = s.id;
    try { p.propertyCode = s.propertyCode; } catch (_) {}
    try { p.title = s.title; } catch (_) {}
    try { p.description = s.description; } catch (_) {}
    try { p.categoryId = s.categoryId; } catch (_) {}
    try { p.categoryName = s.categoryName; } catch (_) {}
    try { p.propertyTypeId = s.propertyTypeId; } catch (_) {}
    try { p.propertyTypeName = s.propertyTypeName; } catch (_) {}
    try { p.configurationId = s.configurationId; } catch (_) {}
    try { p.configurationName = s.configurationName; } catch (_) {}
    try { p.listingTypeId = s.listingTypeId; } catch (_) {}
    try { p.listingTypeName = s.listingTypeName; } catch (_) {}
    try { p.propertyStatusId = s.propertyStatusId; } catch (_) {}
    try { p.propertyStatusName = s.propertyStatusName; } catch (_) {}
    try { p.cityId = s.cityId; } catch (_) {}
    try { p.cityName = s.cityName; } catch (_) {}
    try { p.areaId = s.areaId; } catch (_) {}
    try { p.areaName = s.areaName; } catch (_) {}
    try { p.pincode = s.pincode; } catch (_) {}
    try { p.address = s.address; } catch (_) {}
    try { p.landmark = s.landmark; } catch (_) {}
    try { p.latitude = s.latitude; } catch (_) {}
    try { p.longitude = s.longitude; } catch (_) {}
    try { p.superBuiltupArea = s.superBuiltupArea; } catch (_) {}
    try { p.carpetArea = s.carpetArea; } catch (_) {}
    try { p.plotArea = s.plotArea; } catch (_) {}
    try { p.price = s.price; } catch (_) {}
    try { p.deposit = s.deposit; } catch (_) {}
    try { p.maintenance = s.maintenance; } catch (_) {}
    try { p.furnishingTypeId = s.furnishingTypeId; } catch (_) {}
    try { p.furnishingTypeName = s.furnishingTypeName; } catch (_) {}
    try { p.facingTypeId = s.facingTypeId; } catch (_) {}
    try { p.facingTypeName = s.facingTypeName; } catch (_) {}
    try { p.ownershipTypeId = s.ownershipTypeId; } catch (_) {}
    try { p.ownershipTypeName = s.ownershipTypeName; } catch (_) {}
    try { p.bedrooms = s.bedrooms; } catch (_) {}
    try { p.bathrooms = s.bathrooms; } catch (_) {}
    try { p.balconies = s.balconies; } catch (_) {}
    try { p.parking = s.parking; } catch (_) {}
    try { p.floorNo = s.floorNo; } catch (_) {}
    try { p.totalFloor = s.totalFloor; } catch (_) {}
    try { p.ageOfProperty = s.ageOfProperty; } catch (_) {}
    try { p.possessionDate = s.possessionDate; } catch (_) {}
    try { p.ownerName = s.ownerName; } catch (_) {}
    try { p.ownerMobile = s.ownerMobile; } catch (_) {}
    try { p.brokerName = s.brokerName; } catch (_) {}
    try { p.remarks = s.remarks; } catch (_) {}
    try { p.blockWing = s.blockWing; } catch (_) {}
    try { p.flatNo = s.flatNo; } catch (_) {}
    try { p.googlePlaceId = s.googlePlaceId; } catch (_) {}
    try { p.brokerageTypeId = s.brokerageTypeId; } catch (_) {}
    try { p.brokerageTypeName = s.brokerageTypeName; } catch (_) {}
    try { p.isVerified = s.isVerified; } catch (_) {}
    try { p.createdBy = s.createdBy; } catch (_) {}
    try { p.createdByName = s.createdByName; } catch (_) {}
    try { p.createdAt = s.createdAt; } catch (_) {}
    try { p.images = List<String>.from(s.images); } catch (_) {}
    try { p.amenities = List<String>.from(s.amenities); } catch (_) {}
    try { p.videos = List<String>.from(s.videos); } catch (_) {}
    try { p.adminId = s.adminId; } catch (_) {}
    try { p.organizationId = s.organizationId; } catch (_) {}
    try { p.portalStatus = s.portalStatus; } catch (_) {}
    p.isarId = s.isarId;
    return p;
  }

  static void _copyPropertyField({
    required PropertyLocal from,
    required PropertyLocal to,
    required String field,
  }) {
    switch (field) {
      case 'title':
        to.title = from.title;
        break;
      case 'price':
        to.price = from.price;
        break;
      case 'deposit':
        to.deposit = from.deposit;
        break;
      case 'maintenance':
        to.maintenance = from.maintenance;
        break;
      case 'description':
        to.description = from.description;
        break;
      case 'propertyStatusId':
      case 'status':
        to.propertyStatusId = from.propertyStatusId;
        to.propertyStatusName = from.propertyStatusName;
        break;
      case 'listingTypeId':
        to.listingTypeId = from.listingTypeId;
        to.listingTypeName = from.listingTypeName;
        break;
      case 'ownerName':
        to.ownerName = from.ownerName;
        break;
      case 'ownerMobile':
        to.ownerMobile = from.ownerMobile;
        break;
      case 'brokerName':
        to.brokerName = from.brokerName;
        break;
      case 'remarks':
        to.remarks = from.remarks;
        break;
      case 'bedrooms':
        to.bedrooms = from.bedrooms;
        break;
      case 'bathrooms':
        to.bathrooms = from.bathrooms;
        break;
      case 'images':
        to.images = List<String>.from(from.images);
        break;
      case 'amenities':
        to.amenities = List<String>.from(from.amenities);
        break;
      case 'superBuiltupArea':
        to.superBuiltupArea = from.superBuiltupArea;
        break;
      case 'carpetArea':
        to.carpetArea = from.carpetArea;
        break;
      case 'portalStatus':
        to.portalStatus = from.portalStatus;
        break;
    }
  }

  static RequirementLocal _cloneRequirement(RequirementLocal s) {
    final r = RequirementLocal()..id = s.id;
    try { r.clientName = s.clientName; } catch (_) {}
    try { r.clientMobile = s.clientMobile; } catch (_) {}
    try { r.categoryId = s.categoryId; } catch (_) {}
    try { r.categoryName = s.categoryName; } catch (_) {}
    try { r.propertyTypeId = s.propertyTypeId; } catch (_) {}
    try { r.propertyTypeName = s.propertyTypeName; } catch (_) {}
    try { r.configurationId = s.configurationId; } catch (_) {}
    try { r.configurationName = s.configurationName; } catch (_) {}
    try { r.configurationIds = s.configurationIds != null ? List<String>.from(s.configurationIds!) : null; } catch (_) {}
    try { r.propertyTypeIds = s.propertyTypeIds != null ? List<String>.from(s.propertyTypeIds!) : null; } catch (_) {}
    try { r.furnishingIds = s.furnishingIds != null ? List<String>.from(s.furnishingIds!) : null; } catch (_) {}
    try { r.facingIds = s.facingIds != null ? List<String>.from(s.facingIds!) : null; } catch (_) {}
    try { r.minBudget = s.minBudget; } catch (_) {}
    try { r.maxBudget = s.maxBudget; } catch (_) {}
    try { r.minArea = s.minArea; } catch (_) {}
    try { r.maxArea = s.maxArea; } catch (_) {}
    try { r.areaIds = List<String>.from(s.areaIds); } catch (_) {}
    try { r.areaNames = List<String>.from(s.areaNames); } catch (_) {}
    try { r.remarks = s.remarks; } catch (_) {}
    try { r.notes = s.notes; } catch (_) {}
    try { r.status = s.status; } catch (_) {}
    try { r.createdAt = s.createdAt; } catch (_) {}
    try { r.budget = s.budget; } catch (_) {}
    try { r.adminId = s.adminId; } catch (_) {}
    try { r.assignedTo = s.assignedTo; } catch (_) {}
    try { r.organizationId = s.organizationId; } catch (_) {}
    try { r.listingTypeId = s.listingTypeId; } catch (_) {}
    try { r.listingTypeName = s.listingTypeName; } catch (_) {}
    try { r.creatorName = s.creatorName; } catch (_) {}
    try { r.assigneeName = s.assigneeName; } catch (_) {}
    try { r.createdBy = s.createdBy; } catch (_) {}
    try { r.leadSource = s.leadSource; } catch (_) {}
    try { r.referralName = s.referralName; } catch (_) {}
    try { r.nextFollowupDate = s.nextFollowupDate; } catch (_) {}
    r.isarId = s.isarId;
    return r;
  }

  static void _copyRequirementField({
    required RequirementLocal from,
    required RequirementLocal to,
    required String field,
  }) {
    switch (field) {
      case 'clientName':
        to.clientName = from.clientName;
        break;
      case 'clientMobile':
        to.clientMobile = from.clientMobile;
        break;
      case 'minBudget':
        to.minBudget = from.minBudget;
        break;
      case 'maxBudget':
        to.maxBudget = from.maxBudget;
        break;
      case 'status':
        to.status = from.status;
        break;
      case 'notes':
        to.notes = from.notes;
        break;
      case 'remarks':
        to.remarks = from.remarks;
        break;
      case 'assignedTo':
        to.assignedTo = from.assignedTo;
        to.assigneeName = from.assigneeName;
        break;
      case 'nextFollowupDate':
        to.nextFollowupDate = from.nextFollowupDate;
        break;
      case 'areaIds':
        to.areaIds = List<String>.from(from.areaIds);
        to.areaNames = List<String>.from(from.areaNames);
        break;
    }
  }
}

/// Outcome classification for conflict resolution.
enum ConflictWinner {
  merged,
  local,
  server,
}

/// Detailed result of a multi-tier conflict resolution operation.
class ConflictResolutionResult<T> {
  final ConflictWinner winner;
  final String tier; // 'FIELD_MERGE', 'VERSION_COUNTER', 'TIMESTAMP_LWW', 'TIE_BREAK'
  final T resolvedItem;
  final List<String> mergedFields;
  final String reason;

  const ConflictResolutionResult({
    required this.winner,
    required this.tier,
    required this.resolvedItem,
    this.mergedFields = const [],
    required this.reason,
  });

  @override
  String toString() =>
      'ConflictResolutionResult(winner: $winner, tier: $tier, merged: $mergedFields, reason: $reason)';
}
