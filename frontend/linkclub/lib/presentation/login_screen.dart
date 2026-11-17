import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:linkclub/core/theme/theme_controller.dart';
import 'package:linkclub/data/auth_repository.dart';
import 'package:linkclub/presentation/signup_screen.dart';
import 'package:linkclub/presentation/clubs_page.dart';
import 'package:linkclub/core/session/session_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authRepo = AuthRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authRepo.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      await SessionController.instance.cargarSesion();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ClubsPage()),
        );
      }
    } on DioException catch (error) {
      String errorMessage = 'Error de autenticación. Verifica tus datos.';
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        errorMessage = 'Correo o contraseña incorrectos.';
      } else if (error.response?.statusCode == 422) {
        errorMessage = 'Datos incompletos o inválidos.';
      } else if (error.response?.statusCode == 404) {
        errorMessage = 'Servidor no encontrado. Verifica tu conexión.';
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    const primaryBlue = Color(0xFF1D4ED8);
    const buttonTextLight = Color(0xFFF1F5F9);

    final inputFillColor = isDarkMode ? const Color(0xFF0F1623) : Colors.white;
    final inputBorderColor = isDarkMode
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    final hintColor = isDarkMode
        ? const Color(0xFF8A99AD)
        : const Color(0xFF94A3B8);
    final subtitleColor = isDarkMode
        ? const Color(0xFF8A99AD)
        : const Color(0xFF64748B);
    final titleColor = isDarkMode
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF080C14)
          : const Color(0xFFF8FAFC),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0E1422),
                    Color(0xFF0A0F1A),
                    Color(0xFF080C14),
                  ],
                  stops: [0.0, 0.5, 1.0],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFEFF6FF),
                    Color(0xFFF8FAFC),
                    Color(0xFFF8FAFC),
                  ],
                  stops: [0.0, 0.35, 1.0],
                ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryBlue.withValues(alpha: isDarkMode ? 0.08 : 0.06),
                        primaryBlue.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28.0,
                      vertical: 16.0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32.0,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: Material(
                                color: isDarkMode
                                    ? const Color(0xFF131B2E)
                                    : Colors.white.withValues(alpha: 0.9),
                                shape: CircleBorder(
                                  side: BorderSide(
                                    color: isDarkMode
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFE2E8F0),
                                    width: 1,
                                  ),
                                ),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => ThemeController.toggle(),
                                  child: SizedBox(
                                    width: 42,
                                    height: 42,
                                    child: Icon(
                                      isDarkMode
                                          ? Icons.wb_sunny_outlined
                                          : Icons.nightlight_round,
                                      size: 20,
                                      color: isDarkMode
                                          ? const Color(0xFFEAB308)
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 24.0,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Center(
                                      child: Container(
                                        width: 96,
                                        height: 96,
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isDarkMode
                                              ? const Color(0xFF131B2E)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          border: Border.all(
                                            color: isDarkMode
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFFE2E8F0),
                                            width: 1,
                                          ),
                                          boxShadow: isDarkMode
                                              ? null
                                              : [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                          alpha: 0.04,
                                                        ),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Image.asset(
                                            'assets/icon/logo_clean.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),

                                    Text(
                                      'Bienvenido a LinkClub',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        color: titleColor,
                                        letterSpacing: -0.5,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    Text(
                                      'Tu espacio universitario en un solo lugar',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w400,
                                        color: subtitleColor,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 32),

                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: titleColor,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Correo institucional',
                                        hintStyle: TextStyle(
                                          color: hintColor,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 15,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.mail_outline_rounded,
                                          color: subtitleColor,
                                          size: 21,
                                        ),
                                        filled: true,
                                        fillColor: inputFillColor,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 18,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: inputBorderColor,
                                            width: 1,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: inputBorderColor,
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: primaryBlue,
                                            width: 1.6,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                            width: 1.2,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                            width: 1.6,
                                          ),
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
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: titleColor,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Contraseña',
                                        hintStyle: TextStyle(
                                          color: hintColor,
                                          fontWeight: FontWeight.w400,
                                          fontSize: 15,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.lock_outline_rounded,
                                          color: subtitleColor,
                                          size: 21,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: subtitleColor,
                                            size: 21,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                        filled: true,
                                        fillColor: inputFillColor,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 18,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: inputBorderColor,
                                            width: 1,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: inputBorderColor,
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: primaryBlue,
                                            width: 1.6,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                            width: 1.2,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                            width: 1.6,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Por favor ingresa tu contraseña.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    SizedBox(
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _signIn,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryBlue,
                                          disabledBackgroundColor: primaryBlue
                                              .withValues(alpha: 0.55),
                                          foregroundColor: buttonTextLight,
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                          surfaceTintColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: buttonTextLight,
                                                      strokeWidth: 2.3,
                                                    ),
                                              )
                                            : const Text(
                                                'Iniciar Sesión',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    Center(
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const SignUpScreen(),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        child: Text(
                                          '¿No tienes una cuenta? Regístrate aquí',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode
                                                ? const Color(0xFF3B82F6)
                                                : primaryBlue,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 15,
                                    color: subtitleColor.withValues(
                                      alpha: 0.75,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Universidad Tecnológica de Bolívar',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: subtitleColor.withValues(
                                        alpha: 0.75,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
