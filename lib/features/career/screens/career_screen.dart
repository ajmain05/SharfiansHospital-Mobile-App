import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/locale_provider.dart';
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(t(ref, 'career')),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(siteSettingsProvider),
        child: settingsAsync.when(
          data: (settings) {
            if (!settings.careerSettings.enabled) {
              return Center(child: Text(lang == 'bn' ? 'আবেদন গ্রহণ সাময়িকভাবে বন্ধ আছে।' : 'Applications are currently closed.'));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one education level')));
      return;
    }
    if (_hasExperience == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select whether you have previous experience')));
      return;
    }

    setState(() => _submitting = true);

    try {
      final experienceData = _hasExperience == 'yes'
          ? _experiences.where((e) => e['organization'].toString().isNotEmpty && e['position'].toString().isNotEmpty).toList()
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t(ref, 'applicationSubmitted'))));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t(ref, 'applicationFailed'))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.lang == 'bn' ? widget.settings.titleBn : widget.settings.title;
    final subtitle = widget.lang == 'bn' ? widget.settings.subtitleBn : widget.settings.subtitle;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, height: 1.45)),
                if (widget.settings.notice.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(widget.settings.notice, style: const TextStyle(color: AppColors.primary700, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                label: Text(_submitting ? t(ref, 'submitting') : t(ref, 'submitApplication')),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'First Name *'),
              onChanged: (v) => _firstName = v,
              validator: (v) => Validators.required(v, t(ref, 'requiredField')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Last Name *'),
              onChanged: (v) => _lastName = v,
              validator: (v) => Validators.required(v, t(ref, 'requiredField')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email Address *'),
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) => _email = v,
              validator: (v) => (v == null || !v.contains('@')) ? t(ref, 'invalidEmail') : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Phone Number *'),
              keyboardType: TextInputType.phone,
              onChanged: (v) => _phone = v,
              validator: (v) => Validators.phone(v, t(ref, 'invalidPhone')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppliedPosition() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Applied Position', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
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
        ),
      ),
    );
  }

  List<String> _positionItems() {
    if (widget.settings.positions.isNotEmpty) return widget.settings.positions;
    return [t(ref, 'generalApplication')];
  }

  Widget _buildEducation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Educational Qualification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ..._educations.asMap().entries.map((entry) {
              final i = entry.key;
              final edu = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Education #${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary600)),
                        if (_educations.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(() => _educations.removeAt(i)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: edu['level'],
                      decoration: const InputDecoration(labelText: 'Degree / Level *', hintText: 'e.g. HSC, BSc, Alim'),
                      onChanged: (v) => edu['level'] = v,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: edu['institution'],
                      decoration: const InputDecoration(labelText: 'Institution Name *'),
                      onChanged: (v) => edu['institution'] = v,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: edu['subject'],
                      decoration: const InputDecoration(labelText: 'Subject / Major (Optional)'),
                      onChanged: (v) => edu['subject'] = v,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: edu['year'],
                            decoration: const InputDecoration(labelText: 'Passing Year'),
                            onChanged: (v) => edu['year'] = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: edu['gpa'],
                            decoration: const InputDecoration(labelText: 'GPA / CGPA'),
                            onChanged: (v) => edu['gpa'] = v,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: () => setState(() => _educations.add({'category': '', 'level': '', 'institution': '', 'subject': '', 'year': '', 'gpa': ''})),
              icon: const Icon(Icons.add),
              label: const Text('Add Education'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverLetter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cover Letter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Tell us why you want to join Sharfians Hospital...'),
              onChanged: (v) => _coverLetter = v,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperience() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Work Experience', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            const Text('Do you have previous work experience? *', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _hasExperience = 'yes'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: _hasExperience == 'yes' ? AppColors.primary600 : Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(8),
                        color: _hasExperience == 'yes' ? AppColors.primary50 : Colors.transparent,
                      ),
                      alignment: Alignment.center,
                      child: const Text('✅ Yes', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _hasExperience = 'no'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: _hasExperience == 'no' ? AppColors.primary600 : Colors.grey.shade300, width: 2),
                        borderRadius: BorderRadius.circular(8),
                        color: _hasExperience == 'no' ? AppColors.primary50 : Colors.transparent,
                      ),
                      alignment: Alignment.center,
                      child: const Text('❌ No', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_hasExperience == 'yes') ...[
              ..._experiences.asMap().entries.map((entry) {
                final i = entry.key;
                final exp = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Experience #${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary600)),
                          if (_experiences.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(() => _experiences.removeAt(i)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: exp['organization'],
                        decoration: const InputDecoration(labelText: 'Organization / Company *'),
                        onChanged: (v) => exp['organization'] = v,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: exp['position'],
                        decoration: const InputDecoration(labelText: 'Position / Designation *'),
                        onChanged: (v) => exp['position'] = v,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: exp['startDate'],
                              decoration: const InputDecoration(labelText: 'Start Date', hintText: 'YYYY-MM'),
                              onChanged: (v) => exp['startDate'] = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: exp['endDate'],
                              enabled: !exp['running'],
                              decoration: const InputDecoration(labelText: 'End Date', hintText: 'YYYY-MM'),
                              onChanged: (v) => exp['endDate'] = v,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: exp['running'],
                        onChanged: (v) => setState(() {
                          exp['running'] = v;
                          if (v == true) exp['endDate'] = '';
                        }),
                        title: const Text('Currently Working Here', style: TextStyle(fontSize: 14)),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ],
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: () => setState(() => _experiences.add({'organization': '', 'position': '', 'startDate': '', 'endDate': '', 'running': false})),
                icon: const Icon(Icons.add),
                label: const Text('Add Another Experience'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 40)),
              ),
            ],
            if (_hasExperience == 'no')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Text('👍', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No problem at all!', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('We welcome fresh candidates. Your educational background matters more.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
