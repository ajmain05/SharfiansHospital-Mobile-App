import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../l10n/locale_provider.dart';

class ErrorRetryView extends ConsumerWidget {
  final String? message;
  final VoidCallback onRetry;

  const ErrorRetryView({super.key, this.message, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: Lottie.asset(
                'assets/animations/No internet connection.json',
                fit: BoxFit.contain,
                frameRate: const FrameRate(30),
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? t(ref, 'somethingWentWrong'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                t(ref, 'retry'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
