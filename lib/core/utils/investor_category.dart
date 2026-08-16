import 'package:flutter/material.dart';

/// Direct port of the website's `utils/investorCategory.js` tier thresholds,
/// so DIRECTOR badges match exactly between the app and the website.
class InvestorCategory {
  final String id;
  final String label;
  final Color color;
  final Gradient gradient;
  final bool isDirector;

  const InvestorCategory({
    required this.id,
    required this.label,
    required this.color,
    required this.gradient,
    required this.isDirector,
  });

  static InvestorCategory of(num? amount) {
    final a = amount ?? 0;
    if (a >= 50000000) {
      return InvestorCategory(
        id: 'diamond',
        label: 'Diamond Director',
        color: const Color(0xFF0E7490),
        gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF2563EB)]),
        isDirector: true,
      );
    }
    if (a >= 10000000) {
      return InvestorCategory(
        id: 'platinum',
        label: 'Platinum Director',
        color: const Color(0xFF334155),
        gradient: const LinearGradient(colors: [Color(0xFF64748B), Color(0xFF334155)]),
        isDirector: true,
      );
    }
    if (a >= 5000000) {
      return InvestorCategory(
        id: 'golden',
        label: 'Golden Director',
        color: const Color(0xFFB45309),
        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFF97316)]),
        isDirector: true,
      );
    }
    if (a >= 2000000) {
      return InvestorCategory(
        id: 'silver',
        label: 'Silver Director',
        color: const Color(0xFF374151),
        gradient: const LinearGradient(colors: [Color(0xFF9CA3AF), Color(0xFF64748B)]),
        isDirector: true,
      );
    }
    return InvestorCategory(
      id: 'regular',
      label: 'Regular Investor',
      color: const Color(0xFF047857),
      gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF0D9488)]),
      isDirector: false,
    );
  }
}
