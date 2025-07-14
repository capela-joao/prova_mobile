import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart'; // Certifique-se de criar um modelo de Post, caso não tenha

class PostService {
  static const String API_URL =
      'https://questboard-review-api.azurewebsites.net';
  Future<Map<String, dynamic>> createPost(PostData data, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/posts'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: jsonEncode(data.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception(
          'Erro ao criar post: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('Erro ao criar post: $e');
      throw Exception('Erro ao criar post.');
    }
  }

  Future<List<dynamic>> getPostsByUser(String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$API_URL/posts/user/$userId'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Erro ao recuperar posts do usuário: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('Erro ao recuperar posts: $e');
      return [];
    }
  }

  // Obtém todos os posts
  Future<List<dynamic>> getAllPosts(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$API_URL/posts'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      print('Status: ${response.statusCode}');
      print('Body: "${response.body}"');

      if (response.statusCode != 200) {
        throw Exception(
          'Erro ao recuperar posts: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('Erro ao recuperar posts: $e');
      return [];
    }
  }
}
