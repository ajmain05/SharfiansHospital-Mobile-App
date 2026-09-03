import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/investor_category.dart';
import '../../../models/investor.dart';
import '../../settings/providers/site_settings_provider.dart';
import '../data/admin_dashboard_repository.dart';

class StaffDirectoryScreen extends ConsumerStatefulWidget {
  const StaffDirectoryScreen({super.key});

  @override
  ConsumerState<StaffDirectoryScreen> createState() => _StaffDirectoryScreenState();
}

class _StaffDirectoryScreenState extends ConsumerState<StaffDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<dynamic> _investors = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchInvestors(''); // Fetch initial list (recent 50)
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchInvestors(query);
    });
  }

  Future<void> _fetchInvestors(String query) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminDashboardRepoProvider);
      final investors = await repo.searchInvestors(query);
      if (mounted) {
        setState(() {
          _investors = investors;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to search: $e')));
      }
    }
  }

  void _showInvestorDetails(Map<String, dynamic> raw) {
    final investor = Investor.fromJson(raw);
    final pricePerShare = ref.read(siteSettingsProvider).maybeWhen(
      data: (s) => s.pricePerShare,
      orElse: () => InvestorCategory.defaultPricePerShare,
    );
    final tier = InvestorCategory.of(investor.shareAmount, tierOverride: investor.tierOverride, pricePerShare: pricePerShare);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary100,
                      foregroundColor: AppColors.primary700,
                      child: Text(
                        investor.displayName.isNotEmpty
                            ? investor.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            investor.displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            investor.investorId,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (investor.isDirector)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: tier.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tier.label,
                          style: TextStyle(
                            color: tier.color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                _detailRow('Phone', investor.phone),
                _detailRow('Address', investor.address),
                _detailRow('Share Amount', Formatters.bdt(investor.shareAmount)),
                _detailRow('Monthly Payment', Formatters.bdt(investor.monthlyPayment)),
                _detailRow('Persons', '${investor.numberOfPersons}'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _callPhone(investor.phone);
                    },
                    icon: const Icon(Icons.call_rounded, color: Colors.green),
                    label: const Text('Call'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callPhone(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch dialer')));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Investor Directory'),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _investors.isEmpty
                    ? const Center(child: Text('No investors found.', style: TextStyle(color: Colors.grey, fontSize: 16)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _investors.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final investor = _investors[index];
                          return InkWell(
                            onTap: () => _showInvestorDetails(
                              (investor as Map).cast<String, dynamic>(),
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary100,
                                    foregroundColor: AppColors.primary700,
                                    child: Text(
                                      (investor['name'] ?? '?')[0].toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          investor['name'] ?? 'Unknown',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          investor['phone'] ?? 'No phone',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                        ),
                                        if (investor['status'] != null)
                                          Text(
                                            investor['status'],
                                            style: TextStyle(
                                              color: investor['status'] == 'DIRECTOR' ? Colors.purple : Colors.green,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.call_rounded, color: Colors.green),
                                    onPressed: () => _callPhone(investor['phone']),
                                  ),
                                ],
                              ),
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
