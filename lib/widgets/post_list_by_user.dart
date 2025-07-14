import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';

class PostListByUser extends StatefulWidget {
  final User user;
  final String token;

  const PostListByUser({super.key, required this.user, required this.token});

  @override
  _PostListByUserState createState() => _PostListByUserState();
}

class _PostListByUserState extends State<PostListByUser> {
  List<dynamic> _posts = [];
  bool _isLoading = true;
  Map<String, UserProfile> _userProfiles = {};

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final posts = await PostService().getPostsByUser(
        widget.user.id,
        widget.token,
      );
      final response = jsonEncode(posts);
      debugPrint(response);

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

      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Erro ao buscar posts: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao buscar posts: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            shrinkWrap: true,
            itemCount: _posts.length,
            itemBuilder: (context, index) {
              final post = _posts[index];
              final authorId = post['authorId'];
              final userProfile = _userProfiles[authorId];

              return Card(
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
                        post['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post['content'],
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      if (post['imageURL'] != null &&
                          post['imageURL'].isNotEmpty)
                        Center(
                          child: Image.network(
                            post['imageURL'],
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 8),

                      Text(
                        'Avaliação: ${post['rate']} / 5',
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
