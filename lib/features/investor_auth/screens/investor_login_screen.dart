import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/language_toggle_button.dart';
import '../providers/investor_session_provider.dart';

class InvestorLoginScreen extends ConsumerStatefulWidget {
  const InvestorLoginScreen({super.key});

  @override
  ConsumerState<InvestorLoginScreen> createState() =>
      _InvestorLoginScreenState();
}

class _InvestorLoginScreenState extends ConsumerState<InvestorLoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final ok = await ref
        .read(investorSessionProvider.notifier)
        .loginWithPhone(_phoneController.text.trim());
    if (!mounted) return;
    if (ok) {
      context.go('/investor/dashboard');
    } else {
      setState(() => _error = t(ref, 'noAccountFound'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(investorSessionProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(t(ref, 'myPortal')),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: LanguageToggleButton(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_circle_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  t(ref, 'myPortalTitle'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t(ref, 'myPortalSubtitle'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary600,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t(ref, 'loginHelpText'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: t(ref, 'phoneNumber'),
                          prefixIcon: const Icon(Icons.phone_outlined),
                          hintText: 'e.g. 017XXXXXXXX',
                        ),
                        validator: (v) {
                          final digits = (v ?? '').replaceAll(
                            RegExp(r'\D'),
                            '',
                          );
                          if (digits.length < 10) return t(ref, 'invalidPhone');
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: session.isLoading ? null : _submit,
                          child: session.isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(t(ref, 'continueBtn')),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Color(0xFF991B1B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: Text(t(ref, 'becomeInvestor')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
