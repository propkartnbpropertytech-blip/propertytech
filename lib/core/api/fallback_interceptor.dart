import 'package:dio/dio.dart';
import 'api_constants.dart';
import '../config/app_env.dart';
import 'dio_client.dart';

class FallbackInterceptor extends Interceptor {
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (AppEnv.isLocal) {
      return super.onError(err, handler);
    }

    final isNetworkError = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    if (isNetworkError &&
        ApiConstants.primaryBaseUrl != ApiConstants.backupBaseUrl &&
        err.requestOptions.baseUrl == ApiConstants.primaryBaseUrl) {
      final options = err.requestOptions;
      options.baseUrl = ApiConstants.backupBaseUrl;
      try {
        final response = await DioClient.dio.fetch(options);
        return handler.resolve(response);
      } catch (retryErr) {
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
