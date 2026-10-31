import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'isar_collections.dart';
import 'isar_service.dart';
import 'dart:convert';
import 'web_storage/web_storage_service.dart';
import 'web_storage/web_storage_migration.dart';
import '../search/directory_search.dart';

class PropertyLocalRepository {
  Isar get _isar => IsarService().isar;
  bool get _useInMemory => kIsWeb || !IsarService().isInitialized;

  static final Map<String, PropertyLocal> inMemory = {};

  Future<PropertyLocal?> getPropertyById(String id) async {
    if (_useInMemory) {
      if (inMemory.containsKey(id)) return inMemory[id];
      for (final p in inMemory.values) {
        if (p.id == id || p.propertyCode == id) return p;
      }
      return null;
    }
    final byId = await _isar.propertyLocals.getById(id);
    if (byId != null) return byId;
    return await _isar.propertyLocals.where().propertyCodeEqualTo(id).findFirst();
  }

  Future<PropertyLocal?> getPropertyByIdOrCode(String idOrCode) async {
    final byId = await getPropertyById(idOrCode);
    if (byId != null) return byId;
    if (kIsWeb) {
      for (final p in inMemory.values) {
        if (p.propertyCode == idOrCode) return p;
      }
      return null;
    }
    return await _isar.propertyLocals
        .filter()
        .propertyCodeEqualTo(idOrCode)
        .findFirst();
  }

  Future<List<PropertyLocal>> getProperties({
    String? search,
    String? categoryId,
    String? areaId,
    String? listingTypeId,
    String? createdBy,
    bool? isVerified,
  }) async {
    if (_useInMemory) {
      var list = inMemory.values.toList();
      if (search != null && search.isNotEmpty) {
        final query = search.toLowerCase();
        list = list.where((p) =>
          p.title.toLowerCase().contains(query) ||
          p.propertyCode.toLowerCase().contains(query) ||
          (p.description != null && p.description!.toLowerCase().contains(query))
        ).toList();
      }
      if (categoryId != null) list = list.where((p) => p.categoryId == categoryId).toList();
      if (areaId != null) list = list.where((p) => p.areaId == areaId).toList();
      if (listingTypeId != null) list = list.where((p) => p.listingTypeId == listingTypeId).toList();
      if (createdBy != null) list = list.where((p) => p.createdBy == createdBy).toList();
      if (isVerified != null) list = list.where((p) => p.isVerified == isVerified).toList();
      return list;
    }

    final query = _isar.propertyLocals.filter().idIsNotEmpty();
    QueryBuilder<PropertyLocal, PropertyLocal, QAfterFilterCondition> filtered = query;

    if (search != null && search.isNotEmpty) {
      filtered = filtered.and().group((q) => q
        .titleContains(search, caseSensitive: false)
        .or()
        .propertyCodeContains(search, caseSensitive: false)
        .or()
        .descriptionContains(search, caseSensitive: false)
      );
    }
    if (categoryId != null) filtered = filtered.and().categoryIdEqualTo(categoryId);
    if (areaId != null) filtered = filtered.and().areaIdEqualTo(areaId);
    if (listingTypeId != null) filtered = filtered.and().listingTypeIdEqualTo(listingTypeId);
    if (createdBy != null) filtered = filtered.and().createdByEqualTo(createdBy);
    if (isVerified != null) filtered = filtered.and().isVerifiedEqualTo(isVerified);

    return await filtered.sortByCreatedAtDesc().findAll();
  }

  static Map<String, dynamic> _propertyToMap(PropertyLocal item) {
    return {
      'id': item.id,
      'propertyCode': item.propertyCode,
      'title': item.title,
      'description': item.description,
      'categoryId': item.categoryId,
      'categoryName': item.categoryName,
      'propertyTypeId': item.propertyTypeId,
      'propertyTypeName': item.propertyTypeName,
      'configurationId': item.configurationId,
      'configurationName': item.configurationName,
      'listingTypeId': item.listingTypeId,
      'listingTypeName': item.listingTypeName,
      'propertyStatusId': item.propertyStatusId,
      'propertyStatusName': item.propertyStatusName,
      'cityId': item.cityId,
      'cityName': item.cityName,
      'areaId': item.areaId,
      'areaName': item.areaName,
      'pincode': item.pincode,
      'address': item.address,
      'landmark': item.landmark,
      'latitude': item.latitude,
      'longitude': item.longitude,
      'superBuiltupArea': item.superBuiltupArea,
      'carpetArea': item.carpetArea,
      'plotArea': item.plotArea,
      'price': item.price,
      'deposit': item.deposit,
      'maintenance': item.maintenance,
      'furnishingTypeId': item.furnishingTypeId,
      'furnishingTypeName': item.furnishingTypeName,
      'facingTypeId': item.facingTypeId,
      'facingTypeName': item.facingTypeName,
      'ownershipTypeId': item.ownershipTypeId,
      'ownershipTypeName': item.ownershipTypeName,
      'bedrooms': item.bedrooms,
      'bathrooms': item.bathrooms,
      'balconies': item.balconies,
      'parking': item.parking,
      'floorNo': item.floorNo,
      'totalFloor': item.totalFloor,
      'ageOfProperty': item.ageOfProperty,
      'possessionDate': item.possessionDate?.toIso8601String(),
      'ownerName': kIsWeb ? '' : item.ownerName,
      'ownerMobile': kIsWeb ? '' : item.ownerMobile,
      'brokerName': item.brokerName,
      'remarks': item.remarks,
      'blockWing': item.blockWing,
      'flatNo': item.flatNo,
      'googlePlaceId': item.googlePlaceId,
      'brokerageTypeId': item.brokerageTypeId,
      'brokerageTypeName': item.brokerageTypeName,
      'isVerified': item.isVerified,
      'createdBy': item.createdBy,
      'createdByName': item.createdByName,
      'createdAt': item.createdAt.toIso8601String(),
      'images': item.images,
      'amenities': item.amenities,
      'adminId': item.adminId,
      'organizationId': item.organizationId,
      'portalStatus': item.portalStatus,
    };
  }

