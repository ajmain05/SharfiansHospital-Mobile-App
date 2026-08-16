import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around shared_preferences, mirroring the localStorage keys the
/// website already uses (sharfians_investor_data / sharfians_investor_phone / appLang)
/// so both surfaces behave the same way for anyone comparing them.
class LocalStorage {
  LocalStorage._();

  static const _kInvestorData = 'sharfians_investor_data';
  static const _kInvestorPhone = 'sharfians_investor_phone';
  static const _kAdminToken = 'sharfians_admin_token';
  static const _kAdminData = 'sharfians_admin_data';
  static const _kAppLang = 'appLang';
  static const _kAppTheme = 'appThemeMode';

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

  static Future<void> saveInvestorAccounts(
    List<Map<String, dynamic>> accounts,
  ) {
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

  static Future<void> saveInvestorPhone(String phone) =>
      _p.setString(_kInvestorPhone, phone);

  static String? getInvestorPhone() => _p.getString(_kInvestorPhone);

  static Future<void> clearInvestorSession() async {
    await _p.remove(_kInvestorData);
    await _p.remove(_kInvestorPhone);
  }

  static Future<void> saveLang(String lang) => _p.setString(_kAppLang, lang);

  static String getLang() => _p.getString(_kAppLang) ?? 'en';

  static Future<void> saveThemeMode(String theme) => _p.setString(_kAppTheme, theme);

  static String getThemeMode() => _p.getString(_kAppTheme) ?? 'system';
  // ─── ADMIN AUTH ────────────────────────────────────────────────────────────

  static Future<void> saveAdminToken(String token) =>
      _p.setString(_kAdminToken, token);

  static String? getAdminToken() => _p.getString(_kAdminToken);

  static Future<void> saveAdminData(Map<String, dynamic> data) =>
      _p.setString(_kAdminData, jsonEncode(data));

  static Map<String, dynamic>? getAdminData() {
    final str = _p.getString(_kAdminData);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAdminSession() async {
    await _p.remove(_kAdminToken);
    await _p.remove(_kAdminData);
  }
}
