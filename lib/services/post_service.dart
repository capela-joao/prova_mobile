import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

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

      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      print('Erro ao criar post: $e');
      throw Exception('Erro ao criar post.');
    }
  }

  Future<Map<String, dynamic>> deletePost(String postId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$API_URL/posts/$postId'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Erro ao deletar post: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }

      if (response.statusCode == 204 || response.body.isEmpty) {
        return {'success': true, 'message': 'Post deletado com sucesso'};
      }

      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      print('Erro ao deletar post: $e');
      throw Exception('Erro ao deletar post.');
    }
  }

  Future<Map<String, dynamic>> editPost(
    EditPostData data,
    String postId,
    String token,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$API_URL/posts/$postId'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: jsonEncode(data.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Erro ao editar post: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }

      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      print('Erro ao editar post: $e');
      throw Exception('Erro ao editar post.');
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

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data;
    } catch (e) {
      print('Erro ao recuperar posts: $e');
      return [];
    }
  }

  Future<List<dynamic>> getAllPosts(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$API_URL/posts'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Erro ao recuperar posts: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data;
    } catch (e) {
      print('Erro ao recuperar posts: $e');
      return [];
    }
  }

  
}
