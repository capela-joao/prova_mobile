import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quest_board_mobile/models/game_model.dart';

class GameService {
  static const String API_URL =
      'https://questboard-games-api-dfh4c8emeqgwgjbd.eastasia-01.azurewebsites.net';

  // Busca jogos com base na pesquisa
  Future<List<dynamic>> searchGames(String query, String? token) async {
    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado. Token ausente.');
    }
    try {
      final url = Uri.parse('$API_URL/catalogo/rawg/searchGames');
      final params = {'search': query};

      final uri = Uri.parse('$url?${Uri(queryParameters: params).query}');
      final response = await http.get(
        uri,
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      print(response.body);

      if (response.statusCode != 200) {
        throw Exception(
          'Erro ao buscar jogos: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }

      final data = jsonDecode(latin1.decode(response.bodyBytes));

      if (data['results'] == null) {
        throw Exception('Nenhum jogo encontrado para a pesquisa.');
      }

      return data['results'];
    } catch (e) {
      print('Erro na requisição: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getTopGames(String token) async {
    try {
      final responsedata = await http.get(
        Uri.parse('$API_URL/catalogo/rawg/getTopGames'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );
      final response = jsonDecode(latin1.decode(responsedata.bodyBytes));

      if (response.statusCode != 200) {
        throw Exception('Erro ao recuperar jogos mais populares');
      }

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      print('Erro ao recuperar jogos: $e');
      return [];
    }
  }

  Future<Game> getGamesById(String token, int gameId) async {
    try {
      final response = await http.get(
        Uri.parse('$API_URL/catalogo/rawg/gameById?gameId=$gameId'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        print('Erro na API. Status Code: ${response.statusCode}');
        print('Corpo da resposta: ${response.body}');
        throw Exception(
          'Erro ao recuperar detalhes do jogo: ${response.statusCode}',
        );
      }

      final data = jsonDecode(latin1.decode(response.bodyBytes));

      print('Resposta da API: $data');

      if (data is Map<String, dynamic> && data.isNotEmpty) {
        return Game.fromJson(data);
      } else {
        throw Exception('Nenhum jogo encontrado para o ID: $gameId');
      }
    } catch (e) {
      print('Erro ao recuperar detalhes do jogo: $e');
      rethrow;
    }
  }
}
