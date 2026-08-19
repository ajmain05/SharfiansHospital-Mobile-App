import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/network/cloudinary_uploader.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/event.dart';
import '../providers/events_providers.dart';

const String _bgImageUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuC-r2SZdviaJpcKKrOGKAF2giGZNzpqbuOT-7M40iwK7piLgybI2GMmZO7Frfh2wOSEBk8dZrnSVZrhDUMVQsXycYvYZ_LT4wYQX5zMvYCllpE0R0yBcgA97ioWSwH1vjnJY5n0_y2VV0wHgwdZlAWjfRePONzIz-6hOz4PZ0xZMRLAE3zX6tU-0f6tP6PGUbanD_gU_ZAip05vxQL_g_zDdlqhiPdNrtHUAxEeSg0y431n7QutbdNi';

class EventRegistrationScreen extends ConsumerWidget {
  final String slug;

  const EventRegistrationScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventBySlugProvider(slug));

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAF8FF),
            border: Border(
              bottom: BorderSide(color: Color(0xFFC5C5D3), width: 1),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 64,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF444651)),
              onPressed: () => context.pop(),
            ),
            title: Text(
              t(ref, 'eventRegistrationTitle'),
              style: GoogleFonts.publicSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF00236F),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Illustration with 92% rgba(250, 248, 255, 0.92) overlay tint
          Positioned.fill(
            child: Image.network(
              _bgImageUrl,
              fit: BoxFit.cover,
              color: const Color(0xFFFAF8FF).withValues(alpha: 0.92),
              colorBlendMode: BlendMode.srcOver,
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFFFAF8FF)),
            ),
          ),
          eventAsync.when(
            data: (event) {
              if (!event.isActive) {
                return _ClosedView(message: t(ref, 'eventClosedMsg'));
              }
              if (event.isDeadlinePassed) {
                return _ClosedView(message: t(ref, 'deadlinePassed'));
              }
              if (event.isCapacityFull) {
                return _ClosedView(message: t(ref, 'capacityFull'));
              }
              return _RegistrationForm(event: event);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => _ClosedView(message: t(ref, 'eventNotFound')),
          ),
        ],
      ),
    );
  }
}

class _ClosedView extends ConsumerWidget {
  final String message;

