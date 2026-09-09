import 'package:dio/dio.dart';

import 'dio_client.dart';

class ApiClient {
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await DioClient.dio.get(
      url,
      queryParameters: queryParameters,
    );
  }

  Future<Response> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    return await DioClient.dio.post(
      url,
      data: body,
    );
  }

  Future<Response> put(
    String url,
    Map<String, dynamic> body,
  ) async {
    return await DioClient.dio.put(
      url,
      data: body,
    );
  }

  Future<Response> patch(
    String url,
    Map<String, dynamic> body,
  ) async {
    return await DioClient.dio.patch(
      url,
      data: body,
    );
  }

  Future<Response> delete(String url) async {
    return await DioClient.dio.delete(url);
  }
}