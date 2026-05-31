import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  // Simulamos un delay de red para conectarnos al backend
  await Future.delayed(const Duration(seconds: 1));

  // TODO: En el futuro esto será un ref.read(dioProvider).get('/api/v1/weather?lat=x&lon=y')
  // Por ahora devolvemos datos simulados basados en la ubicación.
  return const WeatherData(
    temperature: 28.5,
    humidity: 75,
    condition: 'Parcialmente Nublado',
    iconCode: '02d',
  );
});
