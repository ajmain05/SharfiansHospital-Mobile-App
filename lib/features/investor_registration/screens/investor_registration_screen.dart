import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/investor_category.dart';
import '../../../core/widgets/language_toggle_button.dart';
import '../../investor_auth/providers/investor_session_provider.dart';
import '../../settings/providers/site_settings_provider.dart';

class InvestorRegistrationScreen extends ConsumerStatefulWidget {
  const InvestorRegistrationScreen({super.key});

  @override
  ConsumerState<InvestorRegistrationScreen> createState() => _InvestorRegistrationScreenState();
}

class _InvestorRegistrationScreenState extends ConsumerState<InvestorRegistrationScreen> {
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
        SnackBar(content: Text(t(ref, 'minimumShareError', params: {'amount': Formatters.number(minShareAmount)}))),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final payload = {
        'investor_type': _investorType,
        if (_investorType == 'Organization') 'organization_name': _orgNameCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'father_name': _fatherCtrl.text.trim(),
        'mother_name': _motherCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'share_amount': _share,
        'number_of_persons': int.tryParse(_personsCtrl.text) ?? 1,
        if (_educationLevelCtrl.text.trim().isNotEmpty) 'education_level': _educationLevelCtrl.text.trim(),
        if (_passingYearCtrl.text.trim().isNotEmpty) 'passing_year': int.tryParse(_passingYearCtrl.text.trim()),
        if (_investorType != 'Organization') ...{
          'nominee_name': _nomineeNameCtrl.text.trim(),
          'nominee_relation': _nomineeRelationCtrl.text.trim(),
          'nominee_phone': _nomineePhoneCtrl.text.trim(),
          if (_nomineeNidCtrl.text.trim().isNotEmpty) 'nominee_nid': _nomineeNidCtrl.text.trim(),
          'nominee_address': _nomineeAddressCtrl.text.trim(),
        },
        if (_charityCtrl.text.trim().isNotEmpty) 'charity_percentage': num.tryParse(_charityCtrl.text.trim()),
      };
      final result = await ref.read(investorRepositoryProvider).register(payload);
      if (!mounted) return;
      setState(() => _submitted = result);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(siteSettingsProvider);
    final minShareAmount = settingsAsync.maybeWhen(data: (s) => s.minShareAmount, orElse: () => 100000);

