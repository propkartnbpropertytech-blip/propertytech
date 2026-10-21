import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:propkart/core/api/api_exception.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Error Sanitization Security Tests', () {
    test('PostgreSQL relation errors are sanitized to prevent database schema enumeration', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/leads'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/leads'),
          statusCode: 500,
          data: {
            'message': 'relation "public.integration_leads" does not exist in schema',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.message.contains('integration_leads'), isFalse);
      expect(apiException.message.contains('relation'), isFalse);
      expect(apiException.message, equals('A database processing error occurred. Please contact support.'));
      expect(apiException.code, equals('INTERNAL_SERVER_ERROR'));
    });

    test('PostgreSQL column errors are sanitized', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/properties'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/properties'),
          statusCode: 500,
          data: {
            'message': 'column "secret_admin_notes" does not exist',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.message.contains('secret_admin_notes'), isFalse);
      expect(apiException.message, equals('A database processing error occurred. Please contact support.'));
    });

    test('pg_ catalog references are stripped', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/kpis'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/kpis'),
          statusCode: 500,
          data: {
            'message': 'ERROR: permission denied for table pg_shadow',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.message.contains('pg_shadow'), isFalse);
      expect(apiException.message, equals('A database processing error occurred. Please contact support.'));
    });
  });
}
