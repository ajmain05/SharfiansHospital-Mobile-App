import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/theme/adaptive_colors.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../models/notification_item.dart';
import '../providers/notifications_provider.dart';

class _CategoryStyle {
  final IconData icon;
  final Color color;
  const _CategoryStyle(this.icon, this.color);
}

const _categoryStyles = {
  'payment': _CategoryStyle(Icons.payments_rounded, Color(0xFF16A34A)),
  'event': _CategoryStyle(Icons.event_rounded, AppColors.primary700),
};
const _defaultCategoryStyle = _CategoryStyle(Icons.campaign_rounded, AppColors.accent600);

String _timeAgo(WidgetRef ref, DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return t(ref, 'justNow');
  if (diff.inHours < 1) return t(ref, 'minutesAgo', params: {'count': '${diff.inMinutes}'});
  if (diff.inDays < 1) return t(ref, 'hoursAgo', params: {'count': '${diff.inHours}'});
  if (diff.inDays < 7) return t(ref, 'daysAgo', params: {'count': '${diff.inDays}'});
  return DateFormat.yMMMd().format(dateTime);
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _handleClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t(ref, 'clearNotificationsConfirmTitle'), style: GoogleFonts.publicSans(fontWeight: FontWeight.w800)),
        content: Text(t(ref, 'clearNotificationsConfirmBody'), style: GoogleFonts.publicSans(fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t(ref, 'cancel'), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t(ref, 'clearAll'), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(notificationsRepositoryProvider).clearAll();
      ref.invalidate(notificationsInboxProvider);
    }
  }

  Future<void> _handleTap(WidgetRef ref, NotificationItem item) async {
    // Navigate immediately — don't make the tap feel laggy waiting on the
    // mark-read network round trip.
    handleNotificationLink(item.link);
    if (item.isUnread) {
      await ref.read(notificationsRepositoryProvider).markRead(item.id);
      ref.invalidate(notificationsInboxProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(notificationsInboxProvider);

    return Scaffold(
      backgroundColor: context.bgFill,
      appBar: AppBar(
        backgroundColor: context.cardFill,
        elevation: 0,
        leading: BackButton(color: context.textHigh, onPressed: () => context.pop()),
        title: Text(
          t(ref, 'notifications'),
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: context.textHigh),
        ),
        actions: [
          inboxAsync.maybeWhen(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: t(ref, 'markAllRead'),
                    icon: Icon(Icons.done_all_rounded, color: context.textMed),
                    onPressed: () async {
                      await ref.read(notificationsRepositoryProvider).markAllRead();
                      ref.invalidate(notificationsInboxProvider);
                    },
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          inboxAsync.maybeWhen(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: t(ref, 'clearAll'),
                    icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFDC2626)),
                    onPressed: () => _handleClearAll(context, ref),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary700,
        backgroundColor: context.cardFill,
        onRefresh: () async => ref.invalidate(notificationsInboxProvider),
        child: inboxAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary700)),
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: ErrorRetryView(
                  message: t(ref, 'failedToLoadNotifications'),
                  onRetry: () => ref.invalidate(notificationsInboxProvider),
                ),
              ),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.75,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 220,
                              height: 220,
                              child: Lottie.asset(
                                'assets/animations/Notifications.json',
                                fit: BoxFit.contain,
                                frameRate: const FrameRate(30),
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.notifications_off_rounded,
                                  size: 56,
                                  color: context.textLow,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t(ref, 'noNewNotifications'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: context.textHigh,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t(ref, 'noNewNotificationsHint'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.publicSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.textMed,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _NotificationCard(
                item: items[index],
                onTap: () => _handleTap(ref, items[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _categoryStyles[item.category] ?? _defaultCategoryStyle;
    final unread = item.isUnread;

    return Material(
      color: unread ? style.color.withValues(alpha: context.isDark ? 0.12 : 0.06) : context.cardFill,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: unread ? style.color.withValues(alpha: 0.25) : context.borderFill),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: context.isDark ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.publicSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: context.textHigh,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(left: 8, top: 4),
                            decoration: BoxDecoration(color: style.color, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.publicSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: context.textMed,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Consumer(
                      builder: (context, ref, _) => Text(
                        _timeAgo(ref, item.sentAt),
                        style: GoogleFonts.publicSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: context.textLow,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
