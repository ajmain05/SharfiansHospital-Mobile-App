/// One message in a support ticket's thread — either the investor's own
/// text or an admin's reply, from `GET /support/investor/:id/tickets/:id`.
class SupportMessage {
  final String id;
  final String senderType; // 'INVESTOR' | 'ADMIN'
  final String? senderName; // populated only when senderType is ADMIN
  final String message;
  final String? attachmentUrl;
  final DateTime createdAt;

  const SupportMessage({
    required this.id,
    required this.senderType,
    this.senderName,
    required this.message,
    this.attachmentUrl,
    required this.createdAt,
  });

  bool get isFromAdmin => senderType == 'ADMIN';

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: (json['id'] ?? '').toString(),
      senderType: (json['senderType'] ?? 'INVESTOR').toString(),
      senderName: json['senderName'] as String?,
      message: (json['message'] ?? '').toString(),
      attachmentUrl: json['attachmentUrl'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