  static PropertyLocal _propertyFromMap(Map<String, dynamic> map) {
    return PropertyLocal()
      ..id = map['id']?.toString() ?? ''
      ..propertyCode = map['propertyCode']?.toString() ?? ''
      ..title = map['title']?.toString() ?? ''
      ..description = map['description']?.toString()
      ..categoryId = map['categoryId']?.toString() ?? ''
      ..categoryName = map['categoryName']?.toString() ?? ''
      ..propertyTypeId = map['propertyTypeId']?.toString() ?? ''
      ..propertyTypeName = map['propertyTypeName']?.toString() ?? ''
      ..configurationId = map['configurationId']?.toString()
      ..configurationName = map['configurationName']?.toString()
      ..listingTypeId = map['listingTypeId']?.toString() ?? ''
      ..listingTypeName = map['listingTypeName']?.toString() ?? ''
      ..propertyStatusId = map['propertyStatusId']?.toString() ?? ''
      ..propertyStatusName = map['propertyStatusName']?.toString() ?? ''
      ..cityId = map['cityId']?.toString() ?? ''
      ..cityName = map['cityName']?.toString() ?? ''
      ..areaId = map['areaId']?.toString() ?? ''
      ..areaName = map['areaName']?.toString() ?? ''
      ..pincode = map['pincode']?.toString() ?? ''
      ..address = map['address']?.toString() ?? ''
      ..landmark = map['landmark']?.toString()
      ..latitude = map['latitude'] != null ? double.tryParse(map['latitude'].toString()) : null
      ..longitude = map['longitude'] != null ? double.tryParse(map['longitude'].toString()) : null
      ..superBuiltupArea = map['superBuiltupArea'] != null ? double.tryParse(map['superBuiltupArea'].toString()) : null
      ..carpetArea = map['carpetArea'] != null ? double.tryParse(map['carpetArea'].toString()) : null
      ..plotArea = map['plotArea'] != null ? double.tryParse(map['plotArea'].toString()) : null
      ..price = double.tryParse(map['price']?.toString() ?? '') ?? 0.0
      ..deposit = double.tryParse(map['deposit']?.toString() ?? '') ?? 0.0
      ..maintenance = double.tryParse(map['maintenance']?.toString() ?? '') ?? 0.0
      ..furnishingTypeId = map['furnishingTypeId']?.toString()
      ..furnishingTypeName = map['furnishingTypeName']?.toString()
      ..facingTypeId = map['facingTypeId']?.toString()
      ..facingTypeName = map['facingTypeName']?.toString()
      ..ownershipTypeId = map['ownershipTypeId']?.toString()
      ..ownershipTypeName = map['ownershipTypeName']?.toString()
      ..bedrooms = map['bedrooms'] as int? ?? 0
      ..bathrooms = map['bathrooms'] as int? ?? 0
      ..balconies = map['balconies'] as int? ?? 0
      ..parking = map['parking'] as int? ?? 0
      ..floorNo = map['floorNo'] as int?
      ..totalFloor = map['totalFloor'] as int?
      ..ageOfProperty = map['ageOfProperty'] as int?
      ..possessionDate = map['possessionDate'] != null ? DateTime.tryParse(map['possessionDate'].toString()) : null
      ..ownerName = map['ownerName']?.toString() ?? ''
      ..ownerMobile = map['ownerMobile']?.toString() ?? ''
      ..brokerName = map['brokerName']?.toString()
      ..remarks = map['remarks']?.toString()
      ..blockWing = map['blockWing']?.toString()
      ..flatNo = map['flatNo']?.toString()
      ..googlePlaceId = map['googlePlaceId']?.toString()
      ..brokerageTypeId = map['brokerageTypeId']?.toString()
      ..brokerageTypeName = map['brokerageTypeName']?.toString()
      ..isVerified = map['isVerified'] as bool? ?? false
      ..createdBy = map['createdBy']?.toString() ?? ''
      ..createdByName = map['createdByName']?.toString() ?? 'N/A'
      ..createdAt = DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now()
      ..images = List<String>.from(map['images'] ?? [])
      ..amenities = List<String>.from(map['amenities'] ?? [])
      ..adminId = map['adminId']?.toString()
      ..organizationId = map['organizationId']?.toString()
      ..portalStatus = map['portalStatus']?.toString() ?? 'None';
  }

  Future<void> loadInMemoryCache() async {
    if (!kIsWeb) return;
    try {
      await WebStorageMigration.migrateLegacyLocalStorageIfNeeded();
      final records = await WebStorage().getAllRecords(WebStorageStores.properties);
      for (final jsonStr in records) {
        try {
          final map = jsonDecode(jsonStr);
          if (map is Map<String, dynamic>) {
            final p = _propertyFromMap(map);
            inMemory[p.id] = p;
          }
        } catch (_) {}
      }
      debugPrint("Loaded ${inMemory.length} properties from IndexedDB WebStorage.");
    } catch (e) {
      debugPrint("Error loading cached properties from WebStorage: $e");
    }
  }

  Future<void> _persistBatchAsync(List<PropertyLocal> properties, {bool clearExisting = false}) async {
    if (!kIsWeb) return;
    try {
      if (clearExisting) {
        await WebStorage().clearStore(WebStorageStores.properties);
      }
      if (properties.isEmpty) return;
      final batch = <String, String>{};
      for (final item in properties) {
        batch[item.id] = jsonEncode(_propertyToMap(item));
      }
      await WebStorage().putBatch(WebStorageStores.properties, batch);
    } catch (e) {
      debugPrint("Error persisting properties to WebStorage: $e");
    }
  }

  Future<void> _deleteRecordAsync(String id) async {
    if (!kIsWeb) return;
    try {
      await WebStorage().deleteRecord(WebStorageStores.properties, id);
    } catch (e) {
      debugPrint("Error deleting property from WebStorage: $e");
    }
  }

  Future<void> saveInMemoryCacheOnlyIfChanged() async {
    // Retained for API compatibility. Mutations are persisted incrementally on write.
  }

  Future<void> saveProperties(List<PropertyLocal> properties, {bool clearExisting = false}) async {
    if (_useInMemory) {
      if (clearExisting) {
        inMemory.clear();
      }
      for (final p in properties) {
        inMemory[p.id] = p;
      }
      await _persistBatchAsync(properties, clearExisting: clearExisting);
      return;
    }

    await _isar.writeTxn(() async {
      if (clearExisting) {
        await _isar.propertyLocals.clear();
      }
      await _isar.propertyLocals.putAll(properties);
    });
  }

  Future<void> deleteProperty(String id) async {
    if (_useInMemory) {
      inMemory.remove(id);
      await _deleteRecordAsync(id);
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.propertyLocals.deleteById(id);
    });
  }
}

class RequirementLocalRepository {
  Isar get _isar => IsarService().isar;
  bool get _useInMemory => kIsWeb || !IsarService().isInitialized;

  static final Map<String, RequirementLocal> inMemory = {};
  static final Map<String, Map<String, dynamic>> metaCustomFieldsById = {};
  static final Map<String, String> rejectionRemarksById = {};
  static final Map<String, String> assignedTelecallerIdById = {};
  static final Map<String, DateTime> salesAssignedAtById = {};
  static final Map<String, String> assignedToById = {};
  static final Map<String, String> assigneeNameById = {};

  static void rememberAssignedTo(String id, String? assignedTo) {
    if (id.trim().isEmpty) return;
    if (assignedTo == null || assignedTo.trim().isEmpty) {
      assignedToById.remove(id);
    } else {
      assignedToById[id] = assignedTo.trim();
    }
  }

  static String? getAssignedTo(String id) {
    return assignedToById[id];
  }

  static void rememberAssigneeName(String id, String? name) {
    if (id.trim().isEmpty) return;
    if (name == null || name.trim().isEmpty) {
      assigneeNameById.remove(id);
    } else {
      assigneeNameById[id] = name.trim();
    }
  }

  static String? getAssigneeName(String id) {
    return assigneeNameById[id];
  }

  static void rememberSalesAssignedAt(String id, DateTime? dt) {
    if (id.trim().isEmpty || dt == null) return;
    salesAssignedAtById[id] = dt;
  }

  static DateTime? getSalesAssignedAt(String id) {
    return salesAssignedAtById[id];
  }

  static void rememberAssignedTelecallerId(String id, String? telecallerId) {
    if (id.trim().isEmpty || telecallerId == null || telecallerId.trim().isEmpty) return;
    assignedTelecallerIdById[id] = telecallerId.trim();
  }

  static String? getAssignedTelecallerId(String id) {
    return assignedTelecallerIdById[id];
  }

