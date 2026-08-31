import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../models/event.dart';

/// Shown instead of silently hiding the register button/blocking the whole
/// page once an event can no longer be registered for — keeps the event's
/// own info (date, location, description) visible either way, just labels
/// why registration isn't open right now. Renders nothing while
/// registration is still open.
class EventStatusBadge extends ConsumerWidget {
  final Event event;

  const EventStatusBadge({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? label;
    final Color color;
    final IconData icon;

    if (event.isCompleted) {
      label = t(ref, 'eventCompleted');
      color = const Color(0xFF64748B);
      icon = Icons.check_circle_rounded;
    } else if (!event.isActive || event.isDeadlinePassed || event.isCapacityFull) {
      label = t(ref, 'eventRegistrationClosed');
      color = const Color(0xFFB45309);
      icon = Icons.lock_clock_rounded;
    } else {
      label = null;
      color = Colors.transparent;
      icon = Icons.circle;
    }

    if (label == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.publicSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
