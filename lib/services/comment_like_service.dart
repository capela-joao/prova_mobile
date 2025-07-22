import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comment_model.dart';
import '../models/like_model.dart';

class CommentLikeService {
  static const String API_URL =
      'https://questboard-review-api.azurewebsites.net';

  Future<Map<String, dynamic>> createComment(
    CommentData data,
    String token,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/comments'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: jsonEncode(data.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = response.body.isNotEmpty
            ? response.body
            : 'Erro ao criar comentário.';
        throw Exception('$error');
      }

      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      print('Erro ao criar comentário: $e');
      throw Exception('Erro ao criar comentário.');
    }
  }

  Future<List<dynamic>> getCommentsByPost(String postId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$API_URL/comments/post/$postId'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao buscar comentários');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data;
    } catch (e) {
      print('Erro ao buscar comentários: $e');
      throw Exception('Erro ao buscar comentários');
    }
  }

  Future<Map<String, dynamic>> sendLike(LikeData data, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$API_URL/likes'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: jsonEncode(data.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = response.body.isNotEmpty
            ? response.body
            : 'Erro ao dar like.';
        throw Exception('$error');
      }

      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      print('Erro ao dar like: $e');
      throw Exception('Erro ao dar like.');
    }
  }

  Future<int> getLikesByPost(String postId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$API_URL/likes/post/$postId'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao buscar likes');
      }

      final likesCount = jsonDecode(utf8.decode(response.bodyBytes));

      if (likesCount is int) {
        return likesCount;
      } else if (likesCount is double) {
        return likesCount.toInt();
      } else if (likesCount is String) {
        try {
          final doubleValue = double.parse(likesCount);
          return doubleValue.toInt();
        } catch (e) {
          return int.parse(likesCount);
        }
      } else {
        final stringValue = likesCount.toString();
        try {
          final doubleValue = double.parse(stringValue);
          return doubleValue.toInt();
        } catch (e) {
          return int.parse(stringValue);
        }
      }
    } catch (e) {
      print('Erro ao buscar likes: $e');
      throw Exception('Erro ao buscar likes');
    }
  }

  Future<Map<String, dynamic>> deleteLike(LikeData data, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$API_URL/likes'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: jsonEncode(data.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = response.body.isNotEmpty
            ? response.body
            : 'Erro ao remover like.';
        throw Exception('$error');
      }

      if (response.statusCode == 204 || response.body.isEmpty) {
        return {'success': true, 'message': 'Like removido com sucesso'};
      }

      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      print('Erro ao remover like: $e');
      throw Exception('Erro ao remover like.');
    }
  }

  Future<bool> isLiked(String userId, String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$API_URL/likes/isLiked/$userId/$postId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final error = response.body.isNotEmpty
            ? response.body
            : 'Erro ao verificar like.';
        throw Exception('$error');
      }

      final result = jsonDecode(utf8.decode(response.bodyBytes));

      if (result is bool) {
        return result;
      } else if (result is String) {
        return result.toLowerCase() == 'true';
      } else if (result is int) {
        return result != 0;
      } else if (result is double) {
        return result != 0.0;
      } else {
        return bool.parse(result.toString());
      }
    } catch (e) {
      print('Erro ao verificar like: $e');
      throw Exception('Erro ao verificar like.');
    }
  }
}
