import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/investor_category.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../models/site_settings.dart';
import '../../settings/providers/site_settings_provider.dart';

class FaqScreen extends ConsumerWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(siteSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(t(ref, 'faq')),
      ),
      body: RefreshIndicator(
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  for (final item in entry.value) _FaqTile(item: item),
                  const SizedBox(height: 12),
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

class _FaqTile extends StatelessWidget {
  final FaqItem item;

  const _FaqTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final parts = item.answer.split('{{DIRECTORSHIP_TABLE}}');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          item.question,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        children: [
          if (parts.first.trim().isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                parts.first.trim(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
          if (item.answer.contains('{{DIRECTORSHIP_TABLE}}')) ...[
            const SizedBox(height: 12),
            const _DirectorshipTable(),
          ],
          if (parts.length > 1 && parts.last.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                parts.last.trim(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DirectorshipTable extends StatelessWidget {
  const _DirectorshipTable();

  @override
  Widget build(BuildContext context) {
    final rows = [
      (InvestorCategory.of(2000000), 2000000),
      (InvestorCategory.of(5000000), 5000000),
      (InvestorCategory.of(10000000), 10000000),
      (InvestorCategory.of(50000000), 50000000),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: i == rows.length - 1
                    ? null
                    : const Border(bottom: BorderSide(color: AppColors.border)),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    Formatters.bdt(rows[i].$2),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 120),
          child: Column(
            children: [
              const Icon(
                Icons.help_outline_rounded,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                t(ref, 'noFaqs'),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
