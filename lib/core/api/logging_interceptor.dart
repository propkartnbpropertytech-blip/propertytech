import 'dart:math';
import 'package:dio/dio.dart';
import '../utils/app_logger.dart';

String _generateUuidV4() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(256));
  values[6] = (values[6] & 0x0f) | 0x40;
  values[8] = (values[8] & 0x3f) | 0x80;
  final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}

/// Dio interceptor for clean, structured request/response/error logging using [AppLogger].
class LoggingInterceptor extends Interceptor {
  static const _startTimeKey = '_requestStartTime';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startTimeKey] = DateTime.now().millisecondsSinceEpoch;
    final requestId = options.headers['X-Request-Id'] ??
        options.headers['X-Correlation-Id'] ??
        _generateUuidV4();
    options.headers['X-Request-Id'] = requestId;
    options.headers['X-Correlation-Id'] = requestId;
    options.extra['_requestId'] = requestId;
    
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

    final requestId = response.headers.value('x-request-id') ??
        response.headers.value('x-correlation-id') ??
        response.requestOptions.extra['_requestId'] as String?;

    AppLogger.network(
      method,
      path,
      statusCode: statusCode,
      durationMs: durationMs,
      requestId: requestId,
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

    final typeLabel = err.type.name;
    final inner = err.error?.toString();
    final combined = [
      if (errorMsg != null && errorMsg.toString().isNotEmpty) errorMsg,
      typeLabel,
      if (inner != null && inner.isNotEmpty) inner,
    ].join(' | ');

    final requestId = err.response?.headers.value('x-request-id') ??
        err.response?.headers.value('x-correlation-id') ??
        err.requestOptions.extra['_requestId'] as String?;

    AppLogger.network(
      method,
      path,
      statusCode: statusCode,
      error: combined,
      durationMs: durationMs,
      requestId: requestId,
    );

    super.onError(err, handler);
  }
}
