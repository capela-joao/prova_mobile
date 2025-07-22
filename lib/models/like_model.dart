class LikeData {
  final String userId;
  final String postId;

  LikeData({required this.userId, required this.postId});

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'postId': postId};
  }

  factory LikeData.fromJson(Map<String, dynamic> json) {
    return LikeData(userId: json['userId'], postId: json['postId']);
  }
}
