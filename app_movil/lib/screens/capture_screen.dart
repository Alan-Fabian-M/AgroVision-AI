import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  List<XFile> _selectedImages = [];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final backCamera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );
        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
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
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final picker = ImagePicker();
      final files = await picker.pickMultiImage(
        imageQuality: 60,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (files.isNotEmpty && mounted) {
        setState(() {
          _selectedImages.addAll(files);
          _currentPage = 0;
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _takePhoto() async {
    if (_isProcessing || !_isCameraInitialized || _cameraController == null) return;
    setState(() => _isProcessing = true);

    try {
      final XFile file = await _cameraController!.takePicture();
      if (mounted) {
        setState(() {
          _selectedImages.add(file);
          _currentPage = 0;
        });
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _navigateToPreview() {
    if (_selectedImages.isEmpty) return;
    context.push(
      '/preview',
      extra: {
        'imagePaths': _selectedImages.map((e) => e.path).toList(),
        'tipo': 'Automático',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedImages.isNotEmpty) {
      return _buildSelectedImagesView();
    }
    return _buildCameraView();
  }

  // ==========================================
  // ESTADO 1: CÁMARA (selectedImages.isEmpty)
  // ==========================================
  Widget _buildCameraView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Live Camera Preview
          _buildBackground(),
          
          // Header (Solo Atrás)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
            ),
          ),
          
          // Controles inferiores
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 32,
                right: 32,
                top: 40,
                bottom: MediaQuery.of(context).padding.bottom + 32,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87, Colors.black],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Importar Galería
                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          child: const Icon(Icons.photo_library, color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Importar',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Botón de Captura
                  GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isProcessing ? Colors.white30 : Colors.white,
                          ),
                          child: _isProcessing
                              ? const Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                              : const SizedBox(),
                        ),
                      ),
                    ),
                  ),
                  
                  // Espacio vacío para equilibrar
                  const SizedBox(width: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    if (_isCameraInitialized && _cameraController != null) {
      final size = MediaQuery.of(context).size;
      var scale = size.aspectRatio * _cameraController!.value.aspectRatio;
      if (scale < 1) scale = 1 / scale;
      
      return Transform.scale(
        scale: scale,
        child: Center(
          child: CameraPreview(_cameraController!),
        ),
      );
    }
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  // ==========================================
  // ESTADO 2: SELECCIONADO (selectedImages.isNotEmpty)
  // ==========================================
  Widget _buildSelectedImagesView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Carrusel
          PageView.builder(
            itemCount: _selectedImages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return Image.file(
                File(_selectedImages[index].path),
                fit: BoxFit.contain,
              );
            },
          ),
          
          // Header: Descartar e Info
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón Descartar / Volver a Cámara
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImages.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
                // Indicador de página
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_currentPage + 1} / ${_selectedImages.length}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Botón eliminar imagen actual
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImages.removeAt(_currentPage);
                      if (_currentPage >= _selectedImages.length && _currentPage > 0) {
                        _currentPage--;
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
          
          // Botón inferior Analizar
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: _navigateToPreview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Analizar ${_selectedImages.length} foto${_selectedImages.length > 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
