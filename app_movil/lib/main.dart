import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/capture_screen.dart';
import 'screens/preview_screen.dart';
import 'screens/analysis_result_screen.dart';
import 'screens/field_map_screen.dart';
import 'screens/advisor_screen.dart';
import 'screens/insumo_screen.dart';

void main() {
  runApp(const AgroGuardianApp());
}

class AgroGuardianApp extends StatelessWidget {
  const AgroGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroGuardian AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/capture': (_) => const CaptureScreen(),
        '/field': (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments as Map<String, dynamic>?;
          return FieldMapScreen(
            nuevaPlaga: args?['plaga'] as String?,
            nuevaPrioridad: args?['prioridad'] as String?,
          );
        },
        '/advisor': (_) => const AdvisorScreen(),
        '/insumos': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
          return InsumoScreen(
            plaga: args['plaga'] as String,
            productosSugeridos: List<String>.from(args['productos'] as List? ?? []),
          );
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/preview') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => PreviewScreen(
              imagePath: args['imagePath'] as String,
              tipo: args['tipo'] as String,
            ),
          );
        }
        if (settings.name == '/analysis-result') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => AnalysisResultScreen(
              imagePaths: List<String>.from(args['imagePaths'] as List),
              tipo: args['tipo'] as String,
              descripcion: args['descripcion'] as String? ?? '',
            ),
          );
        }
        return null;
      },
    );
  }
}
