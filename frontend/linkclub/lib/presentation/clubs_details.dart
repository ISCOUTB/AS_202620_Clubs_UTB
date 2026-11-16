import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:linkclub/data/club_repository.dart';
import 'package:linkclub/data/publication_repository.dart';
import 'package:linkclub/presentation/create_publication_screen.dart';

class ClubDetailPage extends StatefulWidget {
  final ClubModel club;

  const ClubDetailPage({super.key, required this.club});

  @override
  State<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends State<ClubDetailPage> {
  final ClubRepository _clubRepository = ClubRepository();
  List<PublicacionModel> _publicaciones = [];
  bool _cargandoPublicaciones = true;

  @override
  void initState() {
    super.initState();
    _cargarPublicaciones();
  }

  Future<void> _cargarPublicaciones() async {
    setState(() => _cargandoPublicaciones = true);
    final lista = await _clubRepository.obtenerPublicacionesDelClub(
      widget.club.id,
    );
    if (mounted) {
      setState(() {
        _publicaciones = lista;
        _cargandoPublicaciones = false;
      });
    }
  }

  Future<void> _abrirCrearPublicacion() async {
    final creada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CreatePublicationScreen()),
    );
    if (creada == true) {
      _cargarPublicaciones();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final club = widget.club;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Información del club',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar publicaciones',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargarPublicaciones,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCrearPublicacion,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('Nuevo aviso'),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarPublicaciones,
        color: colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera del club
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              club.iconoCategoria,
                              size: 34,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    club.categoria,
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  club.nombre,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Acerca del club',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        club.descripcion,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: colorScheme.onSurface.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Ficha técnica institucional
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        colorScheme,
                        Icons.person_outline_rounded,
                        'Coordinación',
                        club.lider,
                      ),
                      Divider(
                        height: 1,
                        color: colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                      _buildInfoRow(
                        colorScheme,
                        Icons.schedule_outlined,
                        'Horario habitual',
                        club.horario,
                      ),
                      Divider(
                        height: 1,
                        color: colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                      _buildInfoRow(
                        colorScheme,
                        Icons.location_on_outlined,
                        'Lugar de encuentro',
                        club.lugar,
                      ),
                      Divider(
                        height: 1,
                        color: colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                      _buildInfoRow(
                        colorScheme,
                        Icons.tag_rounded,
                        'ID en sistema',
                        club.id.length > 8
                            ? '${club.id.substring(0, 8)}...'
                            : club.id,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sección de publicaciones en vivo del club
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Publicaciones del club',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!_cargandoPublicaciones)
                    Text(
                      '${_publicaciones.length} ${_publicaciones.length == 1 ? 'aviso' : 'avisos'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              if (_cargandoPublicaciones)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_publicaciones.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.feed_outlined,
                            size: 36,
                            color: colorScheme.onSurface.withOpacity(0.35),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Este club aún no tiene publicaciones.',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _publicaciones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pub = _publicaciones[index];
                    return _buildClubPostCard(theme, pub);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ColorScheme colorScheme,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: colorScheme.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: colorScheme.onSurface.withOpacity(0.65),
        ),
      ),
    );
  }

  Widget _buildClubPostCard(ThemeData theme, PublicacionModel pub) {
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    pub.autorNombre.isNotEmpty
                        ? pub.autorNombre[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pub.autorNombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '${pub.creadoEn.day}/${pub.creadoEn.month}/${pub.creadoEn.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
            if (pub.titulo.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                pub.titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 6),
            MarkdownBody(
              data: pub.contenido,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
            if (pub.imagenUrl != null && pub.imagenUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  pub.imagenUrl!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
