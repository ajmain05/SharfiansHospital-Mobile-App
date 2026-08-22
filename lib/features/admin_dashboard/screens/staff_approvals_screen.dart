import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/adaptive_colors.dart';
import '../data/admin_dashboard_repository.dart';

class StaffApprovalsScreen extends ConsumerStatefulWidget {
  const StaffApprovalsScreen({super.key});

  @override
  ConsumerState<StaffApprovalsScreen> createState() => _StaffApprovalsScreenState();
}

class _StaffApprovalsScreenState extends ConsumerState<StaffApprovalsScreen> {
  List<dynamic> events = [];
  String? selectedEventId;
  List<dynamic> registrations = [];
  bool isLoadingEvents = true;
  bool isLoadingRegs = false;
  String? processingId;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final repo = ref.read(adminDashboardRepoProvider);
      final evts = await repo.getEvents();
      if (mounted) {
        setState(() {
          events = evts;
          isLoadingEvents = false;
          if (events.isNotEmpty) {
            selectedEventId = events.first['id'];
            _loadRegistrations();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingEvents = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load events: $e')));
      }
    }
  }

  Future<void> _loadRegistrations() async {
    if (selectedEventId == null) return;
    setState(() => isLoadingRegs = true);
    try {
      final repo = ref.read(adminDashboardRepoProvider);
      final regs = await repo.getEventRegistrations(selectedEventId!);
      if (mounted) {
        setState(() {
          registrations = regs.where((r) => r['status'] == 'PENDING').toList();
          isLoadingRegs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingRegs = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load registrations: $e')));
      }
    }
  }

  Future<void> _handleApprove(String regId) async {
    setState(() => processingId = regId);
    try {
      await ref.read(adminDashboardRepoProvider).approveRegistration(regId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration approved! SMS sent.')));
        _loadRegistrations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approval failed: $e')));
      }
    } finally {
      if (mounted) setState(() => processingId = null);
    }
  }

  Future<void> _handleReject(String regId) async {
    setState(() => processingId = regId);
    try {
      await ref.read(adminDashboardRepoProvider).rejectRegistration(regId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration rejected.')));
        _loadRegistrations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rejection failed: $e')));
      }
    } finally {
      if (mounted) setState(() => processingId = null);
    }
  }

  void _showProofImage(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgFill,
      appBar: AppBar(
        title: const Text('Pending Approvals'),
      ),
      body: isLoadingEvents
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Event Selector
                if (events.isNotEmpty)
                  Container(
                    color: context.cardFill,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedEventId,
                      hint: const Text('Select Event'),
                      items: events.map((ev) {
                        return DropdownMenuItem<String>(
                          value: ev['id'],
                          child: Text(ev['title']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedEventId = val);
                          _loadRegistrations();
                        }
                      },
                    ),
                  ),

                // Registrations List
                Expanded(
                  child: isLoadingRegs
                      ? const Center(child: CircularProgressIndicator())
                      : registrations.isEmpty
                          ? Center(child: Text('No pending registrations.', style: TextStyle(fontSize: 16, color: context.textMed)))
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: registrations.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final reg = registrations[index];
                                final bool isProcessing = processingId == reg['id'];

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: context.cardFill,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: context.borderFill),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              reg['name'] ?? 'Unknown',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.yellow.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'PENDING',
                                              style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      _InfoRow(icon: Icons.phone_rounded, text: reg['phone'] ?? ''),
                                      _InfoRow(icon: Icons.group_rounded, text: '${reg['personsCount']} Persons'),
                                      _InfoRow(icon: Icons.payments_rounded, text: '৳${(reg['totalAmount'] ?? 0).toString()} via ${reg['paymentMethod'] ?? reg['paymentChannel'] ?? 'Unknown'}'),
                                      if (reg['paymentSenderNumber'] != null)
                                        _InfoRow(icon: Icons.account_balance_rounded, text: 'Sender: ${reg['paymentSenderNumber']}'),
                                      if (reg['paymentTransactionId'] != null)
                                        _InfoRow(icon: Icons.receipt_long_rounded, text: 'TrxID: ${reg['paymentTransactionId']}'),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Actions
                                      Row(
                                        children: [
                                          if (reg['paymentProofUrl'] != null)
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () => _showProofImage(reg['paymentProofUrl']),
                                                icon: const Icon(Icons.image_rounded, size: 16),
                                                label: const Text('Proof'),
                                              ),
                                            ),
                                          if (reg['paymentProofUrl'] != null)
                                            const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: isProcessing ? null : () => _handleApprove(reg['id']),
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                              child: isProcessing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Approve'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: isProcessing ? null : () => _handleReject(reg['id']),
                                              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                                              child: const Text('Reject'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: context.textMed),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: context.textMed),
            ),
          ),
        ],
      ),
    );
  }
}
