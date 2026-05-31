class ApiConstants {
  // ── Configuración base de la API ──────────────────────
  // Cambia esta IP por la de tu máquina en la red local.
  // Para encontrarla: ejecuta 'ipconfig' en Windows o 'ifconfig' en Mac/Linux.
  static const String _host = '10.10.34.29';
  static const int _port = 8000;
  static const String baseUrl = 'http://$_host:$_port';

  // ── Endpoints ─────────────────────────────────────────
  static const String analyzeDiagnostic = '$baseUrl/api/v1/diagnostics/analyze';
  static const String knowledgeRisks = '$baseUrl/api/v1/knowledge-graph/risks';
  static const String knowledgeCrops = '$baseUrl/api/v1/knowledge-graph/crops';
  static const String knowledgePests = '$baseUrl/api/v1/knowledge-graph/pests';
  static const String health = '$baseUrl/health';
}
