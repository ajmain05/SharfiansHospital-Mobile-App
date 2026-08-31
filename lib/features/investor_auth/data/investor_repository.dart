import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

/// Wraps every `/investors*` endpoint the app needs. Kept as raw
/// `Map<String, dynamic>` returns (rather than parsed [Investor]s) so callers
/// can cache the exact server payload verbatim, matching the website's own
/// localStorage-caching behavior in `investorService.js` / `InvestorDashboard.jsx`.
class InvestorRepository {
  final _api = ApiClient();

  /// `POST /investors/auth-phone` — unchanged, still used for the silent
  /// background refresh of an already-logged-in session (see
  /// [InvestorSessionNotifier]), which must never itself trigger an OTP/SMS.
  Future<List<Map<String, dynamic>>> loginWithPhone(String phone) async {
    final res = await _api.post('/investors/auth-phone', {'phone': phone});
    if (!res.success) {
      throw ApiException(
        res.error ?? 'Login failed',
        statusCode: res.statusCode,
      );
    }
    final data = res.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    return const [];
  }

  /// `POST /investors/auth-phone/start` — the explicit login screen's entry
  /// point, OTP-gated for BD numbers only. Returns `otpRequired: false` with
  /// `accounts` already populated for a non-BD number (login already
  /// complete, identical to today's [loginWithPhone]), or `otpRequired: true`
  /// with an empty `accounts` list when [verifyPhoneAuthOtp] must be called
  /// next. Reads from `res.raw` (not `res.data`) because [ApiClient] only
  /// populates `res.data` from the body's `data` key when present, which
  /// would silently drop the `otpRequired` flag itself in the non-BD case.
  Future<({bool otpRequired, List<Map<String, dynamic>> accounts})> startPhoneAuth(
    String phone,
  ) async {
    final res = await _api.post('/investors/auth-phone/start', {'phone': phone});
    if (!res.success) {
      throw ApiException(
        res.error ?? 'Login failed',
        statusCode: res.statusCode,
      );
    }
    final body = res.raw;
    final otpRequired = body is Map && body['otpRequired'] == true;
    final rawAccounts = body is Map ? body['data'] : null;
    return (
      otpRequired: otpRequired,
      accounts: rawAccounts is List
          ? rawAccounts.cast<Map<String, dynamic>>()
          : const <Map<String, dynamic>>[],
    );
  }

  /// `POST /investors/auth-phone/verify` — verifies the code sent by
  /// [startPhoneAuth] and completes login, returning the same shape as
  /// [loginWithPhone].
  Future<List<Map<String, dynamic>>> verifyPhoneAuthOtp(
    String phone,
    String code,
  ) async {
    final res = await _api.post('/investors/auth-phone/verify', {
      'phone': phone,
      'code': code,
    });
    if (!res.success) {
      throw ApiException(
        res.error ?? 'Verification failed',
        statusCode: res.statusCode,
      );
    }
    final data = res.data;
    if (data is List) return data.cast<Map<String, dynamic>>();
    return const [];
  }

  /// `POST /investors` — public registration.
  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final res = await _api.post('/investors', payload);
    if (!res.success) {
      throw ApiException(
        res.error ?? 'Registration failed',
        statusCode: res.statusCode,
      );
    }
    return res.data as Map<String, dynamic>;
  }

  /// `PUT /investors/public-update/:id` — nominee/charity-% self-edit,
  /// gated by a phone match on the backend.
  Future<Map<String, dynamic>> updatePublicProfile(
    String id,
    Map<String, dynamic> data,
  ) async {
    final res = await _api.put('/investors/public-update/$id', data);
    if (!res.success) {
      throw ApiException(
        res.error ?? 'Update failed',
        statusCode: res.statusCode,
      );
    }
    return res.data as Map<String, dynamic>;
  }

  /// `POST /investors/:id/request-deletion` — submits an account deletion
  /// request. Does NOT revoke portal access; access stays fully intact until
  /// a superadmin actually approves the request from the admin dashboard.
  Future<void> requestAccountDeletion({
    required String id,
    required String phone,
    required String reason,
    String? details,
  }) async {
    final res = await _api.post('/investors/$id/request-deletion', {
      'phone': phone,
      'reason': reason,
      if (details != null && details.trim().isNotEmpty) 'details': details.trim(),
    });
    if (!res.success) {
      throw ApiException(
        res.error ?? 'Failed to submit deletion request',
        statusCode: res.statusCode,
      );
    }
  }

  /// `POST /investors/:id/request-share-increase` — submits how much MORE
  /// the investor wants to invest (not a new total), gated by an admin's
  /// approval from the dashboard. Does not change share_amount itself yet.
  Future<void> requestShareIncrease({
    required String id,
    required String phone,
    required num additionalAmount,
    String? reason,
  }) async {
    final res = await _api.post('/investors/$id/request-share-increase', {
      'phone': phone,
      'additionalAmount': additionalAmount,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
    if (!res.success) {
      throw ApiException(
        res.error ?? 'Failed to submit share increase request',
        statusCode: res.statusCode,
      );
    }
  }

  /// `GET /investors/public-stats` — live totals for the home screen.
  /// Response is shaped `{success, stats: {...}}` (not `data`), so unwrap
  /// `stats` explicitly rather than relying on [ApiClient]'s default `data` key.
  /// A real request failure (offline, timeout, server error) is rethrown so
  /// the home screen lands in an `AsyncError` and shows the retry UI instead
  /// of silently displaying "0 investors" as if that were live data.
  Future<Map<String, dynamic>> getPublicStats() async {
    final res = await _api.get('/investors/public-stats');
    if (!res.success) {
      throw ApiException(
        res.error ?? 'Failed to load stats',
        statusCode: res.statusCode,
      );
    }
    if (res.data is! Map<String, dynamic>) return const {};
    final body = res.data as Map<String, dynamic>;
    final stats = body['stats'];
    return stats is Map<String, dynamic> ? stats : const {};
  }
}
