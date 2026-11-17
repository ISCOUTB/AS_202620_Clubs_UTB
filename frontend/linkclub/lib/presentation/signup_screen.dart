import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:linkclub/core/session/session_controller.dart';
import 'package:linkclub/core/theme/theme_controller.dart';
import 'package:linkclub/data/auth_repository.dart';
import 'package:linkclub/data/club_repository.dart';
import 'package:linkclub/presentation/clubs_page.dart';
import 'package:linkclub/presentation/login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const String _fontFamily = 'DMSans';

  static const Color _darkBg = Color(0xFF080C14);
  static const Color _darkSurface = Color(0xFF0F1623);
  static const Color _darkButtonSurface = Color(0xFF131B2E);
  static const Color _darkBorder = Color(0xFF1E293B);
  static const Color _darkFooterBg = Color(0xFF0B101B);
  static const Color _darkTextPrimary = Color(0xFFE2E8F0);

  static const Color _lightBg = Color(0xFFFFFFFF);
  static const Color _lightSurface = Color(0xFFF8FAFC);
  static const Color _lightButtonSurface = Color(0xFFF1F5F9);
  static const Color _lightBorder = Color(0xFFE2E8F0);

  static const Color _brandBlue = Color(0xFF1D4ED8);
  static const Color _adminTeal = Color(0xFF0F766E);
  static const Color _buttonTextLight = Color(0xFFF1F5F9);

  final _nameController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _justificacionController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _authRepo = AuthRepository();
  final _clubRepo = ClubRepository();

  late final TapGestureRecognizer _loginRecognizer;
  late final TapGestureRecognizer _termsRecognizer;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _solicitarAdmin = false;

  List<ClubModel> _clubes = [];
  String? _clubSeleccionadoId;
  bool _cargandoClubes = false;
  String? _errorClubes;

  @override
  void initState() {
    super.initState();
    _loginRecognizer = TapGestureRecognizer()..onTap = _irALogin;
    _termsRecognizer = TapGestureRecognizer()..onTap = _mostrarPoliticasModal;
  }

  Future<void> _cargarClubesSiNecesario({bool forzar = false}) async {
    if (!forzar && (_clubes.isNotEmpty || _cargandoClubes)) return;
    setState(() {
      _cargandoClubes = true;
      _errorClubes = null;
    });

    try {
      final lista = await _clubRepo.obtenerClubes();
      if (!mounted) return;
      setState(() {
        _clubes = lista;
        if (_clubes.isNotEmpty &&
            (_clubSeleccionadoId == null ||
                !_clubes.any((c) => c.id == _clubSeleccionadoId))) {
          _clubSeleccionadoId = _clubes.first.id;
        }
        _cargandoClubes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargandoClubes = false;
        _errorClubes = 'No se pudieron cargar los clubes disponibles.';
      });
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_solicitarAdmin &&
        (_clubSeleccionadoId == null || _clubSeleccionadoId!.isEmpty)) {
      _showErrorSnackBar('Selecciona el club que deseas administrar.');
      return;
    }

    setState(() => _isLoading = true);

    final correoLimpio = _emailController.text.trim().toLowerCase();
    final passwordLimpio = _passwordController.text.trim();

    try {
      await _authRepo.signup(
        _nameController.text.trim(),
        _matriculaController.text.trim().toUpperCase(),
        correoLimpio,
        passwordLimpio,
        solicitarAdmin: _solicitarAdmin,
        clubId: _solicitarAdmin ? _clubSeleccionadoId : null,
        justificacionAdmin: _solicitarAdmin
            ? _justificacionController.text.trim()
            : null,
      );

      await _authRepo.login(correoLimpio, passwordLimpio);
      await SessionController.instance.cargarSesion();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _solicitarAdmin
                ? 'Cuenta creada. Tu solicitud de Admin está pendiente de verificación.'
                : 'Cuenta creada con éxito. Bienvenido a LinkClub.',
            style: const TextStyle(fontFamily: _fontFamily),
          ),
          backgroundColor: _adminTeal,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ClubsPage()),
        (_) => false,
      );
    } on DioException catch (error) {
      String errorMessage = 'Error al crear la cuenta. Verifica tus datos.';
      if (error.response?.data is Map &&
          error.response?.data['detail'] != null) {
        errorMessage = error.response!.data['detail'].toString();
      } else if (error.response?.statusCode == 409) {
        errorMessage = 'Este correo o matrícula ya están registrados.';
      } else if (error.response?.statusCode == 422) {
        errorMessage = 'Datos inválidos en el formulario.';
      }
      _showErrorSnackBar(errorMessage);
    } catch (_) {
      _showErrorSnackBar(
        'Ocurrió un error de red o de sistema. Intenta de nuevo.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _irALogin() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _mostrarPoliticasModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? _darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? _darkBorder : _lightBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Políticas y Términos de Uso',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? _darkTextPrimary : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'LinkClub UTB utiliza tu nombre completo, código estudiantil y correo institucional (@utb.edu.co) exclusivamente para autenticar tu identidad universitaria, gestionar solicitudes de administración de clubes y difundir avisos académicos y extracurriculares dentro del campus.',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 13.5,
                  height: 1.5,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandBlue,
                    foregroundColor: _buttonTextLight,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: _fontFamily)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required bool isDark,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    final fillColor = isDark ? _darkSurface : _lightSurface;
    final borderColor = isDark ? _darkBorder : _lightBorder;
    final hintColor = isDark
        ? const Color(0xFF8A99AD)
        : const Color(0xFF64748B);

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontFamily: _fontFamily,
        color: hintColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(prefixIcon, size: 20, color: hintColor),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
      errorStyle: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        height: 1.2,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _matriculaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _justificacionController.dispose();
    _loginRecognizer.dispose();
    _termsRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _darkBg : _lightBg;
    final textColor = isDark ? _darkTextPrimary : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTopBar(isDark, textColor),
                            const SizedBox(height: 18),
                            Text(
                              'Crea tu cuenta',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 316,
                                ),
                                child: _buildRoleSelector(isDark),
                              ),
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _buildInputDecoration(
                                isDark: isDark,
                                hintText: 'Nombre completo',
                                prefixIcon: Icons.person_outline_rounded,
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Por favor ingresa tu nombre.'
                                  : null,
                            ),
                            const SizedBox(height: 13),
                            TextFormField(
                              controller: _matriculaController,
                              textCapitalization: TextCapitalization.characters,
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _buildInputDecoration(
                                isDark: isDark,
                                hintText: 'Código estudiantil',
                                prefixIcon: Icons.badge_outlined,
                              ),
                              validator: (value) {
                                final matricula = value?.trim().toUpperCase();
                                if (matricula == null || matricula.isEmpty) {
                                  return 'Por favor ingresa tu código estudiantil.';
                                }
                                if (!RegExp(
                                  r'^T\d{7,8}$',
                                ).hasMatch(matricula)) {
                                  return 'Debe iniciar con "T" seguido de 7 u 8 números.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 13),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _buildInputDecoration(
                                isDark: isDark,
                                hintText: 'Correo institucional',
                                prefixIcon: Icons.mail_outline_rounded,
                              ),
                              validator: (value) {
                                final email = value?.trim().toLowerCase();
                                if (email == null || email.isEmpty) {
                                  return 'Por favor ingresa tu correo.';
                                }
                                if (!email.endsWith('@utb.edu.co')) {
                                  return 'Usa tu correo institucional (@utb.edu.co).';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 13),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(
                                fontFamily: _fontFamily,
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _buildInputDecoration(
                                isDark: isDark,
                                hintText: 'Contraseña',
                                prefixIcon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                    color: isDark
                                        ? const Color(0xFF8A99AD)
                                        : const Color(0xFF64748B),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa una contraseña.';
                                }
                                if (value.length < 8) {
                                  return 'La contraseña debe tener al menos 8 caracteres.';
                                }
                                return null;
                              },
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeInOut,
                              child: _solicitarAdmin
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const SizedBox(height: 13),
                                        _buildClubSelector(isDark, textColor),
                                        const SizedBox(height: 13),
                                        TextFormField(
                                          controller: _justificacionController,
                                          minLines: 1,
                                          maxLines: 3,
                                          style: TextStyle(
                                            fontFamily: _fontFamily,
                                            color: textColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: _buildInputDecoration(
                                            isDark: isDark,
                                            hintText: 'Cargo en el club',
                                            prefixIcon:
                                                Icons.assignment_ind_outlined,
                                          ),
                                          validator: (value) {
                                            if (!_solicitarAdmin) return null;
                                            if (value == null ||
                                                value.trim().length < 5) {
                                              return 'Indica tu cargo o motivo para verificar tu rol.';
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _brandBlue,
                                  disabledBackgroundColor: _brandBlue
                                      .withValues(alpha: 0.55),
                                  foregroundColor: _buttonTextLight,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  surfaceTintColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: _buttonTextLight,
                                          strokeWidth: 2.2,
                                        ),
                                      )
                                    : const Text(
                                        'Completar Registro',
                                        style: TextStyle(
                                          fontFamily: _fontFamily,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildFooter(isDark),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark, Color textColor) {
    final btnBg = isDark ? _darkButtonSurface : _lightButtonSurface;
    final btnBorder = isDark ? _darkBorder : _lightBorder;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTopIconButton(
          backgroundColor: btnBg,
          borderColor: btnBorder,
          tooltip: 'Regresar',
          onTap: _irALogin,
          child: Icon(
            Icons.arrow_back_rounded,
            size: 20,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        Text(
          'Registro',
          style: TextStyle(
            fontFamily: _fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: -0.2,
          ),
        ),
        _buildTopIconButton(
          backgroundColor: btnBg,
          borderColor: btnBorder,
          tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
          onTap: () => ThemeController.toggle(),
          child: Icon(
            isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_rounded,
            size: 20,
            color: isDark ? const Color(0xFFEAB308) : const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildTopIconButton({
    required Color backgroundColor,
    required Color borderColor,
    required String tooltip,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor, width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(width: 40, height: 40, child: Center(child: child)),
        ),
      ),
    );
  }

  Widget _buildRoleSelector(bool isDark) {
    final containerBg = isDark ? _darkSurface : _lightButtonSurface;
    final containerBorder = isDark ? _darkBorder : _lightBorder;
    final inactiveTextColor = isDark
        ? const Color(0xFF8A99AD)
        : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: containerBorder, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildRoleSegment(
              label: 'Estudiante',
              icon: Icons.school_outlined,
              isSelected: !_solicitarAdmin,
              activeColor: _adminTeal,
              inactiveColor: inactiveTextColor,
              onTap: () {
                if (_solicitarAdmin) {
                  setState(() => _solicitarAdmin = false);
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildRoleSegment(
              label: 'Admin Club',
              icon: Icons.verified_user_outlined,
              isSelected: _solicitarAdmin,
              activeColor: _adminTeal,
              inactiveColor: inactiveTextColor,
              onTap: () {
                if (!_solicitarAdmin) {
                  setState(() => _solicitarAdmin = true);
                  _cargarClubesSiNecesario();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSegment({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_rounded,
                size: 15,
                color: _buttonTextLight,
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              icon,
              size: 16,
              color: isSelected ? _buttonTextLight : inactiveColor,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? _buttonTextLight : inactiveColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubSelector(bool isDark, Color textColor) {
    final secondaryColor = isDark
        ? const Color(0xFF8A99AD)
        : const Color(0xFF64748B);

    if (_cargandoClubes) {
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? _darkSurface : _lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? _darkBorder : _lightBorder),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Cargando clubes disponibles...',
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: secondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorClubes != null || _clubes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? _darkSurface : _lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? _darkBorder : _lightBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: Colors.amber,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorClubes ?? 'No hay clubes registrados aún.',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF334155),
                ),
              ),
            ),
            TextButton(
              onPressed: () => _cargarClubesSiNecesario(forzar: true),
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final clubTextStyle = TextStyle(
      fontFamily: _fontFamily,
      color: textColor,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    return DropdownButtonFormField<String>(
      value: _clubSeleccionadoId,
      isExpanded: true,
      borderRadius: BorderRadius.circular(14),
      dropdownColor: isDark ? _darkSurface : Colors.white,
      iconEnabledColor: secondaryColor,
      style: clubTextStyle,
      decoration: _buildInputDecoration(
        isDark: isDark,
        hintText: 'Club a administrar',
        prefixIcon: Icons.groups_outlined,
      ),
      selectedItemBuilder: (context) {
        return _clubes.map((c) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              c.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: clubTextStyle,
            ),
          );
        }).toList();
      },
      items: _clubes.map((c) {
        return DropdownMenuItem<String>(
          value: c.id,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  c.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: clubTextStyle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                c.categoria,
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (v) => setState(() => _clubSeleccionadoId = v),
      validator: (value) {
        if (!_solicitarAdmin) return null;
        if (value == null || value.isEmpty) {
          return 'Selecciona el club que deseas administrar.';
        }
        return null;
      },
    );
  }

  Widget _buildFooter(bool isDark) {
    final footerBg = isDark ? _darkFooterBg : _lightSurface;
    final topBorder = isDark ? _darkBorder : _lightBorder;
    final secondaryText = isDark
        ? const Color(0xFF8A99AD)
        : const Color(0xFF64748B);
    final mutedText = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);
    final linkColor = isDark ? const Color(0xFF3B82F6) : _brandBlue;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: footerBg,
        border: Border(top: BorderSide(color: topBorder, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontFamily: _fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: secondaryText,
              ),
              children: [
                const TextSpan(text: '¿Ya tienes cuenta? '),
                TextSpan(
                  text: 'Inicia Sesión',
                  style: TextStyle(
                    fontFamily: _fontFamily,
                    color: linkColor,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: _loginRecognizer,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontFamily: _fontFamily,
                  fontSize: 11,
                  height: 1.4,
                  color: mutedText,
                ),
                children: [
                  const TextSpan(text: 'Al registrarte aceptas las '),
                  TextSpan(
                    text: 'políticas y términos de uso',
                    style: const TextStyle(
                      fontFamily: _fontFamily,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: _termsRecognizer,
                  ),
                  const TextSpan(text: ' de LinkClub UTB.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
