import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'isar_collections.dart';
import 'isar_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PropertyLocalRepository {
  Isar get _isar => IsarService().isar;

  static final Map<String, PropertyLocal> inMemory = {};

  Future<PropertyLocal?> getPropertyById(String id) async {
    if (kIsWeb) {
      return inMemory[id];
    }
    return await _isar.propertyLocals.filter().idEqualTo(id).findFirst();
  }

  Future<List<PropertyLocal>> getProperties({
    String? search,
    String? categoryId,
    String? areaId,
    String? listingTypeId,
    String? createdBy,
    bool? isVerified,
  }) async {
    if (kIsWeb) {
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

  Future<void> loadInMemoryCache() async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('cached_properties');
      if (jsonList != null) {
        for (final jsonStr in jsonList) {
          final map = jsonDecode(jsonStr);
          final p = PropertyLocal()
            ..id = map['id']
            ..propertyCode = map['propertyCode'] ?? ''
            ..title = map['title'] ?? ''
            ..description = map['description']
            ..categoryId = map['categoryId'] ?? ''
            ..categoryName = map['categoryName'] ?? ''
            ..propertyTypeId = map['propertyTypeId'] ?? ''
            ..propertyTypeName = map['propertyTypeName'] ?? ''
            ..configurationId = map['configurationId']
            ..configurationName = map['configurationName']
            ..listingTypeId = map['listingTypeId'] ?? ''
            ..listingTypeName = map['listingTypeName'] ?? ''
            ..propertyStatusId = map['propertyStatusId'] ?? ''
            ..propertyStatusName = map['propertyStatusName'] ?? ''
            ..cityId = map['cityId'] ?? ''
            ..cityName = map['cityName'] ?? ''
            ..areaId = map['areaId'] ?? ''
            ..areaName = map['areaName'] ?? ''
            ..pincode = map['pincode'] ?? ''
            ..address = map['address'] ?? ''
            ..landmark = map['landmark']
            ..latitude = map['latitude'] != null ? double.tryParse(map['latitude'].toString()) : null
            ..longitude = map['longitude'] != null ? double.tryParse(map['longitude'].toString()) : null
            ..superBuiltupArea = map['superBuiltupArea'] != null ? double.tryParse(map['superBuiltupArea'].toString()) : null
            ..carpetArea = map['carpetArea'] != null ? double.tryParse(map['carpetArea'].toString()) : null
            ..plotArea = map['plotArea'] != null ? double.tryParse(map['plotArea'].toString()) : null
            ..price = double.tryParse(map['price']?.toString() ?? '') ?? 0.0
            ..deposit = double.tryParse(map['deposit']?.toString() ?? '') ?? 0.0
            ..maintenance = double.tryParse(map['maintenance']?.toString() ?? '') ?? 0.0
            ..furnishingTypeId = map['furnishingTypeId']
            ..furnishingTypeName = map['furnishingTypeName']
            ..facingTypeId = map['facingTypeId']
            ..facingTypeName = map['facingTypeName']
            ..ownershipTypeId = map['ownershipTypeId']
            ..ownershipTypeName = map['ownershipTypeName']
            ..bedrooms = map['bedrooms'] as int? ?? 0
            ..bathrooms = map['bathrooms'] as int? ?? 0
            ..balconies = map['balconies'] as int? ?? 0
            ..parking = map['parking'] as int? ?? 0
            ..floorNo = map['floorNo'] as int?
            ..totalFloor = map['totalFloor'] as int?
            ..ageOfProperty = map['ageOfProperty'] as int?
            ..possessionDate = map['possessionDate'] != null ? DateTime.tryParse(map['possessionDate']) : null
            ..ownerName = map['ownerName'] ?? ''
            ..ownerMobile = map['ownerMobile'] ?? ''
            ..brokerName = map['brokerName']
            ..remarks = map['remarks']
            ..blockWing = map['blockWing']
            ..flatNo = map['flatNo']
            ..googlePlaceId = map['googlePlaceId']
            ..brokerageTypeId = map['brokerageTypeId']
            ..brokerageTypeName = map['brokerageTypeName']
            ..isVerified = map['isVerified'] as bool? ?? false
            ..createdBy = map['createdBy'] ?? ''
            ..createdByName = map['createdByName'] ?? 'N/A'
            ..createdAt = DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now()
            ..images = List<String>.from(map['images'] ?? [])
            ..amenities = List<String>.from(map['amenities'] ?? [])
            ..adminId = map['adminId']
            ..organizationId = map['organizationId'];
          inMemory[p.id] = p;
        }
        print("Loaded ${inMemory.length} properties from local storage cache.");
      }
    } catch (e) {
      print("Error loading cached properties: $e");
    }
  }

  Future<void> _saveAllToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = inMemory.values.map((item) => jsonEncode({
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
      })).toList();
      await prefs.setStringList('cached_properties', jsonList);
    } catch (e) {
      print("Error saving properties to preferences: $e");
    }
  }

  Future<void> saveProperties(List<PropertyLocal> properties) async {
    if (kIsWeb) {
      for (final p in properties) {
        inMemory[p.id] = p;
      }
      await _saveAllToPrefs();
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.propertyLocals.putAll(properties);
    });
  }

  Future<void> deleteProperty(String id) async {
    if (kIsWeb) {
      inMemory.remove(id);
      await _saveAllToPrefs();
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.propertyLocals.filter().idEqualTo(id).deleteAll();
    });
  }
}

