import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF0A192F),
          ),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          t(ref, 'myPortal'),
          style: GoogleFonts.libreCaslonText(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0A192F),
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: LanguageToggleButton(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profile Icon & Welcome Header ─────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 190,
                        height: 190,
                        child: Lottie.asset(
                          'assets/animations/Man account Icon.json',
                          fit: BoxFit.contain,
                          frameRate: const FrameRate(30),
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF316BF3),
                                      Color(0xFF60A5FA),
                                    ],
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF316BF3,
                                      ).withValues(alpha: 0.35),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t(ref, 'myPortalTitle'),
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0A192F),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t(ref, 'myPortalSubtitle'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF4A5568),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Information Alert Box ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFDBEAFE),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFDBEAFE),
                          ),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF316BF3),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t(ref, 'loginHelpText'),
                          style: GoogleFonts.publicSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(
                                    0xFF0A192F,
                                  ).withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Login Form ──────────────────────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t(ref, 'phoneNumber').toUpperCase(),
                        style: GoogleFonts.publicSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF0A192F).withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.publicSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0A192F),
                        ),
                        decoration: InputDecoration(
                          prefixIconConstraints: const BoxConstraints(minWidth: 0),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 16, right: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '+880',
                                  style: GoogleFonts.publicSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF0A192F).withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ],
                            ),
                          ),
                          hintText: '017XXXXXXXX',
                          hintStyle: GoogleFonts.publicSans(
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFFCBD5E1),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF316BF3),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                              width: 1.2,
                            ),
                          ),
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
                      const SizedBox(height: 28),

                      // Continue Button
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF316BF3,
                              ).withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: session.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF316BF3),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: session.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  t(ref, 'continueBtn'),
                                  style: GoogleFonts.publicSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
                      border: Border.all(color: const Color(0xFFFEE2E8)),
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
                            style: GoogleFonts.publicSans(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Become an Investor — secondary link
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/register'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${t(ref, 'newHereQuestion')} ',
                            style: GoogleFonts.publicSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          TextSpan(
                            text: t(ref, 'becomeInvestor'),
                            style: GoogleFonts.publicSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF316BF3),
                            ),
                          ),
                        ],
                      ),
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
}
