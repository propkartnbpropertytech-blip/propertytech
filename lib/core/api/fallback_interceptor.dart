import 'package:dio/dio.dart';
import 'api_constants.dart';
import 'dio_client.dart';

class FallbackInterceptor extends Interceptor {
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isNetworkError = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    // Only retry on the backup if the request originally targeted the primary baseUrl
    if (isNetworkError && err.requestOptions.baseUrl == ApiConstants.primaryBaseUrl) {
      final options = err.requestOptions;
      
      // Update the base URL to point to the backup/fallback server
      options.baseUrl = ApiConstants.backupBaseUrl;
      
      try {
        // Fetch/retry using the updated options
        final response = await DioClient.dio.fetch(options);
        return handler.resolve(response);
      } catch (retryErr) {
        // If the backup retry fails, return the fallback error or original error
        if (retryErr is DioException) {
          return super.onError(retryErr, handler);
        }
        return super.onError(
          DioException(
            requestOptions: options,
            error: retryErr,
            type: DioExceptionType.unknown,
            message: "Retry on fallback backend failed: ${retryErr.toString()}",
          ),
          handler,
        );
      }
    }
    return super.onError(err, handler);
  }
}
