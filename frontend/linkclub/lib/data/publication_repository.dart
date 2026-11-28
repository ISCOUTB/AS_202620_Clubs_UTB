import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:linkclub/core/network/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final List<String> imagenesUrls;
  final DateTime creadoEn;
  final int totalLikes;
  final bool usuarioDioLike;

  String? get imagenUrl => imagenesUrls.isNotEmpty ? imagenesUrls.first : null;

  PublicacionModel({
    required this.id,
    this.clubId = '',
    this.clubNombre,
    required this.autorNombre,
    required this.titulo,
    required this.contenido,
    List<String>? imagenesUrls,
    String? imagenUrl,
    required this.creadoEn,
    this.totalLikes = 0,
    this.usuarioDioLike = false,
  }) : imagenesUrls =
           imagenesUrls ??
           ((imagenUrl != null && imagenUrl.trim().isNotEmpty)
               ? [imagenUrl.trim()]
               : const <String>[]);

  PublicacionModel copyWith({
    String? id,
    String? clubId,
    String? clubNombre,
    String? autorNombre,
    String? titulo,
    String? contenido,
    List<String>? imagenesUrls,
    String? imagenUrl,
    DateTime? creadoEn,
    int? totalLikes,
    bool? usuarioDioLike,
  }) {
    return PublicacionModel(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      clubNombre: clubNombre ?? this.clubNombre,
      autorNombre: autorNombre ?? this.autorNombre,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      imagenesUrls:
          imagenesUrls ??
          (imagenUrl != null
              ? (imagenUrl.trim().isNotEmpty ? [imagenUrl.trim()] : const [])
              : this.imagenesUrls),
      creadoEn: creadoEn ?? this.creadoEn,
      totalLikes: totalLikes ?? this.totalLikes,
      usuarioDioLike: usuarioDioLike ?? this.usuarioDioLike,
    );
  }

  factory PublicacionModel.fromJson(Map<String, dynamic> json) {
    final String rawContenido = json['contenido'] ?? '';
    final String? imagenPrincipal = json['imagen_url']?.toString().trim();
    final List<String> urls = <String>[];

    if (imagenPrincipal != null && imagenPrincipal.isNotEmpty) {
      urls.add(imagenPrincipal);
    }

    final imgRegex = RegExp(r'!\[[^\]]*\]\(([^)]+)\)');
    for (final match in imgRegex.allMatches(rawContenido)) {
      final url = match.group(1)?.trim();
      if (url != null && url.isNotEmpty && !urls.contains(url)) {
        urls.add(url);
      }
    }

    final String contenidoLimpio = rawContenido.replaceAll(imgRegex, '').trim();

    final int parsedLikes = json['total_likes'] is int
        ? json['total_likes']
        : int.tryParse(json['total_likes']?.toString() ?? '0') ?? 0;
    final bool parsedDioLike =
        json['usuario_dio_like'] == true || json['usuario_dio_like'] == 1;

    return PublicacionModel(
      id: json['id']?.toString() ?? '',
      clubId: json['club_id']?.toString() ?? '',
      clubNombre: json['club_nombre']?.toString(),
      autorNombre: json['autor_nombre'] ?? json['autor_id'] ?? 'Estudiante UTB',
      titulo: json['titulo'] ?? 'Aviso',
      contenido: contenidoLimpio,
      imagenesUrls: urls.take(5).toList(),
      creadoEn: (json['creada_en'] ?? json['creado_en']) != null
          ? DateTime.parse(json['creada_en'] ?? json['creado_en'])
          : DateTime.now(),
      totalLikes: parsedLikes,
      usuarioDioLike: parsedDioLike,
    );
  }
}

class LikeToggleResult {
  final bool usuarioDioLike;
  final int totalLikes;

  const LikeToggleResult({
    required this.usuarioDioLike,
    required this.totalLikes,
  });
}

class PublicacionRepository {
  final Dio _dio = ApiClient.dio;
  static const String _likesPrefsKey = 'publicaciones_liked_ids';

