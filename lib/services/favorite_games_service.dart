import 'dart:convert';
import 'package:http/http.dart' as http;

class FavoriteGameService {
  final String apiUrl =
      'https://questboard-games-api-dfh4c8emeqgwgjbd.eastasia-01.azurewebsites.net';
  final String token;

  FavoriteGameService({required this.token});

  Future<Map<String, dynamic>> addFavoriteGame(int gameId) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/favoriteGame?gameId=$gameId'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
        body: jsonEncode({'gameId': gameId}),
      );

      print('Status: ${response.statusCode}');
      print('Body: "${response.body}"');

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          return jsonDecode(response.body);
        } else {
          print('Jogo favorito adicionado com sucesso');
          return {'success': true, 'message': 'Jogo adicionado aos favoritos'};
        }
      } else {
        throw Exception('Erro ao favoritar o jogo: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao adicionar favorito: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getFavoriteGameByUser() async {
    final response = await http.get(
      Uri.parse('$apiUrl/favoriteGame/getAll'),
      headers: {'Content-Type': 'application/json', 'Authorization': token},
    );

    if (response.statusCode == 204) {
      return [];
    } else if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body) as List<dynamic>;
      } catch (e) {
        throw Exception('Erro ao tentar decodificar a resposta: $e');
      }
    } else {
      throw Exception(_handleError(response));
    }
  }

  String _handleError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

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
