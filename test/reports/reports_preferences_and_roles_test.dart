import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/security/role_guard.dart';
import 'package:propkart/features/reports/models/report_date_range.dart';
import 'package:propkart/features/reports/models/report_filter_state.dart';

void main() {
  group('Reports Role-Based Access Control Tests', () {
    test('RoleGuard.canViewReports allows Admin and Super Admin only', () {
      expect(RoleGuard.canViewReports('admin'), isTrue);
      expect(RoleGuard.canViewReports('Admin'), isTrue);
      expect(RoleGuard.canViewReports('super admin'), isTrue);
      expect(RoleGuard.canViewReports('Super Admin'), isTrue);

      // Blocked roles
      expect(RoleGuard.canViewReports('telecaller'), isFalse);
      expect(RoleGuard.canViewReports('Telecaller'), isFalse);
      expect(RoleGuard.canViewReports('sales'), isFalse);
      expect(RoleGuard.canViewReports('Sales'), isFalse);
      expect(RoleGuard.canViewReports('employee'), isFalse);
      expect(RoleGuard.canViewReports(''), isFalse);
      expect(RoleGuard.canViewReports(null), isFalse);
    });

    test('RoleGuard.sanitizeRedirectPath blocks /reports for unauthorized roles', () {
      const reportsPath = '/reports/leads/overall-business-insight';

      // Allowed for admin and super admin
      expect(RoleGuard.sanitizeRedirectPath(reportsPath, role: 'Admin'), equals(reportsPath));
      expect(RoleGuard.sanitizeRedirectPath(reportsPath, role: 'Super Admin'), equals(reportsPath));

      // Blocked for telecaller and sales -> redirected to /dashboard
      expect(RoleGuard.sanitizeRedirectPath(reportsPath, role: 'Telecaller'), equals('/dashboard'));
      expect(RoleGuard.sanitizeRedirectPath(reportsPath, role: 'Sales'), equals('/dashboard'));
      expect(RoleGuard.sanitizeRedirectPath(reportsPath, role: 'User'), equals('/dashboard'));
    });
  });

  group('Reports Preferences Serialization Tests', () {
    test('ReportDateRange serializes and deserializes correctly', () {
      final todayRange = ReportDateRange.today();
      final todayJson = todayRange.toJson();
      final restoredToday = ReportDateRange.fromJson(todayJson);

      expect(restoredToday.periodType, equals(ReportPeriodType.today));
      expect(restoredToday.subOption, equals(ReportSubPeriodOption.current));

      final customStart = DateTime(2026, 1, 15);
      final customEnd = DateTime(2026, 2, 20);
      final customRange = ReportDateRange.custom(start: customStart, end: customEnd);
      final customJson = customRange.toJson();
      final restoredCustom = ReportDateRange.fromJson(customJson);

      expect(restoredCustom.periodType, equals(ReportPeriodType.customRange));
      expect(restoredCustom.subOption, equals(ReportSubPeriodOption.custom));
      expect(restoredCustom.startDate.year, equals(2026));
      expect(restoredCustom.startDate.month, equals(1));
      expect(restoredCustom.startDate.day, equals(15));
      expect(restoredCustom.endDate.year, equals(2026));
      expect(restoredCustom.endDate.month, equals(2));
      expect(restoredCustom.endDate.day, equals(20));
    });

    test('ReportFilterState serializes and deserializes correctly', () {
      const filter = ReportFilterState(
        leadSource: 'Google Ads',
        leadStatus: 'Call Attempted (Picked Up)',
        telecallerId: 'tc-123',
        telecallerName: 'Jane Telecaller',
        salesUserId: 'sales-456',
        salesUserName: 'John Sales',
        locationName: 'Whitefield',
      );

      final json = filter.toJson();
      final restored = ReportFilterState.fromJson(json);

      expect(restored.leadSource, equals('Google Ads'));
      expect(restored.leadStatus, equals('Call Attempted (Picked Up)'));
      expect(restored.telecallerId, equals('tc-123'));
      expect(restored.telecallerName, equals('Jane Telecaller'));
      expect(restored.salesUserId, equals('sales-456'));
      expect(restored.salesUserName, equals('John Sales'));
      expect(restored.locationName, equals('Whitefield'));
      expect(restored.hasActiveFilters, isTrue);
    });
  });
}
