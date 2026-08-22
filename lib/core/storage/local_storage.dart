import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around shared_preferences, mirroring the localStorage keys the
/// website already uses (sharfians_investor_data / sharfians_investor_phone / appLang)
/// so both surfaces behave the same way for anyone comparing them.
///
/// The auth token and session data (admin + investor) are privileged enough
/// to warrant more than plain shared_preferences, so those four keys live in
/// the OS keychain/keystore via [FlutterSecureStorage] instead. They're also
/// cached in memory after [init] so the many existing synchronous call sites
/// (e.g. GoRouter redirect guards, the Dio auth interceptor) don't need to
/// become async — writes go to memory and secure storage together.
class LocalStorage {
  LocalStorage._();

  static const _kInvestorData = 'sharfians_investor_data';
  static const _kInvestorPhone = 'sharfians_investor_phone';
  static const _kAdminToken = 'sharfians_admin_token';
  static const _kAdminData = 'sharfians_admin_data';
  static const _kAppLang = 'appLang';
  static const _kAppTheme = 'appThemeMode';

  static SharedPreferences? _prefs;
  static const _secure = FlutterSecureStorage();

  static List<Map<String, dynamic>>? _investorAccounts;
  static String? _investorPhone;
  static String? _adminToken;
  static Map<String, dynamic>? _adminData;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    try {
      await _migrateAndLoadSecureValues();
    } catch (e) {
      // Secure storage being unavailable shouldn't crash app startup — worst
      // case the user has to log in again, which is safe.
      debugPrint('LocalStorage: secure storage unavailable, starting logged out: $e');
    }
  }

  static SharedPreferences get _p {
    final p = _prefs;
    if (p == null) {
      throw StateError('LocalStorage.init() must be awaited before use.');
    }
    return p;
  }

  /// These four keys used to live in plain shared_preferences. On first run
  /// after the update, pull any existing value out of shared_preferences into
  /// secure storage (and delete the plaintext copy) so nobody gets silently
  /// logged out — from then on secure storage is the only copy.
  static Future<void> _migrateAndLoadSecureValues() async {
    Future<String?> migrate(String key) async {
      final secureValue = await _secure.read(key: key);
      if (secureValue != null) return secureValue;
      final legacyValue = _p.getString(key);
      if (legacyValue != null) {
        await _secure.write(key: key, value: legacyValue);
        await _p.remove(key);
      }
      return legacyValue;
    }

    _adminToken = await migrate(_kAdminToken);
    _investorPhone = await migrate(_kInvestorPhone);

    final adminDataRaw = await migrate(_kAdminData);
    if (adminDataRaw != null) {
      try {
        _adminData = jsonDecode(adminDataRaw) as Map<String, dynamic>;
      } catch (_) {}
    }

    final investorDataRaw = await migrate(_kInvestorData);
    if (investorDataRaw != null) {
      try {
        _investorAccounts = (jsonDecode(investorDataRaw) as List)
            .cast<Map<String, dynamic>>();
      } catch (_) {}
    }
  }

  static Future<void> saveInvestorAccounts(
    List<Map<String, dynamic>> accounts,
  ) async {
    _investorAccounts = accounts;
    await _secure.write(key: _kInvestorData, value: jsonEncode(accounts));
  }

  static List<Map<String, dynamic>>? getInvestorAccounts() =>
      _investorAccounts;

  static Future<void> saveInvestorPhone(String phone) async {
    _investorPhone = phone;
    await _secure.write(key: _kInvestorPhone, value: phone);
  }

  static String? getInvestorPhone() => _investorPhone;

  static Future<void> clearInvestorSession() async {
    _investorAccounts = null;
    _investorPhone = null;
    await _secure.delete(key: _kInvestorData);
    await _secure.delete(key: _kInvestorPhone);
  }

  static Future<void> saveLang(String lang) => _p.setString(_kAppLang, lang);

  static String getLang() => _p.getString(_kAppLang) ?? 'en';

  static Future<void> saveThemeMode(String theme) =>
      _p.setString(_kAppTheme, theme);

  static String getThemeMode() => _p.getString(_kAppTheme) ?? 'system';

  // ─── ADMIN AUTH ────────────────────────────────────────────────────────────

  static Future<void> saveAdminToken(String token) async {
    _adminToken = token;
    await _secure.write(key: _kAdminToken, value: token);
  }

  static String? getAdminToken() => _adminToken;

  static Future<void> saveAdminData(Map<String, dynamic> data) async {
    _adminData = data;
    await _secure.write(key: _kAdminData, value: jsonEncode(data));
  }

  static Map<String, dynamic>? getAdminData() => _adminData;

  static Future<void> clearAdminSession() async {
    _adminToken = null;
    _adminData = null;
    await _secure.delete(key: _kAdminToken);
    await _secure.delete(key: _kAdminData);
  }
}
