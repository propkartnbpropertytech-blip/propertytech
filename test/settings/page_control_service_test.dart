import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propkart/core/api/dio_client.dart';
import 'package:propkart/features/settings/models/page_control_model.dart';
import 'package:propkart/features/settings/services/page_control_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PageControlModel Value Equality & Effective State', () {
    test('identical attributes produce equality and matching hashCodes', () {
      const a = PageControlModel(
        pageKey: 'properties',
        title: 'Properties',
        route: '/properties',
        roles: ['Admin', 'Sales', 'Telecaller'],
        isUnderDevelopment: false,
        underDevelopmentRoles: [],
      );
      const b = PageControlModel(
        pageKey: 'properties',
        title: 'Properties',
        route: '/properties',
        roles: ['Admin', 'Sales', 'Telecaller'],
        isUnderDevelopment: false,
        underDevelopmentRoles: [],
      );

      expect(a, equals(b));
      expect(a.isEffectivelyEqualTo(b), isTrue);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differing isUnderDevelopment or underDevelopmentRoles are not equal', () {
      const live = PageControlModel(
        pageKey: 'properties',
        title: 'Properties',
        route: '/properties',
        roles: ['Admin', 'Sales', 'Telecaller'],
        isUnderDevelopment: false,
        underDevelopmentRoles: [],
      );
      const dev = PageControlModel(
        pageKey: 'properties',
        title: 'Properties',
        route: '/properties',
        roles: ['Admin', 'Sales', 'Telecaller'],
        isUnderDevelopment: true,
        underDevelopmentRoles: ['Sales'],
      );

      expect(live, isNot(equals(dev)));
      expect(live.isEffectivelyEqualTo(dev), isFalse);
    });

    test('isUnderDevForRole respects role specificity and Super Admin bypass', () {
      const model = PageControlModel(
        pageKey: 'properties',
        title: 'Properties',
        route: '/properties',
        roles: ['Admin', 'Sales', 'Telecaller'],
        isUnderDevelopment: true,
        underDevelopmentRoles: ['Sales'],
      );

      // Super Admin is never blocked
      expect(model.isUnderDevForRole('Super Admin'), isFalse);
      // Sales is blocked
      expect(model.isUnderDevForRole('Sales'), isTrue);
      expect(model.isUnderDevForRole('Sales Person'), isTrue);
      // Telecaller is not blocked
      expect(model.isUnderDevForRole('Telecaller'), isFalse);
      // Admin is not blocked
      expect(model.isUnderDevForRole('Admin'), isFalse);
    });
  });

  group('PageControlService Redundant Notification & Deduplication Control', () {
    late PageControlService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = PageControlService.instance;
      service.reset();
    });

    test('reset() restores defaults and notifies once', () {
      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      service.reset();

      expect(notifyCount, equals(1));
      expect(service.controls.length, greaterThan(15));
      expect(service.isLoading, isFalse);
    });

    test('isRouteUnderDevelopment accurately maps routes to page keys', () {
      expect(service.isRouteUnderDevelopment('/dashboard', 'Sales'), isFalse);
      expect(service.isRouteUnderDevelopment('/properties', 'Sales'), isFalse);
      expect(service.isRouteUnderDevelopment('/requirements', 'Sales'), isFalse);
      expect(service.isRouteUnderDevelopment('/non-existent-route', 'Sales'), isFalse);
    });

    test('Super Admin always bypasses route under development', () {
      expect(service.isRouteUnderDevelopment('/dashboard', 'Super Admin'), isFalse);
      expect(service.isRouteUnderDevelopment('/properties', 'Super Admin'), isFalse);
    });

    test('AppLifecycleState pause and resume toggles periodic sync without exceptions', () {
      // Simulate lifecycle transitions
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(service.controls.isNotEmpty, isTrue);
    });

    test('Silent fetch with identical controls emits 0 notifications', () async {
      final mock = _MockPageControlInterceptor();
      DioClient.dio.interceptors.insert(0, mock);

      try {
        // Return JSON with exact current controls
        mock.mockResponseData = {
          'success': true,
          'data': service.controls.map((c) => c.toJson()).toList(),
        };

        int notifyCount = 0;
        service.addListener(() => notifyCount++);

        await service.fetchControls(silent: true);

        // ZERO notifications emitted because state did not change
        expect(notifyCount, equals(0));
        expect(mock.requestCount, equals(1));
      } finally {
        DioClient.dio.interceptors.remove(mock);
      }
    });

    test('Silent fetch with changed controls emits exactly 1 notification', () async {
      final mock = _MockPageControlInterceptor();
      DioClient.dio.interceptors.insert(0, mock);

      try {
        final modifiedJson = service.controls.map((c) {
          final json = c.toJson();
          if (c.pageKey == 'properties') {
            json['is_under_development'] = true;
            json['under_development_roles'] = ['Sales'];
          }
          return json;
        }).toList();

        mock.mockResponseData = {
          'success': true,
          'data': modifiedJson,
        };

        int notifyCount = 0;
        service.addListener(() => notifyCount++);

        await service.fetchControls(silent: true);

        // Exactly ONE notification emitted
        expect(notifyCount, equals(1));
        expect(service.isRouteUnderDevelopment('/properties', 'Sales'), isTrue);
      } finally {
        DioClient.dio.interceptors.remove(mock);
      }
    });

    test('Concurrent fetchControls calls deduplicate to 1 network request', () async {
      final mock = _MockPageControlInterceptor();
      DioClient.dio.interceptors.insert(0, mock);

      try {
        mock.mockResponseData = {
          'success': true,
          'data': service.controls.map((c) => c.toJson()).toList(),
        };

        // Fire 3 simultaneous calls
        final f1 = service.fetchControls(silent: true);
        final f2 = service.fetchControls(silent: true);
        final f3 = service.fetchControls(silent: true);

        await Future.wait([f1, f2, f3]);

        // Only ONE HTTP request was sent
        expect(mock.requestCount, equals(1));
      } finally {
        DioClient.dio.interceptors.remove(mock);
      }
    });
  });
}

class _MockPageControlInterceptor extends Interceptor {
  Map<String, dynamic>? mockResponseData;
  int requestCount = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path.contains('/page-controls')) {
      requestCount++;
      if (mockResponseData != null) {
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: mockResponseData,
        ));
        return;
      }
    }
    super.onRequest(options, handler);
  }
}
