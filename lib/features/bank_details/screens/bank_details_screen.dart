import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/adaptive_colors.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../models/site_settings.dart';
import '../../settings/providers/site_settings_provider.dart';
import '../../settings/screens/contact_us_screen.dart';

class BankDetailsScreen extends ConsumerWidget {
  const BankDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(siteSettingsProvider);

    return Scaffold(
      backgroundColor: context.bgFill,
      body: RefreshIndicator(
        color: AppColors.primary700,
        onRefresh: () async => ref.invalidate(siteSettingsProvider),
        child: settingsAsync.when(
          data: (settings) => settings.bankDetails.hasAny
              ? _BankDetailsBody(details: settings.bankDetails, ref: ref)
              : _EmptyState(ref: ref),
          loading: () => const ShimmerLoader(),
          error: (err, stack) => ErrorRetryView(
            onRetry: () => ref.invalidate(siteSettingsProvider),
          ),
        ),
      ),
    );
  }
}

class _BankDetailsBody extends StatelessWidget {
  final BankDetails details;
  final WidgetRef ref;

  const _BankDetailsBody({required this.details, required this.ref});

  @override
  Widget build(BuildContext context) {
    final rows = [
      (Icons.account_balance_rounded, t(ref, 'bankName'), details.bankName, AppColors.primary700),
      (Icons.person_rounded, t(ref, 'accountName'), details.accountName, AppColors.teal600),
      (Icons.credit_card_rounded, t(ref, 'accountNumber'), details.accountNumber, AppColors.accent600),
      (Icons.location_on_rounded, t(ref, 'branchName'), details.branchName, const Color(0xFF7C3AED)),
      (Icons.numbers_rounded, t(ref, 'routingNumber'), details.routingNumber, const Color(0xFFDB2777)),
      (Icons.language_rounded, t(ref, 'swiftCode'), details.swiftCode, AppColors.primary600),
    ].where((row) => row.$3.isNotEmpty).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: _PremiumHeader(ref: ref, onBack: () => context.pop()),
        ),

        // Bank account card
        if (rows.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    icon: Icons.account_balance_rounded,
                    title: 'Bank Account',
                    gradient: AppColors.cardGradientGreen,
                  ),
                  const SizedBox(height: 14),
                  ...rows.map((row) => _DetailTile(
                    icon: row.$1,
                    label: row.$2,
                    value: row.$3,
                    color: row.$4,
                    ref: ref,
                  )),
                ],
              ),
            ),
          ),

        // Mobile banking
        if (details.mobileAccounts.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    icon: Icons.phone_android_rounded,
                    title: t(ref, 'mobileBanking'),
                    gradient: AppColors.goldGradient,
                  ),
                  const SizedBox(height: 14),
                  ...details.mobileAccounts.map(
                    (acc) => _MobileBankTile(account: acc, ref: ref),
                  ),
                ],
              ),
            ),
          ),

        // Notice banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.info_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'After making a transfer, please let us know via Contact Us so we can update your investment portfolio.',
                          style: GoogleFonts.nunito(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'Contact Us',
                                style: GoogleFonts.publicSans(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  final WidgetRef ref;
  final VoidCallback onBack;

  const _PremiumHeader({required this.ref, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(ref, 'bankDetails'),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'Official payment information',
                    style: GoogleFonts.nunito(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
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

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final LinearGradient gradient;

  const _SectionTitle({required this.icon, required this.title, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: context.textHigh,
          ),
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final WidgetRef ref;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderFill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: context.textMed,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: context.textHigh,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: value));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${t(ref, 'copied')} ✓',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                      ),
                      duration: const Duration(seconds: 1),
                      backgroundColor: AppColors.primary800,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
              icon: Icon(Icons.copy_rounded, size: 18, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileBankTile extends StatelessWidget {
  final MobileAccount account;
  final WidgetRef ref;

  const _MobileBankTile({required this.account, required this.ref});

  Color get _brandColor {
    final p = account.provider.toLowerCase();
    if (p.contains('bkash')) return const Color(0xFFE2136E);
    if (p.contains('nagad')) return const Color(0xFFF58220);
    if (p.contains('rocket')) return const Color(0xFF7B1FA2);
    if (p.contains('upay')) return const Color(0xFF0F9D58);
    return AppColors.primary600;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderFill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_brandColor, _brandColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                account.provider.length > 5
                    ? account.provider.substring(0, 5)
                    : account.provider,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.provider,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: context.textHigh,
                    ),
                  ),
                  if (account.type.isNotEmpty)
                    Text(
                      account.type,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: context.textMed,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    account.number,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _brandColor,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: account.number));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${t(ref, 'copied')} ✓'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: AppColors.primary800,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
              icon: Icon(Icons.copy_rounded, size: 18, color: _brandColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  final WidgetRef ref;

  const _EmptyState({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _PremiumHeader(ref: ref, onBack: () => context.pop()),
        ),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.cardFill3,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_outlined,
                    size: 52,
                    color: context.textMed,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  t(ref, 'noBankDetails'),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.textMed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
