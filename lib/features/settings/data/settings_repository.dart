import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/site_settings.dart';

class SettingsRepository {
  final _api = ApiClient();

  /// `GET /api/settings` is public and admin-CMS-driven. A real request
  /// failure (offline, timeout, server error) is rethrown so callers land in
  /// an `AsyncError` and show the retry UI instead of silently pretending
  /// live, admin-controlled state (career open/closed, investor totals,
  /// portal enabled) resolved successfully with made-up defaults. Only a
  /// successful-but-oddly-shaped response falls back to
  /// [SiteSettings.fallback], mirroring the website's own fallback-merge
  /// behavior for that case.
  Future<SiteSettings> getSettings() async {
    final res = await _api.get('/settings');
    if (!res.success) {
      throw ApiException(
        res.error ?? 'Failed to load settings',
        statusCode: res.statusCode,
      );
    }
    if (res.data is! Map<String, dynamic>) {
      return SiteSettings.fallback();
    }
    try {
      return SiteSettings.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return SiteSettings.fallback();
    }
  }
}
