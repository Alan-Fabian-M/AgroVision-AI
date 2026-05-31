import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/auth_local_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/auth_interceptor.dart';

// --- State ---
enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// --- Dependencies Providers ---
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  final secureStorage = ref.watch(secureStorageProvider);
  dio.interceptors.add(AuthInterceptor(secureStorage));
  return dio;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  
  return AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(dio),
    localDataSource: AuthLocalDataSourceImpl(secureStorage),
  );
});

// --- Auth Notifier ---
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Initial state
    final state = AuthState();
    
    // We shouldn't call async functions directly in build if we want to return synchronously,
    // but we can trigger the check and return the initial state
    Future.microtask(() => checkAuthStatus());
    
    return state;
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final user = await authRepository.checkSession();
      if (user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error al verificar sesión',
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final user = await authRepository.login(email, password);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> register(String email, String nombre, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final authRepository = ref.read(authRepositoryProvider);
      // Registrar al usuario
      await authRepository.register(email, nombre, password);
      // Auto login después del registro
      await login(email, password);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.logout();
    state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
  }
}

// --- Provider global ---
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
