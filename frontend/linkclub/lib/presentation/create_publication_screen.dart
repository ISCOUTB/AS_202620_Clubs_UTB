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

  // Función unificada y limpia (sin duplicados)
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
    } else {
      final pos = _contenidoController.selection.baseOffset;
      final insertIndex = pos < 0 ? text.length : pos;
      final newText = text.replaceRange(
        insertIndex,
        insertIndex,
        '$prefix$wrapper texto $wrapper',
      );
      _contenidoController.text = newText;
    }
  }

  void _insertarEnlace() {
    showDialog(
      context: context,
      builder: (context) {
        final linkController = TextEditingController();
        final textController = TextEditingController(text: 'enlace');
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
                  _aplicarFormato(
                    '](${linkController.text.trim()})',
                    prefix: '[',
                  );
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
        title: const Text('Crear Publicación', style: TextStyle(fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note, size: 20), text: 'Editor'),
            Tab(icon: Icon(Icons.visibility, size: 20), text: 'Vista Previa'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: IconButton.filled(
              onPressed: _isLoading ? null : _publicar,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Wrap(
                    spacing: 4,
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
                        icon: const Icon(Icons.format_list_bulleted, size: 20),
                        onPressed: () => _aplicarFormato('', prefix: '- '),
                        tooltip: 'Lista',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contenidoController,
                  maxLines: 8,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Escribe tu anuncio aquí con formato...',
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
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_imagenSeleccionada!.path),
                                      height: 160,
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

          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Así se verá tu publicación:',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      MarkdownBody(
                        data: _contenidoController.text.isEmpty
                            ? '*Escribe algo en la pestaña Editor...*'
                            : _contenidoController.text,
                        selectable: true,
                      ),
                      if (_imagenSeleccionada != null ||
                          _urlController.text.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _usarUrlExterna
                              ? Image.network(
                                  _urlController.text,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Text('URL de imagen no disponible'),
                                )
                              : (kIsWeb
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
                                      )),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
