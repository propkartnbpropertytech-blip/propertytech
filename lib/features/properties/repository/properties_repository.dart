import 'dart:convert';
import 'package:propkart/features/properties/models/property_model.dart';
import 'package:propkart/features/properties/services/properties_service.dart';
import 'package:propkart/core/storage/repository_coordinator.dart';
import 'package:propkart/core/api/cloudinary_uploader.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/core/storage/model_mappers.dart';
import 'package:propkart/core/storage/performance_logger.dart';

class PropertiesRepository {
  final PropertiesService _propertiesService = PropertiesService();
  final RepositoryCoordinator _coordinator = RepositoryCoordinator();

  void invalidateCache() {
    _coordinator.propertyLocal.saveProperties([]);
    _coordinator.refreshProperties();
  }

  Future<PropertyModel?> getPropertyById(
    String id, {
    bool refreshFromServer = false,
  }) async {
    final local = await _coordinator.propertyLocal.getPropertyByIdOrCode(id);

    if (!refreshFromServer) {
      return local?.toModel();
    }

    final fresh = await _fetchAndCachePropertyById(local?.id ?? id);
    if (fresh != null) return fresh;
    return local?.toModel();
  }

  Future<PropertyModel?> _fetchAndCachePropertyById(String id) async {
    try {
      final json = await _propertiesService.getPropertyById(id);
      if (json == null) return null;
      final model = PropertyModel.fromJson(json);
      await _coordinator.propertyLocal.saveProperties([model.toLocal()]);
      return model;
    } catch (_) {
      return null;
    }
  }

  Future<List<PropertyModel>> getProperties({
    String? search,
    String? categoryId,
    String? areaId,
    String? listingTypeId,
    String? createdBy,
    bool? isVerified,
    bool? includeDeleted,
    bool refreshFromServer = false,
  }) async {
    final start = DateTime.now();

    final localList = await _coordinator.propertyLocal.getProperties(
      search: search,
      categoryId: categoryId,
      areaId: areaId,
      listingTypeId: listingTypeId,
      createdBy: createdBy,
      isVerified: isVerified,
    );
    final isarReadMs = DateTime.now().difference(start).inMilliseconds;

    final parseStart = DateTime.now();
    final properties = localList.map((item) => item.toModel()).toList();
    final jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;

    final totalMs = DateTime.now().difference(start).inMilliseconds;
    PerformanceLogger().logMetric(
      operation: 'PropertiesRepository.getProperties (local)',
      isarReadMs: isarReadMs,
      jsonParseMs: jsonParseMs,
      totalMs: totalMs,
    );

    if (refreshFromServer) {
      _triggerBackgroundPropertiesRefresh(
        search: search,
        categoryId: categoryId,
        areaId: areaId,
        listingTypeId: listingTypeId,
        createdBy: createdBy,
        isVerified: isVerified,
        includeDeleted: includeDeleted,
      );
    }

    return properties;
  }

  void _triggerBackgroundPropertiesRefresh({
    String? search,
    String? categoryId,
    String? areaId,
    String? listingTypeId,
    String? createdBy,
    bool? isVerified,
    bool? includeDeleted,
  }) {
    final start = DateTime.now();
    _propertiesService.getProperties(
      search: search,
      categoryId: categoryId,
      areaId: areaId,
      listingTypeId: listingTypeId,
      createdBy: createdBy,
      isVerified: isVerified,
      includeDeleted: includeDeleted,
    ).then((response) async {
      final networkMs = DateTime.now().difference(start).inMilliseconds;

      final parseStart = DateTime.now();
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final list = data['properties'] as List? ?? [];
      final freshList = list.map((item) => PropertyModel.fromJson(item)).toList();
      final jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;

      final writeStart = DateTime.now();
      final localEntities = freshList.map((p) => p.toLocal()).toList();
      await _coordinator.propertyLocal.saveProperties(localEntities, clearExisting: true);
      final isarWriteMs = DateTime.now().difference(writeStart).inMilliseconds;

      final totalMs = DateTime.now().difference(start).inMilliseconds;
      PerformanceLogger().logMetric(
        operation: 'PropertiesRepository.getProperties (background refresh)',
        networkMs: networkMs,
        jsonParseMs: jsonParseMs,
        isarWriteMs: isarWriteMs,
        totalMs: totalMs,
      );

      _coordinator.refreshProperties();
    }).catchError((_) {});
  }

