import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_theme.dart';

const _santaCruz = LatLng(-17.7863, -63.1812);

class FieldMapScreen extends StatefulWidget {
  final String? nuevaPlaga;
  final String? nuevaPrioridad;

  const FieldMapScreen({super.key, this.nuevaPlaga, this.nuevaPrioridad});

  @override
  State<FieldMapScreen> createState() => _FieldMapScreenState();
}

class _FieldMapScreenState extends State<FieldMapScreen>
    with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _mapCompleter = Completer();
  late AnimationController _pulseController;
  _AlertData? _selectedAlert;

  final List<_OutbreakPoint> _outbreaks = [
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

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Si viene de un diagnóstico nuevo, mostrarlo como alerta activa
    if (widget.nuevaPlaga != null) {
      final nivel = widget.nuevaPrioridad == 'URGENTE' || widget.nuevaPrioridad == 'ALTA'
          ? _RiskLevel.alto
          : widget.nuevaPrioridad == 'MEDIA'
              ? _RiskLevel.medio
              : _RiskLevel.bajo;
      _selectedAlert = _AlertData(
        titulo: '${widget.nuevaPlaga} — Tu cultivo',
        descripcion: 'Diagnóstico recién registrado en tu ubicación.',
        tiempo: 'Ahora mismo',
        nivel: nivel,
      );
      // Agregar el nuevo brote al mapa
      _outbreaks.insert(0, _OutbreakPoint(
        position: const LatLng(-17.7863, -63.1812),
        label: 'Tu cultivo',
        plaga: widget.nuevaPlaga!,
        nivel: nivel,
      ));
    } else {
      _selectedAlert = _AlertData(
        titulo: 'Roya Asiática a 5km',
        descripcion: 'Detectado en lote vecino. Tome medidas preventivas.',
        tiempo: 'Hace 2h',
        nivel: _RiskLevel.alto,
      );
    }
    _buildMapObjects();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _riskColor(_RiskLevel nivel) {
    switch (nivel) {
      case _RiskLevel.alto:  return AppColors.error;
      case _RiskLevel.medio: return AppColors.secondary;
      case _RiskLevel.bajo:  return AppColors.primary;
    }
  }

  void _buildMapObjects() {
    final markers = <Marker>{};
    final circles = <Circle>{};

    for (final o in _outbreaks) {
      final color = _riskColor(o.nivel);

      // Marcador
      markers.add(Marker(
        markerId: MarkerId(o.label),
        position: o.position,
        infoWindow: InfoWindow(title: o.label, snippet: o.plaga),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          o.nivel == _RiskLevel.alto
              ? BitmapDescriptor.hueRed
              : o.nivel == _RiskLevel.medio
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueGreen,
        ),
        onTap: () => setState(() => _selectedAlert = _AlertData(
              titulo: '${o.plaga} detectada',
              descripcion: 'En ${o.label}. Tome medidas preventivas.',
              tiempo: 'Ahora',
              nivel: o.nivel,
            )),
      ));

      // Círculo de calor
      circles.add(Circle(
        circleId: CircleId('circle_${o.label}'),
        center: o.position,
        radius: o.nivel == _RiskLevel.alto
            ? 800
            : o.nivel == _RiskLevel.medio
                ? 600
                : 400,
        fillColor: color.withValues(alpha: 0.18),
        strokeColor: color.withValues(alpha: 0.5),
        strokeWidth: 2,
      ));
    }

    setState(() {
      _markers = markers;
      _circles = circles;
    });
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
                _buildGoogleMap(),
                _buildLegend(),
                if (widget.nuevaPlaga != null) _buildNewDiagnosisBanner(),
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
                width: 32, height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer,
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: const Icon(Icons.person, color: AppColors.onPrimaryContainer, size: 18),
              ),
              const SizedBox(width: 10),
              Text('AgroGuardian AI',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
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
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
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

  Widget _buildGoogleMap() {
    // Google Maps no soporta Windows — mostrar placeholder
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return Container(
        color: const Color(0xFFE8EFE8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text('Mapa disponible en Android',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
              const SizedBox(height: 8),
              Text('Santa Cruz de la Sierra — ${_outbreaks.length} brotes registrados',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 24),
              ..._outbreaks.map((o) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 12, color: _riskColor(o.nivel)),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${o.label} — ${o.plaga}',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurface))),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      );
    }
    return GoogleMap(
      initialCameraPosition: const CameraPosition(target: _santaCruz, zoom: 12.5),
      onMapCreated: (controller) => _mapCompleter.complete(controller),
      markers: _markers,
      circles: _circles,
      mapType: MapType.normal,
      myLocationButtonEnabled: true,
      myLocationEnabled: true,
      zoomControlsEnabled: false,
      compassEnabled: true,
    );
  }

  Widget _buildLegend() {
    return Positioned(
      top: 12, right: 12,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RIESGO DE BROTE',
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant, letterSpacing: 0.8)),
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

  Widget _buildNewDiagnosisBanner() {
    return Positioned(
      top: 12,
      left: 12,
      right: 80,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)],
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '¡Nuevo brote registrado: ${widget.nuevaPlaga}!',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
      bottom: 12, left: 12, right: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outlineVariant),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Borde izquierdo de color usando Container sólido
                Container(width: 5, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.15)),
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
                                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                                    child: Text(labelText.toUpperCase(),
                                        style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                                  ),
                                  Text(alert.tiempo, style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(alert.titulo,
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                              const SizedBox(height: 2),
                              Text(alert.descripcion,
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 36,
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.outline),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Ver Detalles',
                                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          _NavBtn(icon: Icons.chat_bubble_outline, label: 'Advisor', active: false,
              onTap: () => Navigator.pushNamed(context, '/advisor')),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

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

// ── Modelos ────────────────────────────────────────────────────────────────────

enum _RiskLevel { alto, medio, bajo }

class _OutbreakPoint {
  final LatLng position;
  final String label, plaga;
  final _RiskLevel nivel;
  const _OutbreakPoint({required this.position, required this.label, required this.plaga, required this.nivel});
}

class _AlertData {
  final String titulo, descripcion, tiempo;
  final _RiskLevel nivel;
  const _AlertData({required this.titulo, required this.descripcion, required this.tiempo, required this.nivel});
}
