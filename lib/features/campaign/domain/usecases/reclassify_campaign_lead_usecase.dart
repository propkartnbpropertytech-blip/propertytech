import '../../../integration/services/integration_service.dart';

/// Business operation to reclassify a Campaign Lead between "Property Listing" and "Requirement Lead".
class ReclassifyCampaignLeadUseCase {
  final IntegrationService integrationService;

  ReclassifyCampaignLeadUseCase({IntegrationService? service})
      : integrationService = service ?? IntegrationService();

  /// Optimistically updates the lead in-memory so UI switches immediately.
  void executeOptimistic(String leadId, String targetLeadType) {
    integrationService.reclassifyLeadOptimistic(leadId, targetLeadType);
  }

  /// Sends the reclassification update to the backend server.
  Future<bool> execute(String leadId, String targetLeadType) async {
    return integrationService.reclassifyLead(leadId, targetLeadType);
  }

  /// Reclassifies multiple leads in bulk.
  Future<bool> executeBulk(List<String> leadIds, String targetLeadType) async {
    return integrationService.bulkReclassifyLeads(leadIds, targetLeadType);
  }
}
