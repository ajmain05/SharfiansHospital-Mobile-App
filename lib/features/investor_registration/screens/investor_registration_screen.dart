import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/investor_category.dart';
import '../../../core/widgets/language_toggle_button.dart';
import '../../investor_auth/providers/investor_session_provider.dart';
import '../../settings/providers/site_settings_provider.dart';

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
  final _addressCtrl = TextEditingController();
  final _educationLevelCtrl = TextEditingController();
  final _passingYearCtrl = TextEditingController();
  final _shareCtrl = TextEditingController();
  final _personsCtrl = TextEditingController(text: '1');
  final _nomineeNameCtrl = TextEditingController();
  final _nomineeRelationCtrl = TextEditingController();
  final _nomineePhoneCtrl = TextEditingController();
  final _nomineeNidCtrl = TextEditingController();
  final _nomineeAddressCtrl = TextEditingController();
  final _charityCtrl = TextEditingController();

  bool _loading = false;
  Map<String, dynamic>? _submitted;

  String? _eduCategory;

  static const _degreeOptions = {
    'Madrasa': ['Ponchom (5th)', 'Oshtom (8th)', 'Dakhil', 'Alim', 'Fazil', 'Kamil', 'Dawra-e-Hadith', 'Takhassus / Mufti', 'PhD'],
    'General': ['SSC', 'HSC', 'Honours / Degree', 'BSc / BBA', 'MSc / MBA', 'Masters', 'MPhil', 'PhD', 'Post-Doctorate'],
    'Medical': ['MBBS', 'BDS', 'MD', 'MS', 'FCPS', 'MCPS', 'MRCP', 'FRCS', 'Diploma', 'MPhil (Medical)', 'MPH']
  };

  @override
  void initState() {
    super.initState();
    _shareCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [
      _orgNameCtrl,
      _nameCtrl,
      _fatherCtrl,
      _motherCtrl,
      _phoneCtrl,
      _addressCtrl,
      _educationLevelCtrl,
      _passingYearCtrl,
      _shareCtrl,
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
  num get _monthlyPayment => _share > 0 ? (_share / 12).ceil() : 0;

  Future<void> _submit(num minShareAmount) async {
    if (!_formKey.currentState!.validate()) return;
    if (_share < minShareAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              ref,
              'minimumShareError',
              params: {'amount': Formatters.number(minShareAmount)},
            ),
          ),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final payload = {
        'investor_type': _investorType,
        if (_investorType == 'Organization')
          'organization_name': _orgNameCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'father_name': _fatherCtrl.text.trim(),
        'mother_name': _motherCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
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
        if (_charityCtrl.text.trim().isNotEmpty)
          'charity_percentage': num.tryParse(_charityCtrl.text.trim()),
      };
      final result = await ref
          .read(investorRepositoryProvider)
          .register(payload);
      if (!mounted) return;
      setState(() => _submitted = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
      backgroundColor: const Color(0xFFF8FAFC), // surface
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Brand Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 80),
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
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                      offset: const Offset(0, -40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Video CTA
                          if (tutorialVideoUrl.isNotEmpty) ...[
                            GestureDetector(
                              onTap: () async {
                                final url = Uri.parse(tutorialVideoUrl);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not open video URL.')),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
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
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEFF6FF), // blue-50
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.play_arrow, color: Color(0xFF316BF3), size: 28),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'How to Register?',
                                            style: GoogleFonts.libreCaslonText(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            t(ref, 'howToRegisterWatchVideo'),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF1E293B),
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
                                  onChanged: (v) => setState(() => _investorType = v),
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
                                    _BespokeField(
                                      controller: _phoneCtrl,
                                      label: t(ref, 'phoneNumber'),
                                      icon: Icons.phone_iphone,
                                      placeholder: '+880',
                                      isRequired: true,
                                      keyboardType: TextInputType.phone,
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
                                      t(ref, 'Education Background'),
                                      style: GoogleFonts.publicSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      value: _eduCategory,
                                      decoration: InputDecoration(
                                        labelText: t(ref, 'Education Category'),
                                        prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF64748B)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'Madrasa', child: Text('Madrasa Education')),
                                        DropdownMenuItem(value: 'General', child: Text('General Education')),
                                        DropdownMenuItem(value: 'Medical', child: Text('Medical Degrees')),
                                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                                      ],
                                      onChanged: (val) {
                                        setState(() {
                                          _eduCategory = val;
                                          _educationLevelCtrl.clear();
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    if (_eduCategory != null && _eduCategory != 'Other')
                                      DropdownButtonFormField<String>(
                                        value: _educationLevelCtrl.text.isEmpty ? null : _educationLevelCtrl.text,
                                        decoration: InputDecoration(
                                          labelText: t(ref, 'Degree / Level'),
                                          prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFF64748B)),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                        ),
                                        items: _degreeOptions[_eduCategory]!
                                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                            .toList(),
                                        onChanged: (val) {
                                          setState(() {
                                            _educationLevelCtrl.text = val ?? '';
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
                                      decoration: const BoxDecoration(
                                        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), style: BorderStyle.solid)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Investment Details',
                                            style: GoogleFonts.libreCaslonText(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF), // blue-50
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: const Color(0xFFBFDBFE)), // blue-200
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 20),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    'Minimum required investment is ${Formatters.bdt(minShareAmount)}',
                                                    style: GoogleFonts.publicSans(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFF1E3A8A), // blue-900
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
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
                                            controller: _personsCtrl,
                                            label: t(ref, 'numberOfPersons'),
                                            icon: Icons.group_outlined,
                                            isRequired: true,
                                            keyboardType: TextInputType.number,
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
                                        isRequired: true,
                                      ),
                                      _BespokeField(
                                        controller: _nomineeRelationCtrl,
                                        label: t(ref, 'nomineeRelation'),
                                        icon: Icons.diversity_1,
                                        placeholder: 'Relation with nominee',
                                        isRequired: true,
                                      ),
                                      _BespokeField(
                                        controller: _nomineePhoneCtrl,
                                        label: t(ref, 'nomineePhone'),
                                        icon: Icons.phone_outlined,
                                        placeholder: '+880',
                                        isRequired: true,
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
                                        isRequired: true,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),

                                // Charity Section
                                _EditorialSection(
                                  title: 'Charitable Contribution',
                                  bgColor: const Color(0xFFFAFAF9),
                                  borderColor: const Color(0xFFE7E5E4),
                                  headerContent: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.red.shade100),
                                      ),
                                      child: Icon(Icons.volunteer_activism, color: Colors.red.shade400, size: 24),
                                    ),
                                    Text(
                                      t(ref, 'charityDesc'),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF475569),
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                  children: [
                                    _BespokeField(
                                      controller: _charityCtrl,
                                      label: t(ref, 'donationPercentage'),
                                      icon: Icons.percent,
                                      placeholder: '0',
                                      keyboardType: TextInputType.number,
                                      isOptional: true,
                                    ),
                                  ],
                                ),

                                // Live Calculator
                                _LiveCalculatorCard(
                                  share: _share,
                                  monthlyPayment: _monthlyPayment,
                                ),
                                const SizedBox(height: 120), // Padding for the bottom nav
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

      // Submit Button (Pinned Bottom)
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: _loading ? null : () => _submit(minShareAmount),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF316BF3),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF316BF3).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Become an Investor',
                        style: GoogleFonts.publicSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorialSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  final List<Widget>? headerContent;
  final Color bgColor;
  final Color borderColor;

  const _EditorialSection({
    required this.title,
    required this.children,
    this.icon,
    this.headerContent,
    this.bgColor = Colors.white,
    this.borderColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
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
                  color: Color(0xFF0F172A),
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

class _BespokeField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
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
    required this.icon,
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
              Icon(
                widget.icon,
                size: 18,
                color: _isFocused
                    ? const Color(0xFF316BF3)
                    : const Color(0xFF475569), // slate-600
              ),
              const SizedBox(width: 8),
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
                            : (widget.isPrimary ? const Color(0xFF316BF3) : const Color(0xFF0F172A)), // slate-900 crisp
                      ),
                    ),
                    if (widget.isOptional)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          '(Optional)',
                          style: GoogleFonts.publicSans(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
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
              color: widget.isPrimary ? const Color(0xFF316BF3) : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              filled: false,
              hintText: widget.placeholder,
              hintStyle: GoogleFonts.publicSans(
                color: widget.isPrimary ? const Color(0xFF316BF3).withValues(alpha: 0.5) : const Color(0xFF64748B), // slate-500
                fontSize: widget.isLarge ? 20 : 15,
                fontWeight: widget.isLarge ? FontWeight.w600 : FontWeight.w500,
              ),
              border: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFE2E8F0))),
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

