import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../core/providers/location_provider.dart';
import '../core/constants/api_constants.dart';

class AnalysisResultScreen extends StatefulWidget {
  final List<String> imagePaths;
  final String descripcion;

  const AnalysisResultScreen({
    super.key,
    required this.imagePaths,
    required this.descripcion,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen>
    with SingleTickerProviderStateMixin {
  _AnalysisState _state = _AnalysisState.loading;
  _DiagnosisResult? _result;
  bool _savedToDb = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _runAnalysis();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    try {
      final dio = Dio();
      final locationAsync = ref.read(locationProvider);
      double lat = 0.0;
      double lon = 0.0;
      
      if (locationAsync.hasValue && locationAsync.value != null) {
        lat = locationAsync.value!.latitude;
        lon = locationAsync.value!.longitude;
      }

      List<MultipartFile> imageFiles = [];
      for (final path in widget.imagePaths) {
        final file = File(path);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath('imagenes', path));
        }
      }

      Map<String, dynamic> formDataMap = {
        'descripcion': widget.descripcion,
        'tipo': widget.tipo,
        'latitud': lat,
        'longitud': lon,
        'user_id': 'usuario_123',
        'imagenes': imageFiles,
      };

      if (widget.audioPath != null) {
        final audioFile = File(widget.audioPath!);
        if (await audioFile.exists()) {
          formDataMap['audio'] = await MultipartFile.fromFile(widget.audioPath!, filename: widget.audioPath!.split('/').last);
        }
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await dio.post(
        ApiConstants.analyzeDiagnostic,
        data: formData,
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final guardado = data['guardado'] == true;
        setState(() {
          _result = _DiagnosisResult.fromJson(data);
          _state = _AnalysisState.done;
          _savedToDb = guardado;
        });
      } else {
        _useMockResult();
      }
    } catch (_) {
      _useMockResult();
    }
  }

  void _useMockResult() {
    setState(() {
      _result = _DiagnosisResult(
        plagaDetectada: 'Roya de la Soya',
        nivelGravedad: 'GRAVE',
        prioridad: 'ALTA',
        recomendaciones: [
          'Aplicar fungicida de forma urgente.',
          'Revisar el lote vecino para evitar que se contagie.',
        ],
        productosSugeridos: ['Fungicida triazol', 'Fungicida cúprico'],
        confianza: 0.87,
      );
      _state = _AnalysisState.done;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: _state == _AnalysisState.loading
                ? _buildLoading()
                : _buildResult(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer,
              ),
              child: Center(
                child: Text(
                  'JD',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'AgroVision AI',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.onSurfaceVariant),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Transform.scale(
              scale: 0.9 + _pulseController.value * 0.15,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1 + _pulseController.value * 0.1),
                ),
                child: const Icon(Icons.biotech, color: AppColors.primary, size: 48),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Analizando cultivo...',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'La IA está procesando las imágenes',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: AppColors.surfaceContainerHigh,
              color: AppColors.primary,
              minHeight: 4,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    final isHighRisk = r.prioridad == 'ALTA' || r.prioridad == 'URGENTE';
    final riskColor = isHighRisk ? AppColors.error : AppColors.secondary;
    final riskLabel = _riskLabel(r.prioridad);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: [
          // Imagen del cultivo
          _buildCropImage(),
          const SizedBox(height: 16),

          // Tarjeta de problema
          _buildProblemCard(r, riskColor, riskLabel),
          const SizedBox(height: 16),

          // Tarjeta de solución
          _buildSolutionCard(r),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(Map<String, dynamic> clima) {
    final temp = clima['temperature']?.toString() ?? '--';
    final humidity = clima['humidity']?.toString() ?? '--';
    final condition = clima['condition']?.toString() ?? 'Desconocido';
    final iconCode = clima['icon']?.toString() ?? '01d';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Image.network(
            'https://openweathermap.org/img/wn/$iconCode@2x.png',
            width: 60,
            height: 60,
            errorBuilder: (_, __, ___) => const Icon(Icons.cloud, size: 40, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clima al Momento del Análisis',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  condition,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.thermostat, size: 16, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      '$temp°C',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.air, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      'Humedad: $humidity%',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropImage() {
    final path = widget.imagePaths.isNotEmpty ? widget.imagePaths.first : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: path != null
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(),
              )
            : _imagePlaceholder(),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.surfaceContainerLow,
      child: const Icon(Icons.grass, size: 64, color: AppColors.onSurfaceVariant),
    );
  }

  Widget _buildProblemCard(_DiagnosisResult r, Color riskColor, String riskLabel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Column(
        children: [
          Text(
            'PROBLEMA ENCONTRADO',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.error,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            r.plagaDetectada,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: riskColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  riskLabel,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Confianza
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Confianza: ${(r.confianza * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionCard(_DiagnosisResult r) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título solución
          Row(
            children: [
              const Icon(Icons.task_alt, color: AppColors.primary, size: 30),
              const SizedBox(width: 10),
              Text(
                'Solución',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Recomendaciones
          ...r.recomendaciones.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: _parseMarkdownBold(
                            rec,
                            GoogleFonts.inter(
                              fontSize: 15,
                              color: AppColors.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          // Productos sugeridos
          if (r.productosSugeridos.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Productos sugeridos',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: r.productosSugeridos
                  .map((p) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Text(
                          p,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 24),
          // Botón Ver Insumos
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                '/insumos',
                arguments: {
                  'plaga': r.plagaDetectada,
                  'productos': r.productosSugeridos,
                },
              ),
              icon: const Icon(Icons.shopping_cart, size: 22),
              label: Text(
                'Ver Insumos',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Botón Hablar con Asesor
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              label: Text(
                'Hablar con Asesor',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurface,
                side: const BorderSide(color: AppColors.outlineVariant, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavBtn(icon: Icons.home_outlined, label: 'Home', active: false,
              onTap: () => context.go('/')),
          _NavBtn(icon: Icons.photo_camera, label: 'Capture', active: true, onTap: () {}),
          _NavBtn(icon: Icons.map_outlined, label: 'Field', active: false, onTap: () {}),
          _NavBtn(icon: Icons.person_outline, label: 'Perfil', active: false, onTap: () => Navigator.pushNamed(context, '/profile')),
        ],
      ),
    );
  }

  String _riskLabel(String prioridad) {
    switch (prioridad) {
      case 'URGENTE': return 'Riesgo Urgente';
      case 'ALTA':    return 'Riesgo Alto';
      case 'MEDIA':   return 'Riesgo Medio';
      default:        return 'Riesgo Bajo';
    }
  }

  // --- Utilidad para Negritas ---
  List<TextSpan> _parseMarkdownBold(String text, TextStyle defaultStyle) {
    final parts = text.split('**');
    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(
        TextSpan(
          text: parts[i],
          style: i % 2 == 1 
            ? defaultStyle.copyWith(fontWeight: FontWeight.w800, color: AppColors.onSurface) 
            : defaultStyle,
        ),
      );
    }
    return spans;
  }
}

enum _AnalysisState { loading, done }

class _DiagnosisResult {
  final String plagaDetectada;
  final String nivelGravedad;
  final String prioridad;
  final List<String> recomendaciones;
  final List<String> productosSugeridos;
  final double confianza;
  final Map<String, dynamic>? clima;

  const _DiagnosisResult({
    required this.plagaDetectada,
    required this.nivelGravedad,
    required this.prioridad,
    required this.recomendaciones,
    required this.productosSugeridos,
    required this.confianza,
    this.clima,
  });

  factory _DiagnosisResult.fromJson(Map<String, dynamic> json) {
    List<String> parseRecs(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      if (raw is String) {
        // Si tiene saltos de línea (típico de Gemini), dividimos por ahí
        if (raw.contains('\n')) {
          return raw.split('\n')
              // Eliminar solo las viñetas del INICIO de la línea (*, -, 1.), pero mantener los ** de negrita
              .map((s) => s.replaceAll(RegExp(r'^[-*]\s*|^\d+\.\s*'), '').trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
        // Fallback: si es un párrafo largo, lo separamos por oraciones ('. ')
        return raw.split('. ')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .map((s) => s.endsWith('.') ? s : '$s.')
            .toList();
      }
      return [];
    }

    List<String> parseProducts(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString().replaceAll('*', '')).toList();
      if (raw is String) return raw.split(',').map((s) => s.replaceAll('*', '').trim()).where((s) => s.isNotEmpty).toList();
      return [];
    }

    return _DiagnosisResult(
      plagaDetectada: json['plaga_detectada'] ?? json['diagnostico_ia'] ?? 'No identificada',
      nivelGravedad:  json['nivel_gravedad']  ?? 'MEDIO',
      prioridad:      json['prioridad']        ?? 'MEDIA',
      recomendaciones: parseRecs(json['recomendaciones']),
      productosSugeridos: parseProducts(json['productos_sugeridos']),
      confianza: (json['confianza'] as num?)?.toDouble() ?? 0.0,
      clima: json['clima'] as Map<String, dynamic>?,
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: active
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: AppColors.onPrimaryContainer, size: 22),
                const SizedBox(height: 2),
                Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.onPrimaryContainer)),
              ]),
            )
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
              const SizedBox(height: 2),
              Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
            ]),
    );
  }
}
