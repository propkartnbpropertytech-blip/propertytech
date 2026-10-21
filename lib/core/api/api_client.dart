import 'dio_client.dart';

class ApiClient {
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await DioClient.dio.get(
      url,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> download(
    String urlPath,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    Object? data,
    Options? options,
  }) async {
    return await DioClient.dio.download(
      urlPath,
      savePath,
      onReceiveProgress: onReceiveProgress,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      deleteOnError: deleteOnError,
      lengthHeader: lengthHeader,
      data: data,
      options: options,
    );
  }

  Future<Response> post(
    String url,
    Map<String, dynamic> body, {
    Options? options,
  }) async {
    return await DioClient.dio.post(
      url,
      data: body,
      options: options,
    );
  }

  Future<Response> put(
    String url,
    Map<String, dynamic> body, {
    Options? options,
  }) async {
    return await DioClient.dio.put(
      url,
      data: body,
      options: options,
    );
  }

  Future<Response> patch(
    String url,
    Map<String, dynamic> body, {
    Options? options,
  }) async {
    return await DioClient.dio.patch(
      url,
      data: body,
      options: options,
    );
  }

  Future<Response> delete(
    String url, {
    Options? options,
  }) async {
    return await DioClient.dio.delete(
      url,
      options: options,
    );
  }
}