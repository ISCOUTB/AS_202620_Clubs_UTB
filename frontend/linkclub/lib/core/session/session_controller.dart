import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linkclub/data/auth_repository.dart';

class UsuarioSesion {
  final String matricula;
  final String nombre;
  final String correo;
  final String rol; // ESTUDIANTE | ADMIN_CLUB | SUPERADMIN
  final bool verificado;
  final String? clubAdministradoId;
  final String? clubAdministradoNombre;
  final String? descripcion;
  final String? fotoPerfilUrl;
  final bool solicitudPendiente;

  const UsuarioSesion({
    required this.matricula,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.verificado,
    this.clubAdministradoId,
    this.clubAdministradoNombre,
    this.descripcion,
    this.fotoPerfilUrl,
    this.solicitudPendiente = false,
  });

  factory UsuarioSesion.fromJson(Map<String, dynamic> json) {
    return UsuarioSesion(
      matricula: (json['matricula'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      correo: (json['correo'] ?? '').toString(),
      rol: (json['rol'] ?? 'ESTUDIANTE').toString(),
      verificado: json['verificado'] == true,
      clubAdministradoId: json['club_administrado_id']?.toString(),
      clubAdministradoNombre: json['club_administrado_nombre']?.toString(),
      descripcion: json['descripcion']?.toString(),
      fotoPerfilUrl: json['foto_perfil_url']?.toString(),
      solicitudPendiente: json['solicitud_pendiente'] == true,
    );
  }
}

class SessionController extends ChangeNotifier {
  static final SessionController instance = SessionController._();
  SessionController._();

  final AuthRepository _authRepo = AuthRepository();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UsuarioSesion? _usuario;
  bool _cargando = false;
  bool _forzarVistaEstudiante = false;

  UsuarioSesion? get usuario => _usuario;
  bool get cargando => _cargando;
  bool get estaAutenticado => _usuario != null;
  bool get forzarVistaEstudiante => _forzarVistaEstudiante;

  bool get esSuperAdminReal => _usuario?.rol == 'SUPERADMIN';
  bool get esAdminClubReal =>
      _usuario?.rol == 'ADMIN_CLUB' &&
      _usuario?.verificado == true &&
      _usuario?.clubAdministradoId != null &&
      _usuario!.clubAdministradoId!.isNotEmpty;

  bool get puedeGestionarAlgunClub =>
      !_forzarVistaEstudiante && (esSuperAdminReal || esAdminClubReal);

  bool puedeGestionarClub(String clubId) {
    if (_forzarVistaEstudiante || _usuario == null) return false;
    if (esSuperAdminReal) return true;
    return esAdminClubReal && _usuario!.clubAdministradoId == clubId;
  }

  void alternarVistaEstudiante(bool valor) {
    _forzarVistaEstudiante = valor;
    notifyListeners();
  }

  Future<void> cargarSesion() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      _usuario = null;
      _forzarVistaEstudiante = false;
      notifyListeners();
      return;
    }

    _cargando = true;
    notifyListeners();
    try {
      final data = await _authRepo.obtenerMiPerfil();
      _usuario = UsuarioSesion.fromJson(data);
    } catch (_) {
      _usuario = null;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cerrarSesion() async {
    await _authRepo.logout();
    _usuario = null;
    _forzarVistaEstudiante = false;
    notifyListeners();
  }
}
