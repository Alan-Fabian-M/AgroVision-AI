import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../core/providers/location_provider.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  final _tabs = ['Planta', 'Insecto', 'Suelo'];
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;

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
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium, // Bajamos a medium para evitar el error de buffer maxImages
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _cameraController!.initialize();
        await _cameraController!.setFlashMode(FlashMode.off); // Apagar flash por defecto para evitar crash de buffer
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 80);
    if (files.isNotEmpty && mounted) {
      _navigateToAnalysis(files.map((e) => e.path).toList());
    }
  }

  Future<void> _takePhoto() async {
    if (_isCapturing) return; // Prevenir múltiples toques
    setState(() => _isCapturing = true);

    if (!_isCameraInitialized || _cameraController == null) {
      // Fallback
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (file != null && mounted) {
        _navigateToAnalysis([file.path]);
      }
      if (mounted) setState(() => _isCapturing = false);
      return;
    }

    try {
      final xFile = await _cameraController!.takePicture();
      if (mounted) {
        _navigateToAnalysis([xFile.path]);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _navigateToAnalysis(List<String> imagePaths) {
    Navigator.pushNamed(
      context,
      '/preview',
      arguments: {
        'imagePaths': imagePaths,
        'tipo': _tabs[_selectedTab],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo simulando cámara
          _buildCameraBackground(),
          // Overlay oscuro
          Container(color: Colors.black.withValues(alpha: 0.35)),
          // Header
          _buildHeader(),
          // Viewfinder central
          _buildViewfinder(),
          // Controles inferiores
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildCameraBackground() {
    if (_isCameraInitialized && _cameraController != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _cameraController!.value.previewSize?.height ?? 1,
            height: _cameraController!.value.previewSize?.width ?? 1,
            child: CameraPreview(_cameraController!),
          ),
        ),
      );
    }
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A2E1A), Color(0xFF2D4A2D), Color(0xFF1A2E1A)],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          right: 16,
          bottom: 16,
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
            // Botón volver
            _glassButton(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            ),
            // GPS + Flash
            Row(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final locationAsyncValue = ref.watch(locationProvider);
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            locationAsyncValue.hasValue && locationAsyncValue.value != null 
                                ? Icons.my_location 
                                : Icons.location_disabled, 
                            size: 16, 
                            color: AppColors.onPrimaryContainer,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            locationAsyncValue.when(
                              data: (position) => position != null 
                                  ? '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}' 
                                  : 'GPS Error',
                              loading: () => 'Buscando...',
                              error: (_, __) => 'GPS Error',
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
                const SizedBox(width: 8),
                _glassButton(
                  onTap: () {},
                  child: const Icon(Icons.flash_off, color: Colors.white, size: 22),
                ),
              ],
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
          // Tip de instrucción
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Acerca más la cámara a la hoja para mayor precisión.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Caja de enfoque con esquinas
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  // Sombra alrededor del frame
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 0,
                          spreadRadius: 9999,
                        ),
                      ],
                    ),
                  ),
                  // Esquinas del viewfinder
                  ..._buildCorners(),
                  // Línea de escaneo animada
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, _) {
                      return Positioned(
                        top: null,
                        left: 0,
                        right: 0,
                        child: FractionalTranslation(
                          translation: Offset(0, _scanAnimation.value * 8 - 0.5),
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppColors.onPrimaryContainer.withValues(alpha: 0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.onPrimaryContainer.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Tabs de tipo
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_tabs.length, (i) {
                final active = i == _selectedTab;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primaryContainer : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _tabs[i],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active ? AppColors.onPrimaryContainer : Colors.white,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const color = AppColors.onPrimaryContainer;
    const size = 36.0;
    const thickness = 4.0;
    const radius = 10.0;

    return [
      // Top-left
      Positioned(
        top: 0, left: 0,
        child: _Corner(size: size, thickness: thickness, radius: radius, color: color,
            top: true, left: true),
      ),
      // Top-right
      Positioned(
        top: 0, right: 0,
        child: _Corner(size: size, thickness: thickness, radius: radius, color: color,
            top: true, left: false),
      ),
      // Bottom-left
      Positioned(
        bottom: 0, left: 0,
        child: _Corner(size: size, thickness: thickness, radius: radius, color: color,
            top: false, left: true),
      ),
      // Bottom-right
      Positioned(
        bottom: 0, right: 0,
        child: _Corner(size: size, thickness: thickness, radius: radius, color: color,
            top: false, left: false),
      ),
    ];
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: AppColors.onSurfaceVariant, size: 24),
              ),
            ),
            // Botón de captura
            GestureDetector(
              onTap: _isCapturing ? null : _takePhoto,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isCapturing ? AppColors.outlineVariant : AppColors.onPrimaryContainer, 
                    width: 4
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isCapturing ? AppColors.surfaceContainerHigh : AppColors.primary,
                    ),
                    child: _isCapturing 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
            // Herramientas
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerLow,
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: const Icon(Icons.tune, color: AppColors.onSurfaceVariant, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassButton({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
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

class _Corner extends StatelessWidget {
  final double size, thickness, radius;
  final Color color;
  final bool top, left;

  const _Corner({
    required this.size,
    required this.thickness,
    required this.radius,
    required this.color,
    required this.top,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CornerPainter(
        color: color,
        thickness: thickness,
        radius: radius,
        top: top,
        left: left,
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness, radius;
  final bool top, left;

  _CornerPainter({
    required this.color,
    required this.thickness,
    required this.radius,
    required this.top,
    required this.left,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    if (top && left) {
      path.moveTo(0, h);
      path.lineTo(0, radius);
      path.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));
      path.lineTo(w, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(w - radius, 0);
      path.arcToPoint(Offset(w, radius), radius: Radius.circular(radius));
      path.lineTo(w, h);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, h - radius);
      path.arcToPoint(Offset(radius, h), radius: Radius.circular(radius));
      path.lineTo(w, h);
    } else {
      path.moveTo(0, h);
      path.lineTo(w - radius, h);
      path.arcToPoint(Offset(w, h - radius), radius: Radius.circular(radius));
      path.lineTo(w, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
