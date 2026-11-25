import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/app_logger.dart';

class SupportContacts {
  final String whatsapp;
  final String whatsappHours;
  final String phone;
  final String phoneDisplay;
  final String email;

  const SupportContacts({
    required this.whatsapp,
    required this.whatsappHours,
    required this.phone,
    required this.phoneDisplay,
    required this.email,
  });

  static const SupportContacts defaults = SupportContacts(
    whatsapp: '919999999999',
    whatsappHours: 'Mon–Sat, 9:30 AM – 7 PM',
    phone: '+917900000000',
    phoneDisplay: '+91 79 0000 0000',
    email: 'support@nbpropertytech.com',
  );

  String get whatsappDigits => whatsapp.replaceAll(RegExp(r'\D'), '');

  String get whatsappSubtitle =>
      whatsappHours.trim().isEmpty ? 'Fastest · WhatsApp support' : 'Fastest · $whatsappHours';

  Uri get whatsappUri => Uri.parse('https://wa.me/$whatsappDigits');
  Uri get phoneUri => Uri.parse('tel:$phone');
  Uri get emailUri => Uri.parse('mailto:$email');

  SupportContacts copyWith({
    String? whatsapp,
    String? whatsappHours,
    String? phone,
    String? phoneDisplay,
    String? email,
  }) {
    return SupportContacts(
      whatsapp: whatsapp ?? this.whatsapp,
      whatsappHours: whatsappHours ?? this.whatsappHours,
      phone: phone ?? this.phone,
      phoneDisplay: phoneDisplay ?? this.phoneDisplay,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() => {
        'whatsapp': whatsappDigits,
        'whatsapp_hours': whatsappHours,
        'phone': phone,
        'phone_display': phoneDisplay,
        'email': email,
      };

  factory SupportContacts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return defaults;
    final whatsapp = (json['whatsapp'] ?? defaults.whatsapp).toString().replaceAll(RegExp(r'\D'), '');
    final phone = (json['phone'] ?? defaults.phone).toString().trim();
    final phoneDisplay = (json['phone_display'] ?? json['phoneDisplay'] ?? defaults.phoneDisplay)
        .toString()
        .trim();
    final email = (json['email'] ?? defaults.email).toString().trim().toLowerCase();
    final hours = (json['whatsapp_hours'] ?? json['whatsappHours'] ?? defaults.whatsappHours)
        .toString()
        .trim();
    return SupportContacts(
      whatsapp: whatsapp.isNotEmpty ? whatsapp : defaults.whatsapp,
      whatsappHours: hours.isNotEmpty ? hours : defaults.whatsappHours,
      phone: phone.isNotEmpty ? phone : defaults.phone,
      phoneDisplay: phoneDisplay.isNotEmpty ? phoneDisplay : defaults.phoneDisplay,
      email: email.contains('@') ? email : defaults.email,
    );
  }
}

/// Org-scoped Support page contact details (WhatsApp / Call / Email).
class SupportContactsManager extends ChangeNotifier {
  static final SupportContactsManager _instance = SupportContactsManager._internal();
  factory SupportContactsManager() => _instance;

  static const String prefsKey = 'propkart_support_contacts_v1';

  SupportContacts _contacts = SupportContacts.defaults;
  bool _isLoaded = false;
  bool _isSyncing = false;

  SupportContactsManager._internal() {
    _loadPersisted();
  }

  SupportContacts get contacts => _contacts;
  bool get isLoaded => _isLoaded;
  bool get isSyncing => _isSyncing;

  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _contacts = SupportContacts.fromJson(decoded);
        }
      }
      _isLoaded = true;
      notifyListeners();
    } catch (_) {
      _isLoaded = true;
    }
    await fetchFromBackend(silent: true);
  }

  Future<void> fetchFromBackend({bool silent = false}) async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final response = await ApiClient().get('/config/support-contacts');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        final contactsJson = data is Map ? data['contacts'] : null;
        if (contactsJson is Map) {
          final next = SupportContacts.fromJson(Map<String, dynamic>.from(contactsJson));
          if (next.toJson().toString() != _contacts.toJson().toString()) {
            _contacts = next;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(prefsKey, jsonEncode(next.toJson()));
            notifyListeners();
          }
        }
      }
      _isLoaded = true;
    } catch (e) {
      if (!silent) {
        AppLogger.w('SupportContactsManager: Failed to fetch contacts: $e');
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> save(SupportContacts next) async {
    final normalized = SupportContacts.fromJson(next.toJson());
    _contacts = normalized;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, jsonEncode(normalized.toJson()));
    } catch (_) {}

    try {
      final response = await ApiClient().put('/config/support-contacts', normalized.toJson());
      if (response.statusCode == 200) {
        final data = response.data['data'];
        final contactsJson = data is Map ? data['contacts'] : null;
        if (contactsJson is Map) {
          _contacts = SupportContacts.fromJson(Map<String, dynamic>.from(contactsJson));
          notifyListeners();
        }
        AppLogger.d('SupportContactsManager: Persisted support contacts');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.w('SupportContactsManager: Failed to save contacts: $e');
      return false;
    }
  }
}
