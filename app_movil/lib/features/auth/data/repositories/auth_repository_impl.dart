import 'dart:convert';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<User> login(String email, String password) async {
    final response = await remoteDataSource.login(email, password);
    final token = response['token'] as String;
    
    // Guardar token en secure storage
    await localDataSource.saveToken(token);

    // Decodificar JWT para obtener email y role
    final payload = _decodeJwt(token);
    
    // Como el login no nos da todos los datos, creamos una entidad parcial
    // o podríamos requerir un endpoint /me en el backend.
    return User(
      id: payload['id'] ?? '', // El token actual solo tiene sub y role
      email: payload['sub'] ?? email,
      nombre: payload['nombre'] ?? payload['sub']?.split('@')[0] ?? 'Usuario',
      role: payload['role'] ?? 'AGRICULTOR',
      fechaCreacion: DateTime.now(),
    );
  }

  @override
  Future<User> register(String email, String nombre, String password) async {
    final userModel = await remoteDataSource.register(email, nombre, password);
    // Opcionalmente podemos hacer login automático aquí
    return userModel;
  }

  @override
  Future<void> logout() async {
    await localDataSource.deleteToken();
  }

  @override
  Future<User?> checkSession() async {
    final token = await localDataSource.getToken();
    if (token == null) return null;

    try {
      final payload = _decodeJwt(token);
      
      // Verificar expiración
      final exp = payload['exp'];
      if (exp != null) {
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        if (DateTime.now().isAfter(expiresAt)) {
          await logout();
          return null;
        }
      }

      return User(
        id: '', 
        email: payload['sub'] ?? '',
        nombre: payload['nombre'] ?? payload['sub']?.split('@')[0] ?? 'Usuario',
        role: payload['role'] ?? 'AGRICULTOR',
        fechaCreacion: DateTime.now(),
      );
    } catch (e) {
      await logout();
      return null;
    }
  }

  // Utilidad simple para decodificar JWT sin dependencias extra
  Map<String, dynamic> _decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload = parts[1];
    var normalized = base64Url.normalize(payload);
    final resp = utf8.decode(base64Url.decode(normalized));
    return json.decode(resp);
  }
}
