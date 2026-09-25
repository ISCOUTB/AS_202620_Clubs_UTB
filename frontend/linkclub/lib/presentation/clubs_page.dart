import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:linkclub/presentation/login_screen.dart';

class ClubsPage extends StatefulWidget {
  const ClubsPage({super.key});

  @override
  State<ClubsPage> createState() => _ClubsPageState();
}

class _ClubsPageState extends State<ClubsPage> {
  bool _isDarkMode = false;

  final List<Map<String, String>> clubs = const [
    {
      'name': 'Club de Programación',
      'category': 'Tecnología',
      'description': 'Aprende programación y desarrolla proyectos de software.',
      'icon': '💻',
    },
    {
      'name': 'Club de Robótica',
      'category': 'Tecnología',
      'description': 'Diseña, construye y programa robots.',
      'icon': '🤖',
    },
    {
      'name': 'Club de Música',
      'category': 'Arte y cultura',
      'description':
          'Un espacio para compartir y desarrollar talentos musicales.',
      'icon': '🎵',
    },
    {
      'name': 'Club de Deportes',
      'category': 'Deportes',
      'description':
          'Participa en actividades deportivas y conoce nuevos compañeros.',
      'icon': '⚽',
    },
    {
      'name': 'Club de Fotografía',
      'category': 'Arte y cultura',
      'description': 'Explora la fotografía y aprende nuevas técnicas.',
      'icon': '📷',
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
  }

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
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Modo oscuro'),
              activeColor: colorScheme.primary,
              value: _isDarkMode,
              onChanged: (bool value) {
                setState(() {
                  _isDarkMode = value;
                });
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
                                    onPressed: () {},
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