class RequirementLocalRepository {
  Isar get _isar => IsarService().isar;

  static final Map<String, RequirementLocal> inMemory = {};

  Future<List<RequirementLocal>> getRequirements({
    String? search,
    String? configurationId,
    String? propertyTypeId,
    String? status,
  }) async {
    if (kIsWeb) {
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
      if (status != null && status != 'All') list = list.where((r) => r.status == status).toList();
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

  Future<void> loadInMemoryCache() async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('cached_requirements');
      if (jsonList != null) {
        for (final jsonStr in jsonList) {
          final map = jsonDecode(jsonStr);
          final r = RequirementLocal()
            ..id = map['id']
            ..clientName = map['clientName'] ?? ''
            ..clientMobile = map['clientMobile'] ?? ''
            ..categoryId = map['categoryId'] ?? ''
            ..categoryName = map['categoryName'] ?? ''
            ..propertyTypeId = map['propertyTypeId']
            ..propertyTypeName = map['propertyTypeName']
            ..configurationId = map['configurationId']
            ..configurationName = map['configurationName']
            ..minBudget = double.tryParse(map['minBudget']?.toString() ?? '') ?? 0.0
            ..maxBudget = double.tryParse(map['maxBudget']?.toString() ?? '') ?? 0.0
            ..minArea = map['minArea'] != null ? double.tryParse(map['minArea'].toString()) : null
            ..maxArea = map['maxArea'] != null ? double.tryParse(map['maxArea'].toString()) : null
            ..areaIds = List<String>.from(map['areaIds'] ?? [])
            ..areaNames = List<String>.from(map['areaNames'] ?? [])
            ..remarks = map['remarks']
            ..status = map['status'] ?? 'Active'
            ..createdAt = DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now()
            ..budget = map['budget'] != null ? double.tryParse(map['budget'].toString()) : null
            ..adminId = map['adminId']
            ..organizationId = map['organizationId'];
          inMemory[r.id] = r;
        }
        print("Loaded ${inMemory.length} requirements from local storage cache.");
      }
    } catch (e) {
      print("Error loading cached requirements: $e");
    }
  }

  Future<void> _saveAllToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = inMemory.values.map((item) => jsonEncode({
        'id': item.id,
        'clientName': kIsWeb ? '' : item.clientName,
        'clientMobile': kIsWeb ? '' : item.clientMobile,
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
        'status': item.status,
        'createdAt': item.createdAt.toIso8601String(),
        'budget': item.budget,
        'adminId': item.adminId,
        'organizationId': item.organizationId,
      })).toList();
      await prefs.setStringList('cached_requirements', jsonList);
    } catch (e) {
      print("Error saving requirements to preferences: $e");
    }
  }

  Future<void> saveRequirements(List<RequirementLocal> requirements) async {
    if (kIsWeb) {
      for (final r in requirements) {
        inMemory[r.id] = r;
      }
      await _saveAllToPrefs();
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.requirementLocals.putAll(requirements);
    });
  }

  Future<void> deleteRequirement(String id) async {
    if (kIsWeb) {
      inMemory.remove(id);
      await _saveAllToPrefs();
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.requirementLocals.filter().idEqualTo(id).deleteAll();
    });
  }

  Future<RequirementLocal?> getRequirement(String id) async {
    if (kIsWeb) {
      return inMemory[id];
    }
    return await _isar.requirementLocals.filter().idEqualTo(id).findFirst();
  }
}

