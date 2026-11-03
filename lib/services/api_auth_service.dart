import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// Cấu hình endpoint của backend TokenScope.
///
/// Backend chạy trên máy Windows host. Khi app chạy trên Android Emulator,
/// "localhost" trong máy ảo **không** trỏ về máy host, nên phải dùng alias
/// đặc biệt của từng loại emulator:
///
/// | Emulator                       | Host loopback |
/// | ------------------------------ | ------------- |
/// | Genymotion                     | `10.0.3.2`    |
/// | Android Studio Emulator        | `10.0.3.2`    |
/// | AVD dùng kernel QEMU cũ         | `10.0.2.2`    |
/// | `adb reverse tcp:3000 tcp:3000` | `127.0.0.1`   |
///
/// Vì mỗi loại emulator dùng một địa chỉ khác nhau, [ApiConfig] liệt kê các
/// ứng viên và [ApiAuthService] thử lần lượt cho tới khi kết nối được.
class ApiConfig {
  const ApiConfig({required this.urls});

  /// Ghi đè URL hoàn chỉnh qua `--dart-define=API_BASE_URL=...`.
  ///
  /// Không dùng được trong biểu thức `const` vì `String.fromEnvironment`
  /// chỉ cho phép so sánh với chuỗi hằng, nên việc chọn URL được thực
  /// hiện ở [resolve].
  static const String overrideBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static const int _port = 3000;
  static const String _path = '/api';

  /// Cổng mà backend TokenScope lắng nghe.
  static int get port => _port;

  /// Thời gian chờ tối đa cho một lần thử kết nối.
  ///
  /// Phải ngắn: mỗi ứng viên host được thử tuần tự, nên một timeout dài
  /// khiến người dùng phải chờ `số ứng viên × thời gian chờ` trước khi
  /// thấy thông báo lỗi. Với host đúng, phản hồi dưới 1 giây.
  static const Duration connectTimeout = Duration(seconds: 4);

  /// Thời gian chờ cho một request đã kết nối được (băm mật khẩu + ghi DB).
  static const Duration requestTimeout = Duration(seconds: 15);

  /// Ứng viên trên Android — xếp theo thứ tự ưu tiên thực tế.
  ///
  /// `10.0.2.2` (alias host của Android Studio AVD) vẫn được giữ lại vì đây là
  /// alias chuẩn của QEMU/AVD. Trên Genymotion địa chỉ này không bị từ chối
  /// kết nối mà bị rơi im lặng, nhưng bước dò nhanh ([ApiConfig.connectTimeout])
  /// bỏ qua nó sau vài giây nên không ảnh hưởng trải nghiệm.
  static const List<String> _androidHosts = <String>[
    '10.0.3.2',
    '10.0.2.2',
    '127.0.0.1',
    'localhost',
  ];

  /// Ứng viên trên Web/Desktop — cùng một máy nên `localhost` là đủ.
  static const List<String> _desktopHosts = <String>['localhost', '127.0.0.1'];

  static List<String> get _hosts {
    if (kIsWeb) return _desktopHosts;
    if (defaultTargetPlatform == TargetPlatform.android) return _androidHosts;
    return _desktopHosts;
  }

  /// Danh sách URL đầy đủ để thử, ứng viên đầu tiên là ưu tiên cao nhất.
  static List<String> resolve() {
    if (overrideBaseUrl.isNotEmpty) return <String>[overrideBaseUrl];
    return _hosts
        .map((h) => 'http://$h:$_port$_path')
        .toList(growable: false);
  }

  /// Các URL đầy đủ để thử lần lượt.
  final List<String> urls;

  static final ApiConfig instance = ApiConfig(urls: resolve());
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
    : _config = config ?? ApiConfig.instance,
      _client = client ?? http.Client();

  final ApiConfig _config;
  final http.Client _client;

  /// URL đang hoạt động — cập nhật sau khi tìm được host kết nối được.
  String get baseUrl => _activeUrl ?? _config.urls.first;

  String? _activeUrl;

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

  /// Dò xem host nào đang chạy backend.
  ///
  /// Gọi `/api/health` với timeout ngắn ([ApiConfig.connectTimeout]) trước khi
  /// gửi request thật. Nhờ vậy một host không phản hồi (địa chỉ bị rơi im
  /// lặng) chỉ mất vài giây thay vì phải chờ hết timeout của request.
  Future<bool> _isReachable(String baseUrl) async {
    // `baseUrl` thường đã kết thúc bằng `/api`, nên endpoint health là
    // `.../api/health` — tránh ghép thành `/api/api/health`.
    final healthUrl = baseUrl.endsWith('/api')
        ? '$baseUrl/health'
        : '$baseUrl/api/health';

    try {
      final response = await _client
          .get(Uri.parse(healthUrl))
          .timeout(ApiConfig.connectTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<AuthResult> _post(String path, Map<String, dynamic> body) async {
    final payload = jsonEncode(body);

    // Ưu tiên URL đã biết là hoạt động, sau đó thử lần lượt các ứng viên.
    final candidates = <String>[
      if (_activeUrl != null) _activeUrl!,
      ..._config.urls,
    ];

    final attempted = <String>[];

    for (final baseUrl in candidates) {
      attempted.add(baseUrl);

      // Dò nhanh trước: host treo im lặng sẽ bị bỏ qua sau vài giây thay vì
      // phải chờ hết timeout của request.
      if (!await _isReachable(baseUrl)) {
        continue;
      }

      final result = await _postTo(baseUrl, path, payload);
      if (result != null) {
        // Ghi nhớ host hoạt động để các lần gọi sau không phải dò lại.
        _activeUrl = baseUrl;
        return result;
      }
    }

    // Không host nào phản hồi được: đây là lỗi kết nối, không phải lỗi
    // xác thực. Báo rõ nguyên nhân thay vì đẩy lỗi kỹ thuật cho người dùng.
    return AuthResult.failure(
      'Không kết nối được tới máy chủ TokenScope.\n'
      'Đã thử: ${attempted.join(', ')}\n'
      'Hãy chắc chắn backend đang chạy (npm run dev trong thư mục BE_tokenScope) '
      'và cổng ${ApiConfig.port} thông.',
      code: 'CONNECTION_FAILED',
    );
  }

  /// Gửi request tới một URL cụ thể.
  ///
  /// Trả về `null` khi gặp lỗi mạng (để thử URL tiếp theo), trả về
  /// [AuthResult] khi đã có phản hồi từ server (kể cả lỗi 4xx/5xx).
  Future<AuthResult?> _postTo(
    String baseUrl,
    String path,
    String payload,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(ApiConfig.requestTimeout);

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
      return null;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }
}
