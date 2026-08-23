import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/event_registration_summary.dart';
import '../providers/events_providers.dart';

class EventCheckStatusScreen extends ConsumerStatefulWidget {
  const EventCheckStatusScreen({super.key});

  @override
  ConsumerState<EventCheckStatusScreen> createState() =>
      _EventCheckStatusScreenState();
}

class _EventCheckStatusScreenState
    extends ConsumerState<EventCheckStatusScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;
  String? _error;
  List<EventRegistrationSummary>? _results;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  bool _isValidBdPhone(String phone) => RegExp(r'^01\d{9}$').hasMatch(phone);

  Future<void> _requestOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (!_isValidBdPhone(phone)) {
      setState(() => _error = t(ref, 'invalidPhone'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(eventsRepositoryProvider).requestCheckPhoneOtp(phone);
      setState(() => _otpSent = true);
    } catch (e) {
      final message = e is ApiException && e.statusCode == 429
          ? t(ref, 'tooManyAttempts')
          : t(ref, 'somethingWentWrong');
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneCtrl.text.trim();
    final code = _otpCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _results = null;
    });
    try {
      final results = await ref
          .read(eventsRepositoryProvider)
          .verifyCheckPhoneOtp(phone, code);
      setState(() {
        _results = results;
        if (results.isEmpty) _error = t(ref, 'noRegistrationsFound');
      });
    } catch (e) {
      final message = switch (e) {
        ApiException(statusCode: 429) => t(ref, 'tooManyAttempts'),
        ApiException(statusCode: 400) => t(ref, 'otpInvalidOrExpired'),
        _ => t(ref, 'somethingWentWrong'),
      };
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeNumber() {
    setState(() {
      _otpSent = false;
      _results = null;
      _error = null;
      _otpCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          t(ref, 'checkStatusTitle'),
          style: GoogleFonts.publicSans(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: Lottie.asset(
                  'assets/animations/Searching.json',
                  fit: BoxFit.contain,
                  frameRate: const FrameRate(30),
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.confirmation_number_rounded,
                    size: 38,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _otpSent
                  ? '${t(ref, 'verificationCodeSentTo')} ${_phoneCtrl.text.trim()}'
                  : t(ref, 'checkStatusSubtitle'),
              textAlign: TextAlign.center,
              style: GoogleFonts.publicSans(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_otpSent) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.publicSans(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              labelText: t(ref, 'phoneNumber'),
                              labelStyle: GoogleFonts.publicSans(
                                fontWeight: FontWeight.w600,
                              ),
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _requestOtp,
                            child: _loading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(t(ref, 'sendCode')),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    TextField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: GoogleFonts.publicSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: 4,
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: t(ref, 'enterVerificationCode'),
                        labelStyle: GoogleFonts.publicSans(
                          fontWeight: FontWeight.w600,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          color: colorScheme.primary,
                        ),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _verifyOtp,
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(t(ref, 'verifyCode')),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _loading ? null : _changeNumber,
                          child: Text(
                            t(ref, 'changeNumber'),
                            style: GoogleFonts.publicSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _loading ? null : _requestOtp,
                          child: Text(
                            t(ref, 'resendCode'),
                            style: GoogleFonts.publicSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t(ref, 'otpNotReceivedHint'),
                      style: GoogleFonts.publicSans(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: GoogleFonts.publicSans(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (_results != null && _results!.isNotEmpty) ...[
              const SizedBox(height: 24),
              for (final r in _results!) _ResultCard(result: r),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends ConsumerWidget {
  final EventRegistrationSummary result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final cfg = _statusConfig(result.status);
    final date = result.eventDate != null
        ? DateTime.tryParse(result.eventDate!)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: result.qrCodeToken != null
              ? () => context.push('/events/status/${result.qrCodeToken}')
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.eventTitle ?? '',
                        style: GoogleFonts.publicSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (date != null)
                        Text(
                          DateFormat('MMM d, yyyy').format(date),
                          style: GoogleFonts.publicSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.bdt(result.totalAmount),
                        style: GoogleFonts.publicSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cfg.$2,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cfg.$1,
                    style: TextStyle(
                      color: cfg.$3,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (result.qrCodeToken != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, Color, Color) _statusConfig(String status) {
    switch (status) {
      case 'APPROVED':
        return ('✅ Approved', const Color(0xFFE5F8F0), const Color(0xFF0E9E6F));
      case 'REJECTED':
        return ('❌ Rejected', const Color(0xFFFEF2F2), const Color(0xFFDC2626));
      default:
        return ('⏳ Pending', const Color(0xFFFEF3C7), const Color(0xFFB45309));
    }
  }
}
