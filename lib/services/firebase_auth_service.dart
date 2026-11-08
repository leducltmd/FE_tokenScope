import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_service.dart';

/// Dịch vụ xác thực bằng Firebase Authentication và Google Sign-In thật.
///
/// Tuân thủ quy định Lab 3 và google_sign_in phiên bản 7.2.0:
/// - Khởi tạo [GoogleSignIn.instance.initialize] đúng một lần.
/// - Sử dụng phương thức [GoogleSignIn.instance.authenticate] (thay cho [signIn] cũ ở 6.x).
/// - Liên kết ID Token vào [FirebaseAuth.instance.signInWithCredential].
/// - Truy cập FirebaseAuth/GoogleSignIn dạng lazy để không gây lỗi khi chạy Unit Test độc lập.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    String? serverClientId,
  }) : _customAuth = auth,
       _customGoogleSignIn = googleSignIn,
       _serverClientId = serverClientId ?? _defaultWebClientId;

  /// Web Client ID từ google-services.json (client_type = 3).
  /// Cần thiết trên Android để Google cấp idToken cho Firebase và Backend.
  static const String _defaultWebClientId =
      '282372790467-mq0qns23moutlq1or6r400n8vdsbdhie.apps.googleusercontent.com';

  final FirebaseAuth? _customAuth;
  final GoogleSignIn? _customGoogleSignIn;
  final String _serverClientId;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn =>
      _customGoogleSignIn ?? GoogleSignIn.instance;

  bool get _hasFirebaseAuth =>
      _customAuth != null || (!kIsWeb && Firebase.apps.isNotEmpty);

  static bool _initialized = false;

  @override
  Stream<AuthResult?> get authStateChanges {
    if (!_hasFirebaseAuth) return const Stream<AuthResult?>.empty();
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final token = await user.getIdToken();
      return AuthResult.success(
        token: token,
        user: AuthUser(
          id: user.uid,
          email: user.email,
          name: user.displayName,
          avatarUrl: user.photoURL,
          authProvider: 'google',
        ),
      );
    });
  }

  /// Khởi tạo GoogleSignIn đúng một lần duy nhất.
  static Future<void> ensureInitialized({String? serverClientId}) async {
    if (_initialized || kIsWeb) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: serverClientId ?? _defaultWebClientId,
      );
      _initialized = true;
    } catch (error) {
      debugPrint('GoogleSignIn.initialize notice: $error');
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    if (kIsWeb) {
      return const AuthResult.failure(
        'Google Sign-In bằng Firebase hiện được cấu hình cho ứng dụng Android. Vui lòng chạy trên Android Emulator hoặc thiết bị Android.',
        code: 'WEB_NOT_CONFIGURED',
      );
    }

    try {
      await ensureInitialized(serverClientId: _serverClientId);

      // google_sign_in 7.2.0 sử dụng authenticate() thay thế signIn()
      final GoogleSignInAccount account = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication authTokens = account.authentication;
      final String? idToken = authTokens.idToken;

      if (idToken == null || idToken.isEmpty) {
        return const AuthResult.failure(
          'Không nhận được mã xác thực Google (ID Token rỗng).',
          code: 'EMPTY_ID_TOKEN',
        );
      }

      // Tạo Firebase credential từ Google ID Token
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      // Đăng nhập vào Firebase Authentication thật
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return const AuthResult.failure(
          'Không tìm thấy thông tin tài khoản Firebase sau khi đăng nhập.',
          code: 'NULL_FIREBASE_USER',
        );
      }

      final String? firebaseIdToken = await firebaseUser.getIdToken();

      final authUser = AuthUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? account.email,
        name: firebaseUser.displayName ?? account.displayName,
        avatarUrl: firebaseUser.photoURL ?? account.photoUrl,
        authProvider: 'google',
      );

      return AuthResult.success(token: firebaseIdToken, user: authUser);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const AuthResult.cancelled();
      }
      return AuthResult.failure(
        _formatGoogleSignInError(e),
        code: 'GOOGLE_SIGN_IN_ERROR',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_formatFirebaseAuthError(e), code: e.code);
    } catch (e) {
      return AuthResult.failure(
        'Đăng nhập Google thất bại: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  @override
  Future<AuthResult?> restoreSession() async {
    if (!_hasFirebaseAuth) return null;
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final token = await currentUser.getIdToken();
        final authUser = AuthUser(
          id: currentUser.uid,
          email: currentUser.email,
          name: currentUser.displayName,
          avatarUrl: currentUser.photoURL,
          authProvider: 'google',
        );
        return AuthResult.success(token: token, user: authUser);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    if (kIsWeb) return;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  @override
  Future<AuthResult> login({required String email, required String password}) {
    throw UnsupportedError(
      'FirebaseAuthService chỉ phục vụ Google Sign-In. Đăng nhập email dùng ApiAuthService.',
    );
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String birthDate,
    required String email,
    required String password,
  }) {
    throw UnsupportedError(
      'FirebaseAuthService chỉ phục vụ Google Sign-In. Đăng ký email dùng ApiAuthService.',
    );
  }

  @override
  Future<AuthResult> forgotPassword(String email) {
    throw UnsupportedError(
      'FirebaseAuthService chỉ phục vụ Google Sign-In. Quên mật khẩu dùng ApiAuthService.',
    );
  }

  String _formatGoogleSignInError(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Người dùng đã hủy chọn tài khoản Google.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Thao tác đăng nhập Google bị gián đoạn. Vui lòng thử lại.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Giao diện chọn tài khoản Google không khả dụng trên thiết bị.';
      default:
        final desc = e.description ?? e.toString();
        if (desc.contains('No credential available') ||
            desc.contains('No credentials available')) {
          return 'Thiết bị/máy ảo này chưa đăng nhập tài khoản Google nào. Vui lòng vào Cài đặt (Settings) của máy ảo để thêm tài khoản Google trước.';
        }
        return 'Lỗi đăng nhập Google: $desc';
    }
  }

  String _formatFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'Không có kết nối mạng. Vui lòng kiểm tra lại đường truyền của bạn.';
      case 'account-exists-with-different-credential':
        return 'Email này đã được sử dụng với một phương thức đăng nhập khác.';
      case 'invalid-credential':
        return 'Thông tin xác thực Google không hợp lệ hoặc đã hết hạn.';
      case 'user-disabled':
        return 'Tài khoản Google này đã bị vô hiệu hoá trong hệ thống.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập Google chưa được kích hoạt trên Firebase Console.';
      default:
        return e.message ?? 'Đăng nhập Firebase thất bại (${e.code}).';
    }
  }
}
