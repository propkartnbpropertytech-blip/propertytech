import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/requirements/models/requirement_model.dart';

void main() {
  group('RequirementModel Meta Lead Ads Ingestion Tests', () {
    test('Deserializes Meta Ads attribution fields and unknown custom questions from JSON', () {
      final json = {
        'id': 'req-meta-101',
        'customer_name': 'Rohit Sharma',
        'mobile': '9876543210',
        'category_id': 'cat-1',
        'property_type_id': 'prop-1',
        'budget_from': 5000000,
        'budget_to': 8500000,
        'area_ids': ['area-1', 'area-2'],
        'status': 'Active',
        'source': 'Meta Ads',
        'meta_lead_id': 'meta_lead_99887766',
        'meta_page_id': 'page_12345678',
        'meta_form_id': 'form_87654321',
        'meta_campaign_id': 'camp_112233',
        'meta_campaign_name': 'Ahmedabad Luxury Apartments Campaign',
        'meta_adset_id': 'adset_445566',
        'meta_adset_name': 'High Net Worth Investors',
        'meta_ad_id': 'ad_778899',
        'meta_ad_name': 'Skyline Towers 3BHK Video Ad',
        'meta_custom_fields': {
          'preferred_floor': 'Above 10th Floor',
          'possession_timeline': 'Ready to Move',
          'loan_required': 'Yes - Pre-approved'
        },
        'lead_quality': 'Pending',
      };

      final req = RequirementModel.fromJson(json);

      expect(req.id, equals('req-meta-101'));
      expect(req.clientName, equals('Rohit Sharma'));
      expect(req.clientMobile, equals('9876543210'));
      expect(req.isMetaLead, isTrue);
      expect(req.metaLeadId, equals('meta_lead_99887766'));
      expect(req.metaPageId, equals('page_12345678'));
      expect(req.metaFormId, equals('form_87654321'));
      expect(req.metaCampaignId, equals('camp_112233'));
      expect(req.metaCampaignName, equals('Ahmedabad Luxury Apartments Campaign'));
      expect(req.metaCampaignDisplayName, equals('Ahmedabad Luxury Apartments Campaign'));
      expect(req.metaAdsetId, equals('adset_445566'));
      expect(req.metaAdsetName, equals('High Net Worth Investors'));
      expect(req.metaAdId, equals('ad_778899'));
      expect(req.metaAdName, equals('Skyline Towers 3BHK Video Ad'));
      expect(req.metaAdDisplayName, equals('Skyline Towers 3BHK Video Ad'));
      expect(req.leadQuality, equals('Pending'));

      // Check leadSourceDisplay
      expect(req.leadSourceDisplay, equals('Meta Ads (Ahmedabad Luxury Apartments Campaign)'));

      // Verify custom fields preservation
      expect(req.metaCustomFields, isNotNull);
      expect(req.metaCustomFields!['preferred_floor'], equals('Above 10th Floor'));
      expect(req.metaCustomFields!['possession_timeline'], equals('Ready to Move'));
      expect(req.metaCustomFields!['loan_required'], equals('Yes - Pre-approved'));
    });

    test('Serializes to backend JSON preserving all attribution IDs without data loss', () {
      final req = RequirementModel(
        id: 'req-meta-102',
        clientName: 'Sneha Patel',
        clientMobile: '9123456780',
        categoryId: 'cat-2',
        categoryName: 'Commercial',
        propertyTypeId: 'prop-2',
        propertyTypeName: 'Office Space',
        minBudget: 10000000,
        maxBudget: 15000000,
        areaIds: ['area-3'],
        areaNames: ['SG Highway'],
        status: 'Active',
        createdAt: DateTime.now(),
        leadSource: 'Meta Ads',
        metaLeadId: 'meta_lead_11223344',
        metaPageId: 'page_55667788',
        metaFormId: 'form_99001122',
        metaCampaignId: 'camp_334455',
        metaCampaignName: 'Corporate Spaces 2026',
        metaAdsetId: 'adset_667788',
        metaAdsetName: 'IT Companies Segment',
        metaAdId: 'ad_889900',
        metaAdName: 'Grade-A Offices Carousel',
        metaCustomFields: {'seating_capacity': '50-100 desks'},
        leadQuality: 'Qualified',
      );

      final backendJson = req.toBackendJson();

      expect(backendJson['meta_lead_id'], equals('meta_lead_11223344'));
      expect(backendJson['meta_page_id'], equals('page_55667788'));
      expect(backendJson['meta_form_id'], equals('form_99001122'));
      expect(backendJson['meta_campaign_id'], equals('camp_334455'));
      expect(backendJson['meta_campaign_name'], equals('Corporate Spaces 2026'));
      expect(backendJson['meta_adset_id'], equals('adset_667788'));
      expect(backendJson['meta_adset_name'], equals('IT Companies Segment'));
      expect(backendJson['meta_ad_id'], equals('ad_889900'));
      expect(backendJson['meta_ad_name'], equals('Grade-A Offices Carousel'));
      expect(backendJson['meta_custom_fields'], equals({'seating_capacity': '50-100 desks'}));
      expect(backendJson['lead_quality'], equals('Qualified'));
    });

    test('copyWith preserves or overrides Meta Ads attribution appropriately', () {
      final req1 = RequirementModel(
        id: 'req-1',
        clientName: 'Test',
        clientMobile: '1234567890',
        categoryId: 'cat',
        categoryName: 'Cat',
        propertyTypeId: 'prop',
        propertyTypeName: 'Prop',
        minBudget: 100,
        maxBudget: 200,
        areaIds: [],
        areaNames: [],
        status: 'Active',
        createdAt: DateTime.now(),
        metaLeadId: 'lead_initial',
        leadQuality: 'Pending',
      );

      final req2 = req1.copyWith(leadQuality: 'Converted');
      expect(req2.metaLeadId, equals('lead_initial'));
      expect(req2.leadQuality, equals('Converted'));
    });
  });
}
