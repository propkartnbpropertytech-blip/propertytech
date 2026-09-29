import '../../../core/api/dio_client.dart';
import '../models/business_insight_summary.dart';

class BusinessInsightService {
  static final BusinessInsightService instance = BusinessInsightService._();
  BusinessInsightService._();

  /// Fetches authoritative business insight summary counts from PostgreSQL backend
  Future<BusinessInsightSummary?> fetchSummary({
    DateTime? from,
    DateTime? to,
    String? source,
    String? leadType,
    String? leadStatus,
    String? telecallerId,
    String? salesUserId,
    String? organizationId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) queryParams['from'] = from.toIso8601String();
      if (to != null) queryParams['to'] = to.toIso8601String();
      if (source != null && source.isNotEmpty && source.toLowerCase() != 'all' && source.toLowerCase() != 'all sources') {
        queryParams['source'] = source;
      }
      if (leadType != null && leadType.isNotEmpty && leadType.toLowerCase() != 'all') {
        queryParams['leadType'] = leadType;
      }
      if (leadStatus != null && leadStatus.isNotEmpty) {
        queryParams['leadStatus'] = leadStatus;
      }
      if (telecallerId != null && telecallerId.isNotEmpty) {
        queryParams['telecallerId'] = telecallerId;
      }
      if (salesUserId != null && salesUserId.isNotEmpty) {
        queryParams['salesUserId'] = salesUserId;
      }
      if (organizationId != null && organizationId.isNotEmpty) {
        queryParams['organization_id'] = organizationId;
      }

      final response = await DioClient.dio.get(
        '/reports/business-insight',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          return BusinessInsightSummary.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      // In case of error, return null to allow graceful fallback
      return null;
    }
  }

  /// Fetches leads matching source, leadType, kpi, telecaller, or date range
  Future<Map<String, dynamic>> fetchLeads({
    String? source,
    String? leadType,
    String? kpi,
    String? telecallerId,
    DateTime? from,
    DateTime? to,
    int limit = 500,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (from != null) queryParams['from'] = from.toIso8601String();
      if (to != null) queryParams['to'] = to.toIso8601String();
      if (source != null && source.isNotEmpty && source.toLowerCase() != 'all' && source.toLowerCase() != 'all sources') {
        queryParams['source'] = source;
      }
      if (leadType != null && leadType.isNotEmpty && leadType.toLowerCase() != 'all') {
        queryParams['leadType'] = leadType;
      }
      if (kpi != null && kpi.isNotEmpty && kpi.toLowerCase() != 'all') {
        queryParams['kpi'] = kpi;
      }
      if (telecallerId != null && telecallerId.isNotEmpty) {
        queryParams['telecallerId'] = telecallerId;
      }

      final response = await DioClient.dio.get(
        '/reports/business-insight/leads',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        final rawLeads = data['leads'] as List<dynamic>? ?? [];
        final total = data['total'] as int? ?? rawLeads.length;
        final leads = rawLeads
            .map((item) => BusinessInsightLead.fromJson(item as Map<String, dynamic>))
            .toList();

        return {
          'leads': leads,
          'total': total,
        };
      }
      return {'leads': <BusinessInsightLead>[], 'total': 0};
    } catch (e) {
      return {'leads': <BusinessInsightLead>[], 'total': 0};
    }
  }
}
