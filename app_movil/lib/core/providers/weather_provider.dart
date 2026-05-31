import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'location_provider.dart';

class WeatherData {
  final double temperature;
  final int humidity;
  final String condition;
  final String iconCode;

  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.condition,
    required this.iconCode,
  });
}

final weatherProvider = FutureProvider<WeatherData?>((ref) async {
  final locationAsync = ref.watch(locationProvider);

  // Coordenadas por defecto: Santa Cruz de la Sierra
  double lat = -17.7863;
  double lon = -63.1812;

  if (locationAsync.hasValue && locationAsync.value != null) {
    lat = locationAsync.value!.latitude;
    lon = locationAsync.value!.longitude;
  }

  try {
    final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));
    final url = '${ApiConstants.baseUrl}/weather?lat=$lat&lon=$lon';
    final response = await dio.get(url);
    if (response.statusCode == 200) {
      final data = response.data;
      return WeatherData(
        temperature: (data['temperature'] as num).toDouble(),
        humidity: data['humidity'] as int,
        condition: data['condition'] as String,
        iconCode: data['icon'] as String,
      );
    }
  } catch (e) {
    // Si falla, caemos en datos por defecto
  }
  return const WeatherData(
    temperature: 0.0,
    humidity: 0,
    condition: 'Desconocido',
    iconCode: '01d',
  );
});
