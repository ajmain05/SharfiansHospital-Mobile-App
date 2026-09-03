import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/adaptive_colors.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../core/widgets/language_toggle_button.dart';
import '../../../core/widgets/theme_toggle_button.dart';
import '../../../models/site_settings.dart';
import '../../investor_auth/providers/investor_session_provider.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../settings/providers/site_settings_provider.dart';
import '../../settings/screens/settings_screen.dart';
import '../providers/public_stats_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(siteSettingsProvider);
    final publicStatsAsync = ref.watch(publicStatsProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final loggedIn = ref.watch(investorSessionProvider).isLoggedIn;

    return Scaffold(
      backgroundColor: context.bgFill,
      body: RefreshIndicator(
        color: const Color(0xFF316BF3),
        backgroundColor: context.cardFill,
        onRefresh: () async {
          ref.invalidate(siteSettingsProvider);
          ref.invalidate(publicStatsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Hero ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _HeroSection(
                settingsAsync: settingsAsync,
                lang: lang,
                loggedIn: loggedIn,
                ref: ref,
                onNavigate: (p) => context.push(p),
                onEventsTab: () => context.push('/events'),
              ),
            ),

            // ── Quick Access Row ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _QuickAccessRow(
                ref: ref,
                loggedIn: loggedIn,
                onPortal: () => loggedIn
                    ? context.go('/investor/dashboard')
                    : context.push('/investor/login'),
                onEvents: () => context.push('/events'),
                onBankDetails: () => context.push('/bank-details'),
              ),
            ),

            // ── Impact Stats ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: publicStatsAsync.when(
                data: (stats) => _ImpactSection(
                  stats: stats,
                  settingsAsync: settingsAsync,
                  lang: lang,
                  ref: ref,
                ),
                loading: () => _StatsShimmer(),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: ErrorRetryView(onRetry: () => ref.invalidate(publicStatsProvider)),
                ),
              ),
            ),

            // ── Explore Grid ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _ExploreSection(
                ref: ref,
                onNavigate: (p) => context.push(p),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HERO SECTION
// ══════════════════════════════════════════════════════════════════════════════
class _HeroSection extends StatelessWidget {
  final AsyncValue<SiteSettings> settingsAsync;
  final String lang;
  final bool loggedIn;
  final WidgetRef ref;
  final void Function(String) onNavigate;
  final VoidCallback onEventsTab;

