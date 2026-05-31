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

// Simulamos la respuesta que vendrá del backend (FastAPI) usando la ubicación
final weatherProvider = FutureProvider<WeatherData?>((ref) async {
  final locationAsync = ref.watch(locationProvider);
  
  if (!locationAsync.hasValue || locationAsync.value == null) {
    return null;
  }

  try {
    final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10)));
    final url = '${ApiConstants.baseUrl}/weather?lat=${locationAsync.value!.latitude}&lon=${locationAsync.value!.longitude}';
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
    // Si falla, caemos en datos por defecto pero lo hacemos explícito.
  }
  return const WeatherData(
    temperature: 0.0,
    humidity: 0,
    condition: 'Desconocido',
    iconCode: '01d',
  );
});
