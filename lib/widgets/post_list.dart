import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../services/comment_like_service.dart';
import '../models/comment_model.dart';
import '../models/like_model.dart';

class PostList extends StatefulWidget {
  final String token;
  final String userId;

  const PostList({super.key, required this.token, required this.userId});

  @override
  _PostListState createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, UserProfile> _userProfiles = {};
  Map<String, int> _likeCounts = {};
  Map<String, bool> _userLikedPosts = {};
  Map<String, bool> _likingPosts = {};
  Map<String, List<Comment>> _comments = {};
  Map<String, int> _commentCounts = {};
  Map<String, bool> _showComments = {};
  Map<String, String> _commentTexts = {};
  Map<String, bool> _submittingComment = {};
  Map<String, bool> _loadingComments = {};

  final CommentLikeService _commentLikeService = CommentLikeService();

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final posts = await PostService().getAllPosts(widget.token);
      jsonEncode(posts);

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

      await _fetchPostInteractions(posts);

      if (mounted) {
        setState(() {
          _posts = posts;
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

  Future<void> _fetchPostInteractions(List<dynamic> posts) async {
    Map<String, int> tempLikeCounts = {};
    Map<String, bool> tempUserLikedPosts = {};
    Map<String, List<Comment>> tempComments = {};
    Map<String, int> tempCommentCounts = {};
    Map<String, UserProfile> tempUserProfiles = Map.from(_userProfiles);

    for (var post in posts) {
      final postId = post['id'];
      if (postId != null) {
        try {
          final likeCount = await _commentLikeService.getLikesByPost(
            postId,
            widget.token,
          );
          tempLikeCounts[postId] = likeCount;
        } catch (e) {
          print("Erro ao buscar likes do post $postId: $e");
          tempLikeCounts[postId] = 0;
        }

        if (widget.userId != null) {
          try {
            final isLiked = await _commentLikeService.isLiked(
              widget.userId,
              postId,
            );
            tempUserLikedPosts[postId] = isLiked;
          } catch (e) {
            print("Erro ao verificar like do usuário no post $postId: $e");
            tempUserLikedPosts[postId] = false;
          }
        } else {
          tempUserLikedPosts[postId] = false;
        }

        try {
          final comments = await _commentLikeService.getCommentsByPost(
            postId,
            widget.token,
          );
          final commentList = comments.map((c) => Comment.fromJson(c)).toList();
          tempComments[postId] = commentList;
          tempCommentCounts[postId] = commentList.length;

          for (var comment in commentList) {
            if (!tempUserProfiles.containsKey(comment.userId)) {
              try {
                final userProfile = await UserService().getUserProfile(
                  comment.userId,
                );
                tempUserProfiles[comment.userId] = userProfile;
              } catch (e) {
                print("Erro ao buscar perfil do usuário ${comment.userId}: $e");
              }
            }
          }
        } catch (e) {
          print("Erro ao buscar comentários do post $postId: $e");
          tempComments[postId] = [];
          tempCommentCounts[postId] = 0;
        }
      }
    }

    if (mounted) {
      setState(() {
        _likeCounts.addAll(tempLikeCounts);
        _userLikedPosts.addAll(tempUserLikedPosts);
        _comments.addAll(tempComments);
        _commentCounts.addAll(tempCommentCounts);
        _userProfiles.addAll(tempUserProfiles);
      });
    }
  }

  Future<void> _handleLike(String postId) async {
    if (_likingPosts[postId] == true) return;

    setState(() {
      _likingPosts[postId] = true;
    });

    try {
      final isCurrentlyLiked = _userLikedPosts[postId] ?? false;
      final likeData = LikeData(userId: widget.userId, postId: postId);

      if (isCurrentlyLiked) {
        await _commentLikeService.deleteLike(likeData, widget.token);
        setState(() {
          _userLikedPosts[postId] = false;
          _likeCounts[postId] = (_likeCounts[postId] ?? 1) - 1;
        });
      } else {
        await _commentLikeService.sendLike(likeData, widget.token);
        setState(() {
          _userLikedPosts[postId] = true;
          _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
        });
      }

      final newCount = await _commentLikeService.getLikesByPost(
        postId,
        widget.token,
      );
      final likeStatus = await _commentLikeService.isLiked(
        widget.userId,
        postId,
      );

      setState(() {
        _likeCounts[postId] = newCount;
        _userLikedPosts[postId] = likeStatus;
      });
    } catch (e) {
      print('Erro ao curtir/descurtir o post: $e');
      try {
        final newCount = await _commentLikeService.getLikesByPost(
          postId,
          widget.token,
        );
        final likeStatus = await _commentLikeService.isLiked(
          widget.userId,
          postId,
        );
        setState(() {
          _likeCounts[postId] = newCount;
          _userLikedPosts[postId] = likeStatus;
        });
      } catch (syncError) {
        print('Erro ao sincronizar estado após falha: $syncError');
      }
    } finally {
      setState(() {
        _likingPosts[postId] = false;
      });
    }
  }

  Future<void> _loadComments(String postId) async {
    setState(() {
      _loadingComments[postId] = true;
    });

    try {
      final comments = await _commentLikeService.getCommentsByPost(
        postId,
        widget.token,
      );
      final commentList = comments.map((c) => Comment.fromJson(c)).toList();

      for (var comment in commentList) {
        if (!_userProfiles.containsKey(comment.userId)) {
          try {
            final userProfile = await UserService().getUserProfile(
              comment.userId,
            );
            _userProfiles[comment.userId] = userProfile;
          } catch (e) {
            print("Erro ao buscar perfil do usuário ${comment.userId}: $e");
          }
        }
      }

      setState(() {
        _comments[postId] = commentList;
        _commentCounts[postId] = commentList.length;
      });
    } catch (e) {
      print('Erro ao carregar comentários: $e');
    } finally {
      setState(() {
        _loadingComments[postId] = false;
      });
    }
  }

  Future<void> _toggleComments(String postId) async {
    final isCurrentlyShowing = _showComments[postId] ?? false;

    if (!isCurrentlyShowing) {
      await _loadComments(postId);
    }

    setState(() {
      _showComments[postId] = !isCurrentlyShowing;
    });
  }

  Future<void> _handleCommentSubmit(String postId) async {
    final content = _commentTexts[postId]?.trim();
    if (content == null || content.isEmpty || widget.userId == null) return;

    setState(() {
      _submittingComment[postId] = true;
    });

    try {
      final commentData = CommentData(
        userId: widget.userId,
        postId: postId,
        content: content,
      );

      await _commentLikeService.createComment(commentData, widget.token);

      setState(() {
        _commentTexts[postId] = '';
      });

      await _loadComments(postId);
    } catch (e) {
      print('Erro ao enviar comentário: $e');
    } finally {
      setState(() {
        _submittingComment[postId] = false;
      });
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

        final postId = post['id'] ?? '';
        final isLiking = _likingPosts[postId] ?? false;
        final isLiked = _userLikedPosts[postId] ?? false;
        final likeCount = _likeCounts[postId] ?? 0;
        final commentCount = _commentCounts[postId] ?? 0;
        final isShowingComments = _showComments[postId] ?? false;
        final isSubmittingComment = _submittingComment[postId] ?? false;
        final isLoadingComments = _loadingComments[postId] ?? false;
        final currentCommentText = _commentTexts[postId] ?? '';

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
                        backgroundImage: NetworkImage(userProfile.avatarUrl),
                        radius: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        userProfile.username,
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _handleLike(postId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLiking)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.white70,
                                size: 20,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              '$likeCount',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _toggleComments(postId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$commentCount comentários',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (isShowingComments) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Colors.grey),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundImage:
                            _userProfiles[widget.userId]?.avatarUrl != null
                            ? NetworkImage(
                                _userProfiles[widget.userId]!.avatarUrl,
                              )
                            : null,
                        radius: 16,
                        child: _userProfiles[widget.userId]?.avatarUrl == null
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            TextField(
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Escreva um comentário...',
                                hintStyle: TextStyle(color: Colors.white54),
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              onChanged: (value) {
                                setState(() {
                                  _commentTexts[postId] = value;
                                });
                              },
                              controller:
                                  TextEditingController(
                                      text: currentCommentText,
                                    )
                                    ..selection = TextSelection.fromPosition(
                                      TextPosition(
                                        offset: currentCommentText.length,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed:
                                    currentCommentText.trim().isNotEmpty &&
                                        !isSubmittingComment
                                    ? () => _handleCommentSubmit(postId)
                                    : null,
                                child: isSubmittingComment
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Comentar'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isLoadingComments)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_comments[postId]?.isNotEmpty == true)
                    Column(
                      children: _comments[postId]!.map((comment) {
                        final commentUser = _userProfiles[comment.userId];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundImage: commentUser?.avatarUrl != null
                                    ? NetworkImage(commentUser!.avatarUrl)
                                    : null,
                                radius: 16,
                                child: commentUser?.avatarUrl == null
                                    ? const Icon(Icons.person, size: 16)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      commentUser?.username ??
                                          'Usuário desconhecido',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment.content,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Nenhum comentário ainda. Seja o primeiro a comentar!',
                        style: TextStyle(color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
