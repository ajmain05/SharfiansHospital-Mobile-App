import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/notification_item.dart';

class NotificationsRepository {
  final _api = ApiClient();

  /// This device's own current FCM token — every inbox call is keyed by it
  /// (same trust level as /register-token; there's no investor bearer-auth
  /// yet to require instead, see push_notification_service.dart).
  Future<String?> _currentToken() => FirebaseMessaging.instance.getToken();

  Future<List<NotificationItem>> getInbox() async {
    final token = await _currentToken();
    if (token == null) return const [];
    final res = await _api.get('/notifications/inbox', query: {'token': token});
    if (!res.success) {
      throw ApiException(res.error ?? 'Failed to load notifications', statusCode: res.statusCode);
    }
    final list = (res.data as List?) ?? const [];
    return list
        .map((e) => NotificationItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> markRead(String recipientId) async {
    await _api.post('/notifications/inbox/$recipientId/read');
  }

  Future<void> markAllRead() async {
    final token = await _currentToken();
    if (token == null) return;
    await _api.post('/notifications/inbox/read-all', {'token': token});
  }

  Future<void> clearAll() async {
    final token = await _currentToken();
    if (token == null) return;
    await _api.delete('/notifications/inbox', query: {'token': token});
  }
}
