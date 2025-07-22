import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/profile_page.dart';
import 'pages/home_page.dart';
import 'pages/favorite_games_page.dart';
import 'pages/notification_page.dart';
import 'services/session_service.dart';
import 'pages/logout_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = SessionService();
  final hasSession = await session.hasSession();

  runApp(MyApp(startRoute: hasSession ? '/dashboard' : '/'));
}

class MyApp extends StatelessWidget {
  final String startRoute;

  const MyApp({super.key, required this.startRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      initialRoute: startRoute,
      routes: {
        '/': (context) => const LoginPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/logout': (context) => const LogoutPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/dashboard') {
          return MaterialPageRoute(
            builder: (_) => FutureBuilder(
              future: SessionService().getUser(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return FutureBuilder(
                  future: SessionService().getToken(),
                  builder: (context, tokenSnap) {
                    if (!tokenSnap.hasData) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return HomePage(
                      user: snapshot.data!,
                      token: tokenSnap.data!,
                    );
                  },
                );
              },
            ),
          );
        }

        if (settings.name == '/profile') {
          return MaterialPageRoute(
            builder: (_) => FutureBuilder(
              future: SessionService().getUser(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return FutureBuilder(
                  future: SessionService().getToken(),
                  builder: (context, tokenSnap) {
                    if (!tokenSnap.hasData) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return ProfilePage(
                      user: snapshot.data!,
                      token: tokenSnap.data!,
                    );
                  },
                );
              },
            ),
          );
        }

        if (settings.name == '/favoritegames') {
          return MaterialPageRoute(
            builder: (_) => FutureBuilder(
              future: SessionService().getUser(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return FutureBuilder(
                  future: SessionService().getToken(),
                  builder: (context, tokenSnap) {
                    if (!tokenSnap.hasData) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return FavoriteGamesPage(token: tokenSnap.data!);
                  },
                );
              },
            ),
          );
        }

        if (settings.name == '/notification') {
          return MaterialPageRoute(
            builder: (_) => FutureBuilder(
              future: SessionService().getUser(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return FutureBuilder(
                  future: SessionService().getToken(),
                  builder: (context, tokenSnap) {
                    if (!tokenSnap.hasData) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return NotificationsPage(
                      user: snapshot.data!,
                      token: tokenSnap.data!,
                    );
                  },
                );
              },
            ),
          );
        }
        return null;
      },
    );
  }
}
