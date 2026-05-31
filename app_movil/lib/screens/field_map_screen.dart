import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';

const _santaCruz = LatLng(-17.7863, -63.1812);

class FieldMapScreen extends StatefulWidget {
  final String? nuevaPlaga;
  final String? nuevaPrioridad;
  const FieldMapScreen({super.key, this.nuevaPlaga, this.nuevaPrioridad});

  @override
  State<FieldMapScreen> createState() => _FieldMapScreenState();
}

class _FieldMapScreenState extends State<FieldMapScreen> {
  _AlertData? _selectedAlert;
  late List<_OutbreakPoint> _outbreaks;

  @override
  void initState() {
    super.initState();
    _outbreaks = [
      _OutbreakPoint(position: const LatLng(-17.760, -63.195), label: 'Brote: Farmer A', plaga: 'Roya Asiática',   nivel: _RiskLevel.alto),
      _OutbreakPoint(position: const LatLng(-17.810, -63.155), label: 'Brote: Farmer B', plaga: 'Mildiu',          nivel: _RiskLevel.medio),
      _OutbreakPoint(position: const LatLng(-17.770, -63.220), label: 'Zona Norte',      plaga: 'Pulgón',          nivel: _RiskLevel.bajo),
    ];

    if (widget.nuevaPlaga != null) {
      final nivel = (widget.nuevaPrioridad == 'URGENTE' || widget.nuevaPrioridad == 'ALTA')
          ? _RiskLevel.alto
          : widget.nuevaPrioridad == 'MEDIA' ? _RiskLevel.medio : _RiskLevel.bajo;
      _outbreaks.insert(0, _OutbreakPoint(position: _santaCruz, label: 'Tu cultivo', plaga: widget.nuevaPlaga!, nivel: nivel));
      _selectedAlert = _AlertData(titulo: '${widget.nuevaPlaga} — Tu cultivo', descripcion: 'Diagnóstico registrado en tu ubicación.', tiempo: 'Ahora mismo', nivel: nivel);
    } else {
      _selectedAlert = _AlertData(titulo: 'Roya Asiática a 5km', descripcion: 'Detectado en lote vecino. Tome medidas preventivas.', tiempo: 'Hace 2h', nivel: _RiskLevel.alto);
    }
  }

  Color _riskColor(_RiskLevel n) {
    switch (n) {
      case _RiskLevel.alto:  return AppColors.error;
      case _RiskLevel.medio: return AppColors.secondary;
      case _RiskLevel.bajo:  return AppColors.primary;
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
                if (widget.nuevaPlaga != null) _buildNewBanner(),
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
      decoration: BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.outlineVariant))),
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryContainer), child: const Icon(Icons.person, color: AppColors.onPrimaryContainer, size: 18)),
              const SizedBox(width: 10),
              Text('AgroGuardian AI', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const Spacer(),
              Stack(children: [
                IconButton(icon: const Icon(Icons.notifications_outlined, color: AppColors.primary), onPressed: () {}),
                Positioned(top: 8, right: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.error))),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      options: MapOptions(initialCenter: _santaCruz, initialZoom: 12.5),
      children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.app_movil'),
        CircleLayer(circles: _outbreaks.map((o) => CircleMarker(
          point: o.position,
          radius: o.nivel == _RiskLevel.alto ? 800 : o.nivel == _RiskLevel.medio ? 600 : 400,
          color: _riskColor(o.nivel).withValues(alpha: 0.2),
          borderColor: _riskColor(o.nivel).withValues(alpha: 0.6),
          borderStrokeWidth: 2,
          useRadiusInMeter: true,
        )).toList()),
        MarkerLayer(markers: _outbreaks.map((o) => Marker(
          point: o.position,
          width: 36, height: 36,
          child: GestureDetector(
            onTap: () => setState(() => _selectedAlert = _AlertData(titulo: '${o.plaga} detectada', descripcion: 'En ${o.label}. Tome medidas preventivas.', tiempo: 'Reciente', nivel: o.nivel)),
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: _riskColor(o.nivel), border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: _riskColor(o.nivel).withValues(alpha: 0.4), blurRadius: 8)]),
              child: const Icon(Icons.warning_rounded, color: Colors.white, size: 18),
            ),
          ),
        )).toList()),
      ],
    );
  }

  Widget _buildLegend() {
    return Positioned(
      top: 12, right: 12,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.surface.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.outlineVariant),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('RIESGO DE BROTE', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          _LegendRow(label: 'Alto',  color: AppColors.error),
          const SizedBox(height: 4),
          _LegendRow(label: 'Medio', color: AppColors.secondary),
          const SizedBox(height: 4),
          _LegendRow(label: 'Bajo',  color: AppColors.primary),
        ]),
      ),
    );
  }

  Widget _buildNewBanner() {
    return Positioned(
      top: 12, left: 12, right: 80,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)]),
        child: Row(children: [
          const Icon(Icons.location_on, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text('¡Nuevo brote: ${widget.nuevaPlaga}!', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white), overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  Widget _buildBottomAlert() {
    if (_selectedAlert == null) return const SizedBox();
    final alert = _selectedAlert!;
    final color = _riskColor(alert.nivel);
    final label = alert.nivel == _RiskLevel.alto ? 'ALERTA CRÍTICA' : alert.nivel == _RiskLevel.medio ? 'ALERTA MEDIA' : 'AVISO';

    return Positioned(
      bottom: 12, left: 12, right: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.outlineVariant),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))]),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.15)), child: Icon(Icons.warning_rounded, color: color, size: 22)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                          child: Text(label, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5))),
                        Text(alert.tiempo, style: GoogleFonts.inter(fontSize: 10, color: AppColors.onSurfaceVariant)),
                      ]),
                      const SizedBox(height: 4),
                      Text(alert.titulo, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                      const SizedBox(height: 2),
                      Text(alert.descripcion, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                    ])),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 72,
      decoration: BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.outlineVariant))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _NavBtn(icon: Icons.home_outlined,        label: 'Home',    active: false, onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false)),
        _NavBtn(icon: Icons.photo_camera_outlined, label: 'Capture', active: false, onTap: () => Navigator.pushNamed(context, '/capture')),
        _NavBtn(icon: Icons.map,                  label: 'Field',   active: true,  onTap: () {}),
        _NavBtn(icon: Icons.person_outline, label: 'Perfil', active: false, onTap: () => Navigator.pushNamed(context, '/profile')),
      ]),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _LegendRow extends StatelessWidget {
  final String label; final Color color;
  const _LegendRow({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
    const SizedBox(width: 6),
    Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.onSurface)),
  ]);
}

class _NavBtn extends StatelessWidget {
  final IconData icon; final String label; final bool active; final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: active
        ? Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(999)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: AppColors.onPrimaryContainer, size: 22), const SizedBox(height: 2), Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.onPrimaryContainer))]))
        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: AppColors.onSurfaceVariant, size: 22), const SizedBox(height: 2), Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant))]),
  );
}

// ── Modelos ───────────────────────────────────────────────────────────────────

enum _RiskLevel { alto, medio, bajo }

class _OutbreakPoint {
  final LatLng position; final String label, plaga; final _RiskLevel nivel;
  const _OutbreakPoint({required this.position, required this.label, required this.plaga, required this.nivel});
}

class _AlertData {
  final String titulo, descripcion, tiempo; final _RiskLevel nivel;
  const _AlertData({required this.titulo, required this.descripcion, required this.tiempo, required this.nivel});
}
