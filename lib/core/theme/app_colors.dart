import 'package:flutter/material.dart';

/// New "Warm Community Premium" design system
/// Rich Forest Green + Saffron Gold — mobile-first, app-like, NOT website-like.
class AppColors {
  AppColors._();

  // ── Primary: Royal Blue (#316BF3) ─────────────────────────────────────────
  static const primary50  = Color(0xFFEFF6FF);
  static const primary100 = Color(0xFFDBEAFE);
  static const primary200 = Color(0xFFBFDBFE);
  static const primary400 = Color(0xFF60A5FA);
  static const primary500 = Color(0xFF3B82F6);
  static const primary600 = Color(0xFF2563EB);
  static const primary700 = Color(0xFF316BF3);
  static const primary800 = Color(0xFF1E40AF);
  static const primary900 = Color(0xFF1E3A8A);

  // ── Accent: Saffron Gold ──────────────────────────────────────────────────
  static const accent50  = Color(0xFFFFFBEB);
  static const accent100 = Color(0xFFFEF3C7);
  static const accent300 = Color(0xFFFCD34D);
  static const accent400 = Color(0xFFFBBF24);
  static const accent500 = Color(0xFFF59E0B);
  static const accent600 = Color(0xFFD97706);
  static const accent700 = Color(0xFFB45309);

  // ── Teal / Cyan ───────────────────────────────────────────────────────────
  static const teal500 = Color(0xFF3B82F6);
  static const teal600 = Color(0xFF2563EB);
  static const teal700 = Color(0xFF1D4ED8);

  // ── Warm Neutrals ─────────────────────────────────────────────────────────
  static const background  = Color(0xFFF7F9FB);   // soft surface
  static const surface     = Color(0xFFFFFFFF);
  static const surface2    = Color(0xFFF8FAFC);   // light card
  static const surface3    = Color(0xFFF1F5F9);   // card container
  static const textPrimary = Color(0xFF191C1E);   // dark text
  static const textSecondary = Color(0xFF64748B); // slate gray
  static const border      = Color(0xFFE2E8F0);   // clean border
  static const error       = Color(0xFFDC2626);

  // ── Special ───────────────────────────────────────────────────────────────
  static const directorGold = accent500;

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E40AF), // deep blue
      Color(0xFF316BF3), // royal blue
    ],
    stops: [0.0, 1.0],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent600, accent400],
  );

  static const cardGradientGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF316BF3)],
  );

  static const cardGradientGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
  );

  static const cardGradientTeal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D4ED8), Color(0xFF316BF3)],
  );

  // Keep this for backward compat references
  static const primaryGradient = heroGradient;
  static const brandGradient = heroGradient;
}
