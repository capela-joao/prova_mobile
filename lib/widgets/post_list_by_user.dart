import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../models/post_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class PostListByUser extends StatefulWidget {
  final User user;
  final String token;

  const PostListByUser({super.key, required this.user, required this.token});

  @override
  _PostListByUserState createState() => _PostListByUserState();
}

class _PostListByUserState extends State<PostListByUser> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;
  File? _customImage;
  String? _uploadedImageUrl;

  static const String CLOUDINARY_CLOUD_NAME = 'ddymlahvr';
  static const String CLOUDINARY_UPLOAD_PRESET = 'questboard_profiles';

  List<dynamic> _posts = [];
  bool _isLoading = true;
  Map<String, UserProfile> _userProfiles = {};

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  int _parseRate(dynamic rate) {
    if (rate is int) return rate;
    if (rate is String) {
      return int.tryParse(rate) ?? 1;
    }
    return 1;
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

  Future<void> _deletePost(String postId) async {
    try {
      await PostService().deletePost(postId, widget.token);
      setState(() {
        _posts.removeWhere((post) => post['id'] == postId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post deletado com sucesso!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao deletar post: $e")));
    }
  }

  Future<void> _editPost(
    String postId,
    String title,
    String content,
    String? imageUrl,
    int rate,
  ) async {
    try {
      final editPostData = EditPostData(
        title: title,
        content: content,
        imageURL: imageUrl ?? '',
        rate: rate,
      );

      await PostService().editPost(editPostData, postId, widget.token);

      setState(() {
        final postIndex = _posts.indexWhere((post) => post['id'] == postId);
        if (postIndex != -1) {
          _posts[postIndex]['title'] = title;
          _posts[postIndex]['content'] = content;
          _posts[postIndex]['imageURL'] = imageUrl;
          _posts[postIndex]['rate'] = rate;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post editado com sucesso!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao editar post: $e")));
    }
  }

  Future<void> _pickImageForEdit() async {
    if (_isUploadingImage) return;

    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _customImage = File(pickedFile.path);
        _uploadedImageUrl = null;
      });

      await _uploadImageToCloudinary();
    }
  }

  Future<void> _uploadImageToCloudinary() async {
    if (_customImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/upload',
        ),
      );

      request.fields['upload_preset'] = CLOUDINARY_UPLOAD_PRESET;

      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        _customImage!.path,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          _uploadedImageUrl = jsonResponse['secure_url'];
          _isUploadingImage = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagem enviada com sucesso!')),
          );
        }
      } else {
        final errorResponse = json.decode(response.body);
        final errorMessage =
            errorResponse['error']?['message'] ?? 'Erro ao fazer upload';
        throw Exception(errorMessage);
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro no upload: $e')));
      }
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
                      Row(
                        children: [
                          if (userProfile != null) ...[
                            CircleAvatar(
                              backgroundImage: NetworkImage(
                                userProfile.avatarUrl,
                              ),
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
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white70,
                            ),
                            onPressed: () => {
                              debugPrint("Botão de opções pressionado!"),
                              _showOptionsMenu(post),
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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

  void _showEditModal(Map<String, dynamic> post) {
    final titleController = TextEditingController(text: post['title']);
    final contentController = TextEditingController(text: post['content']);
    int selectedRate = _parseRate(post['rate']);

    _customImage = null;
    _uploadedImageUrl = post['imageURL'];
    _isUploadingImage = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Editar Post',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: titleController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Título do Post',
                                hintStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
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
                              controller: contentController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Descrição do post...',
                                hintStyle: const TextStyle(
                                  color: Colors.white70,
                                ),
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
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _isUploadingImage
                                          ? null
                                          : () async {
                                              await _pickImageForEdit();
                                              setModalState(() {});
                                            },
                                      icon: _isUploadingImage
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.image),
                                      label: Text(
                                        _isUploadingImage
                                            ? 'Enviando...'
                                            : 'Selecionar',
                                      ),
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
                                      )
                                    else if (_uploadedImageUrl != null &&
                                        _uploadedImageUrl!.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          _uploadedImageUrl!,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  width: 60,
                                                  height: 60,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[700],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.image,
                                                    color: Colors.white,
                                                  ),
                                                );
                                              },
                                        ),
                                      ),
                                    if (_uploadedImageUrl != null &&
                                        !_isUploadingImage)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          '✓ Imagem carregada',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                          ),
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
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
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
                                              color: index < selectedRate
                                                  ? Colors.yellow
                                                  : Colors.grey,
                                            ),
                                            onPressed: () {
                                              setModalState(() {
                                                selectedRate = index + 1;
                                              });
                                            },
                                          );
                                        }),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$selectedRate / 5',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isUploadingImage
                                ? null
                                : () {
                                    _editPost(
                                      post['id'],
                                      titleController.text,
                                      contentController.text,
                                      _uploadedImageUrl?.isEmpty == true
                                          ? null
                                          : _uploadedImageUrl,
                                      selectedRate,
                                    );
                                    Navigator.of(context).pop();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00c6ff),
                              foregroundColor: Colors.white,
                            ),
                            child: _isUploadingImage
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Aguarde...'),
                                    ],
                                  )
                                : Text('Salvar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showOptionsMenu(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2b2f33),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text(
                'Editar Post',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _showEditModal(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Deletar Post',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deletePost(post['id']);
              },
            ),
          ],
        );
      },
    );
  }
}
