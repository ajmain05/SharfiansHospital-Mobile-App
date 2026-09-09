import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/network/cloudinary_uploader.dart';
import '../../../core/theme/adaptive_colors.dart';
import '../../../core/theme/app_colors.dart';
import '../../investor_auth/providers/investor_session_provider.dart';
import '../providers/support_provider.dart';
import 'support_list_screen.dart';

// Fallback only — the real, possibly admin-edited list comes from
// supportCategoriesProvider (see build() below).
const _kDefaultCategoryIds = [
  'payment',
  'share_certificate',
  'account_update',
  'technical',
  'complaint',
  'general',
  'other',
];

class NewTicketScreen extends ConsumerStatefulWidget {
  const NewTicketScreen({super.key});

  @override
  ConsumerState<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends ConsumerState<NewTicketScreen> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String? _category;
  String? _photoUrl;
  bool _photoUploading = false;
  double _photoProgress = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    final file = File(picked.path);
    if (await file.length() > 5 * 1024 * 1024) {
      if (!mounted) return;
      setState(() => _error = t(ref, 'photoTooLarge'));
      return;
    }
    setState(() {
      _photoUploading = true;
      _photoProgress = 0;
      _error = null;
    });
    try {
      final url = await CloudinaryUploader.upload(
        file,
        folder: 'support_attachments',
        onProgress: (p) {
          if (mounted) setState(() => _photoProgress = p);
        },
      );
      if (!mounted) return;
      setState(() => _photoUrl = url);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = t(ref, 'photoUploadFailed'));
    } finally {
      if (mounted) setState(() => _photoUploading = false);
    }
  }

  Future<void> _submit() async {
    if (_category == null) {
      setState(() => _error = t(ref, 'supportValidationCategoryRequired'));
      return;
    }
    if (_messageCtrl.text.trim().isEmpty) {
      setState(() => _error = t(ref, 'supportValidationMessageRequired'));
      return;
    }
    final investorId = ref.read(investorSessionProvider).activeAccount?.id;
    if (investorId == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(supportRepositoryProvider)
          .createTicket(
            investorId: investorId,
            category: _category!,
            subject: _subjectCtrl.text,
            message: _messageCtrl.text,
            attachmentUrl: _photoUrl,
          );
      ref.invalidate(supportTicketsProvider);
      if (!mounted) return;
      context.pop();
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            t(ref, 'supportSubmitSuccessTitle'),
            style: GoogleFonts.publicSans(fontWeight: FontWeight.w700),
          ),
          content: Text(
            t(ref, 'supportSubmitSuccessBody'),
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
      // ApiException.toString() is just its message (the backend's own
      // reason, e.g. an invalid-category/attachment rejection) — same
      // pattern as increase_share_dialog.dart, so a validation error is
      // actually actionable instead of a generic "failed" with no reason.
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedCategoryIds = ref
        .watch(supportCategoriesProvider)
        .maybeWhen(
          data: (list) => list.isNotEmpty
              ? list.map((c) => c.id).toList()
              : _kDefaultCategoryIds,
          orElse: () => _kDefaultCategoryIds,
        );
    // If the category list resolves (or an admin edits it) to something that
    // no longer includes whatever the user already picked from the
    // pre-resolve fallback, its chip would otherwise just vanish from the
    // row with no explanation for why their selection is no longer visibly
    // highlighted. Keeping the current pick in the list defensively (even if
    // the "official" list no longer has it) avoids that without needing to
    // silently clear the user's selection mid-form.
    final categoryIds =
        (_category != null && !resolvedCategoryIds.contains(_category))
        ? [...resolvedCategoryIds, _category!]
        : resolvedCategoryIds;
    return Scaffold(
      backgroundColor: context.bgFill,
      appBar: AppBar(
        backgroundColor: context.cardFill,
        elevation: 0,
        leading: BackButton(
          color: context.textHigh,
          onPressed: () => context.pop(),
        ),
        title: Text(
          t(ref, 'newQuery'),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.textHigh,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              t(ref, 'supportCategoryLabel'),
              style: GoogleFonts.publicSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.textHigh,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                for (var i = 0; i < categoryIds.length; i += 2)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i + 2 < categoryIds.length ? 10 : 0,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _CategoryChip(
                              icon: _categoryIcon(categoryIds[i]),
                              label: supportCategoryLabel(ref, categoryIds[i]),
                              selected: _category == categoryIds[i],
                              onTap: () =>
                                  setState(() => _category = categoryIds[i]),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: i + 1 < categoryIds.length
                                ? _CategoryChip(
                                    icon: _categoryIcon(categoryIds[i + 1]),
                                    label: supportCategoryLabel(
                                      ref,
                                      categoryIds[i + 1],
                                    ),
                                    selected: _category == categoryIds[i + 1],
                                    onTap: () => setState(
                                      () => _category = categoryIds[i + 1],
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              t(ref, 'supportSubjectLabel'),
              style: GoogleFonts.publicSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.textHigh,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectCtrl,
              style: GoogleFonts.publicSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: t(ref, 'supportSubjectHint'),
                hintStyle: GoogleFonts.publicSans(color: context.textLow),
                filled: true,
                fillColor: context.cardFill3,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t(ref, 'supportMessageLabel'),
              style: GoogleFonts.publicSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.textHigh,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageCtrl,
              minLines: 4,
              maxLines: 8,
              style: GoogleFonts.publicSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: t(ref, 'supportMessageHint'),
                hintStyle: GoogleFonts.publicSans(color: context.textLow),
                filled: true,
                fillColor: context.cardFill3,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t(ref, 'supportAttachPhoto'),
              style: GoogleFonts.publicSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.textHigh,
              ),
            ),
            const SizedBox(height: 8),
            if (_photoUrl != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      _photoUrl!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: t(ref, 'supportRemovePhoto'),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _photoUrl = null),
                      ),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _photoUploading ? null : _pickPhoto,
                icon: _photoUploading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: _photoProgress > 0 ? _photoProgress : null,
                        ),
                      )
                    : const Icon(Icons.add_a_photo_rounded, size: 18),
                label: Text(
                  t(ref, 'supportAttachPhoto'),
                  style: GoogleFonts.publicSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 14),
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
            FilledButton(
              // Also blocked while a photo is still uploading — submitting
              // mid-upload would create the ticket with _photoUrl still null,
              // silently dropping the attachment the user just picked.
              onPressed: (_submitting || _photoUploading) ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary700,
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
                      t(ref, 'supportSubmit'),
                      style: GoogleFonts.publicSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _categoryIcon(String id) {
  switch (id) {
    case 'payment':
      return Icons.payments_rounded;
    case 'share_certificate':
      return Icons.workspace_premium_rounded;
    case 'account_update':
      return Icons.manage_accounts_rounded;
    case 'technical':
      return Icons.build_rounded;
    case 'complaint':
      return Icons.report_problem_rounded;
    case 'general':
      return Icons.help_rounded;
    case 'other':
      return Icons.category_rounded;
    default:
      // Custom, admin-added category — no dedicated icon for it.
      return Icons.label_important_rounded;
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary700 : context.cardFill3,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary700 : context.borderFill,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? Colors.white : AppColors.primary700,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.publicSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : context.textHigh,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
