import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final String? requestId;
  final List<dynamic>? details;

  ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.requestId,
    this.details,
  });

  factory ApiException.fromDioException(DioException dioException) {
    String message = "An unexpected error occurred.";
    int? statusCode = dioException.response?.statusCode;
    String? code;
    String? requestId = dioException.response?.headers.value('x-request-id');
    List<dynamic>? details;

    if (dioException.response != null && dioException.response?.data != null) {
      final data = dioException.response!.data;
      if (data is Map<String, dynamic>) {
        // Step 8.4 Envelope: { success: false, error: { code, message, details }, requestId }
        if (data['error'] is Map) {
          final errMap = data['error'] as Map;
          message = errMap['message']?.toString() ?? message;
          code = errMap['code']?.toString();
          if (errMap['details'] is List) {
            details = (errMap['details'] as List).cast<dynamic>();
          }
        } else if (data['error'] is String) {
          message = data['error'] as String;
        } else if (data['message'] != null) {
          message = data['message'].toString();
        }

        if (data['code'] != null && code == null) {
          code = data['code'].toString();
        }
        if (data['requestId'] != null && (requestId == null || requestId.isEmpty)) {
          requestId = data['requestId'].toString();
        }
      } else if (data is String) {
        message = data;
      }
    } else {
      switch (dioException.type) {
        case DioExceptionType.connectionTimeout:
          message = "Connection timeout. Please try again.";
          code = "CONNECTION_TIMEOUT";
          break;
        case DioExceptionType.sendTimeout:
          message = "Send timeout in association with server.";
          code = "SEND_TIMEOUT";
          break;
        case DioExceptionType.receiveTimeout:
          message = "Receive timeout in connection.";
          code = "RECEIVE_TIMEOUT";
          break;
        case DioExceptionType.badCertificate:
          message = "Bad certificate.";
          code = "BAD_CERTIFICATE";
          break;
        case DioExceptionType.badResponse:
          message = "Server response error (${dioException.response?.statusCode}).";
          code = "BAD_RESPONSE";
          break;
        case DioExceptionType.cancel:
          message = "Request to the server was cancelled.";
          code = "REQUEST_CANCELLED";
          break;
        case DioExceptionType.connectionError:
          message = "No internet connection detected.";
          code = "NETWORK_ERROR";
          break;
        case DioExceptionType.unknown:
          message = "Connection to server failed.";
          code = "UNKNOWN_ERROR";
          break;
        default:
          message = "Connection error. Please try again.";
          code = "CONNECTION_ERROR";
          break;
      }
    }

    // Safety guard: never expose raw SQL/DB internal leakages to UI
    if (message.contains('syntax error at or near') ||
        message.contains('relation') && message.contains('does not exist') ||
        message.contains('pg_') ||
        message.contains('column') && message.contains('does not exist')) {
      message = "A database processing error occurred. Please contact support.";
      code ??= "INTERNAL_SERVER_ERROR";
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      code: code,
      requestId: requestId,
      details: details,
    );
  }

  @override
  String toString() => message;
}
