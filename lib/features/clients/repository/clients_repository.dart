import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/client_model.dart';
import '../services/clients_service.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../../core/storage/isar_collections.dart';
import '../../../core/storage/model_mappers.dart';
import '../../../core/storage/performance_logger.dart';

class ClientsRepository {
  final ClientsService _clientsService = ClientsService();
  final RepositoryCoordinator _coordinator = RepositoryCoordinator();

  Future<List<ClientModel>> getClients({
    String? search,
    String? stage,
    String? source,
  }) async {
    final start = DateTime.now();

    final localList = await _coordinator.clientLocal.getClients(
      search: search,
      stage: stage,
      source: source,
    );
    final isarReadMs = DateTime.now().difference(start).inMilliseconds;

    final parseStart = DateTime.now();
    final clients = localList.map((item) => item.toModel()).toList();
    final jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;

    final totalMs = DateTime.now().difference(start).inMilliseconds;
    PerformanceLogger().logMetric(
      operation: 'ClientsRepository.getClients (local)',
      isarReadMs: isarReadMs,
      jsonParseMs: jsonParseMs,
      totalMs: totalMs,
    );

    _triggerBackgroundClientsRefresh(search: search, stage: stage, source: source);

    return clients;
  }

  void _triggerBackgroundClientsRefresh({
    String? search,
    String? stage,
    String? source,
  }) {
    final start = DateTime.now();
    _clientsService.getClients(search: search, stage: stage, source: source).then((response) async {
      final networkMs = DateTime.now().difference(start).inMilliseconds;

      final parseStart = DateTime.now();
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final list = data['clients'] as List? ?? [];
      final freshList = list.map((item) => ClientModel.fromJson(item)).toList();
      final jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;

      final writeStart = DateTime.now();
      final localEntities = freshList.map((c) => c.toLocal()).toList();
      await _coordinator.clientLocal.saveClients(localEntities);
      final isarWriteMs = DateTime.now().difference(writeStart).inMilliseconds;

      final totalMs = DateTime.now().difference(start).inMilliseconds;
      PerformanceLogger().logMetric(
        operation: 'ClientsRepository.getClients (background refresh)',
        networkMs: networkMs,
        jsonParseMs: jsonParseMs,
        isarWriteMs: isarWriteMs,
        totalMs: totalMs,
      );

      _coordinator.refreshClients();
    }).catchError((err) {
      print("⚠️ [CLIENT SYNC] Background refresh error: $err");
    });
  }

  Future<ClientModel> createClient(ClientModel client) async {
    try {
      final response = await _clientsService.createClient(client.toJson());
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final fresh = ClientModel.fromJson(data['client'] ?? {});

      await _coordinator.clientLocal.saveClients([fresh.toLocal()]);
      _coordinator.refreshClients();
      return fresh;
    } catch (e) {
      final tempId = 'temp_client_${DateTime.now().millisecondsSinceEpoch}';
      final json = client.toJson();
      json['id'] = tempId;
      json['createdAt'] = DateTime.now().toIso8601String();

      final fresh = ClientModel.fromJson(json);
      await _coordinator.clientLocal.saveClients([fresh.toLocal()]);

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/clients'
        ..method = 'POST'
        ..payloadJson = jsonEncode(client.toJson())
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshClients();
      return fresh;
    }
  }

  Future<ClientModel> updateClient(ClientModel client) async {
    try {
      final response = await _clientsService.updateClient(client.id, client.toJson());
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final fresh = ClientModel.fromJson(data['client'] ?? {});

      await _coordinator.clientLocal.saveClients([fresh.toLocal()]);
      _coordinator.refreshClients();
      return fresh;
    } catch (e) {
      final json = client.toJson();
      json['id'] = client.id;

      final fresh = ClientModel.fromJson(json);
      await _coordinator.clientLocal.saveClients([fresh.toLocal()]);

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/clients/${client.id}'
        ..method = 'PUT'
        ..payloadJson = jsonEncode(client.toJson())
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshClients();
      return fresh;
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      await _clientsService.deleteClient(id);
      await _coordinator.clientLocal.deleteClient(id);
      _coordinator.refreshClients();
    } catch (e) {
      await _coordinator.clientLocal.deleteClient(id);

      final outboxItem = OutboxLocal()
        ..id = 'outbox_${DateTime.now().millisecondsSinceEpoch}'
        ..endpoint = '/clients/$id'
        ..method = 'DELETE'
        ..payloadJson = '{}'
        ..createdAt = DateTime.now()
        ..deviceId = 'device_crm_123';
      await _coordinator.outboxLocal.queueRequest(outboxItem);

      _coordinator.refreshClients();
    }
  }
}
