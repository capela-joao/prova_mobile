import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/favorite_games_service.dart';
import '../models/game_model.dart';
import '../services/game_service.dart';

class FavoriteGameList extends StatefulWidget {
  final String token;

  const FavoriteGameList({super.key, required this.token});

  @override
  _FavoriteGameListState createState() => _FavoriteGameListState();
}

class _FavoriteGameListState extends State<FavoriteGameList> {
  List<dynamic> _favoriteGames = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, Game> _gameDetails = {};

  late FavoriteGameService _favoriteGameService;

  @override
  void initState() {
    super.initState();
    _favoriteGameService = FavoriteGameService(token: widget.token);
    _fetchFavoriteGames();
  }

  Future<void> _fetchFavoriteGames() async {
    try {
      final favoriteGames = await _favoriteGameService.getFavoriteGameByUser();

      if (mounted) {
        setState(() {
          _favoriteGames = favoriteGames ?? [];
        });
      }

      await _fetchGameDetails(favoriteGames);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print("Erro ao buscar jogos favoritos: $e");

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Erro ao buscar jogos favoritos: $e";
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erro ao buscar jogos favoritos: $e")),
            );
          }
        });
      }
    }
  }

  Future<void> _fetchGameDetails(List<dynamic> favoriteGames) async {
    List<Future<void>> futures = [];

    for (var game in favoriteGames) {
      final gameId = game['gameId']?.toString();

      if (gameId != null && !_gameDetails.containsKey(gameId)) {
        futures.add(_fetchSingleGameDetail(gameId));
      }
    }

    await Future.wait(futures);
  }

  Future<void> _fetchSingleGameDetail(String gameId) async {
    try {
      final gameDetails = await GameService().getGamesById(
        widget.token,
        int.parse(gameId),
      );

      debugPrint('Game details loaded: ${gameDetails?.name}');

      if (gameDetails != null && mounted) {
        setState(() {
          _gameDetails[gameId] = gameDetails;
        });
      }
    } catch (e) {
      print("Erro ao buscar detalhes do jogo $gameId: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar jogos favoritos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                  _gameDetails.clear();
                });
                _fetchFavoriteGames();
              },
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_favoriteGames.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum jogo favorito encontrado',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _favoriteGames.length,
      itemBuilder: (context, index) {
        final game = _favoriteGames[index];
        final gameId = game['gameId']?.toString();
        final gameDetails = _gameDetails[gameId];

        return Card(
          key: ValueKey(game['id'] ?? index),
          color: const Color(0xFF2b2f33),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (gameDetails == null && gameId != null)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                if (gameDetails != null) ...[
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          gameDetails.backgroundImage ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey[700],
                              child: const Icon(
                                Icons.gamepad,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gameDetails.name ?? 'Desconhecido',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (gameDetails.backgroundImage != null &&
                      gameDetails.backgroundImage!.isNotEmpty)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          gameDetails.backgroundImage!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 50),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],

                if (gameDetails == null && gameId == null)
                  const Text(
                    'Jogo sem ID válido',
                    style: TextStyle(color: Colors.white70),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
