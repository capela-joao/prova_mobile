import 'package:flutter/material.dart';
import 'package:quest_board_mobile/pages/favorite_games_page.dart';
import '../models/user_model.dart';
import '../services/game_service.dart';
import '../models/post_model.dart';
import '../models/game_model.dart';
import '../models/new_post_args.dart';
import '../services/post_service.dart';
import '../widgets/post_list.dart';
import '../classes/app_routes.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  final User user;
  final String token;

  const HomePage({super.key, required this.user, required this.token});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  bool _isGameSelected = false;
  bool _isModalOpen = false;
  String? _selectedGameName;
  String? _selectedGameImage;
  int? _selectedGameId;
  int _rating = 0;
  List<Game> _games = [];
  bool _isLoading = false;
  File? _customImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _customImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _searchGames(String query) async {
    if (query.isEmpty) {
      setState(() {
        _games = [];
      });
      return;
    }

    if (widget.token == null) {
      print('ERRO: Token é null!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Token não encontrado. Faça login novamente.'),
        ),
      );
      return;
    }

    if (widget.token.isEmpty) {
      print('ERRO: Token está vazio!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Token inválido. Faça login novamente.'),
        ),
      );
      return;
    }

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

      // Limpar a lista de jogos para fechar o dropdown
      _games = [];
    });
  }

  Future<void> _submitPost() async {
    if (!_isGameSelected ||
        _titleController.text.isEmpty ||
        _reviewController.text.isEmpty ||
        _rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos!')),
      );
      return;
    }

    final postData = PostData(
      authorId: widget.user.id,
      gameId: _selectedGameId!,
      title: _titleController.text,
      content: _reviewController.text,
      imageURL: _customImage?.path ?? '',
      rate: _rating,
    );

    try {
      final response = await PostService().createPost(postData, widget.token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post criado com sucesso!')),
        );

        setState(() {
          _isModalOpen = false;
          _selectedGameName = null;
          _selectedGameImage = null;
          _selectedGameId = null;
          _isGameSelected = false;
          _titleController.clear();
          _reviewController.clear();
          _rating = 0;
          _customImage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao criar post: $e')));
      }
    }
  }

  void _logout() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _goToFavoriteGames() {
    Navigator.pushNamed(
      context,
      AppRoutes.favoritegames,
      arguments: FavoriteGamesPage(token: widget.token),
    );
  }

  void _goToProfile() {
    Navigator.pushNamed(
      context,
      AppRoutes.profile,
      arguments: NewPostArgs(user: widget.user, token: widget.token),
    );
  }

  void _goToHome() {
    Navigator.pushNamed(
      context,
      AppRoutes.dashboard,
      arguments: NewPostArgs(user: widget.user, token: widget.token),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101114),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'QuestBoard',
          style: TextStyle(color: Color(0xFFfefefe)),
        ),
        backgroundColor: const Color(0xFF101114),
      ),
      drawer: _buildDrawer(),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: Column(children: [_buildTopSection(), _buildPostsList()]),
            ),
            if (_isModalOpen) _buildPostModal(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        _buildSearchSection(),
        _buildGamesList(),
        _buildPostButton(),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF1A1A1A),
        child: Column(
          children: [
            _buildDrawerHeader(),
            _buildDrawerItem(Icons.home, 'Home', _goToHome),
            _buildDrawerItem(Icons.person, 'Profile', _goToProfile),
            _buildDrawerItem(Icons.star, 'Jogos Favoritos', _goToFavoriteGames),
            _buildDrawerItem(Icons.logout, 'Sair', _logout),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return SizedBox(
      height: 150,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(widget.user.avatarUrl),
              onBackgroundImageError: (exception, stackTrace) {
                print("Erro ao carregar a imagem de avatar.");
              },
            ),
            const SizedBox(height: 8),
            Text(
              widget.user.username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.user.email,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Text(
        'Crie um post sobre seu jogo favorito!',
        style: TextStyle(color: Colors.white, fontSize: 18),
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
          _searchGames(value);
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

  Widget _buildPostButton() {
    if (!_isGameSelected) {
      return const SizedBox(height: 16);
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (_selectedGameImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      _selectedGameImage!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Jogo selecionado: $_selectedGameName',
                    style: const TextStyle(color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isModalOpen = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text('Criar Post'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    return Expanded(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(2.0),
            child: Text(
              'Feed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: PostList(token: widget.token),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostModal() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isModalOpen = false;
          });
        },
        child: Container(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.all(24.0),
                padding: const EdgeInsets.all(20.0),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Postar sobre: $_selectedGameName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isModalOpen = false;
                              });
                            },
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Título do Post',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _reviewController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Escreva uma revisão sobre o jogo...',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Imagem do Post:',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.image),
                                label: const Text('Selecionar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (_customImage != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _customImage!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Avaliação:',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              SizedBox(
                                width: 250,
                                child: Row(
                                  children: List.generate(5, (index) {
                                    return IconButton(
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      icon: Icon(
                                        Icons.star,
                                        size: 24,
                                        color: index < _rating
                                            ? Colors.yellow
                                            : Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _rating = index + 1;
                                        });
                                      },
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$_rating / 5',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isModalOpen = false;
                              });
                            },
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _submitPost,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00c6ff),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Publicar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
