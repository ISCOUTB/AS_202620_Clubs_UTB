import 'package:flutter/material.dart';
import 'package:linkclub/data/publication_repository.dart';

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

  void _mostrarModalCrearPublicacion() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: _FormularioCrearPublicacion(onPublicado: _cargarFeed),
      ),
    );
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
        onPressed: _mostrarModalCrearPublicacion,
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
            Text(
              pub.contenido,
              style: const TextStyle(fontSize: 15, height: 1.4),
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

class _FormularioCrearPublicacion extends StatefulWidget {
  final VoidCallback onPublicado;

  const _FormularioCrearPublicacion({required this.onPublicado});

  @override
  State<_FormularioCrearPublicacion> createState() =>
      _FormularioCrearPublicacionState();
}

class _FormularioCrearPublicacionState
    extends State<_FormularioCrearPublicacion> {
  final TextEditingController _contenidoController = TextEditingController();
  final TextEditingController _imagenController = TextEditingController();
  bool _isLoading = false;

  Future<void> _enviarPublicacion() async {
    if (_contenidoController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final repo = PublicacionRepository();
      await repo.crearPublicacion(
        _contenidoController.text.trim(),
        imagenUrl: _imagenController.text.trim().isNotEmpty
            ? _imagenController.text.trim()
            : null,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onPublicado();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al crear la publicación. Intenta de nuevo.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Crear Publicación',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contenidoController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '¿Qué está pasando en los clubes de la UTB?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _imagenController,
            decoration: const InputDecoration(
              hintText: 'URL de imagen opcional (Ej: https://...)',
              prefixIcon: Icon(Icons.image_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _enviarPublicacion,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Publicar'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
