import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:linkclub/core/session/session_controller.dart';
import 'package:linkclub/data/publication_repository.dart';
import 'package:linkclub/presentation/create_publication_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  static const String _fontFamily = 'DMSans';
  static const Color _darkBg = Color(0xFF080C14);
  static const Color _darkCard = Color(0xFF0F1623);
  static const Color _darkElevated = Color(0xFF131B2E);
  static const Color _darkBorder = Color(0xFF1E293B);
  static const Color _darkTextPrimary = Color(0xFFE2E8F0);
  static const Color _darkTextBody = Color(0xFFCBD5E1);
  static const Color _darkTextSecondary = Color(0xFF8A99AD);

  static const Color _lightBg = Color(0xFFF8FAFC);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightElevated = Color(0xFFF1F5F9);
  static const Color _lightBorder = Color(0xFFE2E8F0);
  static const Color _lightTextPrimary = Color(0xFF0F172A);
  static const Color _lightTextBody = Color(0xFF1E293B);
  static const Color _lightTextSecondary = Color(0xFF64748B);

  static const Color _brandBlue = Color(0xFF1D4ED8);
  static const Color _brandBlueSoft = Color(0xFF60A5FA);
  static const Color _buttonTextLight = Color(0xFFF1F5F9);

  final PublicacionRepository _repository = PublicacionRepository();
  final Set<String> _likedPostKeys = <String>{};
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
              style: TextStyle(fontFamily: _fontFamily),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _mostrarPantallaCrearPublicacion() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePublicationScreen()),
    );

    if (resultado == true) {
      _cargarFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? _darkBg : _lightBg;
    final accentColor = isDarkMode ? _brandBlueSoft : _brandBlue;

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: accentColor,
                strokeWidth: 2.4,
              ),
            )
          : RefreshIndicator(
              onRefresh: _cargarFeed,
              color: accentColor,
              backgroundColor: isDarkMode ? _darkCard : _lightCard,
              child: _publicaciones.isEmpty
                  ? _buildEmptyState(isDarkMode)
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 88),
                      itemCount: _publicaciones.length,
                      itemBuilder: (context, index) {
                        final pub = _publicaciones[index];
                        final postKey =
                            '${pub.autorNombre}_${pub.creadoEn.toIso8601String()}';
                        return _buildPostCard(
                          pub: pub,
                          postKey: postKey,
                          isDarkMode: isDarkMode,
                        );
                      },
                    ),
            ),
      floatingActionButton: ListenableBuilder(
        listenable: SessionController.instance,
        builder: (context, _) {
          if (!SessionController.instance.puedeGestionarAlgunClub) {
            return const SizedBox.shrink();
          }
          return SizedBox(
            width: 54,
            height: 54,
            child: FloatingActionButton(
              onPressed: _mostrarPantallaCrearPublicacion,
              backgroundColor: _brandBlue,
              foregroundColor: _buttonTextLight,
              elevation: 0,
              highlightElevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.edit_outlined, size: 22),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final cardColor = isDarkMode ? _darkCard : _lightCard;
    final titleColor = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final subtitleColor = isDarkMode ? _darkTextSecondary : _lightTextSecondary;
    final accentColor = isDarkMode ? _brandBlueSoft : _brandBlue;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      children: [
        const SizedBox(height: 90),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _brandBlue.withValues(alpha: isDarkMode ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.dynamic_feed_outlined,
                  size: 26,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Aún no hay publicaciones',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cuando los clubes publiquen novedades o convocatorias, aparecerán aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 13.5,
                  height: 1.45,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard({
    required PublicacionModel pub,
    required String postKey,
    required bool isDarkMode,
  }) {
    final cardBg = isDarkMode ? _darkCard : _lightCard;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final titleColor = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final bodyColor = isDarkMode ? _darkTextBody : _lightTextBody;
    final secondaryColor = isDarkMode
        ? _darkTextSecondary
        : _lightTextSecondary;
    final accentColor = isDarkMode ? _brandBlueSoft : _brandBlue;
    final isLiked = _likedPostKeys.contains(postKey);
    final hasImage = pub.imagenUrl != null && pub.imagenUrl!.trim().isNotEmpty;

    // Si estás logueado como desarrollador y por defecto viene Club de Deportes,
    // puedes normalizarlo opcionalmente aquí de forma limpia:
    final autorNombre = pub.autorNombre;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de la publicación (Avatar, Nombre y Fecha)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _brandBlue.withValues(
                      alpha: isDarkMode ? 0.16 : 0.10,
                    ),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.28),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      autorNombre.isNotEmpty
                          ? autorNombre[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              autorNombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: accentColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatearFecha(pub.creadoEn),
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Título de la publicación restaurado
          if (pub.titulo.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Text(
                pub.titulo.trim(),
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                  letterSpacing: -0.2,
                ),
              ),
            ),

          // Contenido en Markdown
          Padding(
            padding: EdgeInsets.fromLTRB(16, 2, 16, hasImage ? 14 : 12),
            child: MarkdownBody(
              data: pub.contenido,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 14.5,
                  height: 1.48,
                  color: bodyColor,
                ),
                strong: TextStyle(
                  fontFamily: _fontFamily,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
                em: TextStyle(
                  fontFamily: _fontFamily,
                  fontStyle: FontStyle.italic,
                  color: bodyColor,
                ),
                listBullet: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 14.5,
                  color: accentColor,
                ),
                a: TextStyle(
                  fontFamily: _fontFamily,
                  color: accentColor,
                  decoration: TextDecoration.underline,
                  decorationColor: accentColor,
                ),
                code: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 13,
                  color: titleColor,
                  backgroundColor: isDarkMode ? _darkElevated : _lightElevated,
                ),
                blockquoteDecoration: BoxDecoration(
                  color: isDarkMode ? _darkElevated : _lightElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: accentColor, width: 3),
                  ),
                ),
              ),
            ),
          ),

          // Imagen adaptativa (soporta 9:16, 16:9, 3:4, 4:3, 1:1 de forma limpia)
          if (hasImage)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 200, maxHeight: 460),
              decoration: BoxDecoration(
                color: isDarkMode ? _darkElevated : _lightElevated,
                border: Border.symmetric(
                  horizontal: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Image.network(
                pub.imagenUrl!,
                fit: BoxFit.contain,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 220,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accentColor,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),

          // Acciones inferiores (Me gusta, Comentar, Compartir)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildActionButton(
                      icon: isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: 'Me gusta',
                      color: isLiked ? const Color(0xFFEF4444) : secondaryColor,
                      onTap: () {
                        setState(() {
                          if (isLiked) {
                            _likedPostKeys.remove(postKey);
                          } else {
                            _likedPostKeys.add(postKey);
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Comentar',
                      color: secondaryColor,
                      onTap: () {},
                    ),
                  ],
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Compartir',
                  color: secondaryColor,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 12.5,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final diferencia = DateTime.now().difference(fecha);
    if (diferencia.inMinutes < 1) {
      return 'Ahora';
    } else if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} h';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}
