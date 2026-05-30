import 'dart:convert';
import 'package:http/http.dart' as http;

const String kBackendUrl = 'http://10.164.62.209:8000';
const String kWeatherKey = '90d448e63a554b44925a501bbe1884c9';

class ApiService {
  static const _timeout = Duration(seconds: 10);

  // ── Diagnósticos ──────────────────────────────────────────────────────────

  static Future<List<DiagnosticoItem>> fetchRecentDiagnostics({int limit = 5}) async {
    try {
      final res = await http
          .get(Uri.parse('$kBackendUrl/api/v1/diagnostics/?limit=$limit'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => DiagnosticoItem.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ── Clima (OpenWeatherMap) ────────────────────────────────────────────────

  static Future<WeatherData?> fetchWeather({
    double lat = -17.7863,
    double lon = -63.1812,
  }) async {
    try {
      final url = 'https://api.openweathermap.org/data/2.5/weather'
          '?lat=$lat&lon=$lon&appid=$kWeatherKey&units=metric&lang=es';
      final res = await http.get(Uri.parse(url)).timeout(_timeout);
      if (res.statusCode == 200) {
        return WeatherData.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  // ── Health check ─────────────────────────────────────────────────────────

  static Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$kBackendUrl/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

// ── Modelos ──────────────────────────────────────────────────────────────────

class DiagnosticoItem {
  final String id;
  final String diagnosticoIa;
  final int severidadRiesgo;
  final double? climaTemp;
  final String fechaCreacion;
  final String userId;

  const DiagnosticoItem({
    required this.id,
    required this.diagnosticoIa,
    required this.severidadRiesgo,
    required this.climaTemp,
    required this.fechaCreacion,
    required this.userId,
  });

  factory DiagnosticoItem.fromJson(Map<String, dynamic> j) => DiagnosticoItem(
        id: j['id']?.toString() ?? '',
        diagnosticoIa: j['diagnostico_ia'] ?? 'Sin diagnóstico',
        severidadRiesgo: (j['severidad_riesgo'] as num?)?.toInt() ?? 1,
        climaTemp: (j['clima_temp'] as num?)?.toDouble(),
        fechaCreacion: j['fecha_creacion'] ?? '',
        userId: j['user_id'] ?? 'Agricultor',
      );

  String get tiempoRelativo {
    try {
      final fecha = DateTime.parse(fechaCreacion);
      final diff = DateTime.now().difference(fecha);
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
      return 'Hace ${diff.inDays}d';
    } catch (_) {
      return 'Reciente';
    }
  }

  String get tagLabel {
    if (severidadRiesgo >= 4) return 'Urgente';
    if (severidadRiesgo >= 3) return 'Revisión req.';
    return 'Saludable';
  }
}

class WeatherData {
  final double temp;
  final String descripcion;
  final int humedad;
  final String ciudad;

  const WeatherData({
    required this.temp,
    required this.descripcion,
    required this.humedad,
    required this.ciudad,
  });

  factory WeatherData.fromJson(Map<String, dynamic> j) => WeatherData(
        temp: (j['main']['temp'] as num).toDouble(),
        descripcion: (j['weather'] as List).first['description'] ?? '',
        humedad: (j['main']['humidity'] as num).toInt(),
        ciudad: j['name'] ?? 'Santa Cruz',
      );

  String get tempString => '${temp.round()}°C';
}
