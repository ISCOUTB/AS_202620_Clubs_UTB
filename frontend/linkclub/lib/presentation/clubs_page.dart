import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:linkclub/core/theme/theme_controller.dart';
import 'package:linkclub/presentation/login_screen.dart';
import 'package:linkclub/presentation/clubs_details.dart';

class ClubsPage extends StatefulWidget {
  const ClubsPage({super.key});

  @override
  State<ClubsPage> createState() => _ClubsPageState();
}

class _ClubsPageState extends State<ClubsPage> {
  final List<Map<String, String>> clubs = const [
    {
      'name': 'Club de Programación',
      'category': 'Tecnología',
      'description': 'Aprende programación y desarrolla proyectos de software.',
      'icon': '💻',
      'fullDescription':
          'El Club de Programación es un espacio para estudiantes interesados '
          'en aprender y mejorar sus habilidades de desarrollo de software. '
          'Los integrantes trabajan en proyectos, practican programación y '
          'comparten conocimientos con otros estudiantes.',
      'members': '25 miembros',
      'leader': 'Juan Pérez',
      'schedule': 'Martes y jueves - 4:00 PM',
      'location': 'Laboratorio de Sistemas',
    },
    {
      'name': 'Club de Robótica',
      'category': 'Tecnología',
      'description': 'Diseña, construye y programa robots.',
      'icon': '🤖',
      'fullDescription':
          'El Club de Robótica reúne estudiantes interesados en electrónica, '
          'programación y diseño de robots. Los miembros desarrollan proyectos '
          'prácticos y participan en actividades relacionadas con robótica.',
      'members': '18 miembros',
      'leader': 'María González',
      'schedule': 'Miércoles - 3:00 PM',
      'location': 'Laboratorio de Electrónica',
    },
    {
      'name': 'Club de Música',
      'category': 'Arte y cultura',
      'description':
          'Un espacio para compartir y desarrollar talentos musicales.',
      'icon': '🎵',
      'fullDescription':
          'El Club de Música es un espacio para estudiantes que disfrutan '
          'de la música. Los integrantes pueden practicar instrumentos, '
          'compartir conocimientos y participar en presentaciones y eventos '
          'de la universidad.',
      'members': '32 miembros',
      'leader': 'Carlos Rodríguez',
      'schedule': 'Viernes - 2:00 PM',
      'location': 'Salón de Música',
    },
    {
      'name': 'Club de Deportes',
      'category': 'Deportes',
      'description':
          'Participa en actividades deportivas y conoce nuevos compañeros.',
      'icon': '⚽',
      'fullDescription':
          'El Club de Deportes promueve la actividad física y la integración '
          'entre estudiantes. Se realizan entrenamientos y actividades '
          'deportivas para diferentes niveles de experiencia.',
      'members': '40 miembros',
      'leader': 'Andrés Martínez',
      'schedule': 'Lunes y miércoles - 5:00 PM',
      'location': 'Cancha deportiva',
    },
    {
      'name': 'Club de Fotografía',
      'category': 'Arte y cultura',
      'description': 'Explora la fotografía y aprende nuevas técnicas.',
      'icon': '📷',
      ('fullDescription'):
          'El Club de Fotografía permite a los estudiantes aprender y '
          'experimentar con diferentes técnicas fotográficas. Se realizan '
          'salidas, sesiones prácticas y actividades para mejorar las '
          'habilidades de los integrantes.',
      'members': '15 miembros',
      'leader': 'Laura Torres',
      'schedule': 'Sábados - 10:00 AM',
      'location': 'Edificio de Arte y Cultura',
    },
  ];

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LinkClub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),

      // Menú lateral (Drawer)
      drawer: Drawer(
        backgroundColor: colorScheme.surface,
        child: Column(
          children: [
            // Cabecera con el Logo
            DrawerHeader(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/icon/logo_clean.png',
                  width: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Switch de Modo Oscuro / Claro
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeController.mode,
              builder: (context, mode, _) {
                return SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Modo oscuro'),
                  activeColor: colorScheme.primary,
                  value: mode == ThemeMode.dark,
                  onChanged: (bool value) => ThemeController.toggle(),
                );
              },
            ),

            // Configuraciones
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configuraciones'),
              onTap: () {
                Navigator.pop(context); // Cierra el drawer
              },
            ),

            const Spacer(),

            Divider(color: colorScheme.onSurface.withOpacity(0.1)),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: _signOut,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clubes disponibles',
              style: theme.textTheme.displayLarge?.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 8),
            Text(
              'Explora los clubes de la universidad',
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurface.withOpacity(
                  0.6,
                ), // Adaptativo al modo oscuro/claro
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar un club...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.transparent,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: clubs.length,
                itemBuilder: (context, index) {
                  final club = clubs[index];

                  return Card(
                    color: colorScheme.surface,
                    margin: const EdgeInsets.only(bottom: 15),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                club['icon']!,
                                style: const TextStyle(fontSize: 27),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          // Información
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  club['name']!,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  club['category']!,
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  club['description']!,
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ClubDetailPage(club: club),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme
                                          .primary, // Botón con color de marca
                                      foregroundColor: colorScheme.onPrimary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text('Ver club'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