  static void rememberMetaCustomFields(String id, Map<String, dynamic>? meta) {
    if (id.trim().isEmpty || meta == null || meta.isEmpty) return;
    metaCustomFieldsById[id] = {
      ...?metaCustomFieldsById[id],
      ...meta,
    };
  }

  static void rememberRejectionRemark(String id, String? remark) {
    if (id.trim().isEmpty) return;
    if (remark == null || remark.trim().isEmpty) {
      rejectionRemarksById.remove(id);
    } else {
      rejectionRemarksById[id] = remark.trim();
    }
  }

  static String? getRejectionRemark(String id) {
    return rejectionRemarksById[id];
  }

  Future<RequirementLocal?> getRequirementById(String id) async {
    if (_useInMemory) {
      if (inMemory.containsKey(id)) return inMemory[id];
      for (final r in inMemory.values) {
        if (r.id == id) return r;
      }
      return null;
    }
    return await _isar.requirementLocals.getById(id);
  }

  Future<List<RequirementLocal>> getRequirements({
    String? search,
    String? configurationId,
    String? propertyTypeId,
    String? status,
  }) async {
    if (_useInMemory) {
      var list = inMemory.values.toList();
      if (search != null && search.isNotEmpty) {
        final query = search.toLowerCase();
        list = list.where((r) =>
          r.clientName.toLowerCase().contains(query) ||
          r.clientMobile.contains(query) ||
          (r.remarks != null && r.remarks!.toLowerCase().contains(query))
        ).toList();
      }
      if (configurationId != null) list = list.where((r) => r.configurationId == configurationId).toList();
      if (propertyTypeId != null) list = list.where((r) => r.propertyTypeId == propertyTypeId).toList();
      if (status != null && status != 'All') {
        if (status == 'Rejected') {
          list = list.where((r) =>
            r.status == 'Rejected' ||
            r.status.startsWith('Rejected') ||
            r.status == 'Suspended' ||
            r.status == 'Dead' ||
            r.status == 'Not Interested' ||
            r.status == 'Bin'
          ).toList();
        } else {
          list = list.where((r) => r.status == status).toList();
        }
      }
      return list;
    }

    final query = _isar.requirementLocals.filter().idIsNotEmpty();
    QueryBuilder<RequirementLocal, RequirementLocal, QAfterFilterCondition> filtered = query;

    if (search != null && search.isNotEmpty) {
      filtered = filtered.and().group((q) => q
        .clientNameContains(search, caseSensitive: false)
        .or()
        .clientMobileContains(search)
        .or()
        .remarksContains(search, caseSensitive: false)
      );
    }
    if (configurationId != null) filtered = filtered.and().configurationIdEqualTo(configurationId);
    if (propertyTypeId != null) filtered = filtered.and().propertyTypeIdEqualTo(propertyTypeId);
    if (status != null && status != 'All') filtered = filtered.and().statusEqualTo(status);

    return await filtered.sortByCreatedAtDesc().findAll();
  }

  static Map<String, dynamic> _requirementToMap(RequirementLocal item) {
    return {
      'id': item.id,
      'clientName': item.clientName,
      'clientMobile': item.clientMobile,
      'categoryId': item.categoryId,
      'categoryName': item.categoryName,
      'propertyTypeId': item.propertyTypeId,
      'propertyTypeName': item.propertyTypeName,
      'configurationId': item.configurationId,
      'configurationName': item.configurationName,
      'minBudget': item.minBudget,
      'maxBudget': item.maxBudget,
      'minArea': item.minArea,
      'maxArea': item.maxArea,
      'areaIds': item.areaIds,
      'areaNames': item.areaNames,
      'remarks': item.remarks,
      'notes': item.notes,
      'status': item.status,
      'createdAt': item.createdAt.toIso8601String(),
      'budget': item.budget,
      'adminId': item.adminId,
      'organizationId': item.organizationId,
      'leadSource': item.leadSource,
      'referralName': item.referralName,
      'listingTypeId': item.listingTypeId,
      'listingTypeName': item.listingTypeName,
      'creatorName': item.creatorName,
      'assigneeName': item.assigneeName,
      'createdBy': item.createdBy,
      'assignedTo': item.assignedTo,
      'nextFollowupDate': item.nextFollowupDate,
      if (assignedTelecallerIdById[item.id] != null)
        'assignedTelecallerId': assignedTelecallerIdById[item.id],
      if (metaCustomFieldsById[item.id] != null)
        'metaCustomFields': metaCustomFieldsById[item.id],
      if (rejectionRemarksById[item.id] != null)
        'rejectionRemark': rejectionRemarksById[item.id],
      if (salesAssignedAtById[item.id] != null)
        'salesAssignedAt': salesAssignedAtById[item.id]!.toIso8601String(),
    };
  }

  static RequirementLocal _requirementFromMap(Map<String, dynamic> map) {
    final r = RequirementLocal()
      ..id = map['id']?.toString() ?? ''
      ..clientName = map['clientName']?.toString() ?? ''
      ..clientMobile = map['clientMobile']?.toString() ?? ''
      ..categoryId = map['categoryId']?.toString() ?? ''
      ..categoryName = map['categoryName']?.toString() ?? ''
      ..propertyTypeId = map['propertyTypeId']?.toString()
      ..propertyTypeName = map['propertyTypeName']?.toString()
      ..configurationId = map['configurationId']?.toString()
      ..configurationName = map['configurationName']?.toString()
      ..minBudget = double.tryParse(map['minBudget']?.toString() ?? '') ?? 0.0
      ..maxBudget = double.tryParse(map['maxBudget']?.toString() ?? '') ?? 0.0
      ..minArea = map['minArea'] != null ? double.tryParse(map['minArea'].toString()) : null
      ..maxArea = map['maxArea'] != null ? double.tryParse(map['maxArea'].toString()) : null
      ..areaIds = List<String>.from(map['areaIds'] ?? [])
      ..areaNames = List<String>.from(map['areaNames'] ?? [])
      ..remarks = map['remarks']?.toString()
      ..notes = map['notes']?.toString()
      ..status = map['status']?.toString() ?? 'Active'
      ..createdAt = DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now()
      ..budget = map['budget'] != null ? double.tryParse(map['budget'].toString()) : null
      ..adminId = map['adminId']?.toString()
      ..organizationId = map['organizationId']?.toString()
      ..leadSource = map['leadSource']?.toString()
      ..referralName = map['referralName']?.toString()
      ..listingTypeId = map['listingTypeId']?.toString()
      ..listingTypeName = map['listingTypeName']?.toString()
      ..creatorName = map['creatorName']?.toString()
      ..assigneeName = map['assigneeName']?.toString()
      ..createdBy = map['createdBy']?.toString()
      ..assignedTo = map['assignedTo']?.toString()
      ..nextFollowupDate = map['nextFollowupDate']?.toString();

    final rawTcId = map['assignedTelecallerId'] ?? map['assigned_telecaller_id'] ?? map['telecaller_id'];
    if (rawTcId != null && rawTcId.toString().trim().isNotEmpty) {
      rememberAssignedTelecallerId(r.id, rawTcId.toString().trim());
    }
    if (map['metaCustomFields'] is Map) {
      rememberMetaCustomFields(
        r.id,
        Map<String, dynamic>.from(map['metaCustomFields'] as Map),
      );
    }
    if (map['rejectionRemark'] != null) {
      rememberRejectionRemark(r.id, map['rejectionRemark']?.toString());
    }
    final rawSalesAssignedAt = map['salesAssignedAt']?.toString().trim() ?? '';
    if (rawSalesAssignedAt.isNotEmpty) {
      rememberSalesAssignedAt(r.id, DateTime.tryParse(rawSalesAssignedAt));
    }
    return r;
  }

