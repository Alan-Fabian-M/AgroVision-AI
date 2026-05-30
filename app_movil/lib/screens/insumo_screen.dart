import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class InsumoScreen extends StatefulWidget {
  final String plaga;
  final List<String> productosSugeridos;

  const InsumoScreen({
    super.key,
    required this.plaga,
    required this.productosSugeridos,
  });

  @override
  State<InsumoScreen> createState() => _InsumoScreenState();
}

class _InsumoScreenState extends State<InsumoScreen> {
  List<_Tratamiento> _tratamientos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTratamientos();
  }

  Future<void> _fetchTratamientos() async {
    try {
      final uri = Uri.parse(
          '$kBackendUrl/api/v1/knowledge-graph/treatments'
          '?plaga=${Uri.encodeComponent(widget.plaga)}');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['tratamientos'] as List? ?? []);
        setState(() {
          _tratamientos = list.map((e) => _Tratamiento.fromJson(e)).toList();
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    // Fallback: usar los productos sugeridos por Gemini
    setState(() {
      _tratamientos = widget.productosSugeridos
          .map((p) => _Tratamiento(nombre: p, ingrediente: '', aplicacion: 'Foliar', plaga: widget.plaga, tipoPlaga: '', cultivos: []))
          .toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildAppBar(),
          _buildPlagaHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _tratamientos.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
          ),
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
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            const Icon(Icons.shopping_cart_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Insumos Recomendados',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlagaHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.surfaceTint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)),
            child: const Icon(Icons.pest_control, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plaga detectada', style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(widget.plaga, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    '${_tratamientos.length} tratamiento${_tratamientos.length != 1 ? 's' : ''} encontrado${_tratamientos.length != 1 ? 's' : ''}',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _tratamientos.length,
      itemBuilder: (_, i) => _TratamientoCard(tratamiento: _tratamientos[i], index: i),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 56, color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('No se encontraron tratamientos específicos', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Consulta a tu asesor agrónomo para recomendaciones personalizadas.', style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/advisor'),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: Text('Hablar con Asesor', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de tratamiento ────────────────────────────────────────────────────

class _TratamientoCard extends StatelessWidget {
  final _Tratamiento tratamiento;
  final int index;
  const _TratamientoCard({required this.tratamiento, required this.index});

  static const _cardColors = [
    Color(0xFFE8F5E9),
    Color(0xFFFFF3E0),
    Color(0xFFE3F2FD),
    Color(0xFFF3E5F5),
  ];
  static const _iconColors = [
    Color(0xFF2E7D32),
    Color(0xFFE65100),
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
  ];

  @override
  Widget build(BuildContext context) {
    final cardColor = _cardColors[index % _cardColors.length];
    final iconColor = _iconColors[index % _iconColors.length];
    final isHongo = tratamiento.tipoPlaga.toLowerCase().contains('hongo');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera con color
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: iconColor.withValues(alpha: 0.15)),
                  child: Icon(
                    isHongo ? Icons.science : Icons.pest_control_rodent,
                    color: iconColor, size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tratamiento.nombre,
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                      ),
                      if (tratamiento.tipoPlaga.isNotEmpty)
                        Text(
                          'Para: ${tratamiento.tipoPlaga}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Detalles
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                if (tratamiento.ingrediente.isNotEmpty)
                  _InfoRow(icon: Icons.biotech_outlined, label: 'Ingrediente activo', value: tratamiento.ingrediente),
                _InfoRow(icon: Icons.water_drop_outlined, label: 'Aplicación', value: tratamiento.aplicacion),
                if (tratamiento.cultivos.isNotEmpty)
                  _InfoRow(icon: Icons.grass_outlined, label: 'Cultivos afectados', value: tratamiento.cultivos.join(', ')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/advisor'),
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: Text('Consultar uso', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: '$label: ', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                  TextSpan(text: value, style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurface)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modelo ────────────────────────────────────────────────────────────────────

class _Tratamiento {
  final String nombre, ingrediente, aplicacion, plaga, tipoPlaga;
  final List<String> cultivos;
  const _Tratamiento({required this.nombre, required this.ingrediente, required this.aplicacion, required this.plaga, required this.tipoPlaga, required this.cultivos});

  factory _Tratamiento.fromJson(Map<String, dynamic> j) => _Tratamiento(
        nombre: j['nombre'] ?? '',
        ingrediente: j['ingrediente_activo'] ?? '',
        aplicacion: j['aplicacion'] ?? 'Foliar',
        plaga: j['plaga'] ?? '',
        tipoPlaga: j['tipo_plaga'] ?? '',
        cultivos: List<String>.from(j['cultivos'] ?? []),
      );
}
