import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linkclub/core/network/api_client.dart';

class AuthRepository {
  final Dio _dio = ApiClient.dio;
  final _storage = const FlutterSecureStorage();

  Future<void> login(String correo, String password) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'correo': correo, 'password': password},
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
    String password,
  ) async {
    await _dio.post(
      '/auth/registro',
      data: {
        'matricula': matricula,
        'nombre': nombre,
        'correo': correo,
        'password': password,
      },
    );
  }
}
