import 'dart:math';

import 'package:tokenscope/services/auth_service.dart';

/// Nguồn dữ liệu xác thực giả lập — chỉ dùng trong test widget.
///
/// Mật khẩu hợp lệ: `123456`.
class MockAuthService implements AuthService {
  MockAuthService({this.simulateDelay = const Duration(milliseconds: 900)});

  final Duration simulateDelay;
  final Random _random = Random();

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
      user: AuthUser(
        email: email,
        name: name,
        birthDate: birthDate,
      ),
    );
  }

  @override
  Future<AuthResult> forgotPassword(String email) async {
    await Future<void>.delayed(simulateDelay);
    return AuthResult.success(token: 'mock_reset_${_random.nextInt(99999)}');
  }

  @override
  Future<void> logout() async {}
}
