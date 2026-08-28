import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../models/notification_item.dart';

class NotificationsRepository {
  final _api = ApiClient();

  /// This device's own current FCM token — every inbox call is keyed by it
  /// (same trust level as /register-token; there's no investor bearer-auth
  /// yet to require instead, see push_notification_service.dart).
  ///
  /// On iOS, getToken() throws until the OS has delivered an APNs token to
  /// the app — a real device passes this within moments of granting
  /// permission, but there's an inherent race right after launch, and the
  /// iOS Simulator never gets one at all. Treating that as "no token yet" (a
  /// perfectly normal, temporary state) rather than letting it propagate is
  /// what keeps the inbox screen from showing a scary connection-error
  /// state for something that isn't a connection error.
  Future<String?> _currentToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('FCM token not available yet: $e');
      return null;
    }
  }

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

  Future<void> deleteOne(String recipientId) async {
    await _api.delete('/notifications/inbox/$recipientId');
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
