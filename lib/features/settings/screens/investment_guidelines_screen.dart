import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/l10n/locale_provider.dart';

class InvestmentGuidelinesScreen extends ConsumerWidget {
  const InvestmentGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Investment Guidelines',
          style: GoogleFonts.publicSans(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildAlertBox(
            context,
            'Minimum Investment',
            'To become an investor in Sharfians Hospital, a minimum commitment of ${Formatters.bdt(100000)} is required.',
            Icons.info_outline_rounded,
            const Color(0xFFEFF6FF), // blue-50
            const Color(0xFF3B82F6), // blue-500
          ),
          const SizedBox(height: 32),
          Text(
            'Directorship Tiers',
            style: GoogleFonts.libreCaslonText(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildTierCard(
            context,
            title: 'Gold Director',
            shareAmount: 1000000,
            benefits: [
              'Voting rights in general board meetings',
              'Special healthcare discounts for family',
              'Priority appointment scheduling',
            ],
            gradient: const LinearGradient(
              colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
            ),
            iconColor: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 16),
          _buildTierCard(
            context,
            title: 'Platinum Director',
            shareAmount: 5000000,
            benefits: [
              'Executive voting rights',
              'Free annual comprehensive health checkups',
              'VIP hospital suite access',
              'Strategic decision making involvement',
            ],
            gradient: const LinearGradient(
              colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8)],
            ),
            iconColor: const Color(0xFF64748B),
          ),
          const SizedBox(height: 32),
          Text(
            'Terms & Conditions',
            style: GoogleFonts.libreCaslonText(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildTermRule(context, '1. All investments are bound by the Shariah-compliant profit and loss sharing agreement.'),
          _buildTermRule(context, '2. Shares cannot be transferred within the first year of acquisition without board approval.'),
          _buildTermRule(context, '3. Directorship status is reviewed annually and is contingent upon maintaining the minimum share threshold.'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAlertBox(BuildContext context, String title, String content, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.publicSans(
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.publicSans(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard(BuildContext context, {required String title, required num shareAmount, required List<String> benefits, required Gradient gradient, required Color iconColor}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.publicSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Icon(Icons.stars_rounded, color: const Color(0xFF1E293B).withValues(alpha: 0.7)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Requirement',
                  style: GoogleFonts.publicSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.bdt(shareAmount),
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Benefits',
                  style: GoogleFonts.publicSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                ...benefits.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_rounded, color: iconColor, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b,
                          style: GoogleFonts.publicSans(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermRule(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.publicSans(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }
}
