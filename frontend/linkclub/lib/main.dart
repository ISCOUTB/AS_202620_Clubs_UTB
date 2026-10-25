import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linkclub/core/theme/app_theme.dart';
import 'package:linkclub/core/theme/theme_controller.dart';
import 'package:linkclub/presentation/clubs_page.dart';
import 'package:linkclub/presentation/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {};

  await dotenv.load(fileName: ".env");

  await ThemeController.init();

  const storage = FlutterSecureStorage();
  final String? jwtToken = await storage.read(key: 'jwt_token');
  final bool isUserLoggedIn = jwtToken != null;

  runApp(LinkClubApp(isUserLoggedIn: isUserLoggedIn));
}

class LinkClubApp extends StatelessWidget {
  final bool isUserLoggedIn;

  const LinkClubApp({super.key, required this.isUserLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LinkClub',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,

          home: isUserLoggedIn ? const ClubsPage() : const LoginScreen(),
        );
      },
    );
  }
}