class _TypeToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _toggleButton('Individual', 'person', 'Individual', value == 'Individual'),
          const SizedBox(width: 32),
          _toggleButton('Organization', 'domain', 'Organization', value == 'Organization'),
        ],
      ),
    );
  }

  Widget _toggleButton(String type, String iconName, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => onChanged(type),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  iconName == 'person' ? Icons.person : Icons.domain,
                  color: isSelected ? const Color(0xFF316BF3) : const Color(0xFF64748B),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? const Color(0xFF316BF3) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                color: const Color(0xFF316BF3),
              ),
            ),
        ],
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
    final category = InvestorCategory.of(share);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
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
                  color: Color(0xFF0F172A),
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
              color: const Color(0xFF0F172A),
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
          Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
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
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      monthlyPayment > 0 ? Formatters.bdt(monthlyPayment) : '—',
                      style: GoogleFonts.publicSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
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
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      share > 0 ? t(ref, 'oneYear') : '—',
                      style: GoogleFonts.publicSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
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
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5), // emerald-50
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD1FAE5)), // emerald-100
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFF34D399),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t(ref, 'registrationSuccessful'),
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF316BF3), Color(0xFF1E40AF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF316BF3).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t(ref, 'yourInvestorId'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (submitted['investor_id'] ?? '').toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  Formatters.bdt(submitted['monthly_payment'] as num?),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                (submitted['status'] ?? '').toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF316BF3), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            helpText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onRegisterAnother,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            t(ref, 'registerAnother'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.go('/'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF316BF3),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            t(ref, 'goHome'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
