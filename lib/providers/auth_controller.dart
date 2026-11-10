import 'package:flutter/foundation.dart';
import 'dart:async';

import '../services/api_auth_service.dart';
import '../services/api_session.dart';
import '../services/auth_service.dart';
import 'firebase_lab3_controller.dart';

enum AuthStatus { unknown, authenticating, authenticated, unauthenticated }

/// Quản lý trạng thái xác thực của ứng dụng.
class AuthController extends ChangeNotifier {
  /// Mặc định dùng [ApiAuthService] kết hợp Firebase cho Google Sign-In.
  AuthController({AuthService? service})
    : _service = service ?? ApiAuthService() {
    _bindAuthStateChanges();
  }

  AuthService _service;

  AuthStatus _status = AuthStatus.unknown;
  String? _token;
  String? _refreshToken;
  String? _error;
  String? _errorCode;
  AuthUser? _user;
  StreamSubscription<AuthResult?>? _authStateSubscription;

  AuthStatus get status => _status;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get error => _error;
  String? get errorCode => _errorCode;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Thông tin người dùng hiện tại (có thể null trước khi đăng nhập).
  AuthUser? get user => _user;

  /// Tên hiển thị trên dashboard — lấy từ họ tên người dùng.
  String get displayName => _user?.displayName ?? 'Admin Token Scope';

  /// Tên gọi thân mật — tên đệm + tên (hai từ cuối của họ tên).
  String get shortName => _user?.shortName ?? displayName;

  /// Thay nguồn dữ liệu — dùng khi chạy test hoặc thay đổi môi trường.
  void useService(AuthService service) {
    _authStateSubscription?.cancel();
    _service = service;
    _bindAuthStateChanges();
  }

  void _bindAuthStateChanges() {
    _authStateSubscription = _service.authStateChanges.listen((result) {
      if (_status == AuthStatus.authenticating) return;
      if (result == null) {
        // Email/password sessions belong to the backend, so a null Firebase
        // event must not log the user out of that session.
        if (_token != null && _user?.authProvider != 'google') return;
        _setUnauthenticated();
      } else {
        _apply(result);
      }
    });
  }

  Future<bool> login({required String email, required String password}) async {
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

  /// Đăng nhập bằng Google qua Firebase Authentication thật.
  Future<bool> signInWithGoogle() async {
    _set(AuthStatus.authenticating);
    final result = await _service.signInWithGoogle();

    if (result.isCancelled) {
      // Người dùng tự hủy chọn tài khoản Google (nhấn Back/Cancel):
      // Không xem là lỗi nghiêm trọng, êm dịu phục hồi trạng thái.
      _status = _user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      _error = null;
      _errorCode = null;
      notifyListeners();
      return false;
    }

    return _apply(result);
  }

  /// Khôi phục phiên đăng nhập (Firebase hoặc token đã lưu).
  /// Đăng nhập bằng GitHub qua Firebase Authentication thật.
  Future<bool> signInWithGitHub() async {
    _set(AuthStatus.authenticating);
    final result = await _service.signInWithGitHub();

    if (result.isCancelled) {
      _status = _user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      _error = null;
      _errorCode = null;
      notifyListeners();
      return false;
    }

    return _apply(result);
  }

  Future<bool> restoreSession() async {
    final result = await _service.restoreSession();
    if (result != null && result.isSuccess) {
      return _apply(result);
    }
    return false;
  }

  Future<void> logout() async {
    // Ghi nhận sự kiện Analytics khi đăng xuất (Slide 15)
    FirebaseLab3Controller.instance.logLogout(screen: 'settings');

    await _service.logout();
    _token = null;
    _refreshToken = null;
    _user = null;
    _setUnauthenticated(notify: false);
    ApiSession.instance.clear();
    notifyListeners();
  }

  void _setUnauthenticated({bool notify = true}) {
    _token = null;
    _refreshToken = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    _errorCode = null;
    ApiSession.instance.clear();
    if (notify) notifyListeners();
  }

  bool _apply(AuthResult result) {
    if (result.isSuccess) {
      _token = result.token;
      _refreshToken = result.refreshToken;
      _user = _parseUser(result.user);
      _error = null;
      _errorCode = null;
      _status = AuthStatus.authenticated;

      // Gắn User ID và Custom Key cho Crashlytics & Analytics (Slide 15 & 18)
      if (_user?.id != null) {
        FirebaseLab3Controller.instance.setCrashlyticsUserId(_user!.id!);
        FirebaseLab3Controller.instance.setAnalyticsUserId(_user!.id!);
        FirebaseLab3Controller.instance.setCrashlyticsCustomKey(
          'auth_provider',
          _user?.authProvider ?? 'password',
        );

        // Gắn userId cho sự kiện sử dụng ứng dụng (Admin Web).
        FirebaseLab3Controller.instance.setAppUsageUserId(_user!.id!);
      }
      FirebaseLab3Controller.instance.logLogin(
        method: _user?.authProvider ?? 'email_password',
      );

      // Gán token cho ApiSession nếu là TokenScope JWT từ Backend Node.js.
      // Khi đăng nhập Google đã hoán đổi thành công với Backend (có refreshToken hoặc Backend JWT),
      // gán token vào ApiSession để có toàn quyền gọi các API backend.
      if (result.token != null &&
          result.token!.isNotEmpty &&
          ((_user?.authProvider != 'google' && _user?.authProvider != 'github') ||
              result.refreshToken != null)) {
        ApiSession.instance.setAccessToken(result.token);
      } else {
        ApiSession.instance.clear();
      }
    } else {
      _setUnauthenticated(notify: false);
      _error = result.error;
      _errorCode = result.code;
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

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