  const _ClosedView({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: Color(0xFF444651),
            ),
            const SizedBox(height: 12),
            Text(
              t(ref, 'registrationClosed'),
              style: GoogleFonts.publicSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: const Color(0xFF131B2E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.publicSans(
                color: const Color(0xFF444651),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationForm extends ConsumerStatefulWidget {
  final Event event;

  const _RegistrationForm({required this.event});

  @override
  ConsumerState<_RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends ConsumerState<_RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _senderCtrl = TextEditingController();
  int _personsCount = 1;
  EventPaymentMethod? _method;
  DateTime? _chequeDate;
  File? _proofFile;
  bool _submitting = false;
  bool _submitted = false;

  late final List<EventPaymentMethod> _methods;

  @override
  void initState() {
    super.initState();
    _methods = EventPaymentMethod.fromPaymentConfig(widget.event.paymentConfig);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _senderCtrl.dispose();
    super.dispose();
  }

  num get _totalAmount => _personsCount * widget.event.feePerPerson;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _proofFile = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_method == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(ref, 'selectPaymentMethod'))));
      return;
    }
    if (_proofFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t(ref, 'paymentProofRequired'))));
      return;
    }

    setState(() {
      _submitting = true;
    });
    try {
      final proofUrl = await CloudinaryUploader.upload(
        _proofFile!,
        folder: 'event_registrations',
      );

      var senderNumber = _senderCtrl.text.trim();
      if (_method!.id == 'Cheque' && _chequeDate != null) {
        senderNumber =
            '$senderNumber (Date: ${DateFormat.yMMMd().format(_chequeDate!)})';
      }

      await ref.read(eventsRepositoryProvider).submitRegistration({
        'eventId': widget.event.id,
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'personsCount': _personsCount,
        'paymentMethod': _method!.id,
        'paymentChannel': _method!.channel,
        'paymentSenderNumber': senderNumber,
        'paymentProofUrl': proofUrl,
      });

      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _SuccessView(phone: _phoneCtrl.text.trim());

    final event = widget.event;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 672),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Centered Bangla Title
                Text(
                  event.formTitle ?? 'অনলাইন রেজিস্ট্রেশন ফর্ম',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E3A8A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please complete the form below to secure your spot.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    color: const Color(0xFF444651),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // Full Name
                _label('Full Name'),
                TextFormField(
                  controller: _nameCtrl,
                  style: GoogleFonts.publicSans(
                    fontSize: 16,
                    color: const Color(0xFF131B2E),
                  ),
                  decoration: _inputDecor('Enter your full name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? t(ref, 'requiredField') : null,
                ),
                const SizedBox(height: 24),

                // Phone Number
                _label('Phone Number'),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.publicSans(
                    fontSize: 16,
                    color: const Color(0xFF131B2E),
                  ),
                  decoration: _inputDecor('e.g. +880 1712 345678'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? t(ref, 'requiredField') : null,
                ),
                const SizedBox(height: 24),

                // No. of Persons
                _label('No. of Persons'),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 200,
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFC5C5D3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => setState(
                            () => _personsCount = (_personsCount - 1).clamp(1, 999),
                          ),
                          icon: const Icon(
                            Icons.remove,
                            color: Color(0xFF1E3A8A),
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Text(
                          '$_personsCount',
                          style: GoogleFonts.publicSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF131B2E),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(
                            () => _personsCount = (_personsCount + 1).clamp(1, 999),
                          ),
                          icon: const Icon(
                            Icons.add,
                            color: Color(0xFF1E3A8A),
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Total Payment Box
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFC5C5D3).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL PAYMENT',
                            style: GoogleFonts.publicSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.7,
                              color: const Color(0xFF444651),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.bdt(_totalAmount),
                            style: GoogleFonts.publicSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Per person: ${Formatters.bdt(event.feePerPerson)}',
                        style: GoogleFonts.publicSans(
                          fontSize: 14,
                          color: const Color(0xFF444651),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Payment Method
                _label('Payment Method'),
                DropdownButtonFormField<EventPaymentMethod>(
                  initialValue: _method,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.expand_more,
                    color: Color(0xFF444651),
                  ),
                  decoration: _inputDecor('Select a payment method'),
                  hint: Text(
                    'Select a payment method',
                    style: GoogleFonts.publicSans(
                      fontSize: 16,
                      color: const Color(0xFF444651).withValues(alpha: 0.5),
                    ),
                  ),
                  items: _methods
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(
                            m.label,
                            style: GoogleFonts.publicSans(
                              fontSize: 16,
                              color: const Color(0xFF131B2E),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (m) => setState(() => _method = m),
                ),

                if (_method != null) ...[
                  const SizedBox(height: 24),
                  _label(_senderLabel(_method!.id)),
                  TextFormField(
                    controller: _senderCtrl,
                    keyboardType:
                        (_method!.id == 'Bank' || _method!.id == 'Cheque')
                            ? TextInputType.text
                            : TextInputType.phone,
                    style: GoogleFonts.publicSans(
                      fontSize: 16,
                      color: const Color(0xFF131B2E),
                    ),
                    decoration: _inputDecor(
                      'Enter ${_senderLabel(_method!.id).toLowerCase()}',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? t(ref, 'requiredField')
                            : null,
                  ),
                ],

                if (_method?.id == 'Cheque') ...[
                  const SizedBox(height: 24),
                  _label('Cheque Date'),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _chequeDate = picked);
                    },
                    child: InputDecorator(
                      decoration: _inputDecor('Select Date'),
                      child: Text(
                        _chequeDate != null
                            ? DateFormat.yMMMd().format(_chequeDate!)
                            : '—',
                        style: GoogleFonts.publicSans(
                          fontSize: 16,
                          color: const Color(0xFF131B2E),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                // Payment Screenshot Upload
                _label('Payment Screenshot'),
                _uploadZone(),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF316BF3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'COMPLETE REGISTRATION',
                                style: GoogleFonts.publicSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.7,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.publicSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.7,
            color: const Color(0xFF314156),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.publicSans(
        fontSize: 16,
        color: const Color(0xFF444651).withValues(alpha: 0.5),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFC5C5D3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFC5C5D3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF00236F), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _uploadZone() {
    if (_proofFile != null) {
      return InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 160,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF316BF3), width: 1.5),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(_proofFile!, fit: BoxFit.cover),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Change Photo',
                    style: GoogleFonts.publicSans(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          radius: const Radius.circular(12),
          color: const Color(0xFFC5C5D3),
          strokeWidth: 2,
          dashPattern: const [6, 4],
        ),
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                size: 36,
                color: Color(0xFF444651),
              ),
              const SizedBox(height: 12),
              Text(
                'Click to upload or drag and drop',
                style: GoogleFonts.publicSans(
                  color: const Color(0xFF131B2E),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'SVG, PNG, JPG or GIF (max. 5MB)',
                style: GoogleFonts.publicSans(
                  color: const Color(0xFF444651),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _senderLabel(String methodId) {
    if (methodId == 'Bank') return t(ref, 'senderNumberBank');
    if (methodId == 'Cheque') return t(ref, 'senderNumberCheque');
    return t(ref, 'senderNumberMobile');
  }
}

class _SuccessView extends ConsumerWidget {
  final String phone;

  const _SuccessView({required this.phone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFF2170E4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t(ref, 'registrationSubmitted'),
              style: GoogleFonts.publicSans(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: const Color(0xFF131B2E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              t(ref, 'registrationPendingMsg'),
              textAlign: TextAlign.center,
              style: GoogleFonts.publicSans(
                color: const Color(0xFF444651),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC5C5D3)),
              ),
              child: Text(
                phone,
                style: GoogleFonts.publicSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => GoRouter.of(context).go('/events/check'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF316BF3),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                t(ref, 'checkStatus'),
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


