import 'package:flutter/material.dart';

/// Sampled directly from the website's Tailwind `@theme` tokens
/// (frontend/src/index.css) so the app matches the hospital's real branding.
class AppColors {
  AppColors._();

  static const primary50 = Color(0xFFEFF6FF);
  static const primary100 = Color(0xFFDBEAFE);
  static const primary200 = Color(0xFFBFDBFE);
  static const primary400 = Color(0xFF60A5FA);
  static const primary500 = Color(0xFF3B82F6);
  static const primary600 = Color(0xFF1D4ED8);
  static const primary700 = Color(0xFF1E40AF);
  static const primary900 = Color(0xFF1E3A5F);

  static const accent400 = Color(0xFF34D399);
  static const accent500 = Color(0xFF10B981);
  static const accent600 = Color(0xFF059669);

  static const directorGold = Color(0xFFF59E0B);

  static const background = Color(0xFFF0F4F8);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF3F4F6);
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const error = Color(0xFFDC2626);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary900, primary600],
  );

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary600, accent500],
  );
}
