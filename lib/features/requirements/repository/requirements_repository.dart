import 'dart:convert';
import 'package:propkart/features/requirements/models/requirement_model.dart';
import 'package:propkart/features/requirements/services/requirements_service.dart';
import 'package:propkart/core/storage/repository_coordinator.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/core/storage/model_mappers.dart';
import 'package:propkart/core/storage/performance_logger.dart';
import 'package:propkart/core/security/role_guard.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:collection/collection.dart';

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
    var requirements = localList.map((item) => item.toModel()).toList();

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
        // Telecaller: same leads rights as their supervisor Admin
        requirements = requirements.where((r) {
          final isCreator = r.createdBy == currentUser.id ||
              (r.createdBy != null && uName.isNotEmpty && r.createdBy!.trim().toLowerCase() == uName) ||
              (r.creatorName != null && uName.isNotEmpty && r.creatorName!.trim().toLowerCase() == uName);
          return isCreator || r.adminId == currentUser.adminId;
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
      );
    }

    return requirements;
  }

  void _triggerBackgroundRequirementsRefresh({
    String? search,
    String? configurationId,
    String? propertyTypeId,
    String? status,
    String? listingTypeId,
  }) {
    if (_refreshInFlight != null) return;
    if (_lastRefreshAt != null && DateTime.now().difference(_lastRefreshAt!) < _minRefreshInterval) {
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
      final freshList = list.map((item) => RequirementModel.fromJson(item)).toList();
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
        return local;
      }).toList();
      await _coordinator.requirementLocal.saveRequirements(localEntities);
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

  Future<RequirementModel> updateRequirement(RequirementModel req) async {
    try {
      final response = await _requirementsService.updateRequirement(req.id, req.toBackendJson());
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final reqJson = Map<String, dynamic>.from(data['requirement'] as Map? ?? {});
      if (req.remarks != null && req.remarks!.trim().isNotEmpty) {
        reqJson['remarks'] = req.remarks!.trim();
      }
      final fresh = RequirementModel.fromJson(reqJson);

      await _coordinator.requirementLocal.saveRequirements([fresh.toLocal()]);
      _coordinator.refreshRequirements();
      return fresh;
    } catch (e) {
      print("RequirementsRepository.updateRequirement error: $e");
      final json = req.toBackendJson();
      json['id'] = req.id;
      json['updated_at'] = DateTime.now().toIso8601String();

      final fresh = RequirementModel.fromJson(json);
      await _coordinator.requirementLocal.saveRequirements([fresh.toLocal()]);

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/requirements/${req.id}'
        ..method = 'PUT'
        ..payloadJson = jsonEncode(req.toBackendJson())
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshRequirements();
      return fresh;
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
        if (data.containsKey('notes')) {
          localItem.notes = data['notes'] as String?;
        }
        await _coordinator.requirementLocal.saveRequirements([localItem]);
      } else {
        final existingList = await _coordinator.requirementLocal.getRequirements();
        final matches = existingList.where((r) => r.id == id).toList();
        if (matches.isNotEmpty) {
          final match = matches.first;
          if (data.containsKey('notes')) {
            match.notes = data['notes'];
          }
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
        if (data.containsKey('notes')) {
          match.notes = data['notes'];
        }
        await _coordinator.requirementLocal.saveRequirements([match]);
      }
      _coordinator.refreshRequirements();
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
}
