class Game {
  final int id;
  final String name;
  final String description;
  final String backgroundImage;
  final double rating;
  final List<String> platforms;
  final List<String> genres;

  Game({
    required this.id,
    required this.name,
    required this.description,
    required this.backgroundImage,
    this.rating = 0.0,
    required this.platforms,
    required this.genres,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    try {
      return Game(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Nome não disponível',
        description: json['description'] ?? 'Descrição não disponível',
        backgroundImage: json['background_image'] ?? '',
        rating: (json['rating'] != null)
            ? (json['rating'] is int
                  ? (json['rating'] as int).toDouble()
                  : json['rating'] as double)
            : 0.0,
        platforms: _extractPlatforms(json['platforms']),
        genres: _extractGenres(json['genres']),
      );
    } catch (e) {
      print('Erro ao criar Game a partir do JSON: $e');
      print('JSON recebido: $json');

      return Game(
        id: json['id'] ?? 0,
        name: json['name'] ?? 'Nome não disponível',
        description: 'Erro ao carregar descrição',
        backgroundImage: '',
        rating: 0.0,
        platforms: [],
        genres: [],
      );
    }
  }

  static List<String> _extractPlatforms(dynamic platformsData) {
    if (platformsData == null) return [];

    try {
      return List<String>.from(
        platformsData.map((platform) {
          if (platform is Map<String, dynamic>) {
            return platform['platform']?['name'] ?? 'Plataforma desconhecida';
          }
          return 'Plataforma desconhecida';
        }),
      );
    } catch (e) {
      print('Erro ao extrair plataformas: $e');
      return [];
    }
  }

  static List<String> _extractGenres(dynamic genresData) {
    if (genresData == null) return [];

    try {
      return List<String>.from(
        genresData.map((genre) {
          if (genre is Map<String, dynamic>) {
            return genre['name'] ?? 'Gênero desconhecido';
          }
          return 'Gênero desconhecido';
        }),
      );
    } catch (e) {
      print('Erro ao extrair gêneros: $e');
      return [];
    }
  }

  @override
  String toString() {
    return 'Game{id: $id, name: $name, rating: $rating, description: $description}';
  }
}