  Future<void> loadInMemoryCache() async {
    if (!kIsWeb) return;
    try {
      await WebStorageMigration.migrateLegacyLocalStorageIfNeeded();
      final records = await WebStorage().getAllRecords(WebStorageStores.requirements);
      for (final jsonStr in records) {
        try {
          final map = jsonDecode(jsonStr);
          if (map is Map<String, dynamic>) {
            final r = _requirementFromMap(map);
            inMemory[r.id] = r;
          }
        } catch (_) {}
      }
      debugPrint("Loaded ${inMemory.length} requirements from IndexedDB WebStorage.");
    } catch (e) {
      debugPrint("Error loading cached requirements from WebStorage: $e");
    }
  }

  Future<void> _persistBatchAsync(List<RequirementLocal> requirements, {bool clearExisting = false}) async {
    if (!kIsWeb) return;
    try {
      if (clearExisting) {
        await WebStorage().clearStore(WebStorageStores.requirements);
      }
      if (requirements.isEmpty) return;
      final batch = <String, String>{};
      for (final item in requirements) {
        batch[item.id] = jsonEncode(_requirementToMap(item));
      }
      await WebStorage().putBatch(WebStorageStores.requirements, batch);
    } catch (e) {
      debugPrint("Error persisting requirements to WebStorage: $e");
    }
  }

  Future<void> _deleteRecordAsync(String id) async {
    if (!kIsWeb) return;
    try {
      await WebStorage().deleteRecord(WebStorageStores.requirements, id);
    } catch (e) {
      debugPrint("Error deleting requirement from WebStorage: $e");
    }
  }

  Future<void> saveInMemoryCacheOnlyIfChanged() async {
    // Retained for API compatibility. Mutations are persisted incrementally on write.
  }

  Future<void> saveRequirements(List<RequirementLocal> requirements, {bool clearExisting = false}) async {
    if (clearExisting) {
      inMemory.clear();
    }
    for (final r in requirements) {
      inMemory[r.id] = r;
    }
    if (_useInMemory) {
      await _persistBatchAsync(requirements, clearExisting: clearExisting);
      return;
    }

    await _isar.writeTxn(() async {
      if (clearExisting) {
        await _isar.requirementLocals.clear();
      }
      await _isar.requirementLocals.putAll(requirements);
    });
  }

  Future<void> deleteRequirement(String id) async {
    if (_useInMemory) {
      inMemory.remove(id);
      await _deleteRecordAsync(id);
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.requirementLocals.deleteById(id);
    });
  }

  Future<RequirementLocal?> getRequirement(String id) async {
    if (_useInMemory) {
      return inMemory[id];
    }
    return await _isar.requirementLocals.getById(id);
  }
}

class FollowupLocalRepository {
  Isar get _isar => IsarService().isar;
  bool get _useInMemory => kIsWeb || !IsarService().isInitialized;

  static final Map<String, FollowupLocal> inMemory = {};

  static Map<String, dynamic> _followupToMap(FollowupLocal item) {
    return {
      'id': item.id,
      'propertyId': item.propertyId,
      'propertyCode': item.propertyCode,
      'propertyTitle': item.propertyTitle,
      'requirementId': item.requirementId,
      'requirementCustomerName': item.requirementCustomerName,
      'createdBy': item.createdBy,
      'clientName': item.clientName,
      'mobile': item.mobile,
      'followupDate': item.followupDate.toIso8601String(),
      'notes': item.notes,
      'status': item.status,
      'createdAt': item.createdAt.toIso8601String(),
    };
  }

  static FollowupLocal _followupFromMap(Map<String, dynamic> map) {
    return FollowupLocal()
      ..id = map['id']?.toString() ?? ''
      ..propertyId = map['propertyId']?.toString()
      ..propertyCode = map['propertyCode']?.toString()
      ..propertyTitle = map['propertyTitle']?.toString()
      ..requirementId = map['requirementId']?.toString()
      ..requirementCustomerName = map['requirementCustomerName']?.toString()
      ..createdBy = map['createdBy']?.toString() ?? ''
      ..clientName = map['clientName']?.toString() ?? ''
      ..mobile = map['mobile']?.toString() ?? ''
      ..followupDate = DateTime.tryParse(map['followupDate']?.toString() ?? '') ?? DateTime.now()
      ..notes = map['notes']?.toString()
      ..status = map['status']?.toString() ?? 'Pending'
      ..createdAt = DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now();
  }

  Future<void> loadInMemoryCache() async {
    if (!kIsWeb) return;
    try {
      await WebStorageMigration.migrateLegacyLocalStorageIfNeeded();
      final records = await WebStorage().getAllRecords(WebStorageStores.followups);
      for (final jsonStr in records) {
        try {
          final map = jsonDecode(jsonStr);
          if (map is Map<String, dynamic>) {
            final f = _followupFromMap(map);
            inMemory[f.id] = f;
          }
        } catch (_) {}
      }
      debugPrint("Loaded ${inMemory.length} followups from IndexedDB WebStorage.");
    } catch (e) {
      debugPrint("Error loading cached followups from WebStorage: $e");
    }
  }

  Future<void> _persistBatchAsync(List<FollowupLocal> followups, {bool clearExisting = false}) async {
    if (!kIsWeb) return;
    try {
      if (clearExisting) {
        await WebStorage().clearStore(WebStorageStores.followups);
      }
      if (followups.isEmpty) return;
      final batch = <String, String>{};
      for (final item in followups) {
        batch[item.id] = jsonEncode(_followupToMap(item));
      }
      await WebStorage().putBatch(WebStorageStores.followups, batch);
    } catch (e) {
      debugPrint("Error persisting followups to WebStorage: $e");
    }
  }

  Future<void> _deleteRecordAsync(String id) async {
    if (!kIsWeb) return;
    try {
      await WebStorage().deleteRecord(WebStorageStores.followups, id);
    } catch (e) {
      debugPrint("Error deleting followup from WebStorage: $e");
    }
  }

  Future<List<FollowupLocal>> getAllFollowups() async {
    if (_useInMemory) {
      return inMemory.values.toList();
    }
    return await _isar.followupLocals.where().findAll();
  }

  Future<List<FollowupLocal>> getFollowupsByClient(String clientName) async {
    if (_useInMemory) {
      return inMemory.values.where((f) => f.clientName == clientName).toList();
    }

    return await _isar.followupLocals.filter().clientNameEqualTo(clientName).findAll();
  }

  Future<void> saveInMemoryCacheOnlyIfChanged() async {
    // Retained for API compatibility. Mutations are persisted incrementally on write.
  }

  Future<void> saveFollowups(List<FollowupLocal> followups, {bool clearExisting = false}) async {
    if (clearExisting) {
      inMemory.clear();
    }
    for (final f in followups) {
      inMemory[f.id] = f;
    }
    if (_useInMemory) {
      await _persistBatchAsync(followups, clearExisting: clearExisting);
      return;
    }

    await _isar.writeTxn(() async {
      if (clearExisting) {
        await _isar.followupLocals.clear();
      }
      await _isar.followupLocals.putAll(followups);
    });
  }

