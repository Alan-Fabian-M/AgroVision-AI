import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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

const _weatherApiKey = '90d448e63a554b44925a501bbe1884c9';

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
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather'
      '?lat=$lat&lon=$lon&appid=$_weatherApiKey&units=metric&lang=es',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return WeatherData(
        temperature: (data['main']['temp'] as num).toDouble(),
        humidity: (data['main']['humidity'] as num).toInt(),
        condition: (data['weather'] as List).first['description'] as String,
        iconCode: (data['weather'] as List).first['icon'] as String,
      );
    }
  } catch (_) {}

  // Fallback con datos simulados si falla la API
  return const WeatherData(
    temperature: 28.5,
    humidity: 75,
    condition: 'Parcialmente nublado',
    iconCode: '02d',
  );
});
