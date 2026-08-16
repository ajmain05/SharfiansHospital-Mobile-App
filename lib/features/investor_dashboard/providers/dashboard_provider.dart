import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/deposit.dart';
import '../../investor_auth/providers/investor_session_provider.dart';

/// Direct port of `InvestorDashboard.jsx`'s per-account overview computation:
/// `auth-phone` returns deposits embedded, so the whole summary is derived
/// client-side from the active account — there is no separate "summary" API call.
class DashboardSummary {
  final num totalCommitted;
  final num totalPaid;
  final num totalRemaining;
  final double progressPercent;
  final String? lastPaymentDate;
  final List<Deposit> deposits;

  const DashboardSummary({
    required this.totalCommitted,
    required this.totalPaid,
    required this.totalRemaining,
    required this.progressPercent,
    required this.lastPaymentDate,
    required this.deposits,
  });
}

DateTime _parseDate(String s) => DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0);

final dashboardSummaryProvider = Provider<DashboardSummary?>((ref) {
  final account = ref.watch(investorSessionProvider).activeAccount;
  if (account == null) return null;

  final deposits = [...account.deposits]..sort((a, b) => _parseDate(b.dateOfDeposit).compareTo(_parseDate(a.dateOfDeposit)));

  final totalPaid = account.deposits.fold<num>(0, (sum, d) => sum + d.totalAmount);
  final totalCommitted = account.shareAmount;
  final totalRemaining = (totalCommitted - totalPaid) < 0 ? 0 : totalCommitted - totalPaid;
  final progressPercent = totalCommitted > 0 ? (totalPaid / totalCommitted * 100).clamp(0, 100).toDouble() : 0.0;

  return DashboardSummary(
    totalCommitted: totalCommitted,
    totalPaid: totalPaid,
    totalRemaining: totalRemaining,
    progressPercent: progressPercent,
    lastPaymentDate: deposits.isNotEmpty ? deposits.first.dateOfDeposit : null,
    deposits: deposits,
  );
});
