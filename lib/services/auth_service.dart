import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/auth_response.dart';

class AuthService {
  static const String _apiUrl =
      'https://questboard-account-api.azurewebsites.net';

  Future<User> register({
    required String username,
    required String email,
    required String bio,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_apiUrl/user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'bio': bio,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.isNotEmpty) {
        return User.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        return User(
          id: "",
          username: "",
          email: "",
          avatarUrl: "",
          bio: "",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } else {
      throw Exception(_handleError(response));
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
    String provider = '',
  }) async {
    final response = await http.post(
      Uri.parse('$_apiUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'provider': provider,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return AuthResponse.fromJson(decoded);
    } else {
      throw Exception(_handleError(response));
    }
  }

  Future<User> updateUser({
    required String id,
    required String token,
    String? username,
    String? email,
    String? bio,
    String? avatarUrl,
  }) async {
    final response = await http.put(
      Uri.parse('$_apiUrl/user/$id'),
      headers: {'Content-Type': 'application/json', 'Authorization': token},
      body: jsonEncode({
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception(_handleError(response));
    }
  }

  Future<User> getUserById(String id, String token) async {
    final response = await http.get(
      Uri.parse('$_apiUrl/user/$id'),
      headers: {'Content-Type': 'application/json', 'Authorization': token},
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception(_handleError(response));
    }
  }

  String _handleError(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is Map<String, dynamic>) {
        return decoded['error'] ?? decoded['message'] ?? 'Erro desconhecido';
      } else {
        return 'Erro no formato da resposta do servidor';
      }
    } catch (e) {
      print('Erro ao tentar decodificar a resposta: $e');
      return response.body.isNotEmpty
          ? 'Erro do servidor: ${response.body}'
          : 'Erro inesperado: ${response.statusCode}';
    }
  }
}
