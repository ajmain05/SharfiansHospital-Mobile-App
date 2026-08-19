import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class AdminDashboardRepository {
  final _api = ApiClient();

  /// Gets total investors and funds from the investors list endpoint
  Future<Map<String, dynamic>> getInvestorStats() async {
    final res = await _api.get('/investors', query: {'limit': '1'});
    if (!res.success) {
      throw ApiException(res.error ?? 'Failed to load stats', statusCode: res.statusCode);
    }
    // `res.data` is typically a List for `/investors`. The top-level 'stats' is kept in `res.raw`.
    final rawMap = res.raw as Map<String, dynamic>? ?? {};
    return (rawMap['stats'] as Map<String, dynamic>?) ?? {};
  }

  /// Gets all events to select from
  Future<List<dynamic>> getEvents() async {
    final res = await _api.get('/events');
    if (!res.success) {
      throw ApiException(res.error ?? 'Failed to load events', statusCode: res.statusCode);
    }
    return res.data as List<dynamic>;
  }

  /// Gets registrations for a specific event
  Future<List<dynamic>> getEventRegistrations(String eventId) async {
    final res = await _api.get('/event-registrations', query: {'eventId': eventId});
    if (!res.success) {
      throw ApiException(res.error ?? 'Failed to load registrations', statusCode: res.statusCode);
    }
    return res.data as List<dynamic>;
  }

  /// Approves an event registration
  Future<void> approveRegistration(String id) async {
    final res = await _api.post('/event-registrations/$id/approve', {
      'frontendUrl': 'https://sharfianshospital.com' // Backend needs this for SMS link
    });
    if (!res.success) {
      throw ApiException(res.error ?? 'Failed to approve', statusCode: res.statusCode);
    }
  }

  /// Rejects an event registration
  Future<void> rejectRegistration(String id) async {
    final res = await _api.post('/event-registrations/$id/reject');
    if (!res.success) {
      throw ApiException(res.error ?? 'Failed to reject', statusCode: res.statusCode);
    }
  }

  /// Search investors
  Future<List<dynamic>> searchInvestors(String query) async {
    final res = await _api.get('/investors', query: {'search': query, 'limit': '50'});
    if (!res.success) {
      throw ApiException(res.error ?? 'Failed to search investors', statusCode: res.statusCode);
    }
    return res.data as List<dynamic>;
  }
}

final adminDashboardRepoProvider = Provider((ref) => AdminDashboardRepository());
