import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/event.dart';
import '../../../models/event_registration_summary.dart';
import '../data/events_repository.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) => EventsRepository());

final publicEventsProvider = FutureProvider<List<Event>>((ref) {
  return ref.watch(eventsRepositoryProvider).getPublicEvents();
});

final eventBySlugProvider = FutureProvider.family<Event, String>((ref, slug) {
  return ref.watch(eventsRepositoryProvider).getEventBySlug(slug);
});

final liveSnapshotProvider = FutureProvider.family<EventLiveSnapshot, String>((ref, eventId) {
  return ref.watch(eventsRepositoryProvider).getLiveSnapshot(eventId);
});

final eventStatusProvider = FutureProvider.family<EventRegistrationSummary, String>((ref, token) {
  return ref.watch(eventsRepositoryProvider).getStatusByToken(token);
});
