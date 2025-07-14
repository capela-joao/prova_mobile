class User {
  final String id;
  final String username;
  final String email;
  final String avatarUrl;
  final String bio;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.bio,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      avatarUrl: json['avatarUrl'] ?? "",
      bio: json['bio'] ?? "",
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.parse(value);
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    } else {
      return DateTime.now();
    }
  }
}

class UserProfile {
  final String username;
  final String avatarUrl;
  final String bio;

  UserProfile({
    required this.username,
    required this.avatarUrl,
    required this.bio,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'],
      avatarUrl: json['avatarUrl'] ?? "",
      bio: json['bio'] ?? "",
    );
  }
}
