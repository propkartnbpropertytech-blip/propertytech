import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/requirements/services/requirements_service.dart';

void main() {
  group('Recycle Bin source', () {
    test('labels name the page and tab a lead returns to', () {
      expect(RecycleBinSource.label(RecycleBinSource.leads), 'Leads');
      expect(RecycleBinSource.label(RecycleBinSource.campaignRequirement), 'Campaign Leads › Requirement Leads');
      expect(RecycleBinSource.label(RecycleBinSource.campaignPropertyListing), 'Campaign Leads › Property Listing Leads');
      expect(RecycleBinSource.label(null), 'Leads');
    });

    test('delete path carries the source only when one is given', () {
      expect(requirementDeletePath('abc'), '/requirements/abc');
      expect(requirementDeletePath('abc', deletedFrom: ''), '/requirements/abc');
      expect(
        requirementDeletePath('abc', deletedFrom: RecycleBinSource.campaignPropertyListing),
        '/requirements/abc?deletedFrom=campaign_property_listing',
      );
    });
  });
}
