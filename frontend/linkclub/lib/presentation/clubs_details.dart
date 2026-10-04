import 'package:flutter/material.dart';

class ClubDetailPage extends StatelessWidget {
  final Map<String, String> club;

  const ClubDetailPage({super.key, required this.club});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Información del club',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ICONO
            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    club['icon']!,
                    style: const TextStyle(fontSize: 55),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // NOMBRE
            Text(
              club['name']!,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // CATEGORÍA
            Text(
              club['category']!,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 30),

            // DESCRIPCIÓN
            Text(
              'Descripción',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              club['fullDescription']!,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 30),

            // INFORMACIÓN
            Text(
              'Información',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // MIEMBROS
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.people_outline, color: colorScheme.primary),
              title: const Text(
                'Miembros',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(club['members']!),
            ),

            // LÍDER
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person_outline, color: colorScheme.primary),
              title: const Text(
                'Líder',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(club['leader']!),
            ),

            // HORARIO
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.schedule_outlined,
                color: colorScheme.primary,
              ),
              title: const Text(
                'Horario',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(club['schedule']!),
            ),

            // LUGAR
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.location_on_outlined,
                color: colorScheme.primary,
              ),
              title: const Text(
                'Lugar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(club['location']!),
            ),
          ],
        ),
      ),
    );
  }
}
