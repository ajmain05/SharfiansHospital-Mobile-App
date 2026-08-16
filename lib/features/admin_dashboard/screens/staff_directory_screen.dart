import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../../../core/theme/app_colors.dart';
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
                            onTap: () {},
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
