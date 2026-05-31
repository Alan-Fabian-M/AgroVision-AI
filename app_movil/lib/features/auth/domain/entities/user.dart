class User {
  final String id;
  final String email;
  final String nombre;
  final String role;
  final DateTime fechaCreacion;

  User({
    required this.id,
    required this.email,
    required this.nombre,
    required this.role,
    required this.fechaCreacion,
  });

  // copyWith method is useful for immutable state updates
  User copyWith({
    String? id,
    String? email,
    String? nombre,
    String? role,
    DateTime? fechaCreacion,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      role: role ?? this.role,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
