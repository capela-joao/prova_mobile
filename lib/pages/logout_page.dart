import 'package:flutter/material.dart';
import '../services/session_service.dart';

class LogoutPage extends StatelessWidget {
  const LogoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () async {
      await SessionService().clearSession();
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    });

    return const Scaffold(
      backgroundColor: Color(0xFF101114),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
