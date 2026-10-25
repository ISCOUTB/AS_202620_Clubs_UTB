import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linkclub/data/publication_repository.dart';

class CreatePublicationScreen extends StatefulWidget {
  const CreatePublicationScreen({super.key});

  @override
  State<CreatePublicationScreen> createState() =>
      _CreatePublicationScreenState();
}

class _CreatePublicationScreenState extends State<CreatePublicationScreen> {
  final TextEditingController _contenidoController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final PublicacionRepository _repository = PublicacionRepository();

  XFile? _imagenSeleccionada;
  bool _usarUrlExterna = false;
  bool _isLoading = false;

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

  // Métodos de formato rápido de texto
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
        offset: selection.end + (wrapper.length * 2) + prefix.length,
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
    }
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
        // Confirmación visual de éxito limpia
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Publicación creada exitosamente!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
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
        elevation: 0,
        actions: [
          // Botón de enviar más pequeño, con icono y feedback claro
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: IconButton.filled(
              onPressed: _isLoading ? null : _publicar,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
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
              tooltip: 'Publicar',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de herramientas simple para formato de texto
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
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
                    onPressed: () => _aplicarFormato('', prefix: '# '),
                    tooltip: 'Título / Encabezado',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Área de texto principal
            TextField(
              controller: _contenidoController,
              maxLines: 7,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: '¿Qué pasa en la UTB? Usa formato simple...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
            ),
            const SizedBox(height: 16),

            // Selector de modo de imagen (Dispositivo vs Link URL)
            Row(
              children: [
                Text(
                  'Imagen o Afiche',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch.adaptive(
                  value: _usarUrlExterna,
                  onChanged: (val) {
                    setState(() {
                      _usarUrlExterna = val;
                      if (val) {
                        _imagenSeleccionada = null;
                      } else {
                        _urlController.clear();
                      }
                    });
                  },
                ),
                Text(
                  _usarUrlExterna ? 'Usar Link URL' : 'Archivo local',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Vista condicional según si usa Link o Archivo Local
            if (_usarUrlExterna) ...[
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: 'https://ejemplo.com/imagen.jpg',
                  prefixIcon: const Icon(Icons.link_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ] else ...[
              if (_imagenSeleccionada != null) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
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
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () =>
                              setState(() => _imagenSeleccionada = null),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _seleccionarImagen,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Elegir imagen de la galería'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
