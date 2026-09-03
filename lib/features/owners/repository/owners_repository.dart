import 'dart:convert';
import 'package:propkart/features/owners/models/owner_model.dart';
import 'package:propkart/features/owners/services/owners_service.dart';
import 'package:propkart/core/storage/repository_coordinator.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/core/storage/model_mappers.dart';
import 'package:propkart/core/storage/performance_logger.dart';

class OwnersRepository {
  final OwnersService _ownersService = OwnersService();
  final RepositoryCoordinator _coordinator = RepositoryCoordinator();

  Future<List<OwnerModel>> getOwners({String? search}) async {
    final start = DateTime.now();

    final localList = await _coordinator.ownerLocal.getOwners(search: search);
    final isarReadMs = DateTime.now().difference(start).inMilliseconds;

    final parseStart = DateTime.now();
    final owners = localList.map((item) => item.toModel()).toList();
    final jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;

    final totalMs = DateTime.now().difference(start).inMilliseconds;
    PerformanceLogger().logMetric(
      operation: 'OwnersRepository.getOwners (local)',
      isarReadMs: isarReadMs,
      jsonParseMs: jsonParseMs,
      totalMs: totalMs,
    );

    _triggerBackgroundOwnersRefresh(search: search);

    return owners;
  }

  void _triggerBackgroundOwnersRefresh({String? search}) {
    final start = DateTime.now();
    _ownersService.getOwners(search: search).then((response) async {
      final networkMs = DateTime.now().difference(start).inMilliseconds;

      final parseStart = DateTime.now();
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final list = data['owners'] as List? ?? [];
      final freshList = list.map((item) => OwnerModel.fromJson(item)).toList();
      final jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;

      final writeStart = DateTime.now();
      final localEntities = freshList.map((o) => o.toLocal()).toList();
      await _coordinator.ownerLocal.saveOwners(localEntities);
      final isarWriteMs = DateTime.now().difference(writeStart).inMilliseconds;

      final totalMs = DateTime.now().difference(start).inMilliseconds;
      PerformanceLogger().logMetric(
        operation: 'OwnersRepository.getOwners (background refresh)',
        networkMs: networkMs,
        jsonParseMs: jsonParseMs,
        isarWriteMs: isarWriteMs,
        totalMs: totalMs,
      );

      _coordinator.refreshOwners();
    }).catchError((_) {});
  }

  Future<OwnerModel> createOwner(OwnerModel owner) async {
    try {
      final response = await _ownersService.createOwner(owner.toJson());
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final fresh = OwnerModel.fromJson(data['owner'] ?? {});

      await _coordinator.ownerLocal.saveOwners([fresh.toLocal()]);
      _coordinator.refreshOwners();
      return fresh;
    } catch (e) {
      final tempId = 'temp_owner_${DateTime.now().millisecondsSinceEpoch}';
      final json = owner.toJson();
      json['id'] = tempId;
      json['created_at'] = DateTime.now().toIso8601String();

      final fresh = OwnerModel.fromJson(json);
      await _coordinator.ownerLocal.saveOwners([fresh.toLocal()]);

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/owners'
        ..method = 'POST'
        ..payloadJson = jsonEncode(owner.toJson())
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshOwners();
      return fresh;
    }
  }

  Future<OwnerModel> updateOwner(OwnerModel owner) async {
    try {
      final response = await _ownersService.updateOwner(owner.id, owner.toJson());
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final fresh = OwnerModel.fromJson(data['owner'] ?? {});

      await _coordinator.ownerLocal.saveOwners([fresh.toLocal()]);
      _coordinator.refreshOwners();
      return fresh;
    } catch (e) {
      final json = owner.toJson();
      json['id'] = owner.id;

      final fresh = OwnerModel.fromJson(json);
      await _coordinator.ownerLocal.saveOwners([fresh.toLocal()]);

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/owners/${owner.id}'
        ..method = 'PUT'
        ..payloadJson = jsonEncode(owner.toJson())
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshOwners();
      return fresh;
    }
  }

  Future<void> deleteOwner(String id) async {
    try {
      await _ownersService.deleteOwner(id);
      await _coordinator.ownerLocal.deleteOwner(id);
      _coordinator.refreshOwners();
    } catch (e) {
      await _coordinator.ownerLocal.deleteOwner(id);

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/owners/$id'
        ..method = 'DELETE'
        ..payloadJson = '{}'
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshOwners();
    }
  }
}
