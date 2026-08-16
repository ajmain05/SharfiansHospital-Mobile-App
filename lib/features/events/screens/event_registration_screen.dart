import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/network/cloudinary_uploader.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/event.dart';
import '../providers/events_providers.dart';

class EventRegistrationScreen extends ConsumerWidget {
  final String slug;

  const EventRegistrationScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventBySlugProvider(slug));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(t(ref, 'eventRegistrationTitle')),
      ),
      body: eventAsync.when(
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
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              t(ref, 'registrationClosed'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
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
  double? _uploadProgress;
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
      _uploadProgress = 0;
    });
    try {
      final proofUrl = await CloudinaryUploader.upload(
        _proofFile!,
        folder: 'event_registrations',
        onProgress: (p) => setState(() => _uploadProgress = p),
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
    final date = DateTime.tryParse(event.date);
    final dateLabel = date != null
        ? DateFormat('MMM d, yyyy · h:mm a').format(date)
        : event.date;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (event.offlineNotice != null && event.offlineNotice!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  event.offlineNotice!,
                  style: const TextStyle(
                    color: Color(0xFF9A3412),
                    fontSize: 13,
                  ),
                ),
              ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: event.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                          ),
                        ),
                        if (event.description != null &&
                            event.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            event.description!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        _metaRow(Icons.calendar_today_outlined, dateLabel),
                        const SizedBox(height: 6),
                        _metaRow(Icons.location_on_outlined, event.location),
                        const SizedBox(height: 6),
                        _metaRow(
                          Icons.payments_outlined,
                          '${Formatters.bdt(event.feePerPerson)} / person',
                        ),
                        if (event.maxCapacity != null) ...[
                          const SizedBox(height: 6),
                          _metaRow(
                            Icons.event_seat_outlined,
                            '${event.remainingSeats} / ${event.maxCapacity} seats left',
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_hasPaymentInfo(event.paymentConfig) ||
                event.branches.isNotEmpty)
              _PaymentInfoCard(event: event),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      event.formTitle ?? t(ref, 'registrationForm'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: '${t(ref, 'fullName')} *',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? t(ref, 'requiredField')
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: '${t(ref, 'phoneNumber')} *',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? t(ref, 'requiredField')
                          : null,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      t(ref, 'numberOfPersons'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _counterButton(
                          Icons.remove,
                          () => setState(
                            () => _personsCount = (_personsCount - 1).clamp(
                              1,
                              999,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '$_personsCount',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        _counterButton(
                          Icons.add,
                          () => setState(
                            () => _personsCount = (_personsCount + 1).clamp(
                              1,
                              999,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accent500.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t(ref, 'totalPayment'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            Formatters.bdt(_totalAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.accent600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '${t(ref, 'paymentMethod')} *',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<EventPaymentMethod>(
                      initialValue: _method,
                      isExpanded: true,
                      hint: Text(t(ref, 'selectPaymentMethod')),
                      items: _methods
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                m.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (m) => setState(() => _method = m),
                    ),
                    if (_method != null) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _senderCtrl,
                        keyboardType:
                            (_method!.id == 'Bank' || _method!.id == 'Cheque')
                            ? TextInputType.text
                            : TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: '${_senderLabel(_method!.id)} *',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? t(ref, 'requiredField')
                            : null,
                      ),
                    ],
                    if (_method?.id == 'Cheque') ...[
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _chequeDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: t(ref, 'chequeDateLabel'),
                          ),
                          child: Text(
                            _chequeDate != null
                                ? DateFormat.yMMMd().format(_chequeDate!)
                                : '—',
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      '${_method?.id == 'Cheque' ? t(ref, 'chequePhotoLabel') : t(ref, 'paymentProofLabel')} *',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _uploadZone(),
                    const SizedBox(height: 22),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                                value:
                                    _uploadProgress != null &&
                                        _uploadProgress! < 1
                                    ? _uploadProgress
                                    : null,
                              ),
                            )
                          : Text(t(ref, 'submitRegistration')),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t(ref, 'registrationDisclaimer'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasPaymentInfo(Map<String, dynamic> pc) =>
      pc.isNotEmpty &&
      (pc['bankName'] != null ||
          pc['bankAccount'] != null ||
          pc['mobileAccounts'] != null ||
          pc['bkashMerchant'] != null ||
          pc['bkashPersonal1'] != null ||
          pc['nagadPersonal'] != null);

  String _senderLabel(String methodId) {
    if (methodId == 'Bank') return t(ref, 'senderNumberBank');
    if (methodId == 'Cheque') return t(ref, 'senderNumberCheque');
    return t(ref, 'senderNumberMobile');
  }

  Widget _counterButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _uploadZone() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 160,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 2),
          color: AppColors.surface2,
        ),
        child: _proofFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 32,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(ref, 'uploadScreenshot'),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_proofFile!, fit: BoxFit.cover),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t(ref, 'changePhoto'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PaymentInfoCard extends ConsumerWidget {
  final Event event;

  const _PaymentInfoCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pc = event.paymentConfig;
    final methods = EventPaymentMethod.fromPaymentConfig(
      pc,
    ).where((m) => m.number != null);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(gradient: AppColors.brandGradient),
            child: Text(
              t(ref, 'paymentInfo'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pc['bankName'] != null || pc['bankAccount'] != null) ...[
                  Text(
                    pc['bankName']?.toString() ?? t(ref, 'bankDetails'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (pc['bankAccount'] != null)
                    Text(
                      '${t(ref, 'accountNumber')}: ${pc['bankAccount']}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  if (pc['bankRouting'] != null)
                    Text(
                      '${t(ref, 'routingNumber')}: ${pc['bankRouting']}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  const SizedBox(height: 12),
                ],
                for (final m in methods) ...[
                  Text(
                    '${m.label}: ${m.number}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (event.branches.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    t(ref, 'branchOffices'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  for (final b in event.branches) ...[
                    Text(
                      b['name']?.toString() ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    if (b['address'] != null)
                      Text(
                        b['address'].toString(),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (b['phone'] != null)
                      Text(
                        b['phone'].toString(),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.primary600,
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
                color: AppColors.accent500,
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
            const SizedBox(height: 10),
            Text(
              t(ref, 'registrationPendingMsg'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                phone,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () => GoRouter.of(context).go('/events/check'),
              child: Text(t(ref, 'checkStatus')),
            ),
          ],
        ),
      ),
    );
  }
}
