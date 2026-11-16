import 'package:flutter/material.dart';
import 'package:linkclub/core/theme/app_theme.dart';
import 'package:linkclub/data/auth_repository.dart';
import 'package:linkclub/data/club_repository.dart';

class DevAdminScreen extends StatefulWidget {
  const DevAdminScreen({super.key});

  @override
  State<DevAdminScreen> createState() => _DevAdminScreenState();
}

class _DevAdminScreenState extends State<DevAdminScreen> {
  final AuthRepository _authRepo = AuthRepository();
  final ClubRepository _clubRepo = ClubRepository();
  late Future<List<Map<String, dynamic>>> _solicitudesFuture;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    setState(() {
      _solicitudesFuture = _authRepo.listarSolicitudesAdmin();
    });
  }

  Future<void> _procesar(String id, bool aprobar) async {
    try {
      if (aprobar) {
        await _authRepo.aprobarSolicitud(id);
      } else {
        await _authRepo.rechazarSolicitud(id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aprobar ? 'Administrador verificado' : 'Solicitud rechazada',
          ),
          backgroundColor: aprobar
              ? AppTheme.brandBlue
              : Colors.orange.shade800,
        ),
      );
      _recargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _abrirDialogoNuevoClub() {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String categoria = 'Tecnología';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear nuevo club UTB'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del club'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: categoria,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: const ['Tecnología', 'Cultura', 'Deportes', 'Académico']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => categoria = v ?? 'Tecnología',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción corta',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.trim().isEmpty ||
                  descCtrl.text.trim().isEmpty) {
                return;
              }
              try {
                await _clubRepo.crearClub({
                  'nombre': nombreCtrl.text.trim(),
                  'descripcion': descCtrl.text.trim(),
                  'categoria': categoria,
                });
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Club creado exitosamente')),
                );
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                  ),
                );
              }
            },
            child: const Text('Crear club'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consola Desarrollador (Superadmin)'),
        actions: [
          IconButton(
            tooltip: 'Crear nuevo club',
            icon: const Icon(Icons.add_business_rounded),
            onPressed: _abrirDialogoNuevoClub,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _solicitudesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final solicitudes = snapshot.data ?? [];
          if (solicitudes.isEmpty) {
            return const Center(
              child: Text('No hay solicitudes pendientes de Admin de Club.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: solicitudes.length,
            itemBuilder: (context, index) {
              final s = solicitudes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s['usuario_nombre']} (${s['usuario_matricula']})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        s['usuario_correo'].toString(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Chip(label: Text('Club solicitado: ${s['club_nombre']}')),
                      const SizedBox(height: 8),
                      Text('Justificación: ${s['justificacion']}'),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () =>
                                _procesar(s['id'].toString(), false),
                            child: const Text('Rechazar'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () =>
                                _procesar(s['id'].toString(), true),
                            child: const Text('Aprobar Admin'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
