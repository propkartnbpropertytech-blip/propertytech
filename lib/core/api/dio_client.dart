import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'dio_credentials_stub.dart'
    if (dart.library.html) 'dio_credentials_web.dart' as credentials;

import 'api_constants.dart';
import 'interceptors.dart';
import 'fallback_interceptor.dart';
import 'logging_interceptor.dart';

/// Interceptor to automatically parse JSON strings into Map/List on platforms (like Web)
/// where the native HTTP client or Dio transformer doesn't decode it automatically.
class JsonDecoderInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data is String) {
      final str = response.data.toString().trim();
      if (str.startsWith('{') || str.startsWith('[')) {
        try {
          response.data = jsonDecode(str);
        } catch (_) {}
      }
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response != null && err.response!.data is String) {
      final str = err.response!.data.toString().trim();
      if (str.startsWith('{') || str.startsWith('[')) {
        try {
          err.response!.data = jsonDecode(str);
        } catch (_) {}
      }
    }
    super.onError(err, handler);
  }
}

class DioClient {
  static final Dio dio = _initDio();

  static Dio _initDio() {
    final dioInstance = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          if (kIsWeb) 'X-Auth-Transport': 'cookie',
        },
      ),
    );

    credentials.configureDioCredentials(dioInstance);
    dioInstance.interceptors.add(LoggingInterceptor());
    dioInstance.interceptors.add(JsonDecoderInterceptor());
    dioInstance.interceptors.add(_ConcurrencyLimiterInterceptor(maxConcurrent: 8));
    dioInstance.interceptors.add(JwtInterceptor());
    dioInstance.interceptors.add(FallbackInterceptor());
    return dioInstance;
  }
}

/// Caps in-flight API calls so one busy client does not flood the server.
class _ConcurrencyLimiterInterceptor extends Interceptor {
  _ConcurrencyLimiterInterceptor({this.maxConcurrent = 8});

  final int maxConcurrent;
  int _active = 0;
  final List<Completer<void>> _waiters = [];

  Future<void> _acquire() {
    final waiter = Completer<void>();
    if (_active < maxConcurrent) {
      _active++;
      waiter.complete();
    } else {
      _waiters.add(waiter);
    }
    return waiter.future;
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
      return;
    }
    if (_active > 0) _active--;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _acquire().then((_) => handler.next(options)).catchError((Object e, StackTrace st) {
      handler.reject(
        DioException(requestOptions: options, error: e, stackTrace: st),
      );
    });
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _release();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _release();
    handler.next(err);
  }
}