    if (_submitted != null) {
      return _SuccessView(submitted: _submitted!, onRegisterAnother: () => setState(() => _submitted = null));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
        title: Text(t(ref, 'investorRegistration')),
        actions: const [Padding(padding: EdgeInsets.only(right: 12), child: LanguageToggleButton())],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TypeToggle(
                value: _investorType,
                onChanged: (v) => setState(() => _investorType = v),
              ),
              const SizedBox(height: 16),
              if (_investorType == 'Organization') ...[
                _Field(controller: _orgNameCtrl, label: t(ref, 'organizationName'), required: true),
                const SizedBox(height: 14),
              ],
              _Field(
                controller: _nameCtrl,
                label: _investorType == 'Organization' ? t(ref, 'representativeFullName') : t(ref, 'fullName'),
                required: true,
              ),
              const SizedBox(height: 14),
              _Field(controller: _fatherCtrl, label: t(ref, 'fathersName'), required: true),
              const SizedBox(height: 14),
              _Field(controller: _motherCtrl, label: t(ref, 'mothersName'), required: true),
              const SizedBox(height: 14),
              _Field(controller: _phoneCtrl, label: t(ref, 'phoneNumber'), required: true, keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              _Field(controller: _addressCtrl, label: t(ref, 'address'), required: true, maxLines: 2),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _educationLevelCtrl,
                      label: '${t(ref, 'degreeLevel')} (${t(ref, 'optional')})',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      controller: _passingYearCtrl,
                      label: '${t(ref, 'passingYear')} (${t(ref, 'optional')})',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _Field(
                      controller: _shareCtrl,
                      label: t(ref, 'shareAmountBdt'),
                      required: true,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      controller: _personsCtrl,
                      label: t(ref, 'numberOfPersons'),
                      required: true,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              if (_investorType != 'Organization') ...[
                const SizedBox(height: 22),
                Text(t(ref, 'nomineeInformation'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                _Field(controller: _nomineeNameCtrl, label: t(ref, 'nomineeName'), required: true),
                const SizedBox(height: 14),
                _Field(controller: _nomineeRelationCtrl, label: t(ref, 'nomineeRelation'), required: true),
                const SizedBox(height: 14),
                _Field(controller: _nomineePhoneCtrl, label: t(ref, 'nomineePhone'), required: true, keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _Field(controller: _nomineeNidCtrl, label: '${t(ref, 'nomineeNid')} (${t(ref, 'optional')})'),
                const SizedBox(height: 14),
                _Field(controller: _nomineeAddressCtrl, label: t(ref, 'nomineeAddress'), required: true, maxLines: 2),
              ],
              const SizedBox(height: 22),
              Text(t(ref, 'charityDonation'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(t(ref, 'charityDesc'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 12),
              _Field(
                controller: _charityCtrl,
                label: '${t(ref, 'donationPercentage')} (${t(ref, 'optional')})',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _LiveCalculatorCard(share: _share, monthlyPayment: _monthlyPayment),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : () => _submit(minShareAmount),
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(t(ref, 'registerAsInvestor')),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final TextInputType? keyboardType;
  final int maxLines;

  const _Field({
    required this.controller,
    required this.label,
    this.required = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: required ? '$label *' : label),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
    );
  }
}

class _TypeToggle extends ConsumerWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: _toggleButton(context, 'Individual', '👤 ${t(ref, 'personalIndividual')}')),
          Expanded(child: _toggleButton(context, 'Organization', '🏢 ${t(ref, 'organizationShomiti')}')),
        ],
      ),
    );
  }

  Widget _toggleButton(BuildContext context, String type, String label) {
    final selected = value == type;
    return GestureDetector(
      onTap: () => onChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: selected ? AppColors.primary600 : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LiveCalculatorCard extends ConsumerWidget {
  final num share;
  final num monthlyPayment;

  const _LiveCalculatorCard({required this.share, required this.monthlyPayment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = InvestorCategory.of(share);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: category.gradient, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(t(ref, 'liveCalculator'), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          _calcRow(t(ref, 'shareAmount'), Formatters.bdt(share)),
          const Divider(color: Colors.white24, height: 20),
          _calcRow(t(ref, 'monthlyPayment'), monthlyPayment > 0 ? Formatters.bdt(monthlyPayment) : '—'),
          const Divider(color: Colors.white24, height: 20),
          _calcRow(t(ref, 'duration'), share > 0 ? t(ref, 'oneYear') : '—'),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t(ref, 'status'), style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  category.isDirector ? '⭐ ${category.label}' : t(ref, 'regular'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calcRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SuccessView extends ConsumerWidget {
  final Map<String, dynamic> submitted;
  final VoidCallback onRegisterAnother;

  const _SuccessView({required this.submitted, required this.onRegisterAnother});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(siteSettingsProvider);
    final lang = ref.watch(localeProvider).languageCode;
    final helpText = settingsAsync.maybeWhen(
      data: (s) => lang == 'bn' ? s.registerHelpTextBn : s.registerHelpText,
      orElse: () => t(ref, 'registerHelpText'),
    );

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(color: AppColors.accent500, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 20),
                    Text(t(ref, 'registrationSuccessful'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t(ref, 'yourInvestorId'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(
                            (submitted['investor_id'] ?? '').toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${t(ref, 'monthlyColon')} ${Formatters.bdt(submitted['monthly_payment'] as num?)}',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  (submitted['status'] ?? '').toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.primary50, borderRadius: BorderRadius.circular(16)),
                      child: Text(helpText, style: const TextStyle(fontSize: 13, color: AppColors.primary900)),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(onPressed: onRegisterAnother, child: Text(t(ref, 'registerAnother'))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(onPressed: () => context.go('/'), child: Text(t(ref, 'goHome'))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
