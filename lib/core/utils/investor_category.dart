import 'package:flutter/material.dart';

/// Direct port of the website's `utils/investorCategory.js` tier thresholds,
/// so DIRECTOR badges match exactly between the app and the website.
///
/// The backend has no CMS field for these thresholds — the website itself
/// hardcodes them the same way (`investorCategory.js`/`DirectorshipTable.jsx`).
/// [tiers] is the single source of truth other screens (FAQ directorship
/// table, Investment Guidelines) should read from instead of re-typing the
/// amounts, so they can't drift out of sync with each other again.
class InvestorCategory {
  final String id;
  final String label;
  final Color color;
  final Gradient gradient;
  final bool isDirector;
  final num minAmount;

  const InvestorCategory({
    required this.id,
    required this.label,
    required this.color,
    required this.gradient,
    required this.isDirector,
    required this.minAmount,
  });

  static const InvestorCategory regular = InvestorCategory(
    id: 'regular',
    label: 'Regular Investor',
    color: Color(0xFF047857),
    gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF0D9488)]),
    isDirector: false,
    minAmount: 0,
  );

  /// Ascending order: silver, golden, platinum, diamond.
  static const List<InvestorCategory> tiers = [
    InvestorCategory(
      id: 'silver',
      label: 'Silver Director',
      color: Color(0xFF374151),
      gradient: LinearGradient(colors: [Color(0xFF9CA3AF), Color(0xFF64748B)]),
      isDirector: true,
      minAmount: 2000000,
    ),
    InvestorCategory(
      id: 'golden',
      label: 'Golden Director',
      color: Color(0xFFB45309),
      gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFF97316)]),
      isDirector: true,
      minAmount: 5000000,
    ),
    InvestorCategory(
      id: 'platinum',
      label: 'Platinum Director',
      color: Color(0xFF334155),
      gradient: LinearGradient(colors: [Color(0xFF64748B), Color(0xFF334155)]),
      isDirector: true,
      minAmount: 10000000,
    ),
    InvestorCategory(
      id: 'diamond',
      label: 'Diamond Director',
      color: Color(0xFF0E7490),
      gradient: LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF2563EB)]),
      isDirector: true,
      minAmount: 50000000,
    ),
  ];

  static InvestorCategory of(num? amount) {
    final a = amount ?? 0;
    for (final tier in tiers.reversed) {
      if (a >= tier.minAmount) return tier;
    }
    return regular;
  }
}
