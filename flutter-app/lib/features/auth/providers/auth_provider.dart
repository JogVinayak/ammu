import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? serverIp;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.serverIp,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    String? serverIp,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      serverIp: serverIp ?? this.serverIp,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    final serverIp = _repository.getServerIp();
    if (_repository.isLoggedIn()) {
      final user = _repository.getCurrentUser();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        serverIp: serverIp,
      );
    } else {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        serverIp: serverIp,
      );
    }
  }

  Future<void> login({
    required String serverIp,
    String? tenantId, // Optional - backend auto-resolves from email
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      // Save server IP first
      await _repository.saveServerIp(serverIp);

      final request = LoginRequest(
        tenantId: (tenantId != null && tenantId.isNotEmpty) ? tenantId : null,
        identifier: email,
        password: password,
      );

      final response = await _repository.login(request);

      final user = User(
        id: response.userId,
        name: response.displayName ?? email,
        email: email,
        tenantId: response.tenantId,
        userType: response.userType,
      );

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        serverIp: serverIp,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState(
      status: AuthStatus.unauthenticated,
      serverIp: state.serverIp,
    );
  }

  void clearError() {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      errorMessage: null,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

// Convenience provider to get current user directly
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});
