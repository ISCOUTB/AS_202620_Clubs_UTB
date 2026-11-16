import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:linkclub/core/session/session_controller.dart';
import 'package:linkclub/core/theme/theme_controller.dart';
import 'package:linkclub/data/auth_repository.dart';
import 'package:linkclub/data/club_repository.dart';
import 'package:linkclub/presentation/clubs_page.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _matriculaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _justificacionController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _authRepo = AuthRepository();
  final _clubRepo = ClubRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _solicitarAdmin = false;
  List<ClubModel> _clubes = [];
  String? _clubSeleccionadoId;
  bool _cargandoClubes = false;

  Future<void> _cargarClubesSiNecesario() async {
    if (_clubes.isNotEmpty || _cargandoClubes) return;
    setState(() => _cargandoClubes = true);
    try {
      final lista = await _clubRepo.obtenerClubes();
      if (mounted) {
        setState(() {
          _clubes = lista;
          if (_clubes.isNotEmpty) {
            _clubSeleccionadoId = _clubes.first.id;
          }
          _cargandoClubes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoClubes = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_solicitarAdmin &&
        (_clubSeleccionadoId == null || _clubSeleccionadoId!.isEmpty)) {
      _showErrorSnackBar('Selecciona el club que deseas administrar.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final correoLimpio = _emailController.text.trim();
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _solicitarAdmin
                  ? 'Cuenta creada. Tu solicitud de Admin está pendiente de verificación.'
                  : '¡Cuenta creada con éxito! Bienvenido a LinkClub.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ClubsPage()),
          (_) => false,
        );
      }
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
    } catch (error) {
      _showErrorSnackBar(
        'Ocurrió un error de red o de sistema. Intenta de nuevo.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final scaffoldBg = theme.scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro', style: TextStyle(fontSize: 18.0)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: colorScheme.onSurface,
            ),
            onPressed: () => ThemeController.toggle(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Crea tu cuenta',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayLarge?.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Únete a la plataforma de los clubes de la UTB',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Estudiante'),
                        icon: Icon(Icons.school_outlined, size: 18),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Admin de Club'),
                        icon: Icon(Icons.verified_user_outlined, size: 18),
                      ),
                    ],
                    selected: {_solicitarAdmin},
                    onSelectionChanged: (selection) {
                      final elegido = selection.first;
                      setState(() => _solicitarAdmin = elegido);
                      if (elegido) {
                        _cargarClubesSiNecesario();
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: scaffoldBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Por favor ingresa tu nombre.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _matriculaController,
                    decoration: InputDecoration(
                      labelText: 'Código estudiantil',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      filled: true,
                      fillColor: scaffoldBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (value) {
                      final matricula = value?.trim().toUpperCase();
                      if (matricula == null || matricula.isEmpty) {
                        return 'Por favor ingresa tu código estudiantil.';
                      }
                      if (!RegExp(r'^T\d{7,8}$').hasMatch(matricula)) {
                        return 'El código debe iniciar con "T" seguido de 7 u 8 números.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo institucional',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: scaffoldBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (value) {
                      final email = value?.trim();
                      if (email == null || email.isEmpty) {
                        return 'Por favor ingresa tu correo.';
                      }
                      if (!email.endsWith('@utb.edu.co')) {
                        return 'Debes usar tu correo institucional (@utb.edu.co).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: true,
                      fillColor: scaffoldBg,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
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
                  if (_solicitarAdmin) ...[
                    const SizedBox(height: 16),
                    if (_cargandoClubes)
                      const LinearProgressIndicator()
                    else
                      DropdownButtonFormField<String>(
                        value: _clubSeleccionadoId,
                        decoration: InputDecoration(
                          labelText: 'Club a administrar',
                          prefixIcon: const Icon(Icons.groups_outlined),
                          filled: true,
                          fillColor: scaffoldBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: _clubes
                            .map(
                              (c) => DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(c.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _clubSeleccionadoId = v),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _justificacionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Cargo / justificación en el club',
                        hintText:
                            'Ej. Presidente / Coordinador de logística del club',
                        prefixIcon: const Icon(Icons.assignment_ind_outlined),
                        filled: true,
                        fillColor: scaffoldBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (value) {
                        if (!_solicitarAdmin) return null;
                        if (value == null || value.trim().length < 5) {
                          return 'Indica tu cargo o motivo para verificar tu rol.';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            )
                          : const Text(
                              'Completar Registro',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
