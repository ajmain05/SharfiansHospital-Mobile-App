import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../investor_auth/providers/investor_session_provider.dart';

/// Reason values are kept in fixed English regardless of app locale, so the
/// admin dashboard (Bengali-first) always sees a consistent, structured set
/// of reasons rather than a mix of languages. Only the on-screen label is
/// translated.
const _reasonValues = [
  'No longer interested in investing',
  'Privacy concerns',
  'Duplicate account',
  'Other',
];

const _reasonLabelKeys = {
  'No longer interested in investing': 'reasonNotInterested',
  'Privacy concerns': 'reasonPrivacyConcerns',
  'Duplicate account': 'reasonDuplicateAccount',
  'Other': 'reasonOther',
};

/// Submitting this request does NOT revoke portal access — the investor
/// keeps full access until a superadmin actually approves it from the admin
/// dashboard. See backend `POST /investors/:id/request-deletion`.
class DeleteAccountDialog {
  const DeleteAccountDialog._();

  static Future<void> show(
    BuildContext context, {
    required String investorId,
    required String phone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _DeleteAccountSheet(investorId: investorId, phone: phone),
    );
  }
}

class _DeleteAccountSheet extends ConsumerStatefulWidget {
  final String investorId;
  final String phone;

  const _DeleteAccountSheet({required this.investorId, required this.phone});

  @override
  ConsumerState<_DeleteAccountSheet> createState() =>
      _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  final _detailsCtrl = TextEditingController();
  String? _reason;
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) {
      setState(() => _error = t(ref, 'selectReasonError'));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(investorRepositoryProvider)
          .requestAccountDeletion(
            id: widget.investorId,
            phone: widget.phone,
            reason: _reason!,
            details: _detailsCtrl.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            t(ref, 'deletionRequestSubmittedTitle'),
            style: GoogleFonts.publicSans(fontWeight: FontWeight.w700),
          ),
          content: Text(
            t(ref, 'deletionRequestSubmittedBody'),
            style: GoogleFonts.publicSans(fontSize: 14, height: 1.4),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(t(ref, 'ok')),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _reasonOption(ColorScheme colorScheme, String value) {
    final selected = _reason == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() {
            _reason = value;
            _error = null;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.08)
                  : colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? colorScheme.primary : colorScheme.outline,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t(ref, _reasonLabelKeys[value]!),
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_remove_rounded,
                        color: Color(0xFFEF4444),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        t(ref, 'deleteAccountDialogTitle'),
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    t(ref, 'deleteAccountDialogBody'),
                    style: GoogleFonts.publicSans(
                      fontSize: 13,
                      height: 1.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  t(ref, 'deletionReasonLabel'),
                  style: GoogleFonts.publicSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                ..._reasonValues.map((v) => _reasonOption(colorScheme, v)),
                const SizedBox(height: 16),
                Text(
                  t(ref, 'deletionDetailsLabel'),
                  style: GoogleFonts.publicSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _detailsCtrl,
                  maxLines: 3,
                  style: GoogleFonts.publicSans(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: t(ref, 'deletionDetailsHint'),
                    hintStyle: GoogleFonts.publicSans(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLowest,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: GoogleFonts.publicSans(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        child: Text(
                          t(ref, 'cancel'),
                          style: GoogleFonts.publicSans(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                t(ref, 'submitRequest'),
                                style: GoogleFonts.publicSans(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