  Future<void> deleteFollowup(String id) async {
    if (_useInMemory) {
      inMemory.remove(id);
      await _deleteRecordAsync(id);
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.followupLocals.deleteById(id);
    });
  }
}

class BuilderLocalRepository {
  Isar get _isar => IsarService().isar;
  bool get _useInMemory => kIsWeb || !IsarService().isInitialized;

  static final Map<String, BuilderLocal> inMemory = {};

  static Map<String, dynamic> _builderToMap(BuilderLocal b) {
    String? id;
    try { id = b.id; } catch (_) { id = ''; }
    String? companyName;
    try { companyName = b.companyName; } catch (_) { companyName = ''; }
    String? contactPerson;
    try { contactPerson = b.contactPerson; } catch (_) { contactPerson = ''; }
    String? mobile;
    try { mobile = b.mobile; } catch (_) { mobile = ''; }
    String? email;
    try { email = b.email; } catch (_) { email = ''; }
    List<String> activeProjects;
    try { activeProjects = b.activeProjects; } catch (_) { activeProjects = []; }
    String? tier;
    try { tier = b.tier; } catch (_) { tier = ''; }
    DateTime? createdAt;
    try { createdAt = b.createdAt; } catch (_) { createdAt = DateTime.now(); }
    return {
      'id': id,
      'companyName': companyName,
      'contactPerson': contactPerson,
      'mobile': mobile,
      'email': email,
      'activeProjects': activeProjects,
      'tier': tier,
      'remarks': b.remarks,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static BuilderLocal _builderFromMap(Map<String, dynamic> m) {
    return BuilderLocal()
      ..id = m['id']?.toString() ?? ''
      ..companyName = m['companyName']?.toString() ?? ''
      ..contactPerson = m['contactPerson']?.toString() ?? ''
      ..mobile = m['mobile']?.toString() ?? ''
      ..email = m['email']?.toString() ?? ''
      ..activeProjects = List<String>.from(m['activeProjects'] ?? [])
      ..tier = m['tier']?.toString() ?? ''
      ..remarks = m['remarks']?.toString()
      ..createdAt = DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now();
  }

  Future<List<BuilderLocal>> getBuilders({String? search, String? tier}) async {
    if (_useInMemory) {
      if (inMemory.isEmpty && kIsWeb) {
        try {
          final records = await WebStorage().getAllRecords(WebStorageStores.builders);
          for (final r in records) {
            try {
              final m = jsonDecode(r);
              if (m is Map<String, dynamic>) {
                final b = _builderFromMap(m);
                inMemory[b.id] = b;
              }
            } catch (_) {}
          }
        } catch (_) {}
      }
      var list = inMemory.values.toList();
      if (search != null && search.isNotEmpty) {
        list = list.where((b) => builderSearchMatches(
          companyName: b.companyName,
          contactPerson: b.contactPerson,
          mobile: b.mobile,
          email: b.email,
          activeProjects: b.activeProjects,
          remarks: b.remarks,
          query: search,
        )).toList();
      }
      if (tier != null) list = list.where((b) => b.tier == tier).toList();
      return list;
    }

    final query = _isar.builderLocals.filter().idIsNotEmpty();
    QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> filtered = query;

    if (search != null && search.isNotEmpty) {
      filtered = filtered.and().group((q) => q
        .companyNameContains(search, caseSensitive: false)
        .or()
        .contactPersonContains(search, caseSensitive: false)
        .or()
        .mobileContains(search)
        .or()
        .emailContains(search, caseSensitive: false)
        .or()
        .activeProjectsElementContains(search, caseSensitive: false)
        .or()
        .remarksContains(search, caseSensitive: false)
      );
    }
    if (tier != null) filtered = filtered.and().tierEqualTo(tier);

    return await filtered.sortByCreatedAtDesc().findAll();
  }

  Future<void> saveBuilders(List<BuilderLocal> builders) async {
    if (_useInMemory) {
      for (final b in builders) {
        inMemory[b.id] = b;
      }
      if (kIsWeb) {
        final batch = <String, String>{};
        for (final b in builders) {
          try {
            batch[b.id] = jsonEncode(_builderToMap(b));
          } catch (_) {}
        }
        if (batch.isNotEmpty) {
          await WebStorage().putBatch(WebStorageStores.builders, batch);
        }
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.builderLocals.putAll(builders);
    });
  }

  Future<void> deleteBuilder(String id) async {
    if (_useInMemory) {
      inMemory.remove(id);
      if (kIsWeb) {
        await WebStorage().deleteRecord(WebStorageStores.builders, id);
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.builderLocals.deleteById(id);
    });
  }
}

class OwnerLocalRepository {
  Isar get _isar => IsarService().isar;
  bool get _useInMemory => kIsWeb || !IsarService().isInitialized;

  static final Map<String, OwnerLocal> inMemory = {};

  static Map<String, dynamic> _ownerToMap(OwnerLocal o) {
    String? id;
    try { id = o.id; } catch (_) { id = ''; }
    String? name;
    try { name = o.name; } catch (_) { name = ''; }
    String? mobile;
    try { mobile = o.mobile; } catch (_) { mobile = ''; }
    DateTime? createdAt;
    try { createdAt = o.createdAt; } catch (_) { createdAt = DateTime.now(); }
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'email': o.email,
      'address': o.address,
      'remarks': o.remarks,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static OwnerLocal _ownerFromMap(Map<String, dynamic> m) {
    return OwnerLocal()
      ..id = m['id']?.toString() ?? ''
      ..name = m['name']?.toString() ?? ''
      ..mobile = m['mobile']?.toString() ?? ''
      ..email = m['email']?.toString()
      ..address = m['address']?.toString()
      ..remarks = m['remarks']?.toString()
      ..createdAt = DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now();
  }

  Future<List<OwnerLocal>> getOwners({String? search}) async {
    if (_useInMemory) {
      if (inMemory.isEmpty && kIsWeb) {
        try {
          final records = await WebStorage().getAllRecords(WebStorageStores.owners);
          for (final r in records) {
            try {
              final m = jsonDecode(r);
              if (m is Map<String, dynamic>) {
                final o = _ownerFromMap(m);
                inMemory[o.id] = o;
              }
            } catch (_) {}
          }
        } catch (_) {}
      }
      var list = inMemory.values.toList();
      if (search != null && search.isNotEmpty) {
        list = list.where((o) => ownerSearchMatches(
          name: o.name,
          mobile: o.mobile,
          email: o.email,
          address: o.address,
          remarks: o.remarks,
          query: search,
        )).toList();
      }
      return list;
    }

    final query = _isar.ownerLocals.filter().idIsNotEmpty();
    QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> filtered = query;

    if (search != null && search.isNotEmpty) {
      filtered = filtered.and().group((q) => q
        .nameContains(search, caseSensitive: false)
        .or()
        .mobileContains(search)
        .or()
        .emailContains(search, caseSensitive: false)
        .or()
        .addressContains(search, caseSensitive: false)
        .or()
        .remarksContains(search, caseSensitive: false)
      );
    }

    return await filtered.sortByCreatedAtDesc().findAll();
  }

  Future<void> saveOwners(List<OwnerLocal> owners) async {
    if (_useInMemory) {
      for (final o in owners) {
        inMemory[o.id] = o;
      }
      if (kIsWeb) {
        final batch = <String, String>{};
        for (final o in owners) {
          try {
            batch[o.id] = jsonEncode(_ownerToMap(o));
          } catch (_) {}
        }
        if (batch.isNotEmpty) {
          await WebStorage().putBatch(WebStorageStores.owners, batch);
        }
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.ownerLocals.putAll(owners);
    });
  }

  Future<void> deleteOwner(String id) async {
    if (_useInMemory) {
      inMemory.remove(id);
      if (kIsWeb) {
        await WebStorage().deleteRecord(WebStorageStores.owners, id);
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.ownerLocals.deleteById(id);
    });
  }
}

class LookupLocalRepository {
  Isar get _isar => IsarService().isar;
  bool get _useInMemory => kIsWeb || !IsarService().isInitialized;

  static final Map<String, LookupItemLocal> inMemory = {};

  static String? getLookupNameSync(String id) {
    if (id.isEmpty) return null;
    if (kIsWeb || !IsarService().isInitialized) {
      return inMemory[id]?.name;
    }
    try {
      final isar = IsarService().isar;
      final item = isar.lookupItemLocals.getByIdSync(id);
      return item?.name;
    } catch (_) {
      return null;
    }
  }

  Future<List<LookupItemLocal>> getLookupsByCategory(String category) async {
    if (_useInMemory) {
      return inMemory.values.where((l) => l.category == category).toList();
    }

    return await _isar.lookupItemLocals.where().categoryEqualTo(category).findAll();
  }

  static Map<String, dynamic> _lookupToMap(LookupItemLocal item) {
    return {
      'id': item.id,
      'name': item.name,
      'category': item.category,
      'categoryId': item.categoryId,
      'cityId': item.cityId,
      'pincode': item.pincode,
    };
  }

  static LookupItemLocal _lookupFromMap(Map<String, dynamic> map) {
    return LookupItemLocal()
      ..id = map['id']?.toString() ?? ''
      ..name = map['name']?.toString() ?? ''
      ..category = map['category']?.toString() ?? ''
      ..categoryId = map['categoryId']?.toString()
      ..cityId = map['cityId']?.toString()
      ..pincode = map['pincode']?.toString();
  }

  Future<void> loadInMemoryCache() async {
    if (!kIsWeb) return;
    try {
      await WebStorageMigration.migrateLegacyLocalStorageIfNeeded();
      final records = await WebStorage().getAllRecords(WebStorageStores.lookups);
      for (final jsonStr in records) {
        try {
          final map = jsonDecode(jsonStr);
          if (map is Map<String, dynamic>) {
            final item = _lookupFromMap(map);
            inMemory[item.id] = item;
          }
        } catch (_) {}
      }
      debugPrint("Loaded ${inMemory.length} lookups from IndexedDB WebStorage.");
    } catch (e) {
      debugPrint("Error loading cached lookups from WebStorage: $e");
    }
  }

  Future<void> _persistBatchAsync(List<LookupItemLocal> items, {bool clearExisting = false}) async {
    if (!kIsWeb) return;
    try {
      if (clearExisting) {
        await WebStorage().clearStore(WebStorageStores.lookups);
      }
      if (items.isEmpty) return;
      final batch = <String, String>{};
      for (final item in items) {
        batch[item.id] = jsonEncode(_lookupToMap(item));
      }
      await WebStorage().putBatch(WebStorageStores.lookups, batch);
    } catch (e) {
      debugPrint("Error persisting lookups to WebStorage: $e");
    }
  }

  Future<void> _deleteBatchAsync(List<String> ids) async {
    if (!kIsWeb || ids.isEmpty) return;
    try {
      await WebStorage().deleteBatch(WebStorageStores.lookups, ids);
    } catch (e) {
      debugPrint("Error deleting lookups from WebStorage: $e");
    }
  }

  Future<void> saveLookups(List<LookupItemLocal> items, {bool clearExisting = false}) async {
    if (_useInMemory) {
      if (clearExisting) {
        inMemory.clear();
      }
      for (final item in items) {
        inMemory[item.id] = item;
      }
      await _persistBatchAsync(items, clearExisting: clearExisting);
      return;
    }

    await _isar.writeTxn(() async {
      if (clearExisting) {
        await _isar.lookupItemLocals.clear();
      }
      await _isar.lookupItemLocals.putAll(items);
    });
  }

  Future<void> deleteLookups(List<String> ids) async {
    if (ids.isEmpty) return;
    final idSet = ids.toSet();
    if (_useInMemory) {
      inMemory.removeWhere((k, v) => idSet.contains(k));
      await _deleteBatchAsync(ids);
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.lookupItemLocals.deleteAllById(ids);
    });
  }

  Future<void> saveSingleLookup(LookupItemLocal item) async {
    if (_useInMemory) {
      inMemory[item.id] = item;
      await _persistBatchAsync([item]);
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.lookupItemLocals.put(item);
    });
  }

  Future<void> deleteSingleLookup(String id) async {
    if (_useInMemory) {
      inMemory.remove(id);
      await _deleteBatchAsync([id]);
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.lookupItemLocals.deleteById(id);
    });
  }

