/// One entry in a device's in-app notification history — the persisted
/// counterpart to a push the device actually received, from
/// `GET /notifications/inbox`.
class NotificationItem {
  final String id; // NotificationRecipient id — used for the per-item mark-as-read call
  final String title;
  final String body;
  final String? imageUrl;
  final String? link;
  final String? category; // 'payment' | 'event' | 'general'
  final DateTime sentAt;
  final DateTime? readAt;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.link,
    this.category,
    required this.sentAt,
    this.readAt,
  });

  bool get isUnread => readAt == null;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      imageUrl: json['imageUrl'] as String?,
      link: json['link'] as String?,
      category: json['category'] as String?,
      sentAt: DateTime.tryParse(json['sentAt']?.toString() ?? '') ?? DateTime.now(),
      readAt: json['readAt'] == null ? null : DateTime.tryParse(json['readAt'].toString()),
    );
  }

  NotificationItem copyWith({DateTime? readAt}) => NotificationItem(
        id: id,
        title: title,
        body: body,
        imageUrl: imageUrl,
        link: link,
        category: category,
        sentAt: sentAt,
        readAt: readAt ?? this.readAt,
      );
}
