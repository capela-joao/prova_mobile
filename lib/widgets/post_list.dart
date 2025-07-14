import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class PostList extends StatefulWidget {
  final String token;

  const PostList({super.key, required this.token});

  @override
  _PostListState createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, UserProfile> _userProfiles = {};

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final posts = await PostService().getAllPosts(widget.token);
      final response = jsonEncode(posts);

      for (var post in posts) {
        final authorId = post['authorId'];
        if (authorId != null && !_userProfiles.containsKey(authorId)) {
          try {
            final userProfile = await UserService().getUserProfile(authorId);
            setState(() {
              _userProfiles[authorId] = userProfile;
            });
          } catch (e) {
            print("Erro ao buscar perfil do usuário $authorId: $e");
          }
        }
      }

      if (mounted) {
        setState(() {
          _posts = posts ?? [];
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print("Erro ao buscar posts: $e");

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Erro ao buscar posts: $e";
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Erro ao buscar posts: $e")));
          }
        });
      }
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
            Text(
              'Erro ao carregar posts',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchPosts();
              },
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum post encontrado',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        final authorId = post['authorId'];
        final userProfile = _userProfiles[authorId];

        return Card(
          key: ValueKey(post['id'] ?? index),
          color: const Color(0xFF2b2f33),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userProfile != null) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(
                          userProfile.avatarUrl ?? '',
                        ),
                        radius: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        userProfile.username ?? 'Desconhecido',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  post['title'] ?? 'Sem título',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post['content'] ?? 'Sem conteúdo',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                if (post['imageURL'] != null &&
                    post['imageURL'].toString().isNotEmpty)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        post['imageURL'],
                        height: 200,
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
                const SizedBox(height: 8),
                Text(
                  'Avaliação: ${post['rate'] ?? 0} / 5',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
