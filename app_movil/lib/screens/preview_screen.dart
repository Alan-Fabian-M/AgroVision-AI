import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../core/providers/location_provider.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  final List<String> imagePaths;
  final String tipo;

  const PreviewScreen({
    super.key,
    required this.imagePaths,
    required this.tipo,
  });

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  late List<String> _imagePaths;
  int _selectedIndex = 0;
  final TextEditingController _notesController = TextEditingController();
  final _picker = ImagePicker();

  // Audio state
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  String? _audioPath;
  bool _isRecording = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _imagePaths = List.from(widget.imagePaths);
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _audioPath = null;
        });
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
    } catch (e) {
      debugPrint('Error stopping record: $e');
    }
  }

  void _deleteAudio() {
    setState(() {
      _audioPath = null;
      _isPlaying = false;
      _audioPlayer.stop();
    });
  }

  Future<void> _toggleAudioPlay() async {
    if (_audioPath == null) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(_audioPath!));
    }
  }

  Future<void> _addImage() async {
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ImageSourceSheet(),
    );
    if (result == null) return;

    final file = await _picker.pickImage(source: result);
    if (file != null && mounted) {
      setState(() {
        _imagePaths.add(file.path);
        _selectedIndex = _imagePaths.length - 1;
      });
    }
  }

  void _analyzeNow() {
    context.push(
      '/analysis-result',
      extra: {
        'imagePaths': _imagePaths,
        'tipo': widget.tipo,
        'descripcion': _notesController.text,
        'audioPath': _audioPath,
      },
    );
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainImage(),
                  _buildEvidenceCarousel(),
                  const SizedBox(height: 160),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomSheet(),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 4,
        right: 8,
      ),
      height: MediaQuery.of(context).padding.top + 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.onSurfaceVariant),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Text(
            'Confirmar Captura',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: AppColors.onSurfaceVariant),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMainImage() {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(_imagePaths[_selectedIndex]),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.surfaceContainerLow,
              child: const Icon(Icons.broken_image, size: 64, color: AppColors.onSurfaceVariant),
            ),
          ),
          // Chip de ubicación
          Positioned(
            top: 16,
            right: 16,
            child: Consumer(
              builder: (context, ref, child) {
                final locationAsync = ref.watch(locationProvider);
                final locationText = locationAsync.when(
                  data: (pos) => pos != null ? '${pos.latitude.toStringAsFixed(3)}, ${pos.longitude.toStringAsFixed(3)}' : 'GPS no disponible',
                  loading: () => 'Obteniendo GPS...',
                  error: (_, __) => 'Error GPS',
                );

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.outlineVariant),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        locationText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
          ),
          // Chip de tipo seleccionado
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.tipo,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCarousel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evidencia Adicional',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Thumbnails existentes
                ..._imagePaths.asMap().entries.map((entry) {
                  final i = entry.key;
                  final path = entry.value;
                  final active = i == _selectedIndex;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _selectedIndex = i),
                        child: Container(
                          width: 72,
                          height: 72,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: active ? AppColors.primary : AppColors.outlineVariant,
                              width: active ? 2.5 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.file(
                              File(path),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.surfaceContainerLow,
                                child: const Icon(Icons.image, size: 24, color: AppColors.onSurfaceVariant),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _imagePaths.removeAt(i);
                              if (_imagePaths.isEmpty) {
                                Navigator.pop(context);
                              } else if (_selectedIndex >= _imagePaths.length) {
                                _selectedIndex = _imagePaths.length - 1;
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_audioPath != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: AppColors.onPrimaryContainer),
                      onPressed: _toggleAudioPlay,
                    ),
                    Expanded(
                      child: Text(
                        'Nota de voz',
                        style: GoogleFonts.inter(color: AppColors.onPrimaryContainer, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: _deleteAudio,
                    ),
                  ],
                ),
              ),
            ),
          // Input multimodal estilo WhatsApp
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attach
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: AppColors.onSurfaceVariant, size: 22),
                    onPressed: _addImage,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _notesController,
                      maxLines: null,
                      style: GoogleFonts.inter(fontSize: 15, color: AppColors.onSurface),
                      decoration: InputDecoration(
                        hintText: _isRecording ? 'Grabando audio...' : 'Añade detalles o dudas...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 15,
                          color: _isRecording ? AppColors.primary : AppColors.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  // Mic
                  GestureDetector(
                    onTap: () {
                      if (_isRecording) {
                        _stopRecording();
                      } else {
                        _startRecording();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 4, bottom: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? AppColors.error // Rojo para indicar grabando
                            : Colors.transparent,
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic_none,
                        color: _isRecording ? Colors.white : AppColors.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Botón analizar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _analyzeNow,
                icon: const Icon(Icons.biotech, size: 20),
                label: Text(
                  'Analizar Cultivo',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimaryContainer,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Añadir imagen',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SourceOption(
                icon: Icons.photo_camera,
                label: 'Cámara',
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              _SourceOption(
                icon: Icons.photo_library,
                label: 'Galería',
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.onSurface)),
        ],
      ),
    );
  }
}
