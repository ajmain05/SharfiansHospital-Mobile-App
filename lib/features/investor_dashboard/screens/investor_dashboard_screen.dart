import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../providers/dashboard_provider.dart';
import '../widgets/circular_progress_ring.dart';
import '../../../core/widgets/theme_toggle_button.dart';

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

    if (!session.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/investor/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final account = session.activeAccount!;
    final summary = ref.watch(dashboardSummaryProvider)!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            t(
              ref,
              'welcomeComma',
              params: {'name': account.displayName.split(' ').first},
            ),
          ),
        actions: [
          ThemeToggleButton(color: Theme.of(context).appBarTheme.foregroundColor),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: t(ref, 'refresh'),
            onPressed: () =>
                ref.read(investorSessionProvider.notifier).refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: t(ref, 'logout'),
            onPressed: () async {
              await ref.read(investorSessionProvider.notifier).logout();
              if (context.mounted) context.go('/investor/login');
            },
          ),
        ],
        bottom: TabBar(
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          indicatorWeight: 3,
          tabs: [
            Tab(text: t(ref, 'overview')),
            Tab(text: t(ref, 'accounts')),
            Tab(text: t(ref, 'payments')),
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
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(
              category.isDirector ? '⭐ ${category.label}' : category.label,
              style: TextStyle(
                color: category.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircularProgressRing(percent: summary.progressPercent),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _statBlock(
                            context,
                            t(ref, 'totalCommitted'),
                            Formatters.bdt(summary.totalCommitted),
                            AppColors.primary900,
                            big: true,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _statBlock(
                                  context,
                                  t(ref, 'paid'),
                                  Formatters.bdt(summary.totalPaid),
                                  AppColors.accent600,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _statBlock(
                                  context,
                                  t(ref, 'remaining'),
                                  Formatters.bdt(summary.totalRemaining),
                                  const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
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
            const SizedBox(width: 12),
            Expanded(
              child: _infoCard(
                context,
                Icons.event_outlined,
                t(ref, 'lastPayment'),
                summary.lastPaymentDate ?? '—',
                AppColors.accent600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _infoCard(
          context,
          Icons.schedule_outlined,
          t(ref, 'monthly'),
          Formatters.bdt(account.monthlyPayment),
          AppColors.primary700,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _statBlock(
    BuildContext context,
    String label,
    String value,
    Color color, {
    bool big = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: big ? 22 : 16,
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
    bool fullWidth = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(16),
      itemCount: accounts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final acc = accounts[i];
        final active = acc.id == activeAccountId;
        final category = InvestorCategory.of(acc.shareAmount);
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => ref
              .read(investorSessionProvider.notifier)
              .setActiveAccount(acc.id),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: active ? AppColors.primary600 : AppColors.border,
                width: active ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              acc.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              acc.investorId,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (category.isDirector)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: category.gradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _miniStat(
                          context,
                          t(ref, 'shareAmount'),
                          Formatters.bdt(acc.shareAmount),
                        ),
                      ),
                      Expanded(
                        child: _miniStat(
                          context,
                          t(ref, 'monthly'),
                          Formatters.bdt(acc.monthlyPayment),
                        ),
                      ),
                      Expanded(
                        child: _miniStat(
                          context,
                          t(ref, 'duration'),
                          '${acc.totalMonths} ${t(ref, 'months')}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _miniStat(BuildContext context, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(ref, 'downloadFailed'))));
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  Future<void> _shareReceipt(Deposit dep) async {
    setState(() => _downloadingId = dep.id);
    try {
      final path = await _receiptPath(dep);
      if (!mounted) return;
      await Share.shareXFiles([XFile(path)]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(ref, 'downloadFailed'))));
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
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: AppColors.primary400,
              ),
              const SizedBox(height: 12),
              Text(
                t(ref, 'noPaymentRecords'),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final dep in widget.deposits) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dep.dateOfDeposit,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (dep.batchNo != null)
                          Text(
                            dep.batchNo!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.bdt(dep.totalAmount),
                    style: const TextStyle(
                      color: AppColors.accent600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_downloadingId == dep.id)
                    const SizedBox(
                      height: 18,
                      width: 18,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else ...[
                    IconButton(
                      tooltip: t(ref, 'download'),
                      onPressed: () => _downloadReceipt(dep),
                      icon: const Icon(
                        Icons.download_rounded,
                        color: AppColors.primary600,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Share',
                      onPressed: () => _shareReceipt(dep),
                      icon: Icon(
                        Icons.share_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t(ref, 'totalPaid'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              Formatters.bdt(widget.totalPaid),
              style: const TextStyle(
                color: AppColors.accent600,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