  Future<int> getLookupsCount() async {
    if (_useInMemory) {
      return inMemory.length;
    }
    return await _isar.lookupItemLocals.count();
  }
}

class OutboxLocalRepository {
  Isar get _isar => IsarService().isar;
  bool get _useInMemory => kIsWeb || !IsarService().isInitialized;

  static final Map<String, OutboxLocal> inMemory = {};

  static Map<String, dynamic> _outboxToMap(OutboxLocal r) {
    return {
      'id': r.id,
      'endpoint': r.endpoint,
      'method': r.method,
      'payloadJson': r.payloadJson,
      'createdAt': r.createdAt.toIso8601String(),
      'deviceId': r.deviceId,
    };
  }

  static OutboxLocal _outboxFromMap(Map<String, dynamic> m) {
    return OutboxLocal()
      ..id = m['id']?.toString() ?? ''
      ..endpoint = m['endpoint']?.toString() ?? ''
      ..method = m['method']?.toString() ?? ''
      ..payloadJson = m['payloadJson']?.toString() ?? '{}'
      ..createdAt = DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now()
      ..deviceId = m['deviceId']?.toString();
  }

  Future<List<OutboxLocal>> getQueuedRequests() async {
    if (_useInMemory) {
      if (inMemory.isEmpty && kIsWeb) {
        try {
          final records = await WebStorage().getAllRecords(WebStorageStores.outbox);
          for (final r in records) {
            try {
              final m = jsonDecode(r);
              if (m is Map<String, dynamic>) {
                final o = _outboxFromMap(m);
                inMemory[o.id] = o;
              }
            } catch (_) {}
          }
        } catch (_) {}
      }
      final list = inMemory.values.toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    }

    return await _isar.outboxLocals.where().sortByCreatedAt().findAll();
  }

  Future<void> queueRequest(OutboxLocal request) async {
    if (_useInMemory) {
      inMemory[request.id] = request;
      if (kIsWeb) {
        await WebStorage().putRecord(
          WebStorageStores.outbox,
          request.id,
          jsonEncode(_outboxToMap(request)),
        );
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.outboxLocals.put(request);
    });
  }

  Future<void> removeRequest(String id) async {
    if (_useInMemory) {
      inMemory.remove(id);
      if (kIsWeb) {
        await WebStorage().deleteRecord(WebStorageStores.outbox, id);
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.outboxLocals.deleteById(id);
    });
  }
}

