import 'dart:convert';
import 'package:propkart/features/builders/models/builder_model.dart';
import 'package:propkart/features/builders/services/builders_service.dart';
import 'package:propkart/core/storage/repository_coordinator.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/core/storage/model_mappers.dart';
import 'package:propkart/core/storage/performance_logger.dart';

class BuildersRepository {
  final BuildersService _buildersService = BuildersService();
  final RepositoryCoordinator _coordinator = RepositoryCoordinator();

  Future<List<BuilderModel>> getBuilders({String? search, String? tier}) async {
    final start = DateTime.now();

    final localList = await _coordinator.builderLocal.getBuilders(search: search, tier: tier);
    final isarReadMs = DateTime.now().difference(start).inMilliseconds;

    final parseStart = DateTime.now();
    final builders = localList.map((item) => item.toModel()).toList();
    final jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;

    final totalMs = DateTime.now().difference(start).inMilliseconds;
    PerformanceLogger().logMetric(
      operation: 'BuildersRepository.getBuilders (local)',
      isarReadMs: isarReadMs,
      jsonParseMs: jsonParseMs,
      totalMs: totalMs,
    );

    _triggerBackgroundBuildersRefresh(search: search, tier: tier);

    return builders;
  }

  void _triggerBackgroundBuildersRefresh({String? search, String? tier}) {
    final start = DateTime.now();
    _buildersService.getBuilders(search: search, tier: tier).then((response) async {
      final networkMs = DateTime.now().difference(start).inMilliseconds;

      final parseStart = DateTime.now();
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final list = data['builders'] as List? ?? [];
      final freshList = list.map((item) => BuilderModel.fromJson(item)).toList();
      final jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;

      final writeStart = DateTime.now();
      final localEntities = freshList.map((b) => b.toLocal()).toList();
      await _coordinator.builderLocal.saveBuilders(localEntities);
      final isarWriteMs = DateTime.now().difference(writeStart).inMilliseconds;

      final totalMs = DateTime.now().difference(start).inMilliseconds;
      PerformanceLogger().logMetric(
        operation: 'BuildersRepository.getBuilders (background refresh)',
        networkMs: networkMs,
        jsonParseMs: jsonParseMs,
        isarWriteMs: isarWriteMs,
        totalMs: totalMs,
      );

      _coordinator.refreshBuilders();
    }).catchError((_) {});
  }

  Future<BuilderModel> createBuilder(BuilderModel builder) async {
    try {
      final response = await _buildersService.createBuilder(builder.toJson());
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final fresh = BuilderModel.fromJson(data['builder'] ?? {});

      await _coordinator.builderLocal.saveBuilders([fresh.toLocal()]);
      _coordinator.refreshBuilders();
      return fresh;
    } catch (e) {
      final tempId = 'temp_builder_${DateTime.now().millisecondsSinceEpoch}';
      final json = builder.toJson();
      json['id'] = tempId;
      json['created_at'] = DateTime.now().toIso8601String();

      final fresh = BuilderModel.fromJson(json);
      await _coordinator.builderLocal.saveBuilders([fresh.toLocal()]);

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/builders'
        ..method = 'POST'
        ..payloadJson = jsonEncode(builder.toJson())
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshBuilders();
      return fresh;
    }
  }

  Future<BuilderModel> updateBuilder(BuilderModel builder) async {
    try {
      final response = await _buildersService.updateBuilder(builder.id, builder.toJson());
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final fresh = BuilderModel.fromJson(data['builder'] ?? {});

      await _coordinator.builderLocal.saveBuilders([fresh.toLocal()]);
      _coordinator.refreshBuilders();
      return fresh;
    } catch (e) {
      final json = builder.toJson();
      json['id'] = builder.id;

      final fresh = BuilderModel.fromJson(json);
      await _coordinator.builderLocal.saveBuilders([fresh.toLocal()]);

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/builders/${builder.id}'
        ..method = 'PUT'
        ..payloadJson = jsonEncode(builder.toJson())
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshBuilders();
      return fresh;
    }
  }

  Future<void> deleteBuilder(String id) async {
    try {
      await _buildersService.deleteBuilder(id);
      await _coordinator.builderLocal.deleteBuilder(id);
      _coordinator.refreshBuilders();
    } catch (e) {
      await _coordinator.builderLocal.deleteBuilder(id);

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/builders/$id'
        ..method = 'DELETE'
        ..payloadJson = '{}'
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshBuilders();
    }
  }
}
