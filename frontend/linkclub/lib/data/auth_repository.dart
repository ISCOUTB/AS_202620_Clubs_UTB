import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linkclub/core/network/api_client.dart';

class AuthRepository {
  final Dio _dio = ApiClient.dio;
  final _storage = const FlutterSecureStorage();

  Future<void> login(String correo, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': correo, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    if (response.data != null && response.data['access_token'] != null) {
      await _storage.write(
        key: 'jwt_token',
        value: response.data['access_token'],
      );
    }
  }

  Future<void> signup(
    String nombre,
    String matricula,
    String correo,
    String password, {
    bool solicitarAdmin = false,
    String? clubId,
    String? justificacionAdmin,
  }) async {
    await _dio.post(
      '/auth/registro',
      data: {
        'matricula': matricula,
        'nombre': nombre,
        'correo': correo,
        'password': password,
        if (solicitarAdmin) ...{
          'solicitar_admin': true,
          if (clubId != null) 'club_id': clubId,
          if (justificacionAdmin != null)
            'justificacion_admin': justificacionAdmin.trim(),
        },
      },
    );
  }

  Future<Map<String, dynamic>> obtenerMiPerfil() async {
    final response = await _dio.get('/usuarios/me');
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> actualizarMiPerfil({
    String? nombre,
    String? descripcion,
    String? fotoPerfilUrl,
  }) async {
    final response = await _dio.patch(
      '/usuarios/me',
      data: {
        if (nombre != null) 'nombre': nombre,
        if (descripcion != null) 'descripcion': descripcion,
        if (fotoPerfilUrl != null) 'foto_perfil_url': fotoPerfilUrl,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> cambiarPassword(
    String passwordActual,
    String passwordNueva,
  ) async {
    await _dio.post(
      '/usuarios/me/password',
      data: {
        'password_actual': passwordActual,
        'password_nueva': passwordNueva,
      },
    );
  }

  Future<void> eliminarMiCuenta() async {
    await _dio.delete('/usuarios/me');
    await logout();
  }

  Future<List<Map<String, dynamic>>> listarSolicitudesAdmin() async {
    final response = await _dio.get('/admin/solicitudes');
    final List data = response.data is List ? response.data : [];
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> aprobarSolicitud(String solicitudId) async {
    await _dio.post('/admin/solicitudes/$solicitudId/aprobar');
  }

  Future<void> rechazarSolicitud(String solicitudId) async {
    await _dio.post('/admin/solicitudes/$solicitudId/rechazar');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }
}
