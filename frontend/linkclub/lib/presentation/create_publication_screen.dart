import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linkclub/core/session/session_controller.dart';
import 'package:linkclub/data/publication_repository.dart';
import 'package:linkclub/presentation/publication_carousel.dart';

class CreatePublicationScreen extends StatefulWidget {
  final String? clubIdFijo;
  const CreatePublicationScreen({super.key, this.clubIdFijo});

  @override
  State<CreatePublicationScreen> createState() =>
      _CreatePublicationScreenState();
}

class _CreatePublicationScreenState extends State<CreatePublicationScreen>
    with SingleTickerProviderStateMixin {
  static const String _fontDisplay = 'Plus Jakarta Sans';
  static const String _fontBody = 'Inter';
  static const int _maxImagenes = 5;

  // Paleta Academic Vanguard
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _deepSapphire = Color(0xFF004AC6);
  static const Color _softBlue = Color(0xFF60A5FA);

  static const Color _lightBg = Color(0xFFF8F9FF);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceLow = Color(0xFFEFF4FF);
  static const Color _lightBorder = Color(0xFFE2E8F0);
  static const Color _lightTextPrimary = Color(0xFF0B1C30);
  static const Color _lightTextSecondary = Color(0xFF434655);

  static const Color _darkBg = Color(0xFF080C14);
  static const Color _darkSurface = Color(0xFF0F1623);
  static const Color _darkElevated = Color(0xFF131B2E);
  static const Color _darkBorder = Color(0xFF1E293B);
  static const Color _darkTextPrimary = Color(0xFFF1F5F9);
  static const Color _darkTextSecondary = Color(0xFF94A3B8);

  late TabController _tabController;
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _contenidoController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final PublicacionRepository _repository = PublicacionRepository();

  String? _clubAdministradoId;
  String? _clubAdministradoNombre;
  bool _cargandoClub = true;

  final List<XFile> _imagenesSeleccionadas = [];
  final List<String> _urlsExternas = [];
  bool _usarUrlExterna = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarClubAdministrado();

    _tabController.addListener(() {
      if (_tabController.index == 1) {
        FocusScope.of(context).unfocus();
        setState(() {});
      }
    });
  }

  Future<void> _cargarClubAdministrado() async {
    final session = SessionController.instance;
    if (session.usuario == null) {
      await session.cargarSesion();
    }

    final String? clubCuentaId =
        (session.usuario?.clubAdministradoId != null &&
            session.usuario!.clubAdministradoId!.trim().isNotEmpty)
        ? session.usuario!.clubAdministradoId!.trim()
        : null;

    final String? clubFijoParam =
        (widget.clubIdFijo != null && widget.clubIdFijo!.trim().isNotEmpty)
        ? widget.clubIdFijo!.trim()
        : null;

    String? idObjetivo = clubFijoParam ?? clubCuentaId;
    String? nombreObjetivo;

    if (idObjetivo != null && idObjetivo == clubCuentaId) {
      final nombreSesion = session.usuario?.clubAdministradoNombre?.trim();
      if (nombreSesion != null && nombreSesion.isNotEmpty) {
        nombreObjetivo = nombreSesion;
      }
    }

    if (idObjetivo == null || nombreObjetivo == null) {
      try {
        final lista = await _repository.obtenerClubes();
        if (idObjetivo != null) {
          final match = lista.where((c) => c.id == idObjetivo);
          if (match.isNotEmpty) {
            nombreObjetivo = match.first.nombre;
          }
        } else if (session.esSuperAdminReal) {
          final institucional = lista.where(
            (c) =>
                c.categoria.trim().toLowerCase() == 'institucional' ||
                c.nombre.trim() == '-Desarrollo y Soporte-',
          );
          if (institucional.isNotEmpty) {
            idObjetivo = institucional.first.id;
            nombreObjetivo = institucional.first.nombre;
          }
        }
      } catch (_) {}
    }

    nombreObjetivo ??=
        session.usuario?.clubAdministradoNombre ??
        (session.esSuperAdminReal ? '-Desarrollo y Soporte-' : 'Club asignado');

    if (!mounted) return;
    setState(() {
      _clubAdministradoId = idObjetivo;
      _clubAdministradoNombre = nombreObjetivo;
      _cargandoClub = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tituloController.dispose();
    _contenidoController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  String get _nombreClubActual {
    if (_clubAdministradoNombre != null &&
        _clubAdministradoNombre!.trim().isNotEmpty) {
      return _clubAdministradoNombre!.trim();
    }
    return SessionController.instance.usuario?.clubAdministradoNombre ??
        'Club UTB';
  }

  List<PublicationCarouselItem> get _itemsCarruselActuales {
    if (_usarUrlExterna) {
      final limpias = List<String>.from(_urlsExternas);
      final pendiente = _urlController.text.trim();
      if (pendiente.isNotEmpty &&
          !limpias.contains(pendiente) &&
          limpias.length < _maxImagenes) {
        limpias.add(pendiente);
      }
      return limpias
          .map((u) => PublicationCarouselItem(pathOrUrl: u, isLocalFile: false))
          .toList();
    }
    return _imagenesSeleccionadas
        .map(
          (x) => PublicationCarouselItem(pathOrUrl: x.path, isLocalFile: true),
        )
        .toList();
  }

  Future<void> _seleccionarImagenes() async {
    final restantes = _maxImagenes - _imagenesSeleccionadas.length;
    if (restantes <= 0) {
      _mostrarAviso(
        'Puedes adjuntar un máximo de $_maxImagenes fotos por publicación.',
        Colors.orangeAccent,
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final List<XFile> elegidas = await picker.pickMultiImage(
      imageQuality: 80,
      limit: restantes,
    );

    if (elegidas.isEmpty || !mounted) return;

    setState(() {
      for (final img in elegidas) {
        if (_imagenesSeleccionadas.length >= _maxImagenes) break;
        final yaExiste = _imagenesSeleccionadas.any(
          (actual) => actual.path == img.path && actual.name == img.name,
        );
        if (!yaExiste) {
          _imagenesSeleccionadas.add(img);
        }
      }
      _urlsExternas.clear();
      _urlController.clear();
    });
  }

  void _agregarUrlExterna() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      _mostrarAviso(
        'Ingresa un enlace válido que empiece con http:// o https://',
        Colors.orangeAccent,
      );
      return;
    }

    if (_urlsExternas.length >= _maxImagenes) {
      _mostrarAviso(
        'Puedes adjuntar un máximo de $_maxImagenes fotos por publicación.',
        Colors.orangeAccent,
      );
      return;
    }

    if (_urlsExternas.contains(url)) {
      _urlController.clear();
      return;
    }

    setState(() {
      _urlsExternas.add(url);
      _urlController.clear();
    });
  }

  void _aplicarFormato(String wrapper, {String prefix = ''}) {
    final text = _contenidoController.text;
    final selection = _contenidoController.selection;

    if (selection.isValid && !selection.isCollapsed) {
      final selectedText = selection.textInside(text);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$wrapper$selectedText$wrapper',
      );
      _contenidoController.text = newText;
      _contenidoController.selection = TextSelection.collapsed(
        offset:
            selection.start +
            prefix.length +
            wrapper.length +
            selectedText.length +
            wrapper.length,
      );
    } else {
      final pos = _contenidoController.selection.baseOffset;
      final insertIndex = pos < 0 ? text.length : pos;
      final newText = text.replaceRange(
        insertIndex,
        insertIndex,
        '$prefix$wrapper texto $wrapper',
      );
      _contenidoController.text = newText;
      _contenidoController.selection = TextSelection.collapsed(
        offset:
            insertIndex + prefix.length + wrapper.length + 6 + wrapper.length,
      );
    }
  }

  void _insertarEnlaceTexto(String textoVisible, String url) {
    final text = _contenidoController.text;
    final selection = _contenidoController.selection;
    final enlaceMarkdown = '[$textoVisible]($url)';

    if (selection.isValid && !selection.isCollapsed) {
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        enlaceMarkdown,
      );
      _contenidoController.text = newText;
      _contenidoController.selection = TextSelection.collapsed(
        offset: selection.start + enlaceMarkdown.length,
      );
    } else {
      final pos = _contenidoController.selection.baseOffset;
      final insertIndex = pos < 0 ? text.length : pos;
      final newText = text.replaceRange(
        insertIndex,
        insertIndex,
        enlaceMarkdown,
      );
      _contenidoController.text = newText;
      _contenidoController.selection = TextSelection.collapsed(
        offset: insertIndex + enlaceMarkdown.length,
      );
    }
  }

  void _insertarEnlace() {
    final selection = _contenidoController.selection;
    final text = _contenidoController.text;

    String textoPreseleccionado = 'enlace';
    if (selection.isValid && !selection.isCollapsed) {
      textoPreseleccionado = text.substring(selection.start, selection.end);
    }

    final linkController = TextEditingController();
    final textController = TextEditingController(text: textoPreseleccionado);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Insertar Hipervínculo',
            style: TextStyle(
              fontFamily: _fontDisplay,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  labelText: 'Texto visible',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkController,
                decoration: InputDecoration(
                  labelText: 'URL (https://...)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (linkController.text.isNotEmpty) {
                  final texto = textController.text.trim().isNotEmpty
                      ? textController.text.trim()
                      : 'enlace';
                  _insertarEnlaceTexto(texto, linkController.text.trim());
                }
                Navigator.pop(context);
              },
              child: const Text('Insertar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _publicar() async {
    final titulo = _tituloController.text.trim();
    final contenido = _contenidoController.text.trim();

    if (_clubAdministradoId == null || _clubAdministradoId!.isEmpty) {
      _mostrarAviso(
        'No tienes un club asignado para publicar.',
        Colors.orangeAccent,
      );
      return;
    }
    if (titulo.isEmpty) {
      _mostrarAviso(
        'Ingresa un título para tu publicación.',
        Colors.orangeAccent,
      );
      return;
    }
    if (contenido.isEmpty) {
      _mostrarAviso(
        'Escribe el contenido de tu publicación.',
        Colors.orangeAccent,
      );
      return;
    }

    if (_usarUrlExterna && _urlController.text.trim().isNotEmpty) {
      _agregarUrlExterna();
    }

    setState(() => _isLoading = true);

    try {
      await _repository.crearPublicacionConArchivo(
        clubId: _clubAdministradoId!,
        titulo: titulo,
        contenido: contenido,
        imagenesUrls: _usarUrlExterna ? _urlsExternas : null,
        archivosLocales: _usarUrlExterna ? null : _imagenesSeleccionadas,
      );

      if (mounted) {
        _mostrarAviso(
          '¡Publicación creada exitosamente!',
          const Color(0xFF10B981),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final mensaje = e.toString().replaceFirst('Exception: ', '');
        _mostrarAviso(mensaje, const Color(0xFFBA1A1A));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarAviso(String texto, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          texto,
          style: const TextStyle(
            fontFamily: _fontBody,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
    required bool isDarkMode,
    required Color surfaceColor,
    required Color borderColor,
    required Color textSecondary,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        fontFamily: _fontBody,
        fontSize: 13.5,
        color: textSecondary,
      ),
      hintStyle: TextStyle(
        fontFamily: _fontBody,
        fontSize: 13.5,
        color: textSecondary.withValues(alpha: 0.7),
      ),
      prefixIcon: Icon(
        icon,
        size: 20,
        color: isDarkMode ? _softBlue : _primaryBlue,
      ),
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryBlue, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? _darkBg : _lightBg;
    final surfaceColor = isDarkMode ? _darkSurface : _lightSurface;
    final elevatedColor = isDarkMode ? _darkElevated : _lightSurfaceLow;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final textPrimary = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final textSecondary = isDarkMode ? _darkTextSecondary : _lightTextSecondary;
    final accentColor = isDarkMode ? _softBlue : _deepSapphire;

    final nombreAutor = _nombreClubActual;
    final inicialAutor = nombreAutor.isNotEmpty
        ? nombreAutor[0].toUpperCase()
        : 'U';
    final totalFotos = _usarUrlExterna
        ? _urlsExternas.length
        : _imagenesSeleccionadas.length;
    final carruselItems = _itemsCarruselActuales;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? _darkBg : _lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 62,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nueva Publicación',
          style: TextStyle(
            fontFamily: _fontDisplay,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _publicar,
              style: FilledButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 17),
              label: const Text(
                'Publicar',
                style: TextStyle(
                  fontFamily: _fontBody,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            child: Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: elevatedColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: _primaryBlue,
                  boxShadow: [
                    BoxShadow(
                      color: _primaryBlue.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: textSecondary,
                labelStyle: const TextStyle(
                  fontFamily: _fontBody,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_note_rounded, size: 18),
                        SizedBox(width: 6),
                        Text('Editor'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility_outlined, size: 17),
                        SizedBox(width: 6),
                        Text('Vista Previa'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // PESTAÑA 1: EDITOR
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recordatorio fijo del club administrado
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _primaryBlue.withValues(
                            alpha: isDarkMode ? 0.18 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.groups_rounded,
                          size: 20,
                          color: isDarkMode ? _softBlue : _primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Club administrado',
                              style: TextStyle(
                                fontFamily: _fontBody,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _cargandoClub && _clubAdministradoNombre == null
                                  ? 'Cargando club...'
                                  : _nombreClubActual,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: _fontDisplay,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _tituloController,
                  maxLength: 120,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontFamily: _fontDisplay,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  decoration: _inputDecoration(
                    label: 'Título del anuncio',
                    hint: 'Ej. Convocatoria abierta 2026-2',
                    icon: Icons.title_rounded,
                    isDarkMode: isDarkMode,
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    textSecondary: textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Barra de herramientas Markdown estilo Academic Vanguard
                Text(
                  'CONTENIDO Y FORMATO',
                  style: TextStyle(
                    fontFamily: _fontBody,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    alignment: WrapAlignment.spaceEvenly,
                    children: [
                      _buildFormatButton(
                        icon: Icons.format_bold_rounded,
                        tooltip: 'Negrita',
                        onTap: () => _aplicarFormato('**'),
                        elevatedColor: elevatedColor,
                        accentColor: accentColor,
                      ),
                      _buildFormatButton(
                        icon: Icons.format_italic_rounded,
                        tooltip: 'Cursiva',
                        onTap: () => _aplicarFormato('*'),
                        elevatedColor: elevatedColor,
                        accentColor: accentColor,
                      ),
                      _buildFormatButton(
                        icon: Icons.title_rounded,
                        tooltip: 'Subtítulo',
                        onTap: () => _aplicarFormato('', prefix: '### '),
                        elevatedColor: elevatedColor,
                        accentColor: accentColor,
                      ),
                      _buildFormatButton(
                        icon: Icons.link_rounded,
                        tooltip: 'Enlace',
                        onTap: _insertarEnlace,
                        elevatedColor: elevatedColor,
                        accentColor: accentColor,
                      ),
                      _buildFormatButton(
                        icon: Icons.format_list_bulleted_rounded,
                        tooltip: 'Lista',
                        onTap: () => _aplicarFormato('', prefix: '- '),
                        elevatedColor: elevatedColor,
                        accentColor: accentColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contenidoController,
                  maxLines: 7,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontFamily: _fontBody,
                    fontSize: 14.5,
                    height: 1.5,
                    color: textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Escribe tu anuncio aquí con formato Markdown...\n\n(Usa doble Enter para separar párrafos)',
                    hintStyle: TextStyle(
                      fontFamily: _fontBody,
                      fontSize: 14,
                      color: textSecondary.withValues(alpha: 0.75),
                    ),
                    filled: true,
                    fillColor: surfaceColor,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: _primaryBlue,
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sección Multimedia (hasta 5 fotos)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'IMÁGENES O AFICHES (MÁX. $_maxImagenes)',
                      style: TextStyle(
                        fontFamily: _fontBody,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: textSecondary,
                      ),
                    ),
                    Text(
                      '$totalFotos / $_maxImagenes',
                      style: TextStyle(
                        fontFamily: _fontBody,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: totalFotos > 0 ? accentColor : textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<bool>(
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: _primaryBlue,
                          selectedForegroundColor: Colors.white,
                          foregroundColor: textSecondary,
                          side: BorderSide(color: borderColor, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text(
                              'Archivo Local',
                              style: TextStyle(
                                fontFamily: _fontBody,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            icon: Icon(Icons.photo_library_outlined, size: 18),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text(
                              'Enlace Web URL',
                              style: TextStyle(
                                fontFamily: _fontBody,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            icon: Icon(Icons.link_rounded, size: 18),
                          ),
                        ],
                        selected: {_usarUrlExterna},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            _usarUrlExterna = newSelection.first;
                            if (_usarUrlExterna) {
                              _imagenesSeleccionadas.clear();
                            } else {
                              _urlsExternas.clear();
                              _urlController.clear();
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      if (_usarUrlExterna) ...[
                        if (_urlsExternas.isNotEmpty) ...[
                          PublicationCarousel(
                            items: _urlsExternas
                                .map(
                                  (u) => PublicationCarouselItem(
                                    pathOrUrl: u,
                                    isLocalFile: false,
                                  ),
                                )
                                .toList(),
                            isDarkMode: isDarkMode,
                            height: 220,
                            borderRadius: BorderRadius.circular(12),
                            onRemoveAt: (idx) {
                              setState(() => _urlsExternas.removeAt(idx));
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_urlsExternas.length < _maxImagenes)
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _urlController,
                                  onSubmitted: (_) => _agregarUrlExterna(),
                                  style: TextStyle(
                                    fontFamily: _fontBody,
                                    fontSize: 14,
                                    color: textPrimary,
                                  ),
                                  decoration: _inputDecoration(
                                    label:
                                        'URL de la imagen (${_urlsExternas.length + 1}/$_maxImagenes)',
                                    hint: 'https://ejemplo.com/afiche.jpg',
                                    icon: Icons.language_rounded,
                                    isDarkMode: isDarkMode,
                                    surfaceColor: elevatedColor,
                                    borderColor: borderColor,
                                    textSecondary: textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 50,
                                child: FilledButton(
                                  onPressed: _agregarUrlExterna,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _primaryBlue,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ] else ...[
                        if (_imagenesSeleccionadas.isNotEmpty) ...[
                          PublicationCarousel(
                            items: _imagenesSeleccionadas
                                .map(
                                  (img) => PublicationCarouselItem(
                                    pathOrUrl: img.path,
                                    isLocalFile: true,
                                  ),
                                )
                                .toList(),
                            isDarkMode: isDarkMode,
                            height: 220,
                            borderRadius: BorderRadius.circular(12),
                            onRemoveAt: (idx) {
                              setState(
                                () => _imagenesSeleccionadas.removeAt(idx),
                              );
                            },
                          ),
                          if (_imagenesSeleccionadas.length < _maxImagenes) ...[
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _seleccionarImagenes,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accentColor,
                                side: BorderSide(
                                  color: _primaryBlue.withValues(alpha: 0.4),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                              ),
                              icon: const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 20,
                              ),
                              label: Text(
                                'Agregar más fotos (${_imagenesSeleccionadas.length}/$_maxImagenes)',
                                style: const TextStyle(
                                  fontFamily: _fontBody,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ] else
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _seleccionarImagenes,
                            child: Container(
                              height: 115,
                              decoration: BoxDecoration(
                                color: elevatedColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _primaryBlue.withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _primaryBlue.withValues(
                                        alpha: 0.12,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: accentColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Seleccionar hasta $_maxImagenes fotos de la galería',
                                    style: TextStyle(
                                      fontFamily: _fontBody,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // PESTAÑA 2: VISTA PREVIA EN EL FEED
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFF0F172A,
                        ).withValues(alpha: isDarkMode ? 0.25 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [_primaryBlue, _deepSapphire],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      inicialAutor,
                                      style: const TextStyle(
                                        fontFamily: _fontDisplay,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nombreAutor,
                                        style: TextStyle(
                                          fontFamily: _fontDisplay,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Ahora',
                                        style: TextStyle(
                                          fontFamily: _fontBody,
                                          fontSize: 12,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_tituloController.text.trim().isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                _tituloController.text.trim(),
                                style: TextStyle(
                                  fontFamily: _fontDisplay,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            MarkdownBody(
                              data: _contenidoController.text.isEmpty
                                  ? '*El contenido de tu publicación aparecerá aquí...*'
                                  : _contenidoController.text,
                              selectable: true,
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  fontFamily: _fontBody,
                                  fontSize: 14.5,
                                  height: 1.5,
                                  color: textPrimary,
                                ),
                                h3: TextStyle(
                                  fontFamily: _fontDisplay,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                                strong: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                                em: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: textSecondary,
                                ),
                                a: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (carruselItems.isNotEmpty)
                        PublicationCarousel(
                          items: carruselItems,
                          isDarkMode: isDarkMode,
                          height: 300,
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildDummyAction(
                              Icons.favorite_border_rounded,
                              'Me gusta',
                              textSecondary,
                            ),
                            _buildDummyAction(
                              Icons.chat_bubble_outline_rounded,
                              'Comentar',
                              textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required Color elevatedColor,
    required Color accentColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 36,
            child: Icon(icon, size: 19, color: accentColor),
          ),
        ),
      ),
    );
  }

  Widget _buildDummyAction(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: _fontBody,
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}