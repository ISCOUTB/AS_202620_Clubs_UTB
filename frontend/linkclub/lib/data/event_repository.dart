import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:linkclub/core/network/api_client.dart';

class EventoModel {
  final String id;
  final String clubId;
  final String clubNombre;
  final String clubCategoria;
  final String? clubLogoUrl;
  final String autorMatricula;
  final String titulo;
  final String descripcion;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final String lugar;
  final DateTime creadoEn;
  final String visibilidad;
  final String? enlaceRegistroMs;
  final String? imagenUrl;
  final int totalAsistentes;
  final bool usuarioAsiste;

  const EventoModel({
    required this.id,
    required this.clubId,
    required this.clubNombre,
    required this.clubCategoria,
    this.clubLogoUrl,
    required this.autorMatricula,
    required this.titulo,
    required this.descripcion,
    required this.fechaInicio,
    this.fechaFin,
    required this.lugar,
    required this.creadoEn,
    required this.visibilidad,
    this.enlaceRegistroMs,
    this.imagenUrl,
    this.totalAsistentes = 0,
    this.usuarioAsiste = false,
  });

  bool get esSoloClub => visibilidad == 'SOLO_CLUB';
  bool get tieneEnlaceExterno =>
      enlaceRegistroMs != null && enlaceRegistroMs!.trim().isNotEmpty;
  bool get yaFinalizo {
    final limite = fechaFin ?? fechaInicio.add(const Duration(hours: 2));
    return DateTime.now().isAfter(limite);
  }

  IconData get iconoCategoria {
    final cat = clubCategoria.toLowerCase();
    if (cat.contains('robót') ||
        cat.contains('tecnolog') ||
        cat.contains('program') ||
        cat.contains('software')) {
      return Icons.memory_rounded;
    }
    if (cat.contains('deport') ||
        cat.contains('fútbol') ||
        cat.contains('futsal') ||
        cat.contains('volei')) {
      return Icons.sports_soccer_rounded;
    }
    if (cat.contains('músic') ||
        cat.contains('arte') ||
        cat.contains('cultur')) {
      return Icons.music_note_rounded;
    }
    if (cat.contains('ajedrez') ||
        cat.contains('lógic') ||
        cat.contains('cienc')) {
      return Icons.extension_rounded;
    }
    return Icons.event_available_rounded;
  }

  EventoModel copyWith({int? totalAsistentes, bool? usuarioAsiste}) {
    return EventoModel(
      id: id,
      clubId: clubId,
      clubNombre: clubNombre,
      clubCategoria: clubCategoria,
      clubLogoUrl: clubLogoUrl,
      autorMatricula: autorMatricula,
      titulo: titulo,
      descripcion: descripcion,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      lugar: lugar,
      creadoEn: creadoEn,
      visibilidad: visibilidad,
      enlaceRegistroMs: enlaceRegistroMs,
      imagenUrl: imagenUrl,
      totalAsistentes: totalAsistentes ?? this.totalAsistentes,
      usuarioAsiste: usuarioAsiste ?? this.usuarioAsiste,
    );
  }

  factory EventoModel.fromJson(Map<String, dynamic> json) {
    return EventoModel(
      id: json['id'].toString(),
      clubId: json['club_id'].toString(),
      clubNombre: (json['club_nombre'] ?? 'Club UTB').toString(),
      clubCategoria: (json['club_categoria'] ?? 'General').toString(),
      clubLogoUrl: json['club_logo_url']?.toString(),
      autorMatricula: (json['autor_matricula'] ?? '').toString(),
      titulo: (json['titulo'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      fechaInicio: DateTime.parse(json['fecha_inicio'].toString()).toLocal(),
      fechaFin: json['fecha_fin'] != null
          ? DateTime.parse(json['fecha_fin'].toString()).toLocal()
          : null,
      lugar: (json['lugar'] ?? 'Campus UTB').toString(),
      creadoEn: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'].toString()).toLocal()
          : DateTime.now(),
      visibilidad: (json['visibilidad'] ?? 'PUBLICO').toString(),
      enlaceRegistroMs: json['enlace_registro_ms']?.toString(),
      imagenUrl: json['imagen_url']?.toString(),
      totalAsistentes: int.tryParse('${json['total_asistentes'] ?? 0}') ?? 0,
      usuarioAsiste: json['usuario_asiste'] == true,
    );
  }
}

class EventRepository {
  String _extraerMensajeError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'] ?? data['error'];
      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString();
      }
    }
    return fallback;
  }

  Future<List<EventoModel>> obtenerEventos() async {
    try {
      final response = await ApiClient.dio.get('/eventos');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((item) => EventoModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _extraerMensajeError(e, 'No se pudieron cargar los eventos.'),
      );
    }
  }

  Future<void> crearEvento({
    String? clubId,
    required String titulo,
    required String descripcion,
    required DateTime fechaInicio,
    DateTime? fechaFin,
    required String lugar,
    String visibilidad = 'PUBLICO',
    String? enlaceRegistroMs,
    String? imagenUrl,
  }) async {
    try {
      await ApiClient.dio.post(
        '/eventos',
        data: {
          if (clubId != null) 'club_id': clubId,
          'titulo': titulo,
          'descripcion': descripcion,
          'fecha_inicio': fechaInicio.toUtc().toIso8601String(),
          if (fechaFin != null) 'fecha_fin': fechaFin.toUtc().toIso8601String(),
          'lugar': lugar,
          'visibilidad': visibilidad,
          if (enlaceRegistroMs != null && enlaceRegistroMs.trim().isNotEmpty)
            'enlace_registro_ms': enlaceRegistroMs.trim(),
          if (imagenUrl != null && imagenUrl.trim().isNotEmpty)
            'imagen_url': imagenUrl.trim(),
        },
      );
    } on DioException catch (e) {
      throw Exception(_extraerMensajeError(e, 'No se pudo crear el evento.'));
    }
  }

  Future<({bool usuarioAsiste, int totalAsistentes})> alternarAsistencia(
    String eventoId,
  ) async {
    try {
      final response = await ApiClient.dio.post(
        '/eventos/$eventoId/asistencia',
      );
      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      return (
        usuarioAsiste: data['usuario_asiste'] == true,
        totalAsistentes: int.tryParse('${data['total_asistentes'] ?? 0}') ?? 0,
      );
    } on DioException catch (e) {
      throw Exception(
        _extraerMensajeError(e, 'No se pudo actualizar la asistencia.'),
      );
    }
  }
}
