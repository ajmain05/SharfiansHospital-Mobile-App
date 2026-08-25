import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class ScannerRepository {
  final _api = ApiClient();

  /// `POST /event-registrations/scan`
  /// Returns a Map with { scanResult, message, data }
  Future<Map<String, dynamic>> scanQrCode(String token) async {
    final res = await _api.post('/event-registrations/scan', {
      'qrCodeToken': token,
    });

    // The backend signals a non-SUCCESS scan (ALREADY_SCANNED, NOT_APPROVED)
    // two different ways depending on the case: sometimes as a 200 response
    // with `success: false` in the body (res.raw), sometimes as an actual
    // HTTP error body (res.data, which ApiClient._fail() leaves untouched).
    // ApiClient's generic `data`-key unwrapping strips `scanResult`/`message`
    // out of res.data on the 200-response path, so check res.raw first —
    // whichever of the two still has scanResult intact is the real payload.
    for (final candidate in [res.raw, res.data]) {
      if (candidate is Map<String, dynamic> &&
          candidate['scanResult'] != null) {
        return candidate;
      }
    }

    if (!res.success) {
      throw ApiException(
        res.error ?? 'Scan failed',
        statusCode: res.statusCode,
      );
    }

    return res.raw as Map<String, dynamic>;
  }

  /// `GET /events/public/active`
  Future<Map<String, dynamic>?> getActiveEvent() async {
    final res = await _api.get('/events/public/active');
    if (!res.success) return null;
    return res.data as Map<String, dynamic>;
  }

  /// `GET /events/:id/live-stats`
  Future<Map<String, dynamic>?> getLiveStats(String eventId) async {
    final res = await _api.get('/events/$eventId/live-stats');
    if (!res.success) return null;
    return res.data as Map<String, dynamic>;
  }
}
