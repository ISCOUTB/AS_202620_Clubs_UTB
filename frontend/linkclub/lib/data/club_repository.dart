import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:linkclub/core/network/api_client.dart';
import 'package:linkclub/data/publication_repository.dart';

class ClubModel {
  final String id;
  final String nombre;
  final String descripcion;
  final String categoria;
  final int miembrosCount;
  final String lider;
  final String horario;
  final String lugar;

  const ClubModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    this.miembrosCount = 0,
    this.lider = 'Coordinación Bienestar UTB',
    this.horario = 'Por definir en convocatoria',
    this.lugar = 'Campus Tecnológico UTB',
  });

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    return ClubModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? 'Club UTB',
      descripcion: json['descripcion'] ?? 'Sin descripción disponible.',
      categoria: json['categoria'] ?? 'General',
      miembrosCount: json['miembros_count'] is int
          ? json['miembros_count']
          : int.tryParse(json['miembros_count']?.toString() ?? '0') ?? 0,
      lider: json['lider'] ?? 'Coordinación Bienestar UTB',
      horario: json['horario'] ?? 'Sábados 9:00 AM - 12:00 PM',
      lugar: json['lugar'] ?? 'Campus Tecnológico UTB',
    );
  }

  IconData get iconoCategoria {
    final cat = categoria.toLowerCase();
    if (cat.contains('tec') || cat.contains('prog') || cat.contains('rob')) {
      return Icons.memory_rounded;
    }
    if (cat.contains('art') || cat.contains('cult') || cat.contains('mus')) {
      return Icons.palette_outlined;
    }
    if (cat.contains('dep')) {
      return Icons.sports_soccer_rounded;
    }
    if (cat.contains('cien') || cat.contains('inv')) {
      return Icons.science_outlined;
    }
    return Icons.groups_rounded;
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