class FollowupLocalRepository {
  Isar get _isar => IsarService().isar;

  static final Map<String, FollowupLocal> inMemory = {};

  Future<List<FollowupLocal>> getFollowupsByClient(String clientName) async {
    if (kIsWeb) {
      return inMemory.values.where((f) => f.clientName == clientName).toList();
    }

    return await _isar.followupLocals.filter().clientNameEqualTo(clientName).findAll();
  }

  Future<void> saveFollowups(List<FollowupLocal> followups) async {
    if (kIsWeb) {
      for (final f in followups) {
        inMemory[f.id] = f;
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.followupLocals.putAll(followups);
    });
  }

  Future<void> deleteFollowup(String id) async {
    if (kIsWeb) {
      inMemory.remove(id);
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.followupLocals.filter().idEqualTo(id).deleteAll();
    });
  }
}

class BuilderLocalRepository {
  Isar get _isar => IsarService().isar;

  static final Map<String, BuilderLocal> inMemory = {};

  Future<List<BuilderLocal>> getBuilders({String? search, String? tier}) async {
    if (kIsWeb) {
      var list = inMemory.values.toList();
      if (search != null && search.isNotEmpty) {
        final query = search.toLowerCase();
        list = list.where((b) => b.companyName.toLowerCase().contains(query)).toList();
      }
      if (tier != null) list = list.where((b) => b.tier == tier).toList();
      return list;
    }

    final query = _isar.builderLocals.filter().idIsNotEmpty();
    QueryBuilder<BuilderLocal, BuilderLocal, QAfterFilterCondition> filtered = query;

    if (search != null && search.isNotEmpty) {
      filtered = filtered.and().companyNameContains(search, caseSensitive: false);
    }
    if (tier != null) filtered = filtered.and().tierEqualTo(tier);

    return await filtered.sortByCreatedAtDesc().findAll();
  }

  Future<void> saveBuilders(List<BuilderLocal> builders) async {
    if (kIsWeb) {
      for (final b in builders) {
        inMemory[b.id] = b;
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.builderLocals.putAll(builders);
    });
  }

  Future<void> deleteBuilder(String id) async {
    if (kIsWeb) {
      inMemory.remove(id);
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.builderLocals.filter().idEqualTo(id).deleteAll();
    });
  }
}

class OwnerLocalRepository {
  Isar get _isar => IsarService().isar;

  static final Map<String, OwnerLocal> inMemory = {};

  Future<List<OwnerLocal>> getOwners({String? search}) async {
    if (kIsWeb) {
      var list = inMemory.values.toList();
      if (search != null && search.isNotEmpty) {
        final query = search.toLowerCase();
        list = list.where((o) => o.name.toLowerCase().contains(query)).toList();
      }
      return list;
    }

    final query = _isar.ownerLocals.filter().idIsNotEmpty();
    QueryBuilder<OwnerLocal, OwnerLocal, QAfterFilterCondition> filtered = query;

    if (search != null && search.isNotEmpty) {
      filtered = filtered.and().nameContains(search, caseSensitive: false);
    }

    return await filtered.sortByCreatedAtDesc().findAll();
  }

  Future<void> saveOwners(List<OwnerLocal> owners) async {
    if (kIsWeb) {
      for (final o in owners) {
        inMemory[o.id] = o;
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.ownerLocals.putAll(owners);
    });
  }

  Future<void> deleteOwner(String id) async {
    if (kIsWeb) {
      inMemory.remove(id);
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.ownerLocals.filter().idEqualTo(id).deleteAll();
    });
  }
}

class LookupLocalRepository {
  Isar get _isar => IsarService().isar;

  static final Map<String, LookupItemLocal> inMemory = {};

  static String? getLookupNameSync(String id) {
    if (id.isEmpty) return null;
    if (kIsWeb) {
      return inMemory[id]?.name;
    }
    try {
      final isar = IsarService().isar;
      final item = isar.lookupItemLocals.filter().idEqualTo(id).findFirstSync();
      return item?.name;
    } catch (_) {
      return null;
    }
  }

  Future<List<LookupItemLocal>> getLookupsByCategory(String category) async {
    if (kIsWeb) {
      return inMemory.values.where((l) => l.category == category).toList();
    }

    return await _isar.lookupItemLocals.filter().categoryEqualTo(category).findAll();
  }

