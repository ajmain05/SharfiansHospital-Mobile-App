import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_provider.dart';

class ThemeToggleButton extends ConsumerWidget {
  final Color? color;

  const ThemeToggleButton({super.key, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return IconButton(
      icon: Icon(
        themeMode == ThemeMode.dark
            ? Icons.dark_mode_rounded
            : Icons.light_mode_rounded,
        color: color ?? Colors.white,
      ),
      onPressed: () => ref.read(themeProvider.notifier).toggle(),
      tooltip: 'Toggle Theme',
    );
  }
}
