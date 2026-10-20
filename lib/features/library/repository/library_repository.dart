import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../properties/models/property_model.dart';
import '../../properties/repository/properties_repository.dart';
import '../../properties/services/properties_service.dart';
import '../models/area_item.dart';
import '../models/document_model.dart';

/// Centralized repository for Library surfaces (Rental, Resale, and Service Agent).
/// Provides offline-first state access, in-memory TTL caching, in-flight request
/// deduplication, and user session cache isolation.
class LibraryRepository {
  static final LibraryRepository _instance = LibraryRepository._internal();
  factory LibraryRepository() => _instance;
  LibraryRepository._internal();

  // Cache durations
  static const Duration _masterPropertiesTtl = Duration(seconds: 60);
  static const Duration _serviceAgentsTtl = Duration(seconds: 60);
  static const Duration _areasTtl = Duration(minutes: 5);

  // In-memory caches
  List<PropertyModel>? _cachedMasterProperties;
  DateTime? _masterPropertiesCachedAt;
  Future<List<PropertyModel>>? _masterPropertiesInFlight;

  List<ServiceAgentDocument>? _cachedServiceAgents;
  DateTime? _serviceAgentsCachedAt;
  Future<List<ServiceAgentDocument>>? _serviceAgentsInFlight;

  List<ServiceAgentDocument>? _cachedPendingAgents;
  DateTime? _pendingAgentsCachedAt;
  Future<List<ServiceAgentDocument>>? _pendingAgentsInFlight;

  List<AreaItem>? _cachedAreas;
  DateTime? _areasCachedAt;
  Future<List<AreaItem>>? _areasInFlight;

  // --- Master Properties (Rental & Resale Library Dropdowns) ---

  Future<List<PropertyModel>> getMasterProperties({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedMasterProperties != null &&
        _masterPropertiesCachedAt != null &&
        DateTime.now().difference(_masterPropertiesCachedAt!) < _masterPropertiesTtl) {
      return _cachedMasterProperties!;
    }

    if (_masterPropertiesInFlight != null) {
      return _masterPropertiesInFlight!;
    }

    _masterPropertiesInFlight = _fetchMasterProperties();
    try {
      final result = await _masterPropertiesInFlight!;
      _cachedMasterProperties = result;
      _masterPropertiesCachedAt = DateTime.now();
      return result;
    } finally {
      _masterPropertiesInFlight = null;
    }
  }

  Future<List<PropertyModel>> _fetchMasterProperties() async {
    return PropertiesRepository().getProperties(refreshFromServer: false);
  }

  // --- Service Agent Documents ---

  Future<List<ServiceAgentDocument>> getServiceAgentDocuments({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedServiceAgents != null &&
        _serviceAgentsCachedAt != null &&
        DateTime.now().difference(_serviceAgentsCachedAt!) < _serviceAgentsTtl) {
      return _cachedServiceAgents!;
    }

    if (_serviceAgentsInFlight != null) {
      return _serviceAgentsInFlight!;
    }

    _serviceAgentsInFlight = _fetchServiceAgentDocuments();
    try {
      final result = await _serviceAgentsInFlight!;
      _cachedServiceAgents = result;
      _serviceAgentsCachedAt = DateTime.now();
      return result;
    } finally {
      _serviceAgentsInFlight = null;
    }
  }

  Future<List<ServiceAgentDocument>> _fetchServiceAgentDocuments() async {
    try {
      final response = await DioClient.dio.get('/service-agents');
      final data = response.data?['data']?['documents'] as List? ?? [];
      final docs = data
          .map((json) => parseServiceAgentDocument(json as Map<String, dynamic>))
          .where((d) {
            final s = d.approvalStatus.toLowerCase();
            return s == 'approved' || s == 'active' || s == '';
          })
          .toList();
      return docs;
    } catch (e) {
      if (_cachedServiceAgents != null) return _cachedServiceAgents!;
      return ServiceAgentDocument.getMockData();
    }
  }

  // --- Pending Service Agent Documents ---

  Future<List<ServiceAgentDocument>> getPendingServiceAgentDocuments({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedPendingAgents != null &&
        _pendingAgentsCachedAt != null &&
        DateTime.now().difference(_pendingAgentsCachedAt!) < _serviceAgentsTtl) {
      return _cachedPendingAgents!;
    }

    if (_pendingAgentsInFlight != null) {
      return _pendingAgentsInFlight!;
    }

    _pendingAgentsInFlight = _fetchPendingServiceAgentDocuments();
    try {
      final result = await _pendingAgentsInFlight!;
      _cachedPendingAgents = result;
      _pendingAgentsCachedAt = DateTime.now();
      return result;
    } finally {
      _pendingAgentsInFlight = null;
    }
  }

