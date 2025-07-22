class CommentData {
  final String userId;
  final String postId;
  final String content;

  CommentData({
    required this.userId,
    required this.postId,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'postId': postId, 'content': content};
  }

  factory CommentData.fromJson(Map<String, dynamic> json) {
    return CommentData(
      userId: json['userId'],
      postId: json['postId'],
      content: json['content'],
    );
  }
}

class Comment {
  final String id;
  final String userId;
  final String postId;
  final String content;
  final String createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.postId,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      userId: json['userId'],
      postId: json['postId'],
      content: json['content'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'postId': postId,
      'content': content,
      'createdAt': createdAt,
    };
  }
}
