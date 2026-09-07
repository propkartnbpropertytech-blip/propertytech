import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Turns messy Google Sheet rows into one campaign lead per real enquiry.
///
/// A Name column that is a dropdown (only a few values, reused across many rows)
/// is treated as a property/project/source tag — never as the unique person.
class CampaignIngestEngine {
  static const engineClientName = '_engine_client_name';
  static const engineMobile = '_engine_mobile';
  static const engineEmail = '_engine_email';
  static const engineProperty = '_engine_property';
  static const engineCampaign = '_engine_campaign';
  static const engineCity = '_engine_city';
  static const engineRow = '_engine_row';

  static final _phoneRegex = RegExp(r'(?:\+?91[\s-]?)?[6-9]\d{9}');
  static final _emailRegex = RegExp(r'[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}', caseSensitive: false);

  Future<List<PreparedCampaignRow>> prepare(List<Map<String, dynamic>> rows) async {
    final flattened = <Map<String, dynamic>>[];
    for (var i = 0; i < rows.length; i++) {
      final clean = _flatten(rows[i]);
      if (_hasData(clean)) flattened.add(clean);
      if (i > 0 && i % 150 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
    if (flattened.isEmpty) return const [];

    final sampleSize = flattened.length > 400 ? 400 : flattened.length;
    final profile = _profileColumns(flattened.sublist(0, sampleSize));
    final prepared = <PreparedCampaignRow>[];

    for (var i = 0; i < flattened.length; i++) {
      final inferred = _inferRow(flattened[i], i, profile);
      final phones = inferred.phones;
      if (phones.isEmpty) {
        prepared.add(
          PreparedCampaignRow(
            rawJson: inferred.row,
            fingerprint: inferred.fingerprint,
            mappings: inferred.mappings,
          ),
        );
      } else {
        for (final phone in phones) {
          final copy = Map<String, dynamic>.from(inferred.row);
          copy[engineMobile] = phone;
          copy['Phone'] = phone;
          prepared.add(
            PreparedCampaignRow(
              rawJson: copy,
              fingerprint: 'phone|$phone',
              mappings: inferred.mappings,
            ),
          );
        }
      }
      if (i > 0 && i % 80 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
    return prepared;
  }

  Map<String, dynamic> _flatten(Map<String, dynamic> raw) {
    var source = Map<String, dynamic>.from(raw);
    if (source['data'] is Map) {
      source = Map<String, dynamic>.from(source['data'] as Map);
    }
    final out = <String, dynamic>{};
    source.forEach((key, value) {
      final header = key.toString().trim();
      if (header.isEmpty || header.toLowerCase() == 'source') return;
      out[header] = _display(value);
    });
    return out;
  }

  _ColumnProfile _profileColumns(List<Map<String, dynamic>> rows) {
    final headers = <String>{};
    for (final row in rows) {
      headers.addAll(row.keys);
    }

    final dropdowns = <String>{};
    final phoneHeaders = <String>{};
    final emailHeaders = <String>{};
    final personHeaders = <String>{};
    final propertyHeaders = <String>{};

    for (final header in headers) {
      final values = rows
          .map((row) => _display(row[header]))
          .where((v) => v.isNotEmpty)
          .toList();
      if (values.isEmpty) continue;

      final unique = values.toSet();
      final lower = header.toLowerCase();
      final compact = lower.replaceAll(RegExp(r'[^a-z0-9]'), '');
      final uniqueRatio = unique.length / values.length;
      final looksDropdown = unique.length <= 8 &&
          values.length > unique.length &&
          (unique.length <= 4 || uniqueRatio <= 0.35);

      if (compact.contains('phone') || compact.contains('mobile') || compact.contains('whatsapp')) {
        phoneHeaders.add(header);
      }
      if (compact.contains('email') || compact.contains('mail')) {
        emailHeaders.add(header);
      }
      if (compact.contains('property') ||
          compact.contains('project') ||
          compact.contains('inventory') ||
          compact.contains('building') ||
          compact.contains('society')) {
        propertyHeaders.add(header);
      }

      if (looksDropdown && (compact == 'name' || compact.contains('name') || compact.contains('project'))) {
        dropdowns.add(header);
        if (!compact.contains('client') && !compact.contains('customer') && !compact.contains('buyer')) {
          propertyHeaders.add(header);
        }
      }

      if (!looksDropdown &&
          (compact.contains('client') ||
              compact.contains('customer') ||
              compact.contains('buyer') ||
              compact == 'fullname' ||
              (compact.contains('name') && !propertyHeaders.contains(header)))) {
        personHeaders.add(header);
      }
    }

    return _ColumnProfile(
      dropdowns: dropdowns,
      phoneHeaders: phoneHeaders,
      emailHeaders: emailHeaders,
      personHeaders: personHeaders,
      propertyHeaders: propertyHeaders,
    );
  }

  _InferredRow _inferRow(Map<String, dynamic> row, int index, _ColumnProfile profile) {
    final out = Map<String, dynamic>.from(row);
    final mappings = <String, String>{};

    final phones = <String>{};
    final emails = <String>{};
    for (final entry in row.entries) {
      phones.addAll(_findPhones(_display(entry.value)));
      emails.addAll(_findEmails(_display(entry.value)));
    }

    String property = '';
    for (final header in profile.propertyHeaders) {
      final val = _display(row[header]);
      if (val.isNotEmpty) {
        property = val;
        mappings[header] = 'property';
        break;
      }
    }
    if (property.isEmpty) {
      for (final header in profile.dropdowns) {
        final val = _display(row[header]);
        if (val.isNotEmpty) {
          property = val;
          mappings[header] = 'property';
          break;
        }
      }
    }

    String clientName = '';
    for (final header in profile.personHeaders) {
      final val = _display(row[header]);
      if (val.isEmpty) continue;
      if (profile.dropdowns.contains(header) && val == property) continue;
      clientName = val;
      mappings[header] = 'name';
      break;
    }

    if (clientName.isEmpty) {
      for (final entry in row.entries) {
        if (profile.dropdowns.contains(entry.key) || profile.propertyHeaders.contains(entry.key)) {
          continue;
        }
        final val = _display(entry.value);
        if (_looksLikePersonName(val) && val != property) {
          clientName = val;
          mappings[entry.key] = 'name';
          break;
        }
      }
    }

    if (clientName.isEmpty || clientName == property) {
      final phone = phones.isNotEmpty ? phones.first : '';
      clientName = phone.length >= 4 ? 'Lead ${phone.substring(phone.length - 4)}' : 'Campaign Lead ${index + 1}';
    }

    String city = '';
    String campaign = '';
    for (final entry in row.entries) {
      final compact = entry.key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final val = _display(entry.value);
      if (val.isEmpty) continue;
      if (compact.contains('city') || compact.contains('location') || compact.contains('area')) {
        city = val;
        mappings[entry.key] = 'city';
      }
      if (compact.contains('campaign') || compact.contains('source') || compact.contains('channel')) {
        campaign = val;
        mappings[entry.key] = 'campaign';
      }
      if (compact.contains('phone') || compact.contains('mobile') || compact.contains('whatsapp')) {
        mappings[entry.key] = 'mobile';
      }
      if (compact.contains('email')) {
        mappings[entry.key] = 'email';
      }
    }

    if (property.isNotEmpty && campaign.isEmpty && profile.dropdowns.isNotEmpty) {
      campaign = property;
    }

    out[engineClientName] = clientName;
    out[engineMobile] = phones.isNotEmpty ? phones.first : '';
    out[engineEmail] = emails.isNotEmpty ? emails.first : '';
    out[engineProperty] = property;
    out[engineCampaign] = campaign;
    out[engineCity] = city;
    out[engineRow] = '${index + 1}';
    out['Client Name'] = clientName;
    if (property.isNotEmpty) out['Property Name'] = property;
    if (phones.isNotEmpty) out['Phone'] = phones.first;
    if (emails.isNotEmpty && _display(out['Email']).isEmpty) out['Email'] = emails.first;

    mappings[engineClientName] = 'name';
    mappings[engineMobile] = 'mobile';
    mappings[engineEmail] = 'email';
    mappings[engineProperty] = 'property';
    mappings[engineCampaign] = 'campaign';
    mappings[engineCity] = 'city';
    mappings['Client Name'] = 'name';
    mappings['Property Name'] = 'property';
    mappings['Phone'] = 'mobile';

    final fingerprint = phones.isNotEmpty
        ? 'phone|${phones.first}'
        : emails.isNotEmpty
            ? 'email|${emails.first.toLowerCase()}'
            : 'row|${index + 1}|${_contentHash(row)}';

    return _InferredRow(
      row: out,
      phones: phones.toList(),
      fingerprint: fingerprint,
      mappings: mappings,
    );
  }

  bool _looksLikePersonName(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 3 || trimmed.length > 60) return false;
    if (_findPhones(trimmed).isNotEmpty || _findEmails(trimmed).isNotEmpty) return false;
    if (RegExp(r'\d{4,}').hasMatch(trimmed)) return false;
    final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty || words.length > 5) return false;
    return words.every((w) => RegExp(r"^[A-Za-z][A-Za-z.'\-]*$").hasMatch(w));
  }

  List<String> _findPhones(String raw) {
    final matches = _phoneRegex.allMatches(raw.replaceAll(RegExp(r'[()]'), ''));
    final out = <String>[];
    for (final match in matches) {
      var digits = match.group(0)!.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.startsWith('91') && digits.length == 12) digits = digits.substring(2);
      if (digits.length == 10 && !out.contains(digits)) out.add(digits);
    }
    return out;
  }

  List<String> _findEmails(String raw) {
    return _emailRegex.allMatches(raw).map((m) => m.group(0)!.toLowerCase()).toSet().toList();
  }

  String _contentHash(Map<String, dynamic> row) {
    final parts = row.entries.map((e) => '${e.key}=${_display(e.value)}').toList()..sort();
    final digest = sha1.convert(utf8.encode(parts.join('|'))).toString();
    return digest.substring(0, 16);
  }

  String _display(dynamic value) {
    if (value == null) return '';
    if (value is List) {
      return value.map(_display).where((v) => v.isNotEmpty).join(', ');
    }
    if (value is Map) {
      final formatted = value['f'] ?? value['label'] ?? value['name'] ?? value['title'];
      if (formatted != null && formatted.toString().trim().isNotEmpty) {
        return formatted.toString().trim();
      }
      final nested = value['v'] ?? value['value'];
      if (nested != null && nested != value) return _display(nested);
    }
    return value.toString().trim();
  }

  bool _hasData(Map<String, dynamic> row) {
    return row.values.any((v) => _display(v).isNotEmpty);
  }
}

class PreparedCampaignRow {
  final Map<String, dynamic> rawJson;
  final String fingerprint;
  final Map<String, String> mappings;

  PreparedCampaignRow({
    required this.rawJson,
    required this.fingerprint,
    required this.mappings,
  });
}

class _ColumnProfile {
  final Set<String> dropdowns;
  final Set<String> phoneHeaders;
  final Set<String> emailHeaders;
  final Set<String> personHeaders;
  final Set<String> propertyHeaders;

  _ColumnProfile({
    required this.dropdowns,
    required this.phoneHeaders,
    required this.emailHeaders,
    required this.personHeaders,
    required this.propertyHeaders,
  });
}

class _InferredRow {
  final Map<String, dynamic> row;
  final List<String> phones;
  final String fingerprint;
  final Map<String, String> mappings;

  _InferredRow({
    required this.row,
    required this.phones,
    required this.fingerprint,
    required this.mappings,
  });
}
