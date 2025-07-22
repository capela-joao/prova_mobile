import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  final User user;
  final String token;

  const NotificationsPage({super.key, required this.user, required this.token});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final notifications = await _notificationService.getNotificationByUser(
        widget.user.id,
        widget.token,
      );

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(
        notificationId,
        widget.token,
      );

      setState(() {
        final index = _notifications.indexWhere(
          (n) => n['id'] == notificationId,
        );
        if (index != -1) {
          _notifications[index]['read'] = true;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao marcar como lida: $e')));
    }
  }

  Future<void> _markAllAsRead() async {
    final unreadNotifications = _notifications
        .where((n) => n['read'] == false)
        .map((n) => n['id'].toString())
        .toList();

    if (unreadNotifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há notificações não lidas')),
      );
      return;
    }

    try {
      await _notificationService.markMultipleNotificationsAsRead(
        unreadNotifications,
        widget.token,
      );

      setState(() {
        for (var notification in _notifications) {
          notification['read'] = true;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas as notificações foram marcadas como lidas'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao marcar todas como lidas: $e')),
      );
    }
  }

  String _getNotificationMessage(Map<String, dynamic> notification) {
    final type = notification['type']?.toString().toLowerCase() ?? '';

    switch (type) {
      case 'like':
        return 'curtiu seu post';
      case 'comment':
        return 'comentou em seu post';
      default:
        return 'enviou uma notificação';
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101114),
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: const Color(0xFF00c6ff),
        actions: [
          if (_notifications.any((n) => n['read'] == false))
            IconButton(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all),
              tooltip: 'Marcar todas como lidas',
            ),
          IconButton(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00c6ff)),
            )
          : _error.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar notificações',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadNotifications,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00c6ff),
                    ),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : _notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.white54,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma notificação encontrada',
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Quando alguém interagir com seus posts,\nvocê verá as notificações aqui.',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: const Color(0xFF00c6ff),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  final isUnread = notification['read'] == false;
                  final createdAt = DateTime.parse(
                    notification['createdAt'] ??
                        DateTime.now().toIso8601String(),
                  );

                  return Card(
                    color: isUnread
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isUnread
                          ? const BorderSide(color: Color(0xFF00c6ff), width: 1)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: _getNotificationIconColor(
                          notification['type'] ?? '',
                        ).withOpacity(0.2),
                        child: Icon(
                          _getNotificationIcon(notification['type'] ?? ''),
                          color: _getNotificationIconColor(
                            notification['type'] ?? '',
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Alguém ${_getNotificationMessage(notification)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: isUnread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00c6ff),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(createdAt),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          if (notification['type']?.toString().toLowerCase() ==
                                  'comment' ||
                              notification['type']?.toString().toLowerCase() ==
                                  'like')
                            Padding(padding: const EdgeInsets.only(top: 4)),
                        ],
                      ),
                      onTap: () async {
                        if (isUnread) {
                          await _markAsRead(notification['id']);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
