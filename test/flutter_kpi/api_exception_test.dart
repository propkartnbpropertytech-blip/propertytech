import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/api/api_exception.dart';

void main() {
  group('Step 8.5: ApiException Contract & Security Masking Tests', () {
    test('1. Parses Step 8.4 machine-readable error format accurately', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/dashboard/kpis'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/dashboard/kpis'),
          statusCode: 400,
          data: {
            'success': false,
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'Invalid date range: startDate must be before endDate.',
              'details': [
                {'field': 'startDate', 'issue': 'Out of bounds'}
              ]
            },
            'requestId': 'req-test-uuid-1234',
          },
        ),
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.statusCode, equals(400));
      expect(apiException.code, equals('VALIDATION_ERROR'));
      expect(apiException.message, equals('Invalid date range: startDate must be before endDate.'));
      expect(apiException.requestId, equals('req-test-uuid-1234'));
      expect(apiException.details?.length, equals(1));
    });

    test('2. Extracts correlation requestId from HTTP response headers', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/dashboard/kpis'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/dashboard/kpis'),
          statusCode: 401,
          headers: Headers.fromMap({
            'x-request-id': ['header-trace-5678'],
          }),
          data: {
            'message': 'Unauthorized access.',
          },
        ),
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.statusCode, equals(401));
      expect(apiException.requestId, equals('header-trace-5678'));
      expect(apiException.message, equals('Unauthorized access.'));
    });

    test('3. Prevents internal database error leakages (masks raw SQL errors)', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/dashboard/kpis'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/dashboard/kpis'),
          statusCode: 500,
          data: {
            'message': 'ERROR: syntax error at or near "FROM_PROPERTIES" at character 42',
          },
        ),
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.statusCode, equals(500));
      expect(apiException.code, equals('INTERNAL_SERVER_ERROR'));
      expect(apiException.message, equals('A database processing error occurred. Please contact support.'));
      // Raw query must never leak
      expect(apiException.message.contains('FROM_PROPERTIES'), isFalse);
    });

    test('4. Handles connection timeout cleanly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/dashboard/kpis'),
        type: DioExceptionType.connectionTimeout,
      );

      final apiException = ApiException.fromDioException(dioException);

      expect(apiException.code, equals('CONNECTION_TIMEOUT'));
      expect(apiException.message, contains('Connection timeout'));
    });
  });
}
