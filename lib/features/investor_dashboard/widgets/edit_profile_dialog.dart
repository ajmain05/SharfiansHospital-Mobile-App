import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/network/cloudinary_uploader.dart';
import '../../../models/investor.dart';
import '../../investor_auth/providers/investor_session_provider.dart';

/// Self-service profile edit — photo, address, nominee info, donation % —
/// direct and immediate (no admin approval), same as the fields this already
/// covered server-side before this screen existed. See backend
/// `PUT /investors/public-update/:id`.
class EditProfileDialog {
  const EditProfileDialog._();

  static Future<void> show(BuildContext context, {required Investor account}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(account: account),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final Investor account;
  const _EditProfileSheet({required this.account});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final _addressCtrl = TextEditingController(text: widget.account.address);
  late final _nomineeNameCtrl = TextEditingController(text: widget.account.nomineeName ?? '');
  late final _nomineeRelationCtrl = TextEditingController(text: widget.account.nomineeRelation ?? '');
  late final _nomineePhoneCtrl = TextEditingController(text: widget.account.nomineePhone ?? '');
  late final _nomineeNidCtrl = TextEditingController(text: widget.account.nomineeNid ?? '');
  late final _nomineeAddressCtrl = TextEditingController(text: widget.account.nomineeAddress ?? '');
  late final _charityCtrl = TextEditingController(
    text: widget.account.charityPercentage != null ? widget.account.charityPercentage.toString() : '',
  );
  late final _emailCtrl = TextEditingController(text: widget.account.email ?? '');
  late final _etinCtrl = TextEditingController(text: widget.account.etinNo ?? '');
  late String? _gender = widget.account.gender;
  late DateTime? _dob = widget.account.dateOfBirth;

  late String? _photoUrl = widget.account.photoUrl;
  bool _photoUploading = false;
  double _photoProgress = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _addressCtrl,
      _nomineeNameCtrl,
      _nomineeRelationCtrl,
      _nomineePhoneCtrl,
      _nomineeNidCtrl,
      _nomineeAddressCtrl,
      _charityCtrl,
      _emailCtrl,
      _etinCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final file = File(picked.path);
    if (await file.length() > 5 * 1024 * 1024) {
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
        folder: 'investor_photos',
        onProgress: (p) => setState(() => _photoProgress = p),
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
    if (!_addressCtrl.text.trim().isNotEmpty) {
      setState(() => _error = t(ref, 'addressRequired'));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final updated = await ref.read(investorRepositoryProvider).updatePublicProfile(
        widget.account.id,
        {
          'phone': widget.account.phone,
          'address': _addressCtrl.text.trim(),
          'photo_url': _photoUrl,
          'nominee_name': _nomineeNameCtrl.text.trim(),
          'nominee_relation': _nomineeRelationCtrl.text.trim(),
          'nominee_phone': _nomineePhoneCtrl.text.trim(),
          'nominee_nid': _nomineeNidCtrl.text.trim(),
          'nominee_address': _nomineeAddressCtrl.text.trim(),
          if (_charityCtrl.text.trim().isNotEmpty)
            'charity_percentage': num.tryParse(_charityCtrl.text.trim()),
          'email': _emailCtrl.text.trim(),
          'gender': _gender,
          'date_of_birth': _dob?.toIso8601String(),
          'etin_no': _etinCtrl.text.trim(),
        },
      );
      await ref.read(investorSessionProvider.notifier).updateActiveAccountProfile(updated);
      if (!mounted) return;
      Navigator.of(context).pop();
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
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                        color: const Color(0xFF316BF3).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.manage_accounts_rounded, color: Color(0xFF316BF3), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        t(ref, 'editProfileTitle'),
                        style: GoogleFonts.libreCaslonText(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
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
                    t(ref, 'editProfileBody'),
                    style: GoogleFonts.publicSans(fontSize: 13, height: 1.5, color: colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 20),

                // Photo
                Row(
                  children: [
                    GestureDetector(
                      onTap: _photoUploading ? null : _pickPhoto,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF316BF3).withValues(alpha: 0.3), width: 2),
                          color: const Color(0xFF316BF3).withValues(alpha: 0.05),
                        ),
                        child: ClipOval(
                          child: _photoUrl != null
                              ? Image.network(
                                  _photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.person_outline, color: Color(0xFF316BF3), size: 28),
                                )
                              : const Icon(Icons.person_outline, color: Color(0xFF316BF3), size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: _photoUploading ? null : _pickPhoto,
                      child: Text(
                        _photoUploading
                            ? '${t(ref, 'uploading')} ${(_photoProgress * 100).round()}%'
                            : (_photoUrl != null ? t(ref, 'changePhoto') : t(ref, 'uploadPhoto')),
                        style: GoogleFonts.publicSans(fontWeight: FontWeight.w700, color: const Color(0xFF316BF3), fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(t(ref, 'addressLabel'), style: GoogleFonts.publicSans(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                const SizedBox(height: 8),
                _field(colorScheme, controller: _addressCtrl, maxLines: 2),
                const SizedBox(height: 20),

                Text(t(ref, 'additionalDetailsSectionTitle'), style: GoogleFonts.publicSans(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                const SizedBox(height: 8),
                _field(colorScheme, controller: _emailCtrl, hint: t(ref, 'email'), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _genderDropdown(colorScheme),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _dobField(colorScheme)),
                  ],
                ),
                const SizedBox(height: 10),
                _field(colorScheme, controller: _etinCtrl, hint: t(ref, 'etinNo')),
                const SizedBox(height: 20),

                Text(t(ref, 'nomineeInfoSectionTitle'), style: GoogleFonts.publicSans(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                const SizedBox(height: 8),
                _field(colorScheme, controller: _nomineeNameCtrl, hint: t(ref, 'nomineeNameHint')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(colorScheme, controller: _nomineeRelationCtrl, hint: t(ref, 'relationHint'))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(
                        colorScheme,
                        controller: _nomineePhoneCtrl,
                        hint: t(ref, 'phoneHint'),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _field(colorScheme, controller: _nomineeNidCtrl, hint: t(ref, 'nidOptionalHint')),
                const SizedBox(height: 10),
                _field(colorScheme, controller: _nomineeAddressCtrl, maxLines: 2, hint: t(ref, 'nomineeAddressHint')),
                const SizedBox(height: 20),

                if (widget.account.investorType != 'Donor') ...[
                  Text(t(ref, 'donationPercentLabel'), style: GoogleFonts.publicSans(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  _field(
                    colorScheme,
                    controller: _charityCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 20),
                ],

                if (_error != null) ...[
                  Text(_error!, style: GoogleFonts.publicSans(color: colorScheme.error, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 12),
                ],

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        child: Text(t(ref, 'cancel'), style: GoogleFonts.publicSans(fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: (_submitting || _photoUploading) ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF316BF3),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _submitting
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(t(ref, 'saveChanges'), style: GoogleFonts.publicSans(fontWeight: FontWeight.w700)),
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

  Widget _genderDropdown(ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      initialValue: _gender,
      isExpanded: true,
      style: GoogleFonts.publicSans(fontSize: 14, color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: t(ref, 'gender'),
        hintStyle: GoogleFonts.publicSans(color: colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      items: [
        DropdownMenuItem(value: 'Male', child: Text(t(ref, 'male'))),
        DropdownMenuItem(value: 'Female', child: Text(t(ref, 'female'))),
      ],
      onChanged: (val) => setState(() => _gender = val),
    );
  }

  Widget _dobField(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dob ?? DateTime(1990, 1, 1),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _dob = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          _dob != null
              ? '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}'
              : t(ref, 'dateOfBirth'),
          style: GoogleFonts.publicSans(
            fontSize: 14,
            color: _dob != null ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _field(
    ColorScheme colorScheme, {
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.publicSans(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.publicSans(color: colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}
