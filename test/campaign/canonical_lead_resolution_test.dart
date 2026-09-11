import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/integration/models/integration_lead_model.dart';
import 'package:propkart/features/integration/services/integration_service.dart';
import 'package:propkart/features/integration/services/lead_understanding_engine.dart';
import 'package:propkart/features/campaign/bloc/campaign_leads_bloc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Canonical Lead Resolution & Formatting Tests', () {
    test('Resolves Property Listing lead from Meta Ads correctly (Ramesh Padia)', () {
      final ramesh = IntegrationLeadModel(
        id: '4c657fb6-1676-406e-9996-66cc22ad765c',
        source: 'Meta Ads',
        leadType: 'Property Listing',
        receivedAt: DateTime.parse('2026-09-11 03:39:53Z'),
        rawJson: {
          'city': 'Ahmedabad',
          'email': 'nrpadia@gmail.com',
          'Ad Name': 'NB propertytech property rental',
          'form_name': 'Property Rent Enquiry – Gota & Vaishnodevi-copy',
          'full_name': 'Ramesh Padia',
          'phone_number': '+919898467025',
          'Campaign Name': 'NB PropertyTech Rental Ad 0408',
          'where_is_your_property_located?': 'other_area',
          'what_is_your_expected_monthly_rent?': '₹20,000–₹30,000',
          'what_type_of_property_are_you_looking_to_rent_out?': '2_bhk',
        },
      );

      // Verify canonical lookups for Property Listing columns
      expect(ramesh.getStringValue('Client / Owner Name'), equals('Ramesh Padia'));
      expect(ramesh.getStringValue('Owner Name'), equals('Ramesh Padia'));
      expect(ramesh.getStringValue('Full Name'), equals('Ramesh Padia'));
      expect(ramesh.getStringValue('Phone Number'), equals('+919898467025'));
      expect(ramesh.getStringValue('Property Type'), equals('2 BHK'));
      expect(ramesh.getStringValue('Expected Rent'), equals('₹20,000–₹30,000'));
      expect(ramesh.getStringValue('Property Location'), equals('Other Area'));
      expect(ramesh.getStringValue('City'), equals('Ahmedabad'));
      expect(ramesh.getStringValue('Email ID'), equals('nrpadia@gmail.com'));
      expect(ramesh.getStringValue('Campaign Name'), equals('NB PropertyTech Rental Ad 0408'));
      expect(ramesh.getStringValue('Form Name'), equals('Property Rent Enquiry – Gota & Vaishnodevi-copy'));
    });

    test('Resolves Remi Remrem lead from Meta Ads correctly', () {
      final remi = IntegrationLeadModel(
        id: '8b841568-c903-4546-b629-3b9c2f23dca1',
        source: 'Meta Ads',
        leadType: 'Property Listing',
        receivedAt: DateTime.parse('2026-09-11 02:03:46Z'),
        rawJson: {
          'city': 'Ahmedabad',
          'email': 'remremilalremruati890@gmail.com',
          'Ad Name': 'NB propertytech property rental',
          'form_name': 'Property Rent Enquiry – Gota & Vaishnodevi-copy',
          'full_name': 'Remi Remrem',
          'phone_number': '+919383177325',
          'Campaign Name': 'NB PropertyTech Rental Ad 0408',
          'where_is_your_property_located?': 'other_area',
          'what_is_your_expected_monthly_rent?': '₹15,000–₹20,000',
          'what_type_of_property_are_you_looking_to_rent_out?': '2_bhk',
        },
      );

      expect(remi.getStringValue('Client / Owner Name'), equals('Remi Remrem'));
      expect(remi.getStringValue('Phone Number'), equals('+919383177325'));
      expect(remi.getStringValue('Property Type'), equals('2 BHK'));
      expect(remi.getStringValue('Expected Rent'), equals('₹15,000–₹20,000'));
      expect(remi.getStringValue('Property Location'), equals('Other Area'));
    });

    test('Resolves Sheet/Webhook lead with non-standard keys correctly', () {
      final zeel = IntegrationLeadModel(
        id: 'test-sheet-zeel',
        source: 'Google Sheets',
        leadType: 'Property Listing',
        receivedAt: DateTime.now(),
        rawJson: {
          'Name': 'Zeel',
          'Number': 919584366883,
          'City': 'Gwalior',
          'where_is_your_property_located?': 'gota',
          'what_is_the_complete_address_of_your_property?': '₹15,000–₹20,000',
          '': '2_bhk',
        },
      );

      expect(zeel.getStringValue('Client / Owner Name'), equals('Zeel'));
      expect(zeel.getStringValue('Phone Number'), equals('919584366883'));
      expect(zeel.getStringValue('Property Type'), equals('2 BHK'));
      expect(zeel.getStringValue('Expected Rent'), equals('₹15,000–₹20,000'));
      expect(zeel.getStringValue('City'), equals('Gwalior'));
    });

    test('Resolves Requirement lead from Meta Ads correctly (Arif)', () {
      final arif = IntegrationLeadModel(
        id: 'f679c49a-d5da-4cd4-9abc-9980697a1f29',
        source: 'Meta Ads',
        leadType: 'Requirement',
        receivedAt: DateTime.parse('2026-09-10 21:13:15Z'),
        rawJson: {
          'city': 'Ahmedabad',
          'email': 'rajasthanironfabrication@gmail.com',
          'Ad Name': 'NB Propertytech Rental Leads',
          'form_name': 'NB PropertyTech Rental Leads-copy',
          'full_name': 'Arif',
          'phone_number': '+919521534922',
          'Campaign Name': 'NB PropertyTech Survey Ad 3108',
          'which_area_are_you_looking_for?': 'bopal_/_south-west_ahmedabad',
          'what_is_your_monthly_rental_budget?': '₹20,000_–_₹35,000',
          'who_will_be_staying_in_the_property?': 'working_professionals',
          'what_type_of_home_are_you_looking_for?': '2_bhk',
        },
      );

      expect(arif.getStringValue('Client Name'), equals('Arif'));
      expect(arif.getStringValue('Phone Number'), equals('+919521534922'));
      expect(arif.getStringValue('Configuration'), equals('2 BHK'));
      expect(arif.getStringValue('Monthly Budget'), equals('₹20,000 – ₹35,000'));
      expect(arif.getStringValue('Preferred Area'), equals('Bopal / South-West Ahmedabad'));
      expect(arif.getStringValue('Who Will Be Staying'), equals('Working Professionals'));
      expect(arif.getStringValue('City'), equals('Ahmedabad'));
    });

    test('IntegrationService detects standard headers for Property Listing', () {
      final service = IntegrationService();
      final headers = service.getDetectedHeaders(section: 'Property Listing');
      expect(headers, contains('Client / Owner Name'));
      expect(headers, contains('Phone Number'));
      expect(headers, contains('Property Type'));
      expect(headers, contains('Expected Rent'));
      expect(headers, contains('Property Location'));
      expect(headers, contains('City'));
    });

    test('IntegrationService maps Ad Name and form_name to campaign, NOT name', () {
      final service = IntegrationService();
      expect(service.columnMappings['Ad Name'], equals('campaign'));
      expect(service.columnMappings['form_name'], equals('campaign'));
      expect(service.columnMappings['Campaign Name'], equals('campaign'));
      expect(service.columnMappings['Number'], equals('mobile'));
      expect(service.columnMappings['Expected Rent'], equals('budget'));
      expect(service.columnMappings['Property Type'], equals('configuration'));
      expect(service.columnMappings['Received On'], equals('received_at'));
    });

    test('IntegrationService standard headers include Received On', () {
      final service = IntegrationService();
      final propHeaders = service.getDetectedHeaders(section: 'Property Listing');
      expect(propHeaders, contains('Received On'));
      expect(propHeaders.indexOf('Received On'), equals(2)); // Right after Client / Owner Name and Phone Number

      final reqHeaders = service.getDetectedHeaders(section: 'Requirement');
      expect(reqHeaders, contains('Received On'));
      expect(reqHeaders.indexOf('Received On'), equals(2)); // Right after Client Name and Phone Number
    });

    test('LeadUnderstandingEngine understands Owner Listing lead correctly', () {
      final ramesh = IntegrationLeadModel(
        id: 'ramesh-owner-001',
        source: 'Meta Ads',
        leadType: 'Property Listing',
        receivedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        rawJson: {
          'full_name': 'Ramesh Padia',
          'phone_number': '+919898467025',
          'where_is_your_property_located?': 'other_area',
          'what_is_your_expected_monthly_rent?': '₹20,000–₹30,000',
          'what_type_of_property_are_you_looking_to_rent_out?': '2_bhk',
          'city': 'Ahmedabad',
        },
      );

      final understanding = LeadUnderstandingEngine.analyze(ramesh);
      expect(understanding.persona, equals(LeadPersona.ownerListing));
      expect(understanding.completeness, equals(LeadCompleteness.complete));
      expect(understanding.freshness, contains('Today'));
      expect(understanding.oneLineSummary, contains('wants to rent out 2 BHK'));
      expect(understanding.keyDetails, contains('Ramesh Padia'));
      expect(understanding.recommendedAction, contains('Properties Inventory'));
      expect(understanding.personalizedWhatsAppMessage, contains('Ramesh Padia ji'));
      expect(understanding.personalizedWhatsAppMessage, contains('list your 2 BHK'));
      expect(understanding.whatsAppUrl, isNotNull);
      expect(understanding.whatsAppUrl, contains('919898467025'));
      expect(understanding.dialerUrl, equals('tel:+919898467025'));
    });

    test('LeadUnderstandingEngine understands Tenant Requirement lead correctly', () {
      final arif = IntegrationLeadModel(
        id: 'arif-tenant-001',
        source: 'Meta Ads',
        leadType: 'Requirement',
        receivedAt: DateTime.now().subtract(const Duration(hours: 1)),
        rawJson: {
          'full_name': 'Arif Vahora',
          'phone_number': '+919601662993',
          'which_area_are_you_looking_for?': 'gota',
          'what_is_your_monthly_rental_budget?': '₹15,000–₹20,000',
          'what_type_of_home_are_you_looking_for?': '2_bhk',
          'who_will_be_staying_in_the_property?': 'family',
          'city': 'Ahmedabad',
        },
      );

      final understanding = LeadUnderstandingEngine.analyze(arif);
      expect(understanding.persona, equals(LeadPersona.tenantRequirement));
      expect(understanding.completeness, equals(LeadCompleteness.complete));
      expect(understanding.freshness, contains('Today'));
      expect(understanding.oneLineSummary, contains('seeking 2 BHK in gota'));
      expect(understanding.recommendedAction, contains('Leads Page'));
      expect(understanding.personalizedWhatsAppMessage, contains('Arif Vahora ji'));
      expect(understanding.personalizedWhatsAppMessage, contains('requirement for a 2 BHK'));
      expect(understanding.whatsAppUrl, isNotNull);
      expect(understanding.whatsAppUrl, contains('919601662993'));
      expect(understanding.dialerUrl, equals('tel:+919601662993'));
    });

    test('CampaignLeadsState defaults to allTime so all leads are shown by default', () {
      const state = CampaignLeadsState();
      expect(state.dateFilter, equals(CampaignDateFilter.allTime));
    });

    test('Strict Section Header Separation: Property Listing vs Requirement', () {
      final service = IntegrationService();

      final propHeaders = service.getDetectedHeaders(section: 'Property Listing');
      final reqHeaders = service.getDetectedHeaders(section: 'Requirement');

      // Property Listing must contain Owner-specific headers
      expect(propHeaders, contains('Client / Owner Name'));
      expect(propHeaders, contains('Property Type'));
      expect(propHeaders, contains('Expected Rent'));
      expect(propHeaders, contains('Property Location'));

      // Property Listing must NEVER contain Requirement-specific headers
      expect(propHeaders, isNot(contains('Configuration')));
      expect(propHeaders, isNot(contains('Monthly Budget')));
      expect(propHeaders, isNot(contains('Preferred Area')));
      expect(propHeaders, isNot(contains('Who Will Be Staying')));

      // Requirement must contain Tenant-specific headers
      expect(reqHeaders, contains('Client Name'));
      expect(reqHeaders, contains('Configuration'));
      expect(reqHeaders, contains('Monthly Budget'));
      expect(reqHeaders, contains('Preferred Area'));
      expect(reqHeaders, contains('Who Will Be Staying'));

      // Requirement must NEVER contain Property Listing-specific headers
      expect(reqHeaders, isNot(contains('Client / Owner Name')));
      expect(reqHeaders, isNot(contains('Property Type')));
      expect(reqHeaders, isNot(contains('Expected Rent')));
      expect(reqHeaders, isNot(contains('Property Location')));
    });

    test('Raw Question keys do not pollute detected headers in either section', () {
      final service = IntegrationService();
      final messyLead = IntegrationLeadModel(
        id: 'raw-messy-001',
        source: 'Meta Ads',
        leadType: 'Property Listing',
        receivedAt: DateTime.now(),
        rawJson: {
          'full_name': 'Test Owner',
          'phone_number': '9876543210',
          'which_location_are_you_looking_for?': 'bopal',
          'what_type_of_property_are_you_looking_to_rent_out?': '3_bhk',
          'what_is_your_expected_monthly_rent?': '₹30,000',
          'where_is_your_property_located?': 'south bopal',
          'random_unmapped_meta_question_1?': 'answer 1',
          'random_unmapped_meta_question_2?': 'answer 2',
        },
      );

      final propHeaders = service.getDetectedHeaders(
        leadsSubset: [messyLead],
        section: 'Property Listing',
      );
      final reqHeaders = service.getDetectedHeaders(
        leadsSubset: [messyLead],
        section: 'Requirement',
      );

      // Neither section should have raw question keys
      expect(propHeaders, isNot(contains('which_location_are_you_looking_for?')));
      expect(propHeaders, isNot(contains('what_type_of_property_are_you_looking_to_rent_out?')));
      expect(propHeaders, isNot(contains('random_unmapped_meta_question_1?')));
      expect(propHeaders, isNot(contains('random_unmapped_meta_question_2?')));

      expect(reqHeaders, isNot(contains('which_location_are_you_looking_for?')));
      expect(reqHeaders, isNot(contains('what_type_of_property_are_you_looking_to_rent_out?')));
      expect(reqHeaders, isNot(contains('random_unmapped_meta_question_1?')));
      expect(reqHeaders, isNot(contains('random_unmapped_meta_question_2?')));
    });

    test('Value Isolation: Owner leads do not leak values into Requirement keys and vice versa', () {
      final ownerLead = IntegrationLeadModel(
        id: 'owner-val-001',
        source: 'Meta Ads',
        leadType: 'Property Listing',
        receivedAt: DateTime.now(),
        rawJson: {
          'full_name': 'Owner Person',
          'phone_number': '9998887771',
          'what_type_of_property_are_you_looking_to_rent_out?': '2_bhk',
          'what_is_your_expected_monthly_rent?': '₹25,000',
          'where_is_your_property_located?': 'Vastrapur',
        },
      );

      // Owner keys return values
      expect(ownerLead.getStringValue('Property Type'), equals('2 BHK'));
      expect(ownerLead.getStringValue('Expected Rent'), equals('₹25,000'));
      expect(ownerLead.getStringValue('Property Location'), equals('Vastrapur'));

      // Tenant keys return empty strings
      expect(ownerLead.getStringValue('Configuration'), equals(''));
      expect(ownerLead.getStringValue('Monthly Budget'), equals(''));
      expect(ownerLead.getStringValue('Preferred Area'), equals(''));
      expect(ownerLead.getStringValue('Who Will Be Staying'), equals(''));

      final tenantLead = IntegrationLeadModel(
        id: 'tenant-val-001',
        source: 'Meta Ads',
        leadType: 'Requirement',
        receivedAt: DateTime.now(),
        rawJson: {
          'full_name': 'Tenant Person',
          'phone_number': '9998887772',
          'what_type_of_home_are_you_looking_for?': '3_bhk',
          'what_is_your_monthly_rental_budget?': '₹35,000',
          'which_area_are_you_looking_for?': 'Bodakdev',
          'who_will_be_staying_in_the_property?': 'family',
        },
      );

      // Tenant keys return values
      expect(tenantLead.getStringValue('Configuration'), equals('3 BHK'));
      expect(tenantLead.getStringValue('Monthly Budget'), equals('₹35,000'));
      expect(tenantLead.getStringValue('Preferred Area'), equals('Bodakdev'));
      expect(tenantLead.getStringValue('Who Will Be Staying'), equals('Family'));

      // Owner keys return empty strings
      expect(tenantLead.getStringValue('Property Type'), equals(''));
      expect(tenantLead.getStringValue('Expected Rent'), equals(''));
      expect(tenantLead.getStringValue('Property Location'), equals(''));
    });
  });
}
