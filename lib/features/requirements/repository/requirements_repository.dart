import 'dart:convert';
import 'package:propkart/features/requirements/models/requirement_model.dart';
import 'package:propkart/features/requirements/services/requirements_service.dart';
import 'package:propkart/core/storage/repository_coordinator.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/core/storage/model_mappers.dart';
import 'package:propkart/core/storage/performance_logger.dart';
import 'package:propkart/core/security/role_guard.dart';
import 'package:propkart/core/storage/local_repositories.dart';

class RequirementsRepository {
  final RequirementsService _requirementsService = RequirementsService();
  final RepositoryCoordinator _coordinator = RepositoryCoordinator();

  void invalidateCache() {
    _coordinator.requirementLocal.saveRequirements([]);
    _coordinator.refreshRequirements();
  }

  static Future<void>? _refreshInFlight;
  static DateTime? _lastRefreshAt;
  static const _minRefreshInterval = Duration(seconds: 45);

  Future<List<RequirementModel>> getRequirements({
    String? search,
    String? configurationId,
    String? propertyTypeId,
    String? status,
    String? listingTypeId,
    bool refreshFromServer = true,
    bool forceRefresh = false,
  }) async {
    final start = DateTime.now();

    final localList = await _coordinator.requirementLocal.getRequirements(
      search: search,
      configurationId: configurationId,
      propertyTypeId: propertyTypeId,
      status: status,
    );
    final isarReadMs = DateTime.now().difference(start).inMilliseconds;

    final parseStart = DateTime.now();
    var requirements = localList.map((item) => _withRememberedMeta(item.toModel())).toList();

    // Apply RBAC role-based filtering on Requirements
    final currentUser = RoleGuard.currentUser;
    if (currentUser != null) {
      final role = currentUser.role;
      final uName = currentUser.fullName.trim().toLowerCase();
      if (role == 'Admin') {
        requirements = requirements.where((r) {
          final isCreator = r.createdBy == currentUser.id ||
              (r.createdBy != null && uName.isNotEmpty && r.createdBy!.trim().toLowerCase() == uName) ||
              (r.creatorName != null && uName.isNotEmpty && r.creatorName!.trim().toLowerCase() == uName);
          return isCreator || r.adminId == currentUser.id;
        }).toList();
      } else if (role == 'Telecaller') {
        // Telecaller: same team leads as their supervisor Admin, including assigned leads.
        final supervisorId = currentUser.adminId;
        requirements = requirements.where((r) {
          final isCreator = r.createdBy == currentUser.id ||
              (r.createdBy != null && uName.isNotEmpty && r.createdBy!.trim().toLowerCase() == uName) ||
              (r.creatorName != null && uName.isNotEmpty && r.creatorName!.trim().toLowerCase() == uName);
          final sameAdminTeam = supervisorId != null &&
              supervisorId.isNotEmpty &&
              (r.adminId == supervisorId || r.createdBy == supervisorId);
          return isCreator || sameAdminTeam;
        }).toList();
      } else if (role != 'Super Admin') {
        // Sales: own leads (including ones transferred away) plus leads assigned to them.
        requirements = requirements.where((r) {
          final isCreator = r.createdBy == currentUser.id ||
              (r.createdBy != null && uName.isNotEmpty && r.createdBy!.trim().toLowerCase() == uName) ||
              (r.creatorName != null && uName.isNotEmpty && r.creatorName!.trim().toLowerCase() == uName);
          final isAssignee = (r.assignedTo != null && (r.assignedTo == currentUser.id || (uName.isNotEmpty && r.assignedTo!.trim().toLowerCase() == uName))) ||
              (r.assigneeName != null && uName.isNotEmpty && r.assigneeName!.trim().toLowerCase() == uName);
          return isCreator || isAssignee;
        }).toList();
      }
    }

    if (listingTypeId != null && listingTypeId.isNotEmpty) {
      requirements = requirements.where((r) => r.listingTypeId == listingTypeId).toList();
    }
    final jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;

    final totalMs = DateTime.now().difference(start).inMilliseconds;
    PerformanceLogger().logMetric(
      operation: 'RequirementsRepository.getRequirements (local)',
      isarReadMs: isarReadMs,
      jsonParseMs: jsonParseMs,
      totalMs: totalMs,
    );

    if (refreshFromServer) {
      _triggerBackgroundRequirementsRefresh(
        search: search,
        configurationId: configurationId,
        propertyTypeId: propertyTypeId,
        status: status,
        listingTypeId: listingTypeId,
        force: forceRefresh,
      );
    }

    return requirements;
  }

