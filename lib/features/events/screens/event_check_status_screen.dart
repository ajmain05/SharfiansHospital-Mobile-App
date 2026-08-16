import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/event_registration_summary.dart';
import '../providers/events_providers.dart';

class EventCheckStatusScreen extends ConsumerStatefulWidget {
  const EventCheckStatusScreen({super.key});

  @override
  ConsumerState<EventCheckStatusScreen> createState() => _EventCheckStatusScreenState();
}

class _EventCheckStatusScreenState extends ConsumerState<EventCheckStatusScreen> {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  List<EventRegistrationSummary>? _results;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _results = null;
    });
    try {
      final results = await ref.read(eventsRepositoryProvider).checkByPhone(phone);
      setState(() {
        _results = results;
        if (results.isEmpty) _error = t(ref, 'noRegistrationsFound');
      });
    } catch (e) {
      setState(() => _error = t(ref, 'somethingWentWrong'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(t(ref, 'checkStatusTitle')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t(ref, 'checkStatusSubtitle'), style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: t(ref, 'phoneNumber'), prefixIcon: const Icon(Icons.phone_outlined)),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _check,
                    child: _loading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.search_rounded),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            if (_results != null && _results!.isNotEmpty) ...[
              const SizedBox(height: 20),
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
    final cfg = _statusConfig(result.status);
    final date = result.eventDate != null ? DateTime.tryParse(result.eventDate!) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: result.qrCodeToken != null ? () => context.push('/events/status/${result.qrCodeToken}') : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.eventTitle ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    if (date != null) Text(DateFormat('MMM d, yyyy').format(date), style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(Formatters.bdt(result.totalAmount), style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: cfg.$2, borderRadius: BorderRadius.circular(20)),
                child: Text(cfg.$1, style: TextStyle(color: cfg.$3, fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
              if (result.qrCodeToken != null) const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
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
