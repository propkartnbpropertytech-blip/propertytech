import 'package:equatable/equatable.dart';

class ReportFilterState extends Equatable {
  final String? propertyId;
  final String? propertyName;
  final String? leadSource;
  final String? telecallerId;
  final String? telecallerName;
  final String? salesUserId;
  final String? salesUserName;
  final String? leadStatus;
  final String? leadType; // 'Rent', 'Sale' or Category
  final String? locationId; // Area or City
  final String? locationName;
  final String? campaign;

  const ReportFilterState({
    this.propertyId,
    this.propertyName,
    this.leadSource,
    this.telecallerId,
    this.telecallerName,
    this.salesUserId,
    this.salesUserName,
    this.leadStatus,
    this.leadType,
    this.locationId,
    this.locationName,
    this.campaign,
  });

  const ReportFilterState.empty()
      : propertyId = null,
        propertyName = null,
        leadSource = null,
        telecallerId = null,
        telecallerName = null,
        salesUserId = null,
        salesUserName = null,
        leadStatus = null,
        leadType = null,
        locationId = null,
        locationName = null,
        campaign = null;

  bool get hasActiveFilters =>
      propertyId != null ||
      leadSource != null ||
      telecallerId != null ||
      salesUserId != null ||
      leadStatus != null ||
      leadType != null ||
      locationId != null ||
      campaign != null;

  int get activeFiltersCount {
    int count = 0;
    if (propertyId != null) count++;
    if (leadSource != null) count++;
    if (telecallerId != null) count++;
    if (salesUserId != null) count++;
    if (leadStatus != null) count++;
    if (leadType != null) count++;
    if (locationId != null) count++;
    if (campaign != null) count++;
    return count;
  }

  ReportFilterState copyWith({
    String? propertyId,
    String? propertyName,
    String? leadSource,
    String? telecallerId,
    String? telecallerName,
    String? salesUserId,
    String? salesUserName,
    String? leadStatus,
    String? leadType,
    String? locationId,
    String? locationName,
    String? campaign,
    bool clearProperty = false,
    bool clearLeadSource = false,
    bool clearTelecaller = false,
    bool clearSalesUser = false,
    bool clearLeadStatus = false,
    bool clearLeadType = false,
    bool clearLocation = false,
    bool clearCampaign = false,
  }) {
    return ReportFilterState(
      propertyId: clearProperty ? null : (propertyId ?? this.propertyId),
      propertyName: clearProperty ? null : (propertyName ?? this.propertyName),
      leadSource: clearLeadSource ? null : (leadSource ?? this.leadSource),
      telecallerId: clearTelecaller ? null : (telecallerId ?? this.telecallerId),
      telecallerName: clearTelecaller ? null : (telecallerName ?? this.telecallerName),
      salesUserId: clearSalesUser ? null : (salesUserId ?? this.salesUserId),
      salesUserName: clearSalesUser ? null : (salesUserName ?? this.salesUserName),
      leadStatus: clearLeadStatus ? null : (leadStatus ?? this.leadStatus),
      leadType: clearLeadType ? null : (leadType ?? this.leadType),
      locationId: clearLocation ? null : (locationId ?? this.locationId),
      locationName: clearLocation ? null : (locationName ?? this.locationName),
      campaign: clearCampaign ? null : (campaign ?? this.campaign),
    );
  }

  @override
  List<Object?> get props => [
        propertyId,
        propertyName,
        leadSource,
        telecallerId,
        telecallerName,
        salesUserId,
        salesUserName,
        leadStatus,
        leadType,
        locationId,
        locationName,
        campaign,
      ];

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'propertyName': propertyName,
      'leadSource': leadSource,
      'telecallerId': telecallerId,
      'telecallerName': telecallerName,
      'salesUserId': salesUserId,
      'salesUserName': salesUserName,
      'leadStatus': leadStatus,
      'leadType': leadType,
      'locationId': locationId,
      'locationName': locationName,
      'campaign': campaign,
    };
  }

  factory ReportFilterState.fromJson(Map<String, dynamic> json) {
    return ReportFilterState(
      propertyId: json['propertyId'] as String?,
      propertyName: json['propertyName'] as String?,
      leadSource: json['leadSource'] as String?,
      telecallerId: json['telecallerId'] as String?,
      telecallerName: json['telecallerName'] as String?,
      salesUserId: json['salesUserId'] as String?,
      salesUserName: json['salesUserName'] as String?,
      leadStatus: json['leadStatus'] as String?,
      leadType: json['leadType'] as String?,
      locationId: json['locationId'] as String?,
      locationName: json['locationName'] as String?,
      campaign: json['campaign'] as String?,
    );
  }
}
