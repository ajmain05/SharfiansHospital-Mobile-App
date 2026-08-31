import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/adaptive_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../models/event.dart';
import '../providers/events_providers.dart';
import '../widgets/event_status_badge.dart';

const _royalBlue = Color(0xFF316BF3);

class EventDetailScreen extends ConsumerWidget {
  final String slug;

  const EventDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventBySlugProvider(slug));

    return Scaffold(
      backgroundColor: context.bgFill,
      appBar: AppBar(
        backgroundColor: context.cardFill,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: context.borderFill, width: 1)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textHigh),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          t(ref, 'eventDetails'),
          style: GoogleFonts.libreCaslonText(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: context.textHigh,
          ),
        ),
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
    // isCompleted (the event's own date has passed) is checked separately
    // from isDeadlinePassed — a deadline that's missing, or (as can happen
    // from a data-entry mistake) set later than the event's own date, would
    // otherwise leave registration looking open for an event that's already
    // happened.
    final canRegister = event.isActive &&
        !event.isCompleted &&
        !event.isDeadlinePassed &&
        !event.isCapacityFull;
    // Check Status stays useful right up until the event itself has
    // happened (you may have registered before the deadline/capacity closed
    // it) — only "Completed" retires the whole bar. Register Now is still
    // gated on canRegister alone within the bar.
    final showBottomBar = !event.isCompleted;

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 768;
            
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 40 : 16,
                isDesktop ? 40 : 16,
                isDesktop ? 40 : 16,
                showBottomBar ? 100 : 40,
              ),
              children: [
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildLeftColumn(context, ref),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 2,
                        child: _buildRightColumn(context, ref),
                      ),
                    ],
                  )
                else ...[
                  _buildLeftColumn(context, ref),
                  const SizedBox(height: 32),
                  _buildRightColumn(context, ref),
                ]
              ],
            );
          }
        ),
        if (showBottomBar)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomActionBar(event: event, canRegister: canRegister),
          ),
      ],
    );
  }

  Widget _buildLeftColumn(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (event.imageUrl != null && event.imageUrl!.isNotEmpty) ...[
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderFill),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 450),
              child: CachedNetworkImage(
                imageUrl: event.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: context.cardFill2, height: 200),
                errorWidget: (_, _, _) => Container(color: context.cardFill2, height: 200),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        Text(
          event.title,
          style: GoogleFonts.hindSiliguri(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: context.textHigh,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        // Without Align, this stretches to the full width of the parent
        // Column (crossAxisAlignment.stretch, for the title/description text
        // above and below) — the badge's own Row sizes itself to just its
        // icon+label, leaving a large empty pill behind it.
        Align(
          alignment: Alignment.centerLeft,
          child: EventStatusBadge(event: event),
        ),
        const SizedBox(height: 16),
        if (event.description != null && event.description!.trim().isNotEmpty) ...[
          Builder(
            builder: (context) {
              final cleanDesc = event.description!
                  .split('\n')
                  .where((line) => !line.contains('ডিনারের আয়োজন') && !line.contains('ডিনারের আয়োজন') && !line.contains('🍽️'))
                  .join('\n')
                  .trim();
              if (cleanDesc.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    cleanDesc,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 15,
                      color: context.textHigh,
                      height: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ],
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardFill2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.borderFill),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.restaurant, color: context.textMed, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'সভা শেষে সম্মানিত শেয়ারহোল্ডারদের জন্য রাতের ডিনারের আয়োজন থাকবে।',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.textHigh,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        _MetaInfoGrid(event: event),
      ],
    );
  }

  Widget _buildRightColumn(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RegistrationStats(event: event),
        const SizedBox(height: 24),
        if (event.offlineNotice != null && event.offlineNotice!.trim().isNotEmpty) ...[
          _WarningBanner(text: event.offlineNotice!),
          const SizedBox(height: 24),
        ],
        if (event.paymentConfig.isNotEmpty || event.branches.isNotEmpty)
          _PaymentInfoCard(event: event),
      ],
    );
  }
}

class _MetaInfoGrid extends ConsumerWidget {
  final Event event;

