import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Static EN/BN dictionary bundled with the app, ported from the website's
/// `frontend/src/utils/translations.js`. Loaded once at startup; the
/// admin-editable overrides layered on top of this live in [Translator].
class BundledTranslations {
  BundledTranslations._();

  static Map<String, Map<String, String>> _dict = const {'en': {}, 'bn': {}};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final enRaw = await rootBundle.loadString('assets/translations/en.json');
    final bnRaw = await rootBundle.loadString('assets/translations/bn.json');
    _dict = {
      'en': Map<String, String>.from(jsonDecode(enRaw) as Map),
      'bn': Map<String, String>.from(jsonDecode(bnRaw) as Map),
    };
    _loaded = true;
  }

  static String get(String lang, String key) {
    return _dict[lang]?[key] ?? _dict['en']?[key] ?? key;
  }
}
