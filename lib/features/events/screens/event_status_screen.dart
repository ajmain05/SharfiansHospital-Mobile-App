import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/adaptive_colors.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../providers/events_providers.dart';

class EventStatusScreen extends ConsumerWidget {
  final String token;

  const EventStatusScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(eventStatusProvider(token));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/events'),
        ),
        title: Text(t(ref, 'yourTicket')),
      ),
      body: statusAsync.when(
        data: (reg) {
          final cfg = _statusConfig(ref, reg.status);
          // Stored/sent as a UTC ('Z'-suffixed) ISO string — .toLocal()
          // converts to the device's local (Bangladesh) time before
          // formatting, otherwise the UTC wall-clock hour prints verbatim
          // (e.g. 6 PM admin input showing as noon).
          final date = reg.eventDate != null
              ? DateTime.tryParse(reg.eventDate!)?.toLocal()
              : null;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: cfg.bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${cfg.emoji} ${cfg.label}',
                            style: TextStyle(
                              color: cfg.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          reg.eventTitle ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (date != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, yyyy · h:mm a').format(date),
                            style: TextStyle(
                              color: context.textHigh,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        if (reg.eventLocation != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            reg.eventLocation!,
                            style: TextStyle(
                              color: context.textHigh,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Text(
                          cfg.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.textHigh,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (reg.status == 'APPROVED' && reg.qrCodeToken != null)
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: QrImageView(
                              data:
                                  'https://sharfianshospital.com/events/status/${reg.qrCodeToken}',
                              size: 200,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _infoBlock(
                              t(ref, 'numberOfPersons'),
                              '${reg.personsCount}',
                            ),
                            _infoBlock(
                              t(ref, 'amount'),
                              Formatters.bdt(reg.totalAmount),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorRetryView(
          message: t(ref, 'notFound'),
          onRetry: () => ref.invalidate(eventStatusProvider(token)),
        ),
      ),
    );
  }

  Widget _infoBlock(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  ({String emoji, String label, Color color, Color bg, String message})
  _statusConfig(WidgetRef ref, String status) {
    switch (status) {
      case 'APPROVED':
        return (
          emoji: '✅',
          label: t(ref, 'statusApproved'),
          color: const Color(0xFF0E9E6F),
          bg: const Color(0xFFE5F8F0),
          message: t(ref, 'statusApprovedMsg'),
        );
      case 'REJECTED':
        return (
          emoji: '❌',
          label: t(ref, 'statusRejected'),
          color: const Color(0xFFDC2626),
          bg: const Color(0xFFFEF2F2),
          message: t(ref, 'statusRejectedMsg'),
        );
      default:
        return (
          emoji: '⏳',
          label: t(ref, 'statusPending'),
          color: const Color(0xFFB45309),
          bg: const Color(0xFFFEF3C7),
          message: t(ref, 'statusPendingMsg'),
        );
    }
  }
}
