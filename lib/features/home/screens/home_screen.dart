import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../core/widgets/language_toggle_button.dart';
import '../../../models/site_settings.dart';
import '../../investor_auth/providers/investor_session_provider.dart';
import '../../settings/providers/site_settings_provider.dart';
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(siteSettingsProvider);
          ref.invalidate(publicStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 48),
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [LanguageToggleButton()],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        settingsAsync.maybeWhen(
                          data: (s) => lang == 'bn' ? s.badgeTextBn : s.badgeText,
                          orElse: () => t(ref, 'badgeText'),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      settingsAsync.maybeWhen(data: (s) => lang == 'bn' ? s.heroTitleBn : s.heroTitle, orElse: () => t(ref, 'heroTitle')),
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      settingsAsync.maybeWhen(
                        data: (s) => lang == 'bn' ? s.heroSubtitleBn : s.heroSubtitle,
                        orElse: () => t(ref, 'heroSubtitle'),
                      ),
                      style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      settingsAsync.maybeWhen(
                        data: (s) => lang == 'bn' ? s.heroDescriptionBn : s.heroDescription,
                        orElse: () => t(ref, 'heroDescription'),
                      ),
                      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary700),
                      onPressed: () => context.go('/register'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Text(t(ref, 'becomeInvestor')), const SizedBox(width: 6), const Icon(Icons.arrow_forward_rounded, size: 18)],
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54, width: 2), foregroundColor: Colors.white),
                      onPressed: () => context.go(loggedIn ? '/investor/dashboard' : '/investor/login'),
                      child: Text(t(ref, 'viewMyPortal')),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => context.push('/events'),
                        style: TextButton.styleFrom(foregroundColor: Colors.white70),
                        icon: const Icon(Icons.event_outlined, size: 18),
                        label: Text(t(ref, 'events')),
                      ),
                    ),
                  ],
                ),
              ),
              publicStatsAsync.when(
                data: (stats) => _StatsSection(stats: stats, settingsAsync: settingsAsync, lang: lang),
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => ErrorRetryView(onRetry: () => ref.invalidate(publicStatsProvider)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsSection extends ConsumerWidget {
  final Map<String, dynamic> stats;
  final AsyncValue<SiteSettings> settingsAsync;
  final String lang;

  const _StatsSection({required this.stats, required this.settingsAsync, required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final InvestorStatsSection? section = settingsAsync.maybeWhen(data: (s) => s.investorStatsSection, orElse: () => null);
    final totalInvestors = (stats['totalInvestors'] as num?) ?? 0;
    final totalAmount = (stats['totalAmount'] as num?) ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        children: [
          Text(
            section != null ? (lang == 'bn' ? section.titleBn : section.title) : t(ref, 'totalInvestors'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  Icons.groups_rounded,
                  section != null ? (lang == 'bn' ? section.investorLabelBn : section.investorLabel) : t(ref, 'totalInvestors'),
                  Formatters.number(totalInvestors),
                  AppColors.primary600,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _statCard(
                  Icons.savings_rounded,
                  section != null ? (lang == 'bn' ? section.amountLabelBn : section.amountLabel) : t(ref, 'committedAmount'),
                  Formatters.bdt(totalAmount),
                  AppColors.accent600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
