import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password);
  Future<UserModel> register(String email, String nombre, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'username': email,
          'password': password,
        },
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        ),
      );
      
      // El backend retorna: {"access_token": "...", "token_type": "bearer"}
      return {
        'token': response.data['access_token'],
        // Decode del token o llamada a endpoint /me para obtener datos del usuario
        // Por ahora, devolveremos datos mínimos ya que nuestro backend actual no tiene un /me
        // Simularemos un user temporal a partir del email o requeriremos implementar un /me
        'email': email,
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Credenciales incorrectas');
      }
      throw Exception('Error al iniciar sesión: ${e.message}');
    }
  }

  @override
  Future<UserModel> register(String email, String nombre, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'email': email,
          'nombre': nombre,
          'password': password,
        },
      );
      
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception(e.response?.data['detail'] ?? 'El usuario ya existe');
      }
      throw Exception('Error en el registro: ${e.message}');
    }
  }
}
