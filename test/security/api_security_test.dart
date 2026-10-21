import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:propkart/core/api/api_exception.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('API Client Security Contract Tests', () {
    test('ApiException extracts standard Step 8.4 envelope', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/properties'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/properties'),
          statusCode: 400,
          data: {
            'success': false,
            'message': 'Invalid query parameter',
            'code': 'VALIDATION_ERROR',
            'requestId': 'req-safe-uuid-1234',
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'Invalid query parameter',
              'details': ['limit must be <= 100'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.statusCode, equals(400));
      expect(apiException.code, equals('VALIDATION_ERROR'));
      expect(apiException.message, equals('Invalid query parameter'));
      expect(apiException.requestId, equals('req-safe-uuid-1234'));
      expect(apiException.details, isNotEmpty);
    });

    test('ApiException masks raw database errors from the client', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/properties'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/properties'),
          statusCode: 500,
          data: {
            'message': 'syntax error at or near "SELECT * FROM public.properties"',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.message.contains('syntax error'), isFalse);
      expect(apiException.message.contains('SELECT * FROM'), isFalse);
      expect(apiException.message, equals('A database processing error occurred. Please contact support.'));
      expect(apiException.code, equals('INTERNAL_SERVER_ERROR'));
    });
  });
}
