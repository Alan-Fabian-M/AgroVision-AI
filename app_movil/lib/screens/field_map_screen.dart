import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';

// Zona central Santa Cruz de la Sierra, Bolivia
const _santaCruz = LatLng(-17.7863, -63.1812);

class FieldMapScreen extends StatefulWidget {
  const FieldMapScreen({super.key});

  @override
  State<FieldMapScreen> createState() => _FieldMapScreenState();
}

class _FieldMapScreenState extends State<FieldMapScreen>
    with SingleTickerProviderStateMixin {
  final _mapController = MapController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  _AlertData? _selectedAlert;

  // Brotes simulados con coordenadas reales en Santa Cruz
  final _outbreaks = [
    _OutbreakPoint(
      position: const LatLng(-17.760, -63.195),
      label: 'Brote: Farmer A',
      plaga: 'Roya Asiática',
      nivel: _RiskLevel.alto,
    ),
    _OutbreakPoint(
      position: const LatLng(-17.810, -63.155),
      label: 'Brote: Farmer B',
      plaga: 'Mildiu',
      nivel: _RiskLevel.medio,
    ),
    _OutbreakPoint(
      position: const LatLng(-17.770, -63.220),
      label: 'Zona Norte',
      plaga: 'Pulgón',
      nivel: _RiskLevel.bajo,
    ),
  ];

  final _alerts = [
    _AlertData(
      titulo: 'Roya Asiática a 5km',
      descripcion: 'Detectado en lote vecino. Tome medidas preventivas.',
      tiempo: 'Hace 2h',
      nivel: _RiskLevel.alto,
    ),
    _AlertData(
      titulo: 'Mildiu detectado a 8km',
      descripcion: 'Condiciones climáticas favorecen propagación.',
      tiempo: 'Hace 5h',
      nivel: _RiskLevel.medio,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _selectedAlert = _alerts.first;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Color _riskColor(_RiskLevel nivel) {
    switch (nivel) {
      case _RiskLevel.alto:   return AppColors.error;
      case _RiskLevel.medio:  return AppColors.secondary;
      case _RiskLevel.bajo:   return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Stack(
              children: [
                _buildMap(),
                _buildLegend(),
                _buildBottomAlert(),
              ],
            ),
          ),
          _buildBottomNav(),
        ],
      ),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer,
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: const Icon(Icons.person, color: AppColors.onPrimaryContainer, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'AgroGuardian AI',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                    onPressed: () {},
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _santaCruz,
        initialZoom: 12.5,
        minZoom: 10,
        maxZoom: 18,
      ),
      children: [
        // Tiles de OpenStreetMap
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app_movil',
        ),
        // Círculos de calor (heatmap simulado)
        CircleLayer(
          circles: _outbreaks.map((o) {
            final color = _riskColor(o.nivel);
            return CircleMarker(
              point: o.position,
              radius: o.nivel == _RiskLevel.alto ? 800 : o.nivel == _RiskLevel.medio ? 600 : 400,
              useRadiusInMeter: true,
              color: color.withValues(alpha: 0.18),
              borderColor: color.withValues(alpha: 0.5),
              borderStrokeWidth: 1.5,
            );
          }).toList(),
        ),
        // Marcadores de brotes
        MarkerLayer(
          markers: _outbreaks.map((o) {
            return Marker(
              point: o.position,
              width: 120,
              height: 70,
              child: _OutbreakMarker(
                label: o.label,
                nivel: o.nivel,
                riskColor: _riskColor(o.nivel),
                pulseAnim: _pulseAnim,
                onTap: () => setState(() => _selectedAlert = _AlertData(
                  titulo: '${o.plaga} detectada',
                  descripcion: 'En ${o.label}. Tome medidas preventivas.',
                  tiempo: 'Ahora',
                  nivel: o.nivel,
                )),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.93),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RIESGO DE BROTE',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            _LegendRow(label: 'Alto',  gradient: [AppColors.error, const Color(0xFFFFDAD6)]),
            const SizedBox(height: 4),
            _LegendRow(label: 'Medio', gradient: [AppColors.secondaryContainer, const Color(0xFFFFB77D)]),
            const SizedBox(height: 4),
            _LegendRow(label: 'Bajo',  gradient: [AppColors.primaryContainer, AppColors.primary]),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAlert() {
    if (_selectedAlert == null) return const SizedBox();
    final alert = _selectedAlert!;
    final color = _riskColor(alert.nivel);
    final labelText = alert.nivel == _RiskLevel.alto
        ? 'Alerta Crítica'
        : alert.nivel == _RiskLevel.medio
            ? 'Alerta Media'
            : 'Aviso';

    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: color, width: 4),
            top: BorderSide(color: AppColors.outlineVariant),
            right: BorderSide(color: AppColors.outlineVariant),
            bottom: BorderSide(color: AppColors.outlineVariant),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(Icons.warning_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          labelText.toUpperCase(),
                          style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
                        ),
                      ),
                      Text(
                        alert.tiempo,
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.titulo,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.descripcion,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const SizedBox(),
                      label: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Ver Detalles',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                        ],
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.outline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
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
              onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false)),
          _NavBtn(icon: Icons.photo_camera_outlined, label: 'Capture', active: false,
              onTap: () => Navigator.pushNamed(context, '/capture')),
          _NavBtn(icon: Icons.map, label: 'Field', active: true, onTap: () {}),
          _NavBtn(icon: Icons.chat_bubble_outline, label: 'Advisor', active: false, onTap: () {}),
        ],
      ),
    );
  }
}

// ── Widgets internos ────────────────────────────────────────────────────────

class _OutbreakMarker extends StatelessWidget {
  final String label;
  final _RiskLevel nivel;
  final Color riskColor;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;

  const _OutbreakMarker({
    required this.label,
    required this.nivel,
    required this.riskColor,
    required this.pulseAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, __) => Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: riskColor,
                boxShadow: [
                  BoxShadow(
                    color: riskColor.withValues(alpha: pulseAnim.value * 0.5),
                    blurRadius: 12 * pulseAnim.value,
                    spreadRadius: 4 * pulseAnim.value,
                  ),
                ],
              ),
              child: const Icon(Icons.pest_control, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: riskColor, width: 1),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: riskColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String label;
  final List<Color> gradient;
  const _LegendRow({required this.label, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28, height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(colors: gradient),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.onSurface)),
      ],
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
              decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(999)),
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

// ── Modelos de datos ─────────────────────────────────────────────────────────

enum _RiskLevel { alto, medio, bajo }

class _OutbreakPoint {
  final LatLng position;
  final String label;
  final String plaga;
  final _RiskLevel nivel;
  const _OutbreakPoint({required this.position, required this.label, required this.plaga, required this.nivel});
}

class _AlertData {
  final String titulo;
  final String descripcion;
  final String tiempo;
  final _RiskLevel nivel;
  const _AlertData({required this.titulo, required this.descripcion, required this.tiempo, required this.nivel});
}
