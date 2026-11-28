import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:linkclub/core/session/session_controller.dart';
import 'package:linkclub/data/publication_repository.dart';
import 'package:linkclub/presentation/create_publication_screen.dart';
import 'package:linkclub/presentation/publication_carousel.dart';

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
  static const Color _likeRed = Color(0xFFEF4444);
  static const Color _buttonTextLight = Color(0xFFF1F5F9);

  static const List<String> _categoriasFiltro = [
    'Todas',
    'Tecnología',
    'Robótica e IA',
    'Deportes',
    'Arte y Cultura',
    'Fotografía y Medios',
    'Ciencia y Estrategia',
    'Originales',
  ];

  final PublicacionRepository _repository = PublicacionRepository();
  final Set<String> _procesandoLikeIds = <String>{};

  List<PublicacionModel> _publicaciones = [];
  List<ClubOption> _clubes = [];
  Map<String, ClubOption> _clubesPorId = {};
  bool _isLoading = true;

  String _categoriaFiltro = 'Todas';
  String? _clubIdFiltro;

  @override
  void initState() {
    super.initState();
    _cargarFeed();
  }

  Future<void> _cargarFeed() async {
    try {
      final resultados = await Future.wait([
        _repository.obtenerFeed(),
        _repository.obtenerClubes().catchError((_) => <ClubOption>[]),
      ]);

      final publicaciones = resultados[0] as List<PublicacionModel>;
      final clubesApi = resultados[1] as List<ClubOption>;

      final mapaClubes = <String, ClubOption>{
        for (final c in clubesApi)
          if (c.id.isNotEmpty) c.id: c,
      };

      for (final pub in publicaciones) {
        if (pub.clubId.isNotEmpty && !mapaClubes.containsKey(pub.clubId)) {
          mapaClubes[pub.clubId] = ClubOption(
            id: pub.clubId,
            nombre:
                (pub.clubNombre != null && pub.clubNombre!.trim().isNotEmpty)
                ? pub.clubNombre!.trim()
                : pub.autorNombre,
            categoria: 'General',
          );
        }
      }

      final listaClubes = mapaClubes.values.toList()
        ..sort(
          (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
        );

      if (mounted) {
        setState(() {
          _publicaciones = publicaciones;
          _clubes = listaClubes;
          _clubesPorId = mapaClubes;
          if (_clubIdFiltro != null && !mapaClubes.containsKey(_clubIdFiltro)) {
            _clubIdFiltro = null;
          }
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

  String _normalizarCategoriaClub(String rawCategoria) {
    final cat = rawCategoria.trim().toLowerCase();
    if (cat.isEmpty ||
        cat == 'general' ||
        cat == 'otro' ||
        cat == 'otros' ||
        cat == 'originales') {
      return 'Originales';
    }
    if (cat.contains('robót') ||
        cat.contains('robot') ||
        cat.contains('inteligencia') ||
        cat == 'ia') {
      return 'Robótica e IA';
    }
    if (cat.contains('tecnolog') ||
        cat.contains('program') ||
        cat.contains('software') ||
        cat.contains('sistemas')) {
      return 'Tecnología';
    }
    if (cat.contains('deport') ||
        cat.contains('fútbol') ||
        cat.contains('futbol') ||
        cat.contains('volei') ||
        cat.contains('baloncesto')) {
      return 'Deportes';
    }
    if (cat.contains('arte') ||
        cat.contains('cultur') ||
        cat.contains('músic') ||
        cat.contains('music') ||
        cat.contains('teatro') ||
        cat.contains('danza')) {
      return 'Arte y Cultura';
    }
    if (cat.contains('fotograf') ||
        cat.contains('medio') ||
        cat.contains('audiovisual') ||
        cat.contains('cine') ||
        cat.contains('comunic')) {
      return 'Fotografía y Medios';
    }
    if (cat.contains('cienc') ||
        cat.contains('ajedrez') ||
        cat.contains('estrateg') ||
        cat.contains('investig')) {
      return 'Ciencia y Estrategia';
    }
    return 'Originales';
  }

  String _categoriaDePublicacion(PublicacionModel pub) {
    ClubOption? club = _clubesPorId[pub.clubId];
    if (club == null &&
        pub.clubNombre != null &&
        pub.clubNombre!.trim().isNotEmpty) {
      final target = pub.clubNombre!.trim().toLowerCase();
      for (final c in _clubes) {
        if (c.nombre.trim().toLowerCase() == target) {
          club = c;
          break;
        }
      }
    }
    return _normalizarCategoriaClub(club?.categoria ?? '');
  }

  List<PublicacionModel> get _publicacionesFiltradas {
    return _publicaciones.where((pub) {
      final coincideClub = _clubIdFiltro == null || pub.clubId == _clubIdFiltro;
      final coincideCategoria =
          _categoriaFiltro == 'Todas' ||
          _categoriaDePublicacion(pub) == _categoriaFiltro;
      return coincideClub && coincideCategoria;
    }).toList();
  }

  int get _cantidadFiltrosActivos {
    int count = 0;
    if (_categoriaFiltro != 'Todas') count++;
    if (_clubIdFiltro != null) count++;
    return count;
  }

  Future<void> _toggleLike(PublicacionModel pub) async {
    if (!SessionController.instance.estaAutenticado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Inicia sesión con tu cuenta institucional para dar Me gusta.',
            style: TextStyle(fontFamily: _fontFamily),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (pub.id.isEmpty || _procesandoLikeIds.contains(pub.id)) return;

    final idx = _publicaciones.indexWhere((p) => p.id == pub.id);
    if (idx == -1) return;

    final previo = _publicaciones[idx];
    final nuevoLiked = !previo.usuarioDioLike;
    final nuevoTotal = (previo.totalLikes + (nuevoLiked ? 1 : -1)).clamp(
      0,
      999999,
    );

    setState(() {
      _procesandoLikeIds.add(pub.id);
      _publicaciones[idx] = previo.copyWith(
        usuarioDioLike: nuevoLiked,
        totalLikes: nuevoTotal,
      );
    });

    try {
      final res = await _repository.alternarLike(pub.id);
      if (mounted) {
        setState(() {
          _publicaciones[idx] = previo.copyWith(
            usuarioDioLike: res.usuarioDioLike,
            totalLikes: res.totalLikes,
          );
          _procesandoLikeIds.remove(pub.id);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _publicaciones[idx] = previo;
          _procesandoLikeIds.remove(pub.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo actualizar tu Me gusta. Intenta nuevamente.',
              style: TextStyle(fontFamily: _fontFamily),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _abrirEnlaceInApp(String? rawUrl) async {
    if (rawUrl == null || rawUrl.trim().isEmpty) return;
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!ok) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
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

  void _mostrarModalFiltros(bool isDarkMode) {
    final sheetBg = isDarkMode ? _darkCard : _lightCard;
    final elevatedBg = isDarkMode ? _darkElevated : _lightElevated;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final titleColor = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final bodyColor = isDarkMode ? _darkTextBody : _lightTextBody;
    final secondaryColor = isDarkMode
        ? _darkTextSecondary
        : _lightTextSecondary;

    String tempCategoria = _categoriaFiltro;
    String? tempClubId = _clubIdFiltro;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: borderColor, width: 1),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: borderColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtrar publicaciones',
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        if (tempCategoria != 'Todas' || tempClubId != null)
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempCategoria = 'Todas';
                                tempClubId = null;
                              });
                            },
                            child: Text(
                              'Restablecer',
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? _brandBlueSoft : _brandBlue,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Categoría de club',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categoriasFiltro.map((cat) {
                        final activa = tempCategoria == cat;
                        return GestureDetector(
                          onTap: () => setModalState(() => tempCategoria = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: activa ? _brandBlue : elevatedBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: activa
                                    ? const Color(
                                        0xFF3B82F6,
                                      ).withValues(alpha: 0.5)
                                    : borderColor,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 12.5,
                                fontWeight: activa
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: activa ? _buttonTextLight : bodyColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Club específico',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 190),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  setModalState(() => tempClubId = null),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: tempClubId == null
                                      ? _brandBlue
                                      : elevatedBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: tempClubId == null
                                        ? const Color(
                                            0xFF3B82F6,
                                          ).withValues(alpha: 0.5)
                                        : borderColor,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Todos los clubes',
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    fontSize: 12.5,
                                    fontWeight: tempClubId == null
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: tempClubId == null
                                        ? _buttonTextLight
                                        : bodyColor,
                                  ),
                                ),
                              ),
                            ),
                            ..._clubes.map((club) {
                              final seleccionado = tempClubId == club.id;
                              return GestureDetector(
                                onTap: () => setModalState(
                                  () => tempClubId = seleccionado
                                      ? null
                                      : club.id,
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: seleccionado
                                        ? _brandBlue
                                        : elevatedBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: seleccionado
                                          ? const Color(
                                              0xFF3B82F6,
                                            ).withValues(alpha: 0.5)
                                          : borderColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    club.nombre,
                                    style: TextStyle(
                                      fontFamily: _fontFamily,
                                      fontSize: 12.5,
                                      fontWeight: seleccionado
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: seleccionado
                                          ? _buttonTextLight
                                          : bodyColor,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _categoriaFiltro = tempCategoria;
                            _clubIdFiltro = tempClubId;
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandBlue,
                          foregroundColor: _buttonTextLight,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Aplicar filtros',
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? _darkBg : _lightBg;
    final accentColor = isDarkMode ? _brandBlueSoft : _brandBlue;
    final filtradas = _publicacionesFiltradas;

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
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 88),
                children: [
                  _buildTopFilterHeader(isDarkMode, filtradas.length),
                  const SizedBox(height: 12),
                  if (filtradas.isEmpty)
                    _buildEmptyState(isDarkMode)
                  else
                    ...filtradas.map(
                      (pub) => _buildPostCard(pub: pub, isDarkMode: isDarkMode),
                    ),
                ],
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

  Widget _buildTopFilterHeader(bool isDarkMode, int totalVisibles) {
    final cardBg = isDarkMode ? _darkCard : _lightCard;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final titleColor = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final secondaryColor = isDarkMode
        ? _darkTextSecondary
        : _lightTextSecondary;
    final accentColor = isDarkMode ? _brandBlueSoft : _brandBlue;
    final activos = _cantidadFiltrosActivos;
    final clubSeleccionado = _clubIdFiltro != null
        ? _clubesPorId[_clubIdFiltro]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Publicaciones',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 17.5,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
              ],
            ),
            InkWell(
              onTap: () => _mostrarModalFiltros(isDarkMode),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: activos > 0
                      ? _brandBlue.withValues(alpha: isDarkMode ? 0.20 : 0.10)
                      : cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: activos > 0
                        ? accentColor.withValues(alpha: 0.45)
                        : borderColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: activos > 0 ? accentColor : titleColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Filtrar',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: activos > 0 ? accentColor : titleColor,
                      ),
                    ),
                    if (activos > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: _brandBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$activos',
                          style: const TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _buttonTextLight,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        if (activos > 0) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (_categoriaFiltro != 'Todas')
                _buildActiveFilterChip(
                  label: 'Categoría: $_categoriaFiltro',
                  isDarkMode: isDarkMode,
                  onRemove: () => setState(() => _categoriaFiltro = 'Todas'),
                ),
              if (clubSeleccionado != null)
                _buildActiveFilterChip(
                  label: 'Club: ${clubSeleccionado.nombre}',
                  isDarkMode: isDarkMode,
                  onRemove: () => setState(() => _clubIdFiltro = null),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required bool isDarkMode,
    required VoidCallback onRemove,
  }) {
    final accentColor = isDarkMode ? _brandBlueSoft : _brandBlue;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        color: _brandBlue.withValues(alpha: isDarkMode ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, size: 15, color: accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final cardColor = isDarkMode ? _darkCard : _lightCard;
    final titleColor = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final subtitleColor = isDarkMode ? _darkTextSecondary : _lightTextSecondary;
    final accentColor = isDarkMode ? _brandBlueSoft : _brandBlue;
    final hayFiltros = _cantidadFiltrosActivos > 0;

    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Container(
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
                hayFiltros
                    ? Icons.filter_alt_off_outlined
                    : Icons.dynamic_feed_outlined,
                size: 26,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hayFiltros
                  ? 'Sin resultados para este filtro'
                  : 'Aún no hay publicaciones',
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
              hayFiltros
                  ? 'Prueba seleccionando otra categoría o limpiando el filtro de club.'
                  : 'Cuando los clubes publiquen novedades o convocatorias, aparecerán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 13.5,
                height: 1.45,
                color: subtitleColor,
              ),
            ),
            if (hayFiltros) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _categoriaFiltro = 'Todas';
                    _clubIdFiltro = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Limpiar filtros',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard({
    required PublicacionModel pub,
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
    final isLiked = pub.usuarioDioLike;
    final hasImage = pub.imagenesUrls.isNotEmpty;
    final autorNombre = pub.autorNombre;
    final clubNombre =
        (pub.clubNombre != null && pub.clubNombre!.trim().isNotEmpty)
        ? pub.clubNombre!.trim()
        : null;
    final categoriaEtiqueta = _categoriaDePublicacion(pub);

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
          // Cabecera de la publicación
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
                      (clubNombre ?? autorNombre).isNotEmpty
                          ? (clubNombre ?? autorNombre)[0].toUpperCase()
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
                              clubNombre ?? autorNombre,
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
                        clubNombre != null && clubNombre != autorNombre
                            ? '$autorNombre • ${_formatearFecha(pub.creadoEn)}'
                            : _formatearFecha(pub.creadoEn),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _brandBlue.withValues(
                      alpha: isDarkMode ? 0.14 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.24),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    categoriaEtiqueta,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Título de la publicación
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
              onTapLink: (_, href, __) => _abrirEnlaceInApp(href),
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

          // Carrusel adaptativo con marco uniforme
          if (hasImage)
            PublicationCarousel(
              items: pub.imagenesUrls
                  .map(
                    (url) => PublicationCarouselItem(
                      pathOrUrl: url,
                      isLocalFile: false,
                    ),
                  )
                  .toList(),
              isDarkMode: isDarkMode,
              height: 310,
            ),

          // Barra inferior: Me gusta persistente con contador (sin Compartir)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _toggleLike(pub),
                  borderRadius: BorderRadius.circular(11),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isLiked
                          ? _likeRed.withValues(alpha: isDarkMode ? 0.16 : 0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: isLiked
                            ? _likeRed.withValues(alpha: 0.35)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 18,
                          color: isLiked ? _likeRed : secondaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${pub.totalLikes} Me gusta',
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 12.5,
                            color: isLiked ? _likeRed : secondaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