  Future<PropertyMetadataModel> getPropertyMetadata() async {
    final start = DateTime.now();

    final cities = await _coordinator.lookupLocal.getLookupsByCategory('city');
    final areas = await _coordinator.lookupLocal.getLookupsByCategory('area');
    final categories = await _coordinator.lookupLocal.getLookupsByCategory('property_category');
    final types = await _coordinator.lookupLocal.getLookupsByCategory('property_type');
    final configs = await _coordinator.lookupLocal.getLookupsByCategory('configuration');
    final listings = await _coordinator.lookupLocal.getLookupsByCategory('listing_type');
    final statuses = await _coordinator.lookupLocal.getLookupsByCategory('property_status');
    final furnishings = await _coordinator.lookupLocal.getLookupsByCategory('furnishing_type');
    final facings = await _coordinator.lookupLocal.getLookupsByCategory('facing_type');
    final ownerships = await _coordinator.lookupLocal.getLookupsByCategory('ownership_type');
    final brokerages = await _coordinator.lookupLocal.getLookupsByCategory('brokerage_type');
    final amenities = await _coordinator.lookupLocal.getLookupsByCategory('amenity');

    final isarReadMs = DateTime.now().difference(start).inMilliseconds;

    final parseStart = DateTime.now();
    final metadata = PropertyMetadataModel(
      cities: cities.map((c) => c.toModel()).toList(),
      areas: areas.map((a) => a.toAreaModel()).toList(),
      categories: categories.map((c) => c.toModel()).toList(),
      types: types.map((t) => t.toModel()).toList(),
      configurations: configs.map((c) => c.toModel()).toList(),
      listingTypes: listings.map((l) => l.toModel()).toList(),
      statuses: statuses.map((s) => s.toModel()).toList(),
      furnishings: furnishings.map((f) => f.toModel()).toList(),
      facings: facings.map((f) => f.toModel()).toList(),
      ownerships: ownerships.map((o) => o.toModel()).toList(),
      brokerages: brokerages.map((b) => b.toModel()).toList(),
      amenities: amenities.map((a) => a.toModel()).toList(),
    );
    final jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;

    final totalMs = DateTime.now().difference(start).inMilliseconds;
    PerformanceLogger().logMetric(
      operation: 'PropertiesRepository.getPropertyMetadata (local)',
      isarReadMs: isarReadMs,
      jsonParseMs: jsonParseMs,
      totalMs: totalMs,
    );

    _triggerBackgroundMetadataRefresh();

    return metadata;
  }

  void _triggerBackgroundMetadataRefresh() {
    final start = DateTime.now();
    _propertiesService.getPropertyMetadata().then((response) async {
      final networkMs = DateTime.now().difference(start).inMilliseconds;

      final parseStart = DateTime.now();
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final meta = PropertyMetadataModel.fromJson(data['metadata'] ?? {});
      final jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;

      final writeStart = DateTime.now();
      final List<LookupItemLocal> locals = [];
      locals.addAll(meta.cities.map((c) => c.toLocal('city')));
      locals.addAll(meta.areas.map((a) => a.toAreaLocal()));
      locals.addAll(meta.categories.map((c) => c.toLocal('property_category')));
      locals.addAll(meta.types.map((t) => t.toLocal('property_type')));
      locals.addAll(meta.configurations.map((c) => c.toLocal('configuration')));
      locals.addAll(meta.listingTypes.map((l) => l.toLocal('listing_type')));
      locals.addAll(meta.statuses.map((s) => s.toLocal('property_status')));
      locals.addAll(meta.furnishings.map((f) => f.toLocal('furnishing_type')));
      locals.addAll(meta.facings.map((f) => f.toLocal('facing_type')));
      locals.addAll(meta.ownerships.map((o) => o.toLocal('ownership_type')));
      locals.addAll(meta.brokerages.map((b) => b.toLocal('brokerage_type')));
      locals.addAll(meta.amenities.map((a) => a.toLocal('amenity')));

      await _coordinator.lookupLocal.saveLookups(locals);
      final isarWriteMs = DateTime.now().difference(writeStart).inMilliseconds;

      final totalMs = DateTime.now().difference(start).inMilliseconds;
      PerformanceLogger().logMetric(
        operation: 'PropertiesRepository.getPropertyMetadata (background refresh)',
        networkMs: networkMs,
        jsonParseMs: jsonParseMs,
        isarWriteMs: isarWriteMs,
        totalMs: totalMs,
      );

      _coordinator.refreshLookups();
    }).catchError((_) {});
  }

