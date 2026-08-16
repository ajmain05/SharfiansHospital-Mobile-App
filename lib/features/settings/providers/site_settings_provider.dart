import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/site_settings.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) => SettingsRepository());

/// Site-wide CMS content, consumed by Home, Registration, Investor Login,
/// and the l10n system's custom-translation overrides.
final siteSettingsProvider = FutureProvider<SiteSettings>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.getSettings();
});
