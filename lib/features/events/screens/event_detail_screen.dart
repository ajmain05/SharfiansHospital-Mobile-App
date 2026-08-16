import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../models/event.dart';
import '../providers/events_providers.dart';

class EventDetailScreen extends ConsumerWidget {
  final String slug;

  const EventDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventBySlugProvider(slug));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(t(ref, 'eventDetails')),
      ),
      body: eventAsync.when(
        data: (event) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(eventBySlugProvider(slug));
            ref.invalidate(liveSnapshotProvider(event.id));
          },
          child: _EventDetailBody(event: event),
        ),
        loading: () => const ShimmerLoader(),
        error: (err, stack) => ErrorRetryView(
          message: t(ref, 'eventNotFound'),
          onRetry: () => ref.invalidate(eventBySlugProvider(slug)),
        ),
      ),
    );
  }
}

class _EventDetailBody extends ConsumerWidget {
  final Event event;

  const _EventDetailBody({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = DateTime.tryParse(event.date);
    final dateLabel = date != null
        ? DateFormat('MMM d, yyyy · h:mm a').format(date)
        : event.date;
    final canRegister =
        event.isActive && !event.isDeadlinePassed && !event.isCapacityFull;
    final snapshotAsync = ref.watch(liveSnapshotProvider(event.id));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: event.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppColors.surface2),
                    errorWidget: (_, _, _) =>
                        Container(color: AppColors.surface2),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    if (event.description != null &&
                        event.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        event.description!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _meta(Icons.calendar_today_outlined, dateLabel),
                    const SizedBox(height: 8),
                    _meta(Icons.location_on_outlined, event.location),
                    const SizedBox(height: 8),
                    _meta(
                      Icons.payments_outlined,
                      '${Formatters.bdt(event.feePerPerson)} / person',
                    ),
                    if (event.registrationDeadline != null) ...[
                      const SizedBox(height: 8),
                      _meta(
                        Icons.timer_outlined,
                        '${t(ref, 'deadline')}: ${event.registrationDeadline}',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        snapshotAsync.maybeWhen(
          data: (s) => _LiveCounter(snapshot: s),
          loading: () => const LinearProgressIndicator(minHeight: 3),
          orElse: () => _CapacityCounter(event: event),
        ),
        if (event.offlineNotice != null &&
            event.offlineNotice!.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              event.offlineNotice!,
              style: const TextStyle(color: Color(0xFF9A3412), fontSize: 13),
            ),
          ),
        ],
        const SizedBox(height: 22),
        ElevatedButton.icon(
          onPressed: canRegister
              ? () => context.push('/events/${event.slug}/register')
              : null,
          icon: const Icon(Icons.app_registration_rounded),
          label: Text(canRegister ? t(ref, 'registerNow') : _closedLabel(ref)),
        ),
      ],
    );
  }

  String _closedLabel(WidgetRef ref) {
    if (!event.isActive) return t(ref, 'registrationClosed');
    if (event.isDeadlinePassed) return t(ref, 'deadlinePassed');
    return t(ref, 'capacityFull');
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveCounter extends ConsumerWidget {
  final EventLiveSnapshot snapshot;

  const _LiveCounter({required this.snapshot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _stat(
                t(ref, 'registered'),
                snapshot.totalRegistrations.toString(),
                AppColors.primary600,
              ),
            ),
            Expanded(
              child: _stat(
                t(ref, 'confirmed'),
                snapshot.confirmedRegistrations.toString(),
                AppColors.accent600,
              ),
            ),
            Expanded(
              child: _stat(
                t(ref, 'seatsLeft'),
                (snapshot.remainingSeats ?? 0).toString(),
                const Color(0xFFB45309),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CapacityCounter extends ConsumerWidget {
  final Event event;

  const _CapacityCounter({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (event.maxCapacity == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                t(ref, 'seatsLeft'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${event.remainingSeats} / ${event.maxCapacity}',
              style: const TextStyle(
                color: AppColors.primary600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
