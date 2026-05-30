import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildTopBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildDiagnosticButton(context),
                    const SizedBox(height: 32),
                    _buildRecentDiagnostics(),
                  ]),
                ),
              ),
            ],
          ),
          _buildFAB(context),
          _buildBottomNav(context),
        ],
      ),
    );
  }

  SliverAppBar _buildTopBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 64,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.outlineVariant),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceContainerHigh,
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: const Icon(Icons.person, color: AppColors.onSurfaceVariant, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, Pedro',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 13, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Text(
                        'Santa Cruz - El Torno',
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
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, size: 18, color: AppColors.tertiaryContainer),
                const SizedBox(width: 6),
                Text(
                  '24°C',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticButton(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/capture'),
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Organic blob shape
                  ClipPath(
                    clipper: _BlobClipper(),
                    child: Container(
                      width: 240,
                      height: 240,
                      color: AppColors.primary,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.crop_free, color: Colors.white, size: 56),
                      const SizedBox(height: 12),
                      Text(
                        'TOCAR PARA\nDIAGNOSTICAR',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.3,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // AI Engine status chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.15),
                ),
                child: const Icon(Icons.sensors, size: 12, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                'AI-Engine: Ready',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDiagnostics() {
    final diagnostics = [
      _DiagnosticItem(
        title: 'Lote 4B - Maíz',
        subtitle: 'Posible deficiencia de Nitrógeno',
        time: 'Hace 2h',
        tag: 'Revisión req.',
        tagColor: AppColors.secondaryContainer,
        tagTextColor: AppColors.onSecondaryContainer,
      ),
      _DiagnosticItem(
        title: 'Lote 2A - Soja',
        subtitle: 'Crecimiento óptimo',
        time: 'Ayer',
        tag: 'Saludable',
        tagColor: AppColors.primaryContainer,
        tagTextColor: AppColors.onPrimaryContainer,
      ),
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Diagnósticos Recientes',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.onBackground,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Ver todos',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...diagnostics.map((d) => _DiagnosticCard(item: d)),
      ],
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Positioned(
      bottom: 88,
      right: 16,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/capture'),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.photo_camera, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                'NUEVA CAPTURA',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home, label: 'Home', active: true, onTap: () {}),
            _NavItem(icon: Icons.photo_camera_outlined, label: 'Capture', active: false, onTap: () => Navigator.pushNamed(context, '/capture')),
            _NavItem(icon: Icons.map_outlined, label: 'Field', active: false, onTap: () => Navigator.pushNamed(context, '/field')),
            _NavItem(icon: Icons.chat_bubble_outline, label: 'Advisor', active: false, onTap: () {}),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticItem {
  final String title, subtitle, time, tag;
  final Color tagColor, tagTextColor;
  const _DiagnosticItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.tag,
    required this.tagColor,
    required this.tagTextColor,
  });
}

class _DiagnosticCard extends StatelessWidget {
  final _DiagnosticItem item;
  const _DiagnosticCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: const Icon(Icons.grass, color: AppColors.onSurfaceVariant, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.time,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: item.tagColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: item.tagColor),
                ),
                child: Text(
                  item.tag,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: item.tagTextColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.onPrimaryContainer, size: 22),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
    );
  }
}

class _BlobClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.5, 0);
    path.cubicTo(w * 0.85, 0, w, h * 0.25, w, h * 0.5);
    path.cubicTo(w, h * 0.78, w * 0.82, h, w * 0.5, h);
    path.cubicTo(w * 0.18, h, 0, h * 0.75, 0, h * 0.5);
    path.cubicTo(0, h * 0.22, w * 0.18, 0, w * 0.5, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_BlobClipper oldClipper) => false;
}
