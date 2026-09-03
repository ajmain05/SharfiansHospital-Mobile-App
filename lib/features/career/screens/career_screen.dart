import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/adaptive_colors.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/error_retry_view.dart';
import '../../../core/widgets/shimmer_loader.dart';
import '../../../models/site_settings.dart';
import '../../settings/providers/site_settings_provider.dart';
import '../providers/career_providers.dart';

class CareerScreen extends ConsumerWidget {
  const CareerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(siteSettingsProvider);
    final lang = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: context.bgFill,
      body: RefreshIndicator(
        color: AppColors.primary700,
        onRefresh: () async => ref.invalidate(siteSettingsProvider),
        child: settingsAsync.when(
          data: (settings) {
            if (!settings.careerSettings.enabled) {
              return _CareerClosed(lang: lang, ref: ref);
            }
            return _CareerBody(settings: settings.careerSettings, lang: lang);
          },
          loading: () => const ShimmerLoader(),
          error: (err, stack) => ErrorRetryView(
            onRetry: () => ref.invalidate(siteSettingsProvider),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CLOSED STATE — Premium, Warm, Not Boring
// ══════════════════════════════════════════════════════════════════════════════
class _CareerClosed extends StatelessWidget {
  final String lang;
  final WidgetRef ref;

  const _CareerClosed({required this.lang, required this.ref});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _CareerHeader(ref: ref, onBack: () => context.pop()),
        ),
        SliverFillRemaining(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lottie Animation Container (Replaces Icon)
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.accent500.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Lottie.asset(
                    'assets/animations/career.json',
                    fit: BoxFit.contain,
                    frameRate: const FrameRate(30),
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.business_center_rounded,
                      size: 60,
                      color: AppColors.accent400,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                Text(
                  lang == 'bn' ? 'নিয়োগ সাময়িকভাবে বন্ধ' : 'No Open Positions',
                  style: GoogleFonts.publicSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: context.textHigh,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  lang == 'bn'
                      ? 'বর্তমানে কোনো পদে আবেদন গ্রহণ করা হচ্ছে না। নতুন সুযোগের জন্য আমাদের সাথেই থাকুন।'
                      : 'We are not accepting applications at this moment. Stay connected for future opportunities when we expand our team.',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textMed,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


// ══════════════════════════════════════════════════════════════════════════════
// OPEN STATE — Premium Application Form
// ══════════════════════════════════════════════════════════════════════════════
class _CareerBody extends ConsumerStatefulWidget {
  final CareerSettings settings;
  final String lang;

  const _CareerBody({required this.settings, required this.lang});

  @override
  ConsumerState<_CareerBody> createState() => _CareerBodyState();
}

class _CareerBodyState extends ConsumerState<_CareerBody> {
  final _formKey = GlobalKey<FormState>();

  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  String? _position;
  String _coverLetter = '';
  String? _hasExperience;

  final List<Map<String, dynamic>> _educations = [
    {'category': '', 'level': '', 'institution': '', 'subject': '', 'year': '', 'gpa': ''}
  ];

  final List<Map<String, dynamic>> _experiences = [
    {'organization': '', 'position': '', 'startDate': '', 'endDate': '', 'running': false}
  ];

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.settings.positions.isNotEmpty) {
      _position = widget.settings.positions.first;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_educations.isEmpty || _educations[0]['level'].toString().trim().isEmpty) {
      _showSnack('Please add at least one education level', isError: true);
      return;
    }
    if (_hasExperience == null) {
      _showSnack('Please select whether you have previous experience', isError: true);
      return;
    }

    setState(() => _submitting = true);

    try {
      final experienceData = _hasExperience == 'yes'
          ? _experiences
              .where((e) => e['organization'].toString().isNotEmpty && e['position'].toString().isNotEmpty)
              .toList()
          : [];

      final educationObj = <String, dynamic>{};
      for (final edu in _educations) {
        if (edu['level'].toString().isNotEmpty && edu['institution'].toString().isNotEmpty) {
          educationObj[edu['level']] = {
            'institution': edu['institution'],
            'subject': edu['subject'],
            'year': edu['year'],
            'gpa': edu['gpa'],
            'category': edu['category']
          };
        }
      }

      final richData = {
        'firstName': _firstName.trim(),
        'lastName': _lastName.trim(),
        'fullName': '${_firstName.trim()} ${_lastName.trim()}',
        'appliedPosition': _position ?? 'General',
        'education': educationObj,
        'hasExperience': _hasExperience == 'yes',
        'experiences': experienceData,
        'coverLetter': _coverLetter.trim(),
      };

      await ref.read(careerRepositoryProvider).submitApplication({
        'name': '${_firstName.trim()} ${_lastName.trim()}',
        'email': _email.trim().toLowerCase(),
        'phone': _phone.trim(),
        'position': _position ?? 'General',
        'experience': jsonEncode(experienceData),
        'message': jsonEncode(richData),
      });

      if (!mounted) return;
      _showSnack(t(ref, 'applicationSubmitted'));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _showSnack(t(ref, 'applicationFailed'), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? AppColors.error : AppColors.primary800,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.lang == 'bn' ? widget.settings.titleBn : widget.settings.title;
    final subtitle = widget.lang == 'bn' ? widget.settings.subtitleBn : widget.settings.subtitle;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _CareerHeader(ref: ref, onBack: () => context.pop()),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Hero info card
              _InfoCard(
                gradient: AppColors.heroGradient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.work_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    if (widget.settings.notice.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accent500.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.campaign_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.settings.notice,
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildPersonalInfo(),
                    const SizedBox(height: 16),
                    _buildAppliedPosition(),
                    const SizedBox(height: 16),
                    _buildEducation(),
                    const SizedBox(height: 16),
                    _buildCoverLetter(),
                    const SizedBox(height: 16),
                    _buildExperience(),
                    const SizedBox(height: 28),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary700,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white),
                        label: Text(
                          _submitting ? t(ref, 'submitting') : t(ref, 'submitApplication'),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    return _FormSection(
      icon: Icons.person_rounded,
      title: 'Personal Information',
      gradient: AppColors.cardGradientGreen,
      children: [
        Row(
          children: [
            Expanded(
              child: _AppField(
                label: 'First Name *',
                onChanged: (v) => _firstName = v,
                validator: (v) => Validators.required(v, t(ref, 'requiredField')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AppField(
                label: 'Last Name *',
                onChanged: (v) => _lastName = v,
                validator: (v) => Validators.required(v, t(ref, 'requiredField')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _AppField(
          label: 'Email Address *',
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) => _email = v,
          validator: (v) => (v == null || !v.contains('@')) ? t(ref, 'invalidEmail') : null,
        ),
        const SizedBox(height: 12),
        _AppField(
          label: 'Phone Number *',
          keyboardType: TextInputType.phone,
          onChanged: (v) => _phone = v,
          validator: (v) => Validators.phone(v, t(ref, 'invalidPhone')),
        ),
      ],
    );
  }

  Widget _buildAppliedPosition() {
    return _FormSection(
      icon: Icons.badge_rounded,
      title: 'Applied Position',
      gradient: AppColors.cardGradientGold,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _position,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Select Position *'),
          items: _positionItems()
              .map((p) => DropdownMenuItem(value: p, child: Text(p)))
              .toList(),
          onChanged: (v) => setState(() => _position = v),
          validator: (v) => Validators.required(v, t(ref, 'requiredField')),
        ),
      ],
    );
  }

  List<String> _positionItems() {
    if (widget.settings.positions.isNotEmpty) return widget.settings.positions;
    return [t(ref, 'generalApplication')];
  }

  Widget _buildEducation() {
    return _FormSection(
      icon: Icons.school_rounded,
      title: 'Educational Qualification',
      gradient: AppColors.cardGradientTeal,
      children: [
        ..._educations.asMap().entries.map((entry) {
          final i = entry.key;
          final edu = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.cardFill2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Education #${i + 1}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.teal600,
                      ),
                    ),
                    if (_educations.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _educations.removeAt(i)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: edu['category'].toString().isEmpty ? null : edu['category'],
                  decoration: const InputDecoration(labelText: 'Category *'),
                  items: const [
                    DropdownMenuItem(value: 'Madrasa', child: Text('Madrasa Education')),
                    DropdownMenuItem(value: 'General', child: Text('General Education')),
                    DropdownMenuItem(value: 'Medical', child: Text('Medical Degrees')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() {
                    edu['category'] = v;
                    edu['level'] = '';
                  }),
                ),
                const SizedBox(height: 10),
                _AppField(
                  label: 'Degree / Level *',
                  hint: 'e.g. HSC, BSc, Alim',
                  initialValue: edu['level'],
                  onChanged: (v) => edu['level'] = v,
                ),
                const SizedBox(height: 10),
                _AppField(
                  label: 'Institution Name *',
                  initialValue: edu['institution'],
                  onChanged: (v) => edu['institution'] = v,
                ),
                const SizedBox(height: 10),
                _AppField(
                  label: 'Subject / Major (Optional)',
                  initialValue: edu['subject'],
                  onChanged: (v) => edu['subject'] = v,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _AppField(
                        label: 'Passing Year',
                        initialValue: edu['year'],
                        onChanged: (v) => edu['year'] = v,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AppField(
                        label: 'GPA / CGPA',
                        initialValue: edu['gpa'],
                        onChanged: (v) => edu['gpa'] = v,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => _educations.add(
              {'category': '', 'level': '', 'institution': '', 'subject': '', 'year': '', 'gpa': ''})),
          icon: const Icon(Icons.add_circle_outline),
          label: Text('Add Education', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildCoverLetter() {
    return _FormSection(
      icon: Icons.edit_note_rounded,
      title: 'Cover Letter',
      gradient: const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      children: [
        TextFormField(
          minLines: 4,
          maxLines: 6,
          style: GoogleFonts.nunito(),
          decoration: InputDecoration(
            hintText: 'Tell us why you want to join Sharfians Hospital PLC...',
            hintStyle: GoogleFonts.nunito(color: context.textMed),
          ),
          onChanged: (v) => _coverLetter = v,
        ),
      ],
    );
  }

  Widget _buildExperience() {
    return _FormSection(
      icon: Icons.history_edu_rounded,
      title: 'Work Experience',
      gradient: const LinearGradient(
        colors: [Color(0xFFDB2777), Color(0xFFF472B6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      children: [
        Text(
          'Do you have previous work experience? *',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Row(
          children: ['yes', 'no'].map((val) {
            final selected = _hasExperience == val;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _hasExperience = val),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: val == 'yes' ? 6 : 0, left: val == 'no' ? 6 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? (val == 'yes' ? AppColors.cardGradientGreen : AppColors.cardGradientGold)
                        : null,
                    color: selected ? null : context.cardFill2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? Colors.transparent : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(val == 'yes' ? '✅' : '❌', style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        val == 'yes' ? 'Yes' : 'No',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : context.textHigh,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        if (_hasExperience == 'yes') ...[
          ..._experiences.asMap().entries.map((entry) {
            final i = entry.key;
            final exp = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cardFill2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Experience #${i + 1}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: const Color(0xFFDB2777),
                        ),
                      ),
                      if (_experiences.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _experiences.removeAt(i)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _AppField(label: 'Organization / Company *', initialValue: exp['organization'], onChanged: (v) => exp['organization'] = v),
                  const SizedBox(height: 10),
                  _AppField(label: 'Position / Designation *', initialValue: exp['position'], onChanged: (v) => exp['position'] = v),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _AppField(label: 'Start (YYYY-MM)', initialValue: exp['startDate'], onChanged: (v) => exp['startDate'] = v)),
                      const SizedBox(width: 10),
                      Expanded(child: _AppField(label: 'End (YYYY-MM)', initialValue: exp['endDate'], enabled: !exp['running'], onChanged: (v) => exp['endDate'] = v)),
                    ],
                  ),
                  CheckboxListTile(
                    value: exp['running'],
                    activeColor: AppColors.primary700,
                    onChanged: (v) => setState(() {
                      exp['running'] = v;
                      if (v == true) exp['endDate'] = '';
                    }),
                    title: Text('Currently working here', style: GoogleFonts.nunito(fontSize: 13)),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() => _experiences.add(
                {'organization': '', 'position': '', 'startDate': '', 'endDate': '', 'running': false})),
            icon: const Icon(Icons.add_circle_outline),
            label: Text('Add Another Experience', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],

        if (_hasExperience == 'no')
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary200),
            ),
            child: Row(
              children: [
                const Text('👍', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No problem at all!',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.primary800),
                      ),
                      Text(
                        'We welcome fresh candidates. Your educational background and passion matter most.',
                        style: GoogleFonts.nunito(fontSize: 12, color: context.textMed),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Shared Premium Widgets ────────────────────────────────────────────────────

class _CareerHeader extends StatelessWidget {
  final WidgetRef ref;
  final VoidCallback onBack;

  const _CareerHeader({required this.ref, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t(ref, 'career'),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    'Join the Sharfians family',
                    style: GoogleFonts.nunito(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final LinearGradient gradient;
  final Widget child;

  const _InfoCard({required this.gradient, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FormSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final LinearGradient gradient;
  final List<Widget> children;

  const _FormSection({
    required this.icon,
    required this.title,
    required this.gradient,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _AppField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;

  const _AppField({
    required this.label,
    required this.onChanged,
    this.hint,
    this.initialValue,
    this.keyboardType,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      enabled: enabled,
      keyboardType: keyboardType,
      style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.nunito(color: context.textMed),
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
