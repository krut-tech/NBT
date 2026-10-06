class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final String? relatedId;
  final String? relatedType;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    this.relatedType,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String,
      message: json['message'] as String,
      relatedId: json['related_id'] as String?,
      relatedType: json['related_type'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
