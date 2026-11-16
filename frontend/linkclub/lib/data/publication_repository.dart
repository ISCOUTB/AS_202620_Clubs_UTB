import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:linkclub/core/network/api_client.dart';

class ClubOption {
  final String id;
  final String nombre;
  final String categoria;

  ClubOption({required this.id, required this.nombre, required this.categoria});

  factory ClubOption.fromJson(Map<String, dynamic> json) {
    return ClubOption(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? 'Club UTB',
      categoria: json['categoria'] ?? 'General',
    );
  }
}

class PublicacionModel {
  final String id;
  final String clubId;
  final String? clubNombre;
  final String autorNombre;
  final String titulo;
  final String contenido;
  final String? imagenUrl;
  final DateTime creadoEn;

  PublicacionModel({
    required this.id,
    this.clubId = '',
    this.clubNombre,
    required this.autorNombre,
    required this.titulo,
    required this.contenido,
    this.imagenUrl,
    required this.creadoEn,
  });

  factory PublicacionModel.fromJson(Map<String, dynamic> json) {
    final String rawContenido = json['contenido'] ?? '';
    String? imagen = json['imagen_url'];
    String contenidoLimpio = rawContenido;

    final imgRegex = RegExp(r'!\[[^\]]*\]\(([^)]+)\)');
    final match = imgRegex.firstMatch(rawContenido);
    if (match != null) {
      imagen ??= match.group(1);
      contenidoLimpio = rawContenido.replaceFirst(imgRegex, '').trim();
    }

    return PublicacionModel(
      id: json['id']?.toString() ?? '',
      clubId: json['club_id']?.toString() ?? '',
      clubNombre: json['club_nombre']?.toString(),
      autorNombre: json['autor_nombre'] ?? json['autor_id'] ?? 'Estudiante UTB',
      titulo: json['titulo'] ?? 'Aviso',
      contenido: contenidoLimpio,
      imagenUrl: imagen,
      creadoEn: (json['creada_en'] ?? json['creado_en']) != null
          ? DateTime.parse(json['creada_en'] ?? json['creado_en'])
          : DateTime.now(),
    );
  }
}

class PublicacionRepository {
  final Dio _dio = ApiClient.dio;

  Future<List<ClubOption>> obtenerClubes() async {
    final response = await _dio.get('/clubes');
    final List data = response.data is List ? response.data : [];
    return data.map((e) => ClubOption.fromJson(e)).toList();
  }

  Future<List<PublicacionModel>> obtenerFeed() async {
    try {
      final response = await _dio.get('/publicaciones');
      final List data = response.data is List ? response.data : [];
      final todas = data.map((e) => PublicacionModel.fromJson(e)).toList();
      todas.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
      return todas;
    } catch (e) {
      throw Exception('Error al cargar el feed de publicaciones.');
    }
  }

  DioMediaType _detectarMediaType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return DioMediaType('image', 'png');
    if (lower.endsWith('.webp')) return DioMediaType('image', 'webp');
    if (lower.endsWith('.gif')) return DioMediaType('image', 'gif');
    return DioMediaType('image', 'jpeg');
  }

  Future<void> crearPublicacionConArchivo({
    required String clubId,
    required String titulo,
    required String contenido,
    String? imagenUrl,
    dynamic archivoLocal,
  }) async {
    String? urlFinal = imagenUrl;

    if (archivoLocal != null) {
      try {
        final String fileName = kIsWeb
            ? archivoLocal.name
            : archivoLocal.path.split('/').last;
        final mediaType = _detectarMediaType(fileName);
        FormData formData;

        if (kIsWeb) {
          final bytes = await archivoLocal.readAsBytes();
          formData = FormData.fromMap({
            'file': MultipartFile.fromBytes(
              bytes,
              filename: fileName,
              contentType: mediaType,
            ),
          });
        } else {
          formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(
              archivoLocal.path,
              filename: fileName,
              contentType: mediaType,
            ),
          });
        }

        final responseUpload = await _dio.post(
          '/recursos/upload',
          data: formData,
        );

        if (responseUpload.statusCode == 200 ||
            responseUpload.statusCode == 201) {
          final String rutaRelativa = responseUpload.data['url'] ?? '';
          if (rutaRelativa.startsWith('http')) {
            urlFinal = rutaRelativa;
          } else if (rutaRelativa.isNotEmpty) {
            urlFinal = '${_dio.options.baseUrl}$rutaRelativa';
          }
        }
      } on DioException catch (e) {
        final detalle = e.response?.data is Map
            ? (e.response?.data['detail'] ?? e.message)
            : e.message;
        throw Exception('Error al subir imagen: $detalle');
      }
    }

    final String cuerpoFinal = (urlFinal != null && urlFinal.isNotEmpty)
        ? '$contenido\n\n![Afiche]($urlFinal)'
        : contenido;

    try {
      await _dio.post(
        '/clubes/$clubId/publicaciones',
        data: {
          'titulo': titulo,
          'contenido': cuerpoFinal,
          'tipo': 'aviso',
          if (urlFinal != null && urlFinal.isNotEmpty) 'imagen_url': urlFinal,
        },
      );
    } on DioException catch (e) {
      final detalle = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.message)
          : e.message;
      throw Exception(detalle.toString());
    }
  }
}
