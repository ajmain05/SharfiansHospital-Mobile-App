import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/site_settings.dart';
import '../providers/site_settings_provider.dart';

class ContactUsScreen extends ConsumerWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsAsync = ref.watch(siteSettingsProvider);
    final fallback = SiteSettings.fallback();
    final settings = settingsAsync.maybeWhen(
      data: (s) => s,
      orElse: () => fallback,
    );

    final hasAny = settings.contactPhone.isNotEmpty ||
        settings.contactEmail.isNotEmpty ||
        settings.contactAddress.isNotEmpty ||
        settings.socialFacebook.isNotEmpty ||
        settings.socialYoutube.isNotEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Contact Us',
          style: GoogleFonts.publicSans(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: !hasAny
          ? Center(
              child: Text(
                'Contact details are not available right now.',
                textAlign: TextAlign.center,
                style: GoogleFonts.publicSans(
                  fontSize: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              children: [
                if (settings.contactPhone.isNotEmpty)
                  _ContactTile(
                    icon: Icons.call_rounded,
                    label: 'Phone',
                    value: settings.contactPhone,
                    onTap: () => _launchTel(context, settings.contactPhone),
                  ),
                if (settings.contactEmail.isNotEmpty)
                  _ContactTile(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    value: settings.contactEmail,
                    onTap: () => _launchEmail(context, settings.contactEmail),
                  ),
                if (settings.contactAddress.isNotEmpty)
                  _ContactTile(
                    icon: Icons.location_on_rounded,
                    label: 'Address',
                    value: settings.contactAddress,
                  ),
                if (settings.socialFacebook.isNotEmpty)
                  _ContactTile(
                    icon: Icons.facebook_rounded,
                    label: 'Facebook',
                    value: settings.socialFacebook,
                    onTap: () => _launchExternal(context, settings.socialFacebook),
                  ),
                if (settings.socialYoutube.isNotEmpty)
                  _ContactTile(
                    icon: Icons.smart_display_rounded,
                    label: 'YouTube',
                    value: settings.socialYoutube,
                    onTap: () => _launchExternal(context, settings.socialYoutube),
                  ),
              ],
            ),
    );
  }
}

Future<void> _launchTel(BuildContext context, String phone) async {
  final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
  await _tryLaunch(context, Uri(scheme: 'tel', path: cleanPhone));
}

Future<void> _launchEmail(BuildContext context, String email) async {
  await _tryLaunch(context, Uri(scheme: 'mailto', path: email));
}

Future<void> _launchExternal(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await _tryLaunch(context, uri, mode: LaunchMode.externalApplication);
}

// Same try/catch + boolean-check + SnackBar-on-failure pattern already used
// for the tel: link on event_detail_screen.dart.
Future<void> _tryLaunch(
  BuildContext context,
  Uri uri, {
  LaunchMode mode = LaunchMode.platformDefault,
}) async {
  try {
    final launched = await launchUrl(uri, mode: mode);
    if (!launched && context.mounted) {
      _showLaunchFailure(context);
    }
  } catch (_) {
    if (context.mounted) _showLaunchFailure(context);
  }
}

void _showLaunchFailure(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('This isn\'t supported on your device (or simulator).'),
    ),
  );
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: GoogleFonts.publicSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        style: GoogleFonts.publicSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: value));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Copied ✓',
                            style: GoogleFonts.publicSans(fontWeight: FontWeight.w600),
                          ),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.copy_rounded, size: 18, color: colorScheme.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
