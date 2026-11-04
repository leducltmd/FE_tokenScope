import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'api_config.dart';
import 'auth_service.dart';

export 'api_client.dart' show ApiException;
export 'api_config.dart' show ApiConfig;

/// Nguồn dữ liệu xác thực gọi trực tiếp backend TokenScope.
///
/// Dùng `package:http` để chạy được trên cả web, Android và desktop —
/// `dart:io` không dùng được trên Flutter web.
class ApiAuthService implements AuthService {
  ApiAuthService({ApiConfig? config, http.Client? client})
    : _client = ApiClient(config: config, client: client);

  final ApiClient _client;

  /// URL đang hoạt động — cập nhật sau khi tìm được host kết nối được.
  String get baseUrl => _client.baseUrl;

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

  void dispose() => _client.dispose();

  /// Gửi POST và chuyển kết quả về [AuthResult].
  Future<AuthResult> _post(String path, Map<String, dynamic> body) async {
    try {
      final data = await _client.post(path, body: body);

      final rawUser = data['user'];
      return AuthResult.success(
        token: data['accessToken'] as String?,
        refreshToken: data['refreshToken'] as String?,
        user: rawUser is Map<String, dynamic>
            ? AuthUser.fromJson(rawUser)
            : rawUser,
      );
    } on ApiException catch (error) {
      return AuthResult.failure(
        error.message,
        code: error.code,
        statusCode: error.statusCode,
      );
    }
  }
}
