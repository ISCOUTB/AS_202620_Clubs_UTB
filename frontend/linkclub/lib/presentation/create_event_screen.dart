import 'package:flutter/material.dart';
import 'package:linkclub/core/session/session_controller.dart';
import 'package:linkclub/data/club_repository.dart';
import 'package:linkclub/data/event_repository.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  static const String _fontFamily = 'DMSans';
  static const Color _darkBg = Color(0xFF080C14);
  static const Color _darkCard = Color(0xFF0F1623);
  static const Color _darkElevated = Color(0xFF131B2E);
  static const Color _darkBorder = Color(0xFF1E293B);
  static const Color _darkTextPrimary = Color(0xFFE2E8F0);
  static const Color _darkTextSecondary = Color(0xFF8A99AD);

  static const Color _lightBg = Color(0xFFF8FAFC);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightElevated = Color(0xFFF1F5F9);
  static const Color _lightBorder = Color(0xFFE2E8F0);
  static const Color _lightTextPrimary = Color(0xFF0F172A);
  static const Color _lightTextSecondary = Color(0xFF64748B);

  static const Color _brandBlue = Color(0xFF1D4ED8);
  static const Color _brandBlueSoft = Color(0xFF60A5FA);
  static const Color _buttonTextLight = Color(0xFFF1F5F9);

  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _lugarCtrl = TextEditingController();
  final _enlaceCtrl = TextEditingController();
  final _imagenUrlCtrl = TextEditingController();
  final EventRepository _eventRepo = EventRepository();

  DateTime _fecha = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _horaInicio = const TimeOfDay(hour: 15, minute: 0);
  TimeOfDay? _horaFin = const TimeOfDay(hour: 17, minute: 0);
  String _visibilidad = 'PUBLICO';
  bool _guardando = false;

  List<ClubModel> _clubes = [];
  String? _clubSeleccionadoId;

  @override
  void initState() {
    super.initState();
    final session = SessionController.instance;
    _clubSeleccionadoId = session.usuario?.clubAdministradoId;
    if (session.esSuperAdminReal) {
      _cargarClubesSuperAdmin();
    }
  }

  Future<void> _cargarClubesSuperAdmin() async {
    try {
      final lista = await ClubRepository().obtenerClubes();
      if (mounted) {
        setState(() {
          _clubes = lista;
          _clubSeleccionadoId ??= lista.isNotEmpty ? lista.first.id : null;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _lugarCtrl.dispose();
    _enlaceCtrl.dispose();
    _imagenUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (elegida != null) {
      setState(() => _fecha = elegida);
    }
  }

  Future<void> _seleccionarHora({required bool esInicio}) async {
    final elegida = await showTimePicker(
      context: context,
      initialTime: esInicio ? _horaInicio : (_horaFin ?? _horaInicio),
    );
    if (elegida != null) {
      setState(() {
        if (esInicio) {
          _horaInicio = elegida;
        } else {
          _horaFin = elegida;
        }
      });
    }
  }

  Future<void> _publicarEvento() async {
    if (!_formKey.currentState!.validate()) return;

    final inicio = DateTime(
      _fecha.year,
      _fecha.month,
      _fecha.day,
      _horaInicio.hour,
      _horaInicio.minute,
    );
    final fin = _horaFin != null
        ? DateTime(
            _fecha.year,
            _fecha.month,
            _fecha.day,
            _horaFin!.hour,
            _horaFin!.minute,
          )
        : null;

    if (fin != null && fin.isBefore(inicio)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La hora de finalización no puede ser anterior a la de inicio.',
            style: TextStyle(fontFamily: _fontFamily),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      await _eventRepo.crearEvento(
        clubId: _clubSeleccionadoId,
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        fechaInicio: inicio,
        fechaFin: fin,
        lugar: _lugarCtrl.text.trim(),
        visibilidad: _visibilidad,
        enlaceRegistroMs: _enlaceCtrl.text.trim(),
        imagenUrl: _imagenUrlCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: const TextStyle(fontFamily: _fontFamily),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? _darkBg : _lightBg;
    final cardBg = isDarkMode ? _darkCard : _lightCard;
    final elevatedBg = isDarkMode ? _darkElevated : _lightElevated;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final titleColor = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final secondaryColor = isDarkMode
        ? _darkTextSecondary
        : _lightTextSecondary;
    final accentColor = isDarkMode ? _brandBlueSoft : _brandBlue;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'Programar Evento',
          style: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (SessionController.instance.esSuperAdminReal &&
                _clubes.isNotEmpty) ...[
              _buildLabel('Club organizador', titleColor),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _clubSeleccionadoId,
                    isExpanded: true,
                    dropdownColor: cardBg,
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontSize: 14,
                      color: titleColor,
                    ),
                    items: _clubes
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _clubSeleccionadoId = v),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildLabel('Título del evento', titleColor),
            _buildInput(
              controller: _tituloCtrl,
              hint: 'Ej. Torneo Interno de Robótica VEX 2026',
              isDarkMode: isDarkMode,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa un título' : null,
            ),
            const SizedBox(height: 16),
            _buildLabel('Descripción y detalles', titleColor),
            _buildInput(
              controller: _descripcionCtrl,
              hint: 'Agenda, requisitos, materiales o dinámica...',
              maxLines: 4,
              isDarkMode: isDarkMode,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Ingresa una descripción'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildLabel('Fecha y horario', titleColor),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: _buildPickerTile(
                    icon: Icons.calendar_today_rounded,
                    text: '${_fecha.day}/${_fecha.month}/${_fecha.year}',
                    isDarkMode: isDarkMode,
                    accent: accentColor,
                    onTap: _seleccionarFecha,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _buildPickerTile(
                    icon: Icons.access_time_rounded,
                    text: _horaInicio.format(context),
                    isDarkMode: isDarkMode,
                    accent: accentColor,
                    onTap: () => _seleccionarHora(esInicio: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _buildPickerTile(
                    icon: Icons.timelapse_rounded,
                    text: _horaFin?.format(context) ?? 'Fin',
                    isDarkMode: isDarkMode,
                    accent: accentColor,
                    onTap: () => _seleccionarHora(esInicio: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel('Lugar en campus', titleColor),
            _buildInput(
              controller: _lugarCtrl,
              hint: 'Ej. Lab 3, Módulo A • Campus Ternera',
              isDarkMode: isDarkMode,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Indica el lugar' : null,
            ),
            const SizedBox(height: 16),
            _buildLabel('Visibilidad', titleColor),
            Row(
              children: [
                Expanded(
                  child: _buildVisibilityOption(
                    value: 'PUBLICO',
                    title: 'Público UTB',
                    subtitle: 'Visible para todos',
                    isDarkMode: isDarkMode,
                    accent: accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildVisibilityOption(
                    value: 'SOLO_CLUB',
                    title: 'Solo miembros',
                    subtitle: 'Exclusivo del club',
                    isDarkMode: isDarkMode,
                    accent: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel('Enlace Microsoft Forms (opcional)', titleColor),
            _buildInput(
              controller: _enlaceCtrl,
              hint: 'https://forms.office.com/...',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 16),
            _buildLabel('URL de imagen de portada (opcional)', titleColor),
            _buildInput(
              controller: _imagenUrlCtrl,
              hint: 'https://...',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _guardando ? null : _publicarEvento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandBlue,
                  foregroundColor: _buttonTextLight,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: _buttonTextLight,
                        ),
                      )
                    : const Text(
                        'Publicar evento',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required bool isDarkMode,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final cardBg = isDarkMode ? _darkCard : _lightCard;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final textColor = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final hintColor = isDarkMode ? _darkTextSecondary : _lightTextSecondary;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(fontFamily: _fontFamily, fontSize: 14, color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontFamily: _fontFamily, color: hintColor),
        filled: true,
        fillColor: cardBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _brandBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String text,
    required bool isDarkMode,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final cardBg = isDarkMode ? _darkCard : _lightCard;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final textColor = isDarkMode ? _darkTextPrimary : _lightTextPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityOption({
    required String value,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    required Color accent,
  }) {
    final selected = _visibilidad == value;
    final cardBg = isDarkMode ? _darkCard : _lightCard;
    final borderColor = isDarkMode ? _darkBorder : _lightBorder;
    final titleColor = isDarkMode ? _darkTextPrimary : _lightTextPrimary;
    final secondaryColor = isDarkMode
        ? _darkTextSecondary
        : _lightTextSecondary;

    return GestureDetector(
      onTap: () => setState(() => _visibilidad = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? _brandBlue.withValues(alpha: isDarkMode ? 0.16 : 0.08)
              : cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent.withValues(alpha: 0.45) : borderColor,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: selected ? accent : titleColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 11.5,
                color: secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
