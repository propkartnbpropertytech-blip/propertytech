import 'package:dio/dio.dart';
import 'package:propkart/core/api/api_constants.dart';

class NetworkInfo {
  static final NetworkInfo _instance = NetworkInfo._internal();
  factory NetworkInfo() => _instance;
  NetworkInfo._internal();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<bool> get isConnected async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
