import '../../../core/api/api_constants.dart';
import '../../../core/api/dio_client.dart';
import '../../integration/services/integration_service.dart';

class TelecallerRepository {
  Future<Map<String, dynamic>> dashboard() async {
    final res = await DioClient.dio.get(ApiConstants.telecallerDashboard);
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<Map<String, dynamic>> setAvailability(String status) async {
    final res = await DioClient.dio.post(
      ApiConstants.telecallerAvailability,
      data: {'status': status},
    );
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<void> heartbeat() async {
    await DioClient.dio.post(ApiConstants.telecallerHeartbeat);
  }

  Future<List<dynamic>> myLeads({String? status, bool? isOldUntouched}) async {
    final res = await DioClient.dio.get(
      ApiConstants.telecallerMyLeads,
      queryParameters: {
        if (status != null) 'status': status,
        if (isOldUntouched != null) 'isOldUntouched': isOldUntouched.toString(),
      },
    );
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<Map<String, dynamic>> startCall(String leadId) async {
    final res = await DioClient.dio.post('/telecaller/leads/$leadId/start-call');
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  /// Persists a telecaller outcome through the integrations lead API.
  /// `/telecaller/leads/:id/outcome` returns HTTP 500 in production, so
  /// assignment and status never stick. Calling Leads already uses transfer
  /// and follow-up, which do update the lead.
  Future<Map<String, dynamic>> recordOutcome(
    String leadId, {
    required String outcome,
    String? remarks,
    String? salesUserId,
    String? assignedToName,
    String? callbackAt,
  }) async {
    final service = IntegrationService();
    final code = outcome.trim().toUpperCase();

    if (code == 'CALLBACK') {
      final when = callbackAt == null ? null : DateTime.tryParse(callbackAt)?.toLocal();
      if (when == null) {
        throw Exception('Choose a callback date and time.');
      }
      final ok = await service.scheduleFollowup(leadId, when, remarks ?? '', status: 'Callback');
      if (!ok) {
        throw Exception('Failed to schedule the callback.');
      }
      return {'success': true};
    }

    final status = code == 'CNR'
        ? 'CNR'
        : (code == 'PICKED_UP' || code == 'PICKED UP' ? 'Picked Up' : outcome);
    final result = await service.transferLead(
      leadId,
      status: status,
      assignedTo: (code == 'PICKED_UP' || code == 'PICKED UP') ? salesUserId : null,
      assignedToName: (code == 'PICKED_UP' || code == 'PICKED UP') ? assignedToName : null,
      remarks: remarks,
    );
    if (result['success'] != true) {
      throw Exception((result['message'] ?? 'Failed to update this lead.').toString());
    }
    return result;
  }

  Future<List<dynamic>> callbacks({String? search, String? from, String? to, String? source}) async {
    final res = await DioClient.dio.get(
      ApiConstants.telecallerCallbacks,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (source != null && source.isNotEmpty) 'source': source,
      },
    );
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<List<dynamic>> cnr({String? search, String? from, String? to, String? source}) async {
    final res = await DioClient.dio.get(
      ApiConstants.telecallerCnr,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (source != null && source.isNotEmpty) 'source': source,
      },
    );
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<List<dynamic>> callHistory(String leadId) async {
    final res = await DioClient.dio.get('/telecaller/leads/$leadId/call-history');
    return List<dynamic>.from(res.data['data'] ?? []);
  }

  Future<Map<String, dynamic>> updateAttemptRemarks(String attemptId, String remarks) async {
    final res = await DioClient.dio.patch(
      '/telecaller/attempts/$attemptId/remarks',
      data: {'remarks': remarks},
    );
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }

  Future<Map<String, dynamic>> getTransferredLeads({int page = 1, int limit = 10}) async {
    final res = await DioClient.dio.get(
      '/telecaller/transferred-leads',
      queryParameters: {'page': page, 'limit': limit},
    );
    return Map<String, dynamic>.from(res.data['data'] ?? {});
  }
}
