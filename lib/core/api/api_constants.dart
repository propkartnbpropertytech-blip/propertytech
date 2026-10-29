import '../config/app_env.dart';

class ApiConstants {
  static String get primaryBaseUrl => AppEnv.apiBaseUrl;
  static String get backupBaseUrl => AppEnv.apiBaseUrl;

  /// Connect directly to the environment-selected backend. No production fallback.
  static String get baseUrl => AppEnv.apiBaseUrl;

  static const String cloudinaryCloudName = "jdvya1gl";
  static const String cloudinaryApiKey = "131871686761399";

  static const sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: 'https://60d7ddcd27827fcd0b9ebe472ce8cd39@o4511857602658304.ingest.us.sentry.io/4511857636999168',
  );

  static const glitchtipDsn = String.fromEnvironment(
    'GLITCHTIP_DSN',
    defaultValue: '',
  );

  static String get errorMonitoringDsn =>
      glitchtipDsn.isNotEmpty ? glitchtipDsn : sentryDsn;

  static String get errorMonitoringProvider =>
      glitchtipDsn.isNotEmpty ? 'GlitchTip' : 'Sentry';

  static const captcha = "/auth/captcha";
  static const login = "/auth/login";
  static const register = "/auth/register";
  static const me = "/auth/me";
  static const refresh = "/auth/refresh";
  static const logout = "/auth/logout";
  static const mfaVerify = "/auth/mfa/verify";
  static const mfaSetup = "/auth/mfa/setup";
  static const mfaConfirm = "/auth/mfa/confirm";
  static const mfaDisable = "/auth/mfa/disable";
  static const health = "/health";

  static const telecallerAvailability = "/telecaller/availability";
  static const telecallerHeartbeat = "/telecaller/heartbeat";
  static const telecallerMyLeads = "/telecaller/my-leads";
  static const telecallerDashboard = "/telecaller/dashboard";
  static const telecallerCallbacks = "/telecaller/callbacks";
  static const telecallerCnr = "/telecaller/cnr";
  static const telecallerTransferLead = "/telecaller/transfer-lead";
  static const adminAllocationConfig = "/admin/allocation-config";
  static const adminAllocationConfigUserAvailability = "/admin/allocation-config/user-availability";
  static const adminAllocationConfigRole = "/admin/allocation-config/role";
  static const campaignAllocationMode = "/integrations/allocation-mode";
  static const adminAllocationConfigUserCampaigns = "/admin/allocation-config/user-campaigns";
  static const adminAllocationCategoryAllocation = "/admin/allocation-config/category-allocation";
  static String adminAllocationCategoryToggle(String id) => "/admin/allocation-config/category-allocation/$id/toggle";
  static String adminAllocationCategoryDelete(String id) => "/admin/allocation-config/category-allocation/$id";
  static const adminAllocationCategoryBatch = "/admin/allocation-config/category-allocations-batch";
  static const adminAllocationCategoryCopy = "/admin/allocation-config/category-allocations-copy";
  static const salesAvailability = "/sales/availability";
  static const salesHeartbeat = "/sales/heartbeat";
  static const adminAllocationMonitor = "/admin/allocation-monitor";
  static const adminAllocationEngineToggle = "/admin/allocation-engine/toggle";
  static const adminAllocationEngineStatus = "/admin/allocation-engine/status";
  static const adminReassignLead = "/admin/reassign-lead";
  static const adminTransferCampaignLeadToSales = "/admin/campaign-leads/transfer-to-sales";
  static const adminAllocateOldLeads = "/admin/allocate-old-leads";
  static const adminTokenExpiration = "/admin/token-expiration";
  static const adminRecoverStaleLeads = "/admin/recover-stale-leads";
  static String adminTelecallerDetails(String id) => "/admin/telecallers/$id/details";
  static String adminTelecallerCapacity(String id) => "/admin/telecallers/$id/capacity";
  static const allocationSalesLeads = "/allocation/sales-leads";
  static String allocationSalesLeadStatus(String id) => "/allocation/sales-leads/$id/status";
  static const allocationSalesLeadBulkStatus = "/allocation/sales-leads/bulk-status";
  static const salesDashboardSummary = "/sales/dashboard-summary";
  static const superAdminMetrics = "/super-admin/metrics";

  /// Public web URL used in password-recovery emails.
  static const passwordResetRedirectTo = 'https://propkart.nbpropertytech.com/reset-password';

  /// Mobile deep-link scheme for recovery redirects into the native app.
  static const passwordResetDeepLink = 'io.nbpropertytech.propkart://reset-password';

  static void assertConfig() {
    AppEnv.assertConfigured();
  }
}
