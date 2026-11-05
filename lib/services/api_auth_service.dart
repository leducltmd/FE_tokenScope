import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'api_config.dart';
import 'auth_service.dart';
import 'firebase_auth_service.dart';

export 'api_client.dart' show ApiException;
export 'api_config.dart' show ApiConfig;

/// Nguồn dữ liệu xác thực chính của TokenScope.
///
/// - Đăng nhập/Đăng ký email & mật khẩu: Gọi Backend Node.js.
/// - Đăng nhập với Google: Xác thực qua Firebase Auth, sau đó trao đổi ID Token
///   với Backend Node.js (`POST /auth/google`) để lấy JWT của TokenScope và
///   đồng bộ người dùng vào cơ sở dữ liệu.
class ApiAuthService implements AuthService {
  ApiAuthService({
    ApiConfig? config,
    http.Client? client,
    FirebaseAuthService? firebaseAuthService,
  })  : _client = ApiClient(config: config, client: client),
        _customFirebaseAuth = firebaseAuthService;

  final ApiClient _client;
  final FirebaseAuthService? _customFirebaseAuth;

  FirebaseAuthService get _firebaseAuth =>
      _customFirebaseAuth ?? FirebaseAuthService();

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
  Future<AuthResult> signInWithGoogle() async {
    // 1. Xác thực Google với Firebase Authentication
    final firebaseResult = await _firebaseAuth.signInWithGoogle();
    if (!firebaseResult.isSuccess || firebaseResult.isCancelled) {
      return firebaseResult;
    }

    // 2. Trao đổi ID Token với Backend Node.js để nhận Backend JWT
    final idToken = firebaseResult.token;
    if (idToken != null && idToken.isNotEmpty) {
      try {
        final backendResult =
            await _post('/auth/google', {'idToken': idToken});
        if (backendResult.isSuccess) {
          final user = backendResult.user;
          final googleUser = user is AuthUser
              ? AuthUser(
                  id: user.id,
                  email: user.email,
                  name: user.name,
                  birthDate: user.birthDate,
                  avatarUrl: user.avatarUrl ??
                      (firebaseResult.user as AuthUser?)?.avatarUrl,
                  authProvider: 'google',
                )
              : user;

          return AuthResult.success(
            token: backendResult.token,
            refreshToken: backendResult.refreshToken,
            user: googleUser,
          );
        } else {
          return backendResult;
        }
      } catch (e) {
        // Nếu Backend chưa chạy hoặc lỗi mạng, trả về kết quả Firebase
      }
    }

    return firebaseResult;
  }

  @override
  Future<AuthResult?> restoreSession() {
    return _firebaseAuth.restoreSession();
  }

  @override
  Future<void> logout() async {
    // Thu hồi phiên Firebase & Google
    await _firebaseAuth.logout();
    // Backend thu hồi phiên qua endpoint /auth/logout (nếu có refreshToken)
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
