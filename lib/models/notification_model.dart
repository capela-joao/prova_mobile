class Notification {
  final String id;
  final String receiverId;
  final String senderId;
  final String type;
  final String redirect;
  final bool read;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.receiverId,
    required this.senderId,
    required this.type,
    required this.redirect,
    required this.read,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] ?? '',
      receiverId: json['receiverId'] ?? '',
      senderId: json['senderId'] ?? '',
      type: json['type'] ?? '',
      redirect: json['redirect'] ?? '',
      read: json['read'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiverId': receiverId,
      'senderId': senderId,
      'type': type,
      'redirect': redirect,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Notification copyWith({
    String? id,
    String? receiverId,
    String? senderId,
    String? type,
    String? redirect,
    bool? read,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      receiverId: receiverId ?? this.receiverId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      redirect: redirect ?? this.redirect,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Notification(id: $id, type: $type, read: $read, redirect: $redirect)';
  }

  bool get isUnread => !read;

  String get postId {
    return redirect.replaceFirst('/', '');
  }

  bool get isLikeNotification => type.toLowerCase() == 'like';
  bool get isCommentNotification => type.toLowerCase() == 'comment';

  String getDisplayMessage(String? senderName) {
    final displayName = senderName ?? 'Alguém';

    switch (type.toLowerCase()) {
      case 'like':
        return '$displayName curtiu seu post';
      case 'comment':
        return '$displayName comentou em seu post';
      default:
        return 'Nova notificação de $displayName';
    }
  }
}

enum NotificationType {
  like('Like'),
  comment('Comment'),
  follow('Follow'),
  mention('Mention'),
  system('System');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value.toLowerCase() == value.toLowerCase(),
      orElse: () => NotificationType.system,
    );
  }
}
