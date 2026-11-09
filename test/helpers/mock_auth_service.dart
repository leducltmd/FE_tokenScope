import 'dart:math';

import 'package:tokenscope/services/auth_service.dart';

/// Nguồn dữ liệu xác thực giả lập — chỉ dùng trong test widget.
///
/// Mật khẩu hợp lệ: `123456`.
class MockAuthService implements AuthService {
  MockAuthService({
    this.simulateDelay = const Duration(milliseconds: 900),
    this.shouldCancelGoogle = false,
    this.googleError,
  });

  final Duration simulateDelay;
  final bool shouldCancelGoogle;
  final String? googleError;
  final Random _random = Random();

  @override
  Stream<AuthResult?> get authStateChanges => const Stream<AuthResult?>.empty();

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(simulateDelay);
    if (password != '123456') {
      return const AuthResult.failure(
        'Email hoặc mật khẩu không đúng.',
        code: 'INVALID_CREDENTIALS',
        statusCode: 401,
      );
    }
    return AuthResult.success(
      token: 'mock_token_${_random.nextInt(99999)}',
      user: AuthUser(email: email, name: 'Minh Anh'),
    );
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String birthDate,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(simulateDelay);
    return AuthResult.success(
      token: 'mock_token_${_random.nextInt(99999)}',
      user: AuthUser(email: email, name: name, birthDate: birthDate),
    );
  }

  @override
  Future<AuthResult> forgotPassword(String email) async {
    await Future<void>.delayed(simulateDelay);
    return AuthResult.success(token: 'mock_reset_${_random.nextInt(99999)}');
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    await Future<void>.delayed(simulateDelay);
    if (shouldCancelGoogle) {
      return const AuthResult.cancelled();
    }
    if (googleError != null) {
      return AuthResult.failure(googleError!, code: 'GOOGLE_ERROR');
    }
    return AuthResult.success(
      token: 'mock_google_id_token_${_random.nextInt(99999)}',
      user: const AuthUser(
        id: 'google_uid_123',
        email: 'google.user@gmail.com',
        name: 'Google User',
        avatarUrl: 'https://lh3.googleusercontent.com/a/mock',
        authProvider: 'google',
      ),
    );
  }

  @override
  Future<AuthResult> signInWithGitHub() async {
    await Future<void>.delayed(simulateDelay);
    return AuthResult.success(
      token: 'mock_github_id_token_${_random.nextInt(99999)}',
      user: const AuthUser(
        id: 'github_uid_456',
        email: 'developer@github.com',
        name: 'GitHub Developer',
        avatarUrl: 'https://avatars.githubusercontent.com/u/9919?v=4',
        authProvider: 'github',
      ),
    );
  }

  Future<AuthResult?> restoreSession() async {
    return null;
  }

  @override
  Future<void> logout() async {}
}
