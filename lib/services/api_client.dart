import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_session.dart';

/// Lỗi HTTP từ backend TokenScope, mang theo mã lỗi để client xử lý.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code, this.details});

  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? details;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Client HTTP dùng chung cho các API của backend TokenScope.
///
/// - Tự dò host đang chạy backend (web / Android emulator / desktop).
/// - Tự gắn header `Authorization: Bearer <token>`.
/// - Chuẩn hoá lỗi thành [ApiException] với `statusCode` + `code` của backend.
class ApiClient {
  ApiClient({
    ApiConfig? config,
    http.Client? client,
    this.tokenProvider,
  }) : _config = config ?? ApiConfig.instance,
       _client = client ?? http.Client(),
       _tokenProvider = tokenProvider;

  final ApiConfig _config;
  final http.Client _client;

  /// Hàm lấy access token hiện tại — null nghĩa là chưa đăng nhập.
  ///
  /// Mặc định đọc từ [ApiSession] để mọi service dùng chung một token.
  final String? Function()? tokenProvider;

  final String? Function()? _tokenProvider;

  String? _currentToken() => _tokenProvider?.call() ?? ApiSession.instance.accessToken;

  /// URL đang hoạt động — cập nhật sau khi tìm được host kết nối được.
  String get baseUrl => _activeUrl ?? _config.urls.first;

  String? _activeUrl;

  void dispose() => _client.close();

  /// GET với query string.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    return _send('GET', path, query: query);
  }

  /// POST với body JSON.
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _send('POST', path, body: body);
  }

  /// PUT với body JSON.
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _send('PUT', path, body: body);
  }

  /// PATCH với body JSON.
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _send('PATCH', path, body: body);
  }

  /// DELETE.
  Future<Map<String, dynamic>> delete(String path) async {
    return _send('DELETE', path);
  }

  /// Thực hiện request tới backend, tự dò host nếu chưa biết host nào chạy.
  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final candidates = <String>[
      if (_activeUrl != null) _activeUrl!,
      ..._config.urls,
    ];

    final attempted = <String>[];

    for (final baseUrl in candidates) {
      attempted.add(baseUrl);

      if (!await _isReachable(baseUrl)) {
        continue;
      }

      try {
        final data = await _sendTo(baseUrl, method, path, body: body, query: query);
        _activeUrl = baseUrl;
        return data;
      } on ApiException catch (error) {
        // Backend đã phản hồi → không thử host khác nữa.
        if (error.statusCode == null) rethrow;
        rethrow;
      } catch (_) {
        // Lỗi mạng → thử URL tiếp theo.
        continue;
      }
    }

    throw ApiException(
      'Không kết nối được tới máy chủ TokenScope.\n'
      'Đã thử: ${attempted.join(', ')}\n'
      'Hãy chắc chắn backend đang chạy (npm run dev trong thư mục BE_tokenScope) '
      'và cổng ${ApiConfig.port} thông.',
      code: 'CONNECTION_FAILED',
    );
  }

  /// Dò nhanh xem host nào đang chạy backend.
  Future<bool> _isReachable(String baseUrl) async {
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

  /// Gửi request tới một URL cụ thể.
  Future<Map<String, dynamic>> _sendTo(
    String baseUrl,
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);

    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = _currentToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final encoded = body == null ? null : jsonEncode(body);

    final response = switch (method) {
      'GET' => await _client.get(uri, headers: headers),
      'POST' => await _client.post(uri, headers: headers, body: encoded),
      'PUT' => await _client.put(uri, headers: headers, body: encoded),
      'PATCH' => await _client.patch(uri, headers: headers, body: encoded),
      'DELETE' => await _client.delete(uri, headers: headers),
      _ => throw ApiException('Phương thức HTTP không được hỗ trợ: $method'),
    };

    final text = response.body;
    Map<String, dynamic> data = {};
    if (text.isNotEmpty) {
      try {
        final decoded = jsonDecode(text);
        data = decoded is Map<String, dynamic> ? decoded : {'data': decoded};
      } catch (_) {
        data = {'message': text};
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final details = data['details'];
    throw ApiException(
      (data['message'] ?? 'Không thể xử lý yêu cầu.').toString(),
      statusCode: response.statusCode,
      code: data['code'] as String?,
      details: details is Map<String, dynamic> ? details : null,
    );
  }
}
