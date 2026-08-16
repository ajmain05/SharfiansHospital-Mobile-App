import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around shared_preferences, mirroring the localStorage keys the
/// website already uses (sharfians_investor_data / sharfians_investor_phone / appLang)
/// so both surfaces behave the same way for anyone comparing them.
class LocalStorage {
  LocalStorage._();

  static const _kInvestorData = 'sharfians_investor_data';
  static const _kInvestorPhone = 'sharfians_investor_phone';
  static const _kAppLang = 'appLang';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    final p = _prefs;
    if (p == null) {
      throw StateError('LocalStorage.init() must be awaited before use.');
    }
    return p;
  }

  static Future<void> saveInvestorAccounts(List<Map<String, dynamic>> accounts) {
    return _p.setString(_kInvestorData, jsonEncode(accounts));
  }

  static List<Map<String, dynamic>>? getInvestorAccounts() {
    final raw = _p.getString(_kInvestorData);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveInvestorPhone(String phone) => _p.setString(_kInvestorPhone, phone);

  static String? getInvestorPhone() => _p.getString(_kInvestorPhone);

  static Future<void> clearInvestorSession() async {
    await _p.remove(_kInvestorData);
    await _p.remove(_kInvestorPhone);
  }

  static Future<void> saveLang(String lang) => _p.setString(_kAppLang, lang);

  static String getLang() => _p.getString(_kAppLang) ?? 'en';
}
