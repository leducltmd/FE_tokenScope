import 'dart:async';

/// Kết quả trả về từ các lời gọi xác thực.
class AuthResult {
  const AuthResult.success({
    this.token,
    this.refreshToken,
    this.user,
    this.code,
    this.statusCode,
  }) : error = null;

  const AuthResult.failure(this.error, {this.code, this.statusCode})
    : token = null,
      refreshToken = null,
      user = null;

  /// Kết quả khi người dùng tự hủy chọn tài khoản Google (nhấn Back / Cancel).
  const AuthResult.cancelled({this.error = 'Đã hủy chọn tài khoản Google.'})
    : token = null,
      refreshToken = null,
      user = null,
      code = 'CANCELLED',
      statusCode = null;

  final String? token;
  final String? refreshToken;
  final dynamic user;
  final String? error;
  final String? code;
  final int? statusCode;

  bool get isSuccess => error == null;

  /// Người dùng chủ động hủy thao tác đăng nhập.
  bool get isCancelled => code == 'CANCELLED';

  /// Lỗi do người dùng nhập sai (email đã tồn tại, mật khẩu yếu...)
  bool get isValidationError => statusCode == 400 || statusCode == 409;

  /// Lỗi xác thực (sai email/mật khẩu, token hết hạn)
  bool get isUnauthorized => statusCode == 401;
}

/// Thông tin người dùng đã đăng nhập.
class AuthUser {
  const AuthUser({
    this.id,
    this.email,
    this.name,
    this.birthDate,
    this.avatarUrl,
    this.authProvider = 'password',
  });

  final String? id;
  final String? email;
  final String? name;

  /// Ngày sinh ở định dạng YYYY-MM-DD.
  final String? birthDate;
  final String? avatarUrl;

  /// Phương thức xác thực: 'password' (Backend) hoặc 'google' (Firebase).
  final String? authProvider;

  /// Tên hiển thị — ưu tiên tên đầy đủ, fallback sang email.
  String get displayName {
    final value = name?.trim();
    if (value == null || value.isEmpty) {
      final mail = email?.trim();
      if (mail == null || mail.isEmpty) return 'bạn';
      return mail.split('@').first;
    }
    return value;
  }

  /// Tên gọi thân mật — gồm tên đệm và tên gọi (hai từ cuối).
  ///
  /// "Nguyễn Minh Anh" → "Minh Anh" · "Nguyễn Văn Minh Anh" → "Minh Anh" ·
  /// "Minh Anh" → "Minh Anh" · "Minh" → "Minh".
  String get shortName {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length < 2) return parts.isEmpty ? displayName : parts.first;
    return parts.sublist(parts.length - 2).join(' ');
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final rawDate = json['birthDate'];
    return AuthUser(
      id: json['id'] as String?,
      email: json['email'] as String?,
      name: json['name'] as String?,
      birthDate: rawDate == null ? null : _formatDate(rawDate),
      avatarUrl: json['avatarUrl'] as String?,
      authProvider: json['authProvider'] as String? ?? 'password',
    );
  }

  /// Chuẩn hoá ngày sinh về YYYY-MM-DD (backend có thể trả ISO-8601).
  static String? _formatDate(Object value) {
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return null;
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    return '${parsed.year}-$month-$day';
  }
}

/// Lớp trừu tượng cho nguồn dữ liệu xác thực.
///
/// Mặc định ứng dụng dùng [ApiAuthService] (backend thật) kết hợp
/// [FirebaseAuthService] cho đăng nhập Google qua Firebase.
/// [MockAuthService] chỉ dùng để chạy giao diện độc lập trong unit/widget test.
abstract class AuthService {
  /// Emits Firebase session changes when the selected auth provider supports it.
  /// Backend-only auth services can keep the default empty stream.
  Stream<AuthResult?> get authStateChanges => const Stream<AuthResult?>.empty();

  Future<AuthResult> login({required String email, required String password});

  Future<AuthResult> register({
    required String name,
    required String birthDate,
    required String email,
    required String password,
  });

  Future<AuthResult> forgotPassword(String email);

  /// Đăng nhập bằng Google thông qua Firebase Authentication.
  Future<AuthResult> signInWithGoogle();

  /// Đăng nhập bằng GitHub thông qua Firebase Authentication.
  Future<AuthResult> signInWithGitHub();

  /// Khôi phục phiên đăng nhập trước đó (nếu còn hiệu lực).
  Future<AuthResult?> restoreSession();

  Future<void> logout();
}
