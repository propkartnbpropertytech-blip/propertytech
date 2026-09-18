import 'dart:async';
import 'dart:convert';
import '../../../core/services/notification_center.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/theme/theme_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/widgets/drawers.dart';
import '../../../core/design_system/widgets/form/crm_multi_select_dropdown.dart';
import '../bloc/requirements_bloc.dart';
import '../models/requirement_model.dart';
import '../services/match_criteria_manager.dart';
import '../repository/requirements_repository.dart';
import 'add_edit_requirement_screen.dart';
import '../../properties/repository/properties_repository.dart';
import '../../properties/services/properties_service.dart';
import '../../properties/models/property_model.dart';
import '../../../core/storage/local_repositories.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/tokens/app_motion.dart';
import '../../../core/design_system/tokens/app_shadows.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/crm_page_header.dart';
import '../../../core/design_system/widgets/data_table.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../dashboard/repository/dashboard_repository.dart';
import '../../dashboard/models/dashboard_summary.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/utils/budget_formatter.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user_model.dart';
import '../../users/bloc/users_bloc.dart';
import '../../users/models/user_model.dart' as users_model;
import '../../users/repository/users_repository.dart';
import '../../team_messages/services/team_messages_service.dart';
import '../../../core/config/app_config.dart';
import 'package:collection/collection.dart';
import 'package:propkart/core/storage/repository_coordinator.dart';
import 'package:propkart/core/storage/model_mappers.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import '../../../core/utils/file_downloader.dart';
import '../utils/property_share_pdf.dart';
import '../../../core/api/cloudinary_uploader.dart';
import '../../../core/telemetry/audit_telemetry_service.dart';
import '../../../core/telemetry/audit_dwell_tracker.dart';
import '../../../core/utils/team_user_visibility.dart';
import '../../../core/security/role_guard.dart';

/// WhatsApp brand green — kept as a distinct constant for brand recognition.
const Color kWhatsAppGreen = Color(0xFF25D366);

