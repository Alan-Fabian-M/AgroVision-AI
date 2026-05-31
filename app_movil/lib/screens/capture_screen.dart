import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  bool _isProcessing = false;
  List<XFile> _selectedImages = [];
  int _currentPage = 0;

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
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (file != null && mounted) {
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
      }, // Ya no mandamos 'tipo'
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedImages.isNotEmpty) {
      return _buildSelectedImagesView();
    }
    return _buildInitialView();
  }

  // ==========================================
  // ESTADO 1: INICIAL (selectedImages.isEmpty)
  // ==========================================
  Widget _buildInitialView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo simple oscuro
          Container(color: Colors.black),
          
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
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
            ),
          ),
          
          // Controles Centrales
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nueva Captura',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona el origen de tus imágenes',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Botón de Cámara
                  _buildActionCard(
                    title: 'Tomar Foto',
                    icon: Icons.camera_alt,
                    color: AppColors.primary,
                    onTap: _takePhoto,
                  ),
                  
                  const SizedBox(height: 24),

                  // Botón de Galería
                  _buildActionCard(
                    title: 'Importar de Galería',
                    icon: Icons.photo_library,
                    color: AppColors.secondary,
                    onTap: _pickFromGallery,
                  ),
                ],
              ),
            ),
          ),
          
          // Indicador de carga central (si aplica)
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isProcessing ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
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
                // Botón Descartar / Volver a Inicio
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
          
          // Botones inferiores (Analizar + Add más)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fila para añadir más fotos
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.white24),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.white24),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Botón Analizar
                SizedBox(
                  width: double.infinity,
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
                          'Finalizar con ${_selectedImages.length} foto${_selectedImages.length > 1 ? 's' : ''}',
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
          ),
        ],
      ),
    );
  }
}
