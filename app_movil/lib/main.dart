import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart'; // Este archivo se generará al ejecutar flutterfire configure
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'core/router/app_router.dart';
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
      // TODO: Usar el router para navegar si goRouter no acepta global key
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensaje recibido en foreground!');
      if (message.notification != null) {
        print('Título: ${message.notification?.title}, Cuerpo: ${message.notification?.body}');
      }
    });
  } catch (e) {
    print("Advertencia: Firebase no pudo inicializarse. Error: $e");
  }

  runApp(const ProviderScope(child: AgroGuardianApp()));
}

class AgroGuardianApp extends ConsumerWidget {
  const AgroGuardianApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'AgroVision AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: goRouter,
    );
  }
}

