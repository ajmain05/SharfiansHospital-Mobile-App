import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/locale_provider.dart';
import '../theme/app_colors.dart';

class ErrorRetryView extends ConsumerWidget {
  final String? message;
  final VoidCallback onRetry;

  const ErrorRetryView({super.key, this.message, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? t(ref, 'somethingWentWrong'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text(t(ref, 'retry'))),
          ],
        ),
      ),
    );
  }
}
