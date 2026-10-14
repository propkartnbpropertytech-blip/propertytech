import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/reports/models/business_insight_summary.dart';

void main() {
  group('BusinessInsightLead Status Display Tests', () {
    test('Unchanged/New lead maps to Allocated stage when parsed', () {
      final leadJson = {
        'id': 'lead-1',
        'customer_name': 'Bharat Patel',
        'phone': '9724653005',
        'source': 'META',
        'lead_type': 'Property Listing',
        'stage': 'Allocated',
        'allocation_status': 'ASSIGNED_TO_TELECALLER',
        'call_disposition': 'NOT_ATTEMPTED',
        'rejection_reason': null,
      };

      final lead = BusinessInsightLead.fromJson(leadJson);
      expect(lead.stage, equals('Allocated'));
      expect(lead.rejectionReason, isNull);
    });

    test('Lead with null or empty stage falls back to Allocated', () {
      final leadJson = {
        'id': 'lead-2',
        'customer_name': 'Kamlesh Patel',
        'phone': '9824677466',
        'source': 'META',
        'lead_type': 'Property Listing',
        'stage': '',
        'rejection_reason': null,
      };

      final lead = BusinessInsightLead.fromJson(leadJson);
      expect(lead.stage, equals('Allocated'));
      expect(lead.rejectionReason, isNull);
    });

    test('Lead with valid changed status preserves exact stage and details', () {
      final cnrJson = {
        'id': 'lead-3',
        'stage': 'CNR',
        'call_disposition': 'CNR',
        'rejection_reason': null,
      };
      expect(BusinessInsightLead.fromJson(cnrJson).stage, equals('CNR'));

      final notInterestedJson = {
        'id': 'lead-4',
        'stage': 'Not Interested',
        'call_disposition': 'NOT_INTERESTED',
        'not_interested_remark': 'Bachelors',
        'rejection_reason': null,
      };
      final notInterestedLead = BusinessInsightLead.fromJson(notInterestedJson);
      expect(notInterestedLead.stage, equals('Not Interested'));
      expect(notInterestedLead.rejectionReason, isNull);
      expect(notInterestedLead.notInterestedRemark, equals('Bachelors'));

      final listedJson = {
        'id': 'lead-5',
        'stage': 'Property Listed',
        'allocation_status': 'LISTED',
        'rejection_reason': null,
      };
      expect(BusinessInsightLead.fromJson(listedJson).stage, equals('Property Listed'));

      final visitJson = {
        'id': 'lead-6',
        'stage': 'Site Visit Done',
        'rejection_reason': null,
      };
      expect(BusinessInsightLead.fromJson(visitJson).stage, equals('Site Visit Done'));
    });

    test('Only genuinely rejected leads carry rejection reason and Rejected stage', () {
      final rejectedJson = {
        'id': 'lead-7',
        'stage': 'Rejected (Budget Issue)',
        'rejection_reason': 'Budget Issue',
      };
      final rejectedLead = BusinessInsightLead.fromJson(rejectedJson);
      expect(rejectedLead.stage, equals('Rejected (Budget Issue)'));
      expect(rejectedLead.rejectionReason, equals('Budget Issue'));
    });
  });
}
