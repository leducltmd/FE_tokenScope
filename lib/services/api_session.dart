/// Nơi lưu access token hiện tại để các service API khác dùng chung.
///
/// [AuthController] cập nhật token khi đăng nhập/đăng ký và xoá khi đăng xuất.
class ApiSession {
  ApiSession._();

  static final ApiSession instance = ApiSession._();

  String? _accessToken;

  /// Access token hiện tại (null nếu chưa đăng nhập).
  String? get accessToken => _accessToken;

  /// Gán access token mới.
  void setAccessToken(String? token) {
    _accessToken = token;
  }

  /// Xoá access token (đăng xuất).
  void clear() {
    _accessToken = null;
  }
}
