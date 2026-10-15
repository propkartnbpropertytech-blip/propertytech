import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/api/dio_client.dart';
import 'package:propkart/features/admin/widgets/telecaller_detail_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final mockData = {
    'status': 'success',
    'data': {
      'profile': {
        'name': 'Priya Sharma (Senior Telecaller)',
        'email': 'priya.sharma@propkart.in',
        'phone': '+91 9876543210',
        'availability': 'BREAK',
        'heartbeatFresh': false,
        'isManuallyOff': false,
        'remainingOffSeconds': 18000,
      },
      'workload': {
        'capacity': 300,
        'currentWorkload': 193,
        'availableSlots': 107,
        'staleCount': 12,
      },
      'outcomes': {
        'cnr': 45,
        'callbacks': 28,
        'salesHandoffs': 14,
      },
      'currentLeads': [
        {
          'id': 'lead-1',
          'name': 'Vikramaditya Singhania (3 BHK)',
          'phone': '+91 9988776655',
          'campaign': 'Meta Ads Super Luxury Campaign',
          'priority': 'HOT',
          'allocationStatus': 'PENDING_CALL',
          'ageMinutes': 45,
          'isStale': true,
          'callAttemptCount': 2,
        },
        {
          'id': 'lead-2',
          'name': 'Rahul Verma',
          'phone': '+91 9811223344',
          'campaign': 'Google Search',
          'priority': 'NORMAL',
          'allocationStatus': 'FOLLOWUP',
          'ageMinutes': 15,
          'isStale': false,
          'callAttemptCount': 1,
        },
      ],
      'history': [
        {
          'assignment_type': 'PEER_TRANSFER',
          'from_telecaller_name': 'Amit Kumar',
          'to_telecaller_name': 'Priya Sharma',
          'reason': 'Workload rebalance requested by manager',
          'assigned_at': '2026-10-07T10:30:00.000Z',
        },
        {
          'assignment_type': 'AUTO_RECOVERY',
          'reason': 'Stale timeout expired after 30 minutes',
          'assigned_at': '2026-10-07T09:15:00.000Z',
        },
      ],
    },
  };

  late Interceptor testInterceptor;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    testInterceptor = InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(Response(
          requestOptions: options,
          data: mockData,
          statusCode: 200,
        ));
      },
    );
    DioClient.dio.interceptors.insert(0, testInterceptor);
  });

  tearDown(() {
    DioClient.dio.interceptors.remove(testInterceptor);
  });

  Widget buildTestDialog({required double width, required double height}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
        ),
        child: Scaffold(
          body: Center(
            child: TelecallerDetailDialog(
              telecallerId: 'test-telecaller-123',
              telecallerName: 'Priya Sharma (Senior Telecaller)',
              allTelecallers: const [
                {
                  'id': 'test-telecaller-456',
                  'name': 'Other Telecaller',
                  'status': 'ACTIVE',
                  'currentWorkload': 50,
                  'maxCapacity': 100,
                }
              ],
            ),
          ),
        ),
      ),
    );
  }

  group('TelecallerDetailDialog Mobile Responsiveness', () {
    testWidgets('renders cleanly with full content at 360x780', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestDialog(width: 360, height: 780));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.byType(TelecallerDetailDialog), findsOneWidget);
      expect(find.textContaining('Priya Sharma'), findsWidgets);
      expect(find.textContaining('Workload: 193 / 300 Leads'), findsOneWidget);
      expect(find.textContaining('Calling queue'), findsOneWidget);
      expect(find.text('Vikramaditya Singhania (3 BHK)'), findsOneWidget);
      expect(find.text('STALE (>30m untouched)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with full content at 320x640 (narrow phone)', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestDialog(width: 320, height: 640));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.byType(TelecallerDetailDialog), findsOneWidget);
      expect(find.textContaining('Priya Sharma'), findsWidgets);
      expect(find.textContaining('Workload: 193 / 300 Leads'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with full content at 390x844 (standard iPhone)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestDialog(width: 390, height: 844));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.byType(TelecallerDetailDialog), findsOneWidget);
      expect(find.textContaining('Priya Sharma'), findsWidgets);
      expect(find.textContaining('Workload: 193 / 300 Leads'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with full content at 412x915 (Android flagship)', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestDialog(width: 412, height: 915));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.byType(TelecallerDetailDialog), findsOneWidget);
      expect(find.textContaining('Priya Sharma'), findsWidgets);
      expect(find.textContaining('Workload: 193 / 300 Leads'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with full content on desktop at 1024x768', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestDialog(width: 1024, height: 768));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.byType(TelecallerDetailDialog), findsOneWidget);
      expect(find.textContaining('Priya Sharma'), findsWidgets);
      expect(find.textContaining('Workload: 193 / 300 Leads'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