DateTime? _parseFollowupDateTime(dynamic raw) {
  if (raw == null) return null;
  String str = raw.toString().trim();
  if (str.isEmpty) return null;

  final parsed = DateTime.tryParse(str);
  if (parsed != null) {
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  try {
    final parts = str.split(RegExp(r'[T\s]'));
    final dateParts = parts[0].split(RegExp(r'[/\\-]'));
    if (dateParts.length == 3) {
      int d, m, y;
      if (dateParts[0].length == 4) {
        y = int.parse(dateParts[0]);
        m = int.parse(dateParts[1]);
        d = int.parse(dateParts[2]);
      } else {
        d = int.parse(dateParts[0]);
        m = int.parse(dateParts[1]);
        y = int.parse(dateParts[2]);
      }
      int h = 0, min = 0, sec = 0;
      if (parts.length > 1 && parts[1].isNotEmpty) {
        final timeParts = parts[1].split(':');
        if (timeParts.length >= 2) {
          h = int.tryParse(timeParts[0]) ?? 0;
          min = int.tryParse(timeParts[1].replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
          if (timeParts.length >= 3) {
            sec = int.tryParse(timeParts[2].replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
          }
        }
      }
      return DateTime(y, m, d, h, min, sec);
    }
  } catch (_) {}

  return null;
}

  String? getTelecallerRemarks(RequirementModel req) {
  if (req.metaCustomFields != null && req.metaCustomFields!['telecaller_remarks'] != null) {
    final tr = req.metaCustomFields!['telecaller_remarks'].toString().trim();
    if (tr.isNotEmpty && tr.toLowerCase() != 'null' && tr.toLowerCase() != 'n/a') {
      return tr;
    }
  }
  if (req.notes != null) {
    final text = req.notes!.trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null' && text.toLowerCase() != 'n/a') {
      return text;
    }
  }
  if (req.remarks != null && req.remarks!.trim().isNotEmpty) {
    final text = req.remarks!.trim();
    if (text.contains('[Telecaller Key Points]:')) {
      final parts = text.split('[Telecaller Key Points]:');
      if (parts.length > 1) {
        final extracted = parts[1].split('\n').first.trim();
        if (extracted.isNotEmpty) return extracted;
      }
    }
    if (text.toLowerCase() != 'null' && text.toLowerCase() != 'n/a') {
      return text;
    }
  }
  return null;
}

Widget _buildNeedsMoreDetailsBadge(RequirementModel req, {bool compact = false}) {
    if (req.matchingReadiness == 'Ready') return const SizedBox.shrink();

    final missing = <String>[];
    if (req.minBudget <= 0 && req.maxBudget <= 0) missing.add('Budget');
    if (!req.isAllAreas && req.areaIds.isEmpty && req.areaNames.isEmpty) missing.add('Area');
    final hasConfig = (req.configurationId != null && req.configurationId!.trim().isNotEmpty) || req.configurationIds.isNotEmpty || (req.configurationName != null && req.configurationName!.trim().isNotEmpty);
    if (!hasConfig) missing.add('Config');
    final hasCategory = req.categoryId.trim().isNotEmpty || req.categoryName.trim().isNotEmpty || req.propertyTypeName.trim().isNotEmpty;
    if (!hasCategory) missing.add('Category');

    final tooltipMsg = missing.isNotEmpty
        ? 'Needs More Details: Missing ${missing.join(', ')}'
        : 'Needs More Details for Property Matching';

    return Tooltip(
      message: tooltipMsg,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 7,
          vertical: compact ? 1.5 : 2.5,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFF97316).withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 11,
              color: Color(0xFFEA580C),
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                'Needs More Details',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFFC2410C),
                  fontSize: compact ? 9.5 : 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

class PropertyMatchResult {
  final PropertyModel property;
  final int matchPercentage;
  final List<String> matchedCriteria;
  final bool isPriceMatched;
  final bool isConfigMatched;
  final bool isAreaMatched;
  final bool isListingTypeMatched;
  final bool isPropertyTypeMatched;
  final List<String> unmatchedPreferences;
  final Map<String, dynamic>? locationMatchDetail;
  final Map<String, dynamic>? breakdown;

  PropertyMatchResult({
    required this.property,
    required this.matchPercentage,
    required this.matchedCriteria,
    this.isPriceMatched = false,
    this.isConfigMatched = false,
    this.isAreaMatched = false,
    this.isListingTypeMatched = false,
    this.isPropertyTypeMatched = false,
    this.unmatchedPreferences = const [],
    this.locationMatchDetail,
    this.breakdown,
  });

  factory PropertyMatchResult.fromServerJson(Map<String, dynamic> json, PropertyModel property) {
    final bd = json['breakdown'] as Map<String, dynamic>?;
    final matchedReasons = (json['matched_reasons'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final unmatched = (json['unmatched_preferences'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final score = (json['overall_match_score'] as num?)?.toInt() ?? 0;

    return PropertyMatchResult(
      property: property,
      matchPercentage: score,
      matchedCriteria: matchedReasons,
      unmatchedPreferences: unmatched,
      isPriceMatched: (bd?['budget_score'] as num? ?? 0) > 0,
      isConfigMatched: (bd?['configuration_score'] as num? ?? 0) > 0,
      isAreaMatched: (bd?['location_score'] as num? ?? 0) > 0,
      isListingTypeMatched: (bd?['listing_type_score'] as num? ?? 0) > 0,
      isPropertyTypeMatched: (bd?['property_type_score'] as num? ?? 0) > 0,
      locationMatchDetail: json['location_match_detail'] as Map<String, dynamic>?,
      breakdown: bd,
    );
  }
}

class PropertyRequirementMatcher {
  static Set<int> extractBhkNumbers(String? text, {int fallbackBedrooms = 0}) {
    final Set<int> bhks = {};
    if (fallbackBedrooms > 0 && fallbackBedrooms <= 10) {
      bhks.add(fallbackBedrooms);
    }
    if (text == null || text.trim().isEmpty) return bhks;

    final matches = RegExp(r'(\d+)\s*(?:bhk|bedroom|bed|rk)', caseSensitive: false).allMatches(text);
    for (final m in matches) {
      final numStr = m.group(1);
      if (numStr != null) {
        final n = int.tryParse(numStr);
        if (n != null && n > 0 && n <= 10) bhks.add(n);
      }
    }
    if (bhks.isEmpty && text.toLowerCase().contains('bhk')) {
      final numMatches = RegExp(r'\b(\d+)\b').allMatches(text);
      for (final m in numMatches) {
        final n = int.tryParse(m.group(1)!);
        if (n != null && n > 0 && n <= 10) bhks.add(n);
      }
    }
    return bhks;
  }

  static String _normalizeTypeLabel(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _isFlatApartmentType(String raw) {
    final n = _normalizeTypeLabel(raw);
    if (n.isEmpty) return false;
    if (n.contains('apartment') || n.contains('flat')) return true;
    final tokens = n.split(' ');
    return tokens.contains('apt') || tokens.contains('apts') || tokens.contains('flats');
  }

  static bool propertyTypesCompatible({
    required String reqTypeName,
    required String propTypeName,
    String reqTypeId = '',
    String propTypeId = '',
    List<String> reqTypeIds = const [],
    String reqCategory = '',
    String propCategory = '',
  }) {
    if (reqTypeIds.contains(propTypeId) ||
        (reqTypeId.isNotEmpty && propTypeId.isNotEmpty && reqTypeId == propTypeId)) {
      return true;
    }

    final reqType = _normalizeTypeLabel(reqTypeName);
    final propType = _normalizeTypeLabel(propTypeName);
    if (reqType.isNotEmpty && propType.isNotEmpty) {
      if (reqType == propType) return true;
      if (reqType.contains(propType) || propType.contains(reqType)) return true;
      if (_isFlatApartmentType(reqType) && _isFlatApartmentType(propType)) {
        return true;
      }

      bool isVilla(String s) =>
          s.contains('villa') ||
          s.contains('bungalow') ||
          s.contains('house');
      bool isPlot(String s) => s.contains('plot') || s.contains('land');
      bool isOffice(String s) =>
          s.contains('office') ||
          s.contains('commercial') ||
          s.contains('shop') ||
          s.contains('showroom');
      if (isVilla(reqType) && isVilla(propType)) return true;
      if (isPlot(reqType) && isPlot(propType)) return true;
      if (isOffice(reqType) && isOffice(propType)) return true;
    }

    final reqCat = _normalizeTypeLabel(reqCategory);
    final propCat = _normalizeTypeLabel(propCategory);
    if (reqCat.isNotEmpty && propCat.isNotEmpty &&
        (reqCat == propCat || reqCat.contains(propCat) || propCat.contains(reqCat))) {
      if (reqType.isEmpty || propType.isEmpty) return true;
    }

    if (reqType.isEmpty && reqTypeId.isEmpty && reqCat.isEmpty) return true;
    return false;
  }

  static bool _hasRequirementCategory(RequirementModel req) {
    return req.categoryId.trim().isNotEmpty || req.categoryName.trim().isNotEmpty;
  }

  static bool _hasRequirementPropertyType(RequirementModel req) {
    return req.propertyTypeId.trim().isNotEmpty ||
        req.propertyTypeIds.isNotEmpty ||
        req.propertyTypeName.trim().isNotEmpty;
  }

  static bool categoriesCompatible(RequirementModel req, PropertyModel p) {
    if (!_hasRequirementCategory(req)) return true;
    if (req.categoryId.trim().isNotEmpty &&
        p.categoryId.trim().isNotEmpty &&
        req.categoryId.trim() == p.categoryId.trim()) {
      return true;
    }
    final reqCat = _normalizeTypeLabel(req.categoryName);
    final propCat = _normalizeTypeLabel(p.categoryName);
    return reqCat.isNotEmpty && propCat.isNotEmpty && reqCat == propCat;
  }

  static bool isEligibleByCategoryAndType(PropertyModel p, RequirementModel req) {
    if (!categoriesCompatible(req, p)) return false;
    if (!_hasRequirementPropertyType(req)) return true;
    return propertyTypesCompatible(
      reqTypeName: req.propertyTypeName,
      propTypeName: p.propertyTypeName,
      reqTypeId: req.propertyTypeId,
      propTypeId: p.propertyTypeId,
      reqTypeIds: req.propertyTypeIds,
      reqCategory: req.categoryName,
      propCategory: p.categoryName,
    );
  }

  static bool isAllAreas(RequirementModel req) {
    if (req.areaIds.isEmpty && req.areaNames.isEmpty) return true;
    for (final a in req.areaNames) {
      final l = a.trim().toLowerCase();
      if (l.isEmpty ||
          l == 'all areas' ||
          l == 'all' ||
          l == 'any area' ||
          l == 'any' ||
          l == 'anywhere' ||
          l == 'entire city' ||
          l == 'all localities') {
        return true;
      }
    }
    return false;
  }

  static bool _isAnyConfigurationLabel(String? raw) {
    final n = (raw ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (n.isEmpty) return true;
    const aliases = {
      'any',
      'any config',
      'any configuration',
      'any configurations',
      'all config',
      'all configuration',
      'all configurations',
      'any bhk',
      'all bhk',
      'any rk',
      'na',
      'n a',
      'unspecified',
      'not specified',
    };
    return aliases.contains(n);
  }

  static bool isAnyConfiguration(RequirementModel req) {
    final hasId = (req.configurationId != null && req.configurationId!.trim().isNotEmpty) ||
        req.configurationIds.isNotEmpty;
    if (hasId) return false;
    return _isAnyConfigurationLabel(req.configurationName);
  }

  static const Map<String, Set<String>> _zoneLocalities = {
    'west': {
      'ambawadi', 'ambli', 'anandnagar', 'azadsociety', 'bhadaj', 'bodakdev',
      'bopal', 'jodhpur', 'jodhpurcharrasta', 'makarba', 'marigold', 'memnagar',
      'prahladnagar', 'sarkhej', 'satellite', 'satelite', 'sciencecity', 'sciencepark',
      'sciencecityroad', 'shela', 'shilaj', 'shyamal', 'sindhubhavan', 'sola',
      'southbopal', 'thaltej', 'vastrapur', 'westahmedabad', 'westamdavad',
      'sghighway', 'sgroad',
    },
    'north': {
      'chandkheda', 'chandlodia', 'ghatlodia', 'gota', 'jagatpur', 'kknagar',
      'naranpura', 'newranip', 'ognaj', 'ranip', 'tragad', 'vaishnodevi',
      'vaishnodevicircle',
    },
    'east': {'naroda', 'nikol'},
    'central': {'navrangpura'},
  };

  static String? _zoneKeyForName(String cleanName) {
    final n = cleanName;
    if (n.isEmpty) return null;
    if (n.contains('westahmedabad') ||
        n.contains('westamdavad') ||
        n.contains('southwestahmedabad') ||
        n.contains('westernahmedabad') ||
        n == 'westahmd') {
      return 'west';
    }
    if (n.contains('northahmedabad') || n.contains('northamdavad')) return 'north';
    if (n.contains('eastahmedabad') || n.contains('eastamdavad')) return 'east';
    if (n.contains('centralahmedabad') || n.contains('centralamdavad')) return 'central';
    return null;
  }

  static bool _isInConfiguredZone(String zoneKey, String areaClean) {
    if (areaClean.isEmpty) return false;
    final members = _zoneLocalities[zoneKey];
    if (members == null) return false;
    if (members.contains(areaClean)) return true;
    if (_zoneKeyForName(areaClean) == zoneKey) return true;
    for (final loc in members) {
      if (loc.length >= 5 && areaClean.contains(loc)) return true;
    }
    return false;
  }

  static bool _namesReferToSameLocality(String a, String aClean, String b, String bClean) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b || aClean == bClean) return true;
    const tooGeneric = {'ahmedabad', 'amdavad', 'gujarat', 'india'};
    if (tooGeneric.contains(aClean) || tooGeneric.contains(bClean)) return false;
    if (aClean.length >= 5 && bClean.length >= 5 &&
        (aClean.contains(bClean) || bClean.contains(aClean))) {
      return true;
    }
    return false;
  }

  static PropertyMatchResult match(PropertyModel p, RequirementModel req) {
    final statusName = p.propertyStatusName.toLowerCase();
    final isInactive = statusName.contains('rented') || statusName.contains('sold') || statusName.contains('closed') || statusName.contains('inactive');
    final isWonReq = req.status.toLowerCase() == 'won' || req.status.toLowerCase() == 'closed';
    if (isInactive && !isWonReq) {
      return PropertyMatchResult(
        property: p,
        matchPercentage: 0,
        matchedCriteria: [],
        unmatchedPreferences: ['Property is not available ($statusName)'],
      );
    }

    if (!isEligibleByCategoryAndType(p, req)) {
      return PropertyMatchResult(
        property: p,
        matchPercentage: 0,
        matchedCriteria: [],
        unmatchedPreferences: ['Category or property type does not match the client requirement'],
      );
    }

    final List<String> matchedTags = [];
    int totalScore = 0;

    // 1. Listing Type Match (Weight: 10 pts)
    bool isListingMatch = false;
    final reqListing = (req.listingTypeName ?? '').toLowerCase();
    final propListing = (p.listingTypeName).toLowerCase();
    final isReqRent = reqListing.contains('rent') || reqListing.contains('lease');
    final isPropRent = propListing.contains('rent') || propListing.contains('lease') || p.listingTypeId == '1c1ccfc1-d318-4b66-9a43-c551532d1802';
    final isReqSale = reqListing.contains('sale') || reqListing.contains('resale') || reqListing.contains('buy');
    final isPropSale = !isPropRent && (propListing.contains('sale') || propListing.contains('resale') || propListing.isNotEmpty);

    // Hard Filter: Rent vs Resale conflict
    if ((isReqRent && isPropSale) || (isReqSale && isPropRent)) {
      return PropertyMatchResult(
        property: p,
        matchPercentage: 0,
        matchedCriteria: [],
        unmatchedPreferences: ['Listing type conflict: Requirement is ${isReqRent ? "Rent" : "Resale"}, Property is ${isPropRent ? "Rent" : "Resale"}'],
      );
    }

    if (reqListing.isEmpty) {
      totalScore += 10;
      isListingMatch = true;
    } else if (isReqRent && isPropRent) {
      totalScore += 10;
      isListingMatch = true;
      matchedTags.add('✓ Rent');
    } else if (isReqSale && isPropSale) {
      totalScore += 10;
      isListingMatch = true;
      matchedTags.add('✓ Resale/Sale');
    } else if (p.listingTypeId.isNotEmpty && req.listingTypeId != null && p.listingTypeId == req.listingTypeId) {
      totalScore += 10;
      isListingMatch = true;
      matchedTags.add('✓ Listing Type');
    }

    // 2. Target Area Match (Weight: 25 pts)
    bool isAreaMatch = false;
    if (isAllAreas(req)) {
      totalScore += 25;
      isAreaMatch = true;
      matchedTags.add('✓ All Areas');
    } else {
      final pArea = p.areaName.trim().toLowerCase();
      final pAreaClean = pArea.replaceAll(RegExp(r'[^a-z0-9]'), '');
      final pTitleClean = p.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      bool found = false;
      bool isZoneMatch = false;
      String zoneLabel = '';

      if (req.areaIds.isNotEmpty && p.areaId.isNotEmpty && req.areaIds.contains(p.areaId)) {
        found = true;
      }

      if (!found && req.areaNames.isNotEmpty) {
        for (final aName in req.areaNames) {
          final subAreas = aName.split(RegExp(r'[,/|]'));
          for (final sub in subAreas) {
            final trimmed = sub.trim().toLowerCase();
            final trimmedClean = trimmed.replaceAll(RegExp(r'[^a-z0-9]'), '');
            if (trimmed.isEmpty) continue;
            if (_namesReferToSameLocality(trimmed, trimmedClean, pArea, pAreaClean)) {
              found = true;
              break;
            }
            final zoneKey = _zoneKeyForName(trimmedClean);
            if (zoneKey != null &&
                (_isInConfiguredZone(zoneKey, pAreaClean) ||
                    _isInConfiguredZone(zoneKey, pTitleClean))) {
              isZoneMatch = true;
              found = true;
              zoneLabel = sub.trim();
              break;
            }
          }
          if (found) break;
        }
      }

      if (found) {
        totalScore += 25;
        isAreaMatch = true;
        matchedTags.add(isZoneMatch
            ? '✓ Zone: ${zoneLabel.isNotEmpty ? zoneLabel : 'coverage'} (covers ${p.areaName.isNotEmpty ? p.areaName : p.title})'
            : '✓ Area: ${p.areaName}');
      } else if (p.cityName.isNotEmpty && (req.cityName.isNotEmpty ? p.cityName.toLowerCase() == req.cityName.toLowerCase() : req.areaNames.any((a) => a.toLowerCase().contains(p.cityName.toLowerCase()) || p.cityName.toLowerCase().contains(a.toLowerCase())))) {
        totalScore += 10;
        matchedTags.add('✓ City: ${p.cityName}');
      }
    }

    // 3. Configuration / BHK Match (Weight: 25 pts)
    // "Any Configuration" fully satisfies this criterion (1RK through penthouse/villa/duplex).
    bool isConfigMatch = false;
    if (isAnyConfiguration(req)) {
      totalScore += 25;
      isConfigMatch = true;
      matchedTags.add('✓ Any Configuration');
    } else {
    final reqBhks = extractBhkNumbers(req.configurationName);
    final propBhks = extractBhkNumbers(
      '${p.configurationName ?? ''} ${p.title}',
      fallbackBedrooms: p.bedrooms,
    );

    final bool hasSameId = (p.configurationId != null && p.configurationId!.isNotEmpty && req.configurationIds.contains(p.configurationId)) ||
        (p.configurationId != null && req.configurationId != null && p.configurationId == req.configurationId);

    if (reqBhks.isNotEmpty && propBhks.isNotEmpty) {
      final intersection = reqBhks.intersection(propBhks);
      if (intersection.isNotEmpty) {
        totalScore += 25;
        isConfigMatch = true;
        matchedTags.add('✓ ${intersection.join(", ")} BHK');
      } else {
        bool adjacent = false;
        for (final rb in reqBhks) {
          for (final pb in propBhks) {
            if ((rb - pb).abs() == 1) {
              adjacent = true;
              break;
            }
          }
          if (adjacent) break;
        }
        if (adjacent) {
          totalScore += 12;
          final pBhkStr = propBhks.isNotEmpty ? '${propBhks.first} BHK' : (p.bedrooms > 0 ? '${p.bedrooms} BHK' : '');
          if (pBhkStr.isNotEmpty) matchedTags.add('~ Near BHK ($pBhkStr)');
        }
      }
    } else if (hasSameId) {
      totalScore += 25;
      isConfigMatch = true;
      matchedTags.add('✓ Config Match');
    } else if (req.configurationName != null && req.configurationName!.isNotEmpty && p.configurationName != null && p.configurationName!.isNotEmpty) {
      final rName = req.configurationName!.toLowerCase();
      final pName = p.configurationName!.toLowerCase();
      if (rName.contains(pName) || pName.contains(rName)) {
        totalScore += 25;
        isConfigMatch = true;
        matchedTags.add('✓ ${p.configurationName}');
      }
    }
    }

    // 4. Price / Budget Match (Weight: 30 pts)
    bool isPriceMatch = false;
    final minB = req.minBudget > 0 ? req.minBudget : 0.0;
    final maxB = req.maxBudget > 0 ? req.maxBudget : 0.0;
    final price = p.price;

    if (maxB > 0) {
      if (price >= minB && price <= maxB) {
        totalScore += 30;
        isPriceMatch = true;
        matchedTags.add('✓ In Budget (₹${BudgetFormatter.format(price)})');
      } else if (price >= minB * 0.8 && price <= maxB * 1.2) {
        totalScore += 20;
        matchedTags.add('~ Near Budget (₹${BudgetFormatter.format(price)})');
      } else if (price >= minB * 0.65 && price <= maxB * 1.35) {
        totalScore += 10;
        matchedTags.add('~ Flex Budget (₹${BudgetFormatter.format(price)})');
      }
    } else {
      totalScore += 20;
      isPriceMatch = true;
      matchedTags.add('✓ ₹${BudgetFormatter.format(price)}');
    }

    // 5. Property Type / Category Match (Weight: 10 pts)
    // Apartment requirements must match Flat/Apartment inventory (same residential type).
    bool isPropTypeMatch = false;
    if (propertyTypesCompatible(
      reqTypeName: req.propertyTypeName,
      propTypeName: p.propertyTypeName,
      reqTypeId: req.propertyTypeId,
      propTypeId: p.propertyTypeId,
      reqTypeIds: req.propertyTypeIds,
      reqCategory: req.categoryName,
      propCategory: p.categoryName,
    )) {
      totalScore += 10;
      isPropTypeMatch = true;
      final typeLabel = p.propertyTypeName.trim().isNotEmpty
          ? p.propertyTypeName
          : p.categoryName;
      if (typeLabel.trim().isNotEmpty) {
        matchedTags.add('✓ $typeLabel');
      }
    }

    final finalPct = totalScore.clamp(0, 100);

    return PropertyMatchResult(
      property: p,
      matchPercentage: finalPct,
      matchedCriteria: matchedTags,
      isPriceMatched: isPriceMatch,
      isConfigMatched: isConfigMatch,
      isAreaMatched: isAreaMatch,
      isListingTypeMatched: isListingMatch,
      isPropertyTypeMatched: isPropTypeMatch,
    );
  }

  static int calculateMatchPercentage(PropertyModel p, RequirementModel req) {
    return match(p, req).matchPercentage;
  }

  static bool isMatch(PropertyModel p, RequirementModel req, {int? threshold}) {
    final t = threshold ?? MatchCriteriaManager().threshold;
    return match(p, req).matchPercentage >= t;
  }
}

class RequirementsScreen extends StatefulWidget {
  final String? initialTab;
  final String? initialSubTab;
  final String? initialGroup;

  const RequirementsScreen({
    super.key,
    this.initialTab,
    this.initialSubTab,
    this.initialGroup,
  });

  @override
  State<RequirementsScreen> createState() => _RequirementsScreenState();
}

enum LeadDateFilterPreset {
  today,
  yesterday,
  last7Days,
  thisMonth,
  customRange,
  allTime,
}

class _RequirementsScreenState extends State<RequirementsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _wonSearchController = TextEditingController();
  String? _wonCategoryId;
  String? _wonPropertyTypeId;
  final List<String> _wonConfigurationIds = [];
  final List<String> _selectedConfigIds = [];
  String? _selectedCategoryId;
  String _selectedStatus = "All";
  String _selectedUserFilterId = "All";
  String _selectedReadiness = "All";
  LeadDateFilterPreset _selectedLeadDateFilter = LeadDateFilterPreset.allTime;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String get _activeListingTab => ThemeManager().isRentMode ? 'Rent' : 'Re-Sale';
  set _activeListingTab(String value) {
    ThemeManager().setRentMode(value == 'Rent');
  }
  String _activeMainTab = "Leads"; // "Leads", "Requirements", or "Follow-ups"
  DateTime? _reqFollowupDateFilter = DateTime.now();
  String _selectedFollowupSubTab = "Today"; // "Today", "Due", "Future"
  String _selectedMainFollowupSection = "Follow ups"; // "Follow ups" or "Site Visit Scheduled"
  final Set<String> _selectedFollowupClientKeys = {};
  int _currentPage = 1;
  int _requirementsPerPage = 10;
  int _currentFollowupPage = 1;
  int _followupsPerPage = 10;
  final PropertiesRepository _propertiesRepository = PropertiesRepository();
  List<PropertyModel>? _propertiesForMatches;
  PropertyMetadataModel? _metadata;
  bool _isTableView = false;
  bool _isLoadingMetadata = true;
  bool _hasAutoOpenedAdd = false;
  bool _isMobileFiltersExpanded = false;
  late Future<List<dynamic>> _followupsFuture;
  StreamSubscription? _requirementsStreamSub;
  StreamSubscription? _dashboardStreamSub;
  OverlayEntry? _notesOverlayEntry;
  final Set<String> _selectedRequirementIds = {};
  final ScrollController _scrollController = ScrollController();
  String? _highlightedRequirementId;
  List<RequirementModel> _cachedRequirements = [];
  final Map<String, RequirementModel> _localRequirementOverrides = {};
  String _salesLeadGroupFilter = 'assigned'; // 'assigned', 'added', 'all'
  final UsersRepository _usersRepository = UsersRepository();
  List<users_model.UserModel> _assignUsers = [];
  bool _assignUsersLoading = false;

  Future<void> _confirmBulkMoveToBin(List<RequirementModel> pageItems) async {
    final count = _selectedRequirementIds.length;
    if (count == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_delete_outlined, color: CRMColors.danger, size: 22),
            const SizedBox(width: 8),
            Text('Move $count Lead(s) to Recycle Bin?'),
          ],
        ),
        content: Text(
          'Selected lead(s) will be moved to the Recycle Bin and can be restored anytime from the Recycle Bin tab.',
          style: TextStyle(fontSize: 13.5, color: CRMColors.textOf(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CRMColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Move to Bin'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final idsToDelete = List<String>.from(_selectedRequirementIds);
      setState(() {
        _selectedRequirementIds.clear();
      });

      for (final id in idsToDelete) {
        try {
          await RequirementsRepository().deleteRequirement(id);
        } catch (_) {}
      }

      _triggerFetch();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count lead(s) moved to Recycle Bin successfully.'),
            backgroundColor: CRMColors.success,
          ),
        );
      }
    }
  }

  void _refreshFollowupsFuture() {
    _followupsFuture = Future.wait([
      DashboardRepository().getDashboardData(backgroundRefresh: false),
      RequirementsRepository().getRequirements(refreshFromServer: false),
    ]);
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) {
      final tabLower = widget.initialTab!.toLowerCase();
      if (tabLower == 'follow-ups' || tabLower == 'followups') {
        _activeMainTab = 'Follow-ups';
      } else if (tabLower == 'my won' || tabLower == 'won') {
        _activeMainTab = 'My Won';
      } else if (tabLower == 'rejected') {
        _activeMainTab = 'Rejected';
      } else if (tabLower == 'leads added by me' || tabLower == 'added') {
        _activeMainTab = 'Leads Added by Me';
      } else if (tabLower == 'leads') {
        _activeMainTab = 'Leads';
      }
    }
    if (widget.initialSubTab != null && widget.initialSubTab!.isNotEmpty) {
      _selectedFollowupSubTab = widget.initialSubTab!;
    }
    if (widget.initialGroup != null && widget.initialGroup!.isNotEmpty) {
      _salesLeadGroupFilter = widget.initialGroup!;
    }
    _refreshFollowupsFuture();
    _requirementsStreamSub = RepositoryCoordinator().requirementsStream.listen((_) {
      if (mounted) {
        setState(() {
          _refreshFollowupsFuture();
        });
      }
    });
    _dashboardStreamSub = RepositoryCoordinator().dashboardStream.listen((_) {
      if (mounted) {
        setState(() {
          _refreshFollowupsFuture();
        });
      }
    });
    // Listen for real-time team match criteria threshold changes
    MatchCriteriaManager().addListener(_onCriteriaChanged);
    // Metadata load triggers the first fetch once listing types are available.
    // Avoid a duplicate empty fetch before metadata arrives.
    _loadMetadata();
    context.read<UsersBloc>().add(const FetchUsers());
    unawaited(_loadAssignUsers());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final uri = GoRouterState.of(context).uri;
        final action = uri.queryParameters['action'];
        if (action == 'add' && !_hasAutoOpenedAdd) {
          _hasAutoOpenedAdd = true;
          _showAddEditDialog();
        }
        final tabParam = uri.queryParameters['tab'];
        if (tabParam != null) {
          final tabLower = tabParam.toLowerCase();
          if (tabLower == 'follow-ups' || tabLower == 'followups') {
            if (_activeMainTab != 'Follow-ups') {
              setState(() {
                _activeMainTab = 'Follow-ups';
              });
              _refreshFollowupsFuture();
            }
          }
        }
        final subTabParam = uri.queryParameters['subTab'];
        if (subTabParam != null && subTabParam.isNotEmpty) {
          if (_selectedFollowupSubTab != subTabParam) {
            setState(() {
              _selectedFollowupSubTab = subTabParam;
            });
          }
        }
        final searchParam = uri.queryParameters['search'];
        if (searchParam != null && searchParam.isNotEmpty) {
          _searchController.text = searchParam;
          setState(() {});
        }
        final openId = uri.queryParameters['openId'];
        if (openId != null && openId.isNotEmpty) {
          RepositoryCoordinator().requirementLocal.getRequirement(openId).then((local) {
            if (local != null && mounted) {
              showCRMRequirementDrawer(context, local.toModel());
            }
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant RequirementsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab && widget.initialTab != null) {
      final tabLower = widget.initialTab!.toLowerCase();
      if (tabLower == 'follow-ups' || tabLower == 'followups') {
        setState(() {
          _activeMainTab = 'Follow-ups';
        });
        _refreshFollowupsFuture();
      } else if (tabLower == 'my won' || tabLower == 'won') {
        setState(() {
          _activeMainTab = 'My Won';
        });
        _triggerFetch();
      } else if (tabLower == 'rejected') {
        setState(() {
          _activeMainTab = 'Rejected';
        });
        _triggerFetch();
      } else if (tabLower == 'leads added by me' || tabLower == 'added') {
        setState(() {
          _activeMainTab = 'Leads Added by Me';
        });
        _triggerFetch();
      } else if (tabLower == 'leads') {
        setState(() {
          _activeMainTab = 'Leads';
        });
        _triggerFetch();
      }
    }
    if (widget.initialSubTab != oldWidget.initialSubTab &&
        widget.initialSubTab != null &&
        widget.initialSubTab!.isNotEmpty) {
      setState(() {
        _selectedFollowupSubTab = widget.initialSubTab!;
      });
    }
    if (widget.initialGroup != oldWidget.initialGroup &&
        widget.initialGroup != null &&
        widget.initialGroup!.isNotEmpty) {
      setState(() {
        _salesLeadGroupFilter = widget.initialGroup!;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final uri = GoRouterState.of(context).uri;
      final tabParam = uri.queryParameters['tab'];
      if (tabParam != null) {
        final tabLower = tabParam.toLowerCase();
        String? targetTab;
        if (tabLower == 'follow-ups' || tabLower == 'followups') {
          targetTab = 'Follow-ups';
        } else if (tabLower == 'my won' || tabLower == 'won') {
          targetTab = 'My Won';
        } else if (tabLower == 'rejected') {
          targetTab = 'Rejected';
        } else if (tabLower == 'leads added by me' || tabLower == 'added') {
          targetTab = 'Leads Added by Me';
        } else if (tabLower == 'leads') {
          targetTab = 'Leads';
        }
        if (targetTab != null && targetTab != _activeMainTab) {
          setState(() {
            _activeMainTab = targetTab!;
          });
          if (targetTab == 'Follow-ups') {
            _refreshFollowupsFuture();
          } else {
            _triggerFetch();
          }
        }
      }
      final subTabParam = uri.queryParameters['subTab'];
      if (subTabParam != null && subTabParam.isNotEmpty && subTabParam != _selectedFollowupSubTab) {
        setState(() {
          _selectedFollowupSubTab = subTabParam;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    MatchCriteriaManager().removeListener(_onCriteriaChanged);
    _removeNotesPopover();
    _requirementsStreamSub?.cancel();
    _dashboardStreamSub?.cancel();
    _searchController.dispose();
    _wonSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onCriteriaChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadPropertiesForMatches() async {
    try {
      final properties = await _propertiesRepository.getProperties();
      if (mounted) {
        setState(() {
          _propertiesForMatches = properties;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadMetadata() async {
    _loadPropertiesForMatches();
    try {
      final meta = await _propertiesRepository.getPropertyMetadata();
      if (!mounted) return;
      setState(() {
        _metadata = meta;
        _isLoadingMetadata = false;
      });
      _triggerFetch();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMetadata = false;
      });
      _triggerFetch();
    }
  }

  void _triggerFetch() {
    if (mounted) {
      setState(() {
        _refreshFollowupsFuture();
      });
    }
    String? listingTypeId;
    if (_metadata != null && _metadata!.listingTypes.isNotEmpty) {
      try {
        final matched = _metadata!.listingTypes.firstWhere(
          (lt) => lt.name.toLowerCase().contains(_activeListingTab == 'Rent' ? 'rent' : 'sale'),
        );
        listingTypeId = matched.id;
      } catch (_) {}
    }

    final selectedCat = _metadata?.categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => LookupItem(id: '', name: ''),
    );
    final catName = selectedCat?.name.toLowerCase() ?? '';
    final isPropertyTypeFilter = catName.contains('commercial') ||
        catName.contains('land') ||
        catName.contains('plot') ||
        catName.contains('industrial');

    String? configId;
    String? propTypeId;
    if (_activeMainTab != 'My Won' && _activeMainTab != 'Rejected') {
      if (_selectedConfigIds.length == 1) {
        if (isPropertyTypeFilter) {
          propTypeId = _selectedConfigIds.first;
        } else {
          configId = _selectedConfigIds.first;
        }
      }
    }

    // Fetch all pipeline statuses and perform status filtering client-side
    // so mapped statuses (such as Rejected, Suspended, Dead, etc.) filter accurately.
    final statusForFetch = 'All';

    context.read<RequirementsBloc>().add(
      FetchRequirementsEvent(
        search: null,
        configurationId: configId,
        propertyTypeId: propTypeId,
        status: statusForFetch,
        listingTypeId: listingTypeId,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedConfigIds.clear();
      _selectedCategoryId = null;
      _selectedStatus = "All";
      _selectedUserFilterId = "All";
      _selectedReadiness = "All";
      _selectedLeadDateFilter = LeadDateFilterPreset.allTime;
      _customStartDate = null;
      _customEndDate = null;
      _activeListingTab = "Rent";
      _currentPage = 1;
    });
    _triggerFetch();
  }

  void _showAddEditDialog([RequirementModel? req]) async {
    String? currentListingTypeId;
    if (_metadata != null && _metadata!.listingTypes.isNotEmpty) {
      try {
        final matched = _metadata!.listingTypes.firstWhere(
          (lt) => lt.name.toLowerCase().contains(_activeListingTab == 'Rent' ? 'rent' : 'sale'),
        );
        currentListingTypeId = matched.id;
      } catch (_) {}
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => AddEditRequirementScreen(
        requirement: req,
        initialListingTypeId: currentListingTypeId,
        initialListingTab: _activeListingTab,
        onSaved: () {
          _triggerFetch();
        },
      ),
    );
    if (mounted) {
      _triggerFetch();
    }
  }

  void _showDeleteConfirmDialog(RequirementModel req) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: CRMColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
          title: Text("Delete Requirement", style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text)),
          content: Text(
            "Are you sure you want to delete the requirement for ${req.clientName}?",
            style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
          ),
          actions: [
            CRMButton(
              label: "Cancel",
              variant: CRMButtonVariant.outline,
              onPressed: () => Navigator.pop(dialogContext),
            ),
            const SizedBox(width: CRMSpacing.xs),
            CRMButton(
              label: "Delete",
              variant: CRMButtonVariant.danger,
              onPressed: () async {
                if (req.status == 'Won' || req.status == 'Closed') {
                  await _revertWonPropertiesToAvailable(req);
                }
                if (dialogContext.mounted) {
                  context.read<RequirementsBloc>().add(DeleteRequirementEvent(req.id));
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showMatchesDrawer(RequirementModel req) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _CRMPropertyMatchesDrawer(
          requirement: req,
          properties: _propertiesForMatches,
        );
      },
    );
  }

  bool _isValidStatusTransition(String currentStatus, String newStatus) {
    return true;
  }

  Future<String?> _lookupPropertyStatusId(String needle) async {
    try {
      final meta = await PropertiesRepository().getPropertyMetadata();
      final n = needle.toLowerCase();
      for (final s in meta.statuses) {
        if (s.name.toLowerCase().contains(n)) return s.id;
      }
    } catch (e) {
      debugPrint('Error looking up property status "$needle": $e');
    }
    return null;
  }

  Future<void> _revertWonPropertiesToAvailable(RequirementModel req) async {
    try {
      final propertiesRepository = PropertiesRepository();
      final propertiesService = PropertiesService();
      final properties = await propertiesRepository.getProperties();
      final availableStatusId = await _lookupPropertyStatusId('available');
      if (availableStatusId == null) {
        debugPrint('Could not resolve Available property status from metadata.');
        return;
      }

      for (final p in properties) {
        final currentStatus = (p.propertyStatusName ?? '').toLowerCase();
        final isRentedOrSold = currentStatus.contains('rented') || currentStatus.contains('sold');

        if (isRentedOrSold) {
          final clientName = await PropertyDealClientStore.getClientName(p.id, property: p);
          if (clientName != null &&
              clientName.trim().toLowerCase() == req.clientName.trim().toLowerCase()) {
            try {
              await propertiesService.updateProperty(p.id, {
                'property_status_id': availableStatusId,
              });
              await PropertyDealClientStore.removeClientName(p.id);
            } catch (e) {
              debugPrint("Error reverting property status to available: $e");
            }
          }
        }
      }

      RepositoryCoordinator().refreshProperties();
    } catch (e) {
      debugPrint("Error in _revertWonPropertiesToAvailable: $e");
    }
  }

  void _changeStatus(RequirementModel req, String newStatus) async {
    _removeNotesPopover();
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    if (_isLeadTransferredAway(req, currentUser)) return;

    final bool isUnhandledAssigned = _isUnhandledAssignedLead(req, currentUser);
    if (!isUnhandledAssigned && newStatus == req.status && newStatus != 'Re-Followup') return;

    final Map<String, dynamic> nextCustomFields = Map<String, dynamic>.from(req.metaCustomFields ?? {});
    if (currentUser?.role == 'Sales') {
      nextCustomFields['handled_by_sales'] = true;
      nextCustomFields['telecaller_status'] ??= _getTelecallerStatusLabel(req);
      nextCustomFields['sales_handled_at'] ??= DateTime.now().toIso8601String();
    }
    if (newStatus.toLowerCase().startsWith('rejected')) {
      nextCustomFields['rejected_at'] = DateTime.now().toIso8601String();
    }
    final RequirementModel baseReq = req.copyWith(metaCustomFields: nextCustomFields);

    if (req.status == 'Won' && newStatus != 'Won') {
      await _revertWonPropertiesToAvailable(req);
    }

    if (!_isValidStatusTransition(req.status, newStatus)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Cannot skip pipeline stages from '${req.status}' to '$newStatus'."),
          backgroundColor: CRMColors.warning,
        ),
      );
      return;
    }

    if (newStatus == 'Follow-up' || newStatus == 'Re-Followup') {
      final bool isReFollowup = newStatus == 'Re-Followup' ||
          req.status == 'Follow-up' ||
          req.status == 'Re-Followup' ||
          req.nextFollowupDate != null;

      showDialog(
        context: context,
        builder: (dialogContext) => RequirementStepperDialog(
          requirement: baseReq,
          initialStep: 1,
          onSavedWithDate: (scheduledDate) {
            final now = DateTime.now();
            final todayDate = DateTime(now.year, now.month, now.day);
            final targetDay = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
            if (targetDay.isBefore(todayDate)) {
              _selectedFollowupSubTab = 'Due';
            } else if (targetDay.isAfter(todayDate)) {
              _selectedFollowupSubTab = 'Future';
            } else {
              _selectedFollowupSubTab = 'Today';
            }
            _reqFollowupDateFilter = scheduledDate;
            _currentFollowupPage = 1;
          },
          onSaved: () {
            if (isReFollowup) {
              NotificationCenter.addNotification(
                title: 'Re-Followup Scheduled',
                message: 'Re-Followup scheduled for ${req.clientName}. Notification reminder active.',
                type: 'refollowup',
              );
            }
            if (isReFollowup && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🔔 Re-Followup Scheduled! Notification reminder active for ${req.clientName}.',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: CRMColors.warning,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            _triggerFetch();
          },
        ),
      );
    } else if (newStatus == 'Site Visit') {
      showDialog(
        context: context,
        builder: (dialogContext) => RequirementStepperDialog(
          requirement: baseReq,
          initialStep: 1,
          updateStatusOnSave: true,
          isSiteVisit: true,
          onSaved: () {
            _triggerFetch();
          },
        ),
      );
    } else if (newStatus == 'Won') {
      showDialog(
        context: context,
        builder: (dialogContext) => RequirementWinPropertySelectionDialog(
          requirement: baseReq,
          onConfirmed: (List<PropertyModel> selectedProperties) async {
            context.read<RequirementsBloc>().add(
              PatchRequirementStatusEvent(baseReq.copyWith(status: 'Won')),
            );

            final selectedIds = selectedProperties.map((p) => p.id).toList();
            await PropertyDealClientStore.setWonRequirementProperties(req.id, selectedIds);

            final propertiesService = PropertiesService();
            final rentedStatusId = await _lookupPropertyStatusId('rented');
            final soldStatusId = await _lookupPropertyStatusId('sold');
            var propertyStatusUpdated = selectedProperties.isEmpty;

            for (final p in selectedProperties) {
              await PropertyDealClientStore.setClientName(p.id, req.clientName);

              final listingType = p.listingTypeName.toLowerCase();
              final isRent = listingType.contains('rent') ||
                  (LookupLocalRepository.getLookupNameSync(p.listingTypeId)?.toLowerCase().contains('rent') ?? false);

              final targetStatusId = isRent ? rentedStatusId : soldStatusId;
              if (targetStatusId == null) {
                propertyStatusUpdated = false;
                debugPrint('Could not resolve ${isRent ? 'Rented' : 'Sold'} property status from metadata.');
                continue;
              }

              try {
                await propertiesService.updateProperty(p.id, {
                  'property_status_id': targetStatusId,
                });
                propertyStatusUpdated = true;
              } catch (e) {
                propertyStatusUpdated = false;
                debugPrint("Error updating property status on win: $e");
              }
            }

            RepositoryCoordinator().refreshProperties();
            _triggerFetch();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    propertyStatusUpdated
                        ? 'Requirement marked as Won and property status updated!'
                        : 'Requirement marked as Won. Property status could not be updated.',
                  ),
                  backgroundColor: propertyStatusUpdated ? CRMColors.success : CRMColors.warning,
                ),
              );
            }
          },
        ),
      );
    } else {
      NotificationCenter.removeNotificationsForClient(req.clientName);
      final updatedReq = baseReq.copyWith(status: newStatus);
      _patchCachedRequirement(updatedReq);
      context.read<RequirementsBloc>().add(
        PatchRequirementStatusEvent(updatedReq),
      );
    }
  }

  void _patchCachedRequirement(RequirementModel updated) {
    RequirementLocalRepository.rememberMetaCustomFields(updated.id, updated.metaCustomFields);
    _localRequirementOverrides[updated.id] = updated;
    _cachedRequirements = _withLocalRequirementOverrides(
      _cachedRequirements.map((r) => r.id == updated.id ? updated : r).toList(),
    );
    if (mounted) {
      setState(() {
        _refreshFollowupsFuture();
      });
    }
  }

  List<RequirementModel> _withLocalRequirementOverrides(List<RequirementModel> source) {
    if (_localRequirementOverrides.isEmpty) return source;
    return source.map((r) {
      final local = _localRequirementOverrides[r.id];
      if (local == null) return r;
      final localHandled = local.metaCustomFields?['handled_by_sales'];
      final remoteHandled = r.metaCustomFields?['handled_by_sales'];
      final localReassign = local.metaCustomFields?['reassigned_by'];
      final remoteReassign = r.metaCustomFields?['reassigned_by'];
      if (local.status == r.status &&
          local.assignedTo == r.assignedTo &&
          localHandled == remoteHandled &&
          localReassign == remoteReassign) {
        _localRequirementOverrides.remove(r.id);
        return r;
      }
      return local;
    }).toList();
  }

  void _showAddAnotherRequirementDialog(RequirementModel existing) {
    final prefilled = RequirementModel(
      id: '',
      clientName: existing.clientName,
      clientMobile: existing.clientMobile,
      categoryId: '',
      categoryName: '',
      propertyTypeId: '',
      propertyTypeName: '',
      minBudget: 0,
      maxBudget: 0,
      areaIds: [],
      areaNames: [],
      status: 'New',
      createdAt: DateTime.now(),
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AddEditRequirementScreen(
        requirement: prefilled,
        initialListingTab: _activeListingTab,
        onSaved: () {
          _triggerFetch();
        },
      ),
    );
  }

  void _shareRequirement(RequirementModel req) {
    final String shareText = "Customer: ${req.clientName}\n"
        "Requirement Code: ${req.requirementCode}\n"
        "Specs: ${req.propertyTypeName} (${req.configurationName ?? 'N/A'})\n"
        "Budget: ${BudgetFormatter.format(req.minBudget)} - ${BudgetFormatter.format(req.maxBudget)}\n"
        "Target Areas: ${req.areaNames.join(', ')}";
        
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Requirement details copied to clipboard!"),
        backgroundColor: CRMColors.success,
      ),
    );
  }

  void _onRequirementEntered(RequirementModel req, {bool scrollToTop = true}) {
    if (!mounted) return;
    setState(() {
      _highlightedRequirementId = req.id;
    });
    if (scrollToTop && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          if (_highlightedRequirementId == req.id) {
            _highlightedRequirementId = null;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final reqBlocState = context.watch<RequirementsBloc>().state;
    if (reqBlocState is RequirementsLoaded) {
      _cachedRequirements = _withLocalRequirementOverrides(reqBlocState.requirements);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocListener<RequirementsBloc, RequirementsState>(
        listener: (context, state) {
          if (state is RequirementsLoaded) {
            _cachedRequirements = _withLocalRequirementOverrides(state.requirements);
          }
          if (state is RequirementsSuccess) {
            final msg = _activeMainTab == 'My Won'
                ? '${state.message} (My Won only shows Won items.)'
                : state.message;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: CRMColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            if (state.newlyAdded != null) {
              _onRequirementEntered(state.newlyAdded!, scrollToTop: true);
            } else if (state.requirement != null) {
              _onRequirementEntered(state.requirement!, scrollToTop: false);
            } else {
              _triggerFetch();
            }
          } else if (state is RequirementsLoaded && state.newlyAdded != null) {
            _onRequirementEntered(state.newlyAdded!, scrollToTop: true);
          } else if (state is RequirementsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error: ${state.message}"),
                backgroundColor: CRMColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? CRMSpacing.m : CRMSpacing.l,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              _buildPageHeader(),
              const SizedBox(height: CRMSpacing.m),

              // Main View Tabs (Requirements vs Follow-ups vs My Won)
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: CRMColors.cardBg,
                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                  border: Border.all(color: CRMColors.border),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMainViewTabButton('Leads'),
                      const SizedBox(width: 4),
                      _buildMainViewTabButton('Follow-ups'),
                      const SizedBox(width: 4),
                      _buildMainViewTabButton('My Won'),
                      const SizedBox(width: 4),
                      _buildMainViewTabButton('Rejected'),
                      if (currentUser != null &&
                          (currentUser.role == 'Admin' || currentUser.role == 'Super Admin')) ...[
                        const SizedBox(width: 4),
                        _buildMainViewTabButton('Leads Added by Me'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: CRMSpacing.l),

              if (_activeMainTab == 'Leads' || _activeMainTab == 'Leads Added by Me' || _activeMainTab == 'Rejected') ...[
                if (_activeMainTab == 'Leads' && currentUser != null && currentUser.role == 'Sales') ...[
                  _buildSalesLeadGroupSelector(currentUser, _cachedRequirements),
                  const SizedBox(height: CRMSpacing.m),
                ],

                // Filters & Search Card
                LayoutBuilder(
                  builder: (context, constraints) {
                    final bool isMobile = constraints.maxWidth < 600;
                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildMobileFilterButton(),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _isMobileFiltersExpanded
                                ? Padding(
                                    padding: const EdgeInsets.only(top: CRMSpacing.m),
                                    child: _buildSearchAndFiltersCard(_cachedRequirements),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      );
                    } else {
                      return _buildSearchAndFiltersCard(_cachedRequirements);
                    }
                  },
                ),
                const SizedBox(height: CRMSpacing.l),

                // Data Table
                _buildRequirementsTable(),
              ] else if (_activeMainTab == 'My Won') ...[
                _buildMyWonFiltersAndTable(),
              ] else ...[
                // Follow-ups View
                _buildFollowupsView(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    final listingToggle = Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 44,
        width: 240,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: CRMColors.backgroundOf(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: CRMColors.borderOf(context).withValues(alpha: 0.6), width: 1.0),
        ),
        child: Row(
          children: [
            Expanded(child: _buildListingTabButton('Rent')),
            const SizedBox(width: 4),
            Expanded(child: _buildListingTabButton('Re-Sale')),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CRMPageHeader(
          title: 'Leads',
          trailing: CRMButton(
            label: 'Add Lead',
            prefixIcon: Icons.add_rounded,
            height: 40,
            onPressed: () => _showAddEditDialog(),
          ),
        ),
        const SizedBox(height: CRMSpacing.s),
        listingToggle,
      ],
    );
  }

  Widget _buildMobileFilterButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isMobileFiltersExpanded = !_isMobileFiltersExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 10),
        decoration: BoxDecoration(
          color: _isMobileFiltersExpanded ? CRMColors.primaryOf(context) : CRMColors.cardBgOf(context),
          borderRadius: BorderRadius.circular(CRMBorderRadius.button),
          border: Border.all(
            color: _isMobileFiltersExpanded ? CRMColors.primaryOf(context) : CRMColors.borderOf(context),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 18,
              color: _isMobileFiltersExpanded ? Colors.white : CRMColors.primaryOf(context),
            ),
            const SizedBox(width: CRMSpacing.s),
            Text(
              _isMobileFiltersExpanded ? "Hide Filters" : "Show Search Filters",
              style: CRMTypography.bodyMedium.copyWith(
                color: _isMobileFiltersExpanded ? Colors.white : CRMColors.textOf(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFiltersCard([List<RequirementModel> baseList = const []]) {
    List<RequirementModel> allReqs = baseList;
    if (allReqs.isEmpty) {
      final blocState = context.read<RequirementsBloc>().state;
      if (blocState is RequirementsLoaded) {
        allReqs = blocState.requirements;
      }
    }

    final authState = context.read<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final bool showUnassign = _canSeeUnassignStatusFilter(currentUser);
    final statusItems = _statusFilterItems(showUnassign: showUnassign);
    final String statusFilterValue =
        (!showUnassign && _selectedStatus == 'Unassign') ? 'All' : _selectedStatus;

    final bool isMobile = MediaQuery.of(context).size.width < 600;
    String configDropdownLabel = 'BHK';
    final selectedCat = _metadata?.categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => LookupItem(id: '', name: ''),
    );
    final catName = selectedCat?.name.toLowerCase() ?? '';
    List<LookupItem> specLookupItems = [];

    if (catName.contains('commercial')) {
      configDropdownLabel = 'Property Type';
      
      var filtered = _metadata?.types.where((t) => t.categoryId == _selectedCategoryId).toList() ?? [];
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.types.where((t) {
          final n = t.name.toLowerCase();
          return n.contains('office') || n.contains('shop') || n.contains('showroom') || n.contains('commercial');
        }).toList();
      }
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.types;
      }
      specLookupItems = filtered;
    } else if (catName.contains('land') || catName.contains('plot')) {
      configDropdownLabel = 'Property Type';
      
      var filtered = _metadata?.types.where((t) => t.categoryId == _selectedCategoryId).toList() ?? [];
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.types.where((t) {
          final n = t.name.toLowerCase();
          return n.contains('plot') || n.contains('land');
        }).toList();
      }
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.types;
      }
      specLookupItems = filtered;
    } else if (catName.contains('industrial')) {
      configDropdownLabel = 'Property Type';
      
      var filtered = _metadata?.types.where((t) => t.categoryId == _selectedCategoryId).toList() ?? [];
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.types.where((t) {
          final n = t.name.toLowerCase();
          return n.contains('warehouse') || n.contains('shed') || n.contains('industrial');
        }).toList();
      }
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.types;
      }
      specLookupItems = filtered;
    } else {
      configDropdownLabel = 'BHK';
      
      var filtered = _metadata?.configurations.where((c) => _selectedCategoryId == null || c.categoryId == _selectedCategoryId).toList() ?? [];
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.configurations;
      }
      specLookupItems = filtered;
    }

    return CRMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: CRMTypography.body.copyWith(color: CRMColors.text),
                  decoration: InputDecoration(
                    hintText: 'Search by client name, mobile, specs, remarks...',
                    hintStyle: CRMTypography.body.copyWith(color: CRMColors.textMuted),
                    prefixIcon: Icon(Icons.search_rounded, color: CRMColors.textMuted),
                    filled: true,
                    fillColor: CRMColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      borderSide: BorderSide(color: CRMColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      borderSide: BorderSide(color: CRMColors.border),
                    ),
                  ),
                  onChanged: (val) {
                    AuditTelemetryService.instance.trackSearch(
                      query: val,
                      module: 'Leads',
                    );
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              CRMButton(
                label: "Search",
                onPressed: () {
                  AuditTelemetryService.instance.trackButtonClick(
                    buttonId: 'btn_search_leads',
                    buttonLabel: 'Search Leads',
                    page: '/requirements',
                    extra: {'query': _searchController.text.trim()},
                  );
                  _triggerFetch();
                },
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDropdownFilter<String?>(
                      label: 'Category',
                      value: _selectedCategoryId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text("All Categories")),
                        ...?_metadata?.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      ],
                      isMobile: isMobile,
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                          _selectedConfigIds.clear();
                        });
                        _triggerFetch();
                      },
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    CRMMultiSelectDropdown(
                      label: configDropdownLabel,
                      selectedIds: _selectedConfigIds,
                      items: specLookupItems,
                      onChanged: (vals) {
                        setState(() {});
                        _triggerFetch();
                      },
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    _buildDropdownFilter(
                      label: 'Status',
                      value: statusFilterValue,
                      items: statusItems,
                      isMobile: isMobile,
                      onChanged: (val) {
                        setState(() => _selectedStatus = val ?? "All");
                        _triggerFetch();
                      },
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    _buildUserFilterDropdown(isMobile: isMobile),
                    const SizedBox(height: CRMSpacing.s),
                    CRMButton(
                      label: "Clear Filters",
                      variant: CRMButtonVariant.outline,
                      onPressed: _clearFilters,
                    ),
                  ],
                )
              : Wrap(
                  spacing: CRMSpacing.m,
                  runSpacing: CRMSpacing.s,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildDropdownFilter<String?>(
                      label: 'Category',
                      value: _selectedCategoryId,
                      items: [
                        const DropdownMenuItem(value: null, child: Text("All Categories")),
                        ...?_metadata?.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      ],
                      isMobile: isMobile,
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                          _selectedConfigIds.clear();
                        });
                        _triggerFetch();
                      },
                    ),
                    SizedBox(
                      width: isMobile ? double.infinity : 200,
                      child: CRMMultiSelectDropdown(
                        label: configDropdownLabel,
                        selectedIds: _selectedConfigIds,
                        items: specLookupItems,
                        onChanged: (vals) {
                          setState(() {});
                          _triggerFetch();
                        },
                      ),
                    ),
                    _buildDropdownFilter(
                      label: 'Status',
                      value: statusFilterValue,
                      items: statusItems,
                      isMobile: isMobile,
                      onChanged: (val) {
                        setState(() => _selectedStatus = val ?? "All");
                        _triggerFetch();
                      },
                    ),
                    _buildUserFilterDropdown(isMobile: isMobile),
                    CRMButton(
                      label: "Clear Filters",
                      variant: CRMButtonVariant.outline,
                      onPressed: _clearFilters,
                    ),
                  ],
                ),
          const SizedBox(height: CRMSpacing.m),
          const Divider(height: 1),
          const SizedBox(height: CRMSpacing.m),
          _buildDateFilterBar(context, allReqs),
        ],
      ),
    );
  }

  bool _matchesLeadDateFilter(RequirementModel req) {
    return _matchesLeadDateFilterWithPreset(req, _selectedLeadDateFilter);
  }

  bool _matchesLeadDateFilterWithPreset(RequirementModel req, LeadDateFilterPreset preset) {
    final createdAt = _dateForLeadFilter(req);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (preset) {
      case LeadDateFilterPreset.today:
        return !createdAt.isBefore(todayStart) && !createdAt.isAfter(todayEnd);
      case LeadDateFilterPreset.yesterday:
        final yestStart = todayStart.subtract(const Duration(days: 1));
        final yestEnd = DateTime(yestStart.year, yestStart.month, yestStart.day, 23, 59, 59);
        return !createdAt.isBefore(yestStart) && !createdAt.isAfter(yestEnd);
      case LeadDateFilterPreset.last7Days:
        final start = todayStart.subtract(const Duration(days: 6));
        return !createdAt.isBefore(start) && !createdAt.isAfter(todayEnd);
      case LeadDateFilterPreset.thisMonth:
        final monthStart = DateTime(now.year, now.month, 1);
        return !createdAt.isBefore(monthStart) && !createdAt.isAfter(todayEnd);
      case LeadDateFilterPreset.customRange:
        if (_customStartDate != null && _customEndDate != null) {
          final start = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
          final end = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day, 23, 59, 59);
          return !createdAt.isBefore(start) && !createdAt.isAfter(end);
        }
        return true;
      case LeadDateFilterPreset.allTime:
        return true;
    }
  }

  users_model.UserModel? _selectedUserForDateCounts() {
    if (_selectedUserFilterId == 'All' || _selectedUserFilterId.isEmpty) return null;
    try {
      final usersState = context.read<UsersBloc>().state;
      if (usersState is UsersLoaded) {
        return usersState.users.firstWhereOrNull((u) => u.id == _selectedUserFilterId);
      }
    } catch (_) {}
    return null;
  }

  bool _isRequirementVisibleToUser(RequirementModel req, UserModel? currentUser) {
    if (currentUser == null) return false;
    final role = currentUser.role;

    if (role == 'Super Admin') return true;

    if (role == 'Sales') {
      if (_isLeadTransferredAway(req, currentUser)) return false;
      return _salesCanViewRequirement(req, currentUser);
    }

    if (role == 'Admin') {
      if (req.adminId != null && req.adminId!.isNotEmpty && req.adminId == currentUser.id) return true;
      if (req.createdBy == currentUser.id) return true;
      if (req.organizationId != null && currentUser.organizationId != null && req.organizationId == currentUser.organizationId) return true;
      try {
        final usersState = context.read<UsersBloc>().state;
        if (usersState is UsersLoaded) {
          final isManagedUserLead = usersState.users.any((u) =>
              (u.adminId == currentUser.id || u.id == currentUser.id) &&
              TeamUserVisibility.requirementBelongsToUser(req, u));
          if (isManagedUserLead) return true;
        }
      } catch (_) {}
      return true;
    }

    if (role == 'Telecaller') {
      if (currentUser.adminId != null && currentUser.adminId!.isNotEmpty && req.adminId == currentUser.adminId) return true;
      if (req.createdBy == currentUser.id) return true;
      return true;
    }

    return true;
  }

  int _getLeadDateFilterCount(List<RequirementModel> baseList, LeadDateFilterPreset preset) {
    final selectedUser = _selectedUserForDateCounts();
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;

    return baseList.where((req) {
      if (!_isRequirementVisibleToUser(req, currentUser)) return false;

      final matchesListingType = getListingTypeLabel(req) == _activeListingTab;
      if (!matchesListingType) return false;

      if (_activeMainTab == 'Rejected') {
        if (!_isLeadRejected(req)) return false;
      } else if (_activeMainTab == 'Leads Added by Me') {
        if (currentUser == null || !_isUserCreator(req, currentUser)) return false;
      } else if (_activeMainTab == 'My Won') {
        if (!_isLeadWon(req)) return false;
      } else {
        if (_isLeadRejected(req)) return false;
        if (_selectedStatus != 'Won' && _isLeadWon(req)) return false;
        if (currentUser != null && currentUser.role == 'Sales') {
          if (_salesLeadGroupFilter == 'assigned' && (!_isUserAssignee(req, currentUser) || _isUserCreator(req, currentUser))) {
            return false;
          }
          if (_salesLeadGroupFilter == 'added' && !_isUserCreator(req, currentUser)) {
            return false;
          }
        }
      }

      if (selectedUser != null &&
          !(_activeMainTab == 'Rejected' && _canViewAllRejectedLeads(currentUser)) &&
          !TeamUserVisibility.requirementBelongsToUser(req, selectedUser)) {
        return false;
      }

      if (_selectedCategoryId != null && req.categoryId != _selectedCategoryId) {
        return false;
      }

      if (_selectedConfigIds.isNotEmpty) {
        final matchesSpec = _selectedConfigIds.contains(req.configurationId) ||
            _selectedConfigIds.contains(req.propertyTypeId) ||
            req.configurationIds.any((id) => _selectedConfigIds.contains(id)) ||
            req.propertyTypeIds.any((id) => _selectedConfigIds.contains(id));
        if (!matchesSpec) return false;
      }

      if (_selectedStatus != 'All') {
        if (_selectedStatus == 'Unassign') {
          if (!_isLeadUnassigned(req)) return false;
        } else {
          final isUnhandledAssigned = _isUnhandledAssignedLead(req, currentUser);
          String mappedStatus = _isLeadRejected(req)
              ? getEffectiveStatus(req)
              : ((req.status == 'Assigned')
                  ? 'Assigned'
                  : (isUnhandledAssigned ? 'Not Started' : getEffectiveStatus(req)));
          if (mappedStatus == 'Active' || mappedStatus == 'Live') mappedStatus = 'Interested';
          if (mappedStatus == 'Closed' || mappedStatus == 'Won') mappedStatus = 'Won';
          if (mappedStatus == 'Suspended' || mappedStatus == 'Dead') mappedStatus = 'Not Interested';
          if (mappedStatus.startsWith('Rejected') || mappedStatus == 'Bin') mappedStatus = 'Rejected';

          if (mappedStatus != _selectedStatus && req.status != _selectedStatus) {
            final matchesCallAttempted = _selectedStatus == 'Call Attempted' &&
                (req.status.startsWith('Call Attempted') || req.status.startsWith('Call attempted'));
            final matchesRejected = _selectedStatus == 'Rejected' && req.status.startsWith('Rejected');
            if (!matchesCallAttempted && !matchesRejected) return false;
          }
        }
      }

      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final clientName = req.clientName.toLowerCase();
        final clientMobile = req.clientMobile.toLowerCase();
        final specs = '${req.propertyTypeName} ${req.configurationName ?? ""} ${req.listingTypeName ?? ""} ${req.categoryName ?? ""}'.toLowerCase();
        final remarks = (req.remarks ?? '').toLowerCase();
        final areas = req.areaNames.join(' ').toLowerCase();

        bool matchesSalesman = false;
        if (currentUser != null && (currentUser.role == 'Admin' || currentUser.role == 'Super Admin' || currentUser.role == 'Telecaller')) {
          final creator = (req.creatorName ?? '').toLowerCase();
          final assignee = (req.assigneeName ?? '').toLowerCase();
          matchesSalesman = creator.contains(query) || assignee.contains(query);
        }

        final matchesSearch = clientName.contains(query) ||
            clientMobile.contains(query) ||
            specs.contains(query) ||
            remarks.contains(query) ||
            areas.contains(query) ||
            matchesSalesman;
        if (!matchesSearch) return false;
      }

      return _matchesLeadDateFilterWithPreset(req, preset);
    }).length;
  }

  Future<void> _pickCustomDateRange(BuildContext context) async {
    final initialRange = DateTimeRange(
      start: _customStartDate ?? DateTime.now().subtract(const Duration(days: 7)),
      end: _customEndDate ?? DateTime.now(),
    );
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) {
        final isDark = ThemeManager().isDarkMode;
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: CRMColors.primaryOf(ctx),
                    onPrimary: Colors.white,
                    surface: const Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : ColorScheme.light(
                    primary: CRMColors.primaryOf(ctx),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedLeadDateFilter = LeadDateFilterPreset.customRange;
        _currentPage = 1;
      });
    }
  }

  Widget _buildDateFilterBar(BuildContext context, List<RequirementModel> baseList) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primaryOf(context);

    final todayCount = _getLeadDateFilterCount(baseList, LeadDateFilterPreset.today);
    final yesterdayCount = _getLeadDateFilterCount(baseList, LeadDateFilterPreset.yesterday);
    final last7Count = _getLeadDateFilterCount(baseList, LeadDateFilterPreset.last7Days);
    final thisMonthCount = _getLeadDateFilterCount(baseList, LeadDateFilterPreset.thisMonth);
    final allTimeCount = _getLeadDateFilterCount(baseList, LeadDateFilterPreset.allTime);

    final items = [
      (LeadDateFilterPreset.today, 'Today', todayCount, Icons.calendar_today_rounded),
      (LeadDateFilterPreset.yesterday, 'Yesterday', yesterdayCount, Icons.history_rounded),
      (LeadDateFilterPreset.last7Days, 'Last 7 Days', last7Count, Icons.date_range_rounded),
      (LeadDateFilterPreset.thisMonth, 'This Month', thisMonthCount, Icons.calendar_month_rounded),
      (LeadDateFilterPreset.customRange, 'Custom Range', null, Icons.event_repeat_rounded),
      (LeadDateFilterPreset.allTime, 'All Time', allTimeCount, Icons.all_inclusive_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_month_rounded, size: 16, color: primaryColor),
            const SizedBox(width: 8),
            Text(
              'DATE FILTER:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 6),
            if (_selectedLeadDateFilter == LeadDateFilterPreset.today)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'DEFAULT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((item) {
              final filter = item.$1;
              final label = item.$2;
              final count = item.$3;
              final icon = item.$4;
              final isSelected = _selectedLeadDateFilter == filter;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    if (filter == LeadDateFilterPreset.customRange) {
                      _pickCustomDateRange(context);
                    } else {
                      setState(() {
                        _selectedLeadDateFilter = filter;
                        _currentPage = 1;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor
                          : (isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                          ),
                        ),
                        if (count != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildListingTabButton(String label) {
    final isSelected = _activeListingTab == label;
    final accent =
        label == 'Rent' ? CRMColors.rentAccent : CRMColors.resaleAccent;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeListingTab = label;
          _currentPage = 1;
        });
        _triggerFetch();
      },
      child: AnimatedContainer(
        duration: CRMMotion.fast,
        curve: CRMMotion.easeInOut,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: CRMTypography.bodyMedium.copyWith(
            color: isSelected
                ? CRMColors.onAtmosphereAccent(label == 'Rent')
                : CRMColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildUserFilterDropdown({required bool isMobile}) {
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    if (currentUser == null || !TeamUserVisibility.canUseFilter(currentUser.role)) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        final users = state is UsersLoaded
            ? TeamUserVisibility.visibleUsers(
                users: state.users,
                currentRole: currentUser.role,
                currentUserId: currentUser.id,
              )
            : <users_model.UserModel>[];
        final items = <DropdownMenuItem<String>>[
          const DropdownMenuItem(value: 'All', child: Text('All Users')),
          ...users.map(
            (u) => DropdownMenuItem(
              value: u.id,
              child: Text(
                '${u.fullName} (${u.roleName})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ];
        final value = items.any((i) => i.value == _selectedUserFilterId)
            ? _selectedUserFilterId
            : 'All';

        return _buildDropdownFilter<String>(
          label: 'User',
          value: value,
          items: items,
          isMobile: isMobile,
          onChanged: (val) {
            setState(() {
              _selectedUserFilterId = val ?? 'All';
              _currentPage = 1;
            });
            _triggerFetch();
          },
        );
      },
    );
  }

  Widget _buildDropdownFilter<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool isMobile = false,
    bool highlight = false,
  }) {
    final bool hasValue = value == null || items.any((item) => item.value == value);
    final T? safeValue = hasValue ? value : null;
    final Color borderColor = highlight
        ? CRMColors.primaryOf(context)
        : CRMColors.borderOf(context).withOpacity(0.6);
    final Color fillColor = highlight
        ? CRMColors.primaryOf(context).withValues(alpha: 0.10)
        : CRMColors.backgroundOf(context);

    return SizedBox(
      width: isMobile ? double.infinity : 200,
      height: isMobile ? 54 : 48,
      child: DropdownButtonFormField<T>(
        value: safeValue,
        isExpanded: true,
        dropdownColor: CRMColors.cardBgOf(context),
        style: CRMTypography.body.copyWith(
          color: highlight ? CRMColors.primaryOf(context) : CRMColors.textOf(context),
          fontWeight: highlight ? FontWeight.w700 : FontWeight.normal,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: CRMTypography.caption.copyWith(
            color: highlight ? CRMColors.primaryOf(context) : CRMColors.textSecondaryOf(context),
            fontWeight: highlight ? FontWeight.w700 : FontWeight.normal,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: isMobile ? 12 : 8),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            borderSide: BorderSide(color: borderColor, width: highlight ? 1.5 : 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            borderSide: BorderSide(color: borderColor, width: highlight ? 1.5 : 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            borderSide: BorderSide(color: CRMColors.primaryOf(context), width: 1.5),
          ),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  bool _canSeeUnassignStatusFilter(UserModel? user) {
    if (user == null) return false;
    final role = user.role;
    return role == 'Admin' || role == 'Super Admin' || role == 'Telecaller';
  }

  bool _canViewAllRejectedLeads(UserModel? user) {
    if (user == null) return false;
    final role = user.role;
    return role == 'Admin' || role == 'Super Admin' || role == 'Telecaller';
  }

  bool _isLeadUnassigned(RequirementModel req) {
    try {
      final usersState = context.read<UsersBloc>().state;
      final blocUsers = usersState is UsersLoaded ? usersState.users : <users_model.UserModel>[];
      final currentAssignedTo = _currentAssignedUserId(req, _mergedAssignUsers(blocUsers));
      if (currentAssignedTo == null || currentAssignedTo.trim().isEmpty) return true;
      return currentAssignedTo.trim().toLowerCase() == 'unassigned';
    } catch (_) {
      final assigned = (req.assignedTo ?? '').trim();
      if (assigned.isNotEmpty && assigned.toLowerCase() != 'unassigned') return false;
      final name = (req.assigneeName ?? '').trim();
      if (name.isNotEmpty && name.toLowerCase() != 'unassigned') return false;
      return true;
    }
  }

  List<DropdownMenuItem<String>> _statusFilterItems({required bool showUnassign}) {
    final bool unassignActive = _selectedStatus == 'Unassign';
    return [
      const DropdownMenuItem(value: 'All', child: Text('All')),
      if (showUnassign)
        DropdownMenuItem(
          value: 'Unassign',
          child: Text(
            'Unassign',
            style: unassignActive
                ? TextStyle(
                    fontWeight: FontWeight.w800,
                    color: CRMColors.primaryOf(context),
                  )
                : null,
          ),
        ),
      const DropdownMenuItem(value: 'New', child: Text('New')),
      const DropdownMenuItem(value: 'Assigned', child: Text('Assigned')),
      const DropdownMenuItem(value: 'Not Started', child: Text('Not Started')),
      const DropdownMenuItem(value: 'Call Attempted', child: Text('Call Attempted')),
      const DropdownMenuItem(value: 'Follow-up', child: Text('Follow-up')),
      const DropdownMenuItem(value: 'Interested', child: Text('Interested')),
      const DropdownMenuItem(value: 'Site Visit', child: Text('Site Visit Sche.')),
      const DropdownMenuItem(value: 'Site Visit Done', child: Text('Site Visit Done')),
      const DropdownMenuItem(value: 'Negotiation', child: Text('Negotiation')),
      const DropdownMenuItem(value: 'Won', child: Text('Won')),
    ];
  }

  bool _looksLikeUserId(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
  }

  String? _liveUserName(String? idOrName) {
    if (idOrName == null || idOrName.trim().isEmpty) return null;
    final needle = idOrName.trim();
    try {
      final usersState = context.read<UsersBloc>().state;
      final blocUsers = usersState is UsersLoaded ? usersState.users : <users_model.UserModel>[];
      final match = _mergedAssignUsers(blocUsers).firstWhereOrNull(
        (u) =>
            u.id == needle ||
            u.fullName.trim().toLowerCase() == needle.toLowerCase(),
      );
      if (match != null && match.fullName.trim().isNotEmpty) {
        return match.fullName.trim();
      }
    } catch (_) {}
    return null;
  }

  String _getAddedByName(RequirementModel req) {
    final fromCreatorId = _liveUserName(req.createdBy);
    if (fromCreatorId != null) return fromCreatorId;

    final rawName = req.creatorName?.trim();
    if (rawName != null && rawName.isNotEmpty && rawName != 'System') {
      final fromCreatorName = _liveUserName(rawName);
      if (fromCreatorName != null) return fromCreatorName;
      if (!_looksLikeUserId(rawName)) return rawName;
    }

    return 'Propkart Admin';
  }

  String? _getReassignedByName(RequirementModel req) {
    final name = req.metaCustomFields?['reassigned_by_name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;
    return null;
  }

  String _getAddedByColumnName(RequirementModel req) {
    return _getReassignedByName(req) ?? _getAddedByName(req);
  }

  String _getAddedByDisplayLine(RequirementModel req) {
    final reassigned = _getReassignedByName(req);
    if (reassigned != null) return 'Re-Assigned By: $reassigned';
    return 'Added by: ${_getAddedByName(req)}';
  }

  bool _canInitiallyAssignLead(UserModel? user) {
    return user != null &&
        (user.role == 'Super Admin' || user.role == 'Admin' || user.role == 'Telecaller');
  }

  bool _canSalesReassignLead(UserModel? user) {
    return user != null && user.role == 'Sales';
  }

  void _submitLeadAssignment(RequirementModel req, String? newSalesmanId, String? newSalesmanName) {
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final Map<String, dynamic> nextCustomFields = Map<String, dynamic>.from(req.metaCustomFields ?? {});
    if (currentUser?.role == 'Sales') {
      nextCustomFields['original_added_by_name'] ??= _getAddedByName(req);
      nextCustomFields['original_added_by'] ??= req.createdBy;
      nextCustomFields['reassigned_by'] = currentUser!.id;
      nextCustomFields['reassigned_by_name'] = currentUser.fullName;
      nextCustomFields['reassigned_at'] = DateTime.now().toIso8601String();
    }
    final updated = req.copyWith(
      assignedTo: newSalesmanId ?? '',
      assigneeName: newSalesmanName ?? '',
      metaCustomFields: nextCustomFields,
    );
    _patchCachedRequirement(updated);
    context.read<RequirementsBloc>().add(UpdateRequirementEvent(updated));
  }

  String _getSalesmanName(RequirementModel req, UserModel? currentUser) {
    if (req.assigneeName != null && req.assigneeName!.trim().isNotEmpty) {
      return req.assigneeName!.trim();
    }
    if (req.assignedTo != null && req.assignedTo!.trim().isNotEmpty) {
      final fromAssignId = _liveUserName(req.assignedTo);
      if (fromAssignId != null) return fromAssignId;
      if (req.assignedTo!.trim() != 'Unassigned' && !_looksLikeUserId(req.assignedTo!)) {
        return req.assignedTo!.trim();
      }
    }
    if (req.creatorName != null && req.creatorName!.trim().isNotEmpty) {
      return req.creatorName!.trim();
    }
    if (currentUser != null && req.adminId == currentUser.id) {
      return currentUser.fullName;
    }
    try {
      final usersState = context.read<UsersBloc>().state;
      if (usersState is UsersLoaded) {
        final match = usersState.users.firstWhere(
          (u) => u.id == req.adminId,
          orElse: () => const users_model.UserModel(id: '', roleId: '', roleName: '', fullName: '', email: '', isActive: false),
        );
        if (match.fullName.isNotEmpty) {
          return match.fullName;
        }
      }
    } catch (_) {}
    return 'Unassigned';
  }

  Widget _buildCustomTooltip({
    required String message,
    required Widget child,
    required bool isRent,
    double maxWidth = 340.0,
  }) {
    return Tooltip(
      richMessage: WidgetSpan(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: CRMColors.isDark ? const Color(0xFF24211F) : const Color(0xFF292725),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isRent ? CRMColors.rentAccent : CRMColors.primary).withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSpecsConfigCell(RequirementModel req) {
    final configStr = (req.configurationName != null && req.configurationName!.isNotEmpty)
        ? req.configurationName!
        : '-';
    final specsText = '${req.propertyTypeName} ($configStr)';
    final listingLabel = getListingTypeLabel(req);
    final isRent = listingLabel == 'Rent';

    final tooltipMessage = 'Property Type(s): ${req.propertyTypeName}\nConfiguration(s): $configStr\nListing Type: $listingLabel';

    return _buildCustomTooltip(
      message: tooltipMessage,
      isRent: isRent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 135),
            child: Text(
              specsText,
              style: CRMTypography.body.copyWith(color: CRMColors.text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.xxs, vertical: 2),
            decoration: BoxDecoration(
              color: (isRent ? CRMColors.rentAccent : CRMColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
            ),
            child: Text(
              listingLabel,
              style: CRMTypography.captionBold.copyWith(
                fontSize: 10,
                color: isRent ? CRMColors.rentAccent : CRMColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetAreasCell(RequirementModel req) {
    final areasText = req.areaNames.isNotEmpty ? req.areaNames.join(', ') : 'Any Area';
    final listingLabel = getListingTypeLabel(req);
    final isRent = listingLabel == 'Rent';

    final tooltipMessage = 'Target Area(s):\n$areasText';

    return SizedBox(
      width: 125,
      child: _buildCustomTooltip(
        message: tooltipMessage,
        isRent: isRent,
        child: Text(
          areasText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
        ),
      ),
    );
  }


  static bool _isRequirementPropertyMatch(PropertyModel p, RequirementModel req) {
    final result = PropertyRequirementMatcher.match(p, req);
    return result.matchPercentage >= MatchCriteriaManager().threshold;
  }

  static Future<bool> _isRequirementPropertyMatchAsync(PropertyModel p, RequirementModel req) async {
    final isWonReq = req.status.toLowerCase() == 'won' || req.status.toLowerCase() == 'closed';

    if (isWonReq) {
      final wonPropertyIds = await PropertyDealClientStore.getWonPropertyIds(req.id);
      if (wonPropertyIds.isNotEmpty) {
        return wonPropertyIds.contains(p.id);
      }

      final clientName = await PropertyDealClientStore.getClientName(p.id, property: p);
      if (clientName != null && clientName.trim().toLowerCase() == req.clientName.trim().toLowerCase()) {
        return true;
      }
      return false;
    }

    return _isRequirementPropertyMatch(p, req);
  }

  Future<void> _loadAssignUsers() async {
    if (_assignUsersLoading || _assignUsers.isNotEmpty) return;
    _assignUsersLoading = true;
    List<users_model.UserModel> users = [];
    final role = (RoleGuard.currentUser?.role ?? '').toLowerCase();
    if (role != 'telecaller') {
      try {
        users = await _usersRepository.getUsers();
      } catch (_) {}
    }
    if (users.isEmpty) {
      try {
        final team = await TeamMessagesService().getTeamUsers();
        users = team
            .map((u) => users_model.UserModel(
                  id: u.id,
                  roleId: '',
                  roleName: u.role,
                  fullName: u.name,
                  email: u.email,
                  isActive: true,
                  adminId: u.adminId,
                ))
            .where((u) => u.id.isNotEmpty)
            .toList();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _assignUsers = users.where((u) => u.isActive).toList();
      _assignUsersLoading = false;
    });
  }

  List<users_model.UserModel> _mergedAssignUsers(List<users_model.UserModel> blocUsers) {
    final byId = <String, users_model.UserModel>{};
    for (final u in blocUsers) {
      if (u.id.isNotEmpty) byId[u.id] = u;
    }
    for (final u in _assignUsers) {
      if (u.id.isNotEmpty) byId.putIfAbsent(u.id, () => u);
    }
    return byId.values.toList();
  }

  String? _currentAssignedUserId(RequirementModel req, List<users_model.UserModel> users) {
    if (req.assignedTo != null && req.assignedTo!.trim().isNotEmpty) {
      return req.assignedTo!.trim();
    }
    if (req.assigneeName != null && req.assigneeName!.trim().isNotEmpty) {
      final needle = req.assigneeName!.trim().toLowerCase();
      final match = users.firstWhereOrNull((u) => u.fullName.trim().toLowerCase() == needle);
      if (match != null) return match.id;
    }
    if (req.createdBy != null && req.createdBy!.isNotEmpty) {
      final creatorUser = users.firstWhereOrNull((u) => u.id == req.createdBy);
      if (creatorUser != null) {
        final role = creatorUser.roleName.toLowerCase();
        final isCreatorAdminOrTelecaller = role == 'admin' || role == 'super admin' || role == 'telecaller';
        if (!isCreatorAdminOrTelecaller) return req.createdBy;
      } else if (req.creatorName != null && req.creatorName!.isNotEmpty) {
        final creatorMatch = users.firstWhereOrNull(
          (u) => u.fullName.toLowerCase() == req.creatorName!.toLowerCase(),
        );
        if (creatorMatch != null) {
          final role = creatorMatch.roleName.toLowerCase();
          final isCreatorAdminOrTelecaller = role == 'admin' || role == 'super admin' || role == 'telecaller';
          if (!isCreatorAdminOrTelecaller) return creatorMatch.id;
        }
      }
    }
    return null;
  }

  bool _isSalesPersonRole(String roleName) {
    final r = roleName.toLowerCase().trim();
    if (r.contains('admin') || r.contains('telecaller') || r.contains('super')) {
      return false;
    }
    return r.contains('sales') ||
        r.contains('executive') ||
        r.contains('agent') ||
        r.contains('advisor');
  }

  List<users_model.UserModel> _salesmenForLeadAssign({
    required RequirementModel req,
    required UserModel? currentUser,
    required List<users_model.UserModel> users,
    required String? currentAssignedTo,
  }) {
    final curRole = (currentUser?.role ?? '').toLowerCase();
    final isTelecaller = curRole == 'telecaller';

    var salesmen = users.where((u) {
      if (currentAssignedTo != null && u.id == currentAssignedTo) return true;

      if (isTelecaller) {
        return _isSalesPersonRole(u.roleName);
      }

      final role = u.roleName.toLowerCase();
      final isSales = role.contains('sales') ||
          role.contains('executive') ||
          role.contains('telecaller') ||
          role == 'employee' ||
          role.contains('agent') ||
          role.contains('advisor');
      if (!isSales) return false;

      if (currentUser == null) return true;
      if (curRole == 'super admin') return true;
      if (curRole == 'admin') {
        return u.adminId == currentUser.id || u.id == currentUser.id;
      }
      if (curRole.contains('sales')) {
        return _isSalesPersonRole(u.roleName);
      }
      return true;
    }).toList();

    if (currentAssignedTo != null &&
        currentAssignedTo.isNotEmpty &&
        !salesmen.any((u) => u.id == currentAssignedTo)) {
      final name = (req.assigneeName != null && req.assigneeName!.trim().isNotEmpty)
          ? req.assigneeName!.trim()
          : (_liveUserName(currentAssignedTo) ?? 'Assigned');
      final assignedUser = users.firstWhereOrNull((u) => u.id == currentAssignedTo);
      if (!isTelecaller || assignedUser == null || _isSalesPersonRole(assignedUser.roleName)) {
        salesmen = [
          users_model.UserModel(
            id: currentAssignedTo,
            roleId: '',
            roleName: assignedUser?.roleName.isNotEmpty == true ? assignedUser!.roleName : 'Sales',
            fullName: assignedUser?.fullName.isNotEmpty == true ? assignedUser!.fullName : name,
            email: assignedUser?.email ?? '',
            isActive: true,
            adminId: assignedUser?.adminId,
          ),
          ...salesmen,
        ];
      }
    }
    return salesmen;
  }

  Widget _buildAssignToDropdown(RequirementModel req, {bool isReassign = false}) {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        final authState = context.read<AuthBloc>().state;
        final currentUser = authState is Authenticated ? authState.user : null;
        final blocUsers = state is UsersLoaded ? state.users : <users_model.UserModel>[];
        final users = _mergedAssignUsers(blocUsers);
        final currentAssignedTo = _currentAssignedUserId(req, users);
        var salesmen = _salesmenForLeadAssign(
          req: req,
          currentUser: currentUser,
          users: users,
          currentAssignedTo: currentAssignedTo,
        );
        if (isReassign) {
          salesmen = salesmen
              .where((u) => _isSalesPersonRole(u.roleName) || u.id == currentAssignedTo)
              .toList();
        }

        if (state is UsersLoading && users.isEmpty && currentAssignedTo == null) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final bool hasValue = currentAssignedTo != null && salesmen.any((u) => u.id == currentAssignedTo);
        final dropdownValue = hasValue ? currentAssignedTo : null;
          return Container(
            height: 36,
            constraints: const BoxConstraints(minWidth: 125, maxWidth: 160),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: CRMColors.borderOf(context),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: dropdownValue,
                isDense: true,
                isExpanded: true,
                hint: Text(
                  isReassign ? 'Re-Assign' : 'Assign to',
                  style: CRMTypography.caption.copyWith(
                    color: CRMColors.textSecondaryOf(context),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                items: [
                  if (!isReassign || dropdownValue == null)
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'Unassigned',
                        style: CRMTypography.caption.copyWith(
                          color: CRMColors.textSecondaryOf(context),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ...salesmen.map((u) {
                    final isSelected = u.id == currentAssignedTo;
                    return DropdownMenuItem<String?>(
                      value: u.id,
                      child: Text(
                        u.fullName,
                        style: CRMTypography.caption.copyWith(
                          color: isSelected ? CRMColors.primary : CRMColors.textOf(context),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: (String? newSalesmanId) {
                  String? newSalesmanName;
                  if (newSalesmanId != null) {
                    final u = salesmen.where((s) => s.id == newSalesmanId).firstOrNull;
                    newSalesmanName = u?.fullName;
                  }
                  _submitLeadAssignment(req, newSalesmanId, newSalesmanName);
                },
                icon: Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: CRMColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: CRMColors.primary,
                    size: 18,
                  ),
                ),
                dropdownColor: CRMColors.cardBgOf(context),
              ),
            ),
          );
      },
    );
  }

  Widget _buildMobileAssignToDropdown(RequirementModel req, {bool isReassign = false}) {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        final authState = context.read<AuthBloc>().state;
        final currentUser = authState is Authenticated ? authState.user : null;
        final blocUsers = state is UsersLoaded ? state.users : <users_model.UserModel>[];
        final users = _mergedAssignUsers(blocUsers);
        final currentAssignedTo = _currentAssignedUserId(req, users);
        var salesmen = _salesmenForLeadAssign(
          req: req,
          currentUser: currentUser,
          users: users,
          currentAssignedTo: currentAssignedTo,
        );
        if (isReassign) {
          salesmen = salesmen
              .where((u) => _isSalesPersonRole(u.roleName) || u.id == currentAssignedTo)
              .toList();
        }

        if (state is UsersLoading && users.isEmpty && currentAssignedTo == null) {
          return const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final bool hasValue = currentAssignedTo != null && salesmen.any((u) => u.id == currentAssignedTo);
        final dropdownValue = hasValue ? currentAssignedTo : null;
        return Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: CRMColors.borderOf(context),
                width: 1.2,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: dropdownValue,
                isDense: true,
                isExpanded: true,
                hint: Text(
                  isReassign ? 'Re-Assign' : 'Assign to',
                  style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                items: [
                  if (!isReassign || dropdownValue == null)
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'Unassigned',
                        style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
                      ),
                    ),
                  ...salesmen.map((u) {
                    final isSelected = u.id == currentAssignedTo;
                    return DropdownMenuItem<String?>(
                      value: u.id,
                      child: Text(
                        u.fullName,
                        style: CRMTypography.captionBold.copyWith(
                          color: isSelected ? CRMColors.primary : CRMColors.textOf(context),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: (String? newSalesmanId) {
                  String? newSalesmanName;
                  if (newSalesmanId != null) {
                    final u = salesmen.firstWhere((s) => s.id == newSalesmanId);
                    newSalesmanName = u.fullName;
                  }
                  _submitLeadAssignment(req, newSalesmanId, newSalesmanName);
                },
                icon: Container(
                  margin: const EdgeInsets.only(left: 2),
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: CRMColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: CRMColors.primary,
                    size: 16,
                  ),
                ),
                dropdownColor: CRMColors.cardBgOf(context),
              ),
            ),
          );
      },
    );
  }

  bool _isUserCreator(RequirementModel r, UserModel user) {
    if (r.createdBy == user.id) return true;
    final uName = user.fullName.trim().toLowerCase();
    if (uName.isNotEmpty) {
      if (r.createdBy != null && r.createdBy!.trim().toLowerCase() == uName) return true;
      if (r.creatorName != null && r.creatorName!.trim().toLowerCase() == uName) return true;
    }
    return false;
  }

  bool _isUserAssignee(RequirementModel r, UserModel user) {
    final uName = user.fullName.trim().toLowerCase();
    if (r.assignedTo != null && r.assignedTo!.isNotEmpty) {
      if (r.assignedTo == user.id) return true;
      if (uName.isNotEmpty && r.assignedTo!.trim().toLowerCase() == uName) return true;
    }
    if (r.assigneeName != null && uName.isNotEmpty && r.assigneeName!.trim().toLowerCase() == uName) return true;
    return false;
  }

  bool _hasEditAccess(RequirementModel r, UserModel? currentUser) {
    if (currentUser == null) return false;
    if (currentUser.role == 'Super Admin') return true;
    if (currentUser.role == 'Admin') {
      return _isUserCreator(r, currentUser) || r.adminId == currentUser.id;
    }
    if (currentUser.role == 'Telecaller') {
      return _isUserCreator(r, currentUser) || r.adminId == currentUser.adminId;
    }
    if (currentUser.role == 'Sales') {
      if (_isLeadTransferredAway(r, currentUser)) return false;
      return _isUserCreator(r, currentUser) || _isUserAssignee(r, currentUser);
    }
    return false;
  }

  bool _isLeadTransferredAway(RequirementModel r, UserModel? currentUser) {
    if (currentUser == null || currentUser.role != 'Sales') return false;
    final isAssignee = _isUserAssignee(r, currentUser);
    final isCreator = _isUserCreator(r, currentUser);
    if (!isCreator) return false;
    final assigned = r.assignedTo;
    if (assigned == null || assigned.isEmpty) return false;
    return !isAssignee;
  }

  bool _salesCanViewRequirement(RequirementModel r, UserModel currentUser) {
    if (_isLeadTransferredAway(r, currentUser)) return false;
    return _isUserCreator(r, currentUser) || _isUserAssignee(r, currentUser);
  }

  bool _isUnhandledAssignedLead(RequirementModel req, UserModel? currentUser) {
    if (currentUser == null || currentUser.role != 'Sales') return false;
    if (_isLeadTransferredAway(req, currentUser)) return false;

    // Lead must be assigned to this sales user and NOT created by them
    final isAssigned = _isUserAssignee(req, currentUser);
    final isCreator = _isUserCreator(req, currentUser);
    if (!isAssigned || isCreator) return false;

    // If the lead was re-assigned from another salesperson or staff, preserve status & follow-up
    final meta = req.metaCustomFields;
    if (meta != null && (meta['reassigned_by'] != null || meta['reassigned_by_name'] != null)) {
      return false;
    }

    // If the lead already has a next follow-up date, preserve follow-up status & history
    if (req.nextFollowupDate != null && req.nextFollowupDate!.trim().isNotEmpty) {
      return false;
    }

    // Check if sales user has already handled the lead
    if (_salesHasHandledLead(req)) return false;

    // If terminal or closed state, it is not unhandled
    if (req.status == 'Won' || req.status == 'Closed') return false;
    if (_isLeadRejected(req)) return false;

    // Once sales stores a pipeline status, show that status instead of
    // forcing Not Started. Only mask typical telecaller leftover statuses.
    final status = req.status.trim();
    if (status == 'Not Started' ||
        status == 'Follow-up' ||
        status == 'Re-Followup' ||
        status == 'Interested' ||
        status == 'Active' ||
        status == 'Live' ||
        status == 'Site Visit' ||
        status == 'Site Visit Done' ||
        status == 'Site Visit Scheduled' ||
        status == 'Negotiation') {
      return false;
    }
    if (status.startsWith('Call Attempted') || status.startsWith('Call attempted')) {
      return false;
    }

    return true;
  }

  bool _salesHasHandledLead(RequirementModel req) {
    final meta = {
      ...?RequirementLocalRepository.metaCustomFieldsById[req.id],
      ...?req.metaCustomFields,
    };
    if (meta.isEmpty) return false;
    final handled = meta['handled_by_sales'];
    if (handled == true ||
        handled == 'true' ||
        handled == 1 ||
        handled == '1') {
      return true;
    }
    if (meta['sales_handled_at'] != null &&
        meta['sales_handled_at'].toString().trim().isNotEmpty) {
      return true;
    }
    final telecallerStatus = meta['telecaller_status']?.toString().trim() ?? '';
    if (telecallerStatus.isNotEmpty &&
        req.status.trim() != telecallerStatus &&
        req.status != 'Assigned' &&
        req.status != 'New') {
      return true;
    }
    return false;
  }

  bool _isLeadClosedOrTerminal(RequirementModel req) {
    final status = req.status.trim().toLowerCase();
    if (status == 'won' || status == 'closed') return true;
    if (status.startsWith('rejected')) return true;
    if (status == 'lost' ||
        status == 'bin' ||
        status == 'dead' ||
        status == 'not interested' ||
        status == 'junk') {
      return true;
    }
    return false;
  }

  bool _isLeadWon(RequirementModel req) {
    final status = req.status.trim().toLowerCase();
    return status == 'won' || status == 'closed';
  }

  bool _isLeadRejected(RequirementModel req) {
    final status = req.status.trim();
    if (status.isEmpty) return false;
    final lower = status.toLowerCase();
    if (lower == 'bin') return false;
    return lower.startsWith('rejected');
  }

  DateTime? _rejectedAt(RequirementModel req) {
    final meta = req.metaCustomFields;
    if (meta == null) return null;
    for (final key in ['rejected_at', 'rejectedAt', 'sales_handled_at']) {
      final raw = meta[key];
      if (raw == null) continue;
      final parsed = DateTime.tryParse(raw.toString());
      if (parsed != null) return parsed.toLocal();
    }
    return null;
  }

  DateTime _dateForLeadFilter(RequirementModel req) {
    if (_activeMainTab == 'Rejected') {
      return _rejectedAt(req) ?? req.createdAt.toLocal();
    }
    return req.createdAt.toLocal();
  }

  String _getTelecallerStatusLabel(RequirementModel req) {
    final meta = req.metaCustomFields;
    if (meta != null && meta['telecaller_status'] != null) {
      final s = meta['telecaller_status'].toString().trim();
      if (s.isNotEmpty) return s;
    }
    final raw = req.status;
    if (raw == 'Active' || raw == 'Live' || raw == 'Interested') return 'Interested';
    if (raw == 'New' || raw.isEmpty) return 'Interested';
    return displayStatusLabel(raw);
  }

  bool _shouldShowTelecallerStatusBadge(RequirementModel req, UserModel? currentUser) {
    if (currentUser == null || currentUser.role != 'Sales') return false;
    if (_isLeadTransferredAway(req, currentUser)) return false;

    final isAssigned = _isUserAssignee(req, currentUser);
    final isCreator = _isUserCreator(req, currentUser);
    if (!isAssigned || isCreator) return false;

    // Show if unhandled OR if handled with telecaller_status recorded
    return _isUnhandledAssignedLead(req, currentUser) ||
        (req.metaCustomFields != null && req.metaCustomFields!['telecaller_status'] != null);
  }

  Widget _buildTelecallerStatusBadge(RequirementModel req, {bool compact = false}) {
    final statusLabel = _getTelecallerStatusLabel(req);
    final creator = (req.creatorName != null && req.creatorName!.trim().isNotEmpty)
        ? req.creatorName!.trim()
        : 'telecaller';
    final tooltipText = 'Marked as $statusLabel by $creator';

    return Tooltip(
      message: tooltipText,
      child: Container(
        margin: const EdgeInsets.only(top: 3),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(CRMBorderRadius.round),
          border: Border.all(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.phone_in_talk_rounded,
              size: 11,
              color: Color(0xFF0284C7),
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: compact ? 120 : 160),
              child: Text(
                '$statusLabel by telecaller',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF0369A1),
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 10 : 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesLeadGroupSelector(UserModel currentUser, List<RequirementModel> allLoadedReqs) {
    final activeTabReqs = allLoadedReqs.where((r) => getListingTypeLabel(r) == _activeListingTab).toList();

    final assignedCount = activeTabReqs.where((r) =>
        _salesCanViewRequirement(r, currentUser) &&
        _isUserAssignee(r, currentUser) &&
        !_isUserCreator(r, currentUser) &&
        !_isLeadTransferredAway(r, currentUser) &&
        r.status != 'Won' && r.status != 'Closed' && !_isLeadRejected(r)
    ).length;

    final addedCount = activeTabReqs.where((r) =>
        _salesCanViewRequirement(r, currentUser) &&
        _isUserCreator(r, currentUser) &&
        !_isLeadTransferredAway(r, currentUser) &&
        r.status != 'Won' && r.status != 'Closed' && !_isLeadRejected(r)
    ).length;

    final allCount = activeTabReqs.where((r) =>
        _salesCanViewRequirement(r, currentUser) &&
        !_isLeadTransferredAway(r, currentUser) &&
        r.status != 'Won' && r.status != 'Closed' && !_isLeadRejected(r)
    ).length;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.m),
        border: Border.all(color: CRMColors.borderOf(context).withValues(alpha: 0.6)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSalesGroupFilterButton(
              label: 'Leads Assigned to Me',
              icon: Icons.assignment_ind_rounded,
              value: 'assigned',
              count: assignedCount,
            ),
            const SizedBox(width: 6),
            _buildSalesGroupFilterButton(
              label: 'Leads Added by Me',
              icon: Icons.person_add_alt_1_rounded,
              value: 'added',
              count: addedCount,
            ),
            const SizedBox(width: 6),
            _buildSalesGroupFilterButton(
              label: 'All My Leads',
              icon: Icons.dashboard_customize_rounded,
              value: 'all',
              count: allCount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesGroupFilterButton({
    required String label,
    required IconData icon,
    required String value,
    required int count,
  }) {
    final bool isSelected = _salesLeadGroupFilter == value;
    final primaryColor = CRMColors.primaryOf(context);

    return InkWell(
      onTap: () {
        setState(() {
          _salesLeadGroupFilter = value;
          _currentPage = 1;
        });
      },
      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
      child: AnimatedContainer(
        duration: CRMMotion.fast,
        curve: CRMMotion.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : CRMColors.textSecondaryOf(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: CRMTypography.bodyMedium.copyWith(
                color: isSelected ? Colors.white : CRMColors.textOf(context),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : CRMColors.backgroundOf(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? Colors.white.withValues(alpha: 0.3) : CRMColors.borderOf(context),
                  width: 0.8,
                ),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : CRMColors.textSecondaryOf(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesAssignToLabel(RequirementModel req, UserModel? currentUser) {
    final assignee = req.assigneeName?.trim() ?? '';
    final creator = req.creatorName?.trim() ?? '';
    final isReceivedTransfer = currentUser != null &&
        _isUserAssignee(req, currentUser) &&
        !_isUserCreator(req, currentUser);

    if (_isLeadTransferredAway(req, currentUser)) {
      return Text(
        assignee.isNotEmpty ? 'Transferred to $assignee' : 'Transferred to another salesperson',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: CRMTypography.captionBold.copyWith(
          color: CRMColors.warning,
        ),
      );
    }

    if (isReceivedTransfer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            assignee.isNotEmpty ? assignee : (currentUser.fullName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CRMTypography.bodyMedium.copyWith(
              color: CRMColors.textOf(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (creator.isNotEmpty)
            Text(
              'From $creator',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CRMTypography.caption.copyWith(
                color: CRMColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      );
    }

    final String effectiveName = assignee.isNotEmpty
        ? assignee
        : (creator.isNotEmpty ? creator : 'Unassigned');

    return Text(
      effectiveName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CRMTypography.bodyMedium.copyWith(
        color: CRMColors.textOf(context),
      ),
    );
  }

  String displayStatusLabel(String status) {
    if (status == 'Assigned') return 'Assigned';
    if (status == 'New') return 'New';
    if (status == 'Not Started') return 'Not Started';
    if (status.startsWith('Call Attempted') || status.startsWith('Call attempted')) return 'Call Attempted';
    if (status == 'Not Interested') return 'Not Interested';
    if (status == 'Active' || status == 'Live') return 'Interested';
    if (status == 'Closed' || status == 'Won') return 'Won';
    if (status.startsWith('Rejected') || status == 'Bin') return 'Rejected';
    return status;
  }

  PopupMenuItem<String> _buildStatusMenuItem(
    String value,
    String label,
    String currentStatus, {
    Color? color,
  }) {
    final bool isSelected = currentStatus == value ||
        (value == 'Assigned' && currentStatus == 'Assigned') ||
        (value == 'New' && currentStatus == 'New') ||
        (value == 'Not Started' && currentStatus == 'Not Started') ||
        (value == 'Not Interested' && (currentStatus == 'Not Interested' || currentStatus == 'Dead' || currentStatus == 'Suspended')) ||
        (value == 'Follow-up' && (currentStatus == 'Follow-up' || currentStatus == 'Re-Followup')) ||
        (value == 'Interested' && (currentStatus == 'Interested' || currentStatus == 'Active' || currentStatus == 'Live')) ||
        (value == 'Won' && (currentStatus == 'Won' || currentStatus == 'Closed'));

    return PopupMenuItem<String>(
      value: value,
      child: MouseRegion(
        onEnter: (_) => _removeRejectionOverlay(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color ?? CRMColors.textOf(context),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                size: 16,
                color: Color(0xFF5C6BC0),
              ),
          ],
        ),
      ),
    );
  }

  Offset _lastTapPosition = const Offset(400, 300);
  OverlayEntry? _rejectionOverlayEntry;

  void _removeRejectionOverlay() {
    if (_rejectionOverlayEntry != null) {
      _rejectionOverlayEntry?.remove();
      _rejectionOverlayEntry = null;
    }
  }

  void _showRejectionOverlayAtContext(BuildContext itemContext, RequirementModel req) {
    if (_rejectionOverlayEntry != null) return;

    final RenderBox? renderBox = itemContext.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset itemGlobalOffset = renderBox.localToGlobal(Offset.zero);
    final overlay = Overlay.of(itemContext);
    final size = MediaQuery.of(itemContext).size;

    // Position exact left touching the main status popup menu window (190px width)
    double left = (itemGlobalOffset.dx - 192).clamp(10.0, size.width - 200.0);
    double top = (itemGlobalOffset.dy - 120).clamp(40.0, size.height - 380.0);

    final List<String> reasons = [
      'Not Answering',
      'No Requirement',
      'Budget Mismatch',
      'Locality Mismatch',
      'Broker',
      'Already rented',
      'Want Ready-To-Move',
      'Negotiation Failed',
      'Others',
    ];

    _rejectionOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Positioned(
          left: left,
          top: top,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            color: CRMColors.cardBgOf(context),
            child: Container(
              width: 190,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: CRMColors.cardBgOf(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: reasons.map((reason) {
                  final bool isSelected = req.status == 'Rejected ($reason)';
                  return InkWell(
                    onTap: () {
                      _removeRejectionOverlay();
                      Navigator.of(context, rootNavigator: true).maybePop();
                      _changeStatus(req, 'Rejected ($reason)');
                    },
                    hoverColor: CRMColors.backgroundOf(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            reason,
                            style: TextStyle(
                              color: CRMColors.textOf(context),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Color(0xFF5C6BC0),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_rejectionOverlayEntry!);
  }

  OverlayEntry? _callAttemptedOverlayEntry;

  void _removeCallAttemptedOverlay() {
    if (_callAttemptedOverlayEntry != null) {
      _callAttemptedOverlayEntry?.remove();
      _callAttemptedOverlayEntry = null;
    }
  }

  void _showCallAttemptedOverlayAtContext(BuildContext itemContext, RequirementModel req) {
    if (_callAttemptedOverlayEntry != null) return;

    final RenderBox? renderBox = itemContext.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset itemGlobalOffset = renderBox.localToGlobal(Offset.zero);
    final overlay = Overlay.of(itemContext);
    final size = MediaQuery.of(itemContext).size;

    double left = (itemGlobalOffset.dx - 172).clamp(10.0, size.width - 180.0);
    double top = (itemGlobalOffset.dy - 30).clamp(40.0, size.height - 380.0);

    final List<String> options = [
      'Picked Up',
      'Open',
    ];

    _callAttemptedOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Positioned(
          left: left,
          top: top,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            color: CRMColors.cardBgOf(context),
            child: Container(
              width: 170,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: CRMColors.cardBgOf(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: options.map((opt) {
                  final String fullStatus = 'Call Attempted ($opt)';
                  final bool isSelected = req.status == fullStatus || req.status == 'Call Attempted - $opt';
                  return InkWell(
                    onTap: () {
                      _removeCallAttemptedOverlay();
                      _removeRejectionOverlay();
                      Navigator.of(context, rootNavigator: true).maybePop();
                      _changeStatus(req, fullStatus);
                    },
                    hoverColor: CRMColors.backgroundOf(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            opt,
                            style: TextStyle(
                              color: CRMColors.textOf(context),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Color(0xFF0288D1),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_callAttemptedOverlayEntry!);
  }

  Widget _buildStatusControl(RequirementModel req, UserModel? currentUser, {bool compact = false}) {
    if (_isLeadTransferredAway(req, currentUser)) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? CRMSpacing.s : CRMSpacing.s,
          vertical: compact ? CRMSpacing.xxs : CRMSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: CRMColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(CRMBorderRadius.round),
          border: Border.all(color: CRMColors.warning.withValues(alpha: 0.35)),
        ),
        child: Text(
          'Leads Transfer',
          style: CRMTypography.captionBold.copyWith(
            color: CRMColors.warning,
            fontSize: compact ? 11 : 12,
          ),
        ),
      );
    }

    final bool isUnhandledAssigned = _isUnhandledAssignedLead(req, currentUser);
    final String currentStatus = _isLeadRejected(req)
        ? getEffectiveStatus(req)
        : ((req.status == 'Assigned')
            ? 'Assigned'
            : (isUnhandledAssigned ? 'Not Started' : getEffectiveStatus(req)));
    final statusColor = compact ? _getStatusColor(currentStatus) : CRMColors.primary;
    final bool hasPreviousFollowup = currentStatus == 'Follow-up' ||
        currentStatus == 'Re-Followup' ||
        req.nextFollowupDate != null;
    final String followupLabel = hasPreviousFollowup ? 'Re-Followup' : 'Follow-up';
    final String followupValue = hasPreviousFollowup ? 'Re-Followup' : 'Follow-up';

    String mainLabel = displayStatusLabel(currentStatus);
    String? subReason;
    if (currentStatus.startsWith('Rejected') && currentStatus.contains('(') && currentStatus.contains(')')) {
      mainLabel = 'Rejected';
      subReason = currentStatus.substring(currentStatus.indexOf('(') + 1, currentStatus.indexOf(')')).trim();
    } else if (currentStatus.startsWith('Rejected: ')) {
      mainLabel = 'Rejected';
      subReason = currentStatus.replaceFirst('Rejected: ', '').trim();
    } else if (currentStatus.startsWith('Call Attempted') || currentStatus.startsWith('Call attempted')) {
      mainLabel = 'Call Attempted';
      if (currentStatus.contains('(') && currentStatus.contains(')')) {
        subReason = currentStatus.substring(currentStatus.indexOf('(') + 1, currentStatus.indexOf(')')).trim();
      } else if (currentStatus.contains('-')) {
        subReason = currentStatus.split('-').last.trim();
      }
    }

    return GestureDetector(
      onTapDown: (details) {
        _lastTapPosition = details.globalPosition;
      },
      child: PopupMenuButton<String>(
        tooltip: 'Change Status',
        onCanceled: () {
          _removeRejectionOverlay();
          _removeCallAttemptedOverlay();
        },
        onSelected: (String newStatus) {
          if (newStatus == 'Rejected' || newStatus == 'Call Attempted') {
            // Handled via overlay
          } else {
            _removeRejectionOverlay();
            _removeCallAttemptedOverlay();
            _changeStatus(req, newStatus);
          }
        },
        itemBuilder: (BuildContext context) {
          return [
            _buildStatusMenuItem('New', 'New', currentStatus),
            _buildStatusMenuItem('Assigned', 'Assigned', currentStatus, color: const Color(0xFF0F766E)),
            _buildStatusMenuItem('Not Started', 'Not Started', currentStatus),
            PopupMenuItem<String>(
              value: 'Call Attempted',
              child: Builder(
                builder: (itemContext) {
                  return StatefulBuilder(
                    builder: (context, setItemState) {
                      final bool isOpen = _callAttemptedOverlayEntry != null;
                      final bool isCallAttemptedActive = currentStatus.startsWith('Call Attempted') || currentStatus.startsWith('Call attempted');
                      return MouseRegion(
                        onEnter: (_) {
                          _removeRejectionOverlay();
                          setItemState(() {});
                          _showCallAttemptedOverlayAtContext(itemContext, req);
                        },
                        onExit: (_) {
                          setItemState(() {});
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isOpen ? '>  ' : '<  ',
                                  style: const TextStyle(
                                    color: Color(0xFF0288D1),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Call Attempted',
                                  style: TextStyle(
                                    color: CRMColors.textOf(context),
                                    fontWeight: isCallAttemptedActive ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            if (isCallAttemptedActive)
                              const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Color(0xFF5C6BC0),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _buildStatusMenuItem(followupValue, followupLabel, currentStatus),
            _buildStatusMenuItem('Interested', 'Interested', currentStatus),
            _buildStatusMenuItem('Site Visit', 'Site Visit Sche.', currentStatus),
            _buildStatusMenuItem('Site Visit Done', 'Site Visit Done', currentStatus),
            _buildStatusMenuItem('Negotiation', 'Negotiation', currentStatus),
            _buildStatusMenuItem('Won', 'Deal Success (Won)', currentStatus),
            PopupMenuItem<String>(
              value: 'Rejected',
              child: Builder(
                builder: (itemContext) {
                  return StatefulBuilder(
                    builder: (context, setItemState) {
                      final bool isOpen = _rejectionOverlayEntry != null;
                      return MouseRegion(
                        onEnter: (_) {
                          setItemState(() {});
                          _showRejectionOverlayAtContext(itemContext, req);
                        },
                        onExit: (_) {
                          setItemState(() {});
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isOpen ? '>  ' : '<  ',
                                  style: const TextStyle(
                                    color: CRMColors.danger,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Rejected',
                                  style: TextStyle(
                                    color: CRMColors.danger,
                                    fontWeight: currentStatus.startsWith('Rejected') ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            if (currentStatus.startsWith('Rejected') || currentStatus == 'Not Interested' || currentStatus == 'Bin')
                              const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Color(0xFF5C6BC0),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ];
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: CRMSpacing.xxs),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(CRMBorderRadius.round),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mainLabel,
                      style: CRMTypography.captionBold.copyWith(
                        color: statusColor,
                        fontSize: compact ? 11 : 12,
                      ),
                    ),
                    if (subReason != null && subReason.isNotEmpty)
                      Text(
                        subReason,
                        style: CRMTypography.caption.copyWith(
                          color: statusColor.withOpacity(0.85),
                          fontSize: compact ? 9.5 : 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down_rounded, size: 16, color: statusColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _getCleanNote(RequirementModel req) {
    return getTelecallerRemarks(req);
  }

  void _removeNotesPopover() {
    _notesOverlayEntry?.remove();
    _notesOverlayEntry = null;
  }

  void _showNotesPopover(BuildContext anchorContext, RequirementModel req) {
    _removeNotesPopover();

    final RenderBox? renderBox = anchorContext.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    
    final OverlayState overlay = Overlay.of(anchorContext);
    final RenderBox? overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final double maxCanvasWidth = overlayBox?.size.width ?? MediaQuery.of(anchorContext).size.width;
    final double maxCanvasHeight = overlayBox?.size.height ?? MediaQuery.of(anchorContext).size.height;

    final notesController = TextEditingController(text: '');

    final double popoverWidth = (maxCanvasWidth - 32).clamp(240.0, 320.0);
    const double popoverHeight = 245.0;

    final double targetCenterX = offset.dx + (size.width / 2);
    double left = targetCenterX - (popoverWidth / 2);

    if (left + popoverWidth > maxCanvasWidth - 16) {
      left = maxCanvasWidth - popoverWidth - 16;
    }
    if (left < 16) {
      left = 16;
    }

    double arrowLeft = targetCenterX - left - 10;
    if (arrowLeft < 16) arrowLeft = 16;
    if (arrowLeft > popoverWidth - 36) arrowLeft = popoverWidth - 36;

    double top = offset.dy + size.height + 4;
    bool showAbove = top + popoverHeight > maxCanvasHeight;
    if (showAbove) {
      top = offset.dy - popoverHeight - 14;
    }

    _notesOverlayEntry = OverlayEntry(
      builder: (context) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setOverlayState) {
            final bool hasText = notesController.text.trim().isNotEmpty;

            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _removeNotesPopover,
                    child: Container(color: Colors.black.withOpacity(0.15)),
                  ),
                ),
                Positioned(
                  left: left,
                  top: top,
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!showAbove)
                          Padding(
                            padding: EdgeInsets.only(left: arrowLeft),
                            child: CustomPaint(
                              size: const Size(20, 10),
                              painter: _PopoverTrianglePainter(
                                color: CRMColors.cardBgOf(anchorContext),
                              ),
                            ),
                          ),
                        Container(
                          width: popoverWidth,
                          decoration: BoxDecoration(
                            color: CRMColors.cardBgOf(anchorContext),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '+ Add Note',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: CRMColors.textOf(anchorContext),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(anchorContext).brightness == Brightness.dark
                                        ? Colors.black12
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: CRMColors.borderOf(anchorContext).withOpacity(0.6),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: TextField(
                                    controller: notesController,
                                    maxLines: 4,
                                    minLines: 3,
                                    onChanged: (val) => setOverlayState(() {}),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: CRMColors.textOf(anchorContext),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Type your note here...',
                                      hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: CRMColors.textSecondaryOf(anchorContext).withOpacity(0.6),
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        notesController.clear();
                                        setOverlayState(() {});
                                      },
                                      child: Text(
                                        'Clear',
                                        style: TextStyle(
                                          color: CRMColors.textOf(anchorContext),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: hasText
                                            ? const Color(0xFF6C5CE7)
                                            : const Color(0xFFA0AEC0),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: (isSaving || !hasText)
                                          ? null
                                          : () async {
                                              setOverlayState(() => isSaving = true);
                                              final newNoteText = notesController.text.trim();
                                              final timeStr = DateFormat("dd MMM ''yy, h:mm a").format(DateTime.now());
                                              final formattedEntry = '[$timeStr] $newNoteText';
                                              final existingClean = _getCleanNote(req);
                                              final updatedNotes = (existingClean != null && existingClean.isNotEmpty)
                                                  ? '$existingClean\n$formattedEntry'
                                                  : formattedEntry;

                                              try {
                                                context.read<RequirementsBloc>().add(
                                                  UpdateRequirementEvent(
                                                    req.copyWith(notes: updatedNotes),
                                                  ),
                                                );

                                                await RequirementsRepository().updateRequirementFields(
                                                  req.id,
                                                  {'notes': updatedNotes, 'new_note': formattedEntry},
                                                );

                                                _removeNotesPopover();

                                                if (mounted) {
                                                  setState(() {
                                                    _refreshFollowupsFuture();
                                                  });
                                                  _triggerFetch();
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Note saved successfully.'),
                                                      backgroundColor: CRMColors.success,
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                setOverlayState(() => isSaving = false);
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Failed to save note: $e'),
                                                      backgroundColor: CRMColors.danger,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                      child: isSaving
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Save Notes',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (showAbove)
                          Padding(
                            padding: EdgeInsets.only(left: arrowLeft),
                            child: CustomPaint(
                              size: const Size(20, 10),
                              painter: _PopoverTrianglePainter(
                                color: CRMColors.cardBgOf(anchorContext),
                                pointingDown: true,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    overlay.insert(_notesOverlayEntry!);
  }

  void _showViewAllNotesDialog(BuildContext context, RequirementModel req) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _ViewAllNotesDialogWidget(
          requirement: req,
          onSave: (updatedNotes, updatedReqModel, newNote, [deletedNote]) async {
            context.read<RequirementsBloc>().add(
              UpdateRequirementEvent(updatedReqModel),
            );
            await RequirementsRepository().updateRequirementFields(
              req.id,
              {
                'notes': updatedNotes,
                if (newNote != null && newNote.isNotEmpty) 'new_note': newNote,
                if (deletedNote != null && deletedNote.isNotEmpty) 'deleted_note': deletedNote,
              },
            );
            if (mounted) {
              setState(() {
                _refreshFollowupsFuture();
              });
              _triggerFetch();
            }
          },
        );
      },
    );
  }

  Widget _buildStatusControlWithNotes(RequirementModel req, UserModel? currentUser, {bool compact = false}) {
    final bool isClosed = _isLeadClosedOrTerminal(req);
    final String? userNote = _getCleanNote(req);
    final bool hasNotes = userNote != null && userNote.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildStatusControl(req, currentUser, compact: compact),
        if (!isClosed) ...[
          const SizedBox(height: 4),
          Builder(
            builder: (btnContext) {
              return InkWell(
                onTap: () => _showNotesPopover(btnContext, req),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    '+Add Notes',
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: CRMColors.textOf(context),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRequirementsTable() {
    final authState = context.read<AuthBloc>().state;
    UserModel? currentUser;
    if (authState is Authenticated) {
      currentUser = authState.user;
    }

    return BlocBuilder<RequirementsBloc, RequirementsState>(
      buildWhen: (previous, current) =>
          current is RequirementsLoaded ||
          current is RequirementsLoading ||
          current is RequirementsInitial ||
          current is RequirementsError,
      builder: (context, state) {
        if (state is RequirementsLoaded) {
          _cachedRequirements = _withLocalRequirementOverrides(state.requirements);
        }
        final rawLoadedList = _withLocalRequirementOverrides(
          state is RequirementsLoaded ? state.requirements : _cachedRequirements,
        );
        final isLoading = (state is RequirementsLoading || state is RequirementsInitial) && rawLoadedList.isEmpty;
        List<RequirementModel> requirements = [];

        if (rawLoadedList.isNotEmpty) {
          final query = _searchController.text.trim().toLowerCase();
          requirements = rawLoadedList.where((r) {
            if (_activeMainTab == 'Leads Added by Me') {
              if (currentUser == null || !_isUserCreator(r, currentUser)) {
                return false;
              }
            }
            if (currentUser != null && currentUser.role == 'Sales') {
              if (!_salesCanViewRequirement(r, currentUser)) {
                return false;
              }
              if (_salesLeadGroupFilter == 'assigned') {
                if (!(_isUserAssignee(r, currentUser) && !_isUserCreator(r, currentUser))) {
                  return false;
                }
              } else if (_salesLeadGroupFilter == 'added') {
                if (!_isUserCreator(r, currentUser)) {
                  return false;
                }
              }
            }

            final matchesListingType = getListingTypeLabel(r) == _activeListingTab;
            final matchesCategory = _selectedCategoryId == null || r.categoryId == _selectedCategoryId;
            final matchesSpec = _selectedConfigIds.isEmpty ||
                _selectedConfigIds.contains(r.configurationId) ||
                _selectedConfigIds.contains(r.propertyTypeId) ||
                r.configurationIds.any((id) => _selectedConfigIds.contains(id)) ||
                r.propertyTypeIds.any((id) => _selectedConfigIds.contains(id));
            
            final bool isUnhandledAssigned = _isUnhandledAssignedLead(r, currentUser);
            // Map legacy status strings to new pipeline statuses for backward compatibility
            String mappedStatus = _isLeadRejected(r)
                ? getEffectiveStatus(r)
                : ((r.status == 'Assigned')
                    ? 'Assigned'
                    : (isUnhandledAssigned ? 'Not Started' : getEffectiveStatus(r)));
            if (mappedStatus == 'Active' || mappedStatus == 'Live') mappedStatus = 'Interested';
            if (mappedStatus == 'Closed' || mappedStatus == 'Won') mappedStatus = 'Won';
            if (mappedStatus == 'Suspended' || mappedStatus == 'Dead') mappedStatus = 'Not Interested';
            if (mappedStatus.startsWith('Rejected') || mappedStatus == 'Bin') mappedStatus = 'Rejected';

            final userFilterActive = _selectedUserFilterId != "All" && _selectedUserFilterId.isNotEmpty;
            final bool viewAllRejected =
                _activeMainTab == 'Rejected' && _canViewAllRejectedLeads(currentUser);

            if (_activeMainTab == 'Rejected') {
              if (!_isLeadRejected(r)) return false;
            } else if (_activeMainTab == 'Leads' && _isLeadRejected(r)) {
              return false;
            }

            // Exclude Won requirements from the active Requirements view unless user explicitly selected "Won"
            // or is viewing a specific team member's complete lead set.
            final bool unassignFilter =
                !viewAllRejected &&
                _selectedStatus == 'Unassign' &&
                _canSeeUnassignStatusFilter(currentUser);

            if (_activeMainTab != 'Leads Added by Me' &&
                !userFilterActive &&
                _selectedStatus != 'Won' &&
                !unassignFilter &&
                mappedStatus == 'Won') return false;

            final matchesStatus = viewAllRejected
                ? true
                : unassignFilter
                ? _isLeadUnassigned(r)
                : (userFilterActive
                ? (_selectedStatus == "All" ||
                    mappedStatus == _selectedStatus ||
                    r.status == _selectedStatus)
                : (_selectedStatus == "All" ||
                mappedStatus == _selectedStatus ||
                (!isUnhandledAssigned && r.status == _selectedStatus) ||
                (!isUnhandledAssigned && _selectedStatus == 'Rejected' && r.status.startsWith('Rejected')) ||
                (!isUnhandledAssigned && _selectedStatus == 'Call Attempted' && (r.status.startsWith('Call Attempted') || r.status.startsWith('Call attempted')))));

            final matchesDate = _matchesLeadDateFilter(r);

            bool matchesUser = true;
            if (!viewAllRejected && _activeMainTab != 'Leads Added by Me' && userFilterActive) {
              users_model.UserModel? selectedUser;
              try {
                final usersState = context.read<UsersBloc>().state;
                if (usersState is UsersLoaded) {
                  selectedUser = usersState.users.firstWhereOrNull((u) => u.id == _selectedUserFilterId);
                }
              } catch (_) {}
              matchesUser = selectedUser != null && TeamUserVisibility.requirementBelongsToUser(r, selectedUser);
            }

            bool matchesSearch = true;
            if (query.isNotEmpty) {
              final clientName = r.clientName.toLowerCase();
              final clientMobile = r.clientMobile.toLowerCase();
              final specs = '${r.propertyTypeName} ${r.configurationName ?? ""} ${r.listingTypeName ?? ""} ${r.categoryName ?? ""}'.toLowerCase();
              final remarks = (r.remarks ?? '').toLowerCase();
              final areas = r.areaNames.join(' ').toLowerCase();

              bool matchesSalesman = false;
              if (currentUser != null && (currentUser.role == 'Admin' || currentUser.role == 'Super Admin' || currentUser.role == 'Telecaller')) {
                final creator = (r.creatorName ?? '').toLowerCase();
                final assignee = (r.assigneeName ?? '').toLowerCase();
                matchesSalesman = creator.contains(query) || assignee.contains(query);
              }

              matchesSearch = clientName.contains(query) ||
                  clientMobile.contains(query) ||
                  specs.contains(query) ||
                  remarks.contains(query) ||
                  areas.contains(query) ||
                  matchesSalesman;
            }

            final matchesReadiness = _selectedReadiness == "All" ||
                (_selectedReadiness == "Needs Details" ? r.matchingReadiness != 'Ready' : r.matchingReadiness == _selectedReadiness);

            return matchesListingType && matchesCategory && matchesSpec && matchesStatus && matchesSearch && matchesDate && matchesReadiness && matchesUser;
          }).toList();

          if (_activeMainTab == 'Rejected') {
            requirements.sort((a, b) {
              final da = _rejectedAt(a) ?? a.createdAt;
              final db = _rejectedAt(b) ?? b.createdAt;
              return db.compareTo(da);
            });
          } else {
            requirements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          }
        }

    final totalCount = requirements.length;
    final totalPages = (totalCount / _requirementsPerPage).ceil();
    final currentPage = _currentPage.clamp(1, totalPages > 0 ? totalPages : 1);

    final startIndex = (currentPage - 1) * _requirementsPerPage;
    final endIndex = (startIndex + _requirementsPerPage).clamp(0, totalCount);

    final pageItems = (startIndex < totalCount)
        ? requirements.sublist(startIndex, endIndex)
        : <RequirementModel>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        if (isMobile || !_isTableView) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildActionBar(requirements, currentUser),
              _buildRequirementCards(pageItems, isLoading, currentUser, currentPage, totalPages, totalCount),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildActionBar(requirements, currentUser),
            CRMDataTable(
              isLoading: isLoading,
              emptyTitle: _activeMainTab == 'Rejected' ? 'No Rejected Leads' : 'No Requirements Found',
              emptyDescription: _activeMainTab == 'Rejected'
                  ? 'Leads marked as Rejected will appear here.'
                  : 'Try adjusting filters or create a new requirement pipeline.',
              dataRowMinHeight: 88.0,
              dataRowMaxHeight: 160.0,
              columnSpacing: 10.0,
              horizontalMargin: 12.0,
              columns: [
                const DataColumn(label: Text('Client')),
                if (currentUser != null && (currentUser.role == 'Super Admin' || currentUser.role == 'Admin' || currentUser.role == 'Telecaller'))
                  const DataColumn(label: Text('Added By')),
                const DataColumn(label: Text('Assign to')),
                const DataColumn(label: Text('Specs / Config')),
                const DataColumn(label: Text('Budget Range')),
                const DataColumn(label: Text('Target Area(s)')),
                const DataColumn(label: Text('Status')),
                const DataColumn(label: Text('Matches')),
                const DataColumn(label: Text('Actions')),
              ],
              rows: pageItems.map((req) {
                final qualityColor = req.requirementQuality == 'High'
                    ? CRMColors.success
                    : req.requirementQuality == 'Medium'
                        ? CRMColors.warning
                        : CRMColors.danger;

                final isHighlighted = req.id == _highlightedRequirementId;
                final bool isClosed = _isLeadClosedOrTerminal(req);
                final bool isWon = _isLeadWon(req);

                return DataRow(
                  color: isHighlighted
                      ? WidgetStateProperty.all(CRMColors.primaryOf(context).withOpacity(0.12))
                      : (isClosed ? WidgetStateProperty.all(CRMColors.sidebarBgOf(context).withValues(alpha: 0.6)) : null),
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 135,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _showRequirementDetailDrawer(req),
                              child: Text(
                                req.clientName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CRMTypography.bodyMedium.copyWith(
                                  color: CRMColors.primary,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              req.clientMobile,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Added: ${DateFormat('dd/MM/yyyy').format(req.createdAt)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 10),
                            ),
                            if (req.isMetaLead) ...[
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1877F2).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF1877F2).withOpacity(0.35)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.campaign_rounded, size: 10, color: Color(0xFF1877F2)),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        req.metaCampaignDisplayName != null ? 'Meta: ${req.metaCampaignDisplayName}' : 'Meta Ads',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF1877F2),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (req.matchingReadiness != 'Ready') ...[
                              const SizedBox(height: 3),
                              _buildNeedsMoreDetailsBadge(req, compact: true),
                            ],
                            Builder(
                              builder: (context) {
                                final telecallerKeyPoints = getTelecallerRemarks(req);
                                if (telecallerKeyPoints == null || telecallerKeyPoints.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Tooltip(
                                    message: 'Telecaller Key Points:\n$telecallerKeyPoints',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.35)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.speaker_notes_rounded, size: 10, color: Color(0xFF0F766E)),
                                          const SizedBox(width: 3),
                                          Flexible(
                                            child: Text(
                                              'Key Points: $telecallerKeyPoints',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFF0F766E),
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (req.nextFollowupDate != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.alarm_rounded, size: 12, color: CRMColors.warning),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(DateTime.parse(req.nextFollowupDate!).toLocal()),
                                    style: CRMTypography.captionBold.copyWith(color: CRMColors.warning, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (currentUser != null && (currentUser.role == 'Super Admin' || currentUser.role == 'Admin' || currentUser.role == 'Telecaller'))
                      DataCell(
                        Text(
                          _getAddedByColumnName(req),
                          style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    DataCell(
                      isClosed
                          ? Text(
                              _getSalesmanName(req, currentUser),
                              style: CRMTypography.caption.copyWith(
                                color: CRMColors.textSecondaryOf(context).withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : ((_canInitiallyAssignLead(currentUser) || _canSalesReassignLead(currentUser))
                              ? _buildAssignToDropdown(
                                  req,
                                  isReassign: _canSalesReassignLead(currentUser),
                                )
                              : _buildSalesAssignToLabel(req, currentUser)),
                    ),
                    DataCell(_buildSpecsConfigCell(req)),
                    DataCell(
                      Text(
                        '${BudgetFormatter.format(req.minBudget)} - ${BudgetFormatter.format(req.maxBudget)}',
                        style: CRMTypography.bodyMedium.copyWith(color: CRMColors.primaryOf(context)),
                      ),
                    ),
                    DataCell(_buildTargetAreasCell(req)),
                    DataCell(
                      _buildStatusControlWithNotes(req, currentUser),
                    ),

                    DataCell(
                      isClosed
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isWon
                                    ? CRMColors.success.withValues(alpha: 0.12)
                                    : CRMColors.danger.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isWon
                                      ? CRMColors.success.withValues(alpha: 0.3)
                                      : CRMColors.danger.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isWon ? Icons.verified_rounded : Icons.block_rounded,
                                    size: 13,
                                    color: isWon ? CRMColors.success : CRMColors.danger,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isWon ? 'Deal Won' : 'Lead Closed',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isWon ? CRMColors.success : CRMColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _RunMatchesButtonWithBadge(
                              requirement: req,
                              onPressed: () => _showMatchesDrawer(req),
                              properties: _propertiesForMatches,
                            ),
                    ),
                    DataCell(
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        tooltip: 'More Actions',
                        onSelected: (action) {
                          if (action == 'add_another') {
                            _showAddAnotherRequirementDialog(req);
                          } else if (action == 'share') {
                            _showSharePropertiesDialog(req);
                          } else if (action == 'view_details') {
                            _showRequirementDetailDrawer(req);
                          } else if (action == 'edit') {
                            _showAddEditDialog(req);
                          } else if (action == 'delete') {
                            _showDeleteConfirmDialog(req);
                          } else if (action == 'upload_doc') {
                            final isRent = req.listingTypeName?.toLowerCase().contains('rent') ?? false;
                            context.go(
                              isRent ? '/rental-library' : '/resale-library',
                              extra: {
                                'autoOpenUpload': true,
                                'clientName': req.clientName,
                              },
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view_details',
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('View Details'),
                              ],
                            ),
                          ),
                          if (!isClosed && !_isLeadTransferredAway(req, currentUser))
                            const PopupMenuItem(
                              value: 'add_another',
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle_outline_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Add Another'),
                                ],
                              ),
                            ),
                          if (!isClosed)
                            const PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(Icons.share_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Share Properties'),
                                ],
                              ),
                            ),
                          if (isWon)
                            const PopupMenuItem(
                              value: 'upload_doc',
                              child: Row(
                                children: [
                                  Icon(Icons.upload_file_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Upload Document'),
                                ],
                              ),
                            ),
                          if (!isClosed && _hasEditAccess(req, currentUser)) ...[
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                          ],
                          if (_hasEditAccess(req, currentUser) || currentUser?.role == 'Super Admin' || currentUser?.role == 'Admin') ...[
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: CRMColors.danger),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: CRMColors.danger)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        );
      },
    );
      },
    );
  }

  Widget _buildWonSearchAndFiltersCard(List<RequirementModel> requirements) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    String configDropdownLabel = 'BHK';
    final selectedCat = _metadata?.categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => LookupItem(id: '', name: ''),
    );
    final catName = selectedCat?.name.toLowerCase() ?? '';
    List<LookupItem> specLookupItems = [];

    if (catName.contains('commercial')) {
      configDropdownLabel = 'Property Type';
      var filtered = _metadata?.types.where((t) => t.categoryId == _selectedCategoryId).toList() ?? [];
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.types.where((t) {
          final n = t.name.toLowerCase();
          return n.contains('office') || n.contains('shop') || n.contains('showroom') || n.contains('commercial');
        }).toList();
      }
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.types;
      }
      specLookupItems = filtered;
    } else if (catName.contains('land') || catName.contains('plot')) {
      configDropdownLabel = 'Property Type';
      var filtered = _metadata?.types.where((t) => t.categoryId == _selectedCategoryId).toList() ?? [];
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.types.where((t) {
          final n = t.name.toLowerCase();
          return n.contains('plot') || n.contains('land');
        }).toList();
      }
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.types;
      }
      specLookupItems = filtered;
    } else if (catName.contains('industrial')) {
      configDropdownLabel = 'Property Type';
      var filtered = _metadata?.types.where((t) => t.categoryId == _selectedCategoryId).toList() ?? [];
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.types.where((t) {
          final n = t.name.toLowerCase();
          return n.contains('warehouse') || n.contains('shed') || n.contains('industrial');
        }).toList();
      }
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.types;
      }
      specLookupItems = filtered;
    } else {
      configDropdownLabel = 'BHK';
      var filtered = _metadata?.configurations.where((c) => _selectedCategoryId == null || c.categoryId == _selectedCategoryId).toList() ?? [];
      if (filtered.isEmpty && _metadata != null) {
        filtered = _metadata!.configurations;
      }
      specLookupItems = filtered;
    }

    return CRMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _wonSearchController,
                  style: CRMTypography.body.copyWith(color: CRMColors.text),
                  decoration: InputDecoration(
                    hintText: 'Search won clients by name, mobile, specs...',
                    hintStyle: CRMTypography.body.copyWith(color: CRMColors.textMuted),
                    prefixIcon: Icon(Icons.search_rounded, color: CRMColors.textMuted),
                    filled: true,
                    fillColor: CRMColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      borderSide: BorderSide(color: CRMColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      borderSide: BorderSide(color: CRMColors.border),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              CRMButton(
                label: "Search",
                onPressed: () => setState(() {}),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          Wrap(
            spacing: CRMSpacing.m,
            runSpacing: CRMSpacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildDropdownFilter<String?>(
                label: 'Category',
                value: _selectedCategoryId,
                items: [
                  const DropdownMenuItem(value: null, child: Text("All Categories")),
                  ...?_metadata?.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                ],
                isMobile: isMobile,
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                    _wonConfigurationIds.clear();
                  });
                },
              ),
              SizedBox(
                width: isMobile ? double.infinity : 200,
                child: CRMMultiSelectDropdown(
                  label: configDropdownLabel,
                  selectedIds: _wonConfigurationIds,
                  items: specLookupItems,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              CRMButton(
                label: "Clear Filters",
                variant: CRMButtonVariant.outline,
                onPressed: () {
                  setState(() {
                    _wonSearchController.clear();
                    _wonConfigurationIds.clear();
                    _wonCategoryId = null;
                    _wonPropertyTypeId = null;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyWonFiltersAndTable() {
    final reqBlocState = context.read<RequirementsBloc>().state;
    final isLoading = reqBlocState is RequirementsLoading;

    final authState = context.read<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;

    List<RequirementModel> requirements = _cachedRequirements;

    requirements = requirements.where((r) => _isLeadWon(r)).toList();

    if (currentUser != null && currentUser.role == 'Sales') {
      requirements = requirements.where((r) => _salesCanViewRequirement(r, currentUser)).toList();
    }

    if (_selectedCategoryId != null && _selectedCategoryId!.isNotEmpty) {
      requirements = requirements.where((r) => r.categoryId == _selectedCategoryId).toList();
    }

    final selectedCat = _metadata?.categories.firstWhereOrNull((c) => c.id == _selectedCategoryId);
    final catName = selectedCat?.name.toLowerCase() ?? '';
    final isPropertyTypeFilter = catName.contains('commercial') ||
        catName.contains('land') ||
        catName.contains('plot') ||
        catName.contains('industrial');

    if (_wonConfigurationIds.isNotEmpty) {
      requirements = requirements.where((r) {
        if (isPropertyTypeFilter) {
          return _wonConfigurationIds.contains(r.propertyTypeId) ||
              _wonConfigurationIds.any((id) => r.propertyTypeIds.contains(id));
        } else {
          return (r.configurationId != null && _wonConfigurationIds.contains(r.configurationId)) ||
              _wonConfigurationIds.any((id) => r.configurationIds.contains(id));
        }
      }).toList();
    }

    final query = _wonSearchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      requirements = requirements.where((r) {
        final clientName = r.clientName.toLowerCase();
        final clientMobile = r.clientMobile.toLowerCase();
        final specs = '${r.propertyTypeName} ${r.configurationName ?? ""} ${r.listingTypeName ?? ""} ${r.categoryName ?? ""}'.toLowerCase();
        final remarks = (r.remarks ?? '').toLowerCase();
        final areas = r.areaNames.join(' ').toLowerCase();

        bool matchesSalesman = false;
        if (currentUser != null && (currentUser.role == 'Admin' || currentUser.role == 'Super Admin' || currentUser.role == 'Telecaller')) {
          final creator = (r.creatorName ?? '').toLowerCase();
          final assignee = (r.assigneeName ?? '').toLowerCase();
          matchesSalesman = creator.contains(query) || assignee.contains(query);
        }

        return clientName.contains(query) ||
            clientMobile.contains(query) ||
            specs.contains(query) ||
            remarks.contains(query) ||
            areas.contains(query) ||
            matchesSalesman;
      }).toList();
    }

    requirements.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final totalCount = requirements.length;
    final totalPages = (totalCount / _requirementsPerPage).ceil();
    final currentPage = _currentPage.clamp(1, totalPages > 0 ? totalPages : 1);

    final startIndex = (currentPage - 1) * _requirementsPerPage;
    final endIndex = (startIndex + _requirementsPerPage).clamp(0, totalCount);

    final pageItems = (startIndex < totalCount)
        ? requirements.sublist(startIndex, endIndex)
        : <RequirementModel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildWonSearchAndFiltersCard(requirements),
        const SizedBox(height: CRMSpacing.l),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            if (isMobile || !_isTableView) {
              return _buildRequirementCards(pageItems, isLoading, currentUser, currentPage, totalPages, totalCount);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CRMDataTable(
                  isLoading: isLoading,
                  emptyTitle: 'No Won Requirements Found',
                  emptyDescription: 'Requirements marked as Won or Closed will appear here.',
                  dataRowMinHeight: 88.0,
                  dataRowMaxHeight: 160.0,
                  columnSpacing: 10.0,
                  horizontalMargin: 12.0,
                  columns: [
                    const DataColumn(label: Text('Client')),
                    if (currentUser != null && (currentUser.role == 'Super Admin' || currentUser.role == 'Admin' || currentUser.role == 'Telecaller'))
                      const DataColumn(label: Text('Added By')),
                    const DataColumn(label: Text('Assign to')),
                    const DataColumn(label: Text('Specs / Config')),
                    const DataColumn(label: Text('Budget Range')),
                    const DataColumn(label: Text('Target Area(s)')),
                    const DataColumn(label: Text('Status')),
                    const DataColumn(label: Text('Matches')),
                    const DataColumn(label: Text('Actions')),
                  ],
                  rows: pageItems.map((req) {
                    final isHighlighted = req.id == _highlightedRequirementId;
                    final bool isClosed = _isLeadClosedOrTerminal(req);
                    final bool isWon = _isLeadWon(req);
                    return DataRow(
                      color: isHighlighted
                          ? WidgetStateProperty.all(CRMColors.primaryOf(context).withOpacity(0.12))
                          : WidgetStateProperty.all(CRMColors.sidebarBgOf(context).withValues(alpha: 0.6)),
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 135,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => _showRequirementDetailDrawer(req),
                                  child: Text(
                                    req.clientName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CRMTypography.bodyMedium.copyWith(
                                      color: CRMColors.primary,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  req.clientMobile,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Added: ${DateFormat('dd/MM/yyyy').format(req.createdAt)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (currentUser != null && (currentUser.role == 'Super Admin' || currentUser.role == 'Admin' || currentUser.role == 'Telecaller'))
                          DataCell(
                            Text(
                              _getAddedByColumnName(req),
                              style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        DataCell(
                          Text(
                            _getSalesmanName(req, currentUser),
                            style: CRMTypography.caption.copyWith(
                              color: CRMColors.textSecondaryOf(context).withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataCell(_buildSpecsConfigCell(req)),
                        DataCell(
                          Text(
                            '${BudgetFormatter.format(req.minBudget)} - ${BudgetFormatter.format(req.maxBudget)}',
                            style: CRMTypography.bodyMedium.copyWith(color: CRMColors.primaryOf(context)),
                          ),
                        ),
                        DataCell(_buildTargetAreasCell(req)),
                        DataCell(
                          _buildStatusControlWithNotes(req, currentUser),
                        ),
                        DataCell(
                          isClosed
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isWon
                                        ? CRMColors.success.withValues(alpha: 0.12)
                                        : CRMColors.danger.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isWon
                                          ? CRMColors.success.withValues(alpha: 0.3)
                                          : CRMColors.danger.withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isWon ? Icons.verified_rounded : Icons.block_rounded,
                                        size: 13,
                                        color: isWon ? CRMColors.success : CRMColors.danger,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isWon ? 'Deal Won' : 'Lead Closed',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isWon ? CRMColors.success : CRMColors.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _RunMatchesButtonWithBadge(
                                  requirement: req,
                                  onPressed: () => _showMatchesDrawer(req),
                                  properties: _propertiesForMatches,
                                ),
                        ),
                        DataCell(
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded),
                            tooltip: 'More Actions',
                            onSelected: (action) {
                              if (action == 'add_another') {
                                _showAddAnotherRequirementDialog(req);
                              } else if (action == 'share') {
                                _showSharePropertiesDialog(req);
                              } else if (action == 'view_details') {
                                _showRequirementDetailDrawer(req);
                              } else if (action == 'edit') {
                                _showAddEditDialog(req);
                              } else if (action == 'delete') {
                                _showDeleteConfirmDialog(req);
                              } else if (action == 'upload_doc') {
                                final isRent = req.listingTypeName?.toLowerCase().contains('rent') ?? false;
                                context.go(
                                  isRent ? '/rental-library' : '/resale-library',
                                  extra: {
                                    'autoOpenUpload': true,
                                    'clientName': req.clientName,
                                  },
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view_details',
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                              if (!isClosed && !_isLeadTransferredAway(req, currentUser))
                                const PopupMenuItem(
                                  value: 'add_another',
                                  child: Row(
                                    children: [
                                      Icon(Icons.add_circle_outline_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text('Add Another'),
                                    ],
                                  ),
                                ),
                              if (!isClosed)
                                const PopupMenuItem(
                                  value: 'share',
                                  child: Row(
                                    children: [
                                      Icon(Icons.share_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text('Share Properties'),
                                    ],
                                  ),
                                ),
                              if (isWon)
                                const PopupMenuItem(
                                  value: 'upload_doc',
                                  child: Row(
                                    children: [
                                      Icon(Icons.upload_file_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text('Upload Document'),
                                    ],
                                  ),
                                ),
                              if (!isClosed && _hasEditAccess(req, currentUser)) ...[
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                              ],
                              if (_hasEditAccess(req, currentUser) || currentUser?.role == 'Super Admin' || currentUser?.role == 'Admin') ...[
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded, size: 18, color: CRMColors.danger),
                                      SizedBox(width: 8),
                                      Text('Delete', style: TextStyle(color: CRMColors.danger)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: CRMSpacing.m),
                _buildPagination(totalCount, totalPages, currentPage),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPagination(int totalItems, int totalPages, int currentPage) {
    final from = totalItems == 0 ? 0 : (currentPage - 1) * _requirementsPerPage + 1;
    final to = (currentPage * _requirementsPerPage).clamp(0, totalItems);
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    final infoText = Text(
      'Showing $from–$to of $totalItems',
      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
    );

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Rows:',
            style:
                CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
        const SizedBox(width: CRMSpacing.xs),
        DropdownButton<int>(
          value: _requirementsPerPage,
          underline: const SizedBox.shrink(),
          items: const [
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 25, child: Text('25')),
            DropdownMenuItem(value: 50, child: Text('50')),
          ],
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _requirementsPerPage = val;
              _currentPage = 1;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed:
              currentPage > 1 ? () => setState(() => _currentPage--) : null,
        ),
        Text(
          '$currentPage / $totalPages',
          style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: currentPage < totalPages
              ? () => setState(() => _currentPage++)
              : null,
        ),
      ],
    );

    if (isMobile) {
      return Column(
        children: [
          infoText,
          const SizedBox(height: CRMSpacing.s),
          controls,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        infoText,
        controls,
      ],
    );
  }

  Widget _buildFollowupsPagination(int totalItems, int totalPages, int currentPage) {
    final from = totalItems == 0 ? 0 : (currentPage - 1) * _followupsPerPage + 1;
    final to = (currentPage * _followupsPerPage).clamp(0, totalItems);
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    final infoText = Text(
      'Showing $from–$to of $totalItems',
      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
    );

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Rows:',
            style:
                CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
        const SizedBox(width: CRMSpacing.xs),
        DropdownButton<int>(
          value: _followupsPerPage,
          underline: const SizedBox.shrink(),
          items: const [
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 25, child: Text('25')),
            DropdownMenuItem(value: 50, child: Text('50')),
          ],
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _followupsPerPage = val;
              _currentFollowupPage = 1;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed:
              currentPage > 1 ? () => setState(() => _currentFollowupPage--) : null,
        ),
        Text(
          '$currentPage / $totalPages',
          style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: currentPage < totalPages
              ? () => setState(() => _currentFollowupPage++)
              : null,
        ),
      ],
    );

    if (isMobile) {
      return Column(
        children: [
          infoText,
          const SizedBox(height: CRMSpacing.s),
          controls,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        infoText,
        controls,
      ],
    );
  }

  Widget _buildRequirementCards(
    List<RequirementModel> requirements,
    bool isLoading,
    UserModel? currentUser,
    int currentPage,
    int totalPages,
    int totalCount,
  ) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(CRMSpacing.m),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (requirements.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: CRMCard(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: CRMSpacing.xl),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.folder_open_rounded, size: 48, color: CRMColors.textMuted),
                const SizedBox(height: CRMSpacing.s),
                Text(
                  _activeMainTab == 'Rejected' ? 'No Rejected Leads' : 'No Requirements Found',
                  style: CRMTypography.cardTitle.copyWith(color: CRMColors.textOf(context)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: CRMSpacing.xxs),
                Text(
                  _activeMainTab == 'Rejected'
                      ? 'Leads marked as Rejected will appear here.'
                      : 'Try adjusting filters or create a new requirement pipeline.',
                  style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        if (_selectedRequirementIds.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: CRMSpacing.m),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: CRMColors.primaryOf(context).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: CRMColors.primaryOf(context).withOpacity(0.3),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _selectedRequirementIds.length == requirements.length && requirements.isNotEmpty,
                      activeColor: CRMColors.primaryOf(context),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedRequirementIds.addAll(requirements.map((r) => r.id));
                          } else {
                            _selectedRequirementIds.clear();
                          }
                        });
                      },
                    ),
                    Text(
                      '${_selectedRequirementIds.length} Lead(s) Selected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: CRMColors.textOf(context),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedRequirementIds.clear();
                        });
                      },
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Cancel'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _confirmBulkMoveToBin(requirements),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CRMColors.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text(
                        'Move to Bin',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ...requirements.map((req) {
          final String budgetText = '₹${BudgetFormatter.format(req.minBudget)} - ₹${BudgetFormatter.format(req.maxBudget)}';
          final String dateText = DateFormat("dd MMM ''yy, h:mm a").format(req.createdAt.toLocal());
          final String specsText = '${req.propertyTypeName} (${req.configurationName ?? "Any Config"})';
          final String areasText = req.areaNames.isNotEmpty ? req.areaNames.join(', ') : 'All Areas';
          final String listingType = getListingTypeLabel(req);
          final bool isSelected = _selectedRequirementIds.contains(req.id);
          final bool isHighlighted = req.id == _highlightedRequirementId;
          final bool isClosed = _isLeadClosedOrTerminal(req);
          final bool isWon = _isLeadWon(req);

          return Padding(
            padding: const EdgeInsets.only(bottom: CRMSpacing.m),
            child: CRMCard(
              borderColor: isHighlighted
                  ? CRMColors.primaryOf(context)
                  : (isClosed ? CRMColors.borderOf(context).withValues(alpha: 0.5) : null),
              backgroundColor: isHighlighted
                  ? CRMColors.primaryOf(context).withOpacity(0.08)
                  : (isClosed ? CRMColors.sidebarBgOf(context).withValues(alpha: 0.6) : null),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isClosed)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isWon
                            ? CRMColors.success.withValues(alpha: 0.12)
                            : CRMColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isWon
                              ? CRMColors.success.withValues(alpha: 0.3)
                              : CRMColors.danger.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isWon ? Icons.emoji_events_rounded : Icons.block_rounded,
                            size: 14,
                            color: isWon ? CRMColors.success : CRMColors.danger,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isWon
                                  ? 'Deal Won (Closed) • Lead is locked. Change status to reopen.'
                                  : 'Lead Closed (${req.status}) • Locked. Toggle status to reopen.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isWon ? CRMColors.success : CRMColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Top Row: Checkbox, Client Name, User badge, Share button, Status dropdown
                  Builder(
                    builder: (context) {
                      final isNarrowCard = MediaQuery.sizeOf(context).width < 700;
                      final nameBlock = Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => _showRequirementDetailDrawer(req),
                              child: Text(
                                req.clientName,
                                style: CRMTypography.sectionTitle.copyWith(
                                  color: CRMColors.primaryOf(context),
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: CRMColors.primaryOf(context).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: CRMColors.primaryOf(context).withOpacity(0.3)),
                              ),
                              child: Text(
                                req.requirementCode,
                                style: TextStyle(
                                  color: CRMColors.primaryOf(context),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (req.matchingReadiness != 'Ready')
                              _buildNeedsMoreDetailsBadge(req, compact: true),
                          ],
                        ),
                      );
                      final moreMenu = PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 18),
                        tooltip: 'More Actions',
                        onSelected: (action) {
                          if (action == 'add_another') {
                            _showAddAnotherRequirementDialog(req);
                          } else if (action == 'share') {
                            _showSharePropertiesDialog(req);
                          } else if (action == 'view_details') {
                            _showRequirementDetailDrawer(req);
                          } else if (action == 'edit') {
                            _showAddEditDialog(req);
                          } else if (action == 'delete') {
                            _showDeleteConfirmDialog(req);
                          } else if (action == 'upload_doc') {
                            final isRent = req.listingTypeName?.toLowerCase().contains('rent') ?? false;
                            context.go(
                              isRent ? '/rental-library' : '/resale-library',
                              extra: {
                                'autoOpenUpload': true,
                                'clientName': req.clientName,
                              },
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view_details',
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('View Details'),
                              ],
                            ),
                          ),
                          if (!isClosed && !_isLeadTransferredAway(req, currentUser))
                            const PopupMenuItem(
                              value: 'add_another',
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle_outline_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Add Another Requirement'),
                                ],
                              ),
                            ),
                          if (!isClosed)
                            const PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(Icons.share_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Share Properties'),
                                ],
                              ),
                            ),
                          if (isWon)
                            const PopupMenuItem(
                              value: 'upload_doc',
                              child: Row(
                                children: [
                                  Icon(Icons.upload_file_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Upload Document'),
                                ],
                              ),
                            ),
                          if (!isClosed && _hasEditAccess(req, currentUser)) ...[
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                          ],
                          if (_hasEditAccess(req, currentUser) || currentUser?.role == 'Super Admin' || currentUser?.role == 'Admin') ...[
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: CRMColors.danger),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: CRMColors.danger)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                      final checkbox = SizedBox(
                        width: 28,
                        height: 28,
                        child: Checkbox(
                          value: isSelected,
                          activeColor: CRMColors.primaryOf(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: isClosed
                              ? null
                              : (_) {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedRequirementIds.remove(req.id);
                                    } else {
                                      _selectedRequirementIds.add(req.id);
                                    }
                                  });
                                },
                        ),
                      );

                      if (isNarrowCard) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                checkbox,
                                const SizedBox(width: 6),
                                nameBlock,
                                moreMenu,
                              ],
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _buildStatusControlWithNotes(req, currentUser, compact: true),
                            ),
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                checkbox,
                                const SizedBox(width: 6),
                                nameBlock,
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStatusControlWithNotes(req, currentUser, compact: true),
                              moreMenu,
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 4),

                  // Second Line: Added Date & Time
                  Text(
                    dateText,
                    style: CRMTypography.caption.copyWith(
                      color: CRMColors.textMutedOf(context),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Third Row: Requirement Specs & Tag Pills (Listing Type, Budget, Area Specs)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        specsText,
                        style: CRMTypography.bodyMedium.copyWith(
                          color: CRMColors.textOf(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: CRMColors.sidebarBgOf(context),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.5)),
                        ),
                        child: Text(
                          listingType,
                          style: TextStyle(
                            color: CRMColors.textSecondaryOf(context),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: CRMColors.primaryOf(context).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          budgetText,
                          style: TextStyle(
                            color: CRMColors.primaryOf(context),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Fourth Row: Contact Info & WhatsApp Button & Staff Badges
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: CRMColors.primaryOf(context)),
                          const SizedBox(width: 4),
                          SelectableText(
                            req.clientMobile,
                            style: TextStyle(
                              color: CRMColors.textOf(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      if (isClosed)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 14, color: CRMColors.textSecondaryOf(context).withValues(alpha: 0.4)),
                            const SizedBox(width: 4),
                            Text(
                              'WhatsApp (Disabled)',
                              style: TextStyle(
                                color: CRMColors.textSecondaryOf(context).withValues(alpha: 0.5),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      else
                        InkWell(
                          onTap: () async {
                            final phone = req.clientMobile.replaceAll(RegExp(r'\D'), '');
                            final formattedPhone = phone.length == 10 ? '91$phone' : phone;
                            final url = "https://wa.me/$formattedPhone";
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 14, color: kWhatsAppGreen),
                              SizedBox(width: 4),
                              Text(
                                'Chat on WhatsApp',
                                style: TextStyle(
                                  color: kWhatsAppGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_add_alt_1_outlined, size: 13, color: CRMColors.textMutedOf(context)),
                          const SizedBox(width: 4),
                          Text(
                            _getAddedByDisplayLine(req),
                            style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 11.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      if (req.leadSourceDisplay != null && req.leadSourceDisplay!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              req.isMetaLead ? Icons.campaign_rounded : Icons.hub_outlined,
                              size: 13,
                              color: req.isMetaLead ? const Color(0xFF1877F2) : CRMColors.textMutedOf(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Source: ${req.leadSourceDisplay}',
                              style: TextStyle(
                                color: req.isMetaLead ? const Color(0xFF1877F2) : CRMColors.textSecondaryOf(context),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_outline_rounded, size: 13, color: CRMColors.textMutedOf(context)),
                          const SizedBox(width: 4),
                          if (!isClosed && currentUser != null && (_canInitiallyAssignLead(currentUser) || _canSalesReassignLead(currentUser)))
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Assign: ',
                                  style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 11.5, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(
                                  width: 130,
                                  child: _buildMobileAssignToDropdown(
                                    req,
                                    isReassign: _canSalesReassignLead(currentUser),
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              'Assign: ${_getSalesmanName(req, currentUser)}',
                              style: TextStyle(color: CRMColors.textSecondaryOf(context).withValues(alpha: isClosed ? 0.7 : 1.0), fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bottom Details Box (Subtle Container with Budget, Localities, Notes Link, and Run Matches Button)
                  Builder(
                    builder: (context) {
                      final String? userNote = _getCleanNote(req);
                      final bool hasNotes = userNote != null && userNote.isNotEmpty;

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: CRMColors.backgroundOf(context).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Localities Interested in:',
                                        style: TextStyle(
                                          color: CRMColors.textMutedOf(context),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        areasText,
                                        style: TextStyle(
                                          color: CRMColors.textOf(context),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                isClosed
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isWon
                                              ? CRMColors.success.withValues(alpha: 0.12)
                                              : CRMColors.danger.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isWon
                                                ? CRMColors.success.withValues(alpha: 0.3)
                                                : CRMColors.danger.withValues(alpha: 0.25),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isWon ? Icons.verified_rounded : Icons.cancel_outlined,
                                              size: 13,
                                              color: isWon ? CRMColors.success : CRMColors.danger,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isWon ? 'Deal Won' : 'Lead Closed',
                                              style: TextStyle(
                                                color: isWon ? CRMColors.success : CRMColors.danger,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : _RunMatchesButtonWithBadge(
                                        requirement: req,
                                        onPressed: () => _showMatchesDrawer(req),
                                        properties: _propertiesForMatches,
                                      ),
                              ],
                            ),
                             if (req.remarks != null && req.remarks!.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.notes_rounded,
                                    size: 14,
                                    color: CRMColors.primaryOf(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Remarks: ',
                                            style: TextStyle(
                                              color: CRMColors.textSecondaryOf(context),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: req.remarks!.trim(),
                                            style: TextStyle(
                                              color: CRMColors.textOf(context),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (hasNotes) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.sticky_note_2_outlined,
                                    size: 13,
                                    color: CRMColors.primaryOf(context),
                                  ),
                                  const SizedBox(width: 4),
                                  Builder(
                                    builder: (btnContext) {
                                      return InkWell(
                                        onTap: () => _showViewAllNotesDialog(context, req),
                                        child: Text(
                                          'View All Notes',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                            color: CRMColors.primaryOf(context),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: CRMSpacing.s),
        _buildPagination(totalCount, totalPages, currentPage),
      ],
    );
  }

  Widget _buildDetailChip(IconData icon, String label, String value, {bool isMobile = false}) {
    return Container(
      constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 160),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CRMColors.textMuted),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: CRMTypography.caption.copyWith(color: CRMColors.textMuted, fontSize: 10)),
                Text(
                  value,
                  style: CRMTypography.captionBold.copyWith(color: CRMColors.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSwitcher() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: CRMColors.sidebarBgOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: CRMColors.borderOf(context).withOpacity(0.6),
            width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              if (_isTableView) {
                setState(() => _isTableView = false);
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: !_isTableView ? CRMColors.cardBgOf(context) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: !_isTableView ? CRMShadows.small : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.view_stream_rounded,
                    size: 16,
                    color: !_isTableView ? CRMColors.primaryOf(context) : CRMColors.textMutedOf(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Cards',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: !_isTableView ? FontWeight.bold : FontWeight.normal,
                      color: !_isTableView ? CRMColors.primaryOf(context) : CRMColors.textMutedOf(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              if (!_isTableView) {
                setState(() => _isTableView = true);
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isTableView ? CRMColors.cardBgOf(context) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: _isTableView ? CRMShadows.small : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.table_chart_outlined,
                    size: 16,
                    color: _isTableView ? CRMColors.primaryOf(context) : CRMColors.textMutedOf(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Table',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _isTableView ? FontWeight.bold : FontWeight.normal,
                      color: _isTableView ? CRMColors.primaryOf(context) : CRMColors.textMutedOf(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(List<RequirementModel> requirements, UserModel? currentUser) {
    final role = currentUser?.role.toLowerCase() ?? '';
    final bool canExport = role == 'admin' || role == 'super admin' || role == 'telecaller';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          if (canExport)
            ElevatedButton.icon(
              onPressed: () => _exportLeadsToExcel(requirements, currentUser),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text(
                'Export Leads',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF217346),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 1,
              ),
            )
          else
            const SizedBox.shrink(),
          _buildViewSwitcher(),
        ],
      ),
    );
  }

  void _exportLeadsToExcel(List<RequirementModel> requirements, UserModel? currentUser) {
    if (requirements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No leads available to export.'),
          backgroundColor: CRMColors.warning,
        ),
      );
      return;
    }

    final List<String> headers = [
      'Req ID',
      'Client Name',
      'Client Mobile',
      'Category',
      'Configuration',
      'Property Types',
      'Listing Type',
      'Min Budget',
      'Max Budget',
      'Interested Areas',
      'Status',
      'Next Followup Date',
      'Added By',
      'Assigned To',
      'Notes / Remarks',
      'Created Date',
    ];

    final StringBuffer csvBuffer = StringBuffer();
    // UTF-8 BOM so Excel opens with UTF-8 encoding and auto column split
    csvBuffer.write('\uFEFF');
    csvBuffer.writeln(headers.map((h) => '"${h.replaceAll('"', '""')}"').join(','));

    for (final req in requirements) {
      final row = [
        req.requirementCode,
        req.clientName,
        req.clientMobile,
        req.categoryName ?? '',
        req.configurationName ?? '',
        req.propertyTypeName ?? '',
        req.listingTypeName ?? '',
        BudgetFormatter.format(req.minBudget),
        BudgetFormatter.format(req.maxBudget),
        req.areaNames.join('; '),
        req.status,
        req.nextFollowupDate != null && req.nextFollowupDate!.isNotEmpty
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(req.nextFollowupDate!).toLocal())
            : '',
        (req.creatorName != null && req.creatorName != 'System' && req.creatorName!.trim().isNotEmpty) ? req.creatorName! : 'Propkart Admin',
        _getSalesmanName(req, currentUser),
        _getCleanNote(req) ?? '',
        req.createdAt != null ? DateFormat('dd/MM/yyyy hh:mm a').format(req.createdAt!.toLocal()) : '',
      ];

      csvBuffer.writeln(row.map((val) => '"${val.toString().replaceAll('"', '""')}"').join(','));
    }

    final bytes = utf8.encode(csvBuffer.toString());
    final filename = 'Leads_Export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    FileDownloader.download(bytes, filename);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${requirements.length} leads exported to Excel format successfully!'),
        backgroundColor: CRMColors.success,
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.startsWith('Rejected')) return CRMColors.danger;
    if (status.startsWith('Call Attempted') || status.startsWith('Call attempted')) return const Color(0xFF0288D1);
    switch (status) {
      case 'Assigned':
        return const Color(0xFF0F766E);
      case 'Won':
        return CRMColors.success;
      case 'Follow-up':
      case 'Re-Followup':
        return CRMColors.warning;
      case 'Interested':
      case 'Active':
      case 'Live':
        return CRMColors.info;
      case 'Site Visit':
      case 'Site Visit Sche.':
      case 'Site Visit Done':
        return Colors.purple;
      case 'Negotiation':
        return Colors.orange;
      case 'Bin':
      case 'Not Interested':
      case 'Dead':
      case 'Suspended':
      case 'Rejected':
        return CRMColors.danger;
      case 'New':
      case 'Not Started':
      default:
        return CRMColors.primary;
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: color, size: 16),
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        style: IconButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildMainViewTabButton(String label) {
    final isSelected = _activeMainTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeMainTab = label;
        });
        // My Won needs an unfiltered status fetch so Won rows are present.
        if (label == 'My Won' ||
            label == 'Rejected' ||
            label == 'Leads' ||
            label == 'Requirements' ||
            label == 'Leads Added by Me') {
          _triggerFetch();
        }
      },
      child: AnimatedContainer(
        duration: CRMMotion.fast,
        curve: CRMMotion.easeInOut,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? CRMColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
        ),
        child: Text(
          label,
          style: CRMTypography.bodyMedium.copyWith(
            color: isSelected ? Colors.white : CRMColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showFollowupMessageDialog(BuildContext context, String clientName, String message, {DashboardFollowup? followup}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: CRMColors.cardBgOf(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
          title: Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded, color: CRMColors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Follow-up Agenda ($clientName)",
                  style: CRMTypography.sectionTitle.copyWith(
                    color: CRMColors.textOf(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 300),
            padding: const EdgeInsets.all(CRMSpacing.m),
            decoration: BoxDecoration(
              color: CRMColors.backgroundOf(context),
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              border: Border.all(color: CRMColors.borderOf(context).withValues(alpha: 0.6)),
            ),
            child: SingleChildScrollView(
              child: Text(
                message,
                style: CRMTypography.bodyMedium.copyWith(
                  color: CRMColors.textOf(context),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ),
          actions: [
            if (followup != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                label: const Text("Edit Follow-up"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: CRMColors.primary,
                  side: BorderSide(color: CRMColors.primary.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _showEditFollowupDialog(context, followup);
                },
              ),
            CRMButton(
              label: "Close",
              variant: CRMButtonVariant.primary,
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
        );
      },
    );
  }

  void _showEditFollowupDialog(BuildContext context, DashboardFollowup followup) {
    final DateTime initialDateTime = DateTime.tryParse(followup.followupDate)?.toLocal() ?? DateTime.now();
    DateTime selectedDate = DateTime(initialDateTime.year, initialDateTime.month, initialDateTime.day);
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(initialDateTime);
    final notesController = TextEditingController(text: followup.notes ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dateDisplay = DateFormat('dd/MM/yyyy').format(selectedDate);
            final timeDisplay = selectedTime.format(context);

            return AlertDialog(
              backgroundColor: CRMColors.cardBgOf(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
              title: Row(
                children: [
                  Icon(Icons.edit_calendar_rounded, color: CRMColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Edit Follow-up (${followup.clientName})",
                      style: CRMTypography.sectionTitle.copyWith(
                        color: CRMColors.textOf(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Date & Time",
                        style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: isSaving
                                  ? null
                                  : () async {
                                      final pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2035),
                                      );
                                      if (pickedDate != null) {
                                        setDialogState(() {
                                          selectedDate = pickedDate;
                                        });
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: CRMColors.backgroundOf(context),
                                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                                  border: Border.all(color: CRMColors.borderOf(context)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded, size: 16, color: CRMColors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      dateDisplay,
                                      style: TextStyle(
                                        color: CRMColors.textOf(context),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: isSaving
                                  ? null
                                  : () async {
                                      final pickedTime = await showTimePicker(
                                        context: context,
                                        initialTime: selectedTime,
                                      );
                                      if (pickedTime != null) {
                                        setDialogState(() {
                                          selectedTime = pickedTime;
                                        });
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: CRMColors.backgroundOf(context),
                                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                                  border: Border.all(color: CRMColors.borderOf(context)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 16, color: CRMColors.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      timeDisplay,
                                      style: TextStyle(
                                        color: CRMColors.textOf(context),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Remarks / Agenda",
                        style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesController,
                        enabled: !isSaving,
                        maxLines: 4,
                        style: TextStyle(color: CRMColors.textOf(context), fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Enter follow-up agenda or notes...",
                          hintStyle: TextStyle(color: CRMColors.textMutedOf(context)),
                          filled: true,
                          fillColor: CRMColors.backgroundOf(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                            borderSide: BorderSide(color: CRMColors.borderOf(context)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                            borderSide: BorderSide(color: CRMColors.borderOf(context)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                            borderSide: BorderSide(color: CRMColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: Text("Cancel", style: TextStyle(color: CRMColors.textMutedOf(context))),
                ),
                CRMButton(
                  label: isSaving ? "Saving..." : "Save Changes",
                  prefixIcon: isSaving ? null : Icons.check_rounded,
                  variant: CRMButtonVariant.primary,
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            final combined = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                            final isoUtcString = combined.toUtc().toIso8601String();

                            final newNotes = notesController.text.trim();

                            // Try remote patch if valid server ID (non-local)
                            if (!followup.id.startsWith('local_') && !followup.id.startsWith('sv_') && followup.id.isNotEmpty) {
                              try {
                                await DioClient.dio.patch(
                                  '/followups/${followup.id}',
                                  data: {
                                    'followup_date': isoUtcString,
                                    'notes': newNotes,
                                  },
                                );
                              } catch (e) {
                                debugPrint('⚠️ Remote update patch error (falling back to local): $e');
                              }
                            }

                            // Update local memory cache & persistent database
                            try {
                              for (final fl in FollowupLocalRepository.inMemory.values) {
                                if ((followup.requirementId != null && followup.requirementId!.isNotEmpty && fl.requirementId == followup.requirementId) ||
                                    (fl.clientName.isNotEmpty && fl.clientName.trim().toLowerCase() == followup.clientName.trim().toLowerCase()) ||
                                    fl.id == followup.id) {
                                  fl.followupDate = combined;
                                  fl.notes = newNotes;
                                }
                              }

                              final localItem = FollowupLocalRepository.inMemory[followup.id];
                              if (localItem != null) {
                                localItem.followupDate = combined;
                                localItem.notes = newNotes;
                                await RepositoryCoordinator().followupLocal.saveFollowups([localItem]);
                              } else {
                                final authState = context.read<AuthBloc>().state;
                                final currentUser = authState is Authenticated ? authState.user : null;

                                final newLocal = FollowupLocal()
                                  ..id = followup.id.isNotEmpty ? followup.id : 'local_${DateTime.now().millisecondsSinceEpoch}'
                                  ..requirementId = followup.requirementId ?? ''
                                  ..clientName = followup.clientName
                                  ..mobile = followup.mobile
                                  ..followupDate = combined
                                  ..notes = newNotes
                                  ..status = followup.status.isNotEmpty ? followup.status : (_selectedMainFollowupSection == 'Site Visit Scheduled' ? 'Site Visit Scheduled' : 'Pending')
                                  ..createdBy = followup.creatorName ?? currentUser?.fullName ?? 'Propkart Admin'
                                  ..createdAt = DateTime.now();

                                await RepositoryCoordinator().followupLocal.saveFollowups([newLocal]);
                              }

                              // Update requirement local nextFollowupDate
                              final reqId = (followup.requirementId != null && followup.requirementId!.isNotEmpty) ? followup.requirementId! : followup.id;
                              if (reqId.isNotEmpty) {
                                try {
                                  final reqLocal = await RepositoryCoordinator().requirementLocal.getRequirementById(reqId);
                                  if (reqLocal != null) {
                                    reqLocal.nextFollowupDate = isoUtcString;
                                    await RepositoryCoordinator().requirementLocal.saveRequirements([reqLocal]);
                                  }
                                } catch (_) {}
                              }
                            } catch (e) {
                              debugPrint('⚠️ Local storage save error: $e');
                            }

                            if (mounted) {
                              Navigator.pop(dialogContext);
                              setState(() {
                                _refreshFollowupsFuture();
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_selectedMainFollowupSection == 'Site Visit Scheduled' ? 'Site Visit updated successfully' : 'Follow-up updated successfully'),
                                  backgroundColor: CRMColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              setDialogState(() {
                                isSaving = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error updating follow-up: $e'),
                                  backgroundColor: CRMColors.danger,
                                ),
                              );
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openFollowupStepper(RequirementModel req, String status, {int initialStep = 1, bool? isSiteVisit}) {
    final bool isSiteVisitMode = isSiteVisit ?? (status == 'Site Visit Scheduled' || _selectedMainFollowupSection == 'Site Visit Scheduled');
    final bool isReFollowup = status == 'Re-Followup' ||
        req.status == 'Follow-up' ||
        req.status == 'Re-Followup' ||
        req.nextFollowupDate != null;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: isSiteVisitMode ? 'Site Visit Scheduled' : 'Re-Followup',
      barrierColor: Colors.black.withValues(alpha: 0.12),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, anim1, anim2) {
        return RequirementStepperDialog(
          requirement: req,
          initialStep: initialStep,
          isSiteVisit: isSiteVisitMode,
          onSavedWithDate: (scheduledDate) {
            final now = DateTime.now();
            final todayDate = DateTime(now.year, now.month, now.day);
            final targetDay = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
            if (targetDay.isBefore(todayDate)) {
              _selectedFollowupSubTab = 'Due';
            } else if (targetDay.isAfter(todayDate)) {
              _selectedFollowupSubTab = 'Future';
            } else {
              _selectedFollowupSubTab = 'Today';
            }
            _currentFollowupPage = 1;
          },
          onSaved: () {
            if (isReFollowup) {
              NotificationCenter.addNotification(
                title: isSiteVisitMode ? 'Site Visit Scheduled' : 'Re-Followup Scheduled',
                message: isSiteVisitMode
                    ? 'Site Visit scheduled for ${req.clientName}. Notification reminder active.'
                    : 'Re-Followup scheduled for ${req.clientName}. Notification reminder active.',
                type: isSiteVisitMode ? 'sitevisit' : 'refollowup',
              );
            }
            _triggerFetch();
          },
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildFollowupStatusActionCell(DashboardFollowup f, RequirementModel? reqModel) {
    final targetReq = reqModel ?? RequirementModel(
      id: (f.requirementId != null && f.requirementId!.isNotEmpty) ? f.requirementId! : (f.id.isNotEmpty ? f.id : 'temp_req'),
      clientName: f.clientName,
      clientMobile: f.mobile,
      categoryId: '',
      categoryName: '',
      propertyTypeId: '',
      propertyTypeName: (f.propertyTitle != null && f.propertyTitle!.isNotEmpty) ? f.propertyTitle! : '',
      minBudget: 0.0,
      maxBudget: 0.0,
      areaIds: const [],
      areaNames: const [],
      status: f.status.isNotEmpty ? f.status : 'Re-Followup',
      remarks: null,
      createdAt: DateTime.now(),
    );

    if (_selectedFollowupSubTab == 'AllClients') {
      final historyBtn = OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          side: BorderSide(color: CRMColors.primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: Icon(Icons.history_rounded, size: 16, color: CRMColors.primary),
        label: Text(
          'History',
          style: CRMTypography.captionBold.copyWith(color: CRMColors.primary),
        ),
        onPressed: () => _openFollowupStepper(targetReq, targetReq.status ?? 'Re-Followup', initialStep: 2),
      );

      final authState = context.read<AuthBloc>().state;
      final currentUser = authState is Authenticated ? authState.user : null;
      final isAdminOrSuperAdmin = currentUser != null &&
          (currentUser.role == 'Admin' || currentUser.role == 'Super Admin');

      if (!isAdminOrSuperAdmin) {
        return historyBtn;
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          historyBtn,
          const SizedBox(width: 8),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 20),
            tooltip: _selectedMainFollowupSection == 'Site Visit Scheduled' ? 'Delete Client Site Visit' : 'Delete Client Follow-ups',
            onPressed: () => _confirmAndDeleteClientFollowup(f, reqModel),
          ),
        ],
      );
    }

    return _FollowupActionButton(
      followup: f,
      reqModel: targetReq,
      isSiteVisit: _selectedMainFollowupSection == 'Site Visit Scheduled',
      onSelect: (req, status) {
        if (status == 'Edit Followup' || status == 'Edit Site Visit') {
          _showEditFollowupDialog(context, f);
        } else if (status == 'Re-scheduled') {
          _openFollowupStepper(req, 'Site Visit Scheduled');
        } else if (status == 'Interested' || status.startsWith('Rejected')) {
          _changeStatus(req, status);
        } else {
          _openFollowupStepper(req, status);
        }
      },
    );
  }

  Widget _buildMobileFollowupCard(DashboardFollowup f, List<RequirementModel> reqsList) {
    final parsed = DateTime.tryParse(f.followupDate)?.toLocal();
    final displayDate = parsed != null
        ? DateFormat('dd/MM/yyyy  hh:mm a').format(parsed)
        : f.followupDate;

    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final isHighRole = currentUser != null &&
        (currentUser.role == 'Admin' || currentUser.role == 'Super Admin' || currentUser.role == 'Telecaller');
    final reqModel = reqsList.firstWhereOrNull((r) =>
        (f.requirementId != null && f.requirementId!.isNotEmpty && r.id == f.requirementId) ||
        (f.mobile.isNotEmpty && r.clientMobile.replaceAll(RegExp(r'\D'), '') == f.mobile.replaceAll(RegExp(r'\D'), '')) ||
        (f.clientName.isNotEmpty && r.clientName.trim().toLowerCase() == f.clientName.trim().toLowerCase()));

    return Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(
          color: CRMColors.borderOf(context).withValues(alpha: 0.6),
          width: 1.0,
        ),
        boxShadow: CRMShadows.small,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        onTap: () {
          if (reqModel != null) {
            _showRequirementDetailDrawer(reqModel);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Associated requirement details not found.')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(CRMSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      f.clientName,
                      style: CRMTypography.sectionTitle.copyWith(
                        color: CRMColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                        color: CRMColors.primary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        tooltip: 'Edit Follow-up',
                        onPressed: () => _showEditFollowupDialog(context, f),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: CRMColors.textSecondaryOf(context),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              if (isHighRole) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 13, color: CRMColors.textSecondaryOf(context)),
                    const SizedBox(width: 4),
                    Text(
                      'Added by: ${f.creatorName ?? (reqModel != null ? _getSalesmanName(reqModel, currentUser) : "N/A")}',
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textSecondaryOf(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: CRMSpacing.s),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: CRMSpacing.s),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_outlined, size: 14, color: CRMColors.textSecondaryOf(context)),
                      const SizedBox(width: 4),
                      Text(
                        f.mobile,
                        style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _showEditFollowupDialog(context, f),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: CRMColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            displayDate,
                            style: CRMTypography.bodyMedium.copyWith(
                              color: CRMColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit_outlined, size: 12, color: CRMColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (f.notes != null && f.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: CRMSpacing.s),
                GestureDetector(
                  onTap: () => _showFollowupMessageDialog(context, f.clientName, f.notes!, followup: f),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(CRMSpacing.s),
                    decoration: BoxDecoration(
                      color: CRMColors.backgroundOf(context),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes_rounded, size: 14, color: CRMColors.textSecondaryOf(context)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            f.notes!,
                            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getFollowupClientKey(DashboardFollowup f) {
    if (f.requirementId != null && f.requirementId!.isNotEmpty) {
      return f.requirementId!;
    }
    if (f.id.isNotEmpty) {
      return f.id;
    }
    return '${f.clientName}_${f.mobile}';
  }

  Future<void> _confirmAndDeleteClientFollowup(DashboardFollowup f, RequirementModel? reqModel) async {
    final isSiteVisit = _selectedMainFollowupSection == 'Site Visit Scheduled';
    final titleText = isSiteVisit ? 'Delete Site Visit' : 'Delete Follow-ups';
    final contentText = isSiteVisit
        ? 'Are you sure you want to delete all scheduled site visits for client "${f.clientName}" from the database?'
        : 'Are you sure you want to delete all follow-ups for client "${f.clientName}" from the database?';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: CRMColors.danger, size: 22),
            const SizedBox(width: 8),
            Text(titleText),
          ],
        ),
        content: Text(contentText, style: TextStyle(fontSize: 13.5, color: CRMColors.textOf(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CRMColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final reqId = reqModel?.id ?? f.requirementId;
      final endpoint = isSiteVisit ? '/site_visits/delete-client' : '/followups/delete-client';
      
      await DioClient.dio.post(endpoint, data: {
        'requirement_id': reqId,
        'mobile': f.mobile,
        'client_name': f.clientName,
      });

      if (mounted) {
        _selectedFollowupClientKeys.remove(_getFollowupClientKey(f));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All records for "${f.clientName}" deleted successfully.'),
            backgroundColor: CRMColors.success,
          ),
        );
        context.read<RequirementsBloc>().add(FetchRequirementsEvent());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete client records: $e'),
            backgroundColor: CRMColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _confirmAndDeleteSelectedClients(List<DashboardFollowup> pageItems, List<RequirementModel> reqsList) async {
    final selectedCount = _selectedFollowupClientKeys.length;
    if (selectedCount == 0) return;

    final isSiteVisit = _selectedMainFollowupSection == 'Site Visit Scheduled';
    final titleText = isSiteVisit ? 'Delete Selected Site Visits' : 'Delete Selected Client Follow-ups';
    final contentText = 'Are you sure you want to delete all records for the $selectedCount selected client(s) from the database? This action cannot be undone.';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: CRMColors.danger, size: 22),
            const SizedBox(width: 8),
            Text(titleText),
          ],
        ),
        content: Text(contentText, style: TextStyle(fontSize: 13.5, color: CRMColors.textOf(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CRMColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Selected'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final itemsToDelete = pageItems.where((f) => _selectedFollowupClientKeys.contains(_getFollowupClientKey(f))).toList();
    int successCount = 0;

    for (final f in itemsToDelete) {
      try {
        final reqModel = reqsList.firstWhereOrNull((r) =>
            (f.requirementId != null && f.requirementId!.isNotEmpty && r.id == f.requirementId) ||
            (f.mobile.isNotEmpty && r.clientMobile.replaceAll(RegExp(r'\D'), '') == f.mobile.replaceAll(RegExp(r'\D'), '')) ||
            (f.clientName.isNotEmpty && r.clientName.trim().toLowerCase() == f.clientName.trim().toLowerCase()));

        final reqId = reqModel?.id ?? f.requirementId;
        final endpoint = isSiteVisit ? '/site_visits/delete-client' : '/followups/delete-client';

        await DioClient.dio.post(endpoint, data: {
          'requirement_id': reqId,
          'mobile': f.mobile,
          'client_name': f.clientName,
        });

        _selectedFollowupClientKeys.remove(_getFollowupClientKey(f));
        successCount++;
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount client(s) deleted successfully.'),
          backgroundColor: CRMColors.success,
        ),
      );
      context.read<RequirementsBloc>().add(FetchRequirementsEvent());
    }
  }

  Widget _buildFollowupsView() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final dateStr = _reqFollowupDateFilter != null
        ? DateFormat('dd/MM/yyyy').format(_reqFollowupDateFilter!)
        : 'All Dates';

    final dateFilterWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CRMColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CRMColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_rounded, color: CRMColors.primary, size: 14),
          const SizedBox(width: 6),
          Text(
            dateStr,
            style: CRMTypography.captionBold.copyWith(color: CRMColors.primary),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(Icons.edit_calendar_rounded, color: CRMColors.primary, size: 16),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _reqFollowupDateFilter ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() {
                  _reqFollowupDateFilter = picked;
                  _refreshFollowupsFuture();
                });
              }
            },
            tooltip: 'Filter by Date',
          ),

        ],
      ),
    );

    return CRMCard(
      title: _selectedMainFollowupSection == 'Site Visit Scheduled'
          ? 'Site Visit Management'
          : 'Follow-ups Management',
      subtitle: 'Scheduled client communications and appointments',
      headerAction: isMobile ? null : dateFilterWidget,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMobile) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: dateFilterWidget,
            ),
            const SizedBox(height: CRMSpacing.m),
          ],
          // Mode Toggle Buttons: "Follow ups" & "Site Visit Scheduled"
          Container(
            margin: const EdgeInsets.only(bottom: CRMSpacing.m),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: CRMColors.backgroundOf(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CRMColors.borderOf(context).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMainFollowupSection = 'Follow ups';
                        _currentFollowupPage = 1;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedMainFollowupSection == 'Follow ups'
                            ? CRMColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.phone_in_talk_rounded,
                              size: 16,
                              color: _selectedMainFollowupSection == 'Follow ups'
                                  ? Colors.white
                                  : CRMColors.textSecondaryOf(context),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Follow ups',
                              style: CRMTypography.bodyMedium.copyWith(
                                color: _selectedMainFollowupSection == 'Follow ups'
                                    ? Colors.white
                                    : CRMColors.textSecondaryOf(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMainFollowupSection = 'Site Visit Scheduled';
                        _currentFollowupPage = 1;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedMainFollowupSection == 'Site Visit Scheduled'
                            ? const Color(0xFF6C5CE7)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: _selectedMainFollowupSection == 'Site Visit Scheduled'
                                  ? Colors.white
                                  : CRMColors.textSecondaryOf(context),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Site Visit Scheduled',
                              style: CRMTypography.bodyMedium.copyWith(
                                color: _selectedMainFollowupSection == 'Site Visit Scheduled'
                                    ? Colors.white
                                    : CRMColors.textSecondaryOf(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<List<dynamic>>(
            future: _followupsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final dashboardData = snapshot.data?[0] as DashboardData?;
              final reqsList = _withLocalRequirementOverrides(
                snapshot.data?[1] as List<RequirementModel>? ?? [],
              );

              final serverFollowups = dashboardData?.followups ?? [];
              final localFollowups = FollowupLocalRepository.inMemory.values.map((fl) => fl.toModel()).toList();
              final followups = [
                ...localFollowups,
                ...serverFollowups,
              ];

              final now = DateTime.now();
              final todayDate = DateTime(now.year, now.month, now.day);

              bool isSameMobile(String m1, String m2) {
                final d1 = m1.replaceAll(RegExp(r'\D'), '');
                final d2 = m2.replaceAll(RegExp(r'\D'), '');
                if (d1.isEmpty || d2.isEmpty) return false;
                if (d1 == d2) return true;
                final s1 = d1.length >= 10 ? d1.substring(d1.length - 10) : d1;
                final s2 = d2.length >= 10 ? d2.substring(d2.length - 10) : d2;
                return s1 == s2;
              }

              bool isSiteVisitStatus(String statusStr) {
                final s = statusStr.trim().toLowerCase();
                if (s.contains('done')) return false;
                return s.contains('site visit') || s.contains('sitevisit') || s == 'sv' || s.startsWith('site visit');
              }

              bool isFollowupStatus(String statusStr) {
                final s = statusStr.trim().toLowerCase();
                return s == 'follow-up' || s == 'followup' || s == 're-followup' || s == 'refollowup' || s == 'pending';
              }

              final List<DashboardFollowup> todayFollowups = [];
              final List<DashboardFollowup> dueFollowups = [];
              final List<DashboardFollowup> futureFollowups = [];
              final List<DashboardFollowup> allClientsFollowups = [];

              if (_selectedMainFollowupSection == 'Site Visit Scheduled') {
                final Map<String, DashboardFollowup> siteVisitsMap = {};

                // 1. Check reqsList for Site Visit status
                for (final req in reqsList) {
                  final reqStatus = req.status;
                  if (!isSiteVisitStatus(reqStatus)) continue;
                  if (getListingTypeLabel(req) != _activeListingTab) continue;

                  if (isSiteVisitStatus(reqStatus)) {
                    final matchingFollowups = followups.where((f) =>
                        (f.requirementId != null && f.requirementId!.isNotEmpty && req.id == f.requirementId) ||
                        (f.mobile.isNotEmpty && req.clientMobile.isNotEmpty && isSameMobile(req.clientMobile, f.mobile)) ||
                        (f.clientName.isNotEmpty && req.clientName.trim().toLowerCase() == f.clientName.trim().toLowerCase())
                    ).toList();

                    matchingFollowups.sort((a, b) {
                      final isASV = isSiteVisitStatus(a.status) ? 1 : 0;
                      final isBSV = isSiteVisitStatus(b.status) ? 1 : 0;
                      final svComp = isBSV.compareTo(isASV);
                      if (svComp != 0) return svComp;

                      final dtA = _parseFollowupDateTime(a.followupDate) ?? DateTime(1970);
                      final dtB = _parseFollowupDateTime(b.followupDate) ?? DateTime(1970);
                      final comp = dtB.compareTo(dtA);
                      if (comp != 0) return comp;

                      final isALocal = a.id.startsWith('local_') ? 1 : 0;
                      final isBLocal = b.id.startsWith('local_') ? 1 : 0;
                      return isBLocal.compareTo(isALocal);
                    });

                    final matchingF = matchingFollowups.firstOrNull;

                    final matchingSv = (dashboardData?.siteVisits ?? []).firstWhereOrNull((sv) =>
                        (sv.requirementId != null && sv.requirementId!.isNotEmpty && req.id == sv.requirementId) ||
                        (sv.requirementCustomerName != null && req.clientName.trim().toLowerCase() == sv.requirementCustomerName!.trim().toLowerCase())
                    );

                    final dateStr = (req.nextFollowupDate != null && req.nextFollowupDate!.trim().isNotEmpty)
                        ? req.nextFollowupDate!
                        : (matchingF?.followupDate ?? matchingSv?.visitDate ?? req.createdAt.toIso8601String());
                    final notesStr = (matchingF?.notes != null && matchingF!.notes!.trim().isNotEmpty)
                        ? matchingF.notes!
                        : ((matchingSv?.remarks != null && matchingSv!.remarks!.trim().isNotEmpty)
                            ? matchingSv.remarks!
                            : 'Site visit scheduled');

                    siteVisitsMap[req.id] = DashboardFollowup(
                      id: matchingF?.id ?? matchingSv?.id ?? 'sv_${req.id}',
                      clientName: req.clientName,
                      mobile: req.clientMobile,
                      followupDate: dateStr,
                      notes: notesStr,
                      status: reqStatus,
                      propertyTitle: matchingF?.propertyTitle ?? matchingSv?.propertyTitle,
                      requirementCustomerName: req.clientName,
                      requirementId: req.id,
                    );
                  }
                }

                // 2. Check dashboard siteVisits
                final siteVisitsList = dashboardData?.siteVisits ?? [];
                for (final sv in siteVisitsList) {
                  final req = reqsList.firstWhereOrNull((r) =>
                      (sv.requirementId != null && sv.requirementId!.isNotEmpty && r.id == sv.requirementId) ||
                      (sv.requirementCustomerName != null && r.clientName.trim().toLowerCase() == sv.requirementCustomerName!.trim().toLowerCase()));
                  if (req != null) {
                    final reqStatus = req.status;
                    if (!isSiteVisitStatus(reqStatus)) continue;
                    if (getListingTypeLabel(req) != _activeListingTab) continue;
                  } else {
                    if (!isSiteVisitStatus(sv.status)) continue;
                  }
                  final key = sv.requirementId ?? sv.id;
                  if (!siteVisitsMap.containsKey(key)) {
                    siteVisitsMap[key] = DashboardFollowup(
                      id: sv.id,
                      clientName: sv.requirementCustomerName ?? 'Client Site Visit',
                      mobile: '',
                      followupDate: sv.visitDate,
                      notes: sv.remarks,
                      status: sv.status,
                      propertyTitle: sv.propertyTitle,
                      requirementCustomerName: sv.requirementCustomerName,
                      requirementId: sv.requirementId,
                    );
                  }
                }

                for (final f in siteVisitsMap.values) {
                  allClientsFollowups.add(f);
                  DateTime? parsed = _parseFollowupDateTime(f.followupDate);
                  if (parsed == null) continue;
                  final fDate = DateTime(parsed.year, parsed.month, parsed.day);
                  if (fDate.isBefore(todayDate)) {
                    dueFollowups.add(f);
                  } else if (fDate.isAfter(todayDate)) {
                    futureFollowups.add(f);
                  } else {
                    todayFollowups.add(f);
                  }
                }
              } else {
                // Deduplicate followups by requirementId keeping only active pending entry per lead
                final Map<String, DashboardFollowup> latestReqFollowupsMap = {};
                for (final f in followups) {
                  final req = reqsList.firstWhereOrNull((r) =>
                      (f.requirementId != null && f.requirementId!.isNotEmpty && r.id == f.requirementId) ||
                      (f.mobile.isNotEmpty && r.clientMobile.isNotEmpty && isSameMobile(r.clientMobile, f.mobile)) ||
                      (f.clientName.isNotEmpty && r.clientName.trim().toLowerCase() == f.clientName.trim().toLowerCase()));

                  if (req == null) continue;

                  final reqStatus = req.status;
                  // ONLY ALLOW FOLLOW-UP OR RE-FOLLOWUP STATUS
                  if (!isFollowupStatus(reqStatus)) continue;

                  final key = req.id;
                  final existing = latestReqFollowupsMap[key];
                  if (existing == null) {
                    latestReqFollowupsMap[key] = f;
                  } else {
                    final bool fIsPending = f.status == 'Pending' || f.status == 'Follow-up' || f.status == 'Re-Followup';
                    final bool existingIsPending = existing.status == 'Pending' || existing.status == 'Follow-up' || existing.status == 'Re-Followup';

                    if (f.id.startsWith('local_') && !existing.id.startsWith('local_')) {
                      latestReqFollowupsMap[key] = f;
                    } else if (!f.id.startsWith('local_') && existing.id.startsWith('local_')) {
                      // Keep existing local entry
                    } else if (fIsPending && !existingIsPending) {
                      latestReqFollowupsMap[key] = f;
                    } else {
                      latestReqFollowupsMap[key] = f;
                    }
                  }
                }

                for (final f in latestReqFollowupsMap.values) {
                  final req = reqsList.firstWhereOrNull((r) =>
                      (f.requirementId != null && f.requirementId!.isNotEmpty && r.id == f.requirementId) ||
                      (f.mobile.isNotEmpty && r.clientMobile.isNotEmpty && isSameMobile(r.clientMobile, f.mobile)) ||
                      (f.clientName.isNotEmpty && r.clientName.trim().toLowerCase() == f.clientName.trim().toLowerCase()));

                  if (req == null) continue;

                  final reqStatus = req.status;
                  // ONLY ALLOW FOLLOW-UP OR RE-FOLLOWUP STATUS
                  if (!isFollowupStatus(reqStatus)) continue;

                  if (getListingTypeLabel(req) != _activeListingTab) continue;

                  allClientsFollowups.add(f);

                  DateTime? parsed = _parseFollowupDateTime(f.followupDate);
                  if (parsed == null && f.followupDate.isNotEmpty) {
                    try {
                      final parts = f.followupDate.split(RegExp(r'[/\\-]'));
                      if (parts.length >= 3) {
                        final d = int.tryParse(parts[0]);
                        final m = int.tryParse(parts[1]);
                        final y = int.tryParse(parts[2]);
                        if (d != null && m != null && y != null) {
                          parsed = DateTime(y, m, d);
                        }
                      }
                    } catch (_) {}
                  }
                  if (parsed == null) continue;
                  final fDate = DateTime(parsed.year, parsed.month, parsed.day);

                  if (fDate.isBefore(todayDate)) {
                    dueFollowups.add(f);
                  } else if (fDate.isAfter(todayDate)) {
                    futureFollowups.add(f);
                  } else {
                    todayFollowups.add(f);
                  }
                }
              }

              todayFollowups.sort((a, b) {
                final dtA = _parseFollowupDateTime(a.followupDate) ?? DateTime(1970);
                final dtB = _parseFollowupDateTime(b.followupDate) ?? DateTime(1970);
                return dtA.compareTo(dtB);
              });

              dueFollowups.sort((a, b) {
                final dtA = _parseFollowupDateTime(a.followupDate) ?? DateTime(1970);
                final dtB = _parseFollowupDateTime(b.followupDate) ?? DateTime(1970);
                return dtB.compareTo(dtA);
              });

              futureFollowups.sort((a, b) {
                final dtA = _parseFollowupDateTime(a.followupDate) ?? DateTime(1970);
                final dtB = _parseFollowupDateTime(b.followupDate) ?? DateTime(1970);
                return dtA.compareTo(dtB); // Earliest future date first (e.g. 11/09, 12/09, 13/09)
              });

              allClientsFollowups.sort((a, b) {
                final dtA = _parseFollowupDateTime(a.followupDate) ?? DateTime(1970);
                final dtB = _parseFollowupDateTime(b.followupDate) ?? DateTime(1970);
                return dtB.compareTo(dtA);
              });

              List<DashboardFollowup> selectedList;
              if (_selectedFollowupSubTab == 'Due') {
                selectedList = dueFollowups;
              } else if (_selectedFollowupSubTab == 'Future') {
                selectedList = futureFollowups;
                if (_reqFollowupDateFilter != null) {
                  selectedList = futureFollowups.where((f) {
                    final parsed = _parseFollowupDateTime(f.followupDate);
                    if (parsed == null) return false;
                    return parsed.year == _reqFollowupDateFilter!.year &&
                        parsed.month == _reqFollowupDateFilter!.month &&
                        parsed.day == _reqFollowupDateFilter!.day;
                  }).toList();
                }
              } else if (_selectedFollowupSubTab == 'AllClients') {
                selectedList = allClientsFollowups;
              } else {
                selectedList = todayFollowups;
              }

              final filtered = selectedList;

              final totalCount = filtered.length;
              final totalPages = (totalCount / _followupsPerPage).ceil();
              final currentPage = _currentFollowupPage.clamp(1, totalPages > 0 ? totalPages : 1);

              final startIndex = (currentPage - 1) * _followupsPerPage;
              final endIndex = (startIndex + _followupsPerPage).clamp(0, totalCount);

              final authState = context.watch<AuthBloc>().state;
              final currentUser = authState is Authenticated ? authState.user : null;
              final isHighRole = currentUser != null &&
                  (currentUser.role == 'Admin' || currentUser.role == 'Super Admin' || currentUser.role == 'Telecaller');
              final isAdminOrSuperAdmin = currentUser != null &&
                  (currentUser.role == 'Admin' || currentUser.role == 'Super Admin');
              final bool showSelectColumn = _selectedFollowupSubTab == 'AllClients' && isAdminOrSuperAdmin;

              final pageItems = (startIndex < totalCount)
                  ? filtered.sublist(startIndex, endIndex)
                  : <DashboardFollowup>[];

              if (pageItems.isEmpty && currentPage > 1) {
                // Safe fall-back if page boundaries changed
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _currentFollowupPage = 1;
                    });
                  }
                });
              }

              Widget buildSubTabPill(String label, String tabKey, int count, IconData icon) {
                final bool isSelected = _selectedFollowupSubTab == tabKey;
                final Color activeColor = tabKey == 'Due'
                    ? CRMColors.danger
                    : (tabKey == 'Future'
                        ? CRMColors.info
                        : (tabKey == 'AllClients' ? const Color(0xFF6C5CE7) : CRMColors.primary));

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFollowupSubTab = tabKey;
                      _currentFollowupPage = 1;
                      if (tabKey == 'Today') {
                        _reqFollowupDateFilter = DateTime.now();
                      } else {
                        _reqFollowupDateFilter = null;
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? activeColor : CRMColors.borderOf(context).withValues(alpha: 0.5),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 16, color: isSelected ? activeColor : CRMColors.textSecondaryOf(context)),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: CRMTypography.bodyMedium.copyWith(
                            color: isSelected ? activeColor : CRMColors.textSecondaryOf(context),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? activeColor : activeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: CRMTypography.captionBold.copyWith(
                              color: isSelected ? Colors.white : activeColor,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final bool isSiteVisitTab = _selectedMainFollowupSection == 'Site Visit Scheduled';
              final todayLabel = isSiteVisitTab ? "Today's Site Visit Scheduled" : "Today's Follow-ups";
              final dueLabel = isSiteVisitTab ? "Due Site Visit Scheduled" : "Due Follow-ups";
              final futureLabel = isSiteVisitTab ? "Future Site Visit Scheduled" : "Future Follow-ups";
              final allLabel = isSiteVisitTab ? "All Site Visit Scheduled" : "All clients follow ups";

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        buildSubTabPill(todayLabel, "Today", todayFollowups.length, Icons.today_rounded),
                        const SizedBox(width: CRMSpacing.s),
                        buildSubTabPill(dueLabel, "Due", dueFollowups.length, Icons.warning_amber_rounded),
                        const SizedBox(width: CRMSpacing.s),
                        buildSubTabPill(futureLabel, "Future", futureFollowups.length, Icons.next_plan_rounded),
                        const SizedBox(width: CRMSpacing.s),
                        buildSubTabPill(allLabel, "AllClients", allClientsFollowups.length, Icons.people_alt_rounded),
                      ],
                    ),
                  ),
                  if (showSelectColumn && _selectedFollowupClientKeys.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: CRMColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CRMColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedFollowupClientKeys.length} client(s) selected',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: CRMColors.danger),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CRMColors.danger,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            label: const Text('Delete Selected Clients'),
                            onPressed: () => _confirmAndDeleteSelectedClients(pageItems, reqsList),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.m),
                  ],

                  if (_selectedFollowupSubTab == 'Due' && dueFollowups.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(CRMSpacing.m),
                      decoration: BoxDecoration(
                        color: CRMColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                        border: Border.all(color: CRMColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: CRMColors.danger, size: 22),
                          const SizedBox(width: CRMSpacing.s),
                          Expanded(
                            child: Text(
                              isSiteVisitTab
                                  ? '⚠️ Overdue Site Visit Reminder: You have ${dueFollowups.length} overdue site visit(s)! Please follow up immediately.'
                                  : '⚠️ Overdue Follow-up Reminder: You have ${dueFollowups.length} overdue follow-up(s)! Please contact these clients immediately to take action.',
                              style: CRMTypography.captionBold.copyWith(color: CRMColors.danger, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.m),
                  ],

                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          _selectedFollowupSubTab == 'Due'
                              ? (isSiteVisitTab ? 'No overdue site visits found.' : 'No overdue follow-ups found.')
                              : (_selectedFollowupSubTab == 'Future'
                                  ? (isSiteVisitTab ? 'No future site visits scheduled.' : 'No future follow-ups scheduled.')
                                  : (_reqFollowupDateFilter != null
                                      ? (isSiteVisitTab ? 'No site visits for $dateStr.' : 'No follow-ups for $dateStr.')
                                      : (isSiteVisitTab ? 'No site visits for today.' : 'No follow-ups for today.'))),
                          style: TextStyle(color: CRMColors.textSecondaryOf(context)),
                        ),
                      ),
                    )
                  else if (isMobile)
                    Column(
                      children: pageItems.map((f) => _buildMobileFollowupCard(f, reqsList)).toList(),
                    )
                  else
                    CRMDataTable(
                      showDecoration: false,
                      dataRowMinHeight: 60.0,
                      dataRowMaxHeight: 72.0,
                      columnSpacing: 16.0,
                      columns: [
                        if (showSelectColumn)
                          DataColumn(
                            label: Checkbox(
                              value: pageItems.isNotEmpty && pageItems.every((f) => _selectedFollowupClientKeys.contains(_getFollowupClientKey(f))),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    for (final f in pageItems) {
                                      _selectedFollowupClientKeys.add(_getFollowupClientKey(f));
                                    }
                                  } else {
                                    for (final f in pageItems) {
                                      _selectedFollowupClientKeys.remove(_getFollowupClientKey(f));
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                        const DataColumn(label: Text('Client Details')),
                        if (isHighRole) const DataColumn(label: Text('Added by')),
                        const DataColumn(label: Text('Requirement / Config')),
                        if (_selectedFollowupSubTab != 'AllClients') const DataColumn(label: Text('Scheduled Date')),
                        if (_selectedFollowupSubTab != 'AllClients') const DataColumn(label: Text('Remarks / Agenda')),
                        const DataColumn(label: Text('Actions')),
                      ],
                      rows: pageItems.map((f) {
                        final reqModel = reqsList.firstWhereOrNull((r) =>
                            (f.requirementId != null && f.requirementId!.isNotEmpty && r.id == f.requirementId) ||
                            (f.mobile.isNotEmpty && r.clientMobile.replaceAll(RegExp(r'\D'), '') == f.mobile.replaceAll(RegExp(r'\D'), '')) ||
                            (f.clientName.isNotEmpty && r.clientName.trim().toLowerCase() == f.clientName.trim().toLowerCase()));

                        final parsedDate = _parseFollowupDateTime(f.followupDate);
                        final displayDate = parsedDate != null
                            ? DateFormat('dd/MM/yyyy hh:mm a').format(parsedDate)
                            : f.followupDate;

                        String configText = 'General Requirement';
                        if (reqModel != null) {
                          final config = (reqModel.configurationName ?? '').trim();
                          final pType = (reqModel.propertyTypeName.isNotEmpty
                                  ? reqModel.propertyTypeName
                                  : (reqModel.categoryName.isNotEmpty ? reqModel.categoryName : ''))
                              .trim();
                          final listing = (reqModel.listingTypeName ?? '').trim();

                          final List<String> parts = [];
                          if (config.isNotEmpty && config != '-') parts.add(config);
                          if (pType.isNotEmpty && pType != 'N/A') parts.add(pType);
                          if (listing.isNotEmpty && listing != 'N/A') parts.add('($listing)');

                          if (parts.isNotEmpty) {
                            configText = parts.join(' ');
                          } else if (reqModel.remarks != null && reqModel.remarks!.trim().isNotEmpty) {
                            configText = reqModel.remarks!.trim();
                          }
                        } else if (f.propertyTitle != null && f.propertyTitle!.isNotEmpty) {
                          configText = f.propertyTitle!;
                        }

                        final budgetText = reqModel != null
                            ? '${BudgetFormatter.format(reqModel.minBudget)} - ${BudgetFormatter.format(reqModel.maxBudget)}'
                            : '';
                        final areasText = reqModel != null && reqModel.areaNames.isNotEmpty
                            ? reqModel.areaNames.join(', ')
                            : 'Any Area';

                        final tooltipMsg = reqModel != null
                            ? 'Client: ${f.clientName}\nRequirement: $configText\nBudget: $budgetText\nAreas: $areasText'
                            : 'Client: ${f.clientName}\nMobile: ${f.mobile}';

                        String addedByName = 'N/A';
                        if (reqModel != null) {
                          final salesman = _getSalesmanName(reqModel, currentUser);
                          if (salesman.isNotEmpty && salesman != 'System' && salesman != 'N/A') {
                            addedByName = salesman;
                          }
                        }
                        if (addedByName == 'N/A' && f.creatorName != null && f.creatorName!.isNotEmpty && f.creatorName != 'System') {
                          try {
                            final usersState = context.read<UsersBloc>().state;
                            if (usersState is UsersLoaded) {
                              final match = usersState.users.firstWhereOrNull((u) => u.id == f.creatorName);
                              if (match != null && match.fullName.isNotEmpty) {
                                addedByName = match.fullName;
                              }
                            }
                          } catch (_) {}
                          if (addedByName == 'N/A') {
                            addedByName = f.creatorName!;
                          }
                        }
                        if (addedByName == 'N/A' || addedByName == 'System') {
                          if (currentUser != null && currentUser.fullName.isNotEmpty) {
                            addedByName = currentUser.fullName;
                          }
                        }

                        final clientKey = _getFollowupClientKey(f);
                        return DataRow(
                          cells: [
                            if (showSelectColumn)
                              DataCell(
                                Checkbox(
                                  value: _selectedFollowupClientKeys.contains(clientKey),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedFollowupClientKeys.add(clientKey);
                                      } else {
                                        _selectedFollowupClientKeys.remove(clientKey);
                                      }
                                    });
                                  },
                                ),
                              ),
                            // 1. Client Details
                            DataCell(
                              SizedBox(
                                width: 150,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (reqModel != null) {
                                          if (_selectedFollowupSubTab == 'AllClients') {
                                            _openFollowupStepper(reqModel, reqModel.status ?? 'Re-Followup', initialStep: 2);
                                          } else {
                                            _showRequirementDetailDrawer(reqModel);
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Associated requirement details not found.')),
                                          );
                                        }
                                      },
                                      child: Text(
                                        f.clientName,
                                        style: CRMTypography.bodyMedium.copyWith(
                                          color: CRMColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.phone_outlined, size: 12, color: CRMColors.textMutedOf(context)),
                                        const SizedBox(width: 4),
                                        Text(
                                          f.mobile,
                                          style: TextStyle(color: CRMColors.textMutedOf(context), fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isHighRole)
                              DataCell(
                                SizedBox(
                                  width: 140,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.person_outline_rounded, size: 14, color: CRMColors.primary),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              addedByName,
                                              style: CRMTypography.bodyMedium.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: CRMColors.textOf(context),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // 2. Requirement / Config
                            DataCell(
                              SizedBox(
                                width: 170,
                                child: _buildCustomTooltip(
                                  message: tooltipMsg,
                                  isRent: reqModel?.listingTypeName?.toLowerCase().contains('rent') ?? true,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        configText,
                                        style: CRMTypography.body.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (budgetText.isNotEmpty)
                                        Text(
                                          budgetText,
                                          style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // 3. Scheduled Date
                            if (_selectedFollowupSubTab != 'AllClients')
                              DataCell(
                                InkWell(
                                  onTap: () => _showEditFollowupDialog(context, f),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Tooltip(
                                    message: 'Click to edit date & time',
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: CRMColors.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: CRMColors.primary.withValues(alpha: 0.2)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.access_time_rounded, size: 13, color: CRMColors.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            displayDate,
                                            style: TextStyle(
                                              color: CRMColors.primary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(Icons.edit_outlined, size: 12, color: CRMColors.primary.withValues(alpha: 0.7)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            // 4. Remarks / Agenda
                            if (_selectedFollowupSubTab != 'AllClients')
                              DataCell(
                                SizedBox(
                                  width: 300,
                                  child: GestureDetector(
                                    onTap: () => _showFollowupMessageDialog(context, f.clientName, f.notes ?? 'No notes noted', followup: f),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: CRMColors.backgroundOf(context),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: CRMColors.borderOf(context).withValues(alpha: 0.5),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.notes_rounded, size: 14, color: CRMColors.primary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              f.notes != null && f.notes!.trim().isNotEmpty ? f.notes! : 'No notes noted',
                                              style: TextStyle(
                                                color: f.notes != null && f.notes!.trim().isNotEmpty
                                                    ? CRMColors.textOf(context)
                                                    : CRMColors.textMutedOf(context),
                                                fontSize: 12,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(Icons.edit_calendar_rounded, size: 13, color: CRMColors.primary.withValues(alpha: 0.7)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            // 5. Actions
                            DataCell(
                              _buildFollowupStatusActionCell(f, reqModel),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: CRMSpacing.m),
                  _buildFollowupsPagination(totalCount, totalPages, currentPage),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSharePropertiesDialog(RequirementModel req) {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        List<PropertyMatchResult> allMatches = [];
        final Set<String> selectedPropIds = {};
        bool isInitLoading = true;
        bool isGeneratingLink = false;
        bool isSharingPdf = false;
        String? error;
        String? generatedLink;
        String searchQuery = '';
        int? minScoreFilter;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> loadMatches() async {
              try {
                final List<PropertyMatchResult> results = [];

                // 1. Authoritative Backend Matching
                try {
                  final serverResponse = await RequirementsRepository().getRequirementMatches(
                    req.id,
                    minScore: MatchCriteriaManager().threshold,
                  );
                  final data = serverResponse['data'] as Map<String, dynamic>? ?? {};
                  final rawMatches = data['matches'] as List? ?? [];
                  if (rawMatches.isNotEmpty || data.containsKey('matching_metadata')) {
                    for (final item in rawMatches) {
                      final pJson = item['property'] as Map<String, dynamic>? ?? {};
                      final prop = PropertyModel.fromJson(pJson);
                      if (!PropertyRequirementMatcher.isEligibleByCategoryAndType(prop, req)) continue;
                      results.add(PropertyMatchResult.fromServerJson(item as Map<String, dynamic>, prop));
                    }
                  }
                } catch (serverErr) {
                  debugPrint("⚠️ [Share Dialog Backend Match Fallback] $serverErr");
                }

                // 2. Offline / Local fallback if backend returns empty or fails
                if (results.isEmpty) {
                  final properties = await PropertiesRepository().getProperties();
                  for (final p in properties) {
                    if (await _isRequirementPropertyMatchAsync(p, req)) {
                      final res = PropertyRequirementMatcher.match(p, req);
                      results.add(res);
                    }
                  }
                }

                // 3. Strictly sort by match percentage descending (highest first)
                results.sort((a, b) {
                  final cmp = b.matchPercentage.compareTo(a.matchPercentage);
                  if (cmp != 0) return cmp;
                  return a.property.price.compareTo(b.property.price);
                });

                setDialogState(() {
                  allMatches = results;
                  isInitLoading = false;
                });
              } catch (e) {
                setDialogState(() {
                  error = "Failed to load matching properties.";
                  isInitLoading = false;
                });
              }
            }

            if (isInitLoading && error == null && generatedLink == null) {
              loadMatches();
            }

            if (generatedLink != null) {
              return AlertDialog(
                backgroundColor: CRMColors.cardBgOf(context),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
                title: Text("Share Link Created", style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(CRMSpacing.s),
                      decoration: BoxDecoration(
                        color: CRMColors.backgroundOf(context),
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                        border: Border.all(color: CRMColors.borderOf(context)),
                      ),
                      child: SelectableText(
                        generatedLink!,
                        style: CRMTypography.caption.copyWith(color: CRMColors.primary),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.m),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text("Copy"),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: generatedLink!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Link copied to clipboard!")),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: CRMSpacing.s),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: kWhatsAppGreen, foregroundColor: Colors.white),
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                            label: const Text("WhatsApp"),
                            onPressed: () async {
                              final text = Uri.encodeComponent("Hello, here is the curated list of properties matching your requirements: $generatedLink");
                              final url = "https://wa.me/?text=$text";
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text("Share"),
                      onPressed: () async {
                        try {
                          await Share.share(generatedLink!);
                        } catch (e) {
                          await Clipboard.setData(ClipboardData(text: generatedLink!));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Link copied to clipboard!")),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              );
            }

            // Compute filtered list based on search and min-score filter
            final filteredMatches = allMatches.where((m) {
              if (minScoreFilter != null && m.matchPercentage < minScoreFilter!) {
                return false;
              }
              if (searchQuery.trim().isNotEmpty) {
                final q = searchQuery.trim().toLowerCase();
                final p = m.property;
                final bhk = (p.configurationName ?? "${p.bedrooms} BHK").toLowerCase();
                final area = p.areaName.toLowerCase();
                final code = p.propertyCode.toLowerCase();
                final title = p.title.toLowerCase();
                final reasons = m.matchedCriteria.join(' ').toLowerCase();
                final match = bhk.contains(q) || area.contains(q) || code.contains(q) || title.contains(q) || reasons.contains(q);
                if (!match) return false;
              }
              return true;
            }).toList();

            Future<void> shareViaWhatsAppDirect() async {
              setDialogState(() => isGeneratingLink = true);
              try {
                final response = await DioClient.dio.post(
                  '/share-sessions',
                  data: {
                    'requirement_id': req.id,
                    'property_ids': selectedPropIds.toList(),
                    'expiry_days': 7
                  },
                );
                if (response.data != null && response.data['success'] == true) {
                  final sessionId = response.data['data']['session']['id'];
                  final authState = context.read<AuthBloc>().state;
                  String? currentAgentName;
                  String? currentAgentMobile;
                  if (authState is Authenticated) {
                    currentAgentName = authState.user.fullName;
                    currentAgentMobile = authState.user.mobile;
                  }

                  var link = "${AppConfig.publicShareBaseUrl}/$sessionId";
                  final queryParams = <String>[];
                  if (currentAgentName != null && currentAgentName.isNotEmpty) {
                    queryParams.add("agentName=${Uri.encodeComponent(currentAgentName)}");
                  }
                  if (currentAgentMobile != null && currentAgentMobile.isNotEmpty) {
                    queryParams.add("agentMobile=${Uri.encodeComponent(currentAgentMobile)}");
                  }
                  if (queryParams.isNotEmpty) {
                    link += "?${queryParams.join('&')}";
                  }

                  final selectedItems = allMatches.where((m) => selectedPropIds.contains(m.property.id)).toList();
                  final StringBuffer sb = StringBuffer();
                  final clientGreeting = req.clientName.trim().isNotEmpty ? req.clientName.trim() : 'Sir/Madam';
                  sb.writeln("Hello $clientGreeting,");
                  sb.writeln("Here are the top matching properties curated for your requirement:");
                  sb.writeln("");
                  int counter = 1;
                  for (final item in selectedItems) {
                    final p = item.property;
                    final bhk = p.configurationName ?? "${p.bedrooms} BHK";
                    final price = '₹${BudgetFormatter.format(p.price)}';
                    sb.writeln("$counter. *$bhk in ${p.areaName}* – $price (${item.matchPercentage}% Match) [${p.propertyCode}]");
                    counter++;
                  }
                  sb.writeln("");
                  sb.writeln("View photos, amenities & complete details here:\n$link");

                  final phone = req.clientMobile;
                  final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
                  String formattedPhone = cleanPhone;
                  if (cleanPhone.length == 10) {
                    formattedPhone = '91$cleanPhone';
                  }

                  final encodedMsg = Uri.encodeComponent(sb.toString());
                  final nativeUrl = "whatsapp://send?phone=$formattedPhone&text=$encodedMsg";
                  final nativeUri = Uri.parse(nativeUrl);

                  if (await canLaunchUrl(nativeUri)) {
                    await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
                  } else {
                    final webUrl = "https://web.whatsapp.com/send?phone=$formattedPhone&text=$encodedMsg";
                    final webUri = Uri.parse(webUrl);
                    if (await canLaunchUrl(webUri)) {
                      await launchUrl(webUri, mode: LaunchMode.externalApplication);
                    } else {
                      final fallbackUrl = "https://wa.me/$formattedPhone?text=$encodedMsg";
                      final fallbackUri = Uri.parse(fallbackUrl);
                      if (await canLaunchUrl(fallbackUri)) {
                        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
                      }
                    }
                  }

                  setDialogState(() {
                    generatedLink = link;
                    isGeneratingLink = false;
                  });
                } else {
                  setDialogState(() {
                    error = "Failed to create share session.";
                    isGeneratingLink = false;
                  });
                }
              } catch (e) {
                setDialogState(() {
                  error = "Failed to share via WhatsApp: $e";
                  isGeneratingLink = false;
                });
              }
            }

            final double screenWidth = MediaQuery.of(context).size.width;
            final double dialogWidth = (screenWidth < 560 ? (screenWidth - 32) : 500.0).clamp(280.0, 500.0);

            return Stack(
              children: [
                AlertDialog(
                  backgroundColor: CRMColors.cardBgOf(context),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
                  insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
                  titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                  contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: CRMColors.primaryOf(context).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.share_rounded, size: 18, color: CRMColors.primaryOf(context)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Share Matching Properties",
                              style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context), fontSize: 16),
                            ),
                            Text(
                              "Ranked by Match Score • ${req.clientName.trim().isNotEmpty ? req.clientName : 'Client'}",
                              style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: (isGeneratingLink || isSharingPdf) ? null : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  content: isInitLoading
                      ? SizedBox(
                          height: 200,
                          width: dialogWidth,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 12),
                                Text("Analyzing and ranking matches...", style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        )
                      : error != null
                          ? SizedBox(
                              width: dialogWidth,
                              height: 100,
                              child: Center(child: Text(error!, style: const TextStyle(color: CRMColors.danger))),
                            )
                          : allMatches.isEmpty
                              ? SizedBox(
                                  width: dialogWidth,
                                  height: 100,
                                  child: const Center(child: Text("No matching properties found for this requirement.")),
                                )
                              : SizedBox(
                                  width: dialogWidth,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Search Bar
                                      TextField(
                                        controller: searchController,
                                        style: const TextStyle(fontSize: 13),
                                        decoration: InputDecoration(
                                          hintText: "Filter by locality, BHK, price, code...",
                                          hintStyle: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
                                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                          suffixIcon: searchQuery.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                                  onPressed: () {
                                                    setDialogState(() {
                                                      searchController.clear();
                                                      searchQuery = '';
                                                    });
                                                  },
                                                )
                                              : null,
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: CRMColors.borderOf(context)),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: CRMColors.borderOf(context)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide(color: CRMColors.primaryOf(context)),
                                          ),
                                          filled: true,
                                          fillColor: CRMColors.backgroundOf(context),
                                        ),
                                        onChanged: (val) {
                                          setDialogState(() {
                                            searchQuery = val;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      // Filter Chips & Quick Selectors Bar (Responsive Wrap)
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        alignment: WrapAlignment.spaceBetween,
                                        children: [
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              // All filter
                                              InkWell(
                                                onTap: () => setDialogState(() => minScoreFilter = null),
                                                borderRadius: BorderRadius.circular(12),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: minScoreFilter == null
                                                        ? CRMColors.primaryOf(context).withValues(alpha: 0.12)
                                                        : CRMColors.backgroundOf(context),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: minScoreFilter == null
                                                          ? CRMColors.primaryOf(context)
                                                          : CRMColors.borderOf(context),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    "All (${allMatches.length})",
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: minScoreFilter == null ? FontWeight.w700 : FontWeight.w500,
                                                      color: minScoreFilter == null ? CRMColors.primaryOf(context) : CRMColors.textSecondaryOf(context),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // 90%+ filter chip
                                              if (allMatches.any((m) => m.matchPercentage >= 90))
                                                InkWell(
                                                  onTap: () => setDialogState(() => minScoreFilter = minScoreFilter == 90 ? null : 90),
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: minScoreFilter == 90
                                                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                                          : CRMColors.backgroundOf(context),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: minScoreFilter == 90
                                                            ? const Color(0xFF059669)
                                                            : CRMColors.borderOf(context),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "90%+ (${allMatches.where((m) => m.matchPercentage >= 90).length})",
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: minScoreFilter == 90 ? FontWeight.w700 : FontWeight.w500,
                                                        color: minScoreFilter == 90 ? const Color(0xFF059669) : CRMColors.textSecondaryOf(context),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              // Top 3 quick button
                                              InkWell(
                                                onTap: filteredMatches.isEmpty ? null : () {
                                                  setDialogState(() {
                                                    selectedPropIds.clear();
                                                    for (final m in filteredMatches.take(3)) {
                                                      selectedPropIds.add(m.property.id);
                                                    }
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: CRMColors.surfaceElevatedOf(context),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: CRMColors.borderOf(context)),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFD97706)),
                                                      SizedBox(width: 2),
                                                      Text("Top 3", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Select / Deselect All
                                              InkWell(
                                                onTap: filteredMatches.isEmpty ? null : () {
                                                  setDialogState(() {
                                                    final allSel = filteredMatches.every((m) => selectedPropIds.contains(m.property.id));
                                                    if (allSel) {
                                                      for (final m in filteredMatches) {
                                                        selectedPropIds.remove(m.property.id);
                                                      }
                                                    } else {
                                                      for (final m in filteredMatches) {
                                                        selectedPropIds.add(m.property.id);
                                                      }
                                                    }
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: CRMColors.surfaceElevatedOf(context),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: CRMColors.borderOf(context)),
                                                  ),
                                                  child: Text(
                                                    filteredMatches.every((m) => selectedPropIds.contains(m.property.id)) ? "Deselect" : "All",
                                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      // Selected Counter strip
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: selectedPropIds.isNotEmpty
                                              ? CRMColors.primary.withValues(alpha: 0.08)
                                              : CRMColors.backgroundOf(context),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              selectedPropIds.isNotEmpty ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                              size: 13,
                                              color: selectedPropIds.isNotEmpty ? CRMColors.primary : CRMColors.textSecondaryOf(context),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              "${selectedPropIds.length} of ${filteredMatches.length} selected",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: selectedPropIds.isNotEmpty ? CRMColors.primary : CRMColors.textSecondaryOf(context),
                                              ),
                                            ),
                                            if (selectedPropIds.isNotEmpty) ...[
                                              const Spacer(),
                                              InkWell(
                                                onTap: () => setDialogState(() => selectedPropIds.clear()),
                                                child: const Text(
                                                  "Clear",
                                                  style: TextStyle(fontSize: 11, color: CRMColors.danger, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // List of prioritized matches
                                      SizedBox(
                                        height: 310,
                                        child: filteredMatches.isEmpty
                                            ? Center(
                                                child: Text(
                                                  searchQuery.isNotEmpty
                                                      ? "No matches found matching '$searchQuery'"
                                                      : "No properties meet the current filter.",
                                                  style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
                                                ),
                                              )
                                            : ListView.separated(
                                                itemCount: filteredMatches.length,
                                                separatorBuilder: (context, idx) => Divider(
                                                  height: 1,
                                                  color: CRMColors.borderOf(context).withValues(alpha: 0.4),
                                                ),
                                                itemBuilder: (context, idx) {
                                                  final m = filteredMatches[idx];
                                                  final p = m.property;
                                                  final isSelected = selectedPropIds.contains(p.id);
                                                  final bhk = p.configurationName ?? "${p.bedrooms} BHK";
                                                  final price = '₹${BudgetFormatter.format(p.price)}';
                                                  final area = p.areaName.isNotEmpty ? p.areaName : 'Ahmedabad';
                                                  final score = m.matchPercentage;

                                                  Color badgeBg;
                                                  Color badgeText;
                                                  if (score >= 90) {
                                                    badgeBg = const Color(0xFF10B981).withValues(alpha: 0.14);
                                                    badgeText = const Color(0xFF047857);
                                                  } else if (score >= 75) {
                                                    badgeBg = const Color(0xFF3B82F6).withValues(alpha: 0.14);
                                                    badgeText = const Color(0xFF1D4ED8);
                                                  } else {
                                                    badgeBg = const Color(0xFFF59E0B).withValues(alpha: 0.14);
                                                    badgeText = const Color(0xFFB45309);
                                                  }

                                                  return Material(
                                                    color: isSelected
                                                        ? CRMColors.primary.withValues(alpha: 0.06)
                                                        : Colors.transparent,
                                                    child: InkWell(
                                                      onTap: (isGeneratingLink || isSharingPdf)
                                                          ? null
                                                          : () {
                                                              setDialogState(() {
                                                                if (isSelected) {
                                                                  selectedPropIds.remove(p.id);
                                                                } else {
                                                                  selectedPropIds.add(p.id);
                                                                }
                                                              });
                                                            },
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                        child: Row(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 2, right: 8),
                                                              child: SizedBox(
                                                                width: 18,
                                                                height: 18,
                                                                child: Checkbox(
                                                                  value: isSelected,
                                                                  activeColor: CRMColors.primary,
                                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                                  onChanged: (isGeneratingLink || isSharingPdf)
                                                                      ? null
                                                                      : (val) {
                                                                          setDialogState(() {
                                                                            if (val == true) {
                                                                              selectedPropIds.add(p.id);
                                                                            } else {
                                                                              selectedPropIds.remove(p.id);
                                                                            }
                                                                          });
                                                                        },
                                                                ),
                                                             ),
                                                            ),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Expanded(
                                                                        child: Text(
                                                                          "$bhk in $area",
                                                                          style: TextStyle(
                                                                            fontSize: 13,
                                                                            fontWeight: FontWeight.w600,
                                                                            color: CRMColors.textOf(context),
                                                                          ),
                                                                          maxLines: 1,
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(width: 6),
                                                                      Container(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                                        decoration: BoxDecoration(
                                                                          color: badgeBg,
                                                                          borderRadius: BorderRadius.circular(10),
                                                                          border: Border.all(color: badgeText.withValues(alpha: 0.25)),
                                                                        ),
                                                                        child: Row(
                                                                          mainAxisSize: MainAxisSize.min,
                                                                          children: [
                                                                            Icon(Icons.verified_rounded, size: 10, color: badgeText),
                                                                            const SizedBox(width: 2.5),
                                                                            Text(
                                                                              "$score% Match",
                                                                              style: TextStyle(
                                                                                fontSize: 10.5,
                                                                                fontWeight: FontWeight.w700,
                                                                                color: badgeText,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  const SizedBox(height: 2),
                                                                  Row(
                                                                    children: [
                                                                      Text(
                                                                        price,
                                                                        style: TextStyle(
                                                                          fontSize: 12,
                                                                          fontWeight: FontWeight.w700,
                                                                          color: CRMColors.primaryOf(context),
                                                                        ),
                                                                      ),
                                                                      if (p.propertyCode.isNotEmpty) ...[
                                                                        const SizedBox(width: 5),
                                                                        Text(
                                                                          "(${p.propertyCode})",
                                                                          style: TextStyle(
                                                                            fontSize: 11,
                                                                            color: CRMColors.textSecondaryOf(context),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                      if (p.listingTypeName != null && p.listingTypeName!.isNotEmpty) ...[
                                                                        const SizedBox(width: 5),
                                                                        Container(
                                                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                                          decoration: BoxDecoration(
                                                                            color: CRMColors.backgroundOf(context),
                                                                            borderRadius: BorderRadius.circular(3),
                                                                            border: Border.all(color: CRMColors.borderOf(context).withValues(alpha: 0.6)),
                                                                          ),
                                                                          child: Text(
                                                                            p.listingTypeName!,
                                                                            style: TextStyle(
                                                                              fontSize: 9.5,
                                                                              color: CRMColors.textSecondaryOf(context),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ],
                                                                  ),
                                                                  if (m.matchedCriteria.isNotEmpty) ...[
                                                                    const SizedBox(height: 3),
                                                                    Wrap(
                                                                      spacing: 4,
                                                                      runSpacing: 2,
                                                                      children: m.matchedCriteria.take(3).map((r) => Container(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                                        decoration: BoxDecoration(
                                                                          color: CRMColors.success.withValues(alpha: 0.08),
                                                                          borderRadius: BorderRadius.circular(3),
                                                                        ),
                                                                        child: Text(
                                                                          r,
                                                                          style: const TextStyle(
                                                                            fontSize: 9.5,
                                                                            color: CRMColors.success,
                                                                            fontWeight: FontWeight.w500,
                                                                          ),
                                                                          maxLines: 1,
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      )).toList(),
                                                                    ),
                                                                  ],
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                  actions: [
                    TextButton(
                      onPressed: (isGeneratingLink || isSharingPdf) ? null : () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    if (!isInitLoading && error == null && allMatches.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 15),
                            label: const Text("Share PDF", style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onPressed: selectedPropIds.isEmpty || isGeneratingLink || isSharingPdf
                                ? null
                                : () async {
                                    setDialogState(() => isSharingPdf = true);
                                    try {
                                      final selected = allMatches
                                          .where((m) => selectedPropIds.contains(m.property.id))
                                          .map((m) => m.property)
                                          .toList();
                                      final bytes = await PropertySharePdf.build(selected);
                                      final fileName = selected.length == 1
                                          ? PropertySharePdf.fileName(selected.first)
                                          : 'Selected_Properties_Details.pdf';

                                      await FileDownloader.download(bytes, fileName);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              selected.length == 1
                                                  ? 'Property PDF ready to share.'
                                                  : 'Selected properties PDF ready to share.',
                                            ),
                                          ),
                                        );
                                      }

                                      final phone = req.clientMobile;
                                      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
                                      String formattedPhone = cleanPhone;
                                      if (cleanPhone.length == 10) {
                                        formattedPhone = '91$cleanPhone';
                                      }

                                      final nativeUrl = "whatsapp://send?phone=$formattedPhone";
                                      final nativeUri = Uri.parse(nativeUrl);

                                      if (await canLaunchUrl(nativeUri)) {
                                        await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
                                      } else {
                                        final webUrl = "https://web.whatsapp.com/send?phone=$formattedPhone";
                                        final webUri = Uri.parse(webUrl);
                                        if (await canLaunchUrl(webUri)) {
                                          await launchUrl(webUri, mode: LaunchMode.externalApplication);
                                        } else {
                                          final fallbackUrl = "https://wa.me/$formattedPhone";
                                          final fallbackUri = Uri.parse(fallbackUrl);
                                          if (await canLaunchUrl(fallbackUri)) {
                                            await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
                                          }
                                        }
                                      }
                                    } catch (e) {
                                      debugPrint('Share PDF failed: $e');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Failed to create property PDF.'),
                                            backgroundColor: CRMColors.danger,
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (context.mounted) {
                                        setDialogState(() => isSharingPdf = false);
                                      }
                                    }
                                  },
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.link_rounded, size: 15),
                            label: const Text("Generate Link", style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onPressed: selectedPropIds.isEmpty || isGeneratingLink || isSharingPdf
                                ? null
                                : () async {
                                    setDialogState(() => isGeneratingLink = true);
                                    try {
                                      final response = await DioClient.dio.post(
                                        '/share-sessions',
                                        data: {
                                          'requirement_id': req.id,
                                          'property_ids': selectedPropIds.toList(),
                                          'expiry_days': 7
                                        },
                                      );
                                      if (response.data != null && response.data['success'] == true) {
                                        final sessionId = response.data['data']['session']['id'];
                                        final authState = context.read<AuthBloc>().state;
                                        String? currentAgentName;
                                        String? currentAgentMobile;
                                        if (authState is Authenticated) {
                                          currentAgentName = authState.user.fullName;
                                          currentAgentMobile = authState.user.mobile;
                                        }

                                        setDialogState(() {
                                          var link = "${AppConfig.publicShareBaseUrl}/$sessionId";
                                          final queryParams = <String>[];
                                          if (currentAgentName != null && currentAgentName.isNotEmpty) {
                                            queryParams.add("agentName=${Uri.encodeComponent(currentAgentName)}");
                                          }
                                          if (currentAgentMobile != null && currentAgentMobile.isNotEmpty) {
                                            queryParams.add("agentMobile=${Uri.encodeComponent(currentAgentMobile)}");
                                          }
                                          if (queryParams.isNotEmpty) {
                                            link += "?${queryParams.join('&')}";
                                          }
                                          generatedLink = link;
                                          isGeneratingLink = false;
                                        });
                                      } else {
                                        setDialogState(() {
                                          error = "Failed to generate link.";
                                          isGeneratingLink = false;
                                        });
                                      }
                                    } catch (e) {
                                      setDialogState(() {
                                        error = "Failed to generate link.";
                                        isGeneratingLink = false;
                                      });
                                    }
                                  },
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kWhatsAppGreen,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                            label: const Text("Share on WhatsApp", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            onPressed: selectedPropIds.isEmpty || isGeneratingLink || isSharingPdf
                                ? null
                                : () => shareViaWhatsAppDirect(),
                          ),
                        ],
                      ),
                  ],
                ),
                if (isGeneratingLink || isSharingPdf)
                  Positioned.fill(
                    child: Container(
                      color: CRMColors.overlayOf(context),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: CRMSpacing.s),
                            Text(
                              isSharingPdf ? 'Preparing property PDF(s)...' : 'Generating share link & message...',
                              style: CRMTypography.caption.copyWith(color: CRMColors.textOf(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    ).then((_) => searchController.dispose());
  }

  void _showRequirementDetailDrawer(RequirementModel req) {
    AuditTelemetryService.instance.trackPropertyTouch(
      propertyId: req.id,
      propertyTitle: req.clientName,
      touchType: 'lead_detail_view',
      extra: {
        'client_name': req.clientName,
        'client_mobile': req.clientMobile,
        'category': req.categoryName,
        'areas': req.areaNames.join(', '),
        'min_budget': req.minBudget,
        'max_budget': req.maxBudget,
      },
    );
    showCRMRequirementDrawer(context, req);
  }
}

class RequirementStepperDialog extends StatefulWidget {
  final RequirementModel requirement;
  final int initialStep;
  final VoidCallback onSaved;
  final bool updateStatusOnSave;
  final bool isSiteVisit;
  final void Function(DateTime scheduledDate)? onSavedWithDate;

  const RequirementStepperDialog({
    super.key,
    required this.requirement,
    this.initialStep = 1,
    required this.onSaved,
    this.onSavedWithDate,
    this.updateStatusOnSave = false,
    this.isSiteVisit = false,
  });

  @override
  State<RequirementStepperDialog> createState() => _RequirementStepperDialogState();
}

class _RequirementStepperDialogState extends State<RequirementStepperDialog> {
  late int _currentStep;
  DateTime _followupDate = DateTime.now();
  TimeOfDay _followupTime = TimeOfDay.now();
  final TextEditingController _remarksController = TextEditingController();
  bool _isSavingFollowup = false;
  final Set<String> _completedFollowupIds = {};
  final List<Map<String, dynamic>> _localAddedFollowups = [];

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    if (widget.requirement.nextFollowupDate != null && widget.requirement.nextFollowupDate!.trim().isNotEmpty) {
      final parsed = _parseFollowupDateTime(widget.requirement.nextFollowupDate);
      if (parsed != null) {
        _followupDate = parsed;
        _followupTime = TimeOfDay.fromDateTime(parsed);
      } else {
        _followupDate = DateTime.now();
        _followupTime = TimeOfDay.now();
      }
    } else {
      _followupDate = DateTime.now();
      _followupTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _saveFollowup() async {
    final remarks = _remarksController.text.trim();
    if (remarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter ${widget.isSiteVisit ? "site visit" : "followup"} remarks.')),
      );
      return;
    }

    setState(() => _isSavingFollowup = true);
    try {
      final scheduledDateTime = DateTime(
        _followupDate.year,
        _followupDate.month,
        _followupDate.day,
        _followupTime.hour,
        _followupTime.minute,
      );
      final isoDateStr = scheduledDateTime.toUtc().toIso8601String();

      if (widget.isSiteVisit) {
        try {
          await DioClient.dio.post('/site-visits', data: {
            'requirement_id': widget.requirement.id,
            'visit_date': isoDateStr,
            'remarks': remarks,
          });
        } catch (e) {
          debugPrint('⚠️ Site visit API error: $e');
        }

        try {
          await DioClient.dio.post('/followups', data: {
            'client_name': widget.requirement.clientName,
            'mobile': widget.requirement.clientMobile,
            'notes': remarks,
            'followup_date': isoDateStr,
            'requirement_id': widget.requirement.id,
            'status': 'Site Visit Scheduled',
          });
        } catch (e) {
          debugPrint('⚠️ Site visit followup API error: $e');
        }

        try {
          final authState = context.read<AuthBloc>().state;
          final currentUser = authState is Authenticated ? authState.user : null;

          final newFollowupLocal = FollowupLocal()
            ..id = 'local_sv_${DateTime.now().millisecondsSinceEpoch}'
            ..requirementId = widget.requirement.id
            ..clientName = widget.requirement.clientName
            ..mobile = widget.requirement.clientMobile
            ..followupDate = scheduledDateTime
            ..notes = remarks
            ..status = 'Site Visit Scheduled'
            ..createdBy = currentUser?.fullName ?? 'Propkart Admin'
            ..createdAt = DateTime.now();

          await RepositoryCoordinator().followupLocal.saveFollowups([newFollowupLocal]);
        } catch (e) {
          debugPrint('⚠️ Local site visit followup save error: $e');
        }

        final authState = context.read<AuthBloc>().state;
        final currentUser = authState is Authenticated ? authState.user : null;

        final Map<String, dynamic> nextCustomFields = Map<String, dynamic>.from(widget.requirement.metaCustomFields ?? {});
        if (currentUser?.role == 'Sales') {
          nextCustomFields['handled_by_sales'] = true;
          if (!nextCustomFields.containsKey('telecaller_status')) {
            nextCustomFields['telecaller_status'] = widget.requirement.status;
          }
          nextCustomFields['sales_handled_at'] = DateTime.now().toIso8601String();
        }

        final RequirementsRepository requirementsRepository = RequirementsRepository();
        final updatedReq = widget.requirement.copyWith(
          status: 'Site Visit',
          nextFollowupDate: isoDateStr,
          remarks: (widget.requirement.remarks != null && widget.requirement.remarks!.isNotEmpty) ? widget.requirement.remarks : remarks,
          metaCustomFields: nextCustomFields,
        );
        final saved = await requirementsRepository.updateLeadStatus(updatedReq);
        final finalReq = saved.copyWith(
          nextFollowupDate: (saved.nextFollowupDate != null && saved.nextFollowupDate!.isNotEmpty) ? saved.nextFollowupDate : isoDateStr,
          remarks: (widget.requirement.remarks != null && widget.requirement.remarks!.isNotEmpty)
              ? widget.requirement.remarks
              : ((saved.remarks != null && saved.remarks!.isNotEmpty) ? saved.remarks : null),
          createdBy: (saved.createdBy != null && saved.createdBy!.isNotEmpty) ? saved.createdBy : widget.requirement.createdBy,
          creatorName: (saved.creatorName != null && saved.creatorName!.isNotEmpty) ? saved.creatorName : widget.requirement.creatorName,
          assignedTo: (saved.assignedTo != null && saved.assignedTo!.isNotEmpty) ? saved.assignedTo : widget.requirement.assignedTo,
          assigneeName: (saved.assigneeName != null && saved.assigneeName!.isNotEmpty) ? saved.assigneeName : widget.requirement.assigneeName,
          metaCustomFields: nextCustomFields,
        );
        await RepositoryCoordinator().requirementLocal.saveRequirements([finalReq.toLocal()]);

        RepositoryCoordinator().refreshDashboard();
        RepositoryCoordinator().refreshRequirements();
      } else {
        await DioClient.dio.post('/followups', data: {
          'client_name': widget.requirement.clientName,
          'mobile': widget.requirement.clientMobile,
          'notes': remarks,
          'followup_date': isoDateStr,
          'requirement_id': widget.requirement.id,
        });

        _localAddedFollowups.add({
          'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
          'requirement_id': widget.requirement.id,
          'client_name': widget.requirement.clientName,
          'mobile': widget.requirement.clientMobile,
          'followup_date': isoDateStr,
          'notes': remarks,
          'status': 'Pending',
          'creator_name': 'Propkart Admin',
        });

        try {
          final authState = context.read<AuthBloc>().state;
          final currentUser = authState is Authenticated ? authState.user : null;

          final newFollowupLocal = FollowupLocal()
            ..id = 'local_${DateTime.now().millisecondsSinceEpoch}'
            ..requirementId = widget.requirement.id
            ..clientName = widget.requirement.clientName
            ..mobile = widget.requirement.clientMobile
            ..followupDate = scheduledDateTime
            ..notes = remarks
            ..status = 'Pending'
            ..createdBy = currentUser?.fullName ?? 'Propkart Admin'
            ..createdAt = DateTime.now();

          await RepositoryCoordinator().followupLocal.saveFollowups([newFollowupLocal]);
        } catch (e) {
          debugPrint('⚠️ Local followup save error: $e');
        }

        final authState = context.read<AuthBloc>().state;
        final currentUser = authState is Authenticated ? authState.user : null;

        final Map<String, dynamic> nextCustomFields = Map<String, dynamic>.from(widget.requirement.metaCustomFields ?? {});
        if (currentUser?.role == 'Sales') {
          nextCustomFields['handled_by_sales'] = true;
          if (!nextCustomFields.containsKey('telecaller_status')) {
            nextCustomFields['telecaller_status'] = widget.requirement.status;
          }
          nextCustomFields['sales_handled_at'] = DateTime.now().toIso8601String();
        }

        final RequirementsRepository requirementsRepository = RequirementsRepository();
        final bool hasPreviousFollowup = widget.requirement.status == 'Follow-up' ||
            widget.requirement.status == 'Re-Followup' ||
            widget.requirement.nextFollowupDate != null;
        final String targetStatus = hasPreviousFollowup ? 'Re-Followup' : 'Follow-up';

        final updatedReq = widget.requirement.copyWith(
          status: targetStatus,
          nextFollowupDate: isoDateStr,
          remarks: (widget.requirement.remarks != null && widget.requirement.remarks!.isNotEmpty) ? widget.requirement.remarks : remarks,
          metaCustomFields: nextCustomFields,
        );
        final saved = await requirementsRepository.updateLeadStatus(updatedReq);
        final finalReq = saved.copyWith(
          nextFollowupDate: (saved.nextFollowupDate != null && saved.nextFollowupDate!.isNotEmpty) ? saved.nextFollowupDate : isoDateStr,
          remarks: (widget.requirement.remarks != null && widget.requirement.remarks!.isNotEmpty)
              ? widget.requirement.remarks
              : ((saved.remarks != null && saved.remarks!.isNotEmpty) ? saved.remarks : null),
          createdBy: (saved.createdBy != null && saved.createdBy!.isNotEmpty) ? saved.createdBy : widget.requirement.createdBy,
          creatorName: (saved.creatorName != null && saved.creatorName!.isNotEmpty) ? saved.creatorName : widget.requirement.creatorName,
          assignedTo: (saved.assignedTo != null && saved.assignedTo!.isNotEmpty) ? saved.assignedTo : widget.requirement.assignedTo,
          assigneeName: (saved.assigneeName != null && saved.assigneeName!.isNotEmpty) ? saved.assigneeName : widget.requirement.assigneeName,
          metaCustomFields: nextCustomFields,
        );
        await RepositoryCoordinator().requirementLocal.saveRequirements([finalReq.toLocal()]);

        RepositoryCoordinator().refreshDashboard();
        RepositoryCoordinator().refreshRequirements();
      }

      if (mounted) {
        widget.onSavedWithDate?.call(scheduledDateTime);
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isSiteVisit ? 'Site visit scheduled successfully!' : 'Followup added successfully!'),
            backgroundColor: CRMColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingFollowup = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isSiteVisit ? 'Failed to schedule site visit: $e' : 'Failed to add followup: $e'),
            backgroundColor: CRMColors.danger,
          ),
        );
      }
    }
  }



  Future<List<Map<String, dynamic>>> _fetchClientPastFollowups() async {
    final List<Map<String, dynamic>> result = [];

    bool isSiteVisitStatus(String statusStr) {
      final s = statusStr.trim().toLowerCase();
      return s.contains('site visit') || s.contains('sitevisit') || s == 'sv' || s.startsWith('site visit');
    }

    if (widget.isSiteVisit) {
      // 1. Fetch site visits API
      try {
        final response = await DioClient.dio.get('/site-visits', queryParameters: {
          'requirement_id': widget.requirement.id,
        });

        if (response.statusCode == 200 && response.data != null) {
          final svList = response.data['data']?['site_visits'] as List? ?? response.data['data'] as List?;
          if (svList != null) {
            for (final item in svList) {
              final mapItem = Map<String, dynamic>.from(item as Map);
              mapItem['status'] = mapItem['status'] ?? 'Site Visit Scheduled';
              mapItem['followup_date'] = mapItem['visit_date'] ?? mapItem['followup_date'] ?? mapItem['created_at'];
              mapItem['notes'] = mapItem['remarks'] ?? mapItem['notes'] ?? 'Site Visit';
              result.add(mapItem);
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching site-visits API: $e');
      }

      // 2. Fetch followups API filtered to Site Visit status
      try {
        final response = await DioClient.dio.get('/followups', queryParameters: {
          'requirement_id': widget.requirement.id,
          'mobile': widget.requirement.clientMobile,
        });

        if (response.statusCode == 200 && response.data != null) {
          final followupsData = response.data['data']?['followups'] as List?;
          if (followupsData != null) {
            for (final item in followupsData) {
              final mapItem = Map<String, dynamic>.from(item as Map);
              final st = (mapItem['status'] ?? '').toString();
              if (isSiteVisitStatus(st)) {
                final exists = result.any((r) => r['notes'] == mapItem['notes'] && r['followup_date'] == mapItem['followup_date']);
                if (!exists) result.add(mapItem);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching past followups API: $e');
      }

      // 3. Include local added site visit followups
      final localFollowups = FollowupLocalRepository.inMemory.values
          .where((fl) => fl.requirementId == widget.requirement.id && isSiteVisitStatus(fl.status))
          .map((fl) => {
                'id': fl.id,
                'requirement_id': fl.requirementId,
                'client_name': fl.clientName,
                'mobile': fl.mobile,
                'followup_date': fl.followupDate.toIso8601String(),
                'notes': fl.notes,
                'status': fl.status,
                'creator_name': fl.createdBy,
              });
      for (final loc in localFollowups) {
        final exists = result.any((r) => r['notes'] == loc['notes'] && r['followup_date'] == loc['followup_date']);
        if (!exists) result.add(loc);
      }
    } else {
      // Regular Follow-ups mode
      try {
        final response = await DioClient.dio.get('/followups', queryParameters: {
          'requirement_id': widget.requirement.id,
          'mobile': widget.requirement.clientMobile,
        });

        if (response.statusCode == 200 && response.data != null) {
          final followupsData = response.data['data']?['followups'] as List?;
          if (followupsData != null) {
            for (final item in followupsData) {
              final mapItem = Map<String, dynamic>.from(item as Map);
              final st = (mapItem['status'] ?? '').toString();
              // EXCLUDE Site Visit status in regular follow-ups history
              if (!isSiteVisitStatus(st)) {
                result.add(mapItem);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching past followups API: $e');
      }

      // Include local added followups excluding site visits
      for (final loc in _localAddedFollowups) {
        final st = (loc['status'] ?? '').toString();
        if (!isSiteVisitStatus(st)) {
          final exists = result.any((r) => r['notes'] == loc['notes'] && r['followup_date'] == loc['followup_date']);
          if (!exists) result.add(loc);
        }
      }

      final localFollowups = FollowupLocalRepository.inMemory.values
          .where((fl) => fl.requirementId == widget.requirement.id && !isSiteVisitStatus(fl.status))
          .map((fl) => {
                'id': fl.id,
                'requirement_id': fl.requirementId,
                'client_name': fl.clientName,
                'mobile': fl.mobile,
                'followup_date': fl.followupDate.toIso8601String(),
                'notes': fl.notes,
                'status': fl.status,
                'creator_name': fl.createdBy,
              });
      for (final loc in localFollowups) {
        final exists = result.any((r) => r['notes'] == loc['notes'] && r['followup_date'] == loc['followup_date']);
        if (!exists) result.add(loc);
      }

      // Combine with local requirement remarks if fallback is needed
      if (result.isEmpty && widget.requirement.remarks != null && widget.requirement.remarks!.isNotEmpty && !isSiteVisitStatus(widget.requirement.status)) {
        result.add({
          'id': 'fallback_${widget.requirement.id}',
          'followup_date': widget.requirement.nextFollowupDate ?? DateTime.now().toIso8601String(),
          'notes': widget.requirement.remarks,
          'status': widget.requirement.status,
          'creator_name': 'Sales Executive',
        });
      }
    }

    // Sort newest first
    result.sort((a, b) {
      final dateA = _parseFollowupDateTime(a['followup_date'] ?? a['created_at']) ?? DateTime(1970);
      final dateB = _parseFollowupDateTime(b['followup_date'] ?? b['created_at']) ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    return result;
  }

  Widget _buildPastFollowupsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchClientPastFollowups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load past follow-ups: ${snapshot.error}',
              style: TextStyle(color: CRMColors.danger),
            ),
          );
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(CRMBorderRadius.m),
              border: Border.all(color: CRMColors.borderOf(context).withValues(alpha: 0.3)),
            ),
            child: Text(
              'No past follow-ups recorded yet for ${widget.requirement.clientName}.',
              style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Container(
          constraints: const BoxConstraints(maxHeight: 320),
          margin: const EdgeInsets.only(bottom: CRMSpacing.m),
          decoration: BoxDecoration(
            color: CRMColors.primary.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(CRMBorderRadius.m),
            border: Border.all(color: CRMColors.primary.withValues(alpha: 0.2), width: 1.2),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(CRMSpacing.s),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: CRMSpacing.xs),
            itemBuilder: (context, index) {
              final f = items[index];
              final itemId = f['id']?.toString() ?? 'item_$index';
              final parsedDate = _parseFollowupDateTime(f['followup_date'] ?? f['created_at']);
              final formattedDate = parsedDate != null
                  ? DateFormat('dd/MM/yyyy hh:mm a').format(parsedDate)
                  : 'Date N/A';

              final remarks = f['notes'] ?? f['remarks'] ?? 'No remarks recorded';
              final creatorName = f['creator_name'] ?? f['creator']?['full_name'] ?? 'Sales Executive';
              
              final now = DateTime.now();
              String rawStatus = (f['status'] ?? '').toString();
              bool isExplicitlyCompleted = _completedFollowupIds.contains(itemId) ||
                  rawStatus == 'Completed' ||
                  rawStatus == 'Done' ||
                  rawStatus == 'Resolved';

              final bool isFutureDate = parsedDate != null && parsedDate.isAfter(now);
              final bool isCompleted = isExplicitlyCompleted;
              final String status = (isFutureDate && !isCompleted) ? 'Pending' : (isCompleted ? 'Completed' : 'Pending');

              return Container(
                padding: const EdgeInsets.all(CRMSpacing.s),
                decoration: BoxDecoration(
                  color: CRMColors.cardBgOf(context),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                  border: Border.all(color: CRMColors.borderOf(context).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.event_note_rounded, size: 16, color: CRMColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              formattedDate,
                              style: CRMTypography.captionBold.copyWith(
                                color: CRMColors.primary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? CRMColors.success.withValues(alpha: 0.15)
                                    : CRMColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                status,
                                style: CRMTypography.captionBold.copyWith(
                                  color: isCompleted
                                      ? CRMColors.success
                                      : CRMColors.warning,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            if (!isCompleted) ...[
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () async {
                                  setState(() {
                                    f['status'] = 'Completed';
                                    _completedFollowupIds.add(itemId);
                                  });
                                  try {
                                    if (itemId.isNotEmpty && !itemId.startsWith('local_') && !itemId.startsWith('fallback_')) {
                                      await DioClient.dio.put('/followups/$itemId', data: {'status': 'Completed'});
                                    }
                                  } catch (e) {
                                    debugPrint('Error completing followup: $e');
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Followup marked as Completed!'),
                                        backgroundColor: CRMColors.success,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: CRMColors.success.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: CRMColors.success.withValues(alpha: 0.4)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 14, color: CRMColors.success),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Complete',
                                        style: CRMTypography.captionBold.copyWith(
                                          color: CRMColors.success,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      remarks,
                      style: CRMTypography.body.copyWith(color: CRMColors.textOf(context), fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 12, color: CRMColors.textSecondaryOf(context)),
                        const SizedBox(width: 4),
                        Text(
                          'Logged by: $creatorName',
                          style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Dialog(
      backgroundColor: CRMColors.cardBgOf(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.l)),
      child: Container(
        width: isMobile ? double.infinity : 700,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(CRMSpacing.m),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.isSiteVisit ? 'Update Requirement & Add Site Visit' : 'Update Requirement & Add Followup',
                      style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Stepper Content
            Expanded(
              child: Stepper(
                type: StepperType.horizontal,
                currentStep: _currentStep,
                onStepTapped: (step) => setState(() => _currentStep = step),
                controlsBuilder: (context, details) => const SizedBox.shrink(),
                steps: [
                  Step(
                    title: const Text('Edit Details'),
                    isActive: _currentStep == 0,
                    state: _currentStep == 0 ? StepState.editing : StepState.complete,
                    content: SizedBox(
                      height: 500,
                      child: AddEditRequirementScreen(
                        requirement: widget.requirement,
                        isInline: true,
                        onSaved: () {
                          widget.onSaved();
                          setState(() => _currentStep = 1);
                        },
                      ),
                    ),
                  ),
                  Step(
                    title: Text(widget.isSiteVisit ? 'Add Site Visit' : 'Add Followup'),
                    isActive: _currentStep == 1,
                    state: _currentStep == 1 ? StepState.editing : StepState.indexed,
                    content: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: CRMSpacing.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Client: ${widget.requirement.clientName} (${widget.requirement.clientMobile})',
                                    style: CRMTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: CRMColors.primary,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.history_rounded, size: 16),
                                  label: const Text('Past Follow-ups'),
                                  onPressed: () => setState(() => _currentStep = 2),
                                ),
                              ],
                            ),
                            const SizedBox(height: CRMSpacing.m),
                            // Date & Time pickers row
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _followupDate,
                                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                        lastDate: DateTime(2030),
                                      );
                                      if (picked != null) {
                                        setState(() => _followupDate = picked);
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: widget.isSiteVisit ? 'Site Visit Date *' : 'Followup Date *',
                                        prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                                      ),
                                      child: Text(DateFormat('dd/MM/yyyy').format(_followupDate)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: CRMSpacing.m),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime: _followupTime,
                                      );
                                      if (picked != null) {
                                        setState(() => _followupTime = picked);
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: widget.isSiteVisit ? 'Site Visit Time *' : 'Followup Time *',
                                        prefixIcon: const Icon(Icons.access_time_rounded, size: 18),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                                      ),
                                      child: Text(_followupTime.format(context)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: CRMSpacing.m),
                            // Remarks textfield
                            TextField(
                              controller: _remarksController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: widget.isSiteVisit ? 'Site Visit Remarks *' : 'Followup Remarks *',
                                hintText: widget.isSiteVisit
                                    ? 'Enter location, property code, meeting notes...'
                                    : 'Enter call summary, next meeting notes or client feedback...',
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.s)),
                              ),
                            ),
                            const SizedBox(height: CRMSpacing.l),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: CRMSpacing.m),
                                CRMButton(
                                  label: _isSavingFollowup
                                      ? 'Saving...'
                                      : (widget.isSiteVisit
                                          ? 'Save Site Visit'
                                          : ((widget.requirement.status == 'Follow-up' || widget.requirement.status == 'Re-Followup' || widget.requirement.nextFollowupDate != null)
                                              ? 'Save Re-Followup'
                                              : 'Save Followup')),
                                  onPressed: _isSavingFollowup ? null : _saveFollowup,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Step(
                    title: const Text('Past Follow-ups'),
                    isActive: _currentStep == 2,
                    state: _currentStep == 2 ? StepState.editing : StepState.indexed,
                    content: SizedBox(
                      height: 450,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Client: ${widget.requirement.clientName} (${widget.requirement.clientMobile})',
                            style: CRMTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: CRMColors.primary,
                            ),
                          ),
                          const SizedBox(height: CRMSpacing.m),
                          Expanded(child: _buildPastFollowupsList()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunMatchesButtonWithBadge extends StatefulWidget {
  final RequirementModel requirement;
  final VoidCallback onPressed;
  final List<PropertyModel>? properties;
  final bool isMobileIconOnly;

  const _RunMatchesButtonWithBadge({
    required this.requirement,
    required this.onPressed,
    this.properties,
    this.isMobileIconOnly = false,
  });

  @override
  State<_RunMatchesButtonWithBadge> createState() => _RunMatchesButtonWithBadgeState();
}

class _RunMatchesButtonWithBadgeState extends State<_RunMatchesButtonWithBadge> {
  int? _matchCount;

  @override
  void initState() {
    super.initState();
    MatchCriteriaManager().addListener(_onCriteriaChanged);
    _computeCount();
  }

  void _onCriteriaChanged() {
    if (mounted) {
      _computeCount();
    }
  }

  @override
  void dispose() {
    MatchCriteriaManager().removeListener(_onCriteriaChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _RunMatchesButtonWithBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requirement != widget.requirement || oldWidget.properties != widget.properties) {
      _computeCount();
    }
  }

  Future<void> _computeCount() async {
    List<PropertyModel> props = widget.properties ?? [];
    if (props.isEmpty) {
      try {
        props = await PropertiesRepository().getProperties();
      } catch (_) {}
    }

    int count = 0;
    for (final p in props) {
      if (await _RequirementsScreenState._isRequirementPropertyMatchAsync(p, widget.requirement)) {
        count++;
      }
    }

    if (mounted) {
      setState(() {
        _matchCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget button;
    if (widget.isMobileIconOnly) {
      button = Tooltip(
        message: 'Matches',
        child: IconButton(
          icon: const Icon(Icons.bolt_rounded, color: CRMColors.warning, size: 16),
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          style: IconButton.styleFrom(
            backgroundColor: CRMColors.warning.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.zero,
          ),
          onPressed: widget.onPressed,
        ),
      );
    } else {
      button = CRMButton(
        label: "Run Matches",
        prefixIcon: Icons.bolt_rounded,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s),
        onPressed: widget.onPressed,
      );
    }

    if (_matchCount == null) {
      return button;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          top: widget.isMobileIconOnly ? -4 : -6,
          right: widget.isMobileIconOnly ? -4 : -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
            decoration: BoxDecoration(
              color: _matchCount! > 0 ? const Color(0xFFEF4444) : const Color(0xFF6B7280),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$_matchCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CRMPropertyMatchesDrawer extends StatefulWidget {
  final RequirementModel requirement;
  final List<PropertyModel>? properties;

  const _CRMPropertyMatchesDrawer({
    required this.requirement,
    this.properties,
  });

  @override
  State<_CRMPropertyMatchesDrawer> createState() => _CRMPropertyMatchesDrawerState();
}

class _CRMPropertyMatchesDrawerState extends State<_CRMPropertyMatchesDrawer> {
  final PropertiesRepository _propertiesRepository = PropertiesRepository();
  bool _isLoading = true;
  List<PropertyModel> _matchedProperties = [];
  Map<String, PropertyMatchResult> _matchResults = {};
  bool _includePhotos = true;

  Color _getMatchScoreColor(int pct) {
    if (pct >= 80) return const Color(0xFF10B981);
    if (pct >= 60) return const Color(0xFF0F766E);
    if (pct >= 40) return const Color(0xFF0288D1);
    return const Color(0xFFD97706);
  }

  Future<void> _shareProperty(PropertyModel p) async {
    final BHK = p.configurationName ?? "${p.bedrooms} BHK";
    final size = p.superBuiltupArea != null ? "${p.superBuiltupArea} sq ft" : "${p.plotArea ?? '-'} sq ft";
    final price = '₹${BudgetFormatter.format(p.price)}';
    
    final isWonReq = widget.requirement.status.toLowerCase() == 'won' || widget.requirement.status.toLowerCase() == 'closed';
    final headerMsg = isWonReq
        ? "Dear ${widget.requirement.clientName},\n\nHere are the details of the property selected for your finalized deal:\n\n"
        : "Dear Customer,\n\nWe found a property matching your requirements.\n\n";

    final message = "$headerMsg"
        "Reference ID: ${p.propertyCode}\n\n"
        "📍 Location: ${p.areaName}\n\n"
        "🏠 Configuration: $BHK\n\n"
        "📐 Size: $size\n\n"
        "💰 Price: $price\n\n"
        "📞 For more details, please contact NB Prop Tech.";

    if (_includePhotos && p.images != null && p.images!.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final directory = await getTemporaryDirectory();
        final List<XFile> xFiles = [];
        final limit = p.images!.length > 3 ? 3 : p.images!.length;
        for (int i = 0; i < limit; i++) {
          final imgUrl = p.images![i];
          final ext = imgUrl.split('.').last.split('?').first;
          final filePath = '${directory.path}/share_${p.propertyCode}_$i.$ext';
          await DioClient.dio.download(imgUrl, filePath);
          xFiles.add(XFile(filePath));
        }
        
        Navigator.pop(context);
        
        await Share.shareXFiles(xFiles, text: message);
        await _logShareAction(p, true);
      } catch (e) {
        Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to download images: $e')),
          );
        }
      }
    } else {
      final phone = widget.requirement.clientMobile;
      final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        await _logShareAction(p, false);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch WhatsApp')),
          );
        }
      }
    }
  }

  Future<void> _logShareAction(PropertyModel p, bool isPhotoIncluded) async {
    try {
      await DioClient.dio.post('/audit/share', data: {
        'recordId': p.id,
        'clientMobile': widget.requirement.clientMobile,
        'requirementId': widget.requirement.id,
        'isPhotoIncluded': isPhotoIncluded,
      });
    } catch (e) {
      print("Failed to log share action: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAndFilterMatches();
  }

  Future<bool> _isRequirementPropertyMatchAsync(PropertyModel p, RequirementModel req) async {
    return _RequirementsScreenState._isRequirementPropertyMatchAsync(p, req);
  }

  Future<void> _loadAndFilterMatches() async {
    try {
      final req = widget.requirement;
      final isWonReq = req.status.toLowerCase() == 'won' || req.status.toLowerCase() == 'closed';

      if (isWonReq) {
        final properties = await _propertiesRepository.getProperties();
        List<String> wonIds = await PropertyDealClientStore.getWonPropertyIds(req.id);
        String? wonClientName = await PropertyDealClientStore.getClientName(req.id);
        final List<PropertyMatchResult> results = [];
        for (final p in properties) {
          final isWon = wonIds.contains(p.id) || (wonClientName != null && wonClientName.trim().toLowerCase() == req.clientName.trim().toLowerCase());
          if (isWon) {
            results.add(PropertyMatchResult(
              property: p,
              matchPercentage: 100,
              matchedCriteria: ['✓ Finalized Deal Property'],
            ));
          }
        }
        setState(() {
          _matchedProperties = results.map((r) => r.property).toList();
          _matchResults = { for (var r in results) r.property.id: r };
          _isLoading = false;
        });
        return;
      }

      // 1. Authoritative Backend Matching, then local engine so valid
      // Apartment / Flat-Apartment inventory is never dropped at the active threshold.
      final Map<String, PropertyMatchResult> byId = {};
      final threshold = MatchCriteriaManager().threshold;
      try {
        final serverResponse = await RequirementsRepository().getRequirementMatches(
          req.id,
          minScore: threshold,
          limit: 200,
        );
        final data = serverResponse['data'] as Map<String, dynamic>? ?? {};
        final rawMatches = data['matches'] as List? ?? [];
        for (final item in rawMatches) {
          if (item is! Map) continue;
          final pJson = item['property'] as Map<String, dynamic>? ?? {};
          final prop = PropertyModel.fromJson(pJson);
          if (!PropertyRequirementMatcher.isEligibleByCategoryAndType(prop, req)) continue;
          byId[prop.id] = PropertyMatchResult.fromServerJson(
            Map<String, dynamic>.from(item),
            prop,
          );
        }
      } catch (serverErr) {
        debugPrint("⚠️ [Backend Match Fallback] Falling back to local engine: $serverErr");
      }

      final properties = (widget.properties != null && widget.properties!.isNotEmpty)
          ? widget.properties!
          : await _propertiesRepository.getProperties();
      for (final p in properties) {
        final res = PropertyRequirementMatcher.match(p, req);
        if (res.matchPercentage >= threshold) {
          final existing = byId[p.id];
          if (existing == null || res.matchPercentage >= existing.matchPercentage) {
            byId[p.id] = res;
          }
        }
      }

      final results = byId.values.toList()
        ..sort((a, b) {
          final cmp = b.matchPercentage.compareTo(a.matchPercentage);
          if (cmp != 0) return cmp;
          return a.property.price.compareTo(b.property.price);
        });

      setState(() {
        _matchedProperties = results.map((r) => r.property).toList();
        _matchResults = { for (var r in results) r.property.id: r };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWonReq = widget.requirement.status.toLowerCase() == 'won' || widget.requirement.status.toLowerCase() == 'closed';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: CRMColors.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(CRMBorderRadius.l)),
      ),
      padding: const EdgeInsets.all(CRMSpacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(color: CRMColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: CRMSpacing.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isWonReq ? "Selected Deal Property" : "Matching System Listings", style: CRMTypography.sectionTitle),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: CRMSpacing.xs),
          Text(
            isWonReq
                ? "Property selected and finalized for client deal: ${widget.requirement.clientName}"
                : "Showing ${_matchedProperties.length} matching properties for ${widget.requirement.clientName} (≥${MatchCriteriaManager().threshold}% match criteria)",
            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!isWonReq && PropertyRequirementMatcher.isAllAreas(widget.requirement))
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF0F766E)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Client is interested in All Areas. All matching configurations and price ranges across the city are included.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: CRMSpacing.s),
          if (isWonReq)
            Container(
              margin: const EdgeInsets.only(bottom: CRMSpacing.s, top: CRMSpacing.xs),
              padding: const EdgeInsets.all(CRMSpacing.m),
              decoration: BoxDecoration(
                color: CRMColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                border: Border.all(color: CRMColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: CRMColors.success, size: 24),
                  const SizedBox(width: CRMSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Finalized Property for ${widget.requirement.clientName}',
                          style: CRMTypography.bodyMedium.copyWith(color: CRMColors.success, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'This is the property selected and assigned when winning this client deal.',
                          style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Text(
            "Include Property Photos and Videos",
            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
          ),
          const Divider(height: CRMSpacing.m),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_matchedProperties.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 48, color: CRMColors.textMuted),
                  const SizedBox(height: CRMSpacing.s),
                  Text("No Active Matches Found", style: CRMTypography.cardTitle),
                  const SizedBox(height: 4),
                  Text("No database properties currently fit these filters.", style: CRMTypography.body.copyWith(color: CRMColors.textSecondary)),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _matchedProperties.length,
                itemBuilder: (context, index) {
                  final p = _matchedProperties[index];
                  return Card(
                    color: CRMColors.background,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: CRMSpacing.s),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                      side: BorderSide(color: CRMColors.border),
                    ),
                    child: ListTile(
                      onTap: () => _openPropertyDetails(context, p),
                      contentPadding: const EdgeInsets.all(CRMSpacing.m),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              children: [
                                Text(p.title, style: CRMTypography.bodyMedium),
                                Builder(builder: (context) {
                                  final matchRes = _matchResults[p.id];
                                  final matchPct = matchRes?.matchPercentage ?? 0;
                                  if (isWonReq) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: CRMColors.success.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: CRMColors.success.withValues(alpha: 0.4)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_rounded, size: 12, color: CRMColors.success),
                                          const SizedBox(width: 4),
                                          Text('Won Deal Property', style: CRMTypography.caption.copyWith(color: CRMColors.success, fontWeight: FontWeight.bold, fontSize: 10)),
                                        ],
                                      ),
                                    );
                                  }
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: _getMatchScoreColor(matchPct).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: _getMatchScoreColor(matchPct).withValues(alpha: 0.45)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.auto_awesome_rounded, size: 12, color: _getMatchScoreColor(matchPct)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$matchPct% Match',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _getMatchScoreColor(matchPct),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          Text(
                            '₹${BudgetFormatter.format(p.price)}',
                            style: CRMTypography.bodyMedium.copyWith(color: CRMColors.primary),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(builder: (context) {
                            final matchRes = _matchResults[p.id];
                            if (matchRes == null || isWonReq) {
                              return const SizedBox.shrink();
                            }
                            final hasTags = matchRes.matchedCriteria.isNotEmpty || matchRes.unmatchedPreferences.isNotEmpty;
                            if (!hasTags) return const SizedBox.shrink();

                            return Padding(
                              padding: const EdgeInsets.only(top: 5, bottom: 4),
                              child: Wrap(
                                spacing: 5,
                                runSpacing: 4,
                                children: [
                                  ...matchRes.matchedCriteria.map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: CRMColors.success.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: CRMColors.success.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: CRMColors.success),
                                    ),
                                  )),
                                  ...matchRes.unmatchedPreferences.map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD97706).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      '~ $tag',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                                    ),
                                  )),
                                ],
                              ),
                            );
                          }),
                          if (!isWonReq && p.propertyStatusName.toLowerCase() == 'available')
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: CRMColors.info.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: CRMColors.info.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.info_outline_rounded, size: 14, color: CRMColors.info),
                                    const SizedBox(width: 6),
                                    Text(
                                      'This property is currently Available',
                                      style: CRMTypography.caption.copyWith(
                                        color: CRMColors.info,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 14, color: CRMColors.textSecondary),
                              const SizedBox(width: 4),
                              Text('${p.areaName}, ${p.cityName}', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.square_foot_rounded, size: 14, color: CRMColors.textSecondary),
                              const SizedBox(width: 4),
                              Text('${p.superBuiltupArea ?? "-"} sq ft', style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary)),
                              const SizedBox(width: CRMSpacing.m),
                              Icon(Icons.phone_iphone_rounded, size: 14, color: CRMColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${p.ownerName} (${p.ownerMobile})',
                                  style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  foregroundColor: CRMColors.primary,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.share_rounded, size: 14),
                                label: const Text('Share', style: TextStyle(fontSize: 11)),
                                onPressed: () => _shareProperty(p),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  foregroundColor: CRMColors.success,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.phone_rounded, size: 14),
                                label: const Text('Call', style: TextStyle(fontSize: 11)),
                                onPressed: () async {
                                  final url = Uri.parse('tel:${p.ownerMobile}');
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  }
                                },
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  foregroundColor: CRMColors.textSecondary,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 14),
                                label: const Text('Copy', style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  final BHK = p.configurationName ?? "${p.bedrooms} BHK";
                                  final size = p.superBuiltupArea != null ? "${p.superBuiltupArea} sq ft" : "${p.plotArea ?? '-'} sq ft";
                                  final price = '₹${BudgetFormatter.format(p.price)}';
                                  final message = "Dear Customer,\n\n"
                                      "We found a property matching your requirements.\n\n"
                                      "Reference ID: ${p.propertyCode}\n\n"
                                      "📍 Location: ${p.areaName}\n\n"
                                      "🏠 Configuration: $BHK\n\n"
                                      "📐 Size: $size\n\n"
                                      "💰 Price: $price\n\n"
                                      "📞 For more details, please contact NB Prop Tech.";
                                  Clipboard.setData(ClipboardData(text: message));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Copied to clipboard')),
                                  );
                                },
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.xs),
                                  foregroundColor: CRMColors.info,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.directions_rounded, size: 14),
                                label: const Text('Route', style: TextStyle(fontSize: 11)),
                                onPressed: () async {
                                  final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(p.title + ", " + p.areaName)}');
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openPropertyDetails(BuildContext context, PropertyModel p) {
    showCRMPropertyDrawer(context, p);
  }
}

String getEffectiveStatus(RequirementModel req) {
  String status = req.status;
  if (status == 'New' || status.isEmpty) {
    final now = DateTime.now();
    final difference = now.difference(req.createdAt);
    if (difference >= const Duration(hours: 24)) {
      return 'Not Started';
    }
    return 'New';
  }
  return status;
}

String displayStatusLabel(String status) {
  if (status == 'Assigned') return 'Assigned';
  if (status == 'New') return 'New';
  if (status == 'Not Started') return 'Not Started';
  if (status == 'Not Interested') return 'Not Interested';
  if (status == 'Live' || status == 'Active') return 'Interested';
  if (status == 'Dead' || status == 'Suspended') return 'Not Interested';
  if (status == 'Re-Followup') return 'Re-Followup';
  return status;
}

String getListingTypeLabel(RequirementModel r) {
  final name = r.listingTypeName ?? '';
  final id = r.listingTypeId ?? '';
  final combined = '$name $id'.toLowerCase();
  if (combined.contains('rent')) {
    return 'Rent';
  } else if (combined.contains('sale') || combined.contains('resale')) {
    return 'Re-Sale';
  }
  return 'Rent';
}

void showCRMRequirementDrawer(BuildContext context, RequirementModel req) {
  AuditTelemetryService.instance.trackButtonClick(
    buttonId: 'lead_detail_drawer_open',
    buttonLabel: 'View Lead Details',
    page: '/requirements',
    extra: {
      'lead_id': req.id,
      'client_name': req.clientName,
      'client_mobile': req.clientMobile,
      'category': req.categoryName,
      'areas': req.areaNames.join(', '),
      'min_budget': req.minBudget,
      'max_budget': req.maxBudget,
    },
  );
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return _CRMRequirementDetailDrawer(requirement: req);
    },
  );
}

class _CRMRequirementDetailDrawer extends StatefulWidget {
  final RequirementModel requirement;

  const _CRMRequirementDetailDrawer({required this.requirement});

  @override
  State<_CRMRequirementDetailDrawer> createState() => _CRMRequirementDetailDrawerState();
}

class _CRMRequirementDetailDrawerState extends State<_CRMRequirementDetailDrawer> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _sessions = [];
  List<LookupItem> _furnishings = [];
  List<LookupItem> _facings = [];

  // Summary fields
  int _totalSessions = 0;
  int _totalPropertiesShared = 0;
  int _totalViews = 0;
  String _lastViewed = "Never";

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final metadata = await PropertiesRepository().getPropertyMetadata();
      setState(() {
        _furnishings = metadata.furnishings;
        _facings = metadata.facings;
      });
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    try {
      final response = await DioClient.dio.get('/share-sessions/requirement/${widget.requirement.id}');
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data']['history'] ?? [];
        
        int totalProps = 0;
        int views = 0;
        DateTime? latestView;

        for (var s in list) {
          totalProps += (s['total_properties'] as num? ?? 0).toInt();
          views += (s['view_count'] as num? ?? 0).toInt();
          if (s['last_viewed'] != null) {
            final dt = DateTime.parse(s['last_viewed'].toString());
            if (latestView == null || dt.isAfter(latestView)) {
              latestView = dt;
            }
          }
        }

        String lastViewStr = "Never";
        if (latestView != null) {
          final now = DateTime.now();
          final diff = now.difference(latestView);
          if (diff.inMinutes < 60) {
            lastViewStr = "${diff.inMinutes}m ago";
          } else if (diff.inHours < 24) {
            lastViewStr = "${diff.inHours}h ago";
          } else {
            lastViewStr = DateFormat('dd MMM yyyy').format(latestView);
          }
        }

        setState(() {
          _sessions = list;
          _totalSessions = list.length;
          _totalPropertiesShared = totalProps;
          _totalViews = views;
          _lastViewed = lastViewStr;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load share history.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Failed to load share history.";
        _isLoading = false;
      });
    }
  }

  Future<void> _revokeSession(String sessionId) async {
    try {
      final response = await DioClient.dio.post('/share-sessions/$sessionId/revoke');
      if (response.data != null && response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Share link revoked successfully.")),
        );
        _loadHistory();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to revoke share link.")),
      );
    }
  }

  Widget _buildShareHistoryTable() {
    final req = widget.requirement;
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? Center(child: Text(_error!, style: const TextStyle(color: CRMColors.danger)))
            : _sessions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share_rounded, size: 48, color: CRMColors.textMuted),
                        const SizedBox(height: CRMSpacing.s),
                        Text("No share sessions generated yet.", style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context))),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: CRMDataTable(
                      columns: const [
                        DataColumn(label: Text("Session")),
                        DataColumn(label: Text("Date")),
                        DataColumn(label: Text("Shared By")),
                        DataColumn(label: Text("Properties")),
                        DataColumn(label: Text("Views")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Actions")),
                      ],
                      rows: _sessions.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final s = entry.value;
                        final dateStr = s['created_at'] != null 
                            ? DateFormat('dd-MM-yyyy').format(DateTime.parse(s['created_at'].toString()))
                            : '-';
                        final agentName = s['agent']?['full_name']?.toString() ?? '-';
                        final status = s['status'] ?? 'Active';
                        final agentMobile = s['agent']?['mobile']?.toString() ?? '';
                        var link = "${AppConfig.publicShareBaseUrl}/${s['id']}";
                        final queryParams = <String>[];
                        if (agentName != '-' && agentName.isNotEmpty) {
                          queryParams.add("agentName=${Uri.encodeComponent(agentName)}");
                        }
                        if (agentMobile.isNotEmpty) {
                          queryParams.add("agentMobile=${Uri.encodeComponent(agentMobile)}");
                        }
                        if (queryParams.isNotEmpty) {
                          link += "?${queryParams.join('&')}";
                        }

                        return DataRow(
                          cells: [
                            DataCell(Text("Share #${_sessions.length - idx}", style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context)))),
                            DataCell(Text(dateStr, style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)))),
                            DataCell(Text(agentName, style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)))),
                            DataCell(Text("${s['total_properties'] ?? 0}", style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)))),
                            DataCell(Text("${s['view_count'] ?? 0}", style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.xs, vertical: CRMSpacing.xxs),
                                decoration: BoxDecoration(
                                  color: (status == 'Active'
                                      ? CRMColors.success
                                      : status == 'Expired'
                                          ? CRMColors.warning
                                          : CRMColors.danger)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
                                ),
                                child: Text(
                                  status,
                                  style: CRMTypography.captionBold.copyWith(
                                    fontSize: 11,
                                    color: status == 'Active'
                                        ? CRMColors.success
                                        : status == 'Expired'
                                            ? CRMColors.warning
                                            : CRMColors.danger,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.copy_rounded, size: 16),
                                    tooltip: "Copy Link",
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: link));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Link copied to clipboard!")),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                    tooltip: "Open Link",
                                    onPressed: () async {
                                      final uri = Uri.parse(link);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                                      }
                                    },
                                  ),
                                  if (agentMobile.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: kWhatsAppGreen),
                                      tooltip: "Re-share via WhatsApp",
                                      onPressed: () async {
                                        final text = Uri.encodeComponent("Hello, here is your shortlisted property collection: $link");
                                        final url = "https://wa.me/?text=$text";
                                        final uri = Uri.parse(url);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                    ),
                                  if (status == 'Active')
                                    IconButton(
                                      icon: const Icon(Icons.block_rounded, size: 16, color: CRMColors.danger),
                                      tooltip: "Revoke Link",
                                      onPressed: () => _revokeSession(s['id']),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
  }

  Widget build(BuildContext context) {
    final req = widget.requirement;
    final furnishingNames = req.furnishingIds.map((id) {
      final match = _furnishings.firstWhere(
        (f) => f.id == id,
        orElse: () => LookupItem(id: id, name: id),
      );
      return match.name;
    }).toList();
    final furnishingName = furnishingNames.isNotEmpty ? furnishingNames.join(', ') : '';

    final facingNames = req.facingIds.map((id) {
      final match = _facings.firstWhere(
        (f) => f.id == id,
        orElse: () => LookupItem(id: id, name: id),
      );
      return match.name;
    }).toList();
    final facingName = facingNames.isNotEmpty ? facingNames.join(', ') : '';
    final budget = '₹${BudgetFormatter.format(req.minBudget)} - ₹${BudgetFormatter.format(req.maxBudget)}';
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final isMobile = width < 768;
    final isDesktop = width >= 950;

    final double dialogWidth = isMobile ? width * 0.95 : width * 0.85;
    final double dialogHeight = isMobile ? height * 0.95 : height * 0.85;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth.clamp(320.0, 1100.0),
          height: dialogHeight.clamp(480.0, 800.0),
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(CRMBorderRadius.l),
            boxShadow: CRMShadows.large,
          ),
          padding: const EdgeInsets.all(CRMSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Requirement Details & Share History",
                      style: CRMTypography.sectionTitle.copyWith(
                        color: CRMColors.textOf(context),
                        fontSize: isMobile ? 16 : 20,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: CRMSpacing.m),

            Expanded(
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column: Info card & summary metrics
                        Expanded(
                          flex: 2,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CRMCard(
                                  child: Padding(
                                    padding: const EdgeInsets.all(CRMSpacing.m),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          req.clientName,
                                          style: CRMTypography.sectionTitle.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: CRMColors.textOf(context),
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: CRMSpacing.xs),
                                        Text(
                                          req.clientMobile,
                                          style: CRMTypography.body.copyWith(
                                            color: CRMColors.textSecondaryOf(context),
                                          ),
                                        ),
                                        if (req.matchingReadiness != 'Ready') ...[
                                          const SizedBox(height: CRMSpacing.xs),
                                          _buildNeedsMoreDetailsBadge(req),
                                        ],
                                        const Divider(height: 24),
                                        _buildDetailRow("Code", req.requirementCode, Icons.qr_code_rounded),
                                        _buildDetailRow("Date", DateFormat('dd/MM/yyyy').format(req.createdAt), Icons.calendar_today_rounded),
                                        ..._buildLeadPipelineDetailRows(req),
                                        _buildChipDetailRow(
                                          "Specs",
                                          Icons.business_rounded,
                                          _requirementSpecTags(req),
                                        ),
                                        _buildDetailRow("Budget", budget, Icons.account_balance_wallet_rounded),
                                        _buildChipDetailRow(
                                          "Target Areas",
                                          Icons.location_on_rounded,
                                          req.areaNames,
                                          emptyLabel: "Any Area",
                                        ),
                                        if (furnishingName.isNotEmpty)
                                          _buildDetailRow("Furnishing", furnishingName, Icons.chair_rounded),
                                        if (facingName.isNotEmpty)
                                          _buildDetailRow("Facing", facingName, Icons.explore_rounded),
                                        Builder(
                                          builder: (context) {
                                            final telecallerRemarks = getTelecallerRemarks(req);
                                            if (telecallerRemarks == null || telecallerRemarks.isEmpty) {
                                              return const SizedBox.shrink();
                                            }
                                            final isDark = Theme.of(context).brightness == Brightness.dark;
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 12),
                                              child: Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.25)),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Row(
                                                      children: [
                                                        Icon(Icons.speaker_notes_rounded, size: 15, color: Color(0xFF0F766E)),
                                                        SizedBox(width: 6),
                                                        Text(
                                                          'Telecaller Key Points / Remarks',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                            color: Color(0xFF0F766E),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    SelectableText(
                                                      telecallerRemarks,
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        color: isDark ? Colors.grey.shade200 : const Color(0xFF1E293B),
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (req.isMetaLead)
                                  _buildMetaAttributionCard(req),
                                const SizedBox(height: CRMSpacing.l),
                                if (!_isLoading && _error == null) ...[
                                  Row(
                                    children: [
                                      _buildSummaryMetric("Share Sessions", "$_totalSessions"),
                                      const SizedBox(width: CRMSpacing.m),
                                      _buildSummaryMetric("Properties Shared", "$_totalPropertiesShared"),
                                    ],
                                  ),
                                  const SizedBox(height: CRMSpacing.m),
                                  Row(
                                    children: [
                                      _buildSummaryMetric("Total Views", "$_totalViews"),
                                      const SizedBox(width: CRMSpacing.m),
                                      _buildSummaryMetric("Last Viewed", _lastViewed),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: CRMSpacing.l),
                        // Right column: Share History Table
                        Expanded(
                          flex: 3,
                          child: _buildShareHistoryTable(),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CRMCard(
                                  child: Padding(
                                    padding: const EdgeInsets.all(CRMSpacing.m),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          req.clientName,
                                          style: CRMTypography.sectionTitle.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: CRMColors.textOf(context),
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: CRMSpacing.xs),
                                        Text(
                                          req.clientMobile,
                                          style: CRMTypography.body.copyWith(
                                            color: CRMColors.textSecondaryOf(context),
                                          ),
                                        ),
                                        if (req.matchingReadiness != 'Ready') ...[
                                          const SizedBox(height: CRMSpacing.xs),
                                          _buildNeedsMoreDetailsBadge(req),
                                        ],
                                        const Divider(height: 24),
                                        _buildDetailRow("Code", req.requirementCode, Icons.qr_code_rounded),
                                        _buildDetailRow("Date", DateFormat('dd/MM/yyyy').format(req.createdAt), Icons.calendar_today_rounded),
                                        ..._buildLeadPipelineDetailRows(req),
                                        _buildChipDetailRow(
                                          "Specs",
                                          Icons.business_rounded,
                                          _requirementSpecTags(req),
                                        ),
                                        _buildDetailRow("Budget", budget, Icons.account_balance_wallet_rounded),
                                        _buildChipDetailRow(
                                          "Target Areas",
                                          Icons.location_on_rounded,
                                          req.areaNames,
                                          emptyLabel: "Any Area",
                                        ),
                                        if (furnishingName.isNotEmpty)
                                          _buildDetailRow("Furnishing", furnishingName, Icons.chair_rounded),
                                        if (facingName.isNotEmpty)
                                          _buildDetailRow("Facing", facingName, Icons.explore_rounded),
                                        Builder(
                                          builder: (context) {
                                            final telecallerRemarks = getTelecallerRemarks(req);
                                            if (telecallerRemarks == null || telecallerRemarks.isEmpty) {
                                              return const SizedBox.shrink();
                                            }
                                            final isDark = Theme.of(context).brightness == Brightness.dark;
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 12),
                                              child: Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0F766E).withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.25)),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Row(
                                                      children: [
                                                        Icon(Icons.speaker_notes_rounded, size: 15, color: Color(0xFF0F766E)),
                                                        SizedBox(width: 6),
                                                        Text(
                                                          'Telecaller Key Points / Remarks',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                            color: Color(0xFF0F766E),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    SelectableText(
                                                      telecallerRemarks,
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        color: isDark ? Colors.grey.shade200 : const Color(0xFF1E293B),
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (req.isMetaLead)
                                  _buildMetaAttributionCard(req),
                                const SizedBox(height: CRMSpacing.l),
                                if (!_isLoading && _error == null) ...[
                                  Row(
                                    children: [
                                      _buildSummaryMetric("Share Sessions", "$_totalSessions"),
                                      const SizedBox(width: CRMSpacing.m),
                                      _buildSummaryMetric("Properties Shared", "$_totalPropertiesShared"),
                                    ],
                                  ),
                                  const SizedBox(height: CRMSpacing.m),
                                  Row(
                                    children: [
                                      _buildSummaryMetric("Total Views", "$_totalViews"),
                                      const SizedBox(width: CRMSpacing.m),
                                      _buildSummaryMetric("Last Viewed", _lastViewed),
                                    ],
                                  ),
                                  const SizedBox(height: CRMSpacing.l),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: CRMSpacing.m),
                        Expanded(
                          child: _buildShareHistoryTable(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildMetaAttributionCard(RequirementModel req) {
    if (!req.isMetaLead) return const SizedBox.shrink();
    final customFields = req.metaCustomFields ?? {};

    return Container(
      margin: const EdgeInsets.only(top: CRMSpacing.m),
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: BoxDecoration(
        color: const Color(0xFF1877F2).withOpacity(0.05),
        borderRadius: BorderRadius.circular(CRMBorderRadius.m),
        border: Border.all(color: const Color(0xFF1877F2).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_rounded, size: 16, color: Color(0xFF1877F2)),
              const SizedBox(width: 6),
              Text(
                "Meta Ads Attribution",
                style: CRMTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1877F2),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1877F2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  req.leadQuality ?? "Pending",
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1877F2),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          _buildDetailRow("Campaign", req.metaCampaignName ?? req.metaCampaignId ?? "N/A", Icons.folder_special_outlined),
          if (req.metaAdName != null || req.metaAdId != null)
            _buildDetailRow("Ad", req.metaAdName ?? req.metaAdId ?? "N/A", Icons.ad_units_outlined),
          if (req.metaAdsetName != null || req.metaAdsetId != null)
            _buildDetailRow("AdSet", req.metaAdsetName ?? req.metaAdsetId ?? "N/A", Icons.layers_outlined),
          _buildDetailRow("Meta Lead ID", req.metaLeadId ?? "N/A", Icons.fingerprint_rounded),
          if (req.metaFormId != null)
            _buildDetailRow("Form ID", req.metaFormId!, Icons.assignment_outlined),
          if (customFields.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Form Responses:",
              style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context)),
            ),
            const SizedBox(height: 4),
            ...customFields.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "• ${e.key.replaceAll('_', ' ')}: ",
                    style: CRMTypography.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Text(
                      "${e.value}",
                      style: CRMTypography.caption.copyWith(color: CRMColors.textOf(context)),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildLeadPipelineDetailRows(RequirementModel req) {
    final assignee = (req.assigneeName ?? '').trim().isNotEmpty
        ? req.assigneeName!.trim()
        : 'Unassigned';
    final parsedFu = _parseFollowupDateTime(req.nextFollowupDate);
    final followup = parsedFu != null
        ? DateFormat('dd/MM/yyyy').format(parsedFu)
        : ((req.nextFollowupDate ?? '').trim().isNotEmpty
            ? req.nextFollowupDate!.trim()
            : '—');
    return [
      _buildDetailRow("Listing Type", getListingTypeLabel(req), Icons.sell_outlined),
      _buildDetailRow("Status", displayStatusLabel(req.status), Icons.flag_outlined),
      _buildDetailRow("Assigned To", assignee, Icons.person_outline_rounded),
      _buildDetailRow("Follow-up", followup, Icons.event_rounded),
    ];
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: CRMColors.textSecondaryOf(context)),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(label, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: CRMTypography.bodyMedium.copyWith(
                color: CRMColors.textOf(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _requirementSpecTags(RequirementModel req) {
    final tags = <String>[];
    final seen = <String>{};

    void addTag(String raw) {
      final value = raw.trim();
      if (value.isEmpty || value == '-') return;
      final key = value.toLowerCase();
      if (seen.add(key)) tags.add(value);
    }

    for (final part in req.propertyTypeName.split(',')) {
      addTag(part);
    }
    for (final part in (req.configurationName ?? '').split(',')) {
      addTag(part);
    }
    return tags;
  }

  Widget _buildChipDetailRow(
    String label,
    IconData icon,
    List<String> values, {
    String emptyLabel = '-',
  }) {
    final tags = values.map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: CRMColors.textSecondaryOf(context)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                label,
                style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: tags.isEmpty
                ? Text(
                    emptyLabel,
                    style: CRMTypography.bodyMedium.copyWith(
                      color: CRMColors.textOf(context),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: CRMColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                              border: Border.all(
                                color: CRMColors.primary.withValues(alpha: 0.22),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: CRMTypography.captionBold.copyWith(
                                color: CRMColors.primary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLabel(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: CRMSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: CRMTypography.caption.copyWith(color: CRMColors.textMuted)),
          const SizedBox(height: 2),
          Text(value, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textOf(context), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(CRMSpacing.s),
        decoration: BoxDecoration(
          color: CRMColors.backgroundOf(context),
          borderRadius: BorderRadius.circular(CRMBorderRadius.s),
          border: Border.all(color: CRMColors.borderOf(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: CRMTypography.caption.copyWith(color: CRMColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(value, style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: CRMColors.textOf(context))),
          ],
        ),
      ),
    );
  }
}

class RequirementWinPropertySelectionDialog extends StatefulWidget {
  final RequirementModel requirement;
  final Function(List<PropertyModel> selectedProperties) onConfirmed;

  const RequirementWinPropertySelectionDialog({
    super.key,
    required this.requirement,
    required this.onConfirmed,
  });

  @override
  State<RequirementWinPropertySelectionDialog> createState() =>
      _RequirementWinPropertySelectionDialogState();
}

class _RequirementWinPropertySelectionDialogState
    extends State<RequirementWinPropertySelectionDialog> {
  final PropertiesRepository _propertiesRepository = PropertiesRepository();
  bool _isLoading = true;
  List<PropertyModel> _allProperties = [];
  List<PropertyModel> _filteredProperties = [];
  final Set<String> _selectedPropertyIds = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _searchController.addListener(_filterProperties);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isRequirementPropertyMatch(PropertyModel p, RequirementModel req) {
    return PropertyRequirementMatcher.calculateMatchPercentage(p, req) >= MatchCriteriaManager().threshold;
  }

  Future<void> _loadProperties() async {
    try {
      final properties = await _propertiesRepository.getProperties();
      final req = widget.requirement;

      final matches = properties.where((p) => _isRequirementPropertyMatch(p, req)).toList();
      matches.sort((a, b) =>
        PropertyRequirementMatcher.calculateMatchPercentage(b, req)
          .compareTo(PropertyRequirementMatcher.calculateMatchPercentage(a, req)));

      setState(() {
        _allProperties = matches;
        _filteredProperties = matches;
        if (matches.isNotEmpty) {
          _selectedPropertyIds.add(matches.first.id);
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _filterProperties() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredProperties = _allProperties);
      return;
    }

    setState(() {
      _filteredProperties = _allProperties.where((p) {
        final code = p.propertyCode.toLowerCase();
        final title = (p.title ?? '').toLowerCase();
        final owner = p.ownerName.toLowerCase();
        final area = p.areaName.toLowerCase();
        return code.contains(query) || title.contains(query) || owner.contains(query) || area.contains(query);
      }).toList();
    });
  }

  void _showConfirmWinDialog() {
    final selectedProps = _allProperties.where((p) => _selectedPropertyIds.contains(p.id)).toList();
    if (selectedProps.isEmpty) return;

    final hasRent = selectedProps.any((p) =>
        p.listingTypeName.toLowerCase().contains('rent') ||
        (LookupLocalRepository.getLookupNameSync(p.listingTypeId)?.toLowerCase().contains('rent') ?? false) ||
        p.listingTypeId == '1c1ccfc1-d318-4b66-9a43-c551532d1802');

    final hasResale = selectedProps.any((p) =>
        !p.listingTypeName.toLowerCase().contains('rent') &&
        !(LookupLocalRepository.getLookupNameSync(p.listingTypeId)?.toLowerCase().contains('rent') ?? false) &&
        p.listingTypeId != '1c1ccfc1-d318-4b66-9a43-c551532d1802');

    String actionWord;
    if (hasRent && hasResale) {
      actionWord = "Rented out / Sold out";
    } else if (hasRent) {
      actionWord = "Rented out";
    } else {
      actionWord = "Sold out";
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: CRMColors.cardBgOf(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.m)),
        title: Text("Confirm Win", style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
        content: Text(
          "Are you sure this requirement is $actionWord?",
          style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
        ),
        actions: [
          CRMButton(
            label: "Cancel",
            variant: CRMButtonVariant.outline,
            onPressed: () => Navigator.pop(dialogContext),
          ),
          const SizedBox(width: CRMSpacing.xs),
          CRMButton(
            label: "Yes",
            variant: CRMButtonVariant.primary,
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
              widget.onConfirmed(selectedProps);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return Dialog(
      backgroundColor: CRMColors.cardBgOf(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.l)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 40,
      ),
      child: Container(
        width: isMobile ? double.infinity : 680,
        height: 600,
        padding: const EdgeInsets.all(CRMSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Select Deal Property",
                        style: CRMTypography.sectionTitle.copyWith(
                          color: CRMColors.textOf(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Select property deal matches for ${widget.requirement.clientName}",
                        style: CRMTypography.caption.copyWith(
                          color: CRMColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.m),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search property code, title, owner, area...",
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: CRMColors.backgroundOf(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                  borderSide: BorderSide(color: CRMColors.borderOf(context)),
                ),
              ),
            ),
            const SizedBox(height: CRMSpacing.m),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProperties.isEmpty
                      ? Center(
                          child: Text(
                            "No matching properties found in client's budget range and specs.",
                            style: CRMTypography.body.copyWith(
                              color: CRMColors.textSecondaryOf(context),
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _filteredProperties.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final p = _filteredProperties[index];
                            final isChecked = _selectedPropertyIds.contains(p.id);
                            final isRent = p.listingTypeName.toLowerCase().contains('rent') ||
                                (LookupLocalRepository.getLookupNameSync(p.listingTypeId)?.toLowerCase().contains('rent') ?? false) ||
                                p.listingTypeId == '1c1ccfc1-d318-4b66-9a43-c551532d1802';

                            return CheckboxListTile(
                              value: isChecked,
                              activeColor: CRMColors.primaryOf(context),
                              onChanged: (bool? val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedPropertyIds.add(p.id);
                                  } else {
                                    _selectedPropertyIds.remove(p.id);
                                  }
                                });
                              },
                              title: Row(
                                children: [
                                  Text(
                                    p.propertyCode,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      p.title.isNotEmpty ? p.title : "Property",
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (isRent ? CRMColors.rentAccent : CRMColors.primaryOf(context))
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isRent ? "Rent" : "Re-sale",
                                      style: TextStyle(
                                        color: isRent ? CRMColors.rentAccent : CRMColors.primaryOf(context),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  "${p.ownerName} • ${p.areaName} • ₹${BudgetFormatter.format(p.price)}",
                                  style: TextStyle(
                                    color: CRMColors.textSecondaryOf(context),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: CRMSpacing.m),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CRMButton(
                  label: "Cancel",
                  variant: CRMButtonVariant.outline,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: CRMSpacing.s),
                CRMButton(
                  label: "Done (${_selectedPropertyIds.length})",
                  variant: CRMButtonVariant.primary,
                  onPressed: _selectedPropertyIds.isNotEmpty ? _showConfirmWinDialog : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PropertyDealClientStore {
  static const String _prefix = 'deal_client_name_';
  static const String _reqPrefix = 'won_req_properties_';
  static final Map<String, String> _memoryCache = {};
  static final Map<String, List<String>> _reqMemoryCache = {};

  static Future<void> setClientName(String propertyId, String clientName) async {
    _memoryCache[propertyId] = clientName;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$propertyId', clientName);
    } catch (_) {}
  }

  static Future<void> setWonRequirementProperties(String requirementId, List<String> propertyIds) async {
    _reqMemoryCache[requirementId] = propertyIds;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('$_reqPrefix$requirementId', propertyIds);
    } catch (_) {}
  }

  static Future<List<String>> getWonPropertyIds(String requirementId) async {
    if (_reqMemoryCache.containsKey(requirementId)) {
      return _reqMemoryCache[requirementId]!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('$_reqPrefix$requirementId');
      if (list != null) {
        _reqMemoryCache[requirementId] = list;
        return list;
      }
    } catch (_) {}
    return [];
  }

  static String? getMemoryClientName(String propertyId) {
    return _memoryCache[propertyId];
  }

  static Future<String?> getClientName(String propertyId, {PropertyModel? property}) async {
    if (_memoryCache.containsKey(propertyId)) {
      return _memoryCache[propertyId];
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('$_prefix$propertyId');
      if (savedName != null && savedName.isNotEmpty) {
        _memoryCache[propertyId] = savedName;
        return savedName;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> removeClientName(String propertyId) async {
    _memoryCache.remove(propertyId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$propertyId');
    } catch (_) {}
  }

  static Future<void> removeWonRequirementProperties(String requirementId) async {
    _reqMemoryCache.remove(requirementId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_reqPrefix$requirementId');
    } catch (_) {}
  }
}

class _FollowupActionButton extends StatelessWidget {
  final DashboardFollowup followup;
  final RequirementModel reqModel;
  final bool isSiteVisit;
  final Function(RequirementModel, String) onSelect;

  const _FollowupActionButton({
    super.key,
    required this.followup,
    required this.reqModel,
    this.isSiteVisit = false,
    required this.onSelect,
  });

  void _showMenuAt(BuildContext context, Offset globalPos) {
    final RenderBox? overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromLTWH(globalPos.dx - 60, globalPos.dy - 46, 140, 40),
      Offset.zero & overlayBox.size,
    );

    OverlayEntry? rejectionOverlay;

    void removeRejectionOverlay() {
      rejectionOverlay?.remove();
      rejectionOverlay = null;
    }

    void showRejectionOverlay(BuildContext itemContext) {
      if (rejectionOverlay != null) return;
      final RenderBox? renderBox = itemContext.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final Offset itemGlobalOffset = renderBox.localToGlobal(Offset.zero);
      final overlay = Overlay.of(itemContext);
      final size = MediaQuery.of(itemContext).size;
      double left = (itemGlobalOffset.dx - 192).clamp(10.0, size.width - 200.0);
      double top = (itemGlobalOffset.dy - 120).clamp(40.0, size.height - 380.0);

      const reasons = [
        'Not Answering',
        'No Requirement',
        'Budget Mismatch',
        'Locality Mismatch',
        'Broker',
        'Already rented',
        'Want Ready-To-Move',
        'Negotiation Failed',
        'Others',
      ];

      rejectionOverlay = OverlayEntry(
        builder: (overlayContext) {
          return Positioned(
            left: left,
            top: top,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: CRMColors.cardBgOf(context),
              child: Container(
                width: 190,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: CRMColors.cardBgOf(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: reasons.map((reason) {
                    return InkWell(
                      onTap: () {
                        removeRejectionOverlay();
                        Navigator.of(context, rootNavigator: true).maybePop();
                        onSelect(reqModel, 'Rejected ($reason)');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            reason,
                            style: TextStyle(
                              color: CRMColors.textOf(context),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      );
      overlay.insert(rejectionOverlay!);
    }

    showMenu<String>(
      context: context,
      position: position,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      items: isSiteVisit
          ? [
              PopupMenuItem<String>(
                value: 'Edit Site Visit',
                height: 38,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_calendar_rounded,
                      size: 16,
                      color: CRMColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Edit Site Visit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: CRMColors.textOf(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'Re-scheduled',
                height: 38,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.update_rounded,
                      size: 16,
                      color: CRMColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Re-scheduled',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: CRMColors.textOf(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ]
          : [
              PopupMenuItem<String>(
                value: 'Edit Followup',
                height: 38,
                child: MouseRegion(
                  onEnter: (_) => removeRejectionOverlay(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_calendar_rounded,
                        size: 16,
                        color: CRMColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Edit Followup',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: CRMColors.textOf(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'Re-Followup',
                height: 38,
                child: MouseRegion(
                  onEnter: (_) => removeRejectionOverlay(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.update_rounded,
                        size: 16,
                        color: CRMColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Re-Followup',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: CRMColors.textOf(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'Interested',
                height: 38,
                child: MouseRegion(
                  onEnter: (_) => removeRejectionOverlay(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_up_alt_outlined,
                        size: 16,
                        color: CRMColors.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Interested',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: CRMColors.textOf(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: 'Rejected',
                height: 38,
                child: Builder(
                  builder: (itemContext) {
                    return MouseRegion(
                      onEnter: (_) => showRejectionOverlay(itemContext),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cancel_outlined,
                            size: 16,
                            color: CRMColors.danger,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Rejected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: CRMColors.danger,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: CRMColors.textSecondaryOf(context),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
    ).then((val) {
      removeRejectionOverlay();
      if (val != null && val != 'Rejected') {
        onSelect(reqModel, val);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String statusStr = isSiteVisit
        ? 'Site Visit Scheduled'
        : ((reqModel.status == 'Re-Followup') ? 'Re-Followup' : 'Follow-up');
    final bool isRe = !isSiteVisit && statusStr == 'Re-Followup';

    final Color badgeBg = isSiteVisit
        ? CRMColors.primary.withValues(alpha: 0.15)
        : (isRe ? CRMColors.warning.withValues(alpha: 0.15) : CRMColors.info.withValues(alpha: 0.15));
    final Color badgeColor = isSiteVisit
        ? CRMColors.primary
        : (isRe ? CRMColors.warning : CRMColors.info);
    final Color borderColor = isSiteVisit
        ? CRMColors.primary.withValues(alpha: 0.4)
        : (isRe ? CRMColors.warning.withValues(alpha: 0.4) : CRMColors.info.withValues(alpha: 0.4));

    if (isRe) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => _showMenuAt(context, details.globalPosition),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusStr,
                  style: CRMTypography.captionBold.copyWith(color: badgeColor, fontSize: 12),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down_rounded, size: 18, color: badgeColor),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => _showMenuAt(context, details.globalPosition),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              statusStr,
              style: CRMTypography.captionBold.copyWith(color: badgeColor, fontSize: 12),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, size: 18, color: badgeColor),
          ],
        ),
      ),
    );
  }
}

class _PopoverTrianglePainter extends CustomPainter {
  final Color color;
  final bool pointingDown;
  _PopoverTrianglePainter({required this.color, this.pointingDown = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (pointingDown) {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NoteItemData {
  final String timestamp;
  final String content;

  _NoteItemData({required this.timestamp, required this.content});
}

List<_NoteItemData> _parseNotesList(String? rawNotes) {
  if (rawNotes == null || rawNotes.trim().isEmpty) return [];
  final text = rawNotes.trim();
  if (text.toLowerCase() == 'null' || text.toLowerCase() == 'n/a') return [];

  final List<_NoteItemData> result = [];
  final lines = text.split('\n');

  String currentTimestamp = '';
  StringBuffer currentContent = StringBuffer();

  final regExp = RegExp(r'^\[(.*?)\]\s*(.*)$');

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    final match = regExp.firstMatch(trimmed);

    if (match != null) {
      if (currentContent.isNotEmpty) {
        result.add(_NoteItemData(
          timestamp: currentTimestamp.isEmpty ? 'Saved Note' : currentTimestamp,
          content: currentContent.toString().trim(),
        ));
        currentContent.clear();
      }
      currentTimestamp = match.group(1) ?? '';
      currentContent.write(match.group(2) ?? '');
    } else {
      if (currentContent.isNotEmpty) {
        currentContent.write('\n$trimmed');
      } else {
        currentContent.write(trimmed);
      }
    }
  }

  if (currentContent.isNotEmpty) {
    result.add(_NoteItemData(
      timestamp: currentTimestamp.isEmpty ? 'Saved Note' : currentTimestamp,
      content: currentContent.toString().trim(),
    ));
  }

  return result;
}

class _ViewAllNotesDialogWidget extends StatefulWidget {
  final RequirementModel requirement;
  final Function(String updatedNotes, RequirementModel updatedReqModel, String? newNote, [String? deletedNote]) onSave;

  const _ViewAllNotesDialogWidget({
    required this.requirement,
    required this.onSave,
  });

  @override
  State<_ViewAllNotesDialogWidget> createState() => _ViewAllNotesDialogWidgetState();
}

class _ViewAllNotesDialogWidgetState extends State<_ViewAllNotesDialogWidget> {
  late RequirementModel _currentReq;
  final TextEditingController _newNoteController = TextEditingController();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _currentReq = widget.requirement;
  }

  @override
  void dispose() {
    _newNoteController.dispose();
    super.dispose();
  }

  void _deleteNote(int indexToDelete, List<_NoteItemData> currentList) {
    final itemToDelete = currentList[indexToDelete];
    final deletedNoteStr = (itemToDelete.timestamp == 'Saved Note' || itemToDelete.timestamp == 'Initial Note')
        ? itemToDelete.content
        : '[${itemToDelete.timestamp}] ${itemToDelete.content}';

    final newList = List<_NoteItemData>.from(currentList);
    newList.removeAt(indexToDelete);

    String updatedNotesStr = '';
    if (newList.isNotEmpty) {
      updatedNotesStr = newList.map((item) {
        if (item.timestamp == 'Saved Note' || item.timestamp == 'Initial Note') {
          return item.content;
        } else {
          return '[${item.timestamp}] ${item.content}';
        }
      }).join('\n');
    }

    final updatedReq = _currentReq.copyWith(notes: updatedNotesStr);
    setState(() {
      _currentReq = updatedReq;
    });
    widget.onSave(updatedNotesStr, updatedReq, null, deletedNoteStr);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note deleted successfully.'),
        backgroundColor: CRMColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _addNote() {
    final text = _newNoteController.text.trim();
    if (text.isEmpty) return;

    final timeStr = DateFormat("dd MMM ''yy, h:mm a").format(DateTime.now());
    final formattedEntry = '[$timeStr] $text';
    final existingClean = _currentReq.notes?.trim() ?? '';
    final updatedNotes = (existingClean.isNotEmpty && existingClean.toLowerCase() != 'null')
        ? '$existingClean\n$formattedEntry'
        : formattedEntry;

    final updatedReq = _currentReq.copyWith(notes: updatedNotes);
    setState(() {
      _currentReq = updatedReq;
      _newNoteController.clear();
      _isAdding = false;
    });
    widget.onSave(updatedNotes, updatedReq, formattedEntry);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note added successfully.'),
        backgroundColor: CRMColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesList = _parseNotesList(_currentReq.notes);

    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = (screenSize.width - 32).clamp(280.0, 480.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: CRMColors.cardBgOf(context),
      child: SizedBox(
        width: dialogWidth,
        child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.78,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Icon(
                  Icons.sticky_note_2_rounded,
                  color: CRMColors.primaryOf(context),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All Notes (${notesList.length})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CRMColors.textOf(context),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: CRMColors.textMutedOf(context)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: CRMColors.borderOf(context).withOpacity(0.6), height: 1),
            const SizedBox(height: 12),

            Flexible(
              child: notesList.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notes_outlined,
                              size: 48,
                              color: CRMColors.textMutedOf(context).withOpacity(0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No notes added yet.',
                              style: TextStyle(
                                fontSize: 14,
                                color: CRMColors.textSecondaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: notesList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final note = notesList[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.05)
                                : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CRMColors.borderOf(context).withOpacity(0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 13,
                                        color: CRMColors.primaryOf(context),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        note.timestamp,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: CRMColors.primaryOf(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  InkWell(
                                    onTap: () => _deleteNote(index, notesList),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2),
                                      child: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 16,
                                        color: CRMColors.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                note.content,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: CRMColors.textOf(context),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 12),
            Divider(color: CRMColors.borderOf(context).withOpacity(0.6), height: 1),
            const SizedBox(height: 12),

            if (!_isAdding)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _isAdding = true),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Another Note'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CRMColors.primaryOf(context),
                    side: BorderSide(color: CRMColors.primaryOf(context)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black12
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: CRMColors.primaryOf(context).withOpacity(0.6),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: TextField(
                      controller: _newNoteController,
                      maxLines: 3,
                      minLines: 2,
                      autofocus: true,
                      style: TextStyle(fontSize: 13, color: CRMColors.textOf(context)),
                      decoration: InputDecoration(
                        hintText: 'Type new note here...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: CRMColors.textSecondaryOf(context).withOpacity(0.6),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          _newNoteController.clear();
                          setState(() => _isAdding = false);
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: CRMColors.textSecondaryOf(context)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Save Note', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
