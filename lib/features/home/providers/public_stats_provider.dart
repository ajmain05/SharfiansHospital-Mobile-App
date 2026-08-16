import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../investor_auth/providers/investor_session_provider.dart';

/// Live totals for the home screen (`GET /investors/public-stats`), public/no-auth.
final publicStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(investorRepositoryProvider);
  return repo.getPublicStats();
});
