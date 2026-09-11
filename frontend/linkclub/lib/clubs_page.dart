import 'package:flutter/material.dart';

class ClubsPage extends StatelessWidget {
  const ClubsPage({super.key});

  final List<Map<String, String>> clubs = const [
    // datos de ejemplo
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text(
          'LinkClub',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Clubes disponibles',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Explora los clubes de la universidad',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // Buscador
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar un club...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,

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
                    color: Colors.white,
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
                          // Icono
                          Container(
                            width: 55,
                            height: 55,

                            decoration: BoxDecoration(
                              color: const Color(0xFFEDEFFF),
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
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  club['category']!,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  club['description']!,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                SizedBox(
                                  height: 38,

                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Aquí posteriormente
                                      // podemos abrir la página
                                      // de información del club.
                                    },

                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
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
