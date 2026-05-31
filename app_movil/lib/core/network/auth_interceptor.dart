import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;

  AuthInterceptor(this._secureStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Leer el token almacenado
    final token = await _secureStorage.read(key: 'access_token');
    // Si existe el token y la ruta no es de login/registro, inyectarlo
    if (token != null &&
        !options.path.contains('/auth/login') &&
        !options.path.contains('/auth/register')) {
      options.headers['Authorization'] = 'Bearer $token';
    } 
    return handler.next(options);
  }
}
