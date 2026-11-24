import '../../core/security/role_guard.dart';

/// Where an AI Search result opens. Every route only uses query parameters the target page already reads.
class AiSearchRoutes {
  AiSearchRoutes._();

  static String _stamp() => DateTime.now().millisecondsSinceEpoch.toString();

  static String _text(dynamic value) => value?.toString().trim() ?? '';

  static String _uri(String path, Map<String, String> params) {
    final clean = {
      for (final entry in params.entries)
        if (entry.value.isNotEmpty) entry.key: entry.value,
    };
    return Uri(path: path, queryParameters: clean.isEmpty ? null : clean).toString();
  }

  /// 'rent' or 'resale' for a listing type name, matching how the Properties, Leads and Recycle Bin tabs split rows.
  static String listingParam(dynamic listingType) {
    final name = _text(listingType).toLowerCase();
    if (name.isEmpty) return '';
    if (name.contains('re-sale') || name.contains('resale') || name.contains('sale') || name.contains('sell')) return 'resale';
    return name.contains('rent') ? 'rent' : 'resale';
  }

  static String _digits(dynamic value) {
    final digits = _text(value).replaceAll(RegExp(r'\D'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  /// 'Rented Out' or 'Sold Out' for a property in either status, otherwise null.
  static String? propertyStatus(Map<String, dynamic> row) {
    final status = _text(row['property_status']).toLowerCase();
    if (status.contains('rented')) return 'Rented Out';
    if (status.contains('sold')) return 'Sold Out';
    return null;
  }

  /// Opens the property on the Properties page with the filters of the question that found it, so the list shows its matches.
  static String property(Map<String, dynamic> row, {Map<String, dynamic>? intent}) {
    if (row['is_recycle_bin'] == true) return recycleBin(row);
    final params = <String, String>{'openId': _text(row['id'])};
    final filtered = filteredPage(intent);
    final filteredUri = filtered == null ? null : Uri.parse(filtered);
    if (filteredUri != null && filteredUri.path == '/properties') {
      params.addAll(filteredUri.queryParameters);
    } else {
      final residual = _text(intent?['residual']);
      if (residual.isNotEmpty) params['search'] = residual;
    }
    final listing = listingParam(row['listing_type']);
    if (listing.isNotEmpty) params['listingType'] = listing;
    params['t'] = _stamp();
    return _uri('/properties', params);
  }

  /// Opens the exact lead on the Leads page: the tab, listing mode and search that show it.
  static String requirement(Map<String, dynamic> row, {String? role}) {
    final status = _text(row['status']).toLowerCase();
    final tab = (status == 'won' || status == 'closed' || status == 'deal won')
        ? 'won'
        : status.startsWith('rejected')
            ? 'rejected'
            : 'leads';
    final name = _text(row['customer_name']);
    final search = name.isNotEmpty && name.toLowerCase() != 'client' ? name : _digits(row['mobile']);
    final leadType = _text(row['lead_type']).toLowerCase();
    final isPropertyListing = leadType.contains('property') ||
        leadType.contains('listing') ||
        row['is_property_listing'] == true;
    final subTab = isPropertyListing ? 'Property Listing' : 'Requirement';
    final mode = listingParam(row['listing_type']);

    if (row['is_direct_sales_campaign'] == true) {
      return _uri('/my-campaign-leads', {
        'search': search,
        'subTab': subTab,
        if (tab == 'rejected') 'tab': tab,
        if (mode.isNotEmpty) 'mode': mode,
        't': _stamp(),
      });
    }
    return _uri('/requirements', {
      'search': search,
      'tab': tab,
      'subTab': subTab,
      if (mode.isNotEmpty) 'mode': mode,
      'status': 'All',
      if (RoleGuard.isSales(role)) 'group': 'all',
      't': _stamp(),
    });
  }

  /// Opens the Recycle Bin on the tab and listing that hold the deleted record, searched down to it.
  static String recycleBin(Map<String, dynamic> row) {
    final isProperty = _text(row['kind']) == 'property' || (row['kind'] == null && row.containsKey('property_code'));
    final String search;
    if (isProperty) {
      final code = _text(row['property_code']);
      search = code.isNotEmpty ? code : _text(row['title']);
    } else {
      final name = _text(row['customer_name']);
      search = name.isNotEmpty && name.toLowerCase() != 'client' ? name : _digits(row['mobile']);
    }
    return _uri('/bin', {
      'tab': isProperty ? 'properties' : 'requirements',
      'listing': listingParam(row['listing_type']),
      'search': search,
      't': _stamp(),
    });
  }

  static String client(Map<String, dynamic> row) => _uri('/clients', {'search': _text(row['name'])});

  static String owner(Map<String, dynamic> row) => _uri('/owners', {'search': _text(row['name'])});

  static String employee(Map<String, dynamic> row, {required bool canOpenDetails}) {
    final id = _text(row['id']);
    return canOpenDetails && id.isNotEmpty ? '/users/$id' : '/users';
  }

  /// Pages that can show [row], best first. The caller opens the first one the user may view.
  /// A lead whose Leads page record is rejected opens on Leads → Rejected with that record open.
  static List<String> leadCandidates(Map<String, dynamic> row, String? role) {
    final rejected = row['rejected_requirement'];
    if (rejected is! Map) return _leadPages(row, role);
    final record = Map<String, dynamic>.from(rejected);
    return [
      if (RoleGuard.isSales(role) && row['is_campaign'] == true)
        requirement({...record, 'is_direct_sales_campaign': true}, role: role),
      requirement({...record, 'is_direct_sales_campaign': false}, role: role),
      ..._leadPages(row, role),
    ];
  }

  /// The status a lead row shows: its Leads page rejection when the campaign status still reads as active.
  static String leadStatus(Map<String, dynamic> row) {
    final status = _text(row['status']);
    final rejected = row['rejected_requirement'];
    if (rejected is! Map || status.toLowerCase().startsWith('rejected')) return status;
    final rejectedStatus = _text(rejected['status']);
    return rejectedStatus.isEmpty ? status : rejectedStatus;
  }

  static List<String> _leadPages(Map<String, dynamic> row, String? role) {
    final rawName = _text(row['name']);
    final name = rawName.isEmpty || rawName.toLowerCase() == 'lead' ? _digits(row['phone']) : rawName;
    final queue = _text(row['queue']);
    if (RoleGuard.isSales(role)) {
      final listing = _text(row['lead_type']).toLowerCase() == 'property listing';
      final subTab = listing ? 'Property Listing' : 'Requirement';
      final mode = listingParam(row['listing_type']);
      final params = {
        'search': name,
        'subTab': subTab,
        if (mode.isNotEmpty) 'mode': mode,
        't': _stamp(),
      };
      if (row['is_campaign'] == true) {
        return [_uri('/my-campaign-leads', params), _uri('/requirements', params)];
      }
      return [_uri('/requirements', params)];
    }
    final leadType = _text(row['lead_type']);
    final section = leadType == 'Property Listing' || leadType == 'Requirement' ? leadType : '';
    final campaign = {'search': name, 'section': section, 't': _stamp()};
    if (RoleGuard.isTelecaller(role)) {
      if (queue == 'CNR') return [_uri('/telecaller/cnr', {'q': name})];
      if (queue == 'Callback') return [_uri('/telecaller/callbacks', {'q': name})];
      return [_uri('/telecaller/leads', campaign), _uri('/campaign/leads', campaign)];
    }
    final source = _text(row['source']).toUpperCase();
    final bySource = source == 'HOUSING'
        ? _uri('/campaign/housing', campaign)
        : source == 'META'
            ? _uri('/campaign/meta', campaign)
            : _uri('/campaign/leads', campaign);
    return [
      bySource,
      _uri('/campaign/leads', campaign),
      _uri('/campaign/meta', campaign),
    ];
  }

  static String? firstAllowed(List<String> candidates, bool Function(String route) canOpen) {
    for (final route in candidates) {
      if (canOpen(Uri.parse(route).path)) return route;
    }
    return null;
  }

  /// The Properties page tab a question names ("office", "warehouse", "plot"), matching the page's own category tabs.
  static String propertyCategory(String query) {
    final text = query.toLowerCase();
    if (RegExp(r'\b(commercial|offices?|shops?|showrooms?)\b').hasMatch(text)) return 'Commercial';
    if (RegExp(r'\b(industrial|factory|factories|warehouses?|godowns?)\b').hasMatch(text)) return 'Industrial';
    if (RegExp(r'\b(lands?|plots?)\b').hasMatch(text)) return 'Land & Plot';
    return '';
  }

  /// The Properties page showing every property that matches the question: location, budget, BHK, listing,
  /// status and category. `ai=1` tells the page to replace its filters with exactly these; `area` holds
  /// location names the page turns into its Area filter.
  static String propertiesPage(Map<String, dynamic>? intent, {String query = ''}) {
    final filters = intent?['filters'] is Map ? Map<String, dynamic>.from(intent!['filters'] as Map) : <String, dynamic>{};
    final residual = intent == null ? query.trim() : _text(intent['residual']);
    final areas = filters['area'] is List ? (filters['area'] as List).map(_text).where((a) => a.isNotEmpty).toList() : <String>[];
    final bedrooms = filters['bedrooms'] is num ? (filters['bedrooms'] as num).toInt() : int.tryParse(_text(filters['bedrooms']));
    final status = switch (_text(filters['status']).toLowerCase()) {
      'available' => 'Available',
      'rented' => 'Rented Out',
      'sold' => 'Sold Out',
      _ => '',
    };
    final listing = _text(filters['listing_type']);
    return _uri('/properties', {
      'ai': '1',
      // Rented Out is a Rent tab status and Sold Out a Re-Sale one, so the page shows the tab that has it.
      'listingType': listing.isNotEmpty ? listing : status == 'Rented Out' ? 'rent' : status == 'Sold Out' ? 'resale' : '',
      'bhk': bedrooms == null ? '' : '${bedrooms > 5 ? 5 : bedrooms}',
      'search': residual,
      'area': areas.join(','),
      'minPrice': _text(filters['min_price']),
      'maxPrice': _text(filters['max_price']),
      'status': status,
      'category': propertyCategory(query),
      't': _stamp(),
    });
  }

  /// The page that lists every match for a search, with its filters applied, or null when no single page fits.
  static String? filteredPage(Map<String, dynamic>? intent, {String? role, String query = ''}) {
    if (intent == null) return null;
    final entity = _text(intent['entity']);
    final filters = intent['filters'] is Map ? Map<String, dynamic>.from(intent['filters'] as Map) : <String, dynamic>{};
    final residual = _text(intent['residual']);
    const propertyKeys = {'listing_type', 'bedrooms', 'area', 'min_price', 'max_price', 'status'};
    final propertySearch = entity == 'properties' || (entity == 'all' && filters.keys.any(propertyKeys.contains));
    if (propertySearch) return propertiesPage(intent, query: query);
    final window = _text(filters['followup_window']);
    if (window.isNotEmpty && !RoleGuard.isTelecaller(role)) {
      final subTab = window == 'overdue' ? 'due' : window == 'today' ? 'today' : 'future';
      return _uri('/requirements', {'tab': 'follow-ups', 'subTab': subTab});
    }
    if (entity == 'requirements' || (entity == 'leads' && RoleGuard.isSales(role))) {
      return _uri('/requirements', {'search': residual});
    }
    if (entity == 'leads' && RoleGuard.isTelecaller(role)) return _uri('/telecaller/leads', {'search': residual});
    if (entity == 'clients') return _uri('/clients', {'search': residual});
    if (entity == 'owners') return _uri('/owners', {'search': residual});
    return null;
  }
}
