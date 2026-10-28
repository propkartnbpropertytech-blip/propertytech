import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/integration/services/integration_service.dart';

void main() {
  group('Campaign Source Filter Tests', () {
    test('Housing filter matches Housing.com and Housing leads, strictly excludes Meta Ads', () {
      const housingFilter = 'Housing.com';

      // Matches housing
      expect(IntegrationService.matchesCampaignSource('Housing.com', housingFilter), isTrue);
      expect(IntegrationService.matchesCampaignSource('housing', housingFilter), isTrue);
      expect(IntegrationService.matchesCampaignSource('HOUSING', housingFilter), isTrue);
      expect(IntegrationService.matchesCampaignSource('Housing Portal', housingFilter), isTrue);

      // Excludes non-housing
      expect(IntegrationService.matchesCampaignSource('Meta Ads', housingFilter), isFalse);
      expect(IntegrationService.matchesCampaignSource('Facebook', housingFilter), isFalse);
      expect(IntegrationService.matchesCampaignSource('Instagram', housingFilter), isFalse);
      expect(IntegrationService.matchesCampaignSource('Google Sheets', housingFilter), isFalse);
      expect(IntegrationService.matchesCampaignSource('Manual Entry', housingFilter), isFalse);
    });

    test('Meta Ads filter matches Meta leads, strictly excludes Housing leads', () {
      const metaFilter = 'Meta Ads';

      expect(IntegrationService.matchesCampaignSource('Meta Ads', metaFilter), isTrue);
      expect(IntegrationService.matchesCampaignSource('FACEBOOK', metaFilter), isTrue);
      expect(IntegrationService.matchesCampaignSource('Instagram', metaFilter), isTrue);

      expect(IntegrationService.matchesCampaignSource('Housing.com', metaFilter), isFalse);
      expect(IntegrationService.matchesCampaignSource('Housing', metaFilter), isFalse);
    });
  });
}
