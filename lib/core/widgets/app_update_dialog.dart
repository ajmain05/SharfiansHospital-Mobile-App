import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/adaptive_colors.dart';

/// The nag shown when the admin-configured latest version (see the "App
/// Update Notice" section in the web admin's Homepage Content tab) is newer
/// than what's installed. "Update Later" just closes this instance — there's
/// no snooze state, so it reappears on every launch until the installed
/// version actually catches up.
Future<void> showAppUpdateDialog(
  BuildContext context, {
  required String latestVersion,
  required String storeUrl,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AppUpdateDialog(
      latestVersion: latestVersion,
      storeUrl: storeUrl,
    ),
  );
}

class AppUpdateDialog extends StatelessWidget {
  final String latestVersion;
  final String storeUrl;

  const AppUpdateDialog({
    super.key,
    required this.latestVersion,
    required this.storeUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 56),
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 12),
            decoration: BoxDecoration(
              color: context.cardFill,
              borderRadius: BorderRadius.circular(16),
              border: const Border(
                top: BorderSide(color: Color(0xFF316BF3), width: 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDark ? 0.4 : 0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New Update Available!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: context.textHigh,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Version $latestVersion is now available with improved performance and new features.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    color: context.textMed,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: context.textMed,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: const Text(
                            'Update Later',
                            maxLines: 1,
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: storeUrl.isEmpty
                            ? null
                            : () {
                                final uri = Uri.tryParse(storeUrl);
                                if (uri != null) {
                                  launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4F84FF),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: const Text(
                            'Update Now',
                            maxLines: 1,
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Circular logo avatar, overlapping the card's top edge.
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.cardFill,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDark ? 0.4 : 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}
