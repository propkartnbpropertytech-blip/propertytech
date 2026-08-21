import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  factory ApiException.fromDioException(DioException dioException) {
    String message = "An unexpected error occurred.";
    int? statusCode = dioException.response?.statusCode;

    if (dioException.response != null && dioException.response?.data != null) {
      final data = dioException.response!.data;
      if (data is Map<String, dynamic>) {
        // Handle common backend error formats (e.g. { "message": "..." } or { "error": "..." })
        message = data['message'] ?? data['error'] ?? message;
      } else if (data is String) {
        message = data;
      }
    } else {
      switch (dioException.type) {
        case DioExceptionType.connectionTimeout:
          message = "Connection timeout. Please try again.";
          break;
        case DioExceptionType.sendTimeout:
          message = "Send timeout in association with server.";
          break;
        case DioExceptionType.receiveTimeout:
          message = "Receive timeout in connection.";
          break;
        case DioExceptionType.badCertificate:
          message = "Bad certificate.";
          break;
        case DioExceptionType.badResponse:
          message = "Server response error (${dioException.response?.statusCode}).";
          break;
        case DioExceptionType.cancel:
          message = "Request to the server was cancelled.";
          break;
        case DioExceptionType.connectionError:
          message = "No internet connection detected.";
          break;
        case DioExceptionType.unknown:
          message = "Connection to server failed.";
          break;
        default:
          message = "Unexpected connection error occurred.";
          break;
      }
    }

    return ApiException(message: message, statusCode: statusCode);
  }

  @override
  String toString() => message;
}
