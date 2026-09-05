import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/network/cloudinary_uploader.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/theme/adaptive_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/investor_category.dart';
import '../../../core/widgets/language_toggle_button.dart';
import '../../investor_auth/providers/investor_session_provider.dart';
import '../../settings/providers/site_settings_provider.dart';

// Combines a country dial code with a locally-typed number into E.164 form.
// Strips a single leading trunk '0' if present — the shape investors are
// used to typing for BD numbers ('01712345678') and the shape most other
// countries' domestic mobile numbers use too (e.g. UK '07123456789') — so
// concatenating it straight onto the dial code would produce a spurious
// extra digit rather than the correct '+8801712345678' / '+447123456789'.
String _buildE164Phone(String dialCode, String rawNumber) {
  final digits = rawNumber.replaceAll(RegExp(r'\D'), '');
  final trimmed = digits.startsWith('0') ? digits.substring(1) : digits;
  return '$dialCode$trimmed';
}

class InvestorRegistrationScreen extends ConsumerStatefulWidget {
  const InvestorRegistrationScreen({super.key});

  @override
  ConsumerState<InvestorRegistrationScreen> createState() =>
      _InvestorRegistrationScreenState();
}

class _InvestorRegistrationScreenState
    extends ConsumerState<InvestorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  String _investorType = 'Individual';
  final _orgNameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _fatherCtrl = TextEditingController();
  final _motherCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _phoneDialCode = '+880';
  final _emailCtrl = TextEditingController();
  final _nidCtrl = TextEditingController();
  final _etinCtrl = TextEditingController();
  final _nationalityCtrl = TextEditingController(text: 'Bangladeshi');
  final _occupationCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _educationLevelCtrl = TextEditingController();
  final _passingYearCtrl = TextEditingController();
  final _shareCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _personsCtrl = TextEditingController(text: '1');
  final _nomineeNameCtrl = TextEditingController();
  final _nomineeRelationCtrl = TextEditingController();
  final _nomineePhoneCtrl = TextEditingController();
  final _nomineeNidCtrl = TextEditingController();
  final _nomineeAddressCtrl = TextEditingController();
  final _charityCtrl = TextEditingController();

  bool _loading = false;
  bool _donorConsent = false;
  Map<String, dynamic>? _submitted;
  String _lastValidCharity = '';

  String? _eduCategory;
  String? _gender;
  DateTime? _dob;
  String? _photoUrl;
  bool _photoUploading = false;
  double _photoProgress = 0;
  bool _shareQuantitySyncing = false;

  static const _degreeOptions = {
    'Madrasa': [
      'Ponchom (5th)',
      'Oshtom (8th)',
      'Dakhil',
      'Alim',
      'Fazil',
      'Kamil',
      'Dawra-e-Hadith',
      'Takhassus / Mufti',
      'PhD',
    ],
    'General': [
      'SSC',
      'HSC',
      'Honours / Degree',
      'BSc / BBA',
      'MSc / MBA',
      'Masters',
      'MPhil',
      'PhD',
      'Post-Doctorate',
    ],
    'Medical': [
      'MBBS',
      'BDS',
      'MD',
      'MS',
      'FCPS',
      'MCPS',
      'MRCP',
      'FRCS',
      'DHMS',
      'Diploma',
      'MPhil (Medical)',
      'MPH',
    ],
  };

  @override
  void initState() {
    super.initState();
    _shareCtrl.addListener(_onShareAmountChanged);
    _quantityCtrl.addListener(_onShareQuantityChanged);
    _charityCtrl.addListener(_onCharityChanged);
  }

  num get _pricePerShare => ref.read(siteSettingsProvider).maybeWhen(
    data: (s) => s.pricePerShare,
    orElse: () => InvestorCategory.defaultPricePerShare,
  );

  // Bidirectional Share Amount <-> Share Quantity. Flutter's addListener
  // fires on ANY text change including programmatic ones, so both
  // directions need this guard to avoid infinite re-entry — without it,
  // writing into _quantityCtrl here would re-trigger _onShareQuantityChanged,
  // which would write back into _shareCtrl, forever.
  void _onShareAmountChanged() {
    if (_shareQuantitySyncing) return;
    setState(() {});
    final share = num.tryParse(_shareCtrl.text) ?? 0;
    final price = _pricePerShare;
    _shareQuantitySyncing = true;
    if (share > 0 && price > 0) {
      final qty = share / price;
      final text = qty == qty.roundToDouble()
          ? qty.round().toString()
          : qty.toStringAsFixed(2);
      _quantityCtrl.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    } else {
      _quantityCtrl.clear();
    }
    _shareQuantitySyncing = false;
  }

  // Quantity -> Amount is always exact (quantity is meant to be a whole
  // share count), unlike Amount -> Quantity which may show a fractional,
  // in-progress value.
  void _onShareQuantityChanged() {
    if (_shareQuantitySyncing) return;
    final qty = num.tryParse(_quantityCtrl.text) ?? 0;
    final price = _pricePerShare;
    _shareQuantitySyncing = true;
    if (qty > 0 && price > 0) {
      final text = (qty * price).round().toString();
      _shareCtrl.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    } else {
      _shareCtrl.clear();
    }
    _shareQuantitySyncing = false;
    setState(() {});
  }

  // Rejects the keystroke that would push the value over 100 — silently,
  // no popup, since the field's label already states the 0-100% range up
  // front (see donationPercentage in the translation files) rather than
  // relying on a reactive error every time someone types past it.
  void _onCharityChanged() {
    final text = _charityCtrl.text;
    if (text.isEmpty) {
      _lastValidCharity = text;
      return;
    }
    final value = num.tryParse(text);
    if (value == null || value > 100) {
      _charityCtrl.value = TextEditingValue(
        text: _lastValidCharity,
        selection: TextSelection.collapsed(offset: _lastValidCharity.length),
      );
      return;
    }
    _lastValidCharity = text;
  }

  @override
  void dispose() {
    for (final c in [
      _orgNameCtrl,
      _nameCtrl,
      _fatherCtrl,
      _motherCtrl,
      _phoneCtrl,
      _emailCtrl,
      _nidCtrl,
      _etinCtrl,
      _nationalityCtrl,
      _occupationCtrl,
      _addressCtrl,
      _educationLevelCtrl,
      _passingYearCtrl,
      _shareCtrl,
      _quantityCtrl,
      _personsCtrl,
      _nomineeNameCtrl,
      _nomineeRelationCtrl,
      _nomineePhoneCtrl,
      _nomineeNidCtrl,
      _nomineeAddressCtrl,
      _charityCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  num get _share => num.tryParse(_shareCtrl.text) ?? 0;
  // Frozen — always ৳21,00,000, independent of pricePerShare and the
  // cosmetic InvestorCategory tier. This is the real cutoff
  // computeFields() applies server-side (backend/routes/investors.js) —
  // never derive it from InvestorCategory, or this preview could show a
  // duration/payment that doesn't match what the server actually assigns
  // the moment pricePerShare is ever edited away from its default.
  num get _durationMonths => _share >= 2100000 ? 12 : 36;
  num get _monthlyPayment =>
      _share > 0 ? (_share / _durationMonths).ceil() : 0;
  bool get _isWholeShare {
    if (_share == 0) return true;
    final qty = _share / _pricePerShare;
    return (qty - qty.roundToDouble()).abs() < 1e-6;
  }

  // The submit button lives in a pinned `Scaffold.bottomSheet`, which a
  // default/theme-floating SnackBar doesn't know to avoid — it renders right
  // on top of the button. Explicit margin lifts it clear.
  void _showErrorSnackBar(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 100,
        ),
        backgroundColor: colorScheme.error,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      _showErrorSnackBar(context, t(ref, 'photoTooLarge'));
      return;
    }
    setState(() {
      _photoUploading = true;
      _photoProgress = 0;
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
      _showErrorSnackBar(context, t(ref, 'photoUploadFailed'));
    } finally {
      if (mounted) setState(() => _photoUploading = false);
    }
  }

  Future<void> _submit(num minShareAmount) async {
    if (!_formKey.currentState!.validate()) return;
    if (_gender == null) {
      _showErrorSnackBar(context, t(ref, 'genderRequired'));
      return;
    }
    if (_dob == null) {
      _showErrorSnackBar(context, t(ref, 'dobRequired'));
      return;
    }
    if (_share < minShareAmount) {
      _showErrorSnackBar(
        context,
        t(
          ref,
          'minimumShareError',
          params: {'amount': Formatters.number(minShareAmount)},
        ),
      );
      return;
    }
    if (!_isWholeShare) {
      _showErrorSnackBar(
        context,
        t(
          ref,
          'wholeShareError',
          params: {'price': Formatters.number(_pricePerShare)},
        ),
      );
      return;
    }
    if (_investorType == 'Donor' && !_donorConsent) {
      _showErrorSnackBar(context, t(ref, 'donorConsentRequired'));
      return;
    }
    setState(() => _loading = true);
    try {
      final payload = {
        'photo_url': _photoUrl,
        'investor_type': _investorType,
        if (_investorType == 'Organization')
          'organization_name': _orgNameCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'father_name': _fatherCtrl.text.trim(),
        'mother_name': _motherCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'phone': _buildE164Phone(_phoneDialCode, _phoneCtrl.text),
        'gender': _gender,
        if (_emailCtrl.text.trim().isNotEmpty)
          'email': _emailCtrl.text.trim(),
        'date_of_birth': _dob!.toIso8601String(),
        'nid_no': _nidCtrl.text.trim(),
        'nationality': _nationalityCtrl.text.trim(),
        'occupation': _occupationCtrl.text.trim(),
        if (_etinCtrl.text.trim().isNotEmpty)
          'etin_no': _etinCtrl.text.trim(),
        'share_amount': _share,
        'number_of_persons': int.tryParse(_personsCtrl.text) ?? 1,
        if (_educationLevelCtrl.text.trim().isNotEmpty)
          'education_level': _educationLevelCtrl.text.trim(),
        if (_passingYearCtrl.text.trim().isNotEmpty)
          'passing_year': int.tryParse(_passingYearCtrl.text.trim()),
        if (_investorType != 'Organization') ...{
          'nominee_name': _nomineeNameCtrl.text.trim(),
          'nominee_relation': _nomineeRelationCtrl.text.trim(),
          'nominee_phone': _nomineePhoneCtrl.text.trim(),
          if (_nomineeNidCtrl.text.trim().isNotEmpty)
            'nominee_nid': _nomineeNidCtrl.text.trim(),
          'nominee_address': _nomineeAddressCtrl.text.trim(),
        },
        if (_investorType == 'Donor')
          'charity_percentage': 100
        else if (_charityCtrl.text.trim().isNotEmpty)
          'charity_percentage': num.tryParse(_charityCtrl.text.trim()),
      };
      final result = await ref
          .read(investorRepositoryProvider)
          .register(payload);

      // Attach this phone to the device's push token now that it belongs to
      // a real investor — otherwise this device stays invisible to any
      // phone-targeted push until the investor separately logs into My
      // Portal on it.
      ref.read(pushNotificationServiceProvider).registerToken(phone: _phoneCtrl.text.trim());

      if (!mounted) return;
      setState(() => _submitted = result);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(siteSettingsProvider);
    final minShareAmount = settingsAsync.maybeWhen(
      data: (s) => s.minShareAmount,
      orElse: () => 100000,
    );
    final tutorialVideoUrl = settingsAsync.maybeWhen(
      data: (s) => s.tutorialVideoUrl,
      orElse: () => '',
    );

    if (_submitted != null) {
      return _SuccessView(
        submitted: _submitted!,
        onRegisterAnother: () => setState(() => _submitted = null),
      );
    }

    return Scaffold(
      backgroundColor: context.bgFill, // surface
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Brand Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                      top: 60,
                      left: 24,
                      right: 24,
                      bottom: 80,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF316BF3), Color(0xFF1E40AF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => context.go('/'),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                            ),
                            const LanguageToggleButton(),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          t(ref, 'investorRegistration'),
                          style: GoogleFonts.libreCaslonText(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Join us in shaping the future. Begin your investment journey today.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content Area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Transform.translate(
                      // The -40 overlap is designed around the video CTA
                      // card absorbing it (it floats up over the hero's
                      // rounded bottom edge). Without that card — e.g. site
                      // settings hasn't finished loading yet, or no tutorial
                      // video is configured — there's nothing to absorb the
                      // shift and it drags the Individual/Organization tabs
                      // straight into the hero box instead.
                      offset: Offset(0, tutorialVideoUrl.isNotEmpty ? -40 : 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Video CTA
                          if (tutorialVideoUrl.isNotEmpty) ...[
                            GestureDetector(
                              onTap: () async {
                                final url = Uri.parse(tutorialVideoUrl);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } else if (context.mounted) {
                                  _showErrorSnackBar(
                                    context,
                                    'Could not open video URL.',
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: context.cardFill,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: context.borderFill),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: context.primaryTint,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Color(0xFF316BF3),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'How to Register?',
                                            style: GoogleFonts.libreCaslonText(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: context.textHigh,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            t(ref, 'howToRegisterWatchVideo'),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: context.textHigh,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Entity Toggle
                                _TypeToggle(
                                  value: _investorType,
                                  onChanged: (v) =>
                                      setState(() => _investorType = v),
                                ),
                                const SizedBox(height: 24),

                                // Profile Photo — centered avatar with a
                                // camera-badge overlay (the familiar
                                // Instagram/WhatsApp-style profile-photo
                                // picker) instead of a plain bordered circle
                                // beside a text label.
                                Center(
                                  child: GestureDetector(
                                    onTap: _photoUploading ? null : _pickPhoto,
                                    child: Column(
                                      children: [
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Container(
                                              width: 96,
                                              height: 96,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: _photoUrl == null
                                                    ? LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                        colors: [
                                                          const Color(0xFF316BF3).withValues(alpha: 0.12),
                                                          const Color(0xFF316BF3).withValues(alpha: 0.04),
                                                        ],
                                                      )
                                                    : null,
                                                border: Border.all(
                                                  color: const Color(0xFF316BF3).withValues(alpha: 0.25),
                                                  width: 2.5,
                                                ),
                                              ),
                                              child: ClipOval(
                                                child: _photoUrl != null
                                                    ? Image.network(
                                                        _photoUrl!,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) =>
                                                            const Icon(Icons.person_rounded, color: Color(0xFF316BF3), size: 40),
                                                      )
                                                    : (_photoUploading
                                                        ? const Padding(
                                                            padding: EdgeInsets.all(28),
                                                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF316BF3)),
                                                          )
                                                        : const Icon(Icons.person_rounded, color: Color(0xFF316BF3), size: 40)),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: const Color(0xFF316BF3),
                                                  border: Border.all(color: context.bgFill, width: 3),
                                                ),
                                                child: const Icon(
                                                  Icons.camera_alt_rounded,
                                                  color: Colors.white,
                                                  size: 15,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _photoUploading
                                                  ? '${t(ref, 'uploading')} ${(_photoProgress * 100).round()}%'
                                                  : (_photoUrl != null ? t(ref, 'changePhoto') : t(ref, 'uploadPhoto')),
                                              style: GoogleFonts.publicSans(
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF316BF3),
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (!_photoUploading) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                '(${t(ref, 'optional')})',
                                                style: GoogleFonts.publicSans(
                                                  fontSize: 12,
                                                  color: context.textMed,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          t(ref, 'photoRequirementsHint'),
                                          style: GoogleFonts.publicSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: context.textMed,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Personal Info Section
                                _EditorialSection(
                                  title: 'Personal Details',
                                  icon: Icons.badge_outlined,
                                  children: [
                                    if (_investorType == 'Organization')
                                      _BespokeField(
                                        controller: _orgNameCtrl,
                                        label: t(ref, 'organizationName'),
                                        icon: Icons.domain,
                                        isRequired: true,
                                      ),
                                    _BespokeField(
                                      controller: _nameCtrl,
                                      label: _investorType == 'Organization'
                                          ? t(ref, 'representativeFullName')
                                          : t(ref, 'fullName'),
                                      icon: Icons.person_outline,
                                      placeholder: 'Enter your full name',
                                      isRequired: true,
                                    ),
                                    _BespokeField(
                                      controller: _fatherCtrl,
                                      label: t(ref, 'fathersName'),
                                      icon: Icons.family_restroom,
                                      placeholder: 'Enter father\'s name',
                                      isRequired: true,
                                    ),
                                    _BespokeField(
                                      controller: _motherCtrl,
                                      label: t(ref, 'mothersName'),
                                      icon: Icons.family_restroom,
                                      placeholder: 'Enter mother\'s name',
                                      isRequired: true,
                                    ),
                                    _PhoneBespokeField(
                                      controller: _phoneCtrl,
                                      label: t(ref, 'phoneNumber'),
                                      icon: Icons.phone_iphone,
                                      placeholder: '01XXXXXXXXX',
                                      dialCode: _phoneDialCode,
                                      locale: ref.watch(localeProvider),
                                      onDialCodeChanged: (code) =>
                                          setState(() => _phoneDialCode = code),
                                    ),
                                    _PickerFormField(
                                      label: t(ref, 'gender'),
                                      icon: Icons.wc_outlined,
                                      value: _gender,
                                      options: {
                                        'Male': t(ref, 'male'),
                                        'Female': t(ref, 'female'),
                                      },
                                      onChanged: (val) {
                                        setState(() => _gender = val);
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _DatePickerField(
                                      label: t(ref, 'dateOfBirth'),
                                      icon: Icons.cake_outlined,
                                      value: _dob,
                                      onChanged: (val) {
                                        setState(() => _dob = val);
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _BespokeField(
                                      controller: _nidCtrl,
                                      label: t(ref, 'nidNo'),
                                      icon: Icons.badge_outlined,
                                      placeholder: 'National ID number',
                                      isRequired: true,
                                    ),
                                    _BespokeField(
                                      controller: _emailCtrl,
                                      label: t(ref, 'email'),
                                      icon: Icons.email_outlined,
                                      placeholder: 'name@example.com',
                                      keyboardType: TextInputType.emailAddress,
                                      isOptional: true,
                                    ),
                                    _BespokeField(
                                      controller: _nationalityCtrl,
                                      label: t(ref, 'nationality'),
                                      icon: Icons.public_outlined,
                                      placeholder: 'e.g. Bangladeshi',
                                      isRequired: true,
                                    ),
                                    _BespokeField(
                                      controller: _occupationCtrl,
                                      label: t(ref, 'occupation'),
                                      icon: Icons.work_outline,
                                      placeholder: 'e.g. Doctor, Businessman, Student',
                                      isRequired: true,
                                    ),
                                    _BespokeField(
                                      controller: _etinCtrl,
                                      label: t(ref, 'etinNo'),
                                      icon: Icons.receipt_long_outlined,
                                      placeholder: 'Electronic Tax Identification Number',
                                      isOptional: true,
                                    ),
                                    _BespokeField(
                                      controller: _addressCtrl,
                                      label: t(ref, 'address'),
                                      icon: Icons.location_on_outlined,
                                      placeholder: 'Enter detailed address',
                                      isRequired: true,
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      t(ref, 'educationBackground'),
                                      style: GoogleFonts.publicSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: context.textMed,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _PickerFormField(
                                      label: t(ref, 'educationCategory'),
                                      icon: Icons.category_outlined,
                                      value: _eduCategory,
                                      options: const {
                                        'Madrasa': 'Madrasa Education',
                                        'General': 'General Education',
                                        'Medical': 'Medical Degrees',
                                        'Other': 'Other',
                                      },
                                      onChanged: (val) {
                                        setState(() {
                                          _eduCategory = val;
                                          _educationLevelCtrl.clear();
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    if (_eduCategory != null &&
                                        _eduCategory != 'Other')
                                      _PickerFormField(
                                        label: t(ref, 'degreeLevel'),
                                        icon: Icons.school_outlined,
                                        value: _educationLevelCtrl.text.isEmpty
                                            ? null
                                            : _educationLevelCtrl.text,
                                        options: {
                                          for (final e
                                              in _degreeOptions[_eduCategory]!)
                                            e: e,
                                        },
                                        onChanged: (val) {
                                          setState(() {
                                            _educationLevelCtrl.text = val;
                                          });
                                        },
                                      )
                                    else if (_eduCategory == 'Other')
                                      _BespokeField(
                                        controller: _educationLevelCtrl,
                                        label: t(ref, 'degreeLevel'),
                                        icon: Icons.school_outlined,
                                        placeholder: 'Enter your degree',
                                      ),
                                    _BespokeField(
                                      controller: _passingYearCtrl,
                                      label: t(ref, 'passingYear'),
                                      icon: Icons.calendar_today_outlined,
                                      placeholder: 'YYYY',
                                      keyboardType: TextInputType.number,
                                      isOptional: true,
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.only(top: 24),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          top: BorderSide(
                                            color: context.borderFill,
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Investment Details',
                                            style: GoogleFonts.libreCaslonText(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: context.textHigh,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          _InfoAlertCard(
                                            icon: Icons.info_outline,
                                            accent: const Color(0xFF3B82F6),
                                            bgColor: context.primaryTint,
                                            title: '',
                                            content: 'Minimum required investment is ${Formatters.bdt(minShareAmount)}',
                                          ),
                                          const SizedBox(height: 24),
                                          _BespokeField(
                                            controller: _shareCtrl,
                                            label: t(ref, 'shareAmountBdt'),
                                            icon: Icons.payments_outlined,
                                            placeholder: '0',
                                            isRequired: true,
                                            keyboardType: TextInputType.number,
                                            isLarge: true,
                                            isPrimary: true,
                                          ),
                                          _BespokeField(
                                            controller: _quantityCtrl,
                                            label: t(ref, 'shareQuantityLabel'),
                                            icon: Icons.pie_chart_outline,
                                            placeholder: t(
                                              ref,
                                              'shareQuantityHint',
                                              params: {
                                                'qty': Formatters.number(
                                                  (minShareAmount / _pricePerShare)
                                                      .round(),
                                                ),
                                              },
                                            ),
                                            keyboardType: TextInputType.number,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            child: Text(
                                              t(
                                                ref,
                                                'oneShareEquals',
                                                params: {
                                                  'price': Formatters.number(
                                                    _pricePerShare,
                                                  ),
                                                },
                                              ),
                                              style: GoogleFonts.publicSans(
                                                fontSize: 12,
                                                color: context.textMed,
                                              ),
                                            ),
                                          ),
                                          _BespokeField(
                                            controller: _personsCtrl,
                                            label: t(ref, 'numberOfPersons'),
                                            icon: Icons.group_outlined,
                                            isRequired: true,
                                            keyboardType: TextInputType.number,
                                          ),
                                          _InfoAlertCard(
                                            icon: Icons.verified_outlined,
                                            accent: const Color(0xFF0EA5E9),
                                            bgColor: const Color(0xFFF0F9FF),
                                            title: 'Why ৳${Formatters.number(_pricePerShare)} per share?',
                                            content: t(
                                              ref,
                                              'sharePricingTrustInfo',
                                              params: {
                                                'total': Formatters.number(
                                                  settingsAsync.maybeWhen(
                                                    data: (s) => s.totalRegisteredShares,
                                                    orElse: () => 10000000,
                                                  ),
                                                ),
                                                'price': Formatters.number(_pricePerShare),
                                                'face': Formatters.number(
                                                  settingsAsync.maybeWhen(
                                                    data: (s) => s.shareFaceValue,
                                                    orElse: () => 100,
                                                  ),
                                                ),
                                                'premium': Formatters.number(
                                                  _pricePerShare -
                                                      settingsAsync.maybeWhen(
                                                        data: (s) => s.shareFaceValue,
                                                        orElse: () => 100,
                                                      ),
                                                ),
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Nominee Info Section
                                if (_investorType != 'Organization')
                                  _EditorialSection(
                                    title: 'Nominee Information',
                                    children: [
                                      _BespokeField(
                                        controller: _nomineeNameCtrl,
                                        label: t(ref, 'nomineeName'),
                                        icon: Icons.person_outline,
                                        placeholder: 'Enter nominee name',
                                        isRequired: _investorType == 'Individual',
                                        isOptional: _investorType != 'Individual',
                                      ),
                                      _BespokeField(
                                        controller: _nomineeRelationCtrl,
                                        label: t(ref, 'nomineeRelation'),
                                        icon: Icons.diversity_1,
                                        placeholder: 'Relation with nominee',
                                        isRequired: _investorType == 'Individual',
                                        isOptional: _investorType != 'Individual',
                                      ),
                                      _BespokeField(
                                        controller: _nomineePhoneCtrl,
                                        label: t(ref, 'nomineePhone'),
                                        icon: Icons.phone_outlined,
                                        placeholder: '+880',
                                        isRequired: _investorType == 'Individual',
                                        isOptional: _investorType != 'Individual',
                                        keyboardType: TextInputType.phone,
                                      ),
                                      _BespokeField(
                                        controller: _nomineeNidCtrl,
                                        label: t(ref, 'nomineeNid'),
                                        icon: Icons.badge_outlined,
                                        placeholder: 'ID Number',
                                        isOptional: true,
                                      ),
                                      _BespokeField(
                                        controller: _nomineeAddressCtrl,
                                        label: t(ref, 'nomineeAddress'),
                                        icon: Icons.home_outlined,
                                        placeholder: 'Enter nominee address',
                                        isRequired: _investorType == 'Individual',
                                        isOptional: _investorType != 'Individual',
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),

                                // Charity Section
                                if (_investorType != 'Donor')
                                  _EditorialSection(
                                    title: 'Charitable Contribution',
                                    bgColor: context.isDark
                                        ? context.cardFill2
                                        : const Color(0xFFFAFAF9),
                                    borderColor: context.isDark
                                        ? context.borderFill
                                        : const Color(0xFFE7E5E4),
                                    headerContent: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        margin: const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: context.isDark
                                              ? Colors.red.withValues(alpha: 0.15)
                                              : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: context.isDark
                                                ? Colors.red.withValues(
                                                    alpha: 0.3,
                                                  )
                                                : Colors.red.shade100,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.volunteer_activism,
                                          color: Colors.red.shade400,
                                          size: 24,
                                        ),
                                      ),
                                      Text(
                                        t(ref, 'charityDesc'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: context.textMed,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                    children: [
                                      _BespokeField(
                                        controller: _charityCtrl,
                                        label: t(ref, 'donationPercentage'),
                                        placeholder: '0',
                                        keyboardType: TextInputType.number,
                                        isOptional: true,
                                      ),
                                    ],
                                  ),

                                // Donor 100%-charity consent
                                if (_investorType == 'Donor')
                                  _EditorialSection(
                                    title: t(ref, 'donorConsentTitle'),
                                    bgColor: context.isDark
                                        ? Colors.red.withValues(alpha: 0.08)
                                        : Colors.red.shade50,
                                    borderColor: context.isDark
                                        ? Colors.red.withValues(alpha: 0.3)
                                        : Colors.red.shade100,
                                    headerContent: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        margin: const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: context.isDark
                                              ? Colors.red.withValues(alpha: 0.15)
                                              : Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: context.isDark
                                                ? Colors.red.withValues(
                                                    alpha: 0.3,
                                                  )
                                                : Colors.red.shade200,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.volunteer_activism,
                                          color: Colors.red.shade400,
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                    children: [
                                      Text(
                                        t(ref, 'donorConsentBody'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: context.textMed,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: context.cardFill,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: context.isDark
                                                ? Colors.red.withValues(alpha: 0.3)
                                                : Colors.red.shade200,
                                          ),
                                        ),
                                        child: CheckboxListTile(
                                          value: _donorConsent,
                                          onChanged: (v) => setState(
                                            () => _donorConsent = v ?? false,
                                          ),
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          activeColor: Colors.red.shade400,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          title: Text(
                                            t(ref, 'donorConsentCheckbox'),
                                            style: GoogleFonts.publicSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: context.textHigh,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                // Live Calculator
                                _LiveCalculatorCard(
                                  share: _share,
                                  monthlyPayment: _monthlyPayment,
                                ),
                                const SizedBox(height: 24),
                                SafeArea(
                                  top: false,
                                  child: GestureDetector(
                                    onTap: _loading
                                        ? null
                                        : () => _submit(minShareAmount),
                                    child: Container(
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF316BF3),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF316BF3,
                                            ).withValues(alpha: 0.3),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _loading
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : Text(
                                                'Become an Investor',
                                                style: GoogleFonts.publicSans(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

class _EditorialSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  final List<Widget>? headerContent;
  final Color? bgColor;
  final Color? borderColor;

  const _EditorialSection({
    required this.title,
    required this.children,
    this.icon,
    this.headerContent,
    this.bgColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor ?? context.cardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (icon != null)
            Positioned(
              top: -20,
              right: -20,
              child: Icon(
                icon,
                size: 100,
                color: Colors.black.withValues(alpha: 0.03),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (headerContent != null) ...headerContent!,
              Text(
                title,
                style: GoogleFonts.libreCaslonText(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.textHigh,
                ),
              ),
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        ],
      ),
    );
  }
}

/// A tappable field styled like the app's rounded/filled inputs that opens a
/// bottom-sheet picker instead of the stock (unstyled) dropdown menu.
class _PickerFormField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final Map<String, String> options; // internal value -> display label
  final ValueChanged<String> onChanged;

  const _PickerFormField({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Text(
                    label,
                    style: GoogleFonts.publicSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: options.entries.map((entry) {
                      final isSelected = entry.key == value;
                      return ListTile(
                        onTap: () => Navigator.of(sheetContext).pop(entry.key),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        title: Text(
                          entry.value,
                          style: GoogleFonts.publicSans(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 16,
                            color: isSelected ? cs.primary : cs.onSurface,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: cs.primary,
                              )
                            : null,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: context.textMed),
          suffixIcon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.textMed,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.borderFill),
          ),
          filled: true,
          fillColor: context.cardFill2,
        ),
        child: Text(
          value != null ? (options[value] ?? value!) : '',
          style: GoogleFonts.publicSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.textHigh,
          ),
        ),
      ),
    );
  }
}

/// A tappable field styled to match _PickerFormField, opening the platform
/// date picker instead of a bottom sheet — used for Date of Birth.
class _DatePickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  Future<void> _openPicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) onChanged(picked);
  }

  String _format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: context.textMed),
          suffixIcon: Icon(
            Icons.calendar_today_outlined,
            color: context.textMed,
            size: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.borderFill),
          ),
          filled: true,
          fillColor: context.cardFill2,
        ),
        child: Text(
          value != null ? _format(value!) : '',
          style: GoogleFonts.publicSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.textHigh,
          ),
        ),
      ),
    );
  }
}

class _BespokeField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? placeholder;
  final bool isRequired;
  final bool isOptional;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool isLarge;
  final bool isPrimary;

  const _BespokeField({
    required this.controller,
    required this.label,
    this.icon,
    this.placeholder,
    this.isRequired = false,
    this.isOptional = false,
    this.keyboardType,
    this.maxLines = 1,
    this.isLarge = false,
    this.isPrimary = false,
  });

  @override
  State<_BespokeField> createState() => _BespokeFieldState();
}

class _BespokeFieldState extends State<_BespokeField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: _isFocused
                      ? const Color(0xFF316BF3)
                      : context.textMed, // slate-600
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Row(
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.publicSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _isFocused
                            ? const Color(0xFF316BF3)
                            : (widget.isPrimary
                                  ? const Color(0xFF316BF3)
                                  : context.textHigh), // slate-900 crisp
                      ),
                    ),
                    if (widget.isOptional)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          '(Optional)',
                          style: GoogleFonts.publicSans(
                            fontSize: 12,
                            color: context.textMed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            style: GoogleFonts.publicSans(
              fontSize: widget.isLarge ? 20 : 15,
              fontWeight: widget.isLarge ? FontWeight.w600 : FontWeight.w500,
              color: widget.isPrimary
                  ? const Color(0xFF316BF3)
                  : context.textHigh,
            ),
            decoration: InputDecoration(
              filled: false,
              hintText: widget.placeholder,
              hintStyle: GoogleFonts.publicSans(
                color: widget.isPrimary
                    ? const Color(0xFF316BF3).withValues(alpha: 0.5)
                    : context.textMed, // slate-500
                fontSize: widget.isLarge ? 20 : 15,
                fontWeight: widget.isLarge ? FontWeight.w600 : FontWeight.w500,
              ),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: context.borderFill),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.borderFill),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF316BF3), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              isDense: true,
            ),
            validator: widget.isRequired
                ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
                : null,
          ),
        ],
      ),
    );
  }
}

/// Same icon/label/underline chrome as [_BespokeField], but with a country
/// dial-code picker (flag + calling code) ahead of the number input, so
/// investors can register with a non-Bangladeshi number. Kept as its own
/// widget rather than extending _BespokeField with an optional prefix slot,
/// since only this one field needs it.
class _PhoneBespokeField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? placeholder;
  final String dialCode;
  final Locale locale;
  final ValueChanged<String> onDialCodeChanged;

  const _PhoneBespokeField({
    required this.controller,
    required this.label,
    this.icon,
    this.placeholder,
    required this.dialCode,
    required this.locale,
    required this.onDialCodeChanged,
  });

  @override
  State<_PhoneBespokeField> createState() => _PhoneBespokeFieldState();
}

class _PhoneBespokeFieldState extends State<_PhoneBespokeField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF316BF3);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: _isFocused ? activeColor : context.textMed,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _isFocused ? activeColor : context.textHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _isFocused ? activeColor : context.borderFill,
                  width: _isFocused ? 2 : 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, right: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final picked = await _showCountryPickerSheet(
                        context,
                        widget.locale,
                      );
                      if (picked != null) {
                        widget.onDialCodeChanged(picked.dialCode ?? '+880');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.dialCode,
                            style: GoogleFonts.publicSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: context.textHigh,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: context.textMed,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.publicSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: context.textHigh,
                    ),
                    decoration: InputDecoration(
                      filled: false,
                      hintText: widget.placeholder,
                      hintStyle: GoogleFonts.publicSans(
                        color: context.textMed,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Converts a 2-letter ISO country code to its flag emoji via Unicode Regional
// Indicator Symbols (e.g. "BD" -> 🇧🇩) — each letter A-Z maps to one of 26
// reserved codepoints starting at U+1F1E6, so a country code becomes the two
// corresponding symbols side by side, which every current iOS/Android emoji
// font already renders as the actual flag. No image assets or flag library
// needed, and — unlike the CountryCodePicker's own flag rendering used
// earlier — nothing here sits inside a box the OS or browser can draw its
// own border/background onto.
String _flagEmoji(String? countryCode) {
  if (countryCode == null || countryCode.length != 2) return '';
  return countryCode
      .toUpperCase()
      .codeUnits
      .map((c) => String.fromCharCode(c + 127397))
      .join();
}

Future<CountryCode?> _showCountryPickerSheet(
  BuildContext context,
  Locale locale,
) {
  return showModalBottomSheet<CountryCode>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Localizations.override(
      context: sheetContext,
      locale: locale,
      delegates: const [CountryLocalizations.delegate],
      child: const _CountryPickerSheet(),
    ),
  );
}

/// The country selector, redesigned to match a supplied mockup: a header
/// with a title and round close button, an always-highlighted search field,
/// and a scrollable list where each row pairs an emoji flag + country name
/// on the left with its dial code in a pill on the right.
class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  static const _royal = Color(0xFF316BF3);

  late final List<CountryCode> _allCountries = codes
      .map((c) => CountryCode.fromJson(c))
      .toList();
  late List<CountryCode> _filtered = _allCountries;
  final _searchCtrl = TextEditingController();

  String _nameFor(CountryCode c) =>
      CountryLocalizations.of(context)?.translate(c.code) ?? c.name ?? '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final term = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = term.isEmpty
          ? _allCountries
          : _allCountries.where((c) {
              final name = _nameFor(c).toLowerCase();
              final dial = (c.dialCode ?? '').toLowerCase();
              return name.contains(term) || dial.contains(term);
            }).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaHeight = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Container(
        height: mediaHeight * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Country',
                    style: GoogleFonts.publicSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: false,
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Search country or code',
                  hintStyle: GoogleFonts.publicSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _royal, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _royal, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF1D55E0), width: 2),
                  ),
                ),
              ),
            ),
            // List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: _filtered.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFFF8FAFC)),
                itemBuilder: (context, index) {
                  final country = _filtered[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).pop(country),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  _flagEmoji(country.code),
                                  style: const TextStyle(fontSize: 24, height: 1),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _nameFor(country),
                                    style: GoogleFonts.publicSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              country.dialCode ?? '',
                              style: GoogleFonts.publicSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bordered, left-accented info card — shared by the "Minimum required
/// investment" and "Why ৳X per share?" boxes so they can never drift out of
/// visual sync. High-contrast by design (a saturated 1.4px border + bold,
/// dark-slate body text) rather than the earlier pale/thin-text version,
/// which read as washed out against the light tinted background.
class _InfoAlertCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color bgColor;
  final String title;
  final String content;

  const _InfoAlertCard({
    required this.icon,
    required this.accent,
    required this.bgColor,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.4),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.1), blurRadius: 14, offset: const Offset(0, 5)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: accent.withValues(alpha: 0.18), shape: BoxShape.circle),
                        child: Icon(icon, color: accent, size: 19),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (title.isNotEmpty) ...[
                              Text(
                                title,
                                style: GoogleFonts.publicSans(fontWeight: FontWeight.w800, color: accent, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              content,
                              style: GoogleFonts.publicSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _TypeToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Pill segmented control (mirrors the website's Register.jsx toggle —
    // gray-100 track, white raised pill for the selected segment, each type
    // keeping its own accent color) instead of a plain underline-tab, so the
    // two platforms feel consistent and the selection reads at a glance.
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segment(
              context,
              type: 'Individual',
              icon: Icons.person_rounded,
              label: 'Individual',
              accent: const Color(0xFF316BF3),
              isSelected: value == 'Individual',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _segment(
              context,
              type: 'Organization',
              icon: Icons.domain_rounded,
              label: 'Organization',
              accent: const Color(0xFF059669),
              isSelected: value == 'Organization',
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _segment(
              context,
              type: 'Donor',
              icon: Icons.favorite_rounded,
              label: 'Donor',
              accent: const Color(0xFFE11D48),
              isSelected: value == 'Donor',
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context, {
    required String type,
    required IconData icon,
    required String label,
    required Color accent,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? context.cardFill2 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? accent : context.textMed,
              size: 18,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.publicSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? accent : context.textMed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveCalculatorCard extends ConsumerWidget {
  final num share;
  final num monthlyPayment;

  const _LiveCalculatorCard({
    required this.share,
    required this.monthlyPayment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pricePerShare = ref.watch(siteSettingsProvider).maybeWhen(
      data: (s) => s.pricePerShare,
      orElse: () => InvestorCategory.defaultPricePerShare,
    );
    final category = InvestorCategory.of(share, pricePerShare: pricePerShare);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.borderFill),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.primaryTint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.primaryTintBorder),
                ),
                child: const Icon(
                  Icons.query_stats,
                  color: Color(0xFF316BF3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Investment Projection',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.textHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Projected Share Amount',
            style: GoogleFonts.publicSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.textHigh,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.bdt(share),
            style: GoogleFonts.libreCaslonText(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF316BF3),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: context.borderFill),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Payment',
                      style: GoogleFonts.publicSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: context.textHigh,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        monthlyPayment > 0 ? Formatters.bdt(monthlyPayment) : '—',
                        maxLines: 1,
                        style: GoogleFonts.publicSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.textHigh,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duration',
                      style: GoogleFonts.publicSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: context.textHigh,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        share > 0
                            ? (category.isDirector
                                ? t(ref, 'oneYear')
                                : t(ref, 'threeYears'))
                            : '—',
                        maxLines: 1,
                        style: GoogleFonts.publicSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.textHigh,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Account Status',
                style: GoogleFonts.publicSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.textHigh,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? Colors.green.withValues(alpha: 0.15)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.isDark
                        ? Colors.green.withValues(alpha: 0.3)
                        : const Color(0xFFD1FAE5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399), // emerald-400
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      category.isDirector ? '⭐ ${category.label}' : 'Regular',
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends ConsumerWidget {
  final Map<String, dynamic> submitted;
  final VoidCallback onRegisterAnother;

  const _SuccessView({
    required this.submitted,
    required this.onRegisterAnother,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(siteSettingsProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final helpText = settingsAsync.maybeWhen(
      data: (s) => lang == 'bn' ? s.registerHelpTextBn : s.registerHelpText,
      orElse: () => t(ref, 'registerHelpText'),
    );

    return Scaffold(
      backgroundColor: context.bgFill,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardFill,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Column(
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Lottie.asset(
                          'assets/animations/Success.json',
                          repeat: false,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF316BF3),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF316BF3,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t(ref, 'registrationSuccessful'),
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: context.textHigh,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t(ref, 'registrationSuccessSubtitle'),
                        style: GoogleFonts.publicSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: context.textHigh,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Digital Investor Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF316BF3), Color(0xFF1E3A8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.badge_rounded,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  t(ref, 'digitalInvestorCard').toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              t(ref, 'yourInvestorId'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: double.infinity,
                              height: 28,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  (submitted['investor_id'] ?? '').toString(),
                                  maxLines: 1,
                                  style: GoogleFonts.robotoMono(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Monthly',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      Formatters.bdt(
                                        submitted['monthly_payment'] as num?,
                                      ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    (submitted['status'] ?? '')
                                        .toString()
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Info Note
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.primaryTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.info_outline,
                            color: Color(0xFF316BF3),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            helpText,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textHigh,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onRegisterAnother,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: context.borderFill,
                              width: 2,
                            ),
                          ),
                          icon: Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 16,
                            color: context.textHigh,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              t(ref, 'registerAnother'),
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: context.textHigh,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF316BF3),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(
                            Icons.home_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              t(ref, 'goHome'),
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
