import '../../../core/api/api_client.dart';

class PortalIntegrationsService {
  final ApiClient _api = ApiClient();
  static List<Map<String, dynamic>>? cached;
  static DateTime? cachedAt;

  static void invalidate() {
    cached = null;
    cachedAt = null;
  }

  Future<List<Map<String, dynamic>>> listCached() async {
    final at = cachedAt;
    if (cached != null && at != null && DateTime.now().difference(at).inSeconds < 15) {
      return cached!;
    }
    final rows = await list();
    cached = rows;
    cachedAt = DateTime.now();
    return rows;
  }

  Future<List<Map<String, dynamic>>> list() async {
    final response = await _api.get('/portal-integrations');
    final data = response.data;
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> create({
    required String name,
    required String provider,
    String integrationType = 'API_PULL',
  }) async {
    final response = await _api.post('/portal-integrations', {
      'name': name,
      'provider': provider,
      'integrationType': integrationType,
    });
    PortalIntegrationsService.invalidate();
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<Map<String, dynamic>> getOne(String id) async {
    final response = await _api.get('/portal-integrations/$id');
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<Map<String, dynamic>> save(String id, Map<String, dynamic> body) async {
    final response = await _api.put('/portal-integrations/$id', body);
    PortalIntegrationsService.invalidate();
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<void> saveCredential(String id, {required String key, required String name, required String type, required String value}) async {
    await _api.post('/portal-integrations/$id/credentials', {
      'key': key,
      'name': name,
      'type': type,
      'value': value,
    });
  }

  Future<Map<String, dynamic>> test(String id) async {
    final response = await _api.post('/portal-integrations/$id/test', {});
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<Map<String, dynamic>> sample(String id) async {
    final response = await _api.post('/portal-integrations/$id/sample', {});
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<Map<String, dynamic>> pause(String id) async {
    final response = await _api.post('/portal-integrations/$id/pause', {});
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<Map<String, dynamic>> activate(String id, {bool force = false}) async {
    final response = await _api.post('/portal-integrations/$id/activate', {'force': force});
    PortalIntegrationsService.invalidate();
    return Map<String, dynamic>.from((response.data as Map)['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> logs(String id) async {
    final response = await _api.get('/portal-integrations/$id/logs');
    final data = response.data;
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> destinations() async {
    final response = await _api.get('/portal-integrations/destinations');
    final data = response.data;
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
    }
    return [];
  }
}
