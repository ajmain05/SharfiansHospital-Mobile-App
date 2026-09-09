import 'support_message.dart';

/// A "Help & Support" query/complaint thread — from
/// `GET /support/investor/:id/tickets[/:ticketId]`. [messages] is only
/// populated by the create and thread-detail endpoints; the list endpoint
/// omits it (the list screen only needs the ticket-level summary fields).
class SupportTicket {
  final String id;
  final String category;
  final String? subject;
  final String status; // OPEN | IN_PROGRESS | RESOLVED | CLOSED
  final String? assignedToName;
  final DateTime lastMessageAt;
  final String lastMessageSenderType; // INVESTOR | ADMIN
  final DateTime? investorLastReadAt;
  final DateTime createdAt;
  final List<SupportMessage>? messages;

  const SupportTicket({
    required this.id,
    required this.category,
    this.subject,
    required this.status,
    this.assignedToName,
    required this.lastMessageAt,
    required this.lastMessageSenderType,
    this.investorLastReadAt,
    required this.createdAt,
    this.messages,
  });

  /// An admin reply the investor hasn't opened the thread to see yet.
  bool get hasUnreadReply =>
      lastMessageSenderType == 'ADMIN' &&
      (investorLastReadAt == null || investorLastReadAt!.isBefore(lastMessageAt));

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: (json['id'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      subject: json['subject'] as String?,
      status: (json['status'] ?? 'OPEN').toString(),
      assignedToName: json['assignedToName'] as String?,
      lastMessageAt: DateTime.tryParse(json['lastMessageAt']?.toString() ?? '') ?? DateTime.now(),
      lastMessageSenderType: (json['lastMessageSenderType'] ?? 'INVESTOR').toString(),
      investorLastReadAt: json['investorLastReadAt'] == null
          ? null
          : DateTime.tryParse(json['investorLastReadAt'].toString()),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      messages: (json['messages'] as List?)
          ?.map((e) => SupportMessage.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