  Future<void> fetchAndSaveMetadata() async {
    final response = await _propertiesService.getPropertyMetadata();
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final meta = PropertyMetadataModel.fromJson(data['metadata'] ?? {});
    final List<LookupItemLocal> locals = [];
    locals.addAll(meta.cities.map((c) => c.toLocal('city')));
    locals.addAll(meta.areas.map((a) => a.toAreaLocal()));
    locals.addAll(meta.categories.map((c) => c.toLocal('property_category')));
    locals.addAll(meta.types.map((t) => t.toLocal('property_type')));
    locals.addAll(meta.configurations.map((c) => c.toLocal('configuration')));
    locals.addAll(meta.listingTypes.map((l) => l.toLocal('listing_type')));
    locals.addAll(meta.statuses.map((s) => s.toLocal('property_status')));
    locals.addAll(meta.furnishings.map((f) => f.toLocal('furnishing_type')));
    locals.addAll(meta.facings.map((f) => f.toLocal('facing_type')));
    locals.addAll(meta.ownerships.map((o) => o.toLocal('ownership_type')));
    locals.addAll(meta.brokerages.map((b) => b.toLocal('brokerage_type')));
    locals.addAll(meta.amenities.map((a) => a.toLocal('amenity')));
    await _coordinator.lookupLocal.saveLookups(locals);
    _coordinator.refreshLookups();
  }

  Future<LookupItem> createCity(String name) async {
    try {
      final response = await _propertiesService.createCity(name);
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final city = data['city'] as Map<String, dynamic>? ?? {};
      final model = LookupItem(id: city['id'] ?? '', name: city['city_name'] ?? '');

      await _coordinator.lookupLocal.saveSingleLookup(model.toLocal('city'));
      _coordinator.refreshLookups();
      return model;
    } catch (e) {
      final tempId = 'temp_city_${DateTime.now().millisecondsSinceEpoch}';
      final model = LookupItem(id: tempId, name: name);
      await _coordinator.lookupLocal.saveSingleLookup(model.toLocal('city'));

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/lookup/city'
        ..method = 'POST'
        ..payloadJson = jsonEncode({'city_name': name})
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshLookups();
      return model;
    }
  }

  Future<AreaLookup> createArea(String cityId, String name, String pincode) async {
    try {
      final response = await _propertiesService.createArea(cityId, name, pincode);
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final area = data['area'] as Map<String, dynamic>? ?? {};
      final model = AreaLookup(
        id: area['id'] ?? '',
        name: area['area_name'] ?? '',
        cityId: area['city_id'] ?? '',
        pincode: area['pincode'] ?? '',
      );

      await _coordinator.lookupLocal.saveSingleLookup(model.toAreaLocal());
      _coordinator.refreshLookups();
      return model;
    } catch (e) {
      final tempId = 'temp_area_${DateTime.now().millisecondsSinceEpoch}';
      final model = AreaLookup(id: tempId, name: name, cityId: cityId, pincode: pincode);
      await _coordinator.lookupLocal.saveSingleLookup(model.toAreaLocal());

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/lookup/area'
        ..method = 'POST'
        ..payloadJson = jsonEncode({'city_id': cityId, 'area_name': name, 'pincode': pincode})
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshLookups();
      return model;
    }
  }

  Future<LookupItem> createAmenity(String name) async {
    try {
      final response = await _propertiesService.createAmenity(name);
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final amenity = data['amenity'] as Map<String, dynamic>? ?? {};
      final model = LookupItem(id: amenity['id'] ?? '', name: amenity['name'] ?? '');

      await _coordinator.lookupLocal.saveSingleLookup(model.toLocal('amenity'));
      _coordinator.refreshLookups();
      return model;
    } catch (e) {
      final tempId = 'temp_amenity_${DateTime.now().millisecondsSinceEpoch}';
      final model = LookupItem(id: tempId, name: name);
      await _coordinator.lookupLocal.saveSingleLookup(model.toLocal('amenity'));

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/lookup/amenity'
        ..method = 'POST'
        ..payloadJson = jsonEncode({'name': name})
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshLookups();
      return model;
    }
  }

  Future<PropertyModel> createProperty(Map<String, dynamic> propertyData) async {
    try {
      final response = await _propertiesService.createProperty(propertyData);
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final propMap = Map<String, dynamic>.from(data['property'] ?? {});
      if ((propMap['property_images'] == null || (propMap['property_images'] as List).isEmpty) && propertyData['images'] != null) {
        propMap['images'] = propertyData['images'];
      }
      final fresh = PropertyModel.fromJson(propMap);

      await _coordinator.propertyLocal.saveProperties([fresh.toLocal()]);
      _coordinator.refreshProperties();
      return fresh;
    } catch (e) {
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final freshData = Map<String, dynamic>.from(propertyData);
      freshData['id'] = tempId;
      freshData['property_code'] = 'TEMP-${DateTime.now().millisecondsSinceEpoch % 10000}';
      freshData['created_at'] = DateTime.now().toIso8601String();
      freshData['updated_at'] = DateTime.now().toIso8601String();

      final fresh = PropertyModel.fromJson(freshData);
      await _coordinator.propertyLocal.saveProperties([fresh.toLocal()]);

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/properties'
        ..method = 'POST'
        ..payloadJson = jsonEncode(propertyData)
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshProperties();
      return fresh;
    }
  }

