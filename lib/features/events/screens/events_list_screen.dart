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

class EventsListScreen extends ConsumerWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(publicEventsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(t(ref, 'events')),
        actions: [
          IconButton(
            icon: const Icon(Icons.confirmation_number_outlined),
            tooltip: t(ref, 'checkStatus'),
            onPressed: () => context.push('/events/check'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(publicEventsProvider),
        child: eventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 120),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.event_busy_outlined,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t(ref, 'noEvents'),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, i) => _EventCard(event: events[i]),
            );
          },
          loading: () => const ShimmerLoader(),
          error: (err, stack) => ErrorRetryView(
            onRetry: () => ref.invalidate(publicEventsProvider),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(event.date);
    final dateLabel = date != null
        ? DateFormat('MMM d, yyyy · h:mm a').format(date)
        : event.date;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/events/${event.slug}'),
      child: Card(
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _metaRow(Icons.calendar_today_outlined, dateLabel),
                  const SizedBox(height: 4),
                  _metaRow(Icons.location_on_outlined, event.location),
                  const SizedBox(height: 4),
                  _metaRow(
                    Icons.payments_outlined,
                    '${Formatters.bdt(event.feePerPerson)} / person',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
