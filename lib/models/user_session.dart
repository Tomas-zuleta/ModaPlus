import 'user_role.dart';

enum UsuarioEstado { activo, inactivo }

class UserSession {
  final String? identificacion;
  final String nombres;
  final String apellidos;
  final String email;
  final String phone;
  final String direccion;
  final UserRole role;
  final UsuarioEstado estado;
  final DateTime fechaCreacion;

  const UserSession({
    required this.nombres,
    required this.email,
    required this.role,
    required this.fechaCreacion,
    this.identificacion,
    this.apellidos = '',
    this.phone = '',
    this.direccion = '',
    this.estado = UsuarioEstado.activo,
  });

  /// Nombre completo para mostrar en la interfaz.
  String get name => apellidos.isEmpty ? nombres : '$nombres $apellidos';

  UserSession copyWith({
    String? nombres,
    String? apellidos,
    String? phone,
    String? direccion,
    String? identificacion,
  }) {
    return UserSession(
      identificacion: identificacion ?? this.identificacion,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      email: email,
      phone: phone ?? this.phone,
      direccion: direccion ?? this.direccion,
      role: role,
      estado: estado,
      fechaCreacion: fechaCreacion,
    );
  }
}