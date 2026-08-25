/// Mirrors the backend's `Event` Prisma model as returned by
/// `GET /events/public` and `GET /events/public/:slug`.
class Event {
  final String id;
  final String title;
  final String slug;
  final String? description;
  final String date;
  final String location;
  final num feePerPerson;
  final String? imageUrl;
  final bool isActive;
  final Map<String, dynamic> paymentConfig;
  final List<Map<String, dynamic>> branches;
  final int? maxCapacity;
  final String? registrationDeadline;
  final String? formTitle;
  final String? offlineNotice;
  final int totalRegistered;

  const Event({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    required this.date,
    required this.location,
    required this.feePerPerson,
    this.imageUrl,
    this.isActive = true,
    this.paymentConfig = const {},
    this.branches = const [],
    this.maxCapacity,
    this.registrationDeadline,
    this.formTitle,
    this.offlineNotice,
    this.totalRegistered = 0,
  });

  bool get isDeadlinePassed {
    if (registrationDeadline == null) return false;
    final deadline = DateTime.tryParse(registrationDeadline!);
    return deadline != null && DateTime.now().isAfter(deadline);
  }

  bool get isCapacityFull =>
      maxCapacity != null && totalRegistered >= maxCapacity!;

  int? get remainingSeats => maxCapacity != null
      ? (maxCapacity! - totalRegistered).clamp(0, maxCapacity!)
      : null;

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'] as String,
    title: (json['title'] ?? '').toString(),
    slug: (json['slug'] ?? '').toString(),
    description: json['description'] as String?,
    date: (json['date'] ?? '').toString(),
    location: (json['location'] ?? '').toString(),
    feePerPerson: (json['feePerPerson'] as num?) ?? 0,
    imageUrl: json['imageUrl'] as String?,
    isActive: json['isActive'] as bool? ?? true,
    paymentConfig:
        (json['paymentConfig'] as Map?)?.cast<String, dynamic>() ?? const {},
    branches:
        (json['branches'] as List?)
            ?.map((b) => (b as Map).cast<String, dynamic>())
            .toList() ??
        const [],
    maxCapacity: (json['maxCapacity'] as num?)?.toInt(),
    registrationDeadline: json['registrationDeadline'] as String?,
    formTitle: json['formTitle'] as String?,
    offlineNotice: json['offlineNotice'] as String?,
    totalRegistered: (json['totalRegistered'] as num?)?.toInt() ?? 0,
  );
}

/// `GET /events/public/live-snapshot/:id` — polled on pull-to-refresh
/// rather than over a socket connection, to keep Phase 2 dependency-light.
class EventLiveSnapshot {
  final String eventId;
  final String title;
  final int maxCapacity;
  final int totalRegistrations;
  final int confirmedRegistrations;
  final int? remainingSeats;
  final String? lastUpdatedAt;

  const EventLiveSnapshot({
    required this.eventId,
    required this.title,
    required this.maxCapacity,
    required this.totalRegistrations,
    required this.confirmedRegistrations,
    this.remainingSeats,
    this.lastUpdatedAt,
  });

  factory EventLiveSnapshot.fromJson(Map<String, dynamic> json) =>
      EventLiveSnapshot(
        eventId: (json['eventId'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        maxCapacity: (json['maxCapacity'] as num?)?.toInt() ?? 0,
        totalRegistrations: (json['totalRegistrations'] as num?)?.toInt() ?? 0,
        confirmedRegistrations:
            (json['confirmedRegistrations'] as num?)?.toInt() ?? 0,
        remainingSeats: (json['remainingSeats'] as num?)?.toInt(),
        lastUpdatedAt: json['lastUpdatedAt'] as String?,
      );
}

/// A single payment method choice, built client-side from `Event.paymentConfig`
/// — direct port of the dynamic method list in the website's `EventRegistration.jsx`.
class EventPaymentMethod {
  final String id;
  final String label;
  final String channel;
  final String? number;

  const EventPaymentMethod({
    required this.id,
    required this.label,
    required this.channel,
    this.number,
  });

  static List<EventPaymentMethod> fromPaymentConfig(Map<String, dynamic> pc) {
    final methods = <EventPaymentMethod>[];
    final seen = <String>{};

    final mobileAccounts = <Map<String, String>>[];
    final rawAccounts = pc['mobileAccounts'];
    if (rawAccounts is List && rawAccounts.isNotEmpty) {
      for (final a in rawAccounts) {
        if (a is Map) {
          mobileAccounts.add({
            'provider': (a['provider'] ?? '').toString(),
            'type': (a['type'] ?? '').toString(),
            'number': (a['number'] ?? '').toString(),
          });
        }
      }
    } else {
      void addIfPresent(String key, String provider, String type) {
        final number = pc[key];
        if (number != null && number.toString().isNotEmpty) {
          mobileAccounts.add({
            'provider': provider,
            'type': type,
            'number': number.toString(),
          });
        }
      }

      // bkashMerchant removed as per request
      addIfPresent('bkashPersonal1', 'bKash', 'Personal');
      addIfPresent('bkashPersonal2', 'bKash/Nagad', 'Personal');
      addIfPresent('nagadPersonal', 'Nagad', 'Personal');
    }

    for (final acc in mobileAccounts) {
      final id = '${acc['provider']}-${acc['type']}';
      if (seen.add(id)) {
        methods.add(
          EventPaymentMethod(
            id: id,
            label: '${acc['provider']} (${acc['type']})',
            channel: '${acc['provider']} ${acc['type']}',
            number: acc['number'],
          ),
        );
      }
    }

    final hasBank =
        (pc['bankName']?.toString().isNotEmpty ?? false) ||
        (pc['bankAccount']?.toString().isNotEmpty ?? false);
    if (hasBank) {
      methods.add(
        const EventPaymentMethod(
          id: 'Bank',
          label: 'Bank',
          channel: 'Bank Transfer',
        ),
      );
    }

    return methods;
  }
}
