class PostData {
  final String authorId;
  final int gameId;
  final String title;
  final String content;
  final String imageURL;
  final int rate;

  PostData({
    required this.authorId,
    required this.gameId,
    required this.title,
    required this.content,
    required this.imageURL,
    required this.rate,
  });

  Map<String, dynamic> toJson() {
    return {
      'authorId': authorId,
      'gameId': gameId,
      'title': title,
      'content': content,
      'imageURL': imageURL,
      'rate': rate,
    };
  }
}

class EditPostData {
  final String title;
  final String content;
  final String imageURL;
  final double rate;

  EditPostData({
    required this.title,
    required this.content,
    required this.imageURL,
    required this.rate,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'imageURL': imageURL,
      'rate': rate,
    };
  }
}
