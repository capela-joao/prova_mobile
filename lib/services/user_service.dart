import 'dart:convert';
import 'package:quest_board_mobile/models/user_model.dart';
import 'package:http/http.dart' as http;

class UserService {
  static const String _apiUrl =
      'https://questboard-account-api.azurewebsites.net';

  Future<UserProfile> getUserProfile(String id) async {
    final response = await http.get(
      Uri.parse('$_apiUrl/user/publicProfile/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    print(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
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
