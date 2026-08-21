import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Web: send/receive HttpOnly cookies cross-origin.
void configureDioCredentials(Dio dio) {
  final adapter = BrowserHttpClientAdapter();
  adapter.withCredentials = true;
  dio.httpClientAdapter = adapter;
}
