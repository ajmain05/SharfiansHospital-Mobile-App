import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/site_settings.dart';
import '../providers/site_settings_provider.dart';

const _whyInvestItems = [
  'Shariah-compliant framework',
  'Transparent fund management',
  'Directorship opportunities',
  'Community-driven growth',
];

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsAsync = ref.watch(siteSettingsProvider);
    final fallback = SiteSettings.fallback();
    final hospitalName = settingsAsync.maybeWhen(
      data: (s) => s.heroTitle,
      orElse: () => fallback.heroTitle,
    );
    final aboutTitle = settingsAsync.maybeWhen(
      data: (s) => s.aboutTitle,
      orElse: () => fallback.aboutTitle,
    );
    final aboutDescription = settingsAsync.maybeWhen(
      data: (s) => s.aboutDescription,
      orElse: () => fallback.aboutDescription,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'About Sharfian',
          style: GoogleFonts.publicSans(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          Center(
            child: Container(
              width: 124,
              height: 124,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.apartment_rounded,
                  size: 56,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            hospitalName,
            textAlign: TextAlign.center,
            style: GoogleFonts.libreCaslonText(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
              ),
              child: Text(
                'Shaping the Future of Healthcare',
                style: GoogleFonts.publicSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          _buildSection(
            context,
            aboutTitle,
            aboutDescription,
            Icons.info_outline_rounded,
          ),
          _buildSection(
            context,
            'Our Vision',
            'To establish a world-class, Shariah-compliant healthcare ecosystem that prioritizes human well-being over profit, ensuring accessible and premium medical services for everyone.',
            Icons.visibility_rounded,
          ),
          _buildSection(
            context,
            'Our Mission',
            'We aim to bridge the gap between ethical finance and advanced healthcare by creating an inclusive investment platform. Our hospital will serve with compassion, excellence, and transparency.',
            Icons.rocket_launch_rounded,
          ),
          _buildBulletSection(
            context,
            'Why Invest With Us?',
            _whyInvestItems,
            Icons.verified_rounded,
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Version 1.0.0',
              style: GoogleFonts.publicSans(
                fontSize: 12,
                color: colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(ColorScheme colorScheme) => BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );

  Widget _cardHeader(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.publicSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(colorScheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(context, title, icon),
          const SizedBox(height: 14),
          Text(
            content,
            style: GoogleFonts.publicSans(
              fontSize: 14.5,
              height: 1.65,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletSection(
    BuildContext context,
    String title,
    List<String> items,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(colorScheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(context, title, icon),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.publicSans(
                        fontSize: 14.5,
                        height: 1.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
