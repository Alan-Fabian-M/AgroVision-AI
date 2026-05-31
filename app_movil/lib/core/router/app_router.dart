import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/capture_screen.dart';
import '../../screens/field_map_screen.dart';
import '../../screens/preview_screen.dart';
import '../../screens/analysis_result_screen.dart';
import '../../screens/profile_screen.dart';

// Este ChangeNotifier envuelve al authProvider para que GoRouter pueda escucharlo
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        if (previous?.status != next.status) {
          notifyListeners();
        }
      },
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToRegister = state.matchedLocation == '/register';
      final isAuthScreen = isGoingToLogin || isGoingToRegister;

      if (authState.status == AuthStatus.initial || authState.status == AuthStatus.loading) {
        return null;
      }

      if (authState.status == AuthStatus.unauthenticated && !isAuthScreen) {
        return '/login';
      }

      if (authState.status == AuthStatus.authenticated && isAuthScreen) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/capture',
        builder: (context, state) => const CaptureScreen(),
      ),
      GoRoute(
        path: '/field',
        builder: (context, state) => const FieldMapScreen(),
      ),
      GoRoute(
        path: '/preview',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return PreviewScreen(
            imagePaths: args['imagePaths'] as List<String>,
          );
        },
      ),
      GoRoute(
        path: '/analysis-result',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>;
          return AnalysisResultScreen(
            imagePaths: List<String>.from(args['imagePaths'] as List),
            descripcion: args['descripcion'] as String? ?? '',
            audioPath: args['audioPath'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
