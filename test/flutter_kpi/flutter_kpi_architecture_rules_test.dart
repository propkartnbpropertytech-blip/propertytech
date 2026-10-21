import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Step 8.5: Flutter KPI Architectural Rules Enforcement', () {
    test('1. Zero direct DioClient invocations inside Dashboard UI screens and widgets', () {
      final dashboardScreensDir = Directory('lib/features/dashboard/screens');
      final dashboardWidgetsDir = Directory('lib/features/dashboard/widgets');

      final violations = <String>[];

      for (final dir in [dashboardScreensDir, dashboardWidgetsDir]) {
        if (!dir.existsSync()) continue;
        for (final file in dir.listSync(recursive: true)) {
          if (file is File && file.path.endsWith('.dart')) {
            final content = file.readAsStringSync();
            if (content.contains('DioClient.dio.get') ||
                content.contains('DioClient.dio.post') ||
                content.contains('DioClient.dio.patch') ||
                content.contains('DioClient.dio.delete')) {
              violations.add(file.path);
            }
          }
        }
      }

      expect(violations, isEmpty,
          reason: 'UI screens and widgets must never invoke DioClient directly. Use Repository layer.');
    });

    test('2. DashboardBloc routes exclusively through DashboardRepository', () {
      final blocFile = File('lib/features/dashboard/bloc/dashboard_bloc.dart');
      expect(blocFile.existsSync(), isTrue);

      final content = blocFile.readAsStringSync();

      // Check that getDashboardKpis is called on _dashboardRepository and NOT on _dashboardService
      expect(content.contains('_dashboardRepository.getDashboardKpis'), isTrue);
      expect(content.contains('_dashboardService.getDashboardKpis'), isFalse,
          reason: 'DashboardBloc must route KPI fetches strictly through DashboardRepository.');
    });

    test('3. KpiDrilldownDialogs routes exclusively through DashboardRepository', () {
      final dialogsFile = File('lib/features/dashboard/widgets/kpi_drilldown_dialogs.dart');
      expect(dialogsFile.existsSync(), isTrue);

      final content = dialogsFile.readAsStringSync();

      expect(content.contains('static final DashboardRepository _dashboardRepository'), isTrue);
      expect(content.contains('static final DashboardService _dashboardService'), isFalse,
          reason: 'KpiDrilldownDialogs must route queries strictly through DashboardRepository.');
    });

    test('4. BusinessInsightService uses ApiClient instead of raw DioClient', () {
      final serviceFile = File('lib/features/reports/services/business_insight_service.dart');
      expect(serviceFile.existsSync(), isTrue);

      final content = serviceFile.readAsStringSync();

      expect(content.contains('DioClient.dio.get'), isFalse,
          reason: 'BusinessInsightService must use ApiClient instead of direct DioClient.');
    });
  });
}