  const _HeroSection({
    required this.settingsAsync,
    required this.lang,
    required this.loggedIn,
    required this.ref,
    required this.onNavigate,
    required this.onEventsTab,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
            ),
          ),
        ),

        // Decorative circles removed to keep UI clean

        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Controls row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _NotificationBellButton(onTap: () => onNavigate('/notifications')),
                  ],
                ),
                const SizedBox(height: 8),
                // Lottie Illustration
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow effect specifically for dark mode so the Lottie icons stay visible
                    if (Theme.of(context).brightness == Brightness.dark)
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.white.withValues(alpha: 0.12), blurRadius: 80, spreadRadius: 40),
                          ],
                        ),
                      ),
                    Center(
                      child: Lottie.asset(
                        'assets/animations/hero_bg.json',
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                        frameRate: const FrameRate(30),
                        errorBuilder: (context, error, stackTrace) => const SizedBox(height: 0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Center(
                  child: Text(
                    settingsAsync.maybeWhen(
                      data: (s) => lang == 'bn' ? s.heroTitleBn : s.heroTitle,
                      orElse: () => t(ref, 'heroTitle'),
                    ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E3A8A),
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.2),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Center(
                  child: Text(
                    settingsAsync.maybeWhen(
                      data: (s) => lang == 'bn' ? s.heroSubtitleBn : s.heroSubtitle,
                      orElse: () => t(ref, 'heroSubtitle'),
                    ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E40AF),
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 16),

                // New "Anyone can invest" text
                Center(
                  child: Text(
                    lang == 'bn' ? 'যে কেউ বিনিয়োগ করতে পারে, শুধুমাত্র প্রাক্তন ছাত্রদের মধ্যে সীমাবদ্ধ নয়' : 'Anyone can invest, not limited to alumni',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // CTA row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _HeroCTA(
                    icon: Icons.volunteer_activism_rounded,
                    title: t(ref, 'becomeInvestor'),
                    gradient: const LinearGradient(colors: [Color(0xFFEAB308), Color(0xFFF59E0B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shadow: true,
                    onTap: () => onNavigate('/register'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _circle(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}

class _NotificationBellButton extends ConsumerWidget {
  final VoidCallback onTap;

  const _NotificationBellButton({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final hasUnread = unreadCount > 0;
    final dark = context.isDark;

    // The unread badge deliberately sits in the corner, just outside the
    // bell circle. It must NOT be a descendant of the Material below —
    // Material's own shape:CircleBorder + clipBehavior:antiAlias clips its
    // whole subtree to the inscribed circle (that's what keeps the ink
    // ripple round), and a corner sits outside that circle, so the badge
    // was getting silently sliced by its own container's ripple clip.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF316BF3).withValues(alpha: dark ? 0.25 : 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  color: const Color(0xFF316BF3),
                  size: 21,
                ),
              ),
            ),
          ),
        ),
        if (hasUnread)
          Positioned(
            top: 2,
            right: 2,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: context.bgFill, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFDC2626).withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroCTA extends StatelessWidget {
  final IconData icon;
  final String title;
  final LinearGradient gradient;
  final Color? borderColor;
  final Color? textColor;
  final Color? iconColor;
  final bool shadow;
  final VoidCallback onTap;

  const _HeroCTA({
    required this.icon,
    required this.title,
    required this.gradient,
    required this.onTap,
    this.borderColor,
    this.textColor,
    this.iconColor,
    this.shadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: shadow ? context.cardShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6), // reduced horizontal padding
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              border: borderColor != null ? Border.all(color: borderColor!, width: 1.5) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor ?? Colors.white, size: 16),
                const SizedBox(width: 4), // reduced gap
                Flexible(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(color: textColor ?? Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height - 28);
    path.quadraticBezierTo(size.width * 0.75, size.height - 56, size.width, size.height - 16);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
// QUICK ACCESS ROW (new — prominent, just below hero)
// ══════════════════════════════════════════════════════════════════════════════
class _QuickAccessRow extends StatelessWidget {
  final WidgetRef ref;
  final bool loggedIn;
  final VoidCallback onPortal;
  final VoidCallback onEvents;
  final VoidCallback onBankDetails;

  const _QuickAccessRow({
    required this.ref,
    required this.loggedIn,
    required this.onPortal,
    required this.onEvents,
    required this.onBankDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0), // Reduced top padding to close gap with hero
      child: Row(
        children: [
          _QuickChip(
            icon: Icons.event_rounded,
            label: t(ref, 'events'),
            color: AppColors.teal600,
            onTap: onEvents,
          ),
          const SizedBox(width: 10),
          _QuickChip(
            icon: loggedIn ? Icons.dashboard_rounded : Icons.login_rounded,
            label: loggedIn ? t(ref, 'myPortal') : t(ref, 'login'),
            color: AppColors.primary700,
            onTap: onPortal,
          ),
          const SizedBox(width: 10),
          _QuickChip(
            icon: Icons.account_balance_rounded,
            label: t(ref, 'bankDetails'),
            color: AppColors.accent600,
            onTap: onBankDetails,
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickChip({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: context.cardFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderFill),
              boxShadow: context.cardShadow,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 4), // Reduced gap
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: context.textHigh),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// IMPACT STATS
// ══════════════════════════════════════════════════════════════════════════════
class _ImpactSection extends StatelessWidget {
  final Map<String, dynamic> stats;
  final AsyncValue<SiteSettings> settingsAsync;
  final String lang;
  final WidgetRef ref;

  const _ImpactSection({required this.stats, required this.settingsAsync, required this.lang, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isBn = lang == 'bn';
    final section = settingsAsync.maybeWhen(data: (s) => s.investorStatsSection, orElse: () => null);
    final investmentTarget = settingsAsync.maybeWhen(
      data: (s) => s.investmentTarget.toDouble(),
      orElse: () => 1000000000.0,
    );

    final totalInvestors    = (stats['totalInvestors']    as num?) ?? 0;
    final totalAmount       = (stats['totalAmount']       as num?) ?? 0;
    final confirmedInv      = (stats['confirmedInvestors'] as num?) ?? 0;
    final confirmedTarget   = (stats['confirmedTarget']    as num?) ?? 0;

    final targetCr    = investmentTarget / 10000000;
    final progressPct = (confirmedTarget.toDouble() / investmentTarget).clamp(0.0, 1.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: section != null ? (isBn ? section.titleBn : section.title) : t(ref, 'growingTogether'),
            subtitle: isBn ? 'আমাদের অর্জন একসাথে' : 'Our collective achievement',
          ),
          const SizedBox(height: 12),

          // ── Notice to Unconfirmed Investors ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF3B82F6) : const Color(0xFFBFDBFE),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF316BF3).withValues(alpha: isDark ? 0.2 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF316BF3).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: Color(0xFF316BF3),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isBn ? 'জরুরী বিজ্ঞপ্তি' : 'Important Notice',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF316BF3).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF316BF3).withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isBn ? 'মনোযোগ দিন' : 'Attention',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isBn
                      ? 'সকল ${Formatters.number(totalInvestors)} জন নিবন্ধিত বিনিয়োগকারীর দৃষ্টি আকর্ষণ করছি: যদি কেউ এখনো কোনো পরিমাণ জমা না দিয়ে থাকেন, তবে অনুগ্রহ করে অন্তত সর্বনিম্ন একটি পরিমাণ জমা দিয়ে "নিশ্চিত বিনিয়োগকারী" হিসেবে নিজেকে তালিকাভুক্ত করুন।'
                      : 'Attention to all ${Formatters.number(totalInvestors)} registered investors: If you haven\'t deposited any amount yet, please confirm your registration as a "Confirmed Investor" by making at least a minimum deposit.',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Impact Cards Row ────────────────────────────────────────────
          Row(
            children: [
              // Total Investors card
              Expanded(
                child: _ImpactCard(
                  gradient: AppColors.cardGradientGreen,
                  icon: Icons.groups_rounded,
                  value: Formatters.number(totalInvestors),
                  label: section != null ? (isBn ? section.investorLabelBn : section.investorLabel) : t(ref, 'totalInvestors'),
                  confirmedValue: confirmedInv > 0 ? Formatters.number(confirmedInv) : null,
                  confirmedLabel: isBn ? 'নিশ্চিত' : 'Confirmed',
                  confirmedSub: isBn ? '(পূর্ণ বা আংশিক পরিশোধিত)' : '(Full or Partial paid)',
                ),
              ),
              const SizedBox(width: 14),
              // Committed Amount card
              Expanded(
                child: _ImpactCard(
                  gradient: AppColors.cardGradientGold,
                  icon: Icons.savings_rounded,
                  value: Formatters.bdtCompact(totalAmount),
                  label: section != null ? (isBn ? section.amountLabelBn : section.amountLabel) : t(ref, 'committedAmount'),
                  confirmedValue: confirmedTarget > 0 ? Formatters.bdtCompact(confirmedTarget) : null,
                  confirmedLabel: isBn ? 'নিশ্চিত' : 'Confirmed',
                  confirmedSub: isBn ? '(${Formatters.number(confirmedInv)} জন বিনিয়োগকারী থেকে)' : '(from ${Formatters.number(confirmedInv)} investors)',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Goal Progress Bar ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: isDark ? 0.2 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.track_changes_rounded,
                        color: Color(0xFF4F46E5),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isBn ? 'বিনিয়োগের লক্ষ্যমাত্রা' : 'Investment Target',
                            style: GoogleFonts.publicSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isBn
                                ? 'লক্ষ্য: ${targetCr.toStringAsFixed(0)} কোটি টাকা'
                                : 'Target Goal: ${targetCr % 1 == 0 ? targetCr.toStringAsFixed(0) : targetCr.toStringAsFixed(2)} Cr BDT',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Percentage Pill Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${(progressPct * 100).toStringAsFixed(1)}%',
                            style: GoogleFonts.publicSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Raised vs Goal stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBn ? 'নিশ্চিত সংগ্রহ' : 'Confirmed Raised',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          Formatters.bdtCompact(confirmedTarget),
                          style: GoogleFonts.publicSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF4F46E5),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isBn ? 'লক্ষ্যমাত্রা' : 'Target Goal',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          isBn ? '${targetCr.toStringAsFixed(0)} কোটি' : '${targetCr % 1 == 0 ? targetCr.toStringAsFixed(0) : targetCr.toStringAsFixed(2)} Cr BDT',
                          style: GoogleFonts.publicSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Progress track
                Stack(
                  children: [
                    // Background Track
                    Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Progress Fill
                    LayoutBuilder(builder: (ctx, constraints) {
                      final fillWidth = (constraints.maxWidth * progressPct).clamp(0.0, constraints.maxWidth);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        height: 18,
                        width: fillWidth,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('৳0', style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))),
                    Text(
                      '${(progressPct * 100).toStringAsFixed(1)}% ${isBn ? 'অর্জিত' : 'Achieved'}',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                    Text(
                      isBn ? '${targetCr.toStringAsFixed(0)} কোটি' : '${targetCr % 1 == 0 ? targetCr.toStringAsFixed(0) : targetCr.toStringAsFixed(2)} Cr',
                      style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final LinearGradient gradient;
  final IconData icon;
  final String value;
  final String label;
  final String? confirmedValue;
  final String? confirmedLabel;
  final String? confirmedSub;

  const _ImpactCard({
    required this.gradient,
    required this.icon,
    required this.value,
    required this.label,
    this.confirmedValue,
    this.confirmedLabel,
    this.confirmedSub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Icon Badge
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 14),

          // Main Value & Label
          Text(
            value,
            style: GoogleFonts.publicSans(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          // This label is admin-editable (Stats Section in the web panel),
          // so its length isn't under our control — FittedBox keeps it on
          // one line by shrinking just enough to fit, instead of wrapping
          // and making this card taller than the one next to it whenever
          // an admin picks a longer label (e.g. "Committed Amount" vs
          // "Total Investors").
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.88),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Confirmed Sub-Card
          if (confirmedValue != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$confirmedValue ${confirmedLabel ?? ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (confirmedSub != null) ...[
                    const SizedBox(height: 3),
                    Padding(
                      padding: const EdgeInsets.only(left: 21),
                      child: Text(
                        confirmedSub!,
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class _StatsShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Row(
        children: [
          Expanded(child: Container(height: 120, decoration: BoxDecoration(color: context.cardFill3, borderRadius: BorderRadius.circular(22)))),
          const SizedBox(width: 14),
          Expanded(child: Container(height: 120, decoration: BoxDecoration(color: context.cardFill3, borderRadius: BorderRadius.circular(22)))),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// EXPLORE SECTION
// ══════════════════════════════════════════════════════════════════════════════
class _ExploreSection extends StatelessWidget {
  final WidgetRef ref;
  final void Function(String) onNavigate;

  const _ExploreSection({required this.ref, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(siteSettingsProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final isCareerOpen = settingsAsync.maybeWhen(data: (s) => s.careerSettings.enabled, orElse: () => true);
    final careerSubtitle = isCareerOpen
        ? (lang == 'bn' ? 'আমাদের দলে যোগ দিন' : 'Join our team')
        : (lang == 'bn' ? 'সাময়িকভাবে বন্ধ' : 'Currently Closed');

    final items = [
      _ExploreItem(Icons.photo_library_rounded, t(ref, 'gallery'), '/gallery', AppColors.cardGradientTeal, 'View photos & moments'),
      _ExploreItem(Icons.help_rounded, t(ref, 'faq'), '/faq', const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)], begin: Alignment.topLeft, end: Alignment.bottomRight), 'Common questions'),
      _ExploreItem(Icons.account_balance_rounded, t(ref, 'bankDetails'), '/bank-details', AppColors.cardGradientGold, 'Official payment details'),
      _ExploreItem(Icons.work_rounded, t(ref, 'career'), '/career', const LinearGradient(colors: [Color(0xFFDB2777), Color(0xFFF472B6)], begin: Alignment.topLeft, end: Alignment.bottomRight), careerSubtitle),
      _ExploreItem(Icons.event_rounded, t(ref, 'events'), '/events', AppColors.cardGradientGreen, 'Upcoming programs'),
      _ExploreItem(Icons.shield_rounded, t(ref, 'staffPortal'), '/admin/login', const LinearGradient(colors: [Color(0xFF475569), Color(0xFF64748B)], begin: Alignment.topLeft, end: Alignment.bottomRight), 'Admin & Staff access'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), // Reduced top padding, increased bottom padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: t(ref, 'explore'), subtitle: 'Everything Sharfians offers'),
          const SizedBox(height: 12), // Reduced gap

          // 2-column grid for all items
          GridView.builder(
            padding: EdgeInsets.zero, // Remove default grid padding that causes massive gaps
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              // A fixed pixel height, not childAspectRatio — aspectRatio ties
              // card height to card WIDTH, so a narrower phone gets a
              // shorter card for the exact same (fixed-size) text, which is
              // what caused the gap/overflow tuning fights above. A fixed
              // height sizes every card to exactly what the content needs,
              // on any screen: icon 40 + gap 14 + 1-line title ~20 + gap 2 +
              // 1-line subtitle ~16 + 32 padding ≈ 124, +8 buffer for font
              // metric/accessibility text-scale variance.
              mainAxisExtent: 132,
            ),
            itemBuilder: (context, i) => _ExploreCard(item: items[i], onTap: () => onNavigate(items[i].route)),
          ),
        ],
      ),
    );
  }
}

class _ExploreItem {
  final IconData icon;
  final String label;
  final String route;
  final LinearGradient gradient;
  final String subtitle;

  const _ExploreItem(this.icon, this.label, this.route, this.gradient, this.subtitle);
}

class _ExploreCard extends StatelessWidget {
  final _ExploreItem item;
  final VoidCallback onTap;

  const _ExploreCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: context.cardFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.borderFill),
            boxShadow: context.cardShadow,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(gradient: item.gradient, borderRadius: BorderRadius.circular(13)),
                child: Icon(item.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 14), // Replaced Spacer with fixed gap
              Text(item.label, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: context.textHigh), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              // Plain system font, not GoogleFonts.nunito — a bold Nunito
              // variant is a brand-new fetch never requested elsewhere in the
              // app, so on a device/simulator with flaky network it silently
              // stays unbolded (network fetch failures here don't surface as
              // errors, and no rebuild retries them). A locally-available
              // weight has no such risk.
              Text(item.subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: context.textMed), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: context.textHigh)),
        const SizedBox(height: 2),
        Text(subtitle, style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: context.textHigh.withValues(alpha: 0.75))),
      ],
    );
  }
}
