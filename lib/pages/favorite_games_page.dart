import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import '../services/game_service.dart';
import '../models/game_model.dart';
import '../services/favorite_games_service.dart';
import '../widgets/favorite_game_list.dart';
import 'package:image_picker/image_picker.dart';

class FavoriteGamesPage extends StatefulWidget {
  final String token;

  const FavoriteGamesPage({super.key, required this.token});

  @override
  _FavoriteGamesPageState createState() => _FavoriteGamesPageState();
}

class _FavoriteGamesPageState extends State<FavoriteGamesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Game> _games = [];
  List<int> _favoriteGamesIds = [];
  bool _isLoading = false;
  bool _isGameSelected = false;
  String? _selectedGameName;
  String? _selectedGameImage;
  int? _selectedGameId;
  final ImagePicker _picker = ImagePicker();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _searchGamesWithDebounce(String query) {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchGames(query);
    });
  }

  Future<void> _searchGames(String query) async {
    if (query.isEmpty) {
      setState(() {
        _games = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await GameService().searchGames(query, widget.token);
      setState(() {
        _games = result.map((json) => Game.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error searching games: $e");

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Erro ao buscar jogos: $e")));
        });
      }
    }
  }

  void _selectGame(Game game) {
    setState(() {
      _selectedGameName = game.name;
      _selectedGameImage = game.backgroundImage;
      _selectedGameId = game.id;
      _isGameSelected = true;
    });
  }

  late FavoriteGameService _favoriteGameService;

  @override
  void initState() {
    super.initState();
    _favoriteGameService = FavoriteGameService(token: widget.token);
  }

  Future<void> _toggleFavoriteGame() async {
    if (_selectedGameId == null) return;
    try {
      final favorite = await _favoriteGameService.addFavoriteGame(
        _selectedGameId!,
      );

      debugPrint('Favorito adicionado: ${jsonEncode(favorite)}');

      setState(() {
        _favoriteGamesIds.add(_selectedGameId!);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jogo adicionado aos favoritos')),
      );
    } catch (e) {
      debugPrint('Erro ao adicionar favorito: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar favoritos: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101114),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Jogos Favoritos',
          style: TextStyle(color: Color(0xFFfefefe)),
        ),
        backgroundColor: const Color(0xFF101114),
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            _buildSearchSection(),
            _buildGamesList(),
            _buildFavoriteButton(),
            _buildFavoriteGamesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Digite o nome do jogo...',
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          _searchGamesWithDebounce(value);
        },
      ),
    );
  }

  Widget _buildGamesList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_games.isEmpty) {
      return const SizedBox(height: 16);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListView.builder(
          itemCount: _games.length,
          itemBuilder: (context, index) {
            final game = _games[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  game.backgroundImage,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[700],
                      child: const Icon(Icons.gamepad, color: Colors.white),
                    );
                  },
                ),
              ),
              title: Text(
                game.name,
                style: const TextStyle(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _selectGame(game),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    if (!_isGameSelected) {
      return const SizedBox(height: 16);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _toggleFavoriteGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 45),
        ),
        child: const Text('Adicionar aos Favoritos'),
      ),
    );
  }

  Widget _buildFavoriteGamesList() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: FavoriteGameList(token: widget.token),
      ),
    );
  }
}
