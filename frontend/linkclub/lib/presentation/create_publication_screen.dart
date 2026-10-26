import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linkclub/data/publication_repository.dart';

class CreatePublicationScreen extends StatefulWidget {
  const CreatePublicationScreen({super.key});

  @override
  State<CreatePublicationScreen> createState() =>
      _CreatePublicationScreenState();
}

class _CreatePublicationScreenState extends State<CreatePublicationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _contenidoController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final PublicacionRepository _repository = PublicacionRepository();

  XFile? _imagenSeleccionada;
  bool _usarUrlExterna = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.index == 1) {
        FocusScope.of(context).unfocus();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _contenidoController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (imagen != null) {
      setState(() {
        _imagenSeleccionada = imagen;
        _urlController.clear();
      });
    }
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
          title: const Text('Insertar Hipervínculo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(labelText: 'Texto visible'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: linkController,
                decoration: const InputDecoration(
                  labelText: 'URL (https://...)',
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
    final contenido = _contenidoController.text.trim();
    if (contenido.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe algo para tu publicación.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imagenFinalUrl =
          _usarUrlExterna && _urlController.text.trim().isNotEmpty
          ? _urlController.text.trim()
          : null;

      await _repository.crearPublicacionConArchivo(
        contenido,
        imagenUrl: imagenFinalUrl,
        archivoLocal: _usarUrlExterna ? null : _imagenSeleccionada,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Publicación creada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al publicar: $e'),
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        title: const Text(
          'Crear Publicación',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
        ),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: colorScheme.primaryContainer.withOpacity(0.5),
              ),
              labelColor: colorScheme.onPrimaryContainer,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelPadding: EdgeInsets.zero,
              tabs: const [
                Tab(
                  height: 36,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_note, size: 18),
                      SizedBox(width: 6),
                      Text('Editor'),
                    ],
                  ),
                ),
                Tab(
                  height: 36,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.visibility, size: 18),
                      SizedBox(width: 6),
                      Text('Vista Previa'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton.filled(
              onPressed: _isLoading ? null : _publicar,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                minimumSize: const Size(44, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              tooltip: 'Enviar',
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        0.4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Wrap(
                      spacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.format_bold, size: 20),
                          onPressed: () => _aplicarFormato('**'),
                          tooltip: 'Negrita',
                        ),
                        IconButton(
                          icon: const Icon(Icons.format_italic, size: 20),
                          onPressed: () => _aplicarFormato('*'),
                          tooltip: 'Cursiva',
                        ),
                        IconButton(
                          icon: const Icon(Icons.title, size: 20),
                          onPressed: () => _aplicarFormato('', prefix: '### '),
                          tooltip: 'Título',
                        ),
                        IconButton(
                          icon: const Icon(Icons.link, size: 20),
                          onPressed: _insertarEnlace,
                          tooltip: 'Enlace',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.format_list_bulleted,
                            size: 20,
                          ),
                          onPressed: () => _aplicarFormato('', prefix: '- '),
                          tooltip: 'Lista',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contenidoController,
                  maxLines: 8,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText:
                        'Escribe tu anuncio aquí con formato... \n\n(Usa doble espacio o doble Enter para separar párrafos)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Adjuntar Imagen o Afiche',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 10),

                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Archivo Local'),
                      icon: Icon(Icons.phone_android, size: 18),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Enlace Web URL'),
                      icon: Icon(Icons.link, size: 18),
                    ),
                  ],
                  selected: {_usarUrlExterna},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _usarUrlExterna = newSelection.first;
                      if (_usarUrlExterna) {
                        _imagenSeleccionada = null;
                      } else {
                        _urlController.clear();
                      }
                    });
                  },
                ),
                const SizedBox(height: 14),

                if (_usarUrlExterna)
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'https://ejemplo.com/imagen.jpg',
                      prefixIcon: const Icon(Icons.link_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                else
                  _imagenSeleccionada != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.network(
                                      _imagenSeleccionada!.path,
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_imagenSeleccionada!.path),
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                radius: 16,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  onPressed: () => setState(
                                    () => _imagenSeleccionada = null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : OutlinedButton.icon(
                          onPressed: _seleccionarImagen,
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Elegir imagen de la galería'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
              ],
            ),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 4),
                  child: Text(
                    'Previsualización en el Feed:',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Card(
                  margin: EdgeInsets.zero,
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
                                'U',
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
                                  const Text(
                                    'Tu Nombre',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Hace 0 min',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        MarkdownBody(
                          data: _contenidoController.text.isEmpty
                              ? '*Tu publicación aparecerá aquí...*'
                              : _contenidoController.text,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 15, height: 1.4),
                            strong: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            em: const TextStyle(fontStyle: FontStyle.italic),

                            a: const TextStyle(
                              color: Colors.blueAccent,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),

                        if (_imagenSeleccionada != null ||
                            _urlController.text.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _usarUrlExterna
                                ? Image.network(
                                    _urlController.text,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  )
                                : (kIsWeb
                                      ? Image.network(
                                          _imagenSeleccionada!.path,
                                          width: double.infinity,
                                          height: 200,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(_imagenSeleccionada!.path),
                                          width: double.infinity,
                                          height: 200,
                                          fit: BoxFit.cover,
                                        )),
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
                            _buildDummyAction(
                              Icons.favorite_border_rounded,
                              'Me gusta',
                            ),
                            _buildDummyAction(
                              Icons.chat_bubble_outline_rounded,
                              'Comentar',
                            ),
                            _buildDummyAction(
                              Icons.share_outlined,
                              'Compartir',
                            ),
                          ],
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

  Widget _buildDummyAction(IconData icon, String label) {
    return Row(
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
    );
  }
}
