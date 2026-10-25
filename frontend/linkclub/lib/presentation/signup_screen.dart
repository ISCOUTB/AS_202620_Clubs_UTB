import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:linkclub/core/theme/theme_controller.dart';
import 'package:linkclub/data/auth_repository.dart';
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

  final _formKey = GlobalKey<FormState>();
  final _authRepo = AuthRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authRepo.signup(
        _nameController.text.trim(),
        _matriculaController.text.trim().toUpperCase(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cuenta creada con éxito! Bienvenido a LinkClub.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ClubsPage()),
        );
      }
    } on DioException catch (error) {
      String errorMessage = 'Error al crear la cuenta. Verifica tus datos.';
      if (error.response?.statusCode == 409) {
        errorMessage = 'Este correo ya está registrado.';
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                    'Únete a la plataforma centralizada de clubes de la UTB',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                      if (matricula == null || matricula.isEmpty)
                        return 'Por favor ingresa tu código estudiantil.';
                      if (!RegExp(r'^T\d{7,8}$').hasMatch(matricula))
                        return 'El código debe iniciar con "T" seguido de 7 u 8 números.';
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
                      if (email == null || email.isEmpty)
                        return 'Por favor ingresa tu correo.';
                      if (!email.endsWith('@utb.edu.co'))
                        return 'Debes usar tu correo institucional (@utb.edu.co).';
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
                      if (value == null || value.isEmpty)
                        return 'Por favor ingresa una contraseña.';
                      if (value.length < 8)
                        return 'La contraseña debe tener al menos 8 caracteres.';
                      return null;
                    },
                  ),
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
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
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