class DashboardLocalRepository {
  Isar get _isar => IsarService().isar;
  bool get _useInMemory => kIsWeb || !IsarService().isInitialized;

  static DashboardLocal? inMemoryDashboard;

  static Map<String, dynamic> _dashboardToMap(DashboardLocal d) {
    return {
      'id': d.id,
      'activityJson': d.activityJson,
      'recentPropertiesJson': d.recentPropertiesJson,
      'checklistJson': d.checklistJson,
      'followupsJson': d.followupsJson,
      'siteVisitsJson': d.siteVisitsJson,
      'summary': {
        'totalProperties': d.summary.totalProperties,
        'available': d.summary.available,
        'sold': d.summary.sold,
        'rented': d.summary.rented,
        'requirements': d.summary.requirements,
        'users': d.summary.users,
        'rentalAvailable': d.summary.rentalAvailable,
        'resaleAvailable': d.summary.resaleAvailable,
        'rentalRented': d.summary.rentalRented,
        'resaleSold': d.summary.resaleSold,
        'rentalRequirements': d.summary.rentalRequirements,
        'resaleRequirements': d.summary.resaleRequirements,
        'totalPropertiesTrend': d.summary.totalPropertiesTrend,
        'availableTrend': d.summary.availableTrend,
        'soldTrend': d.summary.soldTrend,
        'rentedTrend': d.summary.rentedTrend,
        'requirementsTrend': d.summary.requirementsTrend,
        'topBroker': d.summary.topBroker,
        'topArea': d.summary.topArea,
        'topProperty': d.summary.topProperty,
        'monthlyGrowth': d.summary.monthlyGrowth,
      },
    };
  }

  static DashboardLocal _dashboardFromMap(Map<String, dynamic> m) {
    final summaryMap = m['summary'] as Map<String, dynamic>? ?? {};
    final summary = DashboardSummaryLocal()
      ..totalProperties = summaryMap['totalProperties'] as int?
      ..available = summaryMap['available'] as int?
      ..sold = summaryMap['sold'] as int?
      ..rented = summaryMap['rented'] as int?
      ..requirements = summaryMap['requirements'] as int?
      ..users = summaryMap['users'] as int?
      ..rentalAvailable = summaryMap['rentalAvailable'] as int?
      ..resaleAvailable = summaryMap['resaleAvailable'] as int?
      ..rentalRented = summaryMap['rentalRented'] as int?
      ..resaleSold = summaryMap['resaleSold'] as int?
      ..rentalRequirements = summaryMap['rentalRequirements'] as int?
      ..resaleRequirements = summaryMap['resaleRequirements'] as int?
      ..totalPropertiesTrend = (summaryMap['totalPropertiesTrend'] as num?)?.toDouble()
      ..availableTrend = (summaryMap['availableTrend'] as num?)?.toDouble()
      ..soldTrend = (summaryMap['soldTrend'] as num?)?.toDouble()
      ..rentedTrend = (summaryMap['rentedTrend'] as num?)?.toDouble()
      ..requirementsTrend = (summaryMap['requirementsTrend'] as num?)?.toDouble()
      ..topBroker = summaryMap['topBroker']?.toString()
      ..topArea = summaryMap['topArea']?.toString()
      ..topProperty = summaryMap['topProperty']?.toString()
      ..monthlyGrowth = summaryMap['monthlyGrowth']?.toString();

    return DashboardLocal()
      ..id = m['id']?.toString() ?? 'singleton'
      ..summary = summary
      ..activityJson = m['activityJson']?.toString() ?? '[]'
      ..recentPropertiesJson = m['recentPropertiesJson']?.toString() ?? '[]'
      ..checklistJson = m['checklistJson']?.toString() ?? '[]'
      ..followupsJson = m['followupsJson']?.toString() ?? '[]'
      ..siteVisitsJson = m['siteVisitsJson']?.toString();
  }

  Future<DashboardLocal?> getDashboard() async {
    if (_useInMemory) {
      if (inMemoryDashboard == null && kIsWeb) {
        try {
          final str = await WebStorage().getRecord(WebStorageStores.dashboard, 'singleton');
          if (str != null) {
            final m = jsonDecode(str);
            if (m is Map<String, dynamic>) {
              inMemoryDashboard = _dashboardFromMap(m);
            }
          }
        } catch (_) {}
      }
      return inMemoryDashboard;
    }

    return await _isar.dashboardLocals.getById('singleton');
  }

  Future<void> saveDashboard(DashboardLocal dashboard) async {
    if (_useInMemory) {
      inMemoryDashboard = dashboard;
      if (kIsWeb) {
        await WebStorage().putRecord(
          WebStorageStores.dashboard,
          'singleton',
          jsonEncode(_dashboardToMap(dashboard)),
        );
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.dashboardLocals.put(dashboard);
    });
  }
}

class ClientLocalRepository {
  Isar get _isar => IsarService().isar;
  bool get _useInMemory => kIsWeb || !IsarService().isInitialized;

  static final Map<String, ClientLocal> inMemory = {};

