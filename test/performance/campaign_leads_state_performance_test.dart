import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/campaign/bloc/campaign_leads_bloc.dart';
import 'package:propkart/features/integration/models/integration_lead_model.dart';

IntegrationLeadModel createMockLead({
  required String id,
  required String status,
  required String leadType,
  required DateTime receivedAt,
  DateTime? statusUpdatedAt,
}) {
  return IntegrationLeadModel(
    id: id,
    source: 'Meta Ads',
    receivedAt: receivedAt,
    rawJson: {'name': 'Client $id', 'phone': '9876543210'},
    qualityStatus: 'Qualified',
    importStatus: 'Ready',
    enquiryCount: 1,
    leadType: leadType,
    campaignStatus: status,
    statusUpdatedAt: statusUpdatedAt,
    isDuplicate: false,
  );
}

void main() {
  group('CampaignLeadsState Performance & O(1) Pre-computation', () {
    test('State precomputes dateFilteredLeads and filterCounts on copyWith', () {
      final now = DateTime.now();
      final todayLead = createMockLead(
        id: 'l1',
        status: 'Interested',
        leadType: 'Property Listing',
        receivedAt: now,
      );
      final yesterdayLead = createMockLead(
        id: 'l2',
        status: 'Follow up',
        leadType: 'Requirement',
        receivedAt: now.subtract(const Duration(days: 1)),
      );
      final oldLead = createMockLead(
        id: 'l3',
        status: 'Interested',
        leadType: 'Property Listing',
        receivedAt: now.subtract(const Duration(days: 60)),
      );

      final state = const CampaignLeadsState().copyWith(
        status: CampaignLeadsStatus.success,
        leads: [todayLead, yesterdayLead, oldLead],
        dateFilter: CampaignDateFilter.today,
      );

      // Verify dateFilteredLeads is precomputed
      expect(state.dateFilteredLeads.length, equals(1));
      expect(state.dateFilteredLeads.first.id, equals('l1'));

      // Verify filterCounts map is precomputed for O(1) lookups
      expect(state.filterCounts.isNotEmpty, isTrue);
      expect(state.countForFilter(CampaignDateFilter.today), equals(1));
      expect(state.countForFilter(CampaignDateFilter.yesterday), equals(1));
      expect(state.countForFilter(CampaignDateFilter.allTime), equals(3));

      // Section-specific counts
      expect(state.countForFilter(CampaignDateFilter.today, section: 'Property Listing'), equals(1));
      expect(state.countForFilter(CampaignDateFilter.today, section: 'Requirement'), equals(0));
    });

    test('Benchmark: 1,000 leads count lookups are instantaneous (O(1)) without rescanning', () {
      final now = DateTime.now();
      final leads = List.generate(1000, (i) {
        return createMockLead(
          id: 'lead_$i',
          status: i % 2 == 0 ? 'Interested' : 'New',
          leadType: i % 3 == 0 ? 'Requirement' : 'Property Listing',
          receivedAt: now.subtract(Duration(hours: i % 72)),
        );
      });

      final state = const CampaignLeadsState().copyWith(
        status: CampaignLeadsStatus.success,
        leads: leads,
        dateFilter: CampaignDateFilter.last7Days,
      );

      // Measure 10,000 count queries
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 10000; i++) {
        final c1 = state.countForFilter(CampaignDateFilter.today);
        final c2 = state.countForFilter(CampaignDateFilter.yesterday);
        final c3 = state.countForFilter(CampaignDateFilter.last7Days);
        expect(c1 + c2 <= c3, isTrue);
      }
      stopwatch.stop();

      // 10,000 lookups over 1,000 leads should execute in < 100ms due to O(1) precomputed map
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('SyncLocalLeadsEvent uses deterministic content hash without raw timestamps', () {
      final now = DateTime.now();
      final leadA1 = createMockLead(
        id: 'l1',
        status: 'Interested',
        leadType: 'Property Listing',
        receivedAt: now,
      );
      final leadA2 = createMockLead(
        id: 'l1',
        status: 'Interested',
        leadType: 'Property Listing',
        receivedAt: now,
      );
      final leadB = createMockLead(
        id: 'l1',
        status: 'Not interested', // changed status
        leadType: 'Property Listing',
        receivedAt: now,
        statusUpdatedAt: now,
      );

      final event1 = SyncLocalLeadsEvent([leadA1]);
      final event2 = SyncLocalLeadsEvent([leadA2]);
      final event3 = SyncLocalLeadsEvent([leadB]);

      // Identical content evaluates to equal (prevents unnecessary BLoC emissions)
      expect(event1, equals(event2));

      // Modified lead content evaluates to not equal (guarantees UI update)
      expect(event1, isNot(equals(event3)));
    });
  });
}
