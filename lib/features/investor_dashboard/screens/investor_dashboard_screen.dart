import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/investor_category.dart';
import '../../../models/deposit.dart';
import '../../../models/investor.dart';
import '../../investor_auth/providers/investor_session_provider.dart';
import '../../investor_auth/screens/investor_login_screen.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/circular_progress_ring.dart';
import '../widgets/delete_account_dialog.dart';

class InvestorDashboardScreen extends ConsumerStatefulWidget {
  const InvestorDashboardScreen({super.key});

  @override
  ConsumerState<InvestorDashboardScreen> createState() =>
      _InvestorDashboardScreenState();
}

class _InvestorDashboardScreenState
    extends ConsumerState<InvestorDashboardScreen> {

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(investorSessionProvider);

    // Render the login form in place rather than navigating to '/investor/login':
    // this is the Portal tab's own branch of the bottom-nav shell, so a
    // context.go() here would replace the whole navigation stack (losing Home,
    // Events, Settings) and leave the hardware back button with nothing to
    // pop — Android would then close the app outright instead of going back.
    if (!session.isLoggedIn) {
      return const InvestorLoginScreen();
    }

    final account = session.activeAccount!;
    final summary = ref.watch(dashboardSummaryProvider)!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: false,
          titleSpacing: 16,
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t(ref, 'welcomeGreeting'),
                style: GoogleFonts.publicSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  account.displayName,
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.15,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  // No navigation needed: this widget already watches
                  // investorSessionProvider and switches to the login form
                  // in place once logged out (see build() above).
                  await ref.read(investorSessionProvider.notifier).logout();
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Tooltip(
                    message: t(ref, 'logout'),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          labelColor: AppColors.primary600,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
          indicatorColor: AppColors.primary600,
          labelStyle: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.6),
          unselectedLabelStyle: GoogleFonts.publicSans(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.6),
          indicatorWeight: 2,
          dividerColor: Theme.of(context).colorScheme.outlineVariant,
          // A fixed letterSpacing/weight combo that "just fits" only holds at
          // one specific screen width and system font scale — narrower
          // phones or a larger accessibility text size push wider words like
          // "ACCOUNTS"/"PAYMENTS" past their equal third of the bar again.
          // FittedBox shrinks instead of clipping, so it holds at any width.
          tabs: [
            Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text(t(ref, 'overview').toUpperCase()))),
            Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text(t(ref, 'accounts').toUpperCase()))),
            Tab(child: FittedBox(fit: BoxFit.scaleDown, child: Text(t(ref, 'payments').toUpperCase()))),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(investorSessionProvider.notifier).refresh(),
        child: TabBarView(
            children: [
              _OverviewTab(account: account, summary: summary),
              _AccountsTab(
                accounts: session.accounts,
                activeAccountId: session.activeAccountId,
              ),
              _PaymentsTab(
                deposits: summary.deposits,
                totalPaid: summary.totalPaid,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final Investor account;
  final DashboardSummary summary;

  const _OverviewTab({required this.account, required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = InvestorCategory.of(account.shareAmount);

    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 32),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: category.gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: Text(
                category.label.toUpperCase(),
                style: GoogleFonts.publicSans(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 40,
                offset: const Offset(0, 10),
                spreadRadius: -10,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularProgressRing(percent: summary.progressPercent),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statBlock(
                      context,
                      t(ref, 'totalCommitted'),
                      Formatters.bdt(summary.totalCommitted),
                      Theme.of(context).colorScheme.onSurface,
                      isTitle: true,
                    ),
                    const SizedBox(height: 20),
                    Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _statBlock(
                          context,
                          t(ref, 'paid'),
                          Formatters.bdt(summary.totalPaid),
                          AppColors.primary600,
                        ),
                        _statBlock(
                          context,
                          t(ref, 'remaining'),
                          Formatters.bdt(summary.totalRemaining),
                          const Color(0xFFD97706),
                          alignRight: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _infoCard(
                context,
                Icons.account_balance_wallet_outlined,
                t(ref, 'totalDeposits'),
                '${summary.deposits.length}',
                AppColors.primary600,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _infoCard(
                context,
                Icons.event_outlined,
                t(ref, 'lastPayment'),
                Formatters.shortDate(summary.lastPaymentDate),
                const Color(0xFFD97706),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _infoCard(
                context,
                Icons.schedule_outlined,
                t(ref, 'monthly'),
                Formatters.bdt(account.monthlyPayment),
                AppColors.primary600,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _infoCard(
                context,
                Icons.timelapse_outlined,
                t(ref, 'duration'),
                '${account.totalMonths} ${t(ref, 'months')}',
                const Color(0xFF0EA5E9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => DeleteAccountDialog.show(
              context,
              investorId: account.id,
              phone: account.phone,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                    spreadRadius: -10,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_remove_rounded,
                      color: Color(0xFFEF4444),
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t(ref, 'deleteMyAccount'),
                          style: GoogleFonts.publicSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t(ref, 'deleteAccountTileSubtitle'),
                          style: GoogleFonts.publicSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statBlock(
    BuildContext context,
    String label,
    String value,
    Color color, {
    bool isTitle = false,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.publicSans(
            fontSize: 11,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: isTitle
              ? GoogleFonts.publicSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: color,
                )
              : GoogleFonts.publicSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
        ),
      ],
    );
  }

  Widget _infoCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color, {
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 10),
            spreadRadius: -10,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 14),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.publicSans(
              fontSize: 11,
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          // FittedBox shrinks the text just enough to actually fit instead
          // of guessing a font size or date format that might still
          // overflow on some device width — it can never truncate.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: isFullWidth
                  ? GoogleFonts.publicSans(fontSize: 26, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)
                  : GoogleFonts.publicSans(fontSize: 19, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountsTab extends ConsumerWidget {
  final List<Investor> accounts;
  final String? activeAccountId;

  const _AccountsTab({required this.accounts, required this.activeAccountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 160),
      itemCount: accounts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final acc = accounts[i];
        final active = acc.id == activeAccountId;
        final category = InvestorCategory.of(acc.shareAmount);
        
        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => ref
              .read(investorSessionProvider.notifier)
              .setActiveAccount(acc.id),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surfaceContainerLowest, 
                  Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFF1E2433) 
                      : const Color(0xFFF8F9FF)
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: active 
                    ? AppColors.primary600 
                    : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: active ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 48,
                  offset: const Offset(0, 24),
                  spreadRadius: -12,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 0,
                  offset: const Offset(0, 0),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      acc.displayName,
                      style: GoogleFonts.publicSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      acc.investorId,
                      style: GoogleFonts.publicSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: category.gradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: category.color.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                            spreadRadius: -6,
                          ),
                        ],
                      ),
                      child: Text(
                        category.label.toUpperCase(),
                        style: GoogleFonts.publicSans(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    _accountStatBlock(
                      context,
                      t(ref, 'shareAmount'),
                      Formatters.bdt(acc.shareAmount),
                    ),
                    const SizedBox(height: 12),
                    _accountStatBlock(
                      context,
                      t(ref, 'monthly'),
                      Formatters.bdt(acc.monthlyPayment),
                    ),
                    const SizedBox(height: 12),
                    _accountStatBlock(
                      context,
                      t(ref, 'duration'),
                      '${acc.totalMonths} ${t(ref, 'months')}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _accountStatBlock(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.2 : 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.publicSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.publicSans(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentsTab extends ConsumerStatefulWidget {
  final List<Deposit> deposits;
  final num totalPaid;

  const _PaymentsTab({required this.deposits, required this.totalPaid});

  @override
  ConsumerState<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends ConsumerState<_PaymentsTab> {
  String? _downloadingId;

  Future<String> _receiptPath(Deposit dep) async {
    final dir = await getTemporaryDirectory();
    final receiptNo = dep.id.length >= 6
        ? dep.id.substring(dep.id.length - 6).toUpperCase()
        : dep.id.toUpperCase();
    final path = '${dir.path}/MR-$receiptNo.pdf';
    await ApiClient().download('/deposits/${dep.id}/receipt', path);
    return path;
  }

  Future<void> _downloadReceipt(Deposit dep) async {
    setState(() => _downloadingId = dep.id);
    try {
      final path = await _receiptPath(dep);
      if (!mounted) return;
      await OpenFilex.open(path);
    } catch (e) {
      debugPrint('Receipt download failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(ref, 'downloadFailed'))));
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  /// iPadOS/macOS present the share sheet as a popover anchored to a screen
  /// rect — without one, shareXFiles throws ("sharePositionOrigin argument
  /// must be set") instead of silently ignoring it the way iPhone/Android
  /// do. Falls back to the full screen if this widget's own RenderBox isn't
  /// available/sized yet, so it's never zero (which throws the same error).
  Rect _sharePositionOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    final size = MediaQuery.of(context).size;
    return Rect.fromLTWH(0, 0, size.width, size.height);
  }

  Future<void> _shareReceipt(Deposit dep) async {
    setState(() => _downloadingId = dep.id);
    try {
      final path = await _receiptPath(dep);
      if (!mounted) return;
      await Share.shareXFiles([XFile(path)], sharePositionOrigin: _sharePositionOrigin());
    } catch (e) {
      // Logged with its real type/message (not just the generic snackbar
      // text) since share-sheet failures on iOS are otherwise a black box —
      // this is what actually tells us whether it's the download step or
      // the native share sheet itself that's failing.
      debugPrint('Receipt share failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(ref, 'shareFailed'))));
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.deposits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 240,
                height: 240,
                child: Lottie.asset(
                  'assets/animations/not-found.json',
                  fit: BoxFit.contain,
                  frameRate: const FrameRate(30),
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 48,
                    color: AppColors.primary400,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t(ref, 'noPaymentRecords'),
                style: GoogleFonts.publicSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 160),
      children: [
        for (final dep in widget.deposits) ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary600.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                  spreadRadius: -3,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRANSACTION DATE',
                  style: GoogleFonts.publicSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dep.dateOfDeposit,
                  style: GoogleFonts.publicSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (dep.batchNo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ref: ${dep.batchNo}',
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AMOUNT PAID',
                          style: GoogleFonts.publicSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppColors.primary600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.bdt(dep.totalAmount),
                          style: GoogleFonts.publicSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary600,
                          ),
                        ),
                      ],
                    ),
                    if (_downloadingId == dep.id)
                      const SizedBox(
                        height: 40,
                        width: 40,
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Download — back to the original filled/tinted
                          // circle look.
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              tooltip: t(ref, 'download'),
                              onPressed: () => _downloadReceipt(dep),
                              icon: const Icon(
                                Icons.download_rounded,
                                color: AppColors.primary600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              tooltip: t(ref, 'share'),
                              onPressed: () => _shareReceipt(dep),
                              // Pre-tinted to AppColors.primary600 in the
                              // asset itself (not via color/colorBlendMode
                              // here) — BlendMode.srcIn on this image was
                              // rendering as a solid block on iOS/Impeller
                              // instead of respecting its alpha shape.
                              icon: Image.asset(
                                'assets/images/share_icon.png',
                                width: 26,
                                height: 26,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.brightness == Brightness.light 
                ? const Color(0xFF1E3A8A) // primary-container from HTML
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF316BF3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    t(ref, 'totalPaid').toUpperCase(),
                    style: GoogleFonts.publicSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                Formatters.bdt(widget.totalPaid),
                style: GoogleFonts.publicSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
