import 'package:flutter/material.dart';
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
  final ClubRepository _clubRepository = ClubRepository();
  late ClubModel _club;
  List<PublicacionModel> _publicaciones = [];
  bool _cargandoPublicaciones = true;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          appBar: AppBar(
            title: const Text(
              'Información del club',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              if (puedeGestionar)
                IconButton(
                  tooltip: 'Editar información e inscripciones',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _abrirModalEditarClub,
                ),
              IconButton(
                tooltip: 'Actualizar publicaciones',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _recargarTodo,
              ),
            ],
          ),
          floatingActionButton: puedeGestionar
              ? FloatingActionButton.extended(
                  onPressed: _abrirCrearPublicacion,
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('Nuevo aviso'),
                )
              : null,
          body: RefreshIndicator(
            onRefresh: _recargarTodo,
            color: colorScheme.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                  _club.iconoCategoria,
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
                                        color: colorScheme.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _club.categoria,
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _club.nombre,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
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
                            (_club.descripcionCompleta != null &&
                                    _club.descripcionCompleta!.isNotEmpty)
                                ? _club.descripcionCompleta!
                                : _club.descripcion,
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _club.inscripcionesAbiertas
                                    ? Icons.how_to_reg_rounded
                                    : Icons.lock_clock_outlined,
                                color: _club.inscripcionesAbiertas
                                    ? Colors.green
                                    : colorScheme.onSurface.withOpacity(0.55),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _club.inscripcionesAbiertas
                                      ? 'Convocatoria e inscripciones abiertas'
                                      : 'Inscripciones cerradas',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_club.avisoInscripcion != null &&
                              _club.avisoInscripcion!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _club.avisoInscripcion!,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                          if (_club.inscripcionesAbiertas &&
                              tieneUrlValida) ...[
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: () => _abrirFormularioInscripcion(
                                _club.msFormsUrl!,
                              ),
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: const Text(
                                'Inscribirme en Microsoft Forms',
                              ),
                            ),
                          ] else if (!_club.inscripcionesAbiertas &&
                              (_club.avisoInscripcion == null ||
                                  _club.avisoInscripcion!.isEmpty)) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Este club no tiene un formulario activo en este momento.',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                            _club.lider,
                          ),
                          Divider(
                            height: 1,
                            color: colorScheme.outlineVariant.withOpacity(0.3),
                          ),
                          _buildInfoRow(
                            colorScheme,
                            Icons.schedule_outlined,
                            'Horario habitual',
                            _club.horario,
                          ),
                          Divider(
                            height: 1,
                            color: colorScheme.outlineVariant.withOpacity(0.3),
                          ),
                          _buildInfoRow(
                            colorScheme,
                            Icons.location_on_outlined,
                            'Lugar de encuentro',
                            _club.lugar,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
      },
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
