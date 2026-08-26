import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../router/app_router.dart';
import '../widgets/app_update_dialog.dart';
import '../../features/settings/providers/site_settings_provider.dart';

/// Compares dot-separated version strings numerically (so "2.10.0" correctly
/// counts as newer than "2.9.0", unlike a plain string comparison).
bool _isNewer(String latest, String current) {
  List<int> parts(String v) =>
      v.trim().split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
  final a = parts(latest);
  final b = parts(current);
  final len = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < len; i++) {
    final av = i < a.length ? a[i] : 0;
    final bv = i < b.length ? b[i] : 0;
    if (av != bv) return av > bv;
  }
  return false;
}

/// Shows the update-nag dialog if the admin-configured latest version (set
/// in the web admin's Homepage Content → App Update Notice section) is newer
/// than what's installed. Silently does nothing if settings haven't loaded,
/// no version is configured for this platform, or the app is already current.
///
/// Deliberately takes no WidgetRef: this is called from the splash screen
/// right as it navigates away and disposes itself (see splash_screen.dart),
/// so a WidgetRef tied to that screen's lifecycle can throw mid-check. Reads
/// providers via dialogNavigatorKey's own ProviderContainer instead, which
/// outlives any individual screen.
Future<void> checkForAppUpdate() async {
  try {
    final context = dialogNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final container = ProviderScope.containerOf(context, listen: false);

    final settings = await container.read(siteSettingsProvider.future);
    final latestVersion = Platform.isIOS
        ? settings.appLatestVersionIos
        : settings.appLatestVersionAndroid;
    if (latestVersion.trim().isEmpty) return;

    final packageInfo = await PackageInfo.fromPlatform();
    if (!_isNewer(latestVersion, packageInfo.version)) return;

    if (!context.mounted) return;
    final storeUrl = Platform.isIOS ? settings.appIosStoreUrl : settings.appAndroidStoreUrl;
    // Deliberately shown on dialogNavigatorKey (a Navigator that sits above
    // GoRouter's own, see app_router.dart) — showing it on GoRouter's
    // navigator instead let it get silently dismissed whenever GoRouter next
    // reconciled that Navigator's page list, e.g. right after the splash
    // screen's own context.go('/') a moment earlier.
    await showAppUpdateDialog(context, latestVersion: latestVersion, storeUrl: storeUrl);
  } catch (_) {
    // Never block app usage over a failed update check.
  }
}
