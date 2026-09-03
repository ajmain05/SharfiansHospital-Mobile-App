import 'package:flutter/material.dart';

/// Direct port of the website's `utils/investorCategory.js` tier thresholds,
/// so DIRECTOR badges match exactly between the app and the website.
///
/// IMPORTANT — this is a DIFFERENT concept from the real Director-vs-Regular
/// classification (`Investor.status`/`monthlyPayment`/`totalMonths`, decided
/// server-side by a FROZEN ৳21,00,000 amount cutoff — see
/// backend/routes/investors.js's computeFields()). That cutoff must never be
/// derived from `pricePerShare` or [minQuantity] below — today they coincide
/// exactly (6000 shares × ৳350 = ৳21,00,000), but the moment `pricePerShare`
/// is ever edited away from 350, only this cosmetic badge is meant to move.
/// Code predicting real payment duration (e.g. the registration screen's
/// pre-submit preview) must use the frozen amount directly, not this class.
///
/// The backend has no CMS field for these thresholds — the website itself
/// hardcodes them the same way (`investorCategory.js`/`DirectorshipTable.jsx`).
/// [tiers] is the single source of truth other screens (FAQ directorship
/// table, Investment Guidelines) should read from instead of re-typing the
/// share counts, so they can't drift out of sync with each other again.
class InvestorCategory {
  final String id;
  final String label;
  final Color color;
  final Gradient gradient;
  final bool isDirector;
  final num minQuantity;

  const InvestorCategory({
    required this.id,
    required this.label,
    required this.color,
    required this.gradient,
    required this.isDirector,
    required this.minQuantity,
  });

  /// Taka amount this tier's share-quantity threshold represents at a given
  /// price — for display only (Investment Guidelines, FAQ table), never for
  /// classification.
  num minAmountFor(num pricePerShare) => minQuantity * pricePerShare;

  static const InvestorCategory regular = InvestorCategory(
    id: 'regular',
    label: 'Regular Investor',
    color: Color(0xFF047857),
    gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF0D9488)]),
    isDirector: false,
    minQuantity: 0,
  );

  /// Ascending order: silver, golden, platinum, diamond. Fixed regulatory
  /// share-count policy (not admin-editable, unlike pricePerShare) — kept in
  /// sync with backend/utils/investorTier.js's TIER_MIN_QUANTITY and the
  /// website's investorCategory.js.
  static const List<InvestorCategory> tiers = [
    InvestorCategory(
      id: 'silver',
      label: 'Silver Director',
      color: Color(0xFF374151),
      gradient: LinearGradient(colors: [Color(0xFF9CA3AF), Color(0xFF64748B)]),
      isDirector: true,
      minQuantity: 6000,
    ),
    InvestorCategory(
      id: 'golden',
      label: 'Golden Director',
      color: Color(0xFFB45309),
      gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFF97316)]),
      isDirector: true,
      minQuantity: 15000,
    ),
    InvestorCategory(
      id: 'platinum',
      label: 'Platinum Director',
      color: Color(0xFF334155),
      gradient: LinearGradient(colors: [Color(0xFF64748B), Color(0xFF334155)]),
      isDirector: true,
      minQuantity: 30000,
    ),
    InvestorCategory(
      id: 'diamond',
      label: 'Diamond Director',
      color: Color(0xFF0E7490),
      gradient: LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF2563EB)]),
      isDirector: true,
      minQuantity: 145000,
    ),
  ];

  static const num defaultPricePerShare = 350;

  /// [tierOverride] is a superadmin-only prestige override
  /// (`Investor.tierOverride`) — when set, it wins over the quantity-based
  /// computation entirely for display purposes (this function only ever
  /// returns the badge to show). It never affects shareAmount, but the
  /// backend does recompute status/monthlyPayment/totalMonths from it —
  /// callers needing real financial standing should keep reading those
  /// fields (`Investor.status`/`monthlyPayment`/`totalMonths`) directly,
  /// not this tier.
  static InvestorCategory of(
    num? amount, {
    String? tierOverride,
    num pricePerShare = defaultPricePerShare,
  }) {
    if (tierOverride != null) {
      if (tierOverride == regular.id) return regular;
      for (final tier in tiers) {
        if (tier.id == tierOverride) return tier;
      }
    }
    final price = pricePerShare > 0 ? pricePerShare : defaultPricePerShare;
    final quantity = (amount ?? 0) / price;
    for (final tier in tiers.reversed) {
      if (quantity >= tier.minQuantity) return tier;
    }
    return regular;
  }
}
