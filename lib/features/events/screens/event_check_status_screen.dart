import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:smart_auth/smart_auth.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/push_notification_service.dart';
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

  // Set when reached from a specific event's detail page (its bottom action
  // bar) — narrows results to just that event instead of showing every
  // registration this phone has ever made, and reflects that in the copy.
  String? _scopedEventId;
  String? _scopedEventTitle;
  bool _scopeRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_scopeRead) {
      final qp = GoRouterState.of(context).uri.queryParameters;
      _scopedEventId = qp['eventId'];
      _scopedEventTitle = qp['eventTitle'];
      _scopeRead = true;
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _stopOtpAutofillListener();
    super.dispose();
  }

  // See the matching comment in investor_login_screen.dart — same
  // SMS User Consent API approach, same reason SMS Retriever was skipped.
  Future<void> _listenForOtpAutofill() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final result = await SmartAuth.instance.getSmsWithUserConsentApi();
    if (!mounted) return;
    final code = result.data?.code;
    if (code != null && code.length == 6) {
      setState(() => _otpCtrl.text = code);
    }
  }

  void _stopOtpAutofillListener() {
    if (kIsWeb || !Platform.isAndroid) return;
    SmartAuth.instance.removeUserConsentApiListener();
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
      _listenForOtpAutofill();
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
      _stopOtpAutofillListener();
      final scoped = _scopedEventId != null
          ? results.where((r) => r.eventId == _scopedEventId).toList()
          : results;
      setState(() {
        _results = scoped;
        if (scoped.isEmpty) _error = t(ref, 'noRegistrationsFound');
      });

      // OTP verification just proved this device's owner really controls
      // this phone — the same proof My Portal login relies on — so this is
      // also the right moment to attach it to the push token. Covers anyone
      // who registered for an event on the website (or before this fix
      // existed) and is only now checking status from the app, without ever
      // logging into My Portal.
      if (results.isNotEmpty) {
        ref.read(pushNotificationServiceProvider).registerToken(phone: phone);
      }
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
    _stopOtpAutofillListener();
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
                  : _scopedEventTitle != null
                      ? t(ref, 'checkStatusSubtitleForEvent', params: {'event': _scopedEventTitle!})
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
                    AutofillGroup(
                      child: TextField(
                        controller: _otpCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        // See the matching comment in
                        // investor_login_screen.dart for why this covers
                        // iOS only, with Android handled separately via
                        // the SmartAuth listener above.
                        autofillHints: const [AutofillHints.oneTimeCode],
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
              // Grouped by event (not a flat list) — one phone can have
              // registrations across several different events, and a bare
              // list of cards made it unclear which result belonged to
              // which event at a glance.
              for (final group in _groupByEvent(_results!)) ...[
                _EventGroupHeader(sample: group.first),
                const SizedBox(height: 10),
                for (final r in group) _ResultCard(result: r),
                const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// Groups registrations by event while preserving each group's first-seen
// order (matches the backend's most-recent-first ordering) — a phone can
// have registrations across several different events, so a bare flat list
// left it unclear which result belonged to which.
List<List<EventRegistrationSummary>> _groupByEvent(
  List<EventRegistrationSummary> results,
) {
  final order = <String>[];
  final groups = <String, List<EventRegistrationSummary>>{};
  for (final r in results) {
    final key = r.eventId ?? r.eventTitle ?? r.id ?? r.hashCode.toString();
    if (!groups.containsKey(key)) order.add(key);
    groups.putIfAbsent(key, () => []).add(r);
  }
  return [for (final key in order) groups[key]!];
}

class _EventGroupHeader extends StatelessWidget {
  final EventRegistrationSummary sample;

  const _EventGroupHeader({required this.sample});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Stored/sent as a UTC ('Z'-suffixed) ISO string — .toLocal() converts to
    // the device's local (Bangladesh) time before formatting.
    final date = sample.eventDate != null
        ? DateTime.tryParse(sample.eventDate!)?.toLocal()
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.event_outlined,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sample.eventTitle ?? '',
                  style: GoogleFonts.publicSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (date != null)
                  Text(
                    DateFormat('MMM d, yyyy').format(date),
                    style: GoogleFonts.publicSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
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

class _ResultCard extends ConsumerWidget {
  final EventRegistrationSummary result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final cfg = _statusConfig(result.status);

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
                        result.name,
                        style: GoogleFonts.publicSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.personsCount > 1
                            ? '${Formatters.bdt(result.totalAmount)} · ${result.personsCount} persons'
                            : Formatters.bdt(result.totalAmount),
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
