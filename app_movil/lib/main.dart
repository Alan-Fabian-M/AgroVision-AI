import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart'; // Este archivo se generará al ejecutar flutterfire configure
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/capture_screen.dart';
import 'screens/preview_screen.dart';
import 'screens/analysis_result_screen.dart';
import 'screens/field_map_screen.dart';
import 'screens/advisor_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/insumo_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Mensaje en background: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    print('Permiso de notificaciones: ${settings.authorizationStatus}');
    
    String? token = await messaging.getToken();
    print('=======================================');
    print('FCM Token: $token');
    print('=======================================');
    if (token != null) {
      ApiService.registerFcmToken(token);
    }
    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notificación clickeada desde background!');
      navigatorKey.currentState?.pushNamed('/capture');
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensaje recibido en foreground!');
      if (message.notification != null) {
        print('Título: ${message.notification?.title}, Cuerpo: ${message.notification?.body}');
      }
    });
  } catch (e) {
    print("Advertencia: Firebase no pudo inicializarse. Asegúrate de ejecutar 'flutterfire configure'. Error: $e");
  }

  runApp(const ProviderScope(child: AgroGuardianApp()));
}

class AgroGuardianApp extends StatelessWidget {
  const AgroGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroVision AI',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/capture': (_) => const CaptureScreen(),
        '/advisor': (_) => const AdvisorScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/field': (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments as Map<String, dynamic>?;
          return FieldMapScreen(
            nuevaPlaga: args?['plaga'] as String?,
            nuevaPrioridad: args?['prioridad'] as String?,
          );
        },
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
