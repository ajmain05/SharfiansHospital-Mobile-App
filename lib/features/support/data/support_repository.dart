import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/local_storage.dart';
import '../../../models/support_category.dart';
import '../../../models/support_ticket.dart';

/// Wraps every `/support/investor/*` endpoint — the app-side half of the
/// Help & Support feature (the admin-panel half lives in the web dashboard's
/// SupportTab.jsx). Same explicit-Authorization-header pattern as
/// InvestorRepository, so an admin and investor session can coexist on one
/// device without either call site picking up the wrong token.
class SupportRepository {
  final _api = ApiClient();

  Map<String, String>? _investorAuthHeaders() {
    final token = LocalStorage.getInvestorToken();
    return token != null ? {'Authorization': 'Bearer $token'} : null;
  }

  /// Current category list (id + label), admin-editable from the web
  /// dashboard's Settings — public endpoint, no investor auth needed.
  Future<List<SupportCategory>> getCategories() async {
    final res = await _api.get('/support/categories');
    if (!res.success) {
      throw ApiException(res.error ?? 'Failed to load categories', statusCode: res.statusCode);
    }
    final list = (res.data as List?) ?? const [];
    return list.map((e) => SupportCategory.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<List<SupportTicket>> getTickets(String investorId) async {
    final res = await _api.get('/support/investor/$investorId/tickets', headers: _investorAuthHeaders());
    if (!res.success) {
      throw ApiException(res.error ?? 'Failed to load queries', statusCode: res.statusCode);
    }
    final list = (res.data as List?) ?? const [];
    return list.map((e) => SupportTicket.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<SupportTicket> getTicketThread(String investorId, String ticketId) async {
    final res = await _api.get('/support/investor/$investorId/tickets/$ticketId', headers: _investorAuthHeaders());
    if (!res.success) {
      throw ApiException(res.error ?? 'Failed to load the query', statusCode: res.statusCode);
    }
    return SupportTicket.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<SupportTicket> createTicket({
    required String investorId,
    required String category,
    String? subject,
    required String message,
    String? attachmentUrl,
  }) async {
    final res = await _api.post('/support/investor/$investorId/tickets', {
      'category': category,
      if (subject != null && subject.trim().isNotEmpty) 'subject': subject.trim(),
      'message': message.trim(),
      'attachmentUrl': ?attachmentUrl,
    }, _investorAuthHeaders());
    if (!res.success) {
      throw ApiException(res.error ?? 'Failed to submit your query', statusCode: res.statusCode);
    }
    return SupportTicket.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<void> postMessage({
    required String investorId,
    required String ticketId,
    required String message,
    String? attachmentUrl,
  }) async {
    final res = await _api.post('/support/investor/$investorId/tickets/$ticketId/messages', {
      'message': message.trim(),
      'attachmentUrl': ?attachmentUrl,
    }, _investorAuthHeaders());
    if (!res.success) {
      throw ApiException(res.error ?? 'Failed to send your reply', statusCode: res.statusCode);
    }
  }

  Future<void> markRead(String investorId, String ticketId) async {
    await _api.patch('/support/investor/$investorId/tickets/$ticketId/read', null, _investorAuthHeaders());
  }
}
