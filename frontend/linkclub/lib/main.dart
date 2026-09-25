import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:linkclub/core/theme/app_theme.dart';
import 'package:linkclub/core/theme/theme_controller.dart';
import 'package:linkclub/presentation/clubs_page.dart';
import 'package:linkclub/presentation/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carga de credenciales desde archivo seguro
  await dotenv.load(fileName: ".env");

  // Inicialización de Supabase inyectando variables de entorno
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Carga la preferencia de tema guardada (claro/oscuro/sistema)
  await ThemeController.init();

  runApp(const LinkClubApp());
}

class LinkClubApp extends StatelessWidget {
  const LinkClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isUserLoggedIn =
        Supabase.instance.client.auth.currentSession != null;

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
