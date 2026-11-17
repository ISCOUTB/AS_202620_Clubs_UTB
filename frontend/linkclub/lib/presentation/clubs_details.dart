import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:linkclub/core/session/session_controller.dart';
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
  static const String _fontFamily = 'DMSans';
  static const Color _darkBg = Color(0xFF080C14);
  static const Color _darkSurface = Color(0xFF0F1623);
  static const Color _darkElevated = Color(0xFF151E2E);
  static const Color _darkBorder = Color(0xFF1E293B);
  static const Color _darkTextPrimary = Color(0xFFF1F5F9);
  static const Color _darkTextSecondary = Color(0xFF94A3B8);

  static const Color _lightBg = Color(0xFFF8FAFC);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightElevated = Color(0xFFF1F5F9);
  static const Color _lightBorder = Color(0xFFE2E8F0);
  static const Color _lightTextPrimary = Color(0xFF0F172A);
  static const Color _lightTextSecondary = Color(0xFF64748B);

  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _softBlue = Color(0xFF60A5FA);

  final ClubRepository _clubRepository = ClubRepository();
  late ClubModel _club;
  List<PublicacionModel> _publicaciones = [];
  bool _cargandoPublicaciones = true;
  int _tabSeleccionada = 0; // 0: Avisos & Feed, 1: Detalles & Convocatoria

  @override
  void initState() {
    super.initState();
    _club = widget.club;
    _recargarTodo();
  }

  Future<void> _recargarTodo() async {
    setState(() => _cargandoPublicaciones = true);
    try {
      final clubActualizado = await _clubRepository.obtenerClubPorId(_club.id);
      if (mounted) {
        _club = clubActualizado;
      }
    } catch (_) {}

    final lista = await _clubRepository.obtenerPublicacionesDelClub(_club.id);
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
      MaterialPageRoute(
        builder: (context) => CreatePublicationScreen(clubIdFijo: _club.id),
      ),
    );
    if (creada == true) {
      _recargarTodo();
    }
  }

  Future<void> _abrirFormularioInscripcion(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El enlace de inscripción configurado no es válido.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final lanzado = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!lanzado && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el navegador para Microsoft Forms.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _compartirInfoClub() async {
    final resumen =
        '${_club.nombre} (${_club.categoria}) - UTB\nHorario: ${_club.horario} • Lugar: ${_club.lugar}';
    await Clipboard.setData(ClipboardData(text: resumen));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Información del club copiada al portapapeles'),
      ),
    );
  }

  String _iniciales(String nombre) {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return 'UTB';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
  }

  void _abrirModalEditarClub() {
    final descCtrl = TextEditingController(text: _club.descripcion);
    final descCompCtrl = TextEditingController(
      text: _club.descripcionCompleta ?? '',
    );
    final liderCtrl = TextEditingController(text: _club.lider);
    final horarioCtrl = TextEditingController(text: _club.horario);
    final lugarCtrl = TextEditingController(text: _club.lugar);
    final formsCtrl = TextEditingController(text: _club.msFormsUrl ?? '');
    final avisoCtrl = TextEditingController(text: _club.avisoInscripcion ?? '');
    bool abiertas = _club.inscripcionesAbiertas;
    bool guardando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Gestionar ${_club.nombre}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Descripción breve',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCompCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción ampliada (opcional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: liderCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Coordinación / Líder',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: horarioCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Horario habitual',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lugarCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Lugar de encuentro',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Inscripciones abiertas',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Habilita el botón externo hacia Microsoft Forms',
                      ),
                      value: abiertas,
                      onChanged: (v) => setModalState(() => abiertas = v),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: formsCtrl,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'URL de Microsoft Forms',
                        hintText: 'https://forms.office.com/...',
                        prefixIcon: Icon(Icons.link_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: avisoCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Aviso o requisitos de inscripción',
                        hintText:
                            'Ej. Cupos limitados hasta el viernes / Próxima convocatoria en agosto',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: guardando
                          ? null
                          : () async {
                              setModalState(() => guardando = true);
                              try {
                                final actualizado = await _clubRepository
                                    .actualizarClub(_club.id, {
                                      'descripcion': descCtrl.text.trim(),
                                      'descripcion_completa':
                                          descCompCtrl.text.trim().isEmpty
                                          ? null
                                          : descCompCtrl.text.trim(),
                                      'lider': liderCtrl.text.trim(),
                                      'horario': horarioCtrl.text.trim(),
                                      'lugar': lugarCtrl.text.trim(),
                                      'inscripciones_abiertas': abiertas,
                                      'ms_forms_url':
                                          formsCtrl.text.trim().isEmpty
                                          ? null
                                          : formsCtrl.text.trim(),
                                      'aviso_inscripcion':
                                          avisoCtrl.text.trim().isEmpty
                                          ? null
                                          : avisoCtrl.text.trim(),
                                    });
                                if (!mounted) return;
                                setState(() => _club = actualizado);
                                if (ctx.mounted) Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ficha del club actualizada'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                setModalState(() => guardando = false);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            },
                      child: guardando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Guardar cambios'),
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
    final surfaceColor = isDarkMode ? _darkSurface : _lightSurface;
    final elevatedColor = isDarkMode ? _darkElevated : _lightElevated;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final textPrimary = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final textSecondary = isDarkMode ? _darkTextSecondary : _lightTextSecondary;
    final accentColor = isDarkMode ? _softBlue : _primaryBlue;

    return ListenableBuilder(
      listenable: SessionController.instance,
      builder: (context, _) {
        final puedeGestionar = SessionController.instance.puedeGestionarClub(
          _club.id,
        );
        final tieneUrlValida =
            _club.msFormsUrl != null &&
            _club.msFormsUrl!.trim().startsWith('http');

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _club.categoria,
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            centerTitle: true,
            actions: [
              if (puedeGestionar)
                IconButton(
                  tooltip: 'Editar información e inscripciones',
                  icon: Icon(Icons.edit_outlined, size: 20, color: textPrimary),
                  onPressed: _abrirModalEditarClub,
                ),
              IconButton(
                tooltip: 'Actualizar publicaciones',
                icon: Icon(Icons.refresh_rounded, size: 21, color: textPrimary),
                onPressed: _recargarTodo,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: borderColor),
            ),
          ),
          floatingActionButton: puedeGestionar
              ? FloatingActionButton.extended(
                  onPressed: _abrirCrearPublicacion,
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text(
                    'Nuevo aviso',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null,
          body: RefreshIndicator(
            onRefresh: _recargarTodo,
            color: accentColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. HERO BANNER CARD (Estilo code_5.html)
                  _buildHeroCard(
                    isDarkMode: isDarkMode,
                    surfaceColor: surfaceColor,
                    elevatedColor: elevatedColor,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    accentColor: accentColor,
                    tieneUrlValida: tieneUrlValida,
                  ),
                  const SizedBox(height: 14),

                  // 2. LEADER / COORDINACIÓN SHOWCASE CARD
                  _buildLeaderCard(
                    isDarkMode: isDarkMode,
                    surfaceColor: surfaceColor,
                    elevatedColor: elevatedColor,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 14),

                  // 3. SOBRE EL CLUB CARD
                  _buildAboutCard(
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 18),

                  // 4. INTERACTIVE SEGMENTED TABS
                  _buildSegmentedTabs(
                    isDarkMode: isDarkMode,
                    elevatedColor: elevatedColor,
                    borderColor: borderColor,
                    textSecondary: textSecondary,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: 14),

                  // 5. TAB CONTENT
                  if (_tabSeleccionada == 0)
                    _buildFeedTabContent(
                      isDarkMode: isDarkMode,
                      surfaceColor: surfaceColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      accentColor: accentColor,
                    )
                  else
                    _buildDetailsTabContent(
                      isDarkMode: isDarkMode,
                      surfaceColor: surfaceColor,
                      elevatedColor: elevatedColor,
                      borderColor: borderColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      accentColor: accentColor,
                      tieneUrlValida: tieneUrlValida,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroCard({
    required bool isDarkMode,
    required Color surfaceColor,
    required Color elevatedColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
    required bool tieneUrlValida,
  }) {
    final puedeInscribirse = _club.inscripcionesAbiertas && tieneUrlValida;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            if (isDarkMode)
              Positioned(
                right: -35,
                top: -35,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _primaryBlue.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryBlue.withValues(alpha: 0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          _club.iconoCategoria,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _club.nombre,
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Universidad Tecnológica de Bolívar',
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 12.5,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bento Quick Metrics Bar (Horario & Lugar)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: elevatedColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: borderColor.withValues(alpha: 0.8),
                        width: 1,
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  _club.horario,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Horario',
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          VerticalDivider(
                            width: 16,
                            thickness: 1,
                            color: borderColor,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  _club.lugar,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Lugar',
                                  style: TextStyle(
                                    fontFamily: _fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CTA Row
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: puedeInscribirse
                                ? () => _abrirFormularioInscripcion(
                                    _club.msFormsUrl!,
                                  )
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryBlue,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: elevatedColor,
                              disabledForegroundColor: textSecondary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: puedeInscribirse
                                    ? BorderSide.none
                                    : BorderSide(color: borderColor),
                              ),
                            ),
                            icon: Icon(
                              puedeInscribirse
                                  ? Icons.person_add_alt_1_rounded
                                  : Icons.lock_clock_outlined,
                              size: 19,
                            ),
                            label: Text(
                              puedeInscribirse
                                  ? 'Inscribirme en Forms'
                                  : 'Inscripciones cerradas',
                              style: const TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: elevatedColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: borderColor, width: 1),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _compartirInfoClub,
                          child: SizedBox(
                            width: 46,
                            height: 46,
                            child: Icon(
                              Icons.share_outlined,
                              size: 20,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_club.avisoInscripcion != null &&
                      _club.avisoInscripcion!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryBlue.withValues(
                          alpha: isDarkMode ? 0.12 : 0.06,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _primaryBlue.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.campaign_outlined,
                            size: 16,
                            color: accentColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _club.avisoInscripcion!,
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 12.5,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderCard({
    required bool isDarkMode,
    required Color surfaceColor,
    required Color elevatedColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF4F46E5),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _iniciales(_club.lider),
                  style: const TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: _primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
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
                        _club.lider,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF4F46E5,
                        ).withValues(alpha: isDarkMode ? 0.25 : 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(
                            0xFF6366F1,
                          ).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'Coordinación',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode
                              ? const Color(0xFFA5B4FC)
                              : const Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Líder de capítulo · ${_club.categoria}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 12.5,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard({
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
  }) {
    final textoDescripcion =
        (_club.descripcionCompleta != null &&
            _club.descripcionCompleta!.trim().isNotEmpty)
        ? _club.descripcionCompleta!
        : _club.descripcion;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 19, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'Sobre el club',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            textoDescripcion,
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 14,
              height: 1.55,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabs({
    required bool isDarkMode,
    required Color elevatedColor,
    required Color borderColor,
    required Color textSecondary,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              index: 0,
              icon: Icons.dynamic_feed_rounded,
              label: 'Avisos & Feed (${_publicaciones.length})',
              isDarkMode: isDarkMode,
              borderColor: borderColor,
              textSecondary: textSecondary,
              accentColor: accentColor,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTabButton(
              index: 1,
              icon: Icons.badge_outlined,
              label: 'Ficha & Horarios',
              isDarkMode: isDarkMode,
              borderColor: borderColor,
              textSecondary: textSecondary,
              accentColor: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
    required bool isDarkMode,
    required Color borderColor,
    required Color textSecondary,
    required Color accentColor,
  }) {
    final selected = _tabSeleccionada == index;
    final activeCardColor = isDarkMode
        ? const Color(0xFF1E293B)
        : const Color(0xFFFFFFFF);

    return GestureDetector(
      onTap: () => setState(() => _tabSeleccionada = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? activeCardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? (isDarkMode ? const Color(0xFF334155) : borderColor)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? accentColor : textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? accentColor : textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTabContent({
    required bool isDarkMode,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
  }) {
    if (_cargandoPublicaciones) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_publicaciones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          children: [
            Icon(
              Icons.feed_outlined,
              size: 36,
              color: textSecondary.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 10),
            Text(
              'Este club aún no tiene avisos publicados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _publicaciones.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final pub = _publicaciones[index];
        return _buildClubPostCard(
          pub: pub,
          isDarkMode: isDarkMode,
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          accentColor: accentColor,
        );
      },
    );
  }

  Widget _buildDetailsTabContent({
    required bool isDarkMode,
    required Color surfaceColor,
    required Color elevatedColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
    required bool tieneUrlValida,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.person_outline_rounded,
            title: 'Coordinación',
            subtitle: _club.lider,
            isDarkMode: isDarkMode,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            accentColor: accentColor,
          ),
          Divider(height: 16, color: borderColor),
          _buildInfoRow(
            icon: Icons.schedule_outlined,
            title: 'Horario habitual',
            subtitle: _club.horario,
            isDarkMode: isDarkMode,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            accentColor: accentColor,
          ),
          Divider(height: 16, color: borderColor),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            title: 'Lugar de encuentro',
            subtitle: _club.lugar,
            isDarkMode: isDarkMode,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            accentColor: accentColor,
          ),
          Divider(height: 16, color: borderColor),
          _buildInfoRow(
            icon: _club.inscripcionesAbiertas
                ? Icons.how_to_reg_rounded
                : Icons.lock_clock_outlined,
            title: 'Estado de convocatoria',
            subtitle: _club.inscripcionesAbiertas
                ? (tieneUrlValida
                      ? 'Convocatoria abierta mediante Microsoft Forms'
                      : 'Convocatoria abierta')
                : 'Inscripciones cerradas temporalmente',
            isDarkMode: isDarkMode,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            accentColor: _club.inscripcionesAbiertas
                ? const Color(0xFF34D399)
                : accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: isDarkMode ? 0.14 : 0.10),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19, color: accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 13,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClubPostCard({
    required PublicacionModel pub,
    required bool isDarkMode,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _primaryBlue.withValues(
                  alpha: isDarkMode ? 0.22 : 0.12,
                ),
                child: Text(
                  pub.autorNombre.isNotEmpty
                      ? pub.autorNombre[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pub.autorNombre,
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
              ),
              Text(
                '${pub.creadoEn.day}/${pub.creadoEn.month}/${pub.creadoEn.year}',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          if (pub.titulo.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              pub.titulo,
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 6),
          MarkdownBody(
            data: pub.contenido,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 14,
                height: 1.45,
                color: textSecondary,
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
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