  Future<PropertyModel> updateProperty(String id, Map<String, dynamic> propertyData) async {
    try {
      final response = await _propertiesService.updateProperty(id, propertyData);
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final propMap = Map<String, dynamic>.from(data['property'] ?? {});
      if ((propMap['property_images'] == null || (propMap['property_images'] as List).isEmpty) && propertyData['images'] != null) {
        propMap['images'] = propertyData['images'];
      }
      final fresh = PropertyModel.fromJson(propMap);

      await _coordinator.propertyLocal.saveProperties([fresh.toLocal()]);
      _coordinator.refreshProperties();
      return fresh;
    } catch (e) {
      final freshData = Map<String, dynamic>.from(propertyData);
      freshData['id'] = id;
      freshData['updated_at'] = DateTime.now().toIso8601String();

      final fresh = PropertyModel.fromJson(freshData);
      await _coordinator.propertyLocal.saveProperties([fresh.toLocal()]);

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/properties/$id'
        ..method = 'PUT'
        ..payloadJson = jsonEncode(propertyData)
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshProperties();
      return fresh;
    }
  }

  Future<PropertyModel> togglePropertyVerification(String id, bool isVerified) async {
    try {
      final response = await _propertiesService.togglePropertyVerification(id, isVerified);
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final fresh = PropertyModel.fromJson(data['property'] ?? {});

      await _coordinator.propertyLocal.saveProperties([fresh.toLocal()]);
      _coordinator.refreshProperties();
      return fresh;
    } catch (e) {
      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/properties/$id/verify'
        ..method = 'PUT'
        ..payloadJson = jsonEncode({'is_verified': isVerified})
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      return PropertyModel.fromJson({'id': id, 'is_verified': isVerified});
    }
  }

  Future<PropertyModel> softDeleteProperty(String id) async {
    try {
      final response = await _propertiesService.softDeleteProperty(id);
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final fresh = PropertyModel.fromJson(data['property'] ?? {});

      await _coordinator.propertyLocal.deleteProperty(id);
      _coordinator.refreshProperties();
      return fresh;
    } catch (e) {
      await _coordinator.propertyLocal.deleteProperty(id);

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/properties/$id'
        ..method = 'DELETE'
        ..payloadJson = '{}'
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshProperties();
      return PropertyModel.fromJson({'id': id, 'title': 'Deleted'});
    }
  }

  Future<PropertyModel> restoreProperty(String id) async {
    try {
      final response = await _propertiesService.restoreProperty(id);
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final fresh = PropertyModel.fromJson(data['property'] ?? {});

      await _coordinator.propertyLocal.saveProperties([fresh.toLocal()]);
      _coordinator.refreshProperties();
      return fresh;
    } catch (e) {
      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/properties/$id/restore'
        ..method = 'PUT'
        ..payloadJson = '{}'
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);
      return PropertyModel.fromJson({'id': id});
    }
  }

  Future<LookupItem> createLookup(String masterType, Map<String, dynamic> payload) async {
    try {
      final response = await _propertiesService.createLookup(masterType, payload);
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final key = masterType == 'property-type' ? 'propertyType' :
                  masterType == 'listing-type' ? 'listingType' : masterType;
      final item = data[key] as Map<String, dynamic>? ?? {};

      if (masterType == 'area') {
        final model = AreaLookup.fromJson(item);
        await _coordinator.lookupLocal.saveSingleLookup(model.toAreaLocal());
        _coordinator.refreshLookups();
        return model;
      } else {
        final model = LookupItem.fromJson(item);
        final category = masterType == 'property-category' ? 'property_category' :
                         masterType == 'property-type' ? 'property_type' :
                         masterType == 'listing-type' ? 'listing_type' :
                         masterType == 'facing-type' ? 'facing_type' :
                         masterType == 'furnishing-type' ? 'furnishing_type' :
                         masterType == 'ownership-type' ? 'ownership_type' :
                         masterType == 'brokerage-type' ? 'brokerage_type' : masterType;
        await _coordinator.lookupLocal.saveSingleLookup(model.toLocal(category));
        _coordinator.refreshLookups();
        return model;
      }
    } catch (e) {
      final tempId = 'temp_lookup_${DateTime.now().millisecondsSinceEpoch}';
      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/lookup/$masterType'
        ..method = 'POST'
        ..payloadJson = jsonEncode(payload)
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      return LookupItem(id: tempId, name: payload['name'] ?? payload['city_name'] ?? '');
    }
  }

  Future<Map<String, dynamic>> checkDuplicate(Map<String, dynamic> checkParams) async {
    try {
      final response = await _propertiesService.checkDuplicate(checkParams);
      return response['data'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      // Offline fallback: no duplicate error to block user creation
      return {'isDuplicate': false};
    }
  }
}
