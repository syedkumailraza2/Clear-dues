import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../data/models/models.dart';
import 'core_providers.dart';

// Auth state
class AuthState {
  final User? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState());

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      final storage = _ref.read(secureStorageProvider);
      final token = await storage.read(key: AppConstants.tokenKey);

      if (token != null) {
        final datasource = _ref.read(authDatasourceProvider);
        final user = await datasource.getCurrentUser();
        state = AuthState(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        state = const AuthState(isLoading: false);
      }
    } catch (e) {
      // Token invalid or expired
      await _clearAuth();
      state = const AuthState(isLoading: false);
    }
  }

  Future<bool> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final datasource = _ref.read(authDatasourceProvider);
      final response = await datasource.login(
        email: email,
        phone: phone,
        password: password,
      );

      await _saveAuth(response.token);

      state = AuthState(
        user: response.user,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? upiId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final datasource = _ref.read(authDatasourceProvider);
      final response = await datasource.signup(
        name: name,
        email: email,
        phone: phone,
        password: password,
        upiId: upiId,
      );

      await _saveAuth(response.token);

      state = AuthState(
        user: response.user,
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _clearAuth();
    state = const AuthState();
  }

  Future<bool> updateProfile({
    String? name,
    String? upiId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final datasource = _ref.read(userDatasourceProvider);
      final user = await datasource.updateProfile(
        name: name,
        upiId: upiId,
      );

      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> _saveAuth(String token) async {
    final storage = _ref.read(secureStorageProvider);
    await storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<void> _clearAuth() async {
    final storage = _ref.read(secureStorageProvider);
    await storage.delete(key: AppConstants.tokenKey);
  }
}

// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

// Convenience providers
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
