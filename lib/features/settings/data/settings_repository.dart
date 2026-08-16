import '../../../core/network/api_client.dart';
import '../../../models/site_settings.dart';

class SettingsRepository {
  final _api = ApiClient();

  /// `GET /api/settings` is public and admin-CMS-driven. Falls back to
  /// [SiteSettings.fallback] on any failure so screens never render blank,
  /// mirroring the website's own fallback-merge behavior.
  Future<SiteSettings> getSettings() async {
    final res = await _api.get('/settings');
    if (!res.success || res.data is! Map<String, dynamic>) {
      return SiteSettings.fallback();
    }
    try {
      return SiteSettings.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return SiteSettings.fallback();
    }
  }
}
