import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'about_screen.dart';
import 'contact_us_screen.dart';
import 'investment_guidelines_screen.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          children: [
            Text(
              'Settings & Info',
              textAlign: TextAlign.center,
              style: GoogleFonts.publicSans(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Manage your preferences and guidelines',
              textAlign: TextAlign.center,
              style: GoogleFonts.publicSans(
                fontSize: 15,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 36),
            const _SectionHeader(title: 'Information'),
            const SizedBox(height: 16),
            _SettingsTile(
              icon: Icons.corporate_fare_rounded,
              title: 'About Sharfian',
              subtitle: 'Vision, mission, and company profile',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.verified_user_rounded,
              title: 'Investment Guidelines',
              subtitle: 'Directorship rules and minimums',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InvestmentGuidelinesScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.contact_phone_rounded,
              title: 'Contact Us',
              subtitle: 'Phone, email, and address',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                );
              },
            ),
            const SizedBox(height: 36),
            const _SectionHeader(title: 'Preferences'),
            const SizedBox(height: 16),
            _SettingsTile(
              icon: Icons.public_rounded,
              title: 'Language',
              subtitle: 'Change app language (En/Bn)',
              onTap: () => _showLanguagePicker(context, ref),
            ),
            const SizedBox(height: 12),
            _ThemeToggleTile(
              icon: Icons.dark_mode_rounded,
              title: 'Theme Appearance',
              subtitle: 'Toggle dark or light mode',
            ),
          ],
        ),
      ),
    );
  }
}

void _showLanguagePicker(BuildContext context, WidgetRef ref) {
  final current = ref.read(localeProvider).languageCode;
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Text(
                  'Select Language',
                  style: GoogleFonts.publicSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              _LanguageOption(
                label: 'English',
                selected: current == 'en',
                onTap: () {
                  ref.read(localeProvider.notifier).set('en');
                  Navigator.of(sheetContext).pop();
                },
              ),
              _LanguageOption(
                label: 'বাংলা (Bangla)',
                selected: current == 'bn',
                onTap: () {
                  ref.read(localeProvider.notifier).set('bn');
                  Navigator.of(sheetContext).pop();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(
        label,
        style: GoogleFonts.publicSans(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 16,
          color: selected ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
          : null,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.publicSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: colorScheme.primary,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

BoxDecoration _tileDecoration(ColorScheme colorScheme) => BoxDecoration(
      color: colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    );

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: _tileDecoration(colorScheme),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 26),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.publicSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.publicSans(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colorScheme.outlineVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeToggleTile extends ConsumerWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ThemeToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final mode = ref.watch(themeProvider);
    // ThemeMode.system resolves to whatever the OS brightness is — reflect
    // that here too, so the switch always matches what's actually on screen
    // instead of only recognizing an explicit ThemeMode.dark.
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _tileDecoration(colorScheme),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 26),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.publicSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.publicSans(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            activeThumbColor: colorScheme.primary,
            // Always sets an explicit mode matching exactly what the switch
            // will show next — no more "toggle twice to actually get light"
            // when the previous state was ThemeMode.system.
            onChanged: (dark) => ref
                .read(themeProvider.notifier)
                .setMode(dark ? ThemeMode.dark : ThemeMode.light),
          ),
        ],
      ),
    );
  }
}
