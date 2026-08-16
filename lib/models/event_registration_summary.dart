/// Shared shape returned by both `GET /event-registrations/status/:token`
/// and `GET /event-registrations/check-phone/:phone` (the latter as a list).
class EventRegistrationSummary {
  final String? id;
  final String name;
  final int personsCount;
  final num totalAmount;
  final String status; // PENDING | APPROVED | REJECTED
  final String? qrCodeToken; // only present once APPROVED
  final String? scannedAt;
  final String? eventTitle;
  final String? eventDate;
  final String? eventLocation;
  final String? createdAt;

  const EventRegistrationSummary({
    this.id,
    required this.name,
    required this.personsCount,
    required this.totalAmount,
    required this.status,
    this.qrCodeToken,
    this.scannedAt,
    this.eventTitle,
    this.eventDate,
    this.eventLocation,
    this.createdAt,
  });

  factory EventRegistrationSummary.fromJson(Map<String, dynamic> json) {
    final event = (json['event'] as Map?)?.cast<String, dynamic>();
    return EventRegistrationSummary(
      id: json['id'] as String?,
      name: (json['name'] ?? '').toString(),
      personsCount: (json['personsCount'] as num?)?.toInt() ?? 1,
      totalAmount: (json['totalAmount'] as num?) ?? 0,
      status: (json['status'] ?? 'PENDING').toString(),
      qrCodeToken: json['qrCodeToken'] as String?,
      scannedAt: json['scannedAt'] as String?,
      eventTitle: event?['title'] as String?,
      eventDate: event?['date'] as String?,
      eventLocation: event?['location'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}
