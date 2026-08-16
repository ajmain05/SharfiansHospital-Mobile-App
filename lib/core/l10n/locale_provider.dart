import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/providers/site_settings_provider.dart';
import '../storage/local_storage.dart';
import 'bundled_translations.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(Locale(LocalStorage.getLang()));

  void toggle() => set(state.languageCode == 'en' ? 'bn' : 'en');

  void set(String languageCode) {
    state = Locale(languageCode);
    LocalStorage.saveLang(languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

/// Admin-edited overrides from `GET /api/settings` -> `customTranslations`.
/// Starts empty until settings load, then the UI naturally rebuilds once
/// this resolves (Riverpod re-runs anything watching it).
final customTranslationsProvider = Provider((ref) {
  final settings = ref.watch(siteSettingsProvider);
  return settings.maybeWhen(
    data: (s) => s.customTranslations,
    orElse: () => const [],
  );
});

/// Resolves a translation key through the same order as the website's
/// `LanguageContext.jsx`: (1) admin override matched by key or by the
/// bundled English text, (2) the bundled dictionary, (3) the raw key.
/// `params` does simple `{name}`-style substitution.
String t(WidgetRef ref, String key, {Map<String, String>? params}) {
  final lang = ref.watch(localeProvider).languageCode;
  final custom = ref.watch(customTranslationsProvider);
  final fallbackEn = BundledTranslations.get('en', key);

  String? resolved;
  for (final c in custom) {
    final matchesKey = c.key == key;
    final matchesEnglishText =
        c.en != null &&
        c.en!.toLowerCase().trim() == fallbackEn.toLowerCase().trim();
    if (matchesKey || matchesEnglishText) {
      final val = c.forLang(lang);
      if (val != null && val.isNotEmpty) resolved = val;
      break;
    }
  }

  resolved ??= BundledTranslations.get(lang, key);

  if (params != null && params.isNotEmpty) {
    params.forEach((k, v) {
      resolved = resolved!.replaceAll('{$k}', v);
    });
  }
  return resolved!;
}
