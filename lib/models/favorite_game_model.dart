class FavoriteGame {
  final String name;
  final String imageUrl;

  FavoriteGame({required this.name, required this.imageUrl});

  Map<String, dynamic> toJson() {
    return {'name': name, 'imageUrl': imageUrl};
  }

  factory FavoriteGame.fromJson(Map<String, dynamic> json) {
    return FavoriteGame(name: json['name'], imageUrl: json['imageUrl']);
  }
}
