import 'package:dio/dio.dart';
import 'package:linkclub/core/network/api_client.dart';

class PublicacionModel {
  final String id;
  final String autorNombre;
  final String contenido;
  final String? imagenUrl;
  final DateTime creadoEn;

  PublicacionModel({
    required this.id,
    required this.autorNombre,
    required this.contenido,
    this.imagenUrl,
    required this.creadoEn,
  });

  factory PublicacionModel.fromJson(Map<String, dynamic> json) {
    return PublicacionModel(
      id: json['id']?.toString() ?? '',
      autorNombre: json['autor_nombre'] ?? 'Estudiante UTB',
      contenido: json['contenido'] ?? '',
      imagenUrl: json['imagen_url'],
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'])
          : DateTime.now(),
    );
  }
}

class PublicacionRepository {
  final Dio _dio = ApiClient.dio;

  Future<List<PublicacionModel>> obtenerFeed() async {
    try {
      final response = await _dio.get('/publicaciones');
      final List data = response.data;
      return data.map((e) => PublicacionModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error al cargar el feed de publicaciones.');
    }
  }

  Future<void> crearPublicacion(String contenido, {String? imagenUrl}) async {
    await _dio.post(
      '/publicaciones',
      data: {'contenido': contenido, 'imagen_url': imagenUrl},
    );
  }

  Future<void> crearPublicacionConArchivo(
    String contenido, {
    String? imagenUrl,
    dynamic archivoLocal,
  }) async {
    String? urlFinal = imagenUrl;

    if (archivoLocal != null) {
      try {
        String filePath = '';
        String fileName = 'imagen_subida.jpg';

        if (archivoLocal.runtimeType.toString().contains('PlatformFile')) {
          filePath = archivoLocal.path ?? '';
          fileName = archivoLocal.name;
        } else {
          filePath = archivoLocal.path;
          fileName = filePath.split('/').last;
        }

        if (filePath.isNotEmpty) {
          FormData formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(filePath, filename: fileName),
          });

          final responseUpload = await _dio.post(
            '/recursos/upload',
            data: formData,
          );

          if (responseUpload.statusCode == 201) {
            urlFinal = responseUpload.data['url'];
          }
        }
      } catch (e) {
        throw Exception('Error al subir la imagen local: $e');
      }
    }

    await _dio.post(
      '/publicaciones',
      data: {'contenido': contenido, 'imagen_url': urlFinal},
    );
  }
}
