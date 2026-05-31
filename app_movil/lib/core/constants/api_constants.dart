class ApiConstants {
  // ── Configuración base de la API ──────────────────────
  // Cambia esta IP por la de tu máquina en la red local.
  // Para encontrarla: ejecuta 'ipconfig' en Windows o 'ifconfig' en Mac/Linux.
  static const String _host = '10.10.34.29';
  static const int _port = 8000;
  static const String baseUrl = 'http://$_host:$_port/api/v1';

  // ── Endpoints de Auth ─────────────────────────────────
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';

  // ── Endpoints de Diagnóstico y Grafo ──────────────────
  static const String analyzeDiagnostic = '$baseUrl/diagnostics/analyze';
  static const String knowledgeRisks = '$baseUrl/knowledge-graph/risks';
  static const String knowledgeCrops = '$baseUrl/knowledge-graph/crops';
  static const String knowledgePests = '$baseUrl/knowledge-graph/pests';
}
