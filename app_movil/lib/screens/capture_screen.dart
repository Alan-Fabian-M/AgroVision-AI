import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_launching) return;
    setState(() => _launching = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file != null && mounted) {
        _navigateToPreview(file.path);
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_launching) return;
    setState(() => _launching = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null && mounted) {
        _navigateToPreview(file.path);
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  void _navigateToPreview(String imagePath) {
    Navigator.pushNamed(context, '/preview', arguments: {
      'imagePath': imagePath,
      'tipo': 'Planta',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          Container(color: Colors.black.withValues(alpha: 0.4)),
          _buildHeader(),
          _buildViewfinder(),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1F0D), Color(0xFF1A3A1A), Color(0xFF0D1F0D)],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16, right: 16, bottom: 16,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x99000000), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _glassBtn(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.my_location, size: 16, color: AppColors.onPrimaryContainer),
                const SizedBox(width: 6),
                Text('GPS Activo', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewfinder() {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tip
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.info, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Acerca más la cámara a la hoja para mayor precisión.',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          // Frame con esquinas y línea de scan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(children: [
                ..._buildCorners(),
                AnimatedBuilder(
                  animation: _scanAnimation,
                  builder: (_, __) => Positioned(
                    left: 0, right: 0,
                    top: _scanAnimation.value * 240,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.onPrimaryContainer.withValues(alpha: 0.8),
                        boxShadow: [BoxShadow(color: AppColors.onPrimaryContainer.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const color = AppColors.onPrimaryContainer;
    const s = 36.0; const t = 4.0; const r = 10.0;
    return [
      Positioned(top: 0, left: 0,  child: _Corner(size: s, thickness: t, radius: r, color: color, top: true,  left: true)),
      Positioned(top: 0, right: 0, child: _Corner(size: s, thickness: t, radius: r, color: color, top: true,  left: false)),
      Positioned(bottom: 0, left: 0,  child: _Corner(size: s, thickness: t, radius: r, color: color, top: false, left: true)),
      Positioned(bottom: 0, right: 0, child: _Corner(size: s, thickness: t, radius: r, color: color, top: false, left: false)),
    ];
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 20,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Galería
            GestureDetector(
              onTap: _pickFromGallery,
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: const Icon(Icons.photo_library_outlined, color: AppColors.onSurfaceVariant, size: 24),
              ),
            ),
            // Botón cámara principal
            GestureDetector(
              onTap: _takePhoto,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 88, height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.onPrimaryContainer, width: 4),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _launching ? AppColors.surfaceTint : AppColors.primary,
                    ),
                    child: _launching
                        ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
            // Espacio balanceado
            const SizedBox(width: 56),
          ],
        ),
      ),
    );
  }

  Widget _glassBtn({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ── Corner painter ────────────────────────────────────────────────────────────

class _Corner extends StatelessWidget {
  final double size, thickness, radius; final Color color; final bool top, left;
  const _Corner({required this.size, required this.thickness, required this.radius, required this.color, required this.top, required this.left});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _CornerPainter(color: color, thickness: thickness, radius: radius, top: top, left: left),
  );
}

class _CornerPainter extends CustomPainter {
  final Color color; final double thickness, radius; final bool top, left;
  _CornerPainter({required this.color, required this.thickness, required this.radius, required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = thickness..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path();
    final w = size.width; final h = size.height;
    if (top && left) {
      path.moveTo(0, h); path.lineTo(0, radius); path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius)); path.lineTo(w, 0);
    } else if (top && !left) {
      path.moveTo(0, 0); path.lineTo(w - radius, 0); path.arcToPoint(Offset(w, radius), radius: Radius.circular(radius)); path.lineTo(w, h);
    } else if (!top && left) {
      path.moveTo(0, 0); path.lineTo(0, h - radius); path.arcToPoint(Offset(radius, h), radius: Radius.circular(radius)); path.lineTo(w, h);
    } else {
      path.moveTo(0, h); path.lineTo(w - radius, h); path.arcToPoint(Offset(w, h - radius), radius: Radius.circular(radius)); path.lineTo(w, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
