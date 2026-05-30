import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/capture_screen.dart';
import 'screens/preview_screen.dart';
import 'screens/analysis_result_screen.dart';
import 'screens/field_map_screen.dart';

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
        '/field': (_) => const FieldMapScreen(),
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
