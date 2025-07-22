import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../widgets/post_list_by_user.dart';
import '../services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  final User user;
  final String token;

  const ProfilePage({super.key, required this.user, required this.token});

  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User currentUser;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingAvatar = false;
  File? _customAvatar;
  String? _uploadedAvatarUrl;

  static const String CLOUDINARY_CLOUD_NAME = 'ddymlahvr';
  static const String CLOUDINARY_UPLOAD_PRESET = 'questboard_profiles';

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userProfile = await AuthService().getUserById(
        widget.user.id,
        widget.token,
      );
      setState(() {
        currentUser = User(
          id: userProfile.id,
          username: userProfile.username ?? currentUser.username,
          email: userProfile.email ?? currentUser.email,
          bio: userProfile.bio ?? currentUser.bio,
          avatarUrl: userProfile.avatarUrl ?? currentUser.avatarUrl,
          createdAt: currentUser.createdAt,
          updatedAt: currentUser.updatedAt,
        );
      });
    } catch (e) {
      print("Erro ao carregar perfil do usuário: $e");
    }
  }

  Future<void> _updateProfile({
    String? username,
    String? email,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final updatedUser = await AuthService().updateUser(
        id: widget.user.id,
        token: widget.token,
        username: username,
        email: email,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      setState(() {
        setState(() {
          currentUser = User(
            id: currentUser.id,
            username: username ?? currentUser.username,
            email: email ?? currentUser.email,
            bio: bio ?? currentUser.bio,
            avatarUrl: avatarUrl ?? currentUser.avatarUrl,
            updatedAt: currentUser.updatedAt,
            createdAt: currentUser.createdAt,
          );
        });
      });

      await _loadUserProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil atualizado com sucesso!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao atualizar perfil: $e")));
    }
  }

  Future<void> _pickAvatarImage() async {
    if (_isUploadingAvatar) return;

    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _customAvatar = File(pickedFile.path);
        _uploadedAvatarUrl = null;
      });

      await _uploadAvatarToCloudinary();
    }
  }

  Future<void> _uploadAvatarToCloudinary() async {
    if (_customAvatar == null) return;

    setState(() {
      _isUploadingAvatar = true;
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
        _customAvatar!.path,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          _uploadedAvatarUrl = jsonResponse['secure_url'];
          _isUploadingAvatar = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar enviado com sucesso!')),
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
        _isUploadingAvatar = false;
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
    return Scaffold(
      backgroundColor: const Color(0xFF101114),
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: const Color(0xFF00c6ff),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  Center(
                    child: const Text(
                      'Meus Posts',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Expanded(
              child: PostListByUser(user: widget.user, token: widget.token),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundImage: currentUser.avatarUrl.isNotEmpty
                  ? NetworkImage(currentUser.avatarUrl)
                  : null,
              backgroundColor: Colors.grey[700],
              child: currentUser.avatarUrl.isEmpty
                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUser.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentUser.email,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  if (currentUser.bio.isNotEmpty)
                    Text(
                      currentUser.bio,
                      style: const TextStyle(color: Colors.white),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Conta criada em: ${_formatDate(currentUser.createdAt)}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _showEditProfileModal(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00c6ff),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Editar Perfil',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileModal() {
    final usernameController = TextEditingController(
      text: currentUser.username,
    );
    final emailController = TextEditingController(text: currentUser.email);
    final bioController = TextEditingController(text: currentUser.bio);
    final avatarUrlController = TextEditingController(
      text: currentUser.avatarUrl,
    );

    _customAvatar = null;
    _uploadedAvatarUrl = currentUser.avatarUrl;
    _isUploadingAvatar = false;

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
                              'Editar Perfil',
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Avatar:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundImage: _customAvatar != null
                                          ? FileImage(_customAvatar!)
                                          : (_uploadedAvatarUrl != null &&
                                                _uploadedAvatarUrl!.isNotEmpty)
                                          ? NetworkImage(_uploadedAvatarUrl!)
                                          : null,
                                      backgroundColor: Colors.grey[700],
                                      child:
                                          (_customAvatar == null &&
                                              (_uploadedAvatarUrl == null ||
                                                  _uploadedAvatarUrl!.isEmpty))
                                          ? const Icon(
                                              Icons.person,
                                              size: 40,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton.icon(
                                      onPressed: _isUploadingAvatar
                                          ? null
                                          : () async {
                                              await _pickAvatarImage();
                                              setModalState(() {});
                                            },
                                      icon: _isUploadingAvatar
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.camera_alt),
                                      label: Text(
                                        _isUploadingAvatar
                                            ? 'Enviando...'
                                            : 'Alterar Avatar',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueGrey,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_uploadedAvatarUrl != null &&
                                    !_isUploadingAvatar)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '✓ Avatar carregado',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            const Text(
                              'Nome de usuário:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: usernameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Digite seu nome de usuário',
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

                            const Text(
                              'Email:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Digite seu email',
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

                            const Text(
                              'Bio:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: bioController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Conte um pouco sobre você...',
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
                              maxLines: 3,
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
                            onPressed: _isUploadingAvatar
                                ? null
                                : () {
                                    Map<String, String?> updates = {};

                                    if (usernameController.text !=
                                        currentUser.username) {
                                      updates['username'] = usernameController
                                          .text
                                          .trim();
                                    }
                                    if (emailController.text !=
                                        currentUser.email) {
                                      updates['email'] = emailController.text
                                          .trim();
                                    }
                                    if (bioController.text != currentUser.bio) {
                                      updates['bio'] = bioController.text
                                          .trim();
                                    }
                                    if (_uploadedAvatarUrl !=
                                        currentUser.avatarUrl) {
                                      updates['avatarUrl'] =
                                          _uploadedAvatarUrl?.isEmpty == true
                                          ? ''
                                          : _uploadedAvatarUrl;
                                    }

                                    if (updates.isNotEmpty) {
                                      _updateProfile(
                                        username: updates['username'],
                                        email: updates['email'],
                                        bio: updates['bio'],
                                        avatarUrl: updates['avatarUrl'],
                                      );
                                    }

                                    Navigator.of(context).pop();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00c6ff),
                              foregroundColor: Colors.white,
                            ),
                            child: _isUploadingAvatar
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
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
                                : const Text('Salvar'),
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
}
