import 'package:flutter/material.dart';
import 'package:linkclub/data/publication_repository.dart';
import 'package:linkclub/presentation/create_publication_screen.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PublicacionRepository _repository = PublicacionRepository();
  List<PublicacionModel> _publicaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarFeed();
  }

  Future<void> _cargarFeed() async {
    try {
      final publicaciones = await _repository.obtenerFeed();
      if (mounted) {
        setState(() {
          _publicaciones = publicaciones;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo conectar con el servidor para actualizar el feed.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Conexión del botón flotante hacia la nueva pantalla dedicada
  Future<void> _mostrarPantallaCrearPublicacion() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePublicationScreen()),
    );

    // Si se publicó con éxito, recargamos el feed automáticamente
    if (resultado == true) {
      _cargarFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarFeed,
              color: colorScheme.primary,
              child: _publicaciones.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text(
                            'Aún no hay publicaciones en el feed.\n¡Sé el primero en compartir algo!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: _publicaciones.length,
                      itemBuilder: (context, index) {
                        final pub = _publicaciones[index];
                        return _buildPostCard(theme, pub);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarPantallaCrearPublicacion,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }

  Widget _buildPostCard(ThemeData theme, PublicacionModel pub) {
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  radius: 20,
                  child: Text(
                    pub.autorNombre.isNotEmpty
                        ? pub.autorNombre[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pub.autorNombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatearFecha(pub.creadoEn),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MarkdownBody(
              data: pub.contenido,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 15, height: 1.4),
                strong: const TextStyle(fontWeight: FontWeight.bold),
                em: const TextStyle(fontStyle: FontStyle.italic),
                a: const TextStyle(
                  color: Colors.blueAccent,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            if (pub.imagenUrl != null && pub.imagenUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  pub.imagenUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Divider(
              color: colorScheme.outlineVariant.withOpacity(0.3),
              height: 1,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  Icons.favorite_border_rounded,
                  'Me gusta',
                  () {},
                ),
                _buildActionButton(
                  Icons.chat_bubble_outline_rounded,
                  'Comentar',
                  () {},
                ),
                _buildActionButton(Icons.share_outlined, 'Compartir', () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final diferencia = DateTime.now().difference(fecha);
    if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} h';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}
