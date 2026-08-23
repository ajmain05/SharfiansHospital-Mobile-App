import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/adaptive_colors.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/investor_category.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../models/site_settings.dart';
import '../../settings/providers/site_settings_provider.dart';

class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  IconData _getCategoryIcon(String category) {
    final catLower = category.toLowerCase();
    if (catLower.contains('investment') || catLower.contains('ownership') || catLower.contains('share')) {
      return Icons.account_balance_outlined;
    } else if (catLower.contains('profit') || catLower.contains('return') || catLower.contains('dividend') || catLower.contains('yield')) {
      return Icons.trending_up_rounded;
    } else if (catLower.contains('financial') || catLower.contains('transparency') || catLower.contains('finance') || catLower.contains('audit')) {
      return Icons.insights_rounded;
    } else if (catLower.contains('management') || catLower.contains('manage') || catLower.contains('board') || catLower.contains('leadership') || catLower.contains('director')) {
      return Icons.manage_accounts_outlined;
    } else if (catLower.contains('project') || catLower.contains('location') || catLower.contains('facility') || catLower.contains('detail')) {
      return Icons.domain_rounded;
    } else if (catLower.contains('exit') || catLower.contains('sell') || catLower.contains('withdraw')) {
      return Icons.currency_exchange_rounded;
    } else if (catLower.contains('licens') || catLower.contains('approval') || catLower.contains('legal') || catLower.contains('permit')) {
      return Icons.verified_user_outlined;
    } else if (catLower.contains('additional') || catLower.contains('general') || catLower.contains('other')) {
      return Icons.info_outline_rounded;
    } else if (catLower.contains('medical') || catLower.contains('hospital') || catLower.contains('health')) {
      return Icons.local_hospital_outlined;
    } else if (catLower.contains('security') || catLower.contains('safe') || catLower.contains('policy')) {
      return Icons.shield_outlined;
    }
    return Icons.quiz_outlined;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(siteSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF191C1E),
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            Text(
              'Sharfians Hospital',
              style: GoogleFonts.publicSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF191C1E),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF316BF3),
        onRefresh: () async => ref.invalidate(siteSettingsProvider),
        child: settingsAsync.when(
          data: (settings) {
            if (settings.faqs.isEmpty) return _EmptyFaq();

            final grouped = <String, List<FaqItem>>{};
            for (final item in settings.faqs) {
              grouped.putIfAbsent(item.category, () => []).add(item);
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                // ── Header Section ─────────────────────────────────────────
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: Lottie.asset(
                      'assets/animations/Question.json',
                      fit: BoxFit.contain,
                      frameRate: const FrameRate(30),
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.quiz_outlined,
                        size: 72,
                        color: const Color(0xFF316BF3).withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                Text(
                  'INVESTOR RESOURCES',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: const Color(0xFF316BF3), // Royal Blue
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Frequently Asked Questions',
                  style: GoogleFonts.publicSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: isDark ? Colors.white : const Color(0xFF191C1E),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Find clear, precise answers regarding your equity, returns, and the operational structure of the hospital project.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF45464D),
                  ),
                ),
                const SizedBox(height: 12),

                // ── FAQ Items Grouped by Category ────────────────────────────
                for (final entry in grouped.entries) ...[
                    // Category Header
                    Row(
                      children: [
                        Icon(
                          _getCategoryIcon(entry.key),
                          color: const Color(0xFF316BF3), // Royal Blue
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: GoogleFonts.publicSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: isDark ? Colors.white : const Color(0xFF191C1E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Accordion items
                    for (final item in entry.value) ...[
                      _FaqAccordionTile(item: item),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 24),
                  ],
              ],
            );
          },
          loading: () => const ShimmerLoader(),
          error: (err, stack) => ErrorRetryView(
            onRetry: () => ref.invalidate(siteSettingsProvider),
          ),
        ),
      ),
    );
  }
}

class _FaqAccordionTile extends StatefulWidget {
  final FaqItem item;

  const _FaqAccordionTile({required this.item});

  @override
  State<_FaqAccordionTile> createState() => _FaqAccordionTileState();
}

class _FaqAccordionTileState extends State<_FaqAccordionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parts = widget.item.answer.split('{{DIRECTORSHIP_TABLE}}');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          title: Text(
            widget.item.question,
            style: GoogleFonts.publicSans(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              height: 1.35,
              color: isDark ? Colors.white : const Color(0xFF191C1E),
            ),
          ),
          trailing: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.expand_more_rounded,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF45464D),
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF7F9FB),
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (parts.first.trim().isNotEmpty)
                    Text(
                      parts.first.trim(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.55,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF45464D),
                      ),
                    ),
                  if (widget.item.answer.contains('{{DIRECTORSHIP_TABLE}}')) ...[
                    const SizedBox(height: 14),
                    const _DirectorshipTable(),
                  ],
                  if (parts.length > 1 && parts.last.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      parts.last.trim(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.55,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF45464D),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectorshipTable extends StatelessWidget {
  const _DirectorshipTable();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rows = InvestorCategory.tiers
        .where((t) => t.isDirector)
        .map((t) => (t, t.minAmount))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: rows[i].$1.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rows[i].$1.label,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF191C1E),
                      ),
                    ),
                  ),
                  Text(
                    Formatters.bdt(rows[i].$2),
                    style: GoogleFonts.inter(
                      color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyFaq extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 120),
          child: Column(
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 48,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                t(ref, 'noFaqs'),
                style: GoogleFonts.inter(
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
