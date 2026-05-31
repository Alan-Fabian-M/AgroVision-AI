import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _totalDiagnosticos = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final diagnosticos = await ApiService.fetchRecentDiagnostics(limit: 50);
    if (mounted) {
      setState(() {
        _totalDiagnosticos = diagnosticos.length;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildStats(),
                  _buildInfo(),
                  _buildActions(context),
                  const SizedBox(height: 32),
                ],
              ),
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
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              Text('Mi Perfil',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.surfaceTint],
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 16),
          Text('Agricultor',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text('Santa Cruz de la Sierra, Bolivia',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.verified, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text('Agricultor Verificado',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          _StatItem(
            value: _loading ? '--' : '$_totalDiagnosticos',
            label: 'Diagnósticos',
            icon: Icons.biotech_outlined,
            color: AppColors.primary,
          ),
          _divider(),
          const _StatItem(value: '4', label: 'Cultivos', icon: Icons.grass_outlined, color: AppColors.secondary),
          _divider(),
          const _StatItem(value: '2', label: 'Alertas', icon: Icons.warning_amber_outlined, color: AppColors.error),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 40, color: AppColors.outlineVariant);

  Widget _buildInfo() {
    final items = [
      _InfoItem(icon: Icons.agriculture_outlined, label: 'Tipo de cultivo', value: 'Soya, Maíz, Sorgo'),
      _InfoItem(icon: Icons.area_chart_outlined, label: 'Superficie', value: '15 hectáreas'),
      _InfoItem(icon: Icons.water_drop_outlined, label: 'Sistema de riego', value: 'Aspersión'),
      _InfoItem(icon: Icons.calendar_today_outlined, label: 'Miembro desde', value: 'Mayo 2026'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceContainerLow,
                  ),
                  child: Icon(e.value.icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.value.label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(e.value.value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                ])),
              ]),
            ),
            if (!isLast) Divider(height: 1, color: AppColors.outlineVariant),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        _ActionBtn(
          icon: Icons.chat_bubble_outline,
          label: 'Hablar con Asesor IA',
          color: AppColors.primary,
          onTap: () => Navigator.pushNamed(context, '/advisor'),
        ),
        const SizedBox(height: 10),
        _ActionBtn(
          icon: Icons.history_outlined,
          label: 'Ver historial de diagnósticos',
          color: AppColors.secondary,
          onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
        ),
      ]),
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
          _NavBtn(icon: Icons.home_outlined,        label: 'Home',    active: false, onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false)),
          _NavBtn(icon: Icons.photo_camera_outlined, label: 'Capture', active: false, onTap: () => Navigator.pushNamed(context, '/capture')),
          _NavBtn(icon: Icons.map_outlined,          label: 'Field',   active: false, onTap: () => Navigator.pushNamed(context, '/field')),
          _NavBtn(icon: Icons.person,                label: 'Perfil',  active: true,  onTap: () {}),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value, label; final IconData icon; final Color color;
  const _StatItem({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 6),
      Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant)),
    ]),
  );
}

class _InfoItem {
  final IconData icon; final String label, value;
  const _InfoItem({required this.icon, required this.label, required this.value});
}

class _ActionBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 50,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}

class _NavBtn extends StatelessWidget {
  final IconData icon; final String label; final bool active; final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: active
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(999)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: AppColors.onPrimaryContainer, size: 22),
              const SizedBox(height: 2),
              Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.onPrimaryContainer)),
            ]))
        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
          ]),
  );
}
