import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propkart/features/integration/services/integration_service.dart';
import 'package:propkart/core/storage/local_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    CampaignLeadLocalRepository.inMemory.clear();
    final service = IntegrationService();
    await service.clearAllLeads();
  });

  group('Bulk Status Action Tests', () {
    test('bulkReclassifyLeadsOptimistic moves multiple leads immediately', () async {
      final service = IntegrationService();
      await service.ensureLoaded();

      await service.ingestRows([
        {
          'Unique_ID': 'bulk-1',
          'lead_type': 'Property Listing',
          'full_name': 'Owner 1',
          'campaign_status': 'New',
        },
        {
          'Unique_ID': 'bulk-2',
          'lead_type': 'Property Listing',
          'full_name': 'Owner 2',
          'campaign_status': 'Allocated',
        },
      ], source: 'Meta Ads');

      expect(service.leads.length, equals(2));
      final ids = service.leads.map((l) => l.id).toList();

      // Reclassify both to Requirement
      service.bulkReclassifyLeadsOptimistic(ids, 'Requirement');

      for (final id in ids) {
        final lead = service.leads.firstWhere((l) => l.id == id);
        expect(lead.leadType, equals('Requirement'));
      }
    });

    test('bulkReclassifyLeadsOptimistic from Requirement to Property Listing', () async {
      final service = IntegrationService();
      await service.ensureLoaded();

      await service.ingestRows([
        {
          'Unique_ID': 'bulk-3',
          'lead_type': 'Requirement',
          'full_name': 'Buyer 1',
          'campaign_status': 'Archived',
        },
      ], source: 'Meta Ads');

      final id = service.leads.first.id;

      service.bulkReclassifyLeadsOptimistic([id], 'Property Listing');

      final updated = service.leads.firstWhere((l) => l.id == id);
      expect(updated.leadType, equals('Property Listing'));
      expect(updated.campaignStatus, equals('New'));
    });
  });
}
