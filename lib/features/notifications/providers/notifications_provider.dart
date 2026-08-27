import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/notification_item.dart';
import '../data/notifications_repository.dart';

final notificationsRepositoryProvider = Provider((ref) => NotificationsRepository());

/// This device's notification history. Refreshed via `ref.invalidate` after
/// any mutating action (mark-read, clear) and whenever a push arrives in the
/// foreground (see push_notification_service.dart), rather than optimistic
/// local updates — matches the invalidate-and-refetch pattern already used
/// for every other list in this app.
final notificationsInboxProvider = FutureProvider.autoDispose<List<NotificationItem>>((ref) {
  return ref.read(notificationsRepositoryProvider).getInbox();
});

/// Derived, so the Home screen's bell badge can watch just the count without
/// rebuilding on every field of every notification.
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(notificationsInboxProvider).maybeWhen(
        data: (items) => items.where((n) => n.isUnread).length,
        orElse: () => 0,
      );
});
