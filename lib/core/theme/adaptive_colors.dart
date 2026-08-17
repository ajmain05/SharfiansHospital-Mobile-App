import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Adaptive color extension on BuildContext.
/// Use these instead of AppColors.* for ANY color that must change in dark mode.
/// Gradient/brand colors (heroGradient, gold, etc.) are fine hardcoded.
extension AppAdaptiveColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ── Backgrounds ────────────────────────────────────────────────────────────
  /// Page/scaffold background
  Color get bgFill => isDark ? const Color(0xFF111827) : AppColors.background;

  /// Card / surface (opaque)
  Color get cardFill => isDark ? const Color(0xFF1F2937) : AppColors.surface;

  /// Slightly elevated surface (input fields, inner containers)
  Color get cardFill2 => isDark ? const Color(0xFF374151) : AppColors.surface2;

  /// Subtle tinted background (shimmer, empty states)
  Color get cardFill3 => isDark ? const Color(0xFF2D3748) : AppColors.surface3;

  // ── Text ──────────────────────────────────────────────────────────────────
  Color get textHigh => isDark ? const Color(0xFFF9FAFB) : AppColors.textPrimary;
  Color get textMed => isDark ? const Color(0xFF9CA3AF) : AppColors.textSecondary;
  Color get textLow => isDark ? const Color(0xFF6B7280) : const Color(0xFFA8A29E);

  // ── Borders / Dividers ────────────────────────────────────────────────────
  Color get borderFill => isDark ? const Color(0xFF374151) : AppColors.border;
  Color get borderLight => isDark ? const Color(0xFF4B5563) : const Color(0xFFF0E8D5);

  // ── Primary tinted fills ──────────────────────────────────────────────────
  Color get primaryTint => isDark
      ? AppColors.primary900.withValues(alpha: 0.4)
      : AppColors.primary50;
  Color get primaryTintBorder => isDark
      ? AppColors.primary700.withValues(alpha: 0.4)
      : AppColors.primary200;

  // ── Shadow ─────────────────────────────────────────────────────────────────
  Color get shadowColor =>
      isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06);

  /// Convenience: BoxShadow list for a standard card
  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: shadowColor,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
