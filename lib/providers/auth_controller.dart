import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/mock_auth_service.dart';

enum AuthStatus { unknown, authenticating, authenticated, unauthenticated }

/// Quản lý trạng thái xác thực của ứng dụng.
class AuthController extends ChangeNotifier {
  AuthController({AuthService? service})
    : _service = service ?? MockAuthService();

  AuthService _service;

  AuthStatus _status = AuthStatus.unknown;
  String? _token;
  String? _refreshToken;
  String? _error;
  String? _errorCode;
  AuthUser? _user;

  AuthStatus get status => _status;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get error => _error;
  String? get errorCode => _errorCode;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Thông tin người dùng hiện tại (có thể null trước khi đăng nhập).
  AuthUser? get user => _user;

  /// Tên hiển thị trên dashboard — lấy từ họ tên người dùng đăng ký.
  String get displayName => _user?.displayName ?? 'Minh Anh';

  /// Tên gọi thân mật — tên đệm + tên (hai từ cuối của họ tên).
  String get shortName => _user?.shortName ?? displayName;

  /// Thay nguồn dữ liệu — dùng khi backend sẵn sàng
  /// (`AuthController(service: ApiAuthService())`).
  void useService(AuthService service) {
    _service = service;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _set(AuthStatus.authenticating);
    final result = await _service.login(email: email, password: password);
    return _apply(result);
  }

  Future<bool> register({
    required String name,
    required String birthDate,
    required String email,
    required String password,
  }) async {
    _set(AuthStatus.authenticating);
    final result = await _service.register(
      name: name,
      birthDate: birthDate,
      email: email,
      password: password,
    );
    return _apply(result);
  }

  Future<bool> forgotPassword(String email) async {
    _set(AuthStatus.authenticating);
    final result = await _service.forgotPassword(email);
    if (result.isSuccess) {
      _status = AuthStatus.unauthenticated;
      _error = null;
      notifyListeners();
    } else {
      _apply(result);
    }
    return result.isSuccess;
  }

  Future<void> logout() async {
    await _service.logout();
    _token = null;
    _refreshToken = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  bool _apply(AuthResult result) {
    if (result.isSuccess) {
      _token = result.token;
      _refreshToken = result.refreshToken;
      _user = _parseUser(result.user);
      _error = null;
      _errorCode = null;
      _status = AuthStatus.authenticated;
    } else {
      _token = null;
      _refreshToken = null;
      _user = null;
      _error = result.error;
      _errorCode = result.code;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
    return result.isSuccess;
  }

  /// Đọc thông tin người dùng từ nhiều kiểu dữ liệu khác nhau.
  AuthUser? _parseUser(dynamic raw) {
    if (raw == null) return null;
    if (raw is AuthUser) return raw;
    if (raw is Map<String, dynamic>) return AuthUser.fromJson(raw);
    if (raw is Map) return AuthUser.fromJson(Map<String, dynamic>.from(raw));
    return null;
  }

  void _set(AuthStatus status) {
    _status = status;
    _error = null;
    _errorCode = null;
    notifyListeners();
  }
}
