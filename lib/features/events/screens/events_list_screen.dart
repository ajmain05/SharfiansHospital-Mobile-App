import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/adaptive_colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          t(ref, 'events'),
          style: GoogleFonts.libreCaslonText(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF191C1E),
          ),
        ),
        // Moved out of `actions` — a wide icon+label button there fought the
        // centered title for space on one side only, so the title never
        // actually looked centered despite `centerTitle: true`.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      // Check Status is per-event now (each event's own detail page), not a
      // single global lookup here — see event_detail_screen.dart's bottom
      // action bar.
      body: _EventsListBody(eventsAsync: eventsAsync, isDark: isDark, ref: ref),
    );
  }
}

class _EventsListBody extends StatelessWidget {
  final AsyncValue<List<Event>> eventsAsync;
  final bool isDark;
  final WidgetRef ref;

  const _EventsListBody({required this.eventsAsync, required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF316BF3),
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
                        Icon(
                          Icons.event_busy_outlined,
                          size: 48,
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t(ref, 'noEvents'),
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                            fontFamily: 'Inter',
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 20),
            itemBuilder: (context, i) => _EventCard(event: events[i]),
          );
        },
        loading: () => const ShimmerLoader(),
        error: (err, stack) => ErrorRetryView(
          onRetry: () => ref.invalidate(publicEventsProvider),
        ),
      ),
    );
  }
}

class _EventCard extends ConsumerWidget {
  final Event event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Stored/sent as a UTC ('Z'-suffixed) ISO string — .toLocal() converts to
    // the device's local (Bangladesh) time before formatting, otherwise the
    // UTC wall-clock hour prints verbatim (e.g. 6 PM admin input showing as
    // noon).
    final date = DateTime.tryParse(event.date)?.toLocal();
    final dateLabel = date != null
        ? DateFormat('MMM d, yyyy · h:mm a').format(date)
        : event.date;

    final hasImage = event.imageUrl != null && event.imageUrl!.isNotEmpty;
    final placeholderColor = isDark ? const Color(0xFF334155) : const Color(0xFFECEEF0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/events/${event.slug}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 2,
                child: hasImage
                    ? CachedNetworkImage(
                        imageUrl: event.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(color: placeholderColor),
                        errorWidget: (_, _, _) => Container(color: placeholderColor),
                      )
                    : Container(
                        color: placeholderColor,
                        child: Icon(
                          Icons.event_outlined,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          size: 40,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: isDark ? Colors.white : const Color(0xFF191C1E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusChip(context, ref, event),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _compactMetaRow(
                      context: context,
                      icon: Icons.calendar_today_outlined,
                      text: dateLabel,
                    ),
                    const SizedBox(height: 8),
                    _compactMetaRow(
                      context: context,
                      icon: Icons.location_on_outlined,
                      text: event.location,
                    ),
                    const SizedBox(height: 8),
                    _compactMetaRow(
                      context: context,
                      icon: Icons.credit_card_outlined,
                      text: event.feePerPerson > 0
                          ? '${Formatters.bdt(event.feePerPerson)} / person'
                          : 'Free',
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

  // Beside the title rather than its own row below the meta list — an
  // explicit "Open" state too (not just the closed/completed cases), so
  // scanning the list actually tells you what's currently registerable
  // instead of "no badge" silently meaning that. Solid fill (not a pale
  // tint) so it actually stands out next to the title.
  Widget _statusChip(BuildContext context, WidgetRef ref, Event event) {
    final (label, color) = event.isCompleted
        ? (t(ref, 'eventCompleted'), const Color(0xFF64748B))
        : (!event.isActive || event.isDeadlinePassed || event.isCapacityFull)
            ? (t(ref, 'eventClosedShort'), const Color(0xFFB45309))
            : (t(ref, 'eventRegistrationOpen'), const Color(0xFF15803D));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.publicSans(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _compactMetaRow({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF316BF3),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.hindSiliguri(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF45464D),
            ),
          ),
        ),
      ],
    );
  }
}
