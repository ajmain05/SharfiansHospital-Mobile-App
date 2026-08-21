import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/event.dart';
import '../../../models/event_registration_summary.dart';

class EventsRepository {
  final _api = ApiClient();

  Future<List<Event>> getPublicEvents() async {
    final res = await _api.get('/events/public');
    if (!res.success || res.data is! List) return const [];
    return (res.data as List)
        .map((e) => Event.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Event> getEventBySlug(String slug) async {
    final res = await _api.get('/events/public/$slug');
    if (!res.success || res.data is! Map<String, dynamic>) {
      throw ApiException(
        res.error ?? 'Event not found',
        statusCode: res.statusCode,
      );
    }
    return Event.fromJson(res.data as Map<String, dynamic>);
  }

  Future<EventLiveSnapshot> getLiveSnapshot(String eventId) async {
    final res = await _api.get('/events/public/live-snapshot/$eventId');
    if (!res.success || res.data is! Map<String, dynamic>) {
      throw ApiException(
        res.error ?? 'Failed to load live stats',
        statusCode: res.statusCode,
      );
    }
    return EventLiveSnapshot.fromJson(res.data as Map<String, dynamic>);
  }

  /// Returns the created registration's `{id, totalAmount}`.
  Future<Map<String, dynamic>> submitRegistration(
    Map<String, dynamic> payload,
  ) async {
    final res = await _api.post('/event-registrations/submit', payload);
    if (!res.success) {
      throw ApiException(
        res.error ?? 'Registration failed',
        statusCode: res.statusCode,
      );
    }
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<EventRegistrationSummary> getStatusByToken(String token) async {
    final res = await _api.get('/event-registrations/status/$token');
    if (!res.success || res.data is! Map<String, dynamic>) {
      throw ApiException(
        res.error ?? 'Registration not found',
        statusCode: res.statusCode,
      );
    }
    return EventRegistrationSummary.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<EventRegistrationSummary>> checkByPhone(String phone) async {
    final res = await _api.get('/event-registrations/check-phone/$phone');
    if (!res.success || res.data is! List) return const [];
    return (res.data as List)
        .map(
          (e) => EventRegistrationSummary.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// Starts a bKash PGW checkout. Returns `{bkashURL, paymentID}` — the
  /// caller opens `bkashURL` in a webview and, once bKash redirects back,
  /// calls [executeBkashPayment] or [cancelBkashPayment].
  Future<Map<String, dynamic>> createBkashPayment({
    required String eventId,
    required String name,
    required String phone,
    required int personsCount,
  }) async {
    final res = await _api.post('/bkash/create-payment', {
      'eventId': eventId,
      'name': name,
      'phone': phone,
      'personsCount': personsCount,
    });
    if (!res.success || res.data is! Map) {
      throw ApiException(
        res.error ?? 'Failed to start bKash payment',
        statusCode: res.statusCode,
      );
    }
    return (res.data as Map).cast<String, dynamic>();
  }

  /// Verifies a completed bKash payment server-side and creates the
  /// registration. Returns `{qrCodeToken}` on success.
  Future<Map<String, dynamic>> executeBkashPayment(String paymentID) async {
    final res = await _api.post('/bkash/execute-payment', {
      'paymentID': paymentID,
      'status': 'success',
    });
    if (!res.success || res.data is! Map) {
      throw ApiException(
        res.error ?? 'Payment verification failed',
        statusCode: res.statusCode,
      );
    }
    return (res.data as Map).cast<String, dynamic>();
  }

  /// Best-effort cleanup when the user cancels/abandons a bKash checkout.
  Future<void> cancelBkashPayment(String paymentID) async {
    await _api.post('/bkash/cancel-payment', {'paymentID': paymentID});
  }
}
