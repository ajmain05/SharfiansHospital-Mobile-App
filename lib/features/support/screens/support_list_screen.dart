import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/adaptive_colors.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../models/support_ticket.dart';
import '../providers/support_provider.dart';

// Categories are admin-editable (web dashboard's Settings → Support Query
// Categories) as of when this ticket's category was picked — prefer whatever
// the live list currently says for that id (an admin may have since renamed
// it), and only fall back to the bundled translation for the original 7
// default ids while that fetch is still loading/has failed, or if the id has
// since been removed from the admin-configured list entirely.
String supportCategoryLabel(WidgetRef ref, String category) {
  final live = ref.watch(supportCategoriesProvider).maybeWhen(
        data: (list) {
          final matches = list.where((c) => c.id == category);
          return matches.isEmpty ? null : matches.first.label;
        },
        orElse: () => null,
      );
  if (live != null) return live;

  switch (category) {
    case 'payment':
      return t(ref, 'supportCategoryPayment');
    case 'share_certificate':
      return t(ref, 'supportCategoryShareCertificate');
    case 'account_update':
      return t(ref, 'supportCategoryAccountUpdate');
    case 'technical':
      return t(ref, 'supportCategoryTechnical');
    case 'complaint':
      return t(ref, 'supportCategoryComplaint');
    case 'general':
      return t(ref, 'supportCategoryGeneral');
    default:
      return t(ref, 'supportCategoryOther');
  }
}

String supportStatusLabel(WidgetRef ref, String status) {
  switch (status) {
    case 'OPEN':
      return t(ref, 'supportStatusOpen');
    case 'IN_PROGRESS':
      return t(ref, 'supportStatusInProgress');
    case 'RESOLVED':
      return t(ref, 'supportStatusResolved');
    default:
      return t(ref, 'supportStatusClosed');
  }
}

Color supportStatusColor(String status) {
  switch (status) {
    case 'OPEN':
      return const Color(0xFFDC2626);
    case 'IN_PROGRESS':
      return const Color(0xFFD97706);
    case 'RESOLVED':
      return const Color(0xFF16A34A);
    default:
      return const Color(0xFF6B7280);
  }
}

class SupportListScreen extends ConsumerWidget {
  const SupportListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(supportTicketsProvider);

    return Scaffold(
      backgroundColor: context.bgFill,
      appBar: AppBar(
        backgroundColor: context.cardFill,
        elevation: 0,
        leading: BackButton(color: context.textHigh, onPressed: () => context.pop()),
        title: Text(
          t(ref, 'myQueries'),
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: context.textHigh),
        ),
        actions: [
          IconButton(
            tooltip: t(ref, 'newQuery'),
            icon: Icon(Icons.add_rounded, color: AppColors.primary700),
            onPressed: () => context.push('/support/new'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary700,
        backgroundColor: context.cardFill,
        onRefresh: () async => ref.invalidate(supportTicketsProvider),
        child: ticketsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary700)),
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: ErrorRetryView(
                  message: t(ref, 'supportFailedToLoad'),
                  onRetry: () => ref.invalidate(supportTicketsProvider),
                ),
              ),
            ],
          ),
          data: (tickets) {
            if (tickets.isEmpty) {
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
                                'assets/animations/support.json',
                                fit: BoxFit.contain,
                                frameRate: const FrameRate(30),
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.support_agent_rounded,
                                  size: 64,
                                  color: context.textLow,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t(ref, 'supportNoQueriesYet'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: context.textHigh),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t(ref, 'supportNoQueriesHint'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.w600, color: context.textMed, height: 1.4),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () => context.push('/support/new'),
                              icon: const Icon(Icons.add_rounded),
                              label: Text(t(ref, 'newQuery'), style: GoogleFonts.publicSans(fontWeight: FontWeight.w700)),
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
              itemCount: tickets.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _TicketCard(
                ticket: tickets[index],
                onTap: () => context.push('/support/thread/${tickets[index].id}'),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TicketCard extends ConsumerWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ticket.hasUnreadReply;
    final statusColor = supportStatusColor(ticket.status);

    return Material(
      color: unread ? statusColor.withValues(alpha: context.isDark ? 0.12 : 0.06) : context.cardFill,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: unread ? statusColor.withValues(alpha: 0.25) : context.borderFill),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject?.trim().isNotEmpty == true ? ticket.subject! : supportCategoryLabel(ref, ticket.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.publicSans(fontSize: 15, fontWeight: FontWeight.w800, color: context.textHigh),
                    ),
                  ),
                  if (unread)
                    Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(left: 8, top: 4),
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      supportStatusLabel(ref, ticket.status),
                      style: GoogleFonts.publicSans(fontSize: 11, fontWeight: FontWeight.w800, color: statusColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      supportCategoryLabel(ref, ticket.category),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.publicSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.textMed),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