  static Map<String, dynamic> _clientToMap(ClientLocal c) {
    String? id;
    try { id = c.id; } catch (_) { id = ''; }
    String? name;
    try { name = c.name; } catch (_) { name = ''; }
    String? email;
    try { email = c.email; } catch (_) { email = ''; }
    String? mobile;
    try { mobile = c.mobile; } catch (_) { mobile = ''; }
    String? stage;
    try { stage = c.stage; } catch (_) { stage = ''; }
    String? source;
    try { source = c.source; } catch (_) { source = ''; }
    DateTime? createdAt;
    try { createdAt = c.createdAt; } catch (_) { createdAt = DateTime.now(); }
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'stage': stage,
      'source': source,
      'assignedAgent': c.assignedAgent,
      'remarks': c.remarks,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static ClientLocal _clientFromMap(Map<String, dynamic> m) {
    return ClientLocal()
      ..id = m['id']?.toString() ?? ''
      ..name = m['name']?.toString() ?? ''
      ..email = m['email']?.toString() ?? ''
      ..mobile = m['mobile']?.toString() ?? ''
      ..stage = m['stage']?.toString() ?? ''
      ..source = m['source']?.toString() ?? ''
      ..assignedAgent = m['assignedAgent']?.toString()
      ..remarks = m['remarks']?.toString()
      ..createdAt = DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now();
  }

  Future<List<ClientLocal>> getClients({String? search, String? stage, String? source}) async {
    if (_useInMemory) {
      if (inMemory.isEmpty && kIsWeb) {
        try {
          final records = await WebStorage().getAllRecords(WebStorageStores.clients);
          for (final r in records) {
            try {
              final m = jsonDecode(r);
              if (m is Map<String, dynamic>) {
                final c = _clientFromMap(m);
                inMemory[c.id] = c;
              }
            } catch (_) {}
          }
        } catch (_) {}
      }
      var list = inMemory.values.toList();
      if (search != null && search.isNotEmpty) {
        final query = search.toLowerCase();
        list = list.where((c) => clientSearchMatches(
          name: c.name,
          email: c.email,
          mobile: c.mobile,
          remarks: c.remarks,
          query: query,
        )).toList();
      }
      if (stage != null && stage != 'All') {
        list = list.where((c) => c.stage == stage).toList();
      }
      if (source != null && source != 'All') {
        list = list.where((c) => c.source == source).toList();
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }

    final query = _isar.clientLocals.filter().idIsNotEmpty();
    QueryBuilder<ClientLocal, ClientLocal, QAfterFilterCondition> filtered = query;
    if (search != null && search.isNotEmpty) {
      filtered = filtered.and().group((q) => q
        .nameContains(search, caseSensitive: false)
        .or()
        .mobileContains(search)
        .or()
        .emailContains(search, caseSensitive: false)
        .or()
        .remarksContains(search, caseSensitive: false)
      );
    }
    if (stage != null && stage != 'All') {
      filtered = filtered.and().stageEqualTo(stage);
    }
    if (source != null && source != 'All') {
      filtered = filtered.and().sourceEqualTo(source);
    }
    return await filtered.sortByCreatedAtDesc().findAll();
  }

  Future<void> saveClients(List<ClientLocal> clients) async {
    if (_useInMemory) {
      for (final c in clients) {
        inMemory[c.id] = c;
      }
      if (kIsWeb) {
        final batch = <String, String>{};
        for (final c in clients) {
          try {
            batch[c.id] = jsonEncode(_clientToMap(c));
          } catch (_) {}
        }
        if (batch.isNotEmpty) {
          await WebStorage().putBatch(WebStorageStores.clients, batch);
        }
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.clientLocals.putAll(clients);
    });
  }

  Future<void> deleteClient(String id) async {
    if (_useInMemory) {
      inMemory.remove(id);
      if (kIsWeb) {
        await WebStorage().deleteRecord(WebStorageStores.clients, id);
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.clientLocals.deleteById(id);
    });
  }
}

class CampaignLeadLocalRepository {
  Isar get _isar => IsarService().isar;
  bool get _useInMemory => kIsWeb || !IsarService().isInitialized;

  static final Map<String, CampaignLeadLocal> inMemory = {};
  static const String webLeadsStorageKey = 'isar_campaign_leads_web_v1';

  static Map<String, dynamic> _leadToMap(CampaignLeadLocal l) {
    return {
      'id': l.id,
      'source': l.source,
      'receivedAt': l.receivedAt.toIso8601String(),
      'rawJsonString': l.rawJsonString,
      'externalLeadId': l.externalLeadId,
      'isDuplicate': l.isDuplicate,
      'duplicateReason': l.duplicateReason,
      'qualityStatus': l.qualityStatus,
      'importStatus': l.importStatus,
      'importedClientId': l.importedClientId,
      'metaFeedbackEventId': l.metaFeedbackEventId,
      'metaFeedbackSentAt': l.metaFeedbackSentAt?.toIso8601String(),
    };
  }

  static CampaignLeadLocal _leadFromMap(Map<String, dynamic> m) {
    return CampaignLeadLocal()
      ..id = m['id']?.toString() ?? ''
      ..source = m['source']?.toString() ?? ''
      ..receivedAt = DateTime.tryParse(m['receivedAt']?.toString() ?? '') ?? DateTime.now()
      ..rawJsonString = m['rawJsonString']?.toString() ?? '{}'
      ..externalLeadId = m['externalLeadId']?.toString()
      ..isDuplicate = m['isDuplicate'] as bool? ?? false
      ..duplicateReason = m['duplicateReason']?.toString()
      ..qualityStatus = m['qualityStatus']?.toString() ?? 'Pending'
      ..importStatus = m['importStatus']?.toString() ?? 'New'
      ..importedClientId = m['importedClientId']?.toString()
      ..metaFeedbackEventId = m['metaFeedbackEventId']?.toString()
      ..metaFeedbackSentAt = m['metaFeedbackSentAt'] != null
          ? DateTime.tryParse(m['metaFeedbackSentAt'].toString())
          : null;
  }

  Future<void> _persistBatchAsync(List<CampaignLeadLocal> leads, {bool clearExisting = false}) async {
    if (!kIsWeb) return;
    try {
      if (clearExisting) {
        await WebStorage().clearStore(WebStorageStores.campaignLeads);
      }
      if (leads.isEmpty) return;
      final batch = <String, String>{};
      for (final l in leads) {
        batch[l.id] = jsonEncode(_leadToMap(l));
      }
      await WebStorage().putBatch(WebStorageStores.campaignLeads, batch);
    } catch (e) {
      debugPrint("Error persisting campaign leads to WebStorage: $e");
    }
  }

  Future<void> _deleteRecordAsync(String id) async {
    if (!kIsWeb) return;
    try {
      await WebStorage().deleteRecord(WebStorageStores.campaignLeads, id);
    } catch (e) {
      debugPrint("Error deleting campaign lead from WebStorage: $e");
    }
  }

  Future<void> _deleteBatchAsync(List<String> ids) async {
    if (!kIsWeb || ids.isEmpty) return;
    try {
      await WebStorage().deleteBatch(WebStorageStores.campaignLeads, ids);
    } catch (e) {
      debugPrint("Error deleting campaign leads from WebStorage: $e");
    }
  }

  Future<List<CampaignLeadLocal>> getLeads() async {
    if (_useInMemory) {
      if (inMemory.isEmpty) {
        try {
          await WebStorageMigration.migrateLegacyLocalStorageIfNeeded();
          final records = await WebStorage().getAllRecords(WebStorageStores.campaignLeads);
          for (final jsonStr in records) {
            try {
              final m = jsonDecode(jsonStr);
              if (m is Map<String, dynamic>) {
                final l = _leadFromMap(m);
                inMemory[l.id] = l;
              }
            } catch (_) {}
          }
        } catch (_) {}
      }
      final list = inMemory.values.toList();
      list.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      return list;
    }
    return await _isar.campaignLeadLocals
        .filter()
        .idIsNotEmpty()
        .sortByReceivedAtDesc()
        .findAll();
  }

  Future<void> saveLeads(List<CampaignLeadLocal> leads, {bool clearExisting = false}) async {
    if (clearExisting) {
      inMemory.clear();
    }
    for (final l in leads) {
      inMemory[l.id] = l;
    }
    if (_useInMemory) {
      await _persistBatchAsync(leads, clearExisting: clearExisting);
      return;
    }
    await _isar.writeTxn(() async {
      if (clearExisting) {
        await _isar.campaignLeadLocals.clear();
      }
      await _isar.campaignLeadLocals.putAll(leads);
    });
  }

  Future<void> saveLead(CampaignLeadLocal lead) async {
    inMemory[lead.id] = lead;
    if (_useInMemory) {
      await _persistBatchAsync([lead]);
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.campaignLeadLocals.put(lead);
    });
  }

  Future<void> deleteLead(String id) async {
    if (_useInMemory) {
      inMemory.remove(id);
      await _deleteRecordAsync(id);
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.campaignLeadLocals.deleteById(id);
    });
  }

  Future<void> deleteLeads(List<String> ids) async {
    if (_useInMemory) {
      for (final id in ids) {
        inMemory.remove(id);
      }
      await _deleteBatchAsync(ids);
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.campaignLeadLocals.deleteAllById(ids);
    });
  }

  Future<void> clearAll() async {
    if (_useInMemory) {
      inMemory.clear();
      if (kIsWeb) {
        await WebStorage().clearStore(WebStorageStores.campaignLeads);
      }
      return;
    }
    await _isar.writeTxn(() async {
      await _isar.campaignLeadLocals.clear();
    });
  }
}