  Future<List<ServiceAgentDocument>> _fetchPendingServiceAgentDocuments() async {
    try {
      final response = await DioClient.dio.get(
        '/service-agents',
        queryParameters: {'approval_status': 'pending'},
      );
      final data = response.data?['data']?['documents'] as List? ?? [];
      return data
          .map((json) => parseServiceAgentDocument(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      if (_cachedPendingAgents != null) return _cachedPendingAgents!;
      return [];
    }
  }

  // --- Service Agent Areas (Local-first) ---

  Future<List<AreaItem>> getServiceAgentAreas({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedAreas != null &&
        _areasCachedAt != null &&
        DateTime.now().difference(_areasCachedAt!) < _areasTtl) {
      return _cachedAreas!;
    }

    if (_areasInFlight != null) {
      return _areasInFlight!;
    }

    _areasInFlight = _fetchServiceAgentAreas(forceRefresh: forceRefresh);
    try {
      final result = await _areasInFlight!;
      _cachedAreas = result;
      _areasCachedAt = DateTime.now();
      return result;
    } finally {
      _areasInFlight = null;
    }
  }

  Future<List<AreaItem>> _fetchServiceAgentAreas({bool forceRefresh = false}) async {
    // 1. Offline-first: Read from local lookup database if available
    if (!forceRefresh) {
      try {
        final localLookups = await RepositoryCoordinator().lookupLocal.getLookupsByCategory('area');
        if (localLookups.isNotEmpty) {
          return localLookups
              .map((l) => AreaItem(id: l.id, name: l.name, pincode: l.pincode))
              .toList();
        }
      } catch (_) {}
    }

    // 2. Network fetch if local cache is empty or forceRefresh is true
    try {
      final meta = await PropertiesService().getPropertyMetadata();
      final areas = meta['data']?['metadata']?['areas'] as List? ?? [];
      if (areas.isNotEmpty) {
        return areas.map((json) => AreaItem(
          id: json['id']?.toString() ?? '',
          name: json['area_name']?.toString() ?? '',
          pincode: json['pincode']?.toString(),
        )).toList();
      }
    } catch (_) {}

    // 3. Fallback defaults if offline and unseeded
    return [
      AreaItem(id: '1', name: 'Visnagar', pincode: '384315'),
      AreaItem(id: '2', name: 'viramgam', pincode: '382150'),
      AreaItem(id: '3', name: 'Vasna road', pincode: '383255'),
      AreaItem(id: '4', name: 'Vaishnodevi', pincode: '382481'),
      AreaItem(id: '5', name: 'Thaltej', pincode: '380059'),
      AreaItem(id: '6', name: 'South Bopal', pincode: '380057'),
      AreaItem(id: '7', name: 'North Zone'),
      AreaItem(id: '8', name: 'Central'),
    ];
  }

  // --- Document Parser Helper ---

  static ServiceAgentDocument parseServiceAgentDocument(Map<String, dynamic> json) {
    List<String> areaList = [];
    final areaRaw = json['area'] ?? json['areas'] ?? json['service_area'] ?? json['target_area'];
    if (areaRaw is String && areaRaw.isNotEmpty) {
      areaList = areaRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    } else if (areaRaw is List) {
      areaList = areaRaw.map((e) => e.toString()).toList();
    }

    final imageUrl = json['agent_image_url']?.toString() ??
        json['image_url']?.toString() ??
        json['photo_url']?.toString() ??
        json['agent_photo']?.toString() ??
        json['photo']?.toString() ??
        json['avatar_url']?.toString();

    final dob = json['date_of_birth']?.toString() ??
        json['dob']?.toString() ??
        json['birth_date']?.toString();

    return ServiceAgentDocument(
      id: json['id']?.toString() ?? '',
      agentName: json['agent_name']?.toString() ?? '',
      serviceType: json['service_type']?.toString() ?? json['role']?.toString() ?? '',
      mobileNumber: json['mobile_number']?.toString() ?? '',
      documentName: json['document_type']?.toString() ?? '',
      documentType: json['document_type']?.toString() ?? '',
      uploadDate: DateTime.tryParse(json['upload_date']?.toString() ?? '') ?? DateTime.now(),
      uploadedBy: json['uploaded_by']?.toString() ?? 'admin',
      status: DocumentStatusExtension.fromString(json['status']?.toString() ?? 'active'),
      description: json['description']?.toString() ?? '',
      fileSize: json['file_size']?.toString() ?? '0 KB',
      fileExtension: json['file_extension']?.toString() ?? 'pdf',
      fileUrl: json['file_url']?.toString() ?? '',
      approvalStatus: json['approval_status']?.toString() ?? 'approved',
      agentImageUrl: imageUrl,
      dateOfBirth: dob,
      area: areaList,
    );
  }

  // --- Invalidation & Cache Management ---

  void invalidateMasterProperties() {
    _cachedMasterProperties = null;
    _masterPropertiesCachedAt = null;
  }

  void invalidateServiceAgents() {
    _cachedServiceAgents = null;
    _serviceAgentsCachedAt = null;
    _cachedPendingAgents = null;
    _pendingAgentsCachedAt = null;
  }

  void invalidateAreas() {
    _cachedAreas = null;
    _areasCachedAt = null;
  }

  void clearCache() {
    _cachedMasterProperties = null;
    _masterPropertiesCachedAt = null;
    _cachedServiceAgents = null;
    _serviceAgentsCachedAt = null;
    _cachedPendingAgents = null;
    _pendingAgentsCachedAt = null;
    _cachedAreas = null;
    _areasCachedAt = null;
  }

  // --- Visible For Testing ---

  @visibleForTesting
  bool get hasCachedProperties => _cachedMasterProperties != null;

  @visibleForTesting
  bool get hasCachedServiceAgents => _cachedServiceAgents != null;

  @visibleForTesting
  bool get hasCachedAreas => _cachedAreas != null;

  @visibleForTesting
  bool get isPropertiesFetchInFlight => _masterPropertiesInFlight != null;

  @visibleForTesting
  bool get isServiceAgentsFetchInFlight => _serviceAgentsInFlight != null;

  @visibleForTesting
  void setCachedPropertiesForTesting(List<PropertyModel> props) {
    _cachedMasterProperties = props;
    _masterPropertiesCachedAt = DateTime.now();
  }

  @visibleForTesting
  void setCachedServiceAgentsForTesting(List<ServiceAgentDocument> docs) {
    _cachedServiceAgents = docs;
    _serviceAgentsCachedAt = DateTime.now();
  }

  @visibleForTesting
  void setCachedAreasForTesting(List<AreaItem> areas) {
    _cachedAreas = areas;
    _areasCachedAt = DateTime.now();
  }
}
