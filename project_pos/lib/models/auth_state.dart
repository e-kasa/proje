import 'user_model.dart';

class AuthState {
  final User? user;
  final String? token;
  final String? refreshToken;
  final String? sessionId;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  const AuthState({
    this.user,
    this.token,
    this.refreshToken,
    this.sessionId,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  factory AuthState.initial() => const AuthState();

  AuthState copyWith({
    User? user,
    String? token,
    String? refreshToken,
    String? sessionId,
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      sessionId: sessionId ?? this.sessionId,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error ?? this.error,
    );
  }
}