  Future<void> loadInMemoryCache() async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('cached_lookups');
      if (jsonList != null) {
        for (final jsonStr in jsonList) {
          final map = jsonDecode(jsonStr);
          final item = LookupItemLocal()
            ..id = map['id'] ?? ''
            ..name = map['name'] ?? ''
            ..category = map['category'] ?? ''
            ..categoryId = map['categoryId']
            ..cityId = map['cityId']
            ..pincode = map['pincode'];
          inMemory[item.id] = item;
        }
        print("Loaded ${inMemory.length} lookups from local storage cache.");
      }
    } catch (e) {
      print("Error loading cached lookups: $e");
    }
  }

  Future<void> _saveAllToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = inMemory.values.map((item) => jsonEncode({
        'id': item.id,
        'name': item.name,
        'category': item.category,
        'categoryId': item.categoryId,
        'cityId': item.cityId,
        'pincode': item.pincode,
      })).toList();
      await prefs.setStringList('cached_lookups', jsonList);
    } catch (e) {
      print("Error saving lookups to preferences: $e");
    }
  }

  Future<void> saveLookups(List<LookupItemLocal> items) async {
    if (kIsWeb) {
      for (final item in items) {
        inMemory[item.id] = item;
      }
      await _saveAllToPrefs();
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.lookupItemLocals.putAll(items);
    });
  }

  Future<void> saveSingleLookup(LookupItemLocal item) async {
    if (kIsWeb) {
      inMemory[item.id] = item;
      await _saveAllToPrefs();
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.lookupItemLocals.put(item);
    });
  }

  Future<int> getLookupsCount() async {
    if (kIsWeb) {
      return inMemory.length;
    }
    return await _isar.lookupItemLocals.count();
  }
}

class OutboxLocalRepository {
  Isar get _isar => IsarService().isar;

  static final Map<String, OutboxLocal> inMemory = {};

  Future<List<OutboxLocal>> getQueuedRequests() async {
    if (kIsWeb) {
      final list = inMemory.values.toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    }

    return await _isar.outboxLocals.where().sortByCreatedAt().findAll();
  }

  Future<void> queueRequest(OutboxLocal request) async {
    if (kIsWeb) {
      inMemory[request.id] = request;
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.outboxLocals.put(request);
    });
  }

  Future<void> removeRequest(String id) async {
    if (kIsWeb) {
      inMemory.remove(id);
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.outboxLocals.filter().idEqualTo(id).deleteAll();
    });
  }
}

class DashboardLocalRepository {
  Isar get _isar => IsarService().isar;

  static DashboardLocal? inMemoryDashboard;

  Future<DashboardLocal?> getDashboard() async {
    if (kIsWeb) {
      return inMemoryDashboard;
    }

    return await _isar.dashboardLocals.filter().idEqualTo('singleton').findFirst();
  }

  Future<void> saveDashboard(DashboardLocal dashboard) async {
    if (kIsWeb) {
      inMemoryDashboard = dashboard;
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.dashboardLocals.put(dashboard);
    });
  }
}

class ClientLocalRepository {
  Isar get _isar => IsarService().isar;

  static final Map<String, ClientLocal> inMemory = {};

  Future<List<ClientLocal>> getClients({String? search, String? stage, String? source}) async {
    if (kIsWeb) {
      var list = inMemory.values.toList();
      if (search != null && search.isNotEmpty) {
        final query = search.toLowerCase();
        list = list.where((c) => c.name.toLowerCase().contains(query) || c.mobile.contains(query) || c.email.toLowerCase().contains(query)).toList();
      }
      if (stage != null && stage != 'All') {
        list = list.where((c) => c.stage == stage).toList();
      }
      if (source != null && source != 'All') {
        list = list.where((c) => c.source == source).toList();
      }
      return list;
    }

    final all = await _isar.clientLocals.where().findAll();
    var list = all;
    if (search != null && search.isNotEmpty) {
      final query = search.toLowerCase();
      list = list.where((c) => c.name.toLowerCase().contains(query) || c.mobile.contains(query) || c.email.toLowerCase().contains(query)).toList();
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

  Future<void> saveClients(List<ClientLocal> clients) async {
    if (kIsWeb) {
      for (final c in clients) {
        inMemory[c.id] = c;
      }
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.clientLocals.putAll(clients);
    });
  }

  Future<void> deleteClient(String id) async {
    if (kIsWeb) {
      inMemory.remove(id);
      return;
    }

    await _isar.writeTxn(() async {
      await _isar.clientLocals.filter().idEqualTo(id).deleteAll();
    });
  }
}
