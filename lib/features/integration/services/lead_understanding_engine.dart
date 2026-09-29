import 'dart:core';
import '../models/integration_lead_model.dart';

enum LeadPersona {
  ownerListing,
  tenantRequirement,
}

enum LeadCompleteness {
  complete,
  partial,
  incomplete,
}

class LeadUnderstanding {
  final LeadPersona persona;
  final LeadCompleteness completeness;
  final String freshness;
  final String oneLineSummary;
  final String keyDetails;
  final String recommendedAction;
  final String personalizedWhatsAppMessage;
  final String? whatsAppUrl;
  final String? dialerUrl;

  const LeadUnderstanding({
    required this.persona,
    required this.completeness,
    required this.freshness,
    required this.oneLineSummary,
    required this.keyDetails,
    required this.recommendedAction,
    required this.personalizedWhatsAppMessage,
    this.whatsAppUrl,
    this.dialerUrl,
  });
}

/// Intelligent engine that analyzes, scores, and creates 1-click workflows for campaign leads.
class LeadUnderstandingEngine {
  static LeadUnderstanding analyze(IntegrationLeadModel lead) {
    final isOwner = lead.leadType == 'Property Listing';
    final persona = isOwner ? LeadPersona.ownerListing : LeadPersona.tenantRequirement;

    final name = lead.getStringValue(isOwner ? 'Client / Owner Name' : 'Client Name');
    final phone = lead.getStringValue('Phone Number');
    final config = lead.getStringValue(isOwner ? 'Property Type' : 'Configuration');
    final budgetOrRent = lead.getStringValue(isOwner ? 'Expected Rent' : 'Monthly Budget');
    final location = lead.getStringValue(isOwner ? 'Property Location' : 'Preferred Area');
    final city = lead.getStringValue('City');
    final staying = lead.getStringValue('Who Will Be Staying');
    final email = lead.getStringValue('Email ID');

    // Completeness score
    int score = 0;
    if (name.isNotEmpty) score++;
    if (phone.isNotEmpty) score++;
    if (config.isNotEmpty) score++;
    if (budgetOrRent.isNotEmpty) score++;
    if (location.isNotEmpty || city.isNotEmpty) score++;

    LeadCompleteness completeness;
    if (score >= 4) {
      completeness = LeadCompleteness.complete;
    } else if (score >= 2) {
      completeness = LeadCompleteness.partial;
    } else {
      completeness = LeadCompleteness.incomplete;
    }

    final freshness = lead.freshnessBadge;

    // One-line summary
    final oneLineSummary = lead.leadSummary;

    // Key details formatted bullet string
    final detailsList = <String>[];
    if (name.isNotEmpty) detailsList.add('Name: $name');
    if (phone.isNotEmpty) detailsList.add('Phone: $phone');
    if (config.isNotEmpty) detailsList.add(isOwner ? 'Configuration: $config' : 'Looking for: $config');
    if (budgetOrRent.isNotEmpty) detailsList.add(isOwner ? 'Expected Rent: $budgetOrRent' : 'Budget: $budgetOrRent');
    if (location.isNotEmpty) detailsList.add('Area: $location');
    if (city.isNotEmpty) detailsList.add('City: $city');
    if (staying.isNotEmpty) detailsList.add('Occupants: $staying');
    if (email.isNotEmpty) detailsList.add('Email: $email');
    detailsList.add('Arrived: ${lead.formattedReceivedAt} (${lead.relativeTimeAgo})');
    final keyDetails = detailsList.join('\n');

    // Recommended next action
    String recommendedAction;
    if (isOwner) {
      recommendedAction = lead.importStatus == 'Imported'
          ? 'Already added to Property Inventory. Follow up on tenant viewings.'
          : 'Move to Properties Inventory and call owner to verify keys/availability.';
    } else {
      recommendedAction = lead.importStatus == 'Imported'
          ? 'Already added to CRM Leads. Send matching property brochures on WhatsApp.'
          : 'Move to Leads Page and share matching rental inventory options.';
    }

    // Personalized WhatsApp Message
    String greetingName = name.isNotEmpty ? name : 'Sir/Ma\'am';
    // Clean honorary prefix
    if (!greetingName.toLowerCase().startsWith('mr') &&
        !greetingName.toLowerCase().startsWith('mrs') &&
        !greetingName.toLowerCase().startsWith('dr')) {
      greetingName = '$greetingName ji';
    }

    final locStr = [location, city].where((s) => s.isNotEmpty).join(', ');

    String waMsg;
    if (isOwner) {
      final configPart = config.isNotEmpty ? ' $config' : ' property';
      final locPart = locStr.isNotEmpty ? ' in $locStr' : '';
      final rentPart = budgetOrRent.isNotEmpty ? ' (Expected rent: $budgetOrRent)' : '';

      waMsg = 'Namaste $greetingName, this is from PropKart PropertyTech. '
          'We received your enquiry to list your$configPart$locPart for rent$rentPart. '
          'We currently have active tenant enquiries looking in your area. '
          'When would be a convenient time for a quick 2-minute call to discuss prospective tenants?';
    } else {
      final configPart = config.isNotEmpty ? ' $config' : ' rental property';
      final locPart = locStr.isNotEmpty ? ' in $locStr' : '';
      final budgetPart = budgetOrRent.isNotEmpty ? ' within budget $budgetOrRent' : '';

      waMsg = 'Namaste $greetingName, this is from PropKart PropertyTech. '
          'We received your requirement for a$configPart$locPart$budgetPart. '
          'We have verified, ready-to-move options matching your criteria. '
          'When would be a good time for a quick 2-minute call to share photos and schedule a visit?';
    }

    // Phone normalization for action links
    String cleanDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.startsWith('91') && cleanDigits.length == 12) {
      // already has 91
    } else if (cleanDigits.length == 10) {
      cleanDigits = '91$cleanDigits';
    }

    final whatsAppUrl = cleanDigits.isNotEmpty
        ? 'https://wa.me/$cleanDigits?text=${Uri.encodeComponent(waMsg)}'
        : null;

    final dialerUrl = cleanDigits.isNotEmpty ? 'tel:+$cleanDigits' : null;

    return LeadUnderstanding(
      persona: persona,
      completeness: completeness,
      freshness: freshness,
      oneLineSummary: oneLineSummary,
      keyDetails: keyDetails,
      recommendedAction: recommendedAction,
      personalizedWhatsAppMessage: waMsg,
      whatsAppUrl: whatsAppUrl,
      dialerUrl: dialerUrl,
    );
  }
}