  Future<void> refreshFromServerNow({
    String? search,
    String? configurationId,
    String? propertyTypeId,
    String? status,
    String? listingTypeId,
  }) async {
    _lastRefreshAt = null;
    if (_refreshInFlight != null) {
      try {
        await _refreshInFlight;
      } catch (_) {}
      _lastRefreshAt = null;
    }
    _triggerBackgroundRequirementsRefresh(
      search: search,
      configurationId: configurationId,
      propertyTypeId: propertyTypeId,
      status: status,
      listingTypeId: listingTypeId,
      force: true,
    );
    if (_refreshInFlight != null) {
      try {
        await _refreshInFlight;
      } catch (_) {}
    }
  }

  void _triggerBackgroundRequirementsRefresh({
    String? search,
    String? configurationId,
    String? propertyTypeId,
    String? status,
    String? listingTypeId,
    bool force = false,
  }) {
    if (_refreshInFlight != null) return;
    if (!force && _lastRefreshAt != null && DateTime.now().difference(_lastRefreshAt!) < _minRefreshInterval) {
      return;
    }

    final start = DateTime.now();
    _refreshInFlight = _requirementsService.getRequirements(
      search: search,
      configurationId: configurationId,
      propertyTypeId: propertyTypeId,
      status: status,
      listingTypeId: listingTypeId,
    ).then((response) async {
      _lastRefreshAt = DateTime.now();
      final networkMs = DateTime.now().difference(start).inMilliseconds;

      final parseStart = DateTime.now();
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final list = data['requirements'] as List? ?? [];
      final freshList = list.map((item) {
        final model = RequirementModel.fromJson(item);
        _rememberMeta(model);
        return model;
      }).toList();
      final jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;

      final writeStart = DateTime.now();
      final existingLocalMap = RequirementLocalRepository.inMemory;
      final localEntities = freshList.map((r) {
        final local = r.toLocal();
        final existing = existingLocalMap[r.id];
        if ((local.nextFollowupDate == null || local.nextFollowupDate!.trim().isEmpty) && existing != null) {
          local.nextFollowupDate = existing.nextFollowupDate;
        }
        if ((local.remarks == null || local.remarks!.trim().isEmpty) && existing != null) {
          local.remarks = existing.remarks;
        }
        if ((local.notes == null || local.notes!.trim().isEmpty) && existing != null) {
          local.notes = existing.notes;
        }
        // Keep the server assignee as-is so unassign (empty/null) actually sticks.
        return local;
      }).toList();
      await _coordinator.requirementLocal.saveRequirements(localEntities);
      _coordinator.refreshRequirements();
      final isarWriteMs = DateTime.now().difference(writeStart).inMilliseconds;

      final totalMs = DateTime.now().difference(start).inMilliseconds;
      PerformanceLogger().logMetric(
        operation: 'RequirementsRepository.getRequirements (background refresh)',
        networkMs: networkMs,
        jsonParseMs: jsonParseMs,
        isarWriteMs: isarWriteMs,
        totalMs: totalMs,
      );
    }).catchError((_) {}).whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<List<RequirementModel>> createRequirementsBulk(List<RequirementModel> reqs) async {
    if (reqs.isEmpty) return [];
    try {
      final payload = reqs.map((r) => r.toBackendJson()).toList();
      final response = await _requirementsService.createRequirementsBulk(payload);
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final list = data['requirements'] as List? ?? [];
      final freshList = list.map((item) => RequirementModel.fromJson(item)).toList();

      final localEntities = freshList.map((r) => r.toLocal()).toList();
      await _coordinator.requirementLocal.saveRequirements(localEntities);
      _coordinator.refreshRequirements();
      return freshList;
    } catch (e) {
      final created = <RequirementModel>[];
      for (final r in reqs) {
        try {
          created.add(await createRequirement(r, notify: false));
        } catch (_) {}
      }
      _coordinator.refreshRequirements();
      return created;
    }
  }

  Future<RequirementModel> createRequirement(RequirementModel req, {bool notify = true}) async {
    try {
      final response = await _requirementsService.createRequirement(req.toBackendJson());
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final fresh = RequirementModel.fromJson(data['requirement'] ?? {});

      await _coordinator.requirementLocal.saveRequirements([fresh.toLocal()]);
      if (notify) _coordinator.refreshRequirements();
      return fresh;
    } catch (e) {
      print("RequirementsRepository.createRequirement error: $e");
      final tempId = 'temp_req_${DateTime.now().millisecondsSinceEpoch}';
      final json = req.toBackendJson();
      json['id'] = tempId;
      json['created_at'] = DateTime.now().toIso8601String();
      json['updated_at'] = DateTime.now().toIso8601String();

      final fresh = RequirementModel.fromJson(json);
      await _coordinator.requirementLocal.saveRequirements([fresh.toLocal()]);

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/requirements'
        ..method = 'POST'
        ..payloadJson = jsonEncode(req.toBackendJson())
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      if (notify) _coordinator.refreshRequirements();
      return fresh;
    }
  }

  void _rememberMeta(RequirementModel req) {
    RequirementLocalRepository.rememberMetaCustomFields(req.id, req.metaCustomFields);
  }

  RequirementModel _withRememberedMeta(RequirementModel req) {
    final remembered = RequirementLocalRepository.metaCustomFieldsById[req.id];
    if (remembered == null || remembered.isEmpty) return req;
    return req.copyWith(metaCustomFields: {
      ...remembered,
      ...?req.metaCustomFields,
    });
  }

  RequirementModel _preserveLeadScope(RequirementModel submitted, RequirementModel incoming) {
    String? keep(String? next, String? fallback) {
      if (next != null && next.trim().isNotEmpty) return next;
      return fallback;
    }

    Map<String, dynamic>? mergedMeta;
    if (incoming.metaCustomFields != null || submitted.metaCustomFields != null) {
      mergedMeta = {
        ...?incoming.metaCustomFields,
        ...?submitted.metaCustomFields,
      };
    }

    final submittedStatus = submitted.status.trim();
    final incomingStatus = incoming.status.trim();
    final preservedStatus = submittedStatus.isNotEmpty
        ? submitted.status
        : (incomingStatus.isNotEmpty ? incoming.status : submitted.status);

    final merged = incoming.copyWith(
      adminId: keep(incoming.adminId, submitted.adminId),
      createdBy: keep(incoming.createdBy, submitted.createdBy),
      creatorName: keep(incoming.creatorName, submitted.creatorName),
      organizationId: keep(incoming.organizationId, submitted.organizationId),
      listingTypeId: keep(incoming.listingTypeId, submitted.listingTypeId),
      listingTypeName: keep(incoming.listingTypeName, submitted.listingTypeName),
      assignedTo: submitted.assignedTo ?? incoming.assignedTo,
      assigneeName: keep(submitted.assigneeName, incoming.assigneeName),
      status: preservedStatus,
      metaCustomFields: mergedMeta,
    );
    _rememberMeta(merged);
    return _withRememberedMeta(merged);
  }

  Future<RequirementModel> updateLeadStatus(RequirementModel req) async {
    _rememberMeta(req);
    final payload = <String, dynamic>{
      'status': req.status,
      if (req.metaCustomFields != null) 'meta_custom_fields': req.metaCustomFields,
      if (req.nextFollowupDate != null && req.nextFollowupDate!.trim().isNotEmpty)
        'next_followup_date': req.nextFollowupDate,
    };
    try {
      final response = await _requirementsService.updateRequirement(req.id, payload);
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final reqJson = Map<String, dynamic>.from(data['requirement'] as Map? ?? {});
      final fresh = reqJson.isEmpty ? req : RequirementModel.fromJson(reqJson);
      final merged = _preserveLeadScope(req, fresh);

      await _coordinator.requirementLocal.saveRequirements([merged.toLocal()]);
      _coordinator.refreshRequirements();
      return merged;
    } catch (e) {
      print("RequirementsRepository.updateLeadStatus error: $e");
      await _coordinator.requirementLocal.saveRequirements([req.toLocal()]);

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/requirements/${req.id}'
        ..method = 'PUT'
        ..payloadJson = jsonEncode(payload)
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshRequirements();
      return req;
    }
  }

  Future<RequirementModel> updateRequirement(RequirementModel req) async {
    try {
      final response = await _requirementsService.updateRequirement(req.id, req.toBackendJson());
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final reqJson = Map<String, dynamic>.from(data['requirement'] as Map? ?? {});
      if (req.remarks != null && req.remarks!.trim().isNotEmpty) {
        reqJson['remarks'] = req.remarks!.trim();
      }
      final fresh = reqJson.isEmpty ? req : RequirementModel.fromJson(reqJson);
      _rememberMeta(req);
      final merged = _preserveLeadScope(req, fresh);

      await _coordinator.requirementLocal.saveRequirements([merged.toLocal()]);
      _coordinator.refreshRequirements();
      return merged;
    } catch (e) {
      print("RequirementsRepository.updateRequirement error: $e");
      final json = req.toBackendJson();
      json['id'] = req.id;
      json['updated_at'] = DateTime.now().toIso8601String();

      final fresh = RequirementModel.fromJson(json);
      final merged = _preserveLeadScope(req, fresh);
      await _coordinator.requirementLocal.saveRequirements([merged.toLocal()]);

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/requirements/${req.id}'
        ..method = 'PUT'
        ..payloadJson = jsonEncode(req.toBackendJson())
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshRequirements();
      return merged;
    }
  }

  Future<void> updateRequirementFields(String id, Map<String, dynamic> data) async {
    try {
      final response = await _requirementsService.updateRequirement(id, data);
      final respData = response['data'] as Map<String, dynamic>? ?? {};
      final freshJson = respData['requirement'] as Map<String, dynamic>?;
      if (freshJson != null) {
        final fresh = RequirementModel.fromJson(freshJson);
        final localItem = fresh.toLocal();
        _applyRequirementFieldPatch(localItem, data);
        await _coordinator.requirementLocal.saveRequirements([localItem]);
      } else {
        final existingList = await _coordinator.requirementLocal.getRequirements();
        final matches = existingList.where((r) => r.id == id).toList();
        if (matches.isNotEmpty) {
          final match = matches.first;
          _applyRequirementFieldPatch(match, data);
          await _coordinator.requirementLocal.saveRequirements([match]);
        }
      }
      _coordinator.refreshRequirements();
    } catch (e) {
      print("RequirementsRepository.updateRequirementFields error: $e");
      final existingList = await _coordinator.requirementLocal.getRequirements();
      final matches = existingList.where((r) => r.id == id).toList();
      if (matches.isNotEmpty) {
        final match = matches.first;
        _applyRequirementFieldPatch(match, data);
        await _coordinator.requirementLocal.saveRequirements([match]);
      }
      _coordinator.refreshRequirements();
    }
  }

  void _applyRequirementFieldPatch(RequirementLocal match, Map<String, dynamic> data) {
    if (data.containsKey('notes')) {
      match.notes = data['notes'] as String?;
    }
    if (data.containsKey('assigned_to')) {
      match.assignedTo = data['assigned_to'] as String?;
    }
    if (data.containsKey('assignee_name') && data['assignee_name'] != null) {
      match.assigneeName = data['assignee_name'].toString();
    }
    if (data.containsKey('status') && data['status'] != null) {
      match.status = data['status'].toString();
    }
    if (data['meta_custom_fields'] is Map) {
      RequirementLocalRepository.rememberMetaCustomFields(
        match.id,
        Map<String, dynamic>.from(data['meta_custom_fields'] as Map),
      );
    }
  }

  Future<void> deleteRequirement(String id) async {
    try {
      await _requirementsService.deleteRequirement(id);
      await _coordinator.requirementLocal.deleteRequirement(id);
      _coordinator.refreshRequirements();
    } catch (e) {
      await _coordinator.requirementLocal.deleteRequirement(id);

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/requirements/$id'
        ..method = 'DELETE'
        ..payloadJson = '{}'
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshRequirements();
    }
  }

  Future<Map<String, dynamic>> getRequirementMatches(
    String requirementId, {
    int page = 1,
    int limit = 20,
    String? mode,
    int? minScore,
    bool includeNearby = false,
  }) async {
    return _requirementsService.getRequirementMatches(
      requirementId,
      page: page,
      limit: limit,
      mode: mode,
      minScore: minScore,
      includeNearby: includeNearby,
    );
  }
}
