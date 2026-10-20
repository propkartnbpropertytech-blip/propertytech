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
}
