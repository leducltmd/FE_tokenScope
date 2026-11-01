import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// Cấu hình endpoint của backend TokenScope.
///
/// `10.0.2.2` là host loopback của máy Windows khi chạy trên Android
/// Emulator. Trên web/desktop dùng `localhost`. Khi chạy trên thiết bị vật
/// lý thật, hãy truyền `--dart-define=API_BASE_URL=http://<IP-LAN>:3000/api`.
class ApiConfig {
  const ApiConfig({this.baseUrl = defaultBaseUrl});

  static const String defaultBaseUrl = kIsWeb
      ? 'http://localhost:3000/api'
      : 'http://10.0.2.2:3000/api';

  /// Ghi đè qua `--dart-define` khi cần trỏ về host khác.
  ///
  /// Không dùng được trong biểu thức `const` vì `String.fromEnvironment`
  /// chỉ cho phép so sánh với chuỗi hằng, nên việc chọn URL được thực
  /// hiện ở [resolve].
  static const String overrideBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// URL đầy đủ dùng cho request, đã áp dụng `API_BASE_URL` nếu có.
  static String resolve() {
    if (overrideBaseUrl.isNotEmpty) return overrideBaseUrl;
    return defaultBaseUrl;
  }

  final String baseUrl;

  static final ApiConfig instance = ApiConfig(baseUrl: resolve());
}

/// Lỗi HTTP từ backend, mang theo mã lỗi để client xử lý.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Nguồn dữ liệu xác thực gọi trực tiếp backend TokenScope.
///
/// Dùng `package:http` để chạy được trên cả web, Android và desktop —
/// `dart:io` không dùng được trên Flutter web.
class ApiAuthService implements AuthService {
  ApiAuthService({ApiConfig? config, http.Client? client})
    : config = config ?? ApiConfig.instance,
      _client = client ?? http.Client();

  final ApiConfig config;
  final http.Client _client;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    return _post('/auth/login', {'email': email, 'password': password});
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String birthDate,
    required String email,
    required String password,
  }) async {
    return _post('/auth/register', {
      'name': name,
      'birthDate': birthDate,
      'email': email,
      'password': password,
    });
  }

  @override
  Future<AuthResult> forgotPassword(String email) async {
    return _post('/auth/forgot-password', {'email': email});
  }

  @override
  Future<void> logout() async {
    // Backend thu hồi phiên qua endpoint /auth/logout (cần refreshToken).
  }

  void dispose() => _client.close();

  Future<AuthResult> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${config.baseUrl}$path');
    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final text = response.body;

      Map<String, dynamic> data = {};
      if (text.isNotEmpty) {
        try {
          data = jsonDecode(text) as Map<String, dynamic>;
        } catch (_) {
          data = {'message': text};
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final rawUser = data['user'];
        return AuthResult.success(
          token: data['accessToken'] as String?,
          refreshToken: data['refreshToken'] as String?,
          user: rawUser is Map<String, dynamic>
              ? AuthUser.fromJson(rawUser)
              : rawUser,
        );
      }

      return AuthResult.failure(
        (data['message'] ?? 'Không thể kết nối tới máy chủ.').toString(),
        code: data['code'] as String?,
        statusCode: response.statusCode,
      );
    } on http.ClientException {
      return const AuthResult.failure(
        'Không thể kết nối tới máy chủ. Kiểm tra kết nối mạng.',
      );
    } catch (e) {
      return AuthResult.failure('Đã xảy ra lỗi: $e');
    }
  }
}