  const _MetaInfoGrid({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The backend stores/sends these as UTC ('Z'-suffixed) ISO strings —
    // DateTime.parse keeps them UTC, so formatting without .toLocal() first
    // prints the UTC wall-clock hour verbatim instead of the device's local
    // (Bangladesh) time, e.g. an admin-entered 6:00 PM showing as 12:00 PM.
    final date = DateTime.tryParse(event.date)?.toLocal();
    final dateLabel = date != null
        ? DateFormat('MMM d, yyyy · h:mm a').format(date)
        : event.date;

    final deadline = event.registrationDeadline != null
        ? DateTime.tryParse(event.registrationDeadline!)?.toLocal()
        : null;
    final deadlineLabel = deadline != null
        ? DateFormat('MMM d, yyyy · h:mm a').format(deadline)
        : event.registrationDeadline;

    final items = [
      _buildItem(context, 'Date & Time', dateLabel, Icons.calendar_month),
      _buildItem(context, 'Registration Fee', '${Formatters.bdt(event.feePerPerson)} / person', Icons.payments),
      if (deadlineLabel != null)
        _buildItem(context, 'Deadline', deadlineLabel, Icons.schedule),
      _buildItem(context, 'Location', event.location, Icons.location_on),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _royalBlue.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: _royalBlue.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1) const SizedBox(height: 12),
          ]
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardFill2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderFill),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _royalBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _royalBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.publicSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: context.textMed,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.textHigh,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrationStats extends ConsumerWidget {
  final Event event;

  const _RegistrationStats({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget buildRow(String totalSeats, String seatsLeft) {
      return Row(
        children: [
          Expanded(child: _buildStatCard(context, 'Total Seats', totalSeats, true)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard(context, 'Seats Left', seatsLeft, false)),
        ],
      );
    }

    final maxCap = event.maxCapacity ?? 1000;
    final seatsLeft = event.remainingSeats ?? 849;
    return buildRow(
      maxCap.toString(),
      seatsLeft.toString(),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, bool isBlue) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _royalBlue.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: _royalBlue.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isBlue ? _royalBlue : context.textHigh.withOpacity(0.2),
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Column(
            children: [
              Text(
                value,
                style: GoogleFonts.publicSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isBlue ? _royalBlue : context.textHigh,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.publicSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: context.textMed,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String text;

  const _WarningBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardFill2,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _royalBlue.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: _royalBlue, width: 4),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.campaign, color: _royalBlue),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 14,
                    color: context.textHigh,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentInfoCard extends ConsumerWidget {
  final Event event;

  const _PaymentInfoCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pc = event.paymentConfig;
    final methods = EventPaymentMethod.fromPaymentConfig(pc)
        .where((m) => m.number != null)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pc['bankName'] != null || pc['bankAccount'] != null) ...[
          _buildBankCard(context, pc),
          const SizedBox(height: 24),
        ],
        if (methods.isNotEmpty) ...[
          _buildMobileBankingCard(context, methods),
          const SizedBox(height: 24),
        ],
        if (event.branches.isNotEmpty) ...[
          _buildBranchesCard(context, event.branches),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildCardBase({required BuildContext context, required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _royalBlue.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: _royalBlue.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: _royalBlue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.publicSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard(BuildContext context, Map<String, dynamic> pc) {
    return _buildCardBase(
      context: context,
      title: 'Bank Details',
      icon: Icons.account_balance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pc['bankName']?.toString() ?? 'Bank Account',
            style: GoogleFonts.publicSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textHigh,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 48,
            decoration: BoxDecoration(
              color: _royalBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          if (pc['bankAccount'] != null)
            _buildBankField(context, 'Account Number', pc['bankAccount'].toString()),
          if (pc['bankRouting'] != null) ...[
            const SizedBox(height: 16),
            _buildBankField(context, 'Routing Number', pc['bankRouting'].toString()),
          ],
        ],
      ),
    );
  }

  Widget _buildBankField(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardFill2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderFill),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.publicSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: context.textMed,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.publicSans(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: context.textHigh,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBankingCard(BuildContext context, List<EventPaymentMethod> methods) {
    return _buildCardBase(
      context: context,
      title: 'Mobile Banking',
      icon: Icons.smartphone,
      child: Column(
        children: methods.map((m) {
          final isMerchant = m.id.toLowerCase().contains('merchant');
          final badgeColor = m.id.toLowerCase().contains('bkash')
              ? (isMerchant ? const Color(0xFFD12053) : _royalBlue)
              : const Color(0xFFF7941D);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            m.label,
                            style: GoogleFonts.publicSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.textHigh,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isMerchant ? 'MERCHANT' : 'PERSONAL',
                              style: GoogleFonts.publicSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m.number!,
                        style: GoogleFonts.publicSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: context.textHigh,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.content_copy, color: context.textMed, size: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBranchesCard(BuildContext context, List<dynamic> branches) {
    return _buildCardBase(
      context: context,
      title: 'Institutional Locations',
      icon: Icons.corporate_fare,
      child: Column(
        children: [
          for (var i = 0; i < branches.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: context.borderFill),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: _royalBlue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branches[i]['name']?.toString() ?? '',
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.textHigh,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (branches[i]['address'] != null)
                        Text(
                          branches[i]['address'].toString(),
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textHigh,
                            height: 1.5,
                          ),
                        ),
                      if (branches[i]['phone'] != null) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            final rawPhone = branches[i]['phone'].toString();
                            final cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
                            final phoneUri = Uri(scheme: 'tel', path: cleanPhone);
                            try {
                              final launched = await launchUrl(phoneUri);
                              if (!launched && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('আপনার ডিভাইসে (বা সিমুলেটরে) কল করা যাচ্ছে না!')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('আপনার ডিভাইসে (বা সিমুলেটরে) কল করা যাচ্ছে না!')),
                                );
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.call, color: _royalBlue, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  branches[i]['phone'].toString(),
                                  style: GoogleFonts.publicSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _royalBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// Built whenever the event isn't Completed yet (see `showBottomBar` in
// _EventDetailBody) — Check Status stays useful through both "open" and
// "registration closed but event hasn't happened yet" states, so it always
// renders here; Register Now only renders alongside it while canRegister.
class _BottomActionBar extends ConsumerWidget {
  final Event event;
  final bool canRegister;

  const _BottomActionBar({required this.event, required this.canRegister});

  void _goToCheckStatus(BuildContext context) {
    context.push(
      Uri(
        path: '/events/check',
        queryParameters: {'eventId': event.id, 'eventTitle': event.title},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkStatusButton = ElevatedButton.icon(
      onPressed: () => _goToCheckStatus(context),
      icon: const Icon(Icons.fact_check_outlined, size: 20),
      label: Text(
        t(ref, 'checkStatus'),
        style: GoogleFonts.publicSans(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _royalBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    );

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: context.cardFill.withOpacity(0.9),
        border: Border(
          top: BorderSide(color: context.borderFill),
        ),
      ),
      child: canRegister
          ? Row(
              children: [
                Expanded(child: checkStatusButton),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/events/${event.slug}/register'),
                    icon: const Icon(Icons.how_to_reg, size: 20),
                    label: Text(
                      t(ref, 'registerNow'),
                      style: GoogleFonts.publicSans(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _royalBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            )
          : checkStatusButton,
    );
  }
}
