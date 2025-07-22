import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationBadge extends StatefulWidget {
  final String userId;
  final String token;
  final VoidCallback? onTap;
  final bool showOnlyBadge;

  const NotificationBadge({
    super.key,
    required this.userId,
    required this.token,
    this.onTap,
    this.showOnlyBadge = false,
  });

  @override
  _NotificationBadgeState createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final count = await _notificationService.getUnreadNotificationCount(
        widget.userId,
        widget.token,
      );

      if (mounted) {
        setState(() {
          _unreadCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _unreadCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  void updateCount() {
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showOnlyBadge) {
      return _unreadCount > 0 && !_isLoading
          ? Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : const SizedBox.shrink();
    }

    return Stack(
      children: [
        IconButton(
          onPressed: () {
            widget.onTap?.call();
            Future.delayed(const Duration(seconds: 1), () {
              _loadUnreadCount();
            });
          },
          icon: const Icon(Icons.notifications, color: Colors.white),
        ),
        if (_unreadCount > 0 && !_isLoading)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
