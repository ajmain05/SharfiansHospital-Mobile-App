import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

/// Wraps every `/investors*` endpoint the app needs. Kept as raw
/// `Map<String, dynamic>` returns (rather than parsed [Investor]s) so callers
/// can cache the exact server payload verbatim, matching the website's own
/// localStorage-caching behavior in `investorService.js` / `InvestorDashboard.jsx`.
class InvestorRepository {
  final _api = ApiClient();

  /// `POST /investors/auth-phone` — the app's chosen login mechanism (no
  /// OTP/password). Returns every investor account matching this phone
  /// number, each with its `deposits` embedded.
  Future<List<Map<String, dynamic>>> loginWithPhone(String phone) async {
    final res = await _api.post('/investors/auth-phone', {'phone': phone});
    if (!res.success) throw ApiException(res.error ?? 'Login failed', statusCode: res.statusCode);
    final data = res.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    return const [];
  }

  /// `POST /investors` — public registration.
  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final res = await _api.post('/investors', payload);
    if (!res.success) throw ApiException(res.error ?? 'Registration failed', statusCode: res.statusCode);
    return res.data as Map<String, dynamic>;
  }

  /// `PUT /investors/public-update/:id` — nominee/charity-% self-edit,
  /// gated by a phone match on the backend.
  Future<Map<String, dynamic>> updatePublicProfile(String id, Map<String, dynamic> data) async {
    final res = await _api.put('/investors/public-update/$id', data);
    if (!res.success) throw ApiException(res.error ?? 'Update failed', statusCode: res.statusCode);
    return res.data as Map<String, dynamic>;
  }

  /// `GET /investors/public-stats` — live totals for the home screen.
  /// Response is shaped `{success, stats: {...}}` (not `data`), so unwrap
  /// `stats` explicitly rather than relying on [ApiClient]'s default `data` key.
  Future<Map<String, dynamic>> getPublicStats() async {
    final res = await _api.get('/investors/public-stats');
    if (!res.success || res.data is! Map<String, dynamic>) return const {};
    final body = res.data as Map<String, dynamic>;
    final stats = body['stats'];
    return stats is Map<String, dynamic> ? stats : const {};
  }
}
