import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:linkclub/core/network/api_client.dart';
import 'package:linkclub/data/publication_repository.dart';

class ClubModel {
  final String id;
  final String nombre;
  final String descripcion;
  final String? descripcionCompleta;
  final String categoria;
  final int miembrosCount;
  final String lider;
  final String horario;
  final String lugar;
  final bool inscripcionesAbiertas;
  final String? msFormsUrl;
  final String? avisoInscripcion;
  final Map<String, dynamic> redesJson;

  const ClubModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.descripcionCompleta,
    required this.categoria,
    this.miembrosCount = 0,
    this.lider = 'Coordinación Bienestar UTB',
    this.horario = 'Por definir en convocatoria',
    this.lugar = 'Campus Tecnológico UTB',
    this.inscripcionesAbiertas = false,
    this.msFormsUrl,
    this.avisoInscripcion,
    this.redesJson = const {},
  });

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    final total = json['total_miembros'] ?? json['miembros_count'] ?? 0;
    return ClubModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? 'Club UTB',
      descripcion: json['descripcion'] ?? 'Sin descripción disponible.',
      descripcionCompleta: json['descripcion_completa']?.toString(),
      categoria: json['categoria'] ?? 'General',
      miembrosCount: total is int ? total : int.tryParse(total.toString()) ?? 0,
      lider: (json['lider'] != null && json['lider'].toString().isNotEmpty)
          ? json['lider'].toString()
          : 'Coordinación Bienestar UTB',
      horario:
          (json['horario'] != null && json['horario'].toString().isNotEmpty)
          ? json['horario'].toString()
          : 'Sábados 9:00 AM - 12:00 PM',
      lugar: (json['lugar'] != null && json['lugar'].toString().isNotEmpty)
          ? json['lugar'].toString()
          : 'Campus Tecnológico UTB',
      inscripcionesAbiertas: json['inscripciones_abiertas'] == true,
      msFormsUrl: json['ms_forms_url']?.toString(),
      avisoInscripcion: json['aviso_inscripcion']?.toString(),
      redesJson: json['redes_json'] is Map
          ? Map<String, dynamic>.from(json['redes_json'])
          : const {},
    );
  }

  IconData get iconoCategoria {
    final cat = categoria.toLowerCase();
    if (cat.contains('ciencia') || cat.contains('ingenier')) {
      return Icons.science_outlined;
    }
    if (cat.contains('arte') || cat.contains('cultur')) {
      return Icons.palette_outlined;
    }
    if (cat.contains('espiritual') || cat.contains('comunidad')) {
      return Icons.volunteer_activism_outlined;
    }
    if (cat.contains('idioma') || cat.contains('intercambio')) {
      return Icons.translate_rounded;
    }
    if (cat.contains('juego') || cat.contains('tecnolog')) {
      return Icons.sports_esports_outlined;
    }
    if (cat.contains('liderazgo') || cat.contains('social')) {
      return Icons.lightbulb_outline_rounded;
    }
    return Icons.auto_awesome_outlined; // Originales / emergentes
  }
}

class ClubRepository {
  final Dio _dio = ApiClient.dio;

  Future<List<ClubModel>> obtenerClubes() async {
    try {
      final response = await _dio.get('/clubes');
      final List data = response.data is List ? response.data : [];
      return data.map((e) => ClubModel.fromJson(e)).toList();
    } on DioException catch (e) {
      final detalle = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.message)
          : e.message;
      throw Exception('No se pudieron cargar los clubes: $detalle');
    }
  }

  Future<ClubModel> obtenerClubPorId(String clubId) async {
    final response = await _dio.get('/clubes/$clubId');
    return ClubModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  Future<ClubModel> actualizarClub(
    String clubId,
    Map<String, dynamic> cambios,
  ) async {
    try {
      final response = await _dio.patch('/clubes/$clubId', data: cambios);
      return ClubModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      final detalle = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.message)
          : e.message;
      throw Exception(detalle.toString());
    }
  }

  Future<ClubModel> crearClub(Map<String, dynamic> nuevoClub) async {
    try {
      final response = await _dio.post('/clubes', data: nuevoClub);
      return ClubModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (e) {
      final detalle = e.response?.data is Map
          ? (e.response?.data['detail'] ?? e.message)
          : e.message;
      throw Exception(detalle.toString());
    }
  }

  Future<List<PublicacionModel>> obtenerPublicacionesDelClub(
    String clubId,
  ) async {
    try {
      final response = await _dio.get('/clubes/$clubId/publicaciones');
      final List data = response.data is List ? response.data : [];
      final lista = data.map((e) => PublicacionModel.fromJson(e)).toList();
      lista.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
      return lista;
    } on DioException {
      return [];
    }
  }
}
