import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../investor_auth/providers/investor_session_provider.dart';

/// Submitting this does NOT change the investor's share amount yet — an
/// admin reviews and approves it from the dashboard first. See backend
/// `POST /investors/:id/request-share-increase`.
class IncreaseShareDialog {
  const IncreaseShareDialog._();

  static Future<void> show(
    BuildContext context, {
    required String investorId,
    required String phone,
    required num currentShareAmount,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IncreaseShareSheet(
        investorId: investorId,
        phone: phone,
        currentShareAmount: currentShareAmount,
      ),
    );
  }
}

class _IncreaseShareSheet extends ConsumerStatefulWidget {
  final String investorId;
  final String phone;
  final num currentShareAmount;

  const _IncreaseShareSheet({
    required this.investorId,
    required this.phone,
    required this.currentShareAmount,
  });

  @override
  ConsumerState<_IncreaseShareSheet> createState() =>
      _IncreaseShareSheetState();
}

class _IncreaseShareSheetState extends ConsumerState<_IncreaseShareSheet> {
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = num.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = t(ref, 'invalidAmountError'));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(investorRepositoryProvider)
          .requestShareIncrease(
            id: widget.investorId,
            phone: widget.phone,
            additionalAmount: amount,
            reason: _reasonCtrl.text,
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
            t(ref, 'shareIncreaseRequestSubmittedTitle'),
            style: GoogleFonts.publicSans(fontWeight: FontWeight.w700),
          ),
          content: Text(
            t(ref, 'shareIncreaseRequestSubmittedBody'),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
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
                        color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: Color(0xFF16A34A),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        t(ref, 'increaseShareDialogTitle'),
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
                    t(ref, 'increaseShareDialogBody'),
                    style: GoogleFonts.publicSans(
                      fontSize: 13,
                      height: 1.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t(ref, 'currentShareAmountLabel'),
                        style: GoogleFonts.publicSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        Formatters.bdt(widget.currentShareAmount),
                        style: GoogleFonts.publicSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  t(ref, 'additionalAmountLabel'),
                  style: GoogleFonts.publicSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.publicSans(fontSize: 16, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    prefixText: '৳ ',
                    prefixStyle: GoogleFonts.publicSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    hintText: t(ref, 'additionalAmountHint'),
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
                const SizedBox(height: 16),
                Text(
                  t(ref, 'increaseReasonLabel'),
                  style: GoogleFonts.publicSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonCtrl,
                  maxLines: 3,
                  style: GoogleFonts.publicSans(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: t(ref, 'increaseReasonHint'),
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
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            t(ref, 'cancel'),
                            maxLines: 1,
                            style: GoogleFonts.publicSans(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
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
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  t(ref, 'submitRequest'),
                                  maxLines: 1,
                                  style: GoogleFonts.publicSans(
                                    fontWeight: FontWeight.w700,
                                  ),
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