  Future<Set<String>> obtenerLikesGuardadosLocalmente() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_likesPrefsKey) ?? const <String>[]).toSet();
  }

  Future<void> _guardarLikesLocales(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_likesPrefsKey, ids.toList());
  }

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

      final likedIds = {
        for (final pub in todas)
          if (pub.usuarioDioLike) pub.id,
      };
      await _guardarLikesLocales(likedIds);

      return todas;
    } catch (e) {
      throw Exception('Error al cargar el feed de publicaciones.');
    }
  }

  Future<LikeToggleResult> alternarLike(String publicacionId) async {
    final localesPrevios = await obtenerLikesGuardadosLocalmente();
    final localesActualizados = Set<String>.from(localesPrevios);
    if (localesActualizados.contains(publicacionId)) {
      localesActualizados.remove(publicacionId);
    } else {
      localesActualizados.add(publicacionId);
    }
    await _guardarLikesLocales(localesActualizados);

    try {
      final response = await _dio.post('/publicaciones/$publicacionId/like');
      final data = response.data is Map ? response.data : <String, dynamic>{};
      final bool dioLike =
          data['usuario_dio_like'] == true || data['usuario_dio_like'] == 1;
      final int totalLikes = data['total_likes'] is int
          ? data['total_likes']
          : int.tryParse(data['total_likes']?.toString() ?? '0') ?? 0;

      final confirmados = Set<String>.from(localesActualizados);
      if (dioLike) {
        confirmados.add(publicacionId);
      } else {
        confirmados.remove(publicacionId);
      }
      await _guardarLikesLocales(confirmados);

      return LikeToggleResult(usuarioDioLike: dioLike, totalLikes: totalLikes);
    } on DioException catch (e) {
      await _guardarLikesLocales(localesPrevios);
      final detalle = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.message)
          : e.message;
      throw Exception(detalle.toString());
    }
  }

  DioMediaType _detectarMediaType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return DioMediaType('image', 'png');
    if (lower.endsWith('.webp')) return DioMediaType('image', 'webp');
    if (lower.endsWith('.gif')) return DioMediaType('image', 'gif');
    return DioMediaType('image', 'jpeg');
  }

  Future<String?> _subirArchivoUnico(dynamic archivoLocal) async {
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

    final responseUpload = await _dio.post('/recursos/upload', data: formData);

    if (responseUpload.statusCode == 200 || responseUpload.statusCode == 201) {
      final String rutaRelativa = responseUpload.data['url'] ?? '';
      if (rutaRelativa.startsWith('http')) {
        return rutaRelativa;
      } else if (rutaRelativa.isNotEmpty) {
        return '${_dio.options.baseUrl}$rutaRelativa';
      }
    }
    return null;
  }

  Future<void> crearPublicacionConArchivo({
    required String clubId,
    required String titulo,
    required String contenido,
    String? imagenUrl,
    dynamic archivoLocal,
    List<dynamic>? archivosLocales,
    List<String>? imagenesUrls,
  }) async {
    final List<String> urlsFinales = <String>[];

    if (imagenesUrls != null) {
      for (final u in imagenesUrls) {
        final limpia = u.trim();
        if (limpia.isNotEmpty && !urlsFinales.contains(limpia)) {
          urlsFinales.add(limpia);
        }
      }
    }
    if (imagenUrl != null &&
        imagenUrl.trim().isNotEmpty &&
        !urlsFinales.contains(imagenUrl.trim())) {
      urlsFinales.add(imagenUrl.trim());
    }

    final List<dynamic> listaArchivos = <dynamic>[
      if (archivosLocales != null) ...archivosLocales,
      if (archivoLocal != null) archivoLocal,
    ];

    for (final archivo in listaArchivos.take(5 - urlsFinales.length)) {
      try {
        final subida = await _subirArchivoUnico(archivo);
        if (subida != null &&
            subida.isNotEmpty &&
            !urlsFinales.contains(subida)) {
          urlsFinales.add(subida);
        }
      } on DioException catch (e) {
        final detalle = e.response?.data is Map
            ? (e.response?.data['detail'] ?? e.message)
            : e.message;
        throw Exception('Error al subir imagen: $detalle');
      }
    }

    final List<String> limitadas = urlsFinales.take(5).toList();
    final String? imagenPrincipal = limitadas.isNotEmpty
        ? limitadas.first
        : null;

    final String bloquesMarkdown = limitadas
        .asMap()
        .entries
        .map((entry) => '![Afiche ${entry.key + 1}](${entry.value})')
        .join('\n\n');

    final String cuerpoFinal = bloquesMarkdown.isNotEmpty
        ? '$contenido\n\n$bloquesMarkdown'
        : contenido;

    try {
      await _dio.post(
        '/clubes/$clubId/publicaciones',
        data: {
          'titulo': titulo,
          'contenido': cuerpoFinal,
          'tipo': 'aviso',
          if (imagenPrincipal != null) 'imagen_url': imagenPrincipal,
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
