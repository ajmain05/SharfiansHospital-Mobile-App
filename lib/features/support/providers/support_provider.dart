import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/support_category.dart';
import '../../../models/support_ticket.dart';
import '../../investor_auth/providers/investor_session_provider.dart';
import '../data/support_repository.dart';

final supportRepositoryProvider = Provider((ref) => SupportRepository());

/// Admin-editable category list — fetched once per app session (not tied to
/// any investor account, so no autoDispose/invalidate needed the way ticket
/// data is).
final supportCategoriesProvider = FutureProvider<List<SupportCategory>>((ref) {
  return ref.read(supportRepositoryProvider).getCategories();
});

/// The active account's own queries. Same invalidate-and-refetch pattern as
/// notificationsInboxProvider — refreshed after any mutating action rather
/// than updated optimistically.
final supportTicketsProvider = FutureProvider.autoDispose<List<SupportTicket>>((ref) {
  final investorId = ref.watch(investorSessionProvider).activeAccount?.id;
  if (investorId == null) return Future.value(const []);
  return ref.read(supportRepositoryProvider).getTickets(investorId);
});

final supportTicketThreadProvider = FutureProvider.autoDispose.family<SupportTicket, String>((ref, ticketId) {
  final investorId = ref.watch(investorSessionProvider).activeAccount?.id;
  if (investorId == null) return Future.error('Not logged in');
  return ref.read(supportRepositoryProvider).getTicketThread(investorId, ticketId);
});
