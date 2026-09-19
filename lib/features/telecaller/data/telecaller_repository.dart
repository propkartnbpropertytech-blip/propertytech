import '../../../core/api/api_constants.dart';
import '../../../core/api/dio_client.dart';

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

  Future<Map<String, dynamic>> recordOutcome(
    String leadId, {
    required String outcome,
    String? remarks,
    String? salesUserId,
    String? callbackAt,
  }) async {
    final res = await DioClient.dio.post(
      '/telecaller/leads/$leadId/outcome',
      data: {
        'outcome': outcome,
        if (remarks != null) 'remarks': remarks,
        if (salesUserId != null) 'salesUserId': salesUserId,
        if (callbackAt != null) 'callbackAt': callbackAt,
      },
    );
    return Map<String, dynamic>.from(res.data['data'] ?? {});
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
}
