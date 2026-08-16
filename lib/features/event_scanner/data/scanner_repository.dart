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
    
    // The backend returns `{ success: true, scanResult: 'SUCCESS', ... }`
    // Or it might throw 400 with `{ scanResult: 'ALREADY_SCANNED', message: ... }`
    if (!res.success) {
      if (res.data != null && res.data is Map<String, dynamic> && res.data['scanResult'] != null) {
        return res.data as Map<String, dynamic>;
      }
      throw ApiException(
        res.error ?? 'Scan failed',
        statusCode: res.statusCode,
      );
    }
    
    return res.data as Map<String, dynamic>;
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
