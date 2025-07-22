import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String API_URL =
      'https://questboard-notifications-api.azurewebsites.net';

  Future<List<dynamic>> getNotificationByUser(
    String userId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$API_URL/notification/$userId'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final error = response.body.isNotEmpty
            ? response.body
            : 'Erro ao receber notificação do usuário.';
        throw Exception(error);
      }

      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      print('Erro ao buscar notificações do usuário: $e');
      throw Exception('Erro ao receber notificação do usuário.');
    }
  }

  Future<List<dynamic>> getLastNotificationByUser(
    String userId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$API_URL/notification/newest/$userId'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final error = response.body.isNotEmpty
            ? response.body
            : 'Erro ao receber as últimas notificações do usuário.';
        throw Exception(error);
      }

      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      print('Erro ao buscar últimas notificações do usuário: $e');
      throw Exception('Erro ao receber as últimas notificações do usuário.');
    }
  }

  Future<void> markNotificationAsRead(
    String notificationId,
    String token,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$API_URL/notification/read/$notificationId'),
        headers: {'Authorization': token, 'Content-Type': 'application/json'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Notificação marcada como lida com sucesso!');
      } else {
        final error = response.body.isNotEmpty
            ? response.body
            : 'Erro ao marcar notificação como lida. Status: ${response.statusCode}';
        print('Erro: $error');
        throw Exception(error);
      }
    } catch (e) {
      print('Erro ao marcar notificação como lida: $e');
      throw Exception('Erro ao marcar notificação como lida.');
    }
  }

  Future<void> markMultipleNotificationsAsRead(
    List<String> notificationIds,
    String token,
  ) async {
    try {
      for (String notificationId in notificationIds) {
        await markNotificationAsRead(notificationId, token);
      }
    } catch (e) {
      print('Erro ao marcar múltiplas notificações como lidas: $e');
      throw Exception('Erro ao marcar notificações como lidas.');
    }
  }

  Future<int> getUnreadNotificationCount(String userId, String token) async {
    try {
      final notifications = await getNotificationByUser(userId, token);

      int unreadCount = 0;
      for (var notification in notifications) {
        if (notification['read'] == false) {
          unreadCount++;
        }
      }

      return unreadCount;
    } catch (e) {
      print('Erro ao contar notificações não lidas: $e');
      return 0;
    }
  }

  Future<List<dynamic>> getNotificationsByType(
    String userId,
    String token,
    String type,
  ) async {
    try {
      final allNotifications = await getNotificationByUser(userId, token);

      return allNotifications
          .where(
            (notification) =>
                notification['type']?.toString().toLowerCase() ==
                type.toLowerCase(),
          )
          .toList();
    } catch (e) {
      print('Erro ao filtrar notificações por tipo: $e');
      throw Exception('Erro ao filtrar notificações por tipo.');
    }
  }

  Future<List<dynamic>> getUnreadNotifications(
    String userId,
    String token,
  ) async {
    try {
      final allNotifications = await getNotificationByUser(userId, token);

      return allNotifications
          .where((notification) => notification['read'] == false)
          .toList();
    } catch (e) {
      print('Erro ao buscar notificações não lidas: $e');
      throw Exception('Erro ao buscar notificações não lidas.');
    }
  }
}
