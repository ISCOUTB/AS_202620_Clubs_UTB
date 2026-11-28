import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:linkclub/core/session/session_controller.dart';
import 'package:linkclub/data/event_repository.dart';
import 'package:linkclub/presentation/create_event_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with WidgetsBindingObserver {
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
  static const Color _emerald = Color(0xFF10B981);
  static const Color _amberUrgent = Color(0xFFF59E0B);
  static const Color _buttonTextLight = Color(0xFFF1F5F9);

  static const List<String> _categoriasEventos = [
    'Todos los eventos',
    'Tecnología',
    'Robótica e IA',
    'Deportes',
    'Arte y Cultura',
    'Fotografía y Medios',
    'Ciencia y Estrategia',
    'Originales',
  ];

  final EventRepository _repository = EventRepository();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _procesandoAsistencia = <String>{};

  List<EventoModel> _todosLosEventos = [];
  bool _isLoading = true;
  String? _errorMensaje;

  late DateTime _ultimaFechaActualVista;
  late DateTime _lunesSemanaActual;
  DateTime? _diaSeleccionado;
  String _categoriaSeleccionada = 'Todos los eventos';
  String _queryBusqueda = '';
  bool _mostrarBuscador = false;

  DateTime get _hoyReal {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  bool _mismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final hoy = _hoyReal;
    _ultimaFechaActualVista = hoy;
    _diaSeleccionado = hoy;
    _lunesSemanaActual = hoy.subtract(Duration(days: hoy.weekday - 1));
    _cargarEventos();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sincronizarDiaActualSiCambio();
    }
  }

  void _sincronizarDiaActualSiCambio() {
    final hoy = _hoyReal;
    if (!_mismoDia(hoy, _ultimaFechaActualVista) && mounted) {
      setState(() {
        final seguiaHoyAnterior =
            _diaSeleccionado != null &&
            _mismoDia(_diaSeleccionado!, _ultimaFechaActualVista);
        _ultimaFechaActualVista = hoy;
        _lunesSemanaActual = hoy.subtract(Duration(days: hoy.weekday - 1));
        if (seguiaHoyAnterior) {
          _diaSeleccionado = hoy;
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarEventos() async {
    _sincronizarDiaActualSiCambio();
    setState(() {
      _isLoading = true;
      _errorMensaje = null;
    });

    try {
      final eventos = await _repository.obtenerEventos();
      if (mounted) {
        setState(() {
          _todosLosEventos = eventos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMensaje = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _normalizarCategoriaEvento(String rawCategoria) {
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

  List<EventoModel> get _eventosFiltrados {
    return _todosLosEventos.where((ev) {
      final coincideDia =
          _diaSeleccionado == null ||
          _mismoDia(ev.fechaInicio, _diaSeleccionado!);

      final coincideCategoria =
          _categoriaSeleccionada == 'Todos los eventos' ||
          _normalizarCategoriaEvento(ev.clubCategoria) ==
              _categoriaSeleccionada;

      final q = _queryBusqueda.toLowerCase();
      final coincideTexto =
          q.isEmpty ||
          ev.titulo.toLowerCase().contains(q) ||
          ev.clubNombre.toLowerCase().contains(q) ||
          ev.lugar.toLowerCase().contains(q);

      return coincideDia && coincideCategoria && coincideTexto;
    }).toList();
  }

  List<EventoModel> get _eventosInscritosUrgentes {
    final ahora = DateTime.now();
    final limite48h = ahora.add(const Duration(hours: 48));
    final lista = _todosLosEventos.where((ev) {
      if (!ev.usuarioAsiste || ev.yaFinalizo) return false;
      final empezoHacePoco = ev.fechaInicio.isAfter(
        ahora.subtract(const Duration(hours: 2)),
      );
      final empiezaPronto = ev.fechaInicio.isBefore(limite48h);
      return empezoHacePoco && empiezaPronto;
    }).toList()..sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
    return lista;
  }

  Future<void> _abrirEnlaceInApp(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El enlace de inscripción no tiene un formato válido.',
            style: TextStyle(fontFamily: _fontFamily),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!ok) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _abrirCrearEvento() async {
    if (!SessionController.instance.puedeGestionarAlgunClub) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solo los administradores de club verificados pueden programar eventos.',
            style: TextStyle(fontFamily: _fontFamily),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final creado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateEventScreen()),
    );
    if (creado == true) {
      _cargarEventos();
    }
  }

  Future<void> _inscribirseEnEvento(EventoModel evento) async {
    if (!SessionController.instance.estaAutenticado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Inicia sesión con tu cuenta institucional para inscribirte.',
            style: TextStyle(fontFamily: _fontFamily),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (evento.tieneEnlaceExterno) {
      await _abrirEnlaceInApp(evento.enlaceRegistroMs!);
    }

    if (!evento.usuarioAsiste) {
      await _toggleAsistencia(evento);
    }
  }

  Future<void> _toggleAsistencia(EventoModel evento) async {
    if (!SessionController.instance.estaAutenticado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Inicia sesión con tu cuenta institucional para confirmar asistencia.',
            style: TextStyle(fontFamily: _fontFamily),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_procesandoAsistencia.contains(evento.id)) return;

    final idx = _todosLosEventos.indexWhere((e) => e.id == evento.id);
    if (idx == -1) return;

    final previo = _todosLosEventos[idx];
    final nuevoAsiste = !previo.usuarioAsiste;
    final nuevoConteo = (previo.totalAsistentes + (nuevoAsiste ? 1 : -1)).clamp(
      0,
      999999,
    );

    setState(() {
      _procesandoAsistencia.add(evento.id);
      _todosLosEventos[idx] = previo.copyWith(
        usuarioAsiste: nuevoAsiste,
        totalAsistentes: nuevoConteo,
      );
    });

    try {
      final res = await _repository.alternarAsistencia(evento.id);
      if (mounted) {
        setState(() {
          _todosLosEventos[idx] = previo.copyWith(
            usuarioAsiste: res.usuarioAsiste,
            totalAsistentes: res.totalAsistentes,
          );
          _procesandoAsistencia.remove(evento.id);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _todosLosEventos[idx] = previo;
          _procesandoAsistencia.remove(evento.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo registrar tu inscripción. Intenta nuevamente.',
              style: TextStyle(fontFamily: _fontFamily),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _mostrarOpcionesInscrito(EventoModel evento, bool isDarkMode) {
    final sheetBg = isDarkMode ? _darkCard : _lightCard;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final titleColor = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final bodyColor = isDarkMode ? _darkTextBody : _lightTextBody;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: borderColor, width: 1),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _emerald.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: _emerald,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ya registraste tu inscripción',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu cupo está contabilizado en "${evento.titulo}". Recibirás un recordatorio cuando el evento esté próximo.',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 13.5,
                    height: 1.45,
                    color: bodyColor,
                  ),
                ),
                const SizedBox(height: 18),
                if (evento.tieneEnlaceExterno) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _abrirEnlaceInApp(evento.enlaceRegistroMs!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandBlue,
                        foregroundColor: _buttonTextLight,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                      label: const Text(
                        'Abrir formulario de MS Forms nuevamente',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _toggleAsistencia(evento);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(
                        color: Colors.redAccent.withValues(alpha: 0.45),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text(
                      'Cancelar mi inscripción',
                      style: TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 13,
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
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? _darkBg : _lightBg;
    final accentColor = isDarkMode ? _brandBlueSoft : _brandBlue;
    final filtrados = _eventosFiltrados;
    final urgentes = _eventosInscritosUrgentes;

    return ListenableBuilder(
      listenable: SessionController.instance,
      builder: (context, _) {
        final session = SessionController.instance;
        final puedeCrearEventos = session.puedeGestionarAlgunClub;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'Eventos Disponibles',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? _darkTextPrimary : _lightTextPrimary,
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _cargarEventos,
            color: accentColor,
            backgroundColor: isDarkMode ? _darkCard : _lightCard,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                puedeCrearEventos ? 92 : 28,
              ),
              children: [
                if (urgentes.isNotEmpty) ...[
                  _buildBannerProximoEvento(urgentes.first, isDarkMode),
                  const SizedBox(height: 12),
                ],
                _buildWeekCalendarCard(isDarkMode),
                const SizedBox(height: 12),
                _buildCategoryStrip(isDarkMode),
                if (_mostrarBuscador) ...[
                  const SizedBox(height: 12),
                  _buildSearchField(isDarkMode),
                ],
                const SizedBox(height: 16),
                _buildSectionHeader(
                  isDarkMode: isDarkMode,
                  totalActivos: filtrados.length,
                ),
                const SizedBox(height: 12),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  )
                else if (_errorMensaje != null)
                  _buildErrorState(isDarkMode)
                else if (filtrados.isEmpty)
                  _buildEmptyState(
                    isDarkMode: isDarkMode,
                    puedeCrearEventos: puedeCrearEventos,
                  )
                else
                  ...filtrados.map(
                    (ev) => _buildEventCard(evento: ev, isDarkMode: isDarkMode),
                  ),
              ],
            ),
          ),
          floatingActionButton: puedeCrearEventos
              ? FloatingActionButton(
                  onPressed: _abrirCrearEvento,
                  tooltip: 'Programar evento',
                  backgroundColor: _brandBlue,
                  foregroundColor: _buttonTextLight,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.add_rounded, size: 26),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBannerProximoEvento(EventoModel evento, bool isDarkMode) {
    final ahora = DateTime.now();
    final diff = evento.fechaInicio.difference(ahora);
    final hoy = _hoyReal;
    final manana = hoy.add(const Duration(days: 1));

    String etiquetaUrgencia;
    if (diff.isNegative) {
      etiquetaUrgencia = '¡En curso ahora!';
    } else if (diff.inMinutes < 60) {
      final mins = diff.inMinutes < 1 ? 1 : diff.inMinutes;
      etiquetaUrgencia = '¡Empieza en $mins min!';
    } else if (_mismoDia(evento.fechaInicio, hoy)) {
      etiquetaUrgencia = 'Hoy • ${_formatearHora12(evento.fechaInicio)}';
    } else if (_mismoDia(evento.fechaInicio, manana)) {
      etiquetaUrgencia = 'Mañana • ${_formatearHora12(evento.fechaInicio)}';
    } else {
      etiquetaUrgencia =
          'Próximo • ${evento.fechaInicio.day} ${_mesCorto(evento.fechaInicio.month)}';
    }

    return GestureDetector(
      onTap: () => _mostrarDetalleEvento(evento, isDarkMode),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A1610) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _amberUrgent.withValues(alpha: isDarkMode ? 0.55 : 0.45),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _amberUrgent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: _amberUrgent,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _amberUrgent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          etiquetaUrgencia,
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode
                                ? const Color(0xFFFCD34D)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Evento inscrito',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode
                                ? _darkTextSecondary
                                : _lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    evento.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? _darkTextPrimary : _lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${evento.clubNombre} • ${evento.lugar}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 11.5,
                      color: isDarkMode
                          ? _darkTextSecondary
                          : _lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: isDarkMode ? _darkTextSecondary : _lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekCalendarCard(bool isDarkMode) {
    final cardBg = isDarkMode ? _darkCard : _lightCard;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final titleColor = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final secondaryColor = isDarkMode
        ? _darkTextSecondary
        : _lightTextSecondary;
    final hoy = _hoyReal;
    final lunesActualReal = hoy.subtract(Duration(days: hoy.weekday - 1));
    final enSemanaActual = _mismoDia(_lunesSemanaActual, lunesActualReal);
    final hoyYaSeleccionado =
        _diaSeleccionado != null && _mismoDia(_diaSeleccionado!, hoy);

    final diasSemana = List.generate(
      7,
      (i) => _lunesSemanaActual.add(Duration(days: i)),
    );
    const nombresDias = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    _formatearMesAnio(_lunesSemanaActual),
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildWeekNavBtn(
                    icon: Icons.chevron_left_rounded,
                    isDarkMode: isDarkMode,
                    onTap: () => setState(() {
                      _lunesSemanaActual = _lunesSemanaActual.subtract(
                        const Duration(days: 7),
                      );
                    }),
                  ),
                  const SizedBox(width: 4),
                  _buildWeekNavBtn(
                    icon: Icons.chevron_right_rounded,
                    isDarkMode: isDarkMode,
                    onTap: () => setState(() {
                      _lunesSemanaActual = _lunesSemanaActual.add(
                        const Duration(days: 7),
                      );
                    }),
                  ),
                ],
              ),
              Row(
                children: [
                  if (!enSemanaActual || !hoyYaSeleccionado) ...[
                    GestureDetector(
                      onTap: () => setState(() {
                        final h = _hoyReal;
                        _lunesSemanaActual = h.subtract(
                          Duration(days: h.weekday - 1),
                        );
                        _diaSeleccionado = h;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _emerald.withValues(
                            alpha: isDarkMode ? 0.16 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _emerald.withValues(alpha: 0.45),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Hoy',
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _emerald,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (_diaSeleccionado != null)
                    GestureDetector(
                      onTap: () => setState(() => _diaSeleccionado = null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode ? _darkElevated : _lightElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Text(
                          'Ver todos',
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: secondaryColor,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(7, (index) {
              final dia = diasSemana[index];
              final esHoy = _mismoDia(dia, hoy);
              final seleccionado =
                  _diaSeleccionado != null && _mismoDia(_diaSeleccionado!, dia);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 6 ? 4 : 0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (seleccionado) {
                          _diaSeleccionado = null;
                        } else {
                          _diaSeleccionado = dia;
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: seleccionado
                            ? _brandBlue
                            : (esHoy
                                  ? _emerald.withValues(
                                      alpha: isDarkMode ? 0.12 : 0.08,
                                    )
                                  : Colors.transparent),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: esHoy
                              ? _emerald
                              : (seleccionado
                                    ? const Color(
                                        0xFF3B82F6,
                                      ).withValues(alpha: 0.5)
                                    : Colors.transparent),
                          width: esHoy ? 1.6 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nombresDias[index],
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 10,
                              fontWeight: esHoy || seleccionado
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: seleccionado
                                  ? _buttonTextLight.withValues(alpha: 0.9)
                                  : (esHoy ? _emerald : secondaryColor),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dia.day}',
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 13.5,
                              fontWeight: esHoy || seleccionado
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: seleccionado
                                  ? _buttonTextLight
                                  : (esHoy ? _emerald : titleColor),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: esHoy ? _emerald : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavBtn({
    required IconData icon,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isDarkMode ? _darkElevated : _lightElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDarkMode ? _darkBorder : _lightBorder,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isDarkMode ? _darkTextSecondary : _lightTextSecondary,
        ),
      ),
    );
  }

  Widget _buildCategoryStrip(bool isDarkMode) {
    final cardBg = isDarkMode ? _darkCard : _lightCard;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final textInactive = isDarkMode ? _darkTextBody : _lightTextBody;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categoriasEventos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categoriasEventos[index];
          final activa = cat == _categoriaSeleccionada;
          return GestureDetector(
            onTap: () => setState(() => _categoriaSeleccionada = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: activa ? _brandBlue : cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activa
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.45)
                      : borderColor,
                  width: 1,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 12.5,
                  fontWeight: activa ? FontWeight.w700 : FontWeight.w500,
                  color: activa ? _buttonTextLight : textInactive,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField(bool isDarkMode) {
    final cardBg = isDarkMode ? _darkCard : _lightCard;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final textColor = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final hintColor = isDarkMode ? _darkTextSecondary : _lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _queryBusqueda = v.trim()),
        style: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13.5,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar por evento, club o lugar...',
          hintStyle: TextStyle(fontFamily: _fontFamily, color: hintColor),
          prefixIcon: Icon(Icons.search_rounded, size: 19, color: hintColor),
          suffixIcon: _queryBusqueda.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: hintColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _queryBusqueda = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required bool isDarkMode,
    required int totalActivos,
  }) {
    final titleColor = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final secondaryColor = isDarkMode
        ? _darkTextSecondary
        : _lightTextSecondary;
    final accentColor = isDarkMode ? _brandBlueSoft : _brandBlue;
    final hoy = _hoyReal;

    String tituloSeccion;
    if (_diaSeleccionado == null) {
      tituloSeccion = 'Próximos Eventos';
    } else if (_mismoDia(_diaSeleccionado!, hoy)) {
      tituloSeccion = 'Eventos de Hoy';
    } else {
      tituloSeccion =
          'Eventos del ${_diaSeleccionado!.day} ${_mesCorto(_diaSeleccionado!.month)}';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          tituloSeccion,
          style: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: titleColor,
            letterSpacing: -0.2,
          ),
        ),
        Row(
          children: [
            InkWell(
              onTap: () => setState(() => _mostrarBuscador = !_mostrarBuscador),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isDarkMode ? _darkCard : _lightCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDarkMode ? _darkBorder : _lightBorder,
                    width: 1,
                  ),
                ),
                child: Icon(
                  _mostrarBuscador
                      ? Icons.search_off_rounded
                      : Icons.search_rounded,
                  size: 16,
                  color: secondaryColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _brandBlue.withValues(alpha: isDarkMode ? 0.16 : 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Text(
                '$totalActivos ${totalActivos == 1 ? 'activo' : 'activos'}',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventCard({
    required EventoModel evento,
    required bool isDarkMode,
  }) {
    final cardBg = isDarkMode ? _darkCard : _lightCard;
    final elevatedBg = isDarkMode ? _darkElevated : _lightElevated;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final titleColor = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final bodyColor = isDarkMode ? _darkTextBody : _lightTextBody;
    final secondaryColor = isDarkMode
        ? _darkTextSecondary
        : _lightTextSecondary;
    final accentColor = isDarkMode ? _brandBlueSoft : _brandBlue;
    final hasImage =
        evento.imagenUrl != null && evento.imagenUrl!.trim().isNotEmpty;
    final cargandoRsvp = _procesandoAsistencia.contains(evento.id);

    return GestureDetector(
      onTap: () => _mostrarDetalleEvento(evento, isDarkMode),
      child: Container(
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
            SizedBox(
              height: 114,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.network(
                      evento.imagenUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildFallbackBanner(evento, isDarkMode),
                    )
                  else
                    _buildFallbackBanner(evento, isDarkMode),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          (isDarkMode ? _darkCard : const Color(0xFF0F172A))
                              .withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                  if (evento.esSoloClub)
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF080C14,
                          ).withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 12,
                              color: _brandBlueSoft,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Solo miembros',
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: _darkTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  evento.clubNombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: _fontFamily,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: _buttonTextLight,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: _brandBlueSoft,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: evento.yaFinalizo
                                    ? _darkTextSecondary
                                    : _emerald,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              evento.yaFinalizo
                                  ? 'Finalizado'
                                  : (evento.tieneEnlaceExterno
                                        ? 'Inscripciones abiertas'
                                        : 'Convocatoria abierta'),
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: evento.yaFinalizo
                                    ? _darkTextSecondary
                                    : _emerald,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evento.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: elevatedBg,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: accentColor,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            _formatearHorarioYLugar(evento),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: bodyColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.people_alt_outlined,
                            size: 15,
                            color: secondaryColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${evento.totalAsistentes} ${evento.totalAsistentes == 1 ? 'inscrito' : 'inscritos'}',
                            style: TextStyle(
                              fontFamily: _fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                      _buildActionCta(
                        evento: evento,
                        isDarkMode: isDarkMode,
                        cargando: cargandoRsvp,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackBanner(EventoModel evento, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? const [Color(0xFF13223F), Color(0xFF0E1729)]
              : const [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, right: 16),
          child: Icon(
            evento.iconoCategoria,
            size: 52,
            color: Colors.white.withValues(alpha: 0.14),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCta({
    required EventoModel evento,
    required bool isDarkMode,
    required bool cargando,
  }) {
    if (evento.yaFinalizo) {
      return OutlinedButton(
        onPressed: () => _mostrarDetalleEvento(evento, isDarkMode),
        style: OutlinedButton.styleFrom(
          foregroundColor: isDarkMode ? _darkTextBody : _lightTextBody,
          side: BorderSide(
            color: isDarkMode ? _darkBorder : _lightBorder,
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: const Text(
          'Ver detalles',
          style: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (evento.usuarioAsiste) {
      return InkWell(
        onTap: cargando
            ? null
            : () => _mostrarOpcionesInscrito(evento, isDarkMode),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: _emerald.withValues(alpha: isDarkMode ? 0.16 : 0.10),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: _emerald.withValues(alpha: 0.40),
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 15, color: _emerald),
              SizedBox(width: 5),
              Text(
                'Inscrito • Asistiré',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _emerald,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: cargando ? null : () => _inscribirseEnEvento(evento),
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandBlue,
          foregroundColor: _buttonTextLight,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        icon: Icon(
          evento.tieneEnlaceExterno
              ? Icons.open_in_browser_rounded
              : Icons.event_available_rounded,
          size: 15,
        ),
        label: Text(
          evento.tieneEnlaceExterno ? 'Inscribirme' : 'Asistiré',
          style: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleEvento(EventoModel evento, bool isDarkMode) {
    final sheetBg = isDarkMode ? _darkCard : _lightCard;
    final elevatedBg = isDarkMode ? _darkElevated : _lightElevated;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final titleColor = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final bodyColor = isDarkMode ? _darkTextBody : _lightTextBody;
    final secondaryColor = isDarkMode
        ? _darkTextSecondary
        : _lightTextSecondary;
    final accentColor = isDarkMode ? _brandBlueSoft : _brandBlue;
    final esOrganizadorActivo = SessionController.instance.puedeGestionarClub(
      evento.clubId,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: borderColor, width: 1),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.68,
          maxChildSize: 0.9,
          minChildSize: 0.45,
          builder: (_, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _brandBlue.withValues(
                          alpha: isDarkMode ? 0.16 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        evento.clubNombre,
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: elevatedBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Text(
                        evento.esSoloClub ? 'Solo miembros' : 'Público UTB',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                    if (esOrganizadorActivo)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _emerald.withValues(
                            alpha: isDarkMode ? 0.16 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _emerald.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Organizador',
                          style: TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _emerald,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  evento.titulo,
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: elevatedBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    children: [
                      _buildMetaRow(
                        icon: Icons.calendar_today_rounded,
                        label: _formatearHorarioYLugar(evento),
                        accent: accentColor,
                        textColor: bodyColor,
                      ),
                      const SizedBox(height: 10),
                      _buildMetaRow(
                        icon: Icons.location_on_outlined,
                        label: evento.lugar,
                        accent: accentColor,
                        textColor: bodyColor,
                      ),
                      const SizedBox(height: 10),
                      _buildMetaRow(
                        icon: Icons.people_alt_outlined,
                        label:
                            '${evento.totalAsistentes} ${evento.totalAsistentes == 1 ? 'estudiante inscrito' : 'estudiantes inscritos'}',
                        accent: accentColor,
                        textColor: bodyColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Acerca del evento',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 6),
                MarkdownBody(
                  data: evento.descripcion,
                  selectable: true,
                  onTapLink: (_, href, __) {
                    if (href != null) _abrirEnlaceInApp(href);
                  },
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 14.5,
                      height: 1.5,
                      color: bodyColor,
                    ),
                    strong: TextStyle(
                      fontFamily: _fontFamily,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                    a: TextStyle(
                      fontFamily: _fontFamily,
                      color: accentColor,
                      decoration: TextDecoration.underline,
                      decorationColor: accentColor,
                    ),
                  ),
                ),
                if (evento.tieneEnlaceExterno) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: elevatedBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.link_rounded, size: 18, color: accentColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                _abrirEnlaceInApp(evento.enlaceRegistroMs!),
                            child: Text(
                              evento.enlaceRegistroMs!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 12.5,
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: evento.enlaceRegistroMs!),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Enlace de registro copiado al portapapeles.',
                                  style: TextStyle(fontFamily: _fontFamily),
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Text('Copiar'),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: evento.yaFinalizo
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            if (evento.usuarioAsiste) {
                              _mostrarOpcionesInscrito(evento, isDarkMode);
                            } else {
                              _inscribirseEnEvento(evento);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: evento.usuarioAsiste
                          ? _emerald
                          : _brandBlue,
                      foregroundColor: _buttonTextLight,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(
                      evento.yaFinalizo
                          ? Icons.event_busy_rounded
                          : (evento.usuarioAsiste
                                ? Icons.check_circle_rounded
                                : (evento.tieneEnlaceExterno
                                      ? Icons.open_in_browser_rounded
                                      : Icons.event_available_rounded)),
                      size: 18,
                    ),
                    label: Text(
                      evento.yaFinalizo
                          ? 'Evento finalizado'
                          : (evento.usuarioAsiste
                                ? 'Inscrito • Asistiré'
                                : (evento.tieneEnlaceExterno
                                      ? 'Inscribirme en MS Forms'
                                      : 'Confirmar mi asistencia')),
                      style: const TextStyle(
                        fontFamily: _fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required Color accent,
    required Color textColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required bool isDarkMode,
    required bool puedeCrearEventos,
  }) {
    final cardBg = isDarkMode ? _darkCard : _lightCard;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final titleColor = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final secondaryColor = isDarkMode
        ? _darkTextSecondary
        : _lightTextSecondary;
    final accentColor = isDarkMode ? _brandBlueSoft : _brandBlue;
    final hayFiltrosActivos =
        _diaSeleccionado != null ||
        _categoriaSeleccionada != 'Todos los eventos' ||
        _queryBusqueda.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _brandBlue.withValues(alpha: isDarkMode ? 0.16 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.event_busy_outlined,
              size: 25,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No hay eventos para mostrar',
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hayFiltrosActivos
                ? 'Prueba seleccionando otro día de la semana, cambiando la categoría o limpiando tu búsqueda.'
                : (puedeCrearEventos
                      ? 'Aún no hay eventos programados. Usa el botón para publicar la próxima actividad de tu club.'
                      : 'Cuando los clubes programen talleres, torneos o convocatorias, aparecerán aquí.'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 13,
              height: 1.45,
              color: secondaryColor,
            ),
          ),
          if (puedeCrearEventos && !hayFiltrosActivos) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _abrirCrearEvento,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandBlue,
                foregroundColor: _buttonTextLight,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Programar evento',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDarkMode) {
    final cardBg = isDarkMode ? _darkCard : _lightCard;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final titleColor = isDarkMode ? _darkTextPrimary : _lightTextPrimary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 38,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 10),
          Text(
            _errorMensaje!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _fontFamily,
              fontSize: 13.5,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _cargarEventos,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  String _formatearHorarioYLugar(EventoModel ev) {
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final diaTexto = dias[ev.fechaInicio.weekday - 1];
    final mesTexto = _mesCorto(ev.fechaInicio.month);
    final horaIni = _formatearHora12(ev.fechaInicio);
    final rangoHora = ev.fechaFin != null
        ? '$horaIni – ${_formatearHora12(ev.fechaFin!)}'
        : horaIni;
    return '$diaTexto ${ev.fechaInicio.day} $mesTexto • $rangoHora • ${ev.lugar}';
  }

  String _formatearHora12(DateTime dt) {
    final hora = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final periodo = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hora:$min $periodo';
  }

  String _formatearMesAnio(DateTime dt) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${meses[dt.month - 1]} ${dt.year}';
  }

  String _mesCorto(int month) {
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return meses[month - 1];
  }
}
