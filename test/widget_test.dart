import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sharfian_app/app.dart';
import 'package:sharfian_app/core/l10n/bundled_translations.dart';
import 'package:sharfian_app/core/storage/local_storage.dart';
import 'package:sharfian_app/features/home/providers/public_stats_provider.dart';
import 'package:sharfian_app/features/settings/providers/site_settings_provider.dart';
import 'package:sharfian_app/models/site_settings.dart';

import 'helpers/secure_storage_mock.dart';

void main() {
  testWidgets('App boots and shows the home screen', (WidgetTester tester) async {
    mockSecureStorage();
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    await BundledTranslations.load();

    // Avoid real network calls in the widget test — stub the two providers
    // that fire on first build of the home screen.
    await tester.pumpWidget(ProviderScope(
      overrides: [
        siteSettingsProvider.overrideWith((ref) async => SiteSettings.fallback()),
        publicStatsProvider.overrideWith((ref) async => <String, dynamic>{}),
      ],
      child: const SharfianApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sharfians Hospital PLC'), findsOneWidget);
  });
}
