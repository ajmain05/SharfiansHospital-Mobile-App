import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../models/site_settings.dart';
import '../../settings/providers/site_settings_provider.dart';

class BankDetailsScreen extends ConsumerWidget {
  const BankDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(siteSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(t(ref, 'bankDetails')),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(siteSettingsProvider),
        child: settingsAsync.when(
          data: (settings) => settings.bankDetails.hasAny
              ? _BankDetailsBody(details: settings.bankDetails)
              : _EmptyBankDetails(),
          loading: () => const ShimmerLoader(),
          error: (err, stack) => ErrorRetryView(
            onRetry: () => ref.invalidate(siteSettingsProvider),
          ),
        ),
      ),
    );
  }
}

class _BankDetailsBody extends ConsumerWidget {
  final BankDetails details;

  const _BankDetailsBody({required this.details});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = [
      (t(ref, 'bankName'), details.bankName),
      (t(ref, 'accountName'), details.accountName),
      (t(ref, 'accountNumber'), details.accountNumber),
      (t(ref, 'branchName'), details.branchName),
      (t(ref, 'routingNumber'), details.routingNumber),
      (t(ref, 'swiftCode'), details.swiftCode),
    ].where((row) => row.$2.isNotEmpty).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        if (rows.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    _CopyRow(label: rows[i].$1, value: rows[i].$2),
                    if (i != rows.length - 1) const Divider(height: 20),
                  ],
                ],
              ),
            ),
          ),
        if (details.mobileAccounts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            t(ref, 'mobileBanking'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          for (final account in details.mobileAccounts) ...[
            _MobileAccountCard(account: account),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }
}

class _CopyRow extends ConsumerWidget {
  final String label;
  final String value;

  const _CopyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        IconButton(
          tooltip: t(ref, 'copy'),
          icon: const Icon(Icons.copy_rounded, size: 20),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(t(ref, 'copied'))));
            }
          },
        ),
      ],
    );
  }
}

class _MobileAccountCard extends StatelessWidget {
  final MobileAccount account;

  const _MobileAccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final color = _brandColor(account.provider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _brandLabel(account.provider),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.provider,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (account.type.isNotEmpty)
                    Text(
                      account.type,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            _CopyNumber(value: account.number),
          ],
        ),
      ),
    );
  }

  Color _brandColor(String provider) {
    final p = provider.toLowerCase();
    if (p.contains('bkash')) return const Color(0xFFE2136E);
    if (p.contains('nagad')) return const Color(0xFFF58220);
    if (p.contains('rocket')) return const Color(0xFF7B1FA2);
    if (p.contains('upay')) return const Color(0xFF0F9D58);
    return AppColors.primary600;
  }

  String _brandLabel(String provider) {
    if (provider.trim().isEmpty) return 'PAY';
    return provider.trim().length > 8
        ? provider.trim().substring(0, 8)
        : provider.trim();
  }
}

class _CopyNumber extends ConsumerWidget {
  final String value;

  const _CopyNumber({required this.value});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t(ref, 'copied'))));
        }
      },
      icon: const Icon(Icons.copy_rounded, size: 16),
      label: Text(value),
    );
  }
}

class _EmptyBankDetails extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 120),
          child: Column(
            children: [
              const Icon(
                Icons.account_balance_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                t(ref, 'noBankDetails'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
