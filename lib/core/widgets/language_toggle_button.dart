import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/locale_provider.dart';
import '../theme/app_colors.dart';

class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    return TextButton(
      onPressed: () => ref.read(localeProvider.notifier).toggle(),
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFEFF6FF),
        foregroundColor: const Color(0xFF2563EB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        lang == 'en' ? 'বাং' : 'EN',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
