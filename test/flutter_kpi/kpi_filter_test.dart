import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/dashboard/models/kpi_models.dart';

void main() {
  group('Step 8.5: KPI Filter Parameters Tests', () {
    test('1. Default filter values conform to canonical rules', () {
      const filters = KpiFilterParams();

      expect(filters.businessType, equals('Rent'));
      expect(filters.dateFilter, equals('Weekly'));
      expect(filters.leadType, equals('Both'));
      expect(filters.startDate, isNull);
      expect(filters.endDate, isNull);
      expect(filters.outcome, isNull);
    });

    test('2. copyWith creates new immutable instance with updated values', () {
      const initial = KpiFilterParams();
      final updated = initial.copyWith(
        businessType: 'Both',
        dateFilter: 'Custom Range',
        startDate: '2026-10-01',
        endDate: '2026-10-21',
      );

      // Initial instance unchanged
      expect(initial.businessType, equals('Rent'));
      expect(initial.dateFilter, equals('Weekly'));
      expect(initial.startDate, isNull);

      // New instance reflects updates
      expect(updated.businessType, equals('Both'));
      expect(updated.dateFilter, equals('Custom Range'));
      expect(updated.startDate, equals('2026-10-01'));
      expect(updated.endDate, equals('2026-10-21'));
      expect(updated.leadType, equals('Both'));
    });

    test('3. toQueryParams generates exact half-open interval dictionary', () {
      const filters = KpiFilterParams(
        businessType: 'Re-sale',
        dateFilter: 'Custom Range',
        startDate: '2026-10-01',
        endDate: '2026-10-21',
        leadType: 'Requirement',
        outcome: 'DEAL_WON',
      );

      final params = filters.toQueryParams();

      expect(params['businessType'], equals('Re-sale'));
      expect(params['dateFilter'], equals('Custom Range'));
      expect(params['startDate'], equals('2026-10-01'));
      expect(params['endDate'], equals('2026-10-21'));
      expect(params['leadType'], equals('Requirement'));
      expect(params['outcome'], equals('DEAL_WON'));
    });

    test('4. toQueryParams omits null and empty optional fields', () {
      const filters = KpiFilterParams(
        businessType: 'Rent',
        dateFilter: 'Today',
        startDate: '',
        endDate: null,
      );

      final params = filters.toQueryParams();

      expect(params.containsKey('startDate'), isFalse);
      expect(params.containsKey('endDate'), isFalse);
      expect(params.containsKey('outcome'), isFalse);
      expect(params['businessType'], equals('Rent'));
      expect(params['dateFilter'], equals('Today'));
    });
  });
}
