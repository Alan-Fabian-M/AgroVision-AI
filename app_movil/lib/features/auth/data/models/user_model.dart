import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.email,
    required super.nombre,
    required super.role,
    required super.fechaCreacion,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      nombre: json['nombre'] as String,
      role: json['role'] as String,
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'role': role,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      nombre: user.nombre,
      role: user.role,
      fechaCreacion: user.fechaCreacion,
    );
  }
}
