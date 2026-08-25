import 'package:dio/dio.dart';
import '../utils/app_logger.dart';

/// Dio interceptor for clean, structured request/response/error logging using [AppLogger].
class LoggingInterceptor extends Interceptor {
  static const _startTimeKey = '_requestStartTime';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startTimeKey] = DateTime.now().millisecondsSinceEpoch;
    
    final query = options.queryParameters.isNotEmpty ? '?${options.queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}' : '';
    AppLogger.d('➡️ [HTTP ${options.method}] ${options.baseUrl}${options.path}$query');
    
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = response.requestOptions.extra[_startTimeKey] as int?;
    final durationMs = startTime != null ? DateTime.now().millisecondsSinceEpoch - startTime : null;
    
    final method = response.requestOptions.method;
    final path = response.requestOptions.path;
    final statusCode = response.statusCode ?? 200;

    AppLogger.network(
      method,
      path,
      statusCode: statusCode,
      durationMs: durationMs,
    );

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final startTime = err.requestOptions.extra[_startTimeKey] as int?;
    final durationMs = startTime != null ? DateTime.now().millisecondsSinceEpoch - startTime : null;
    
    final method = err.requestOptions.method;
    final path = err.requestOptions.path;
    final statusCode = err.response?.statusCode;
    final errorMsg = err.response?.data is Map && err.response?.data['message'] != null
        ? err.response?.data['message']
        : err.message;

    AppLogger.network(
      method,
      path,
      statusCode: statusCode,
      error: errorMsg ?? err.type.toString(),
      durationMs: durationMs,
    );

    super.onError(err, handler);
  }
}
