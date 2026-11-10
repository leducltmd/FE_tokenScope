import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Lớp ghi nhận sự kiện sử dụng ứng dụng gửi về backend TokenScope.
///
/// Mục đích: cung cấp cho Admin Web dữ liệu "lượt sử dụng ứng dụng" và
/// "số người dùng đang hoạt động" — dữ liệu tương đương với Firebase
/// Analytics nhưng lưu trong database của TokenScope nên Admin Web đọc
/// trực tiếp được.
///
/// Lớp này **không** thay thế Firebase Analytics: cả hai cùng tồn tại,
/// Firebase Analytics dùng cho phân tích hành vi, còn service này dùng cho
/// bảng quản trị.
class AppUsageService {
  AppUsageService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Id phiên làm việc hiện tại — gom nhóm sự kiện theo từng lần mở app.
  String? _sessionId;

  /// Người dùng hiện tại (dùng để gắn userId vào sự kiện).
  String? _userId;

  /// Cờ đã ghi nhận sự kiện `app_open` cho phiên hiện tại.
  bool _hasLoggedOpen = false;

  /// Cờ đã gắn userId cho sự kiện `app_open` của phiên hiện tại.
  bool _hasLinkedUser = false;

  String? get sessionId => _sessionId;

  /// Bắt đầu phiên sử dụng mới (gọi khi app khởi động hoặc đăng nhập).
  void startSession({String? userId}) {
    _sessionId = 'sess-${DateTime.now().millisecondsSinceEpoch}';
    _userId = userId;
    _hasLoggedOpen = false;
    _hasLinkedUser = userId != null;
  }

  /// Gắn userId hiện tại (gọi sau khi đăng nhập thành công).
  ///
  /// Nếu sự kiện `app_open` đã được ghi nhận **trước khi đăng nhập** (app
  /// khởi động khi người dùng chưa có phiên), backend sẽ gắn userId vào
  /// chính bản ghi cũ — không tạo bản ghi mới nên số lượt mở ứng dụng
  /// không bị tính trùng.
  Future<void> setUserId(String? userId) async {
    _userId = userId;

    if (userId != null && _hasLoggedOpen && !_hasLinkedUser) {
      _hasLinkedUser = true;
      await _claimOrphanEvents();
    }
  }

  /// Yêu cầu backend gắn userId cho các sự kiện đã ghi trước khi đăng nhập.
  Future<void> _claimOrphanEvents() async {
    try {
      await _client.post(
        '/app-usage/claim',
        body: {
          if (_sessionId != null) 'sessionId': _sessionId,
          'eventName': 'app_open',
        },
      );
    } on ApiException catch (error) {
      debugPrint('[AppUsage] Không gắn được userId cho sự kiện: ${error.message}');
    } catch (error) {
      debugPrint('[AppUsage] Lỗi khi gắn userId cho sự kiện: $error');
    }
  }

  /// Ghi nhận lượt mở ứng dụng — chỉ ghi một lần cho mỗi phiên.
  Future<void> logAppOpen({String? platform, String? appVersion}) async {
    if (_hasLoggedOpen) return;
    _hasLoggedOpen = true;
    await _send(
      eventName: 'app_open',
      platform: platform,
      appVersion: appVersion,
    );
  }

  /// Ghi nhận sự kiện app bị đưa vào nền.
  Future<void> logAppPause() => _send(eventName: 'app_pause');

  /// Ghi nhận sự kiện app trở lại foreground.
  Future<void> logAppResume() => _send(eventName: 'app_resume');

  /// Ghi nhận sự kiện app đóng hẳn.
  Future<void> logAppClose() => _send(eventName: 'app_close');

  /// Ghi nhận người dùng đã dùng một tính năng trong ứng dụng.
  ///
  /// Tham số [feature] dùng để thống kê "sự kiện sử dụng tính năng" trong
  /// Admin Web (ví dụ: `connect_provider`, `export_report`, `view_usage`).
  Future<void> logFeatureUsage(
    String feature, {
    String? screen,
    Map<String, Object?>? metadata,
  }) {
    return _send(
      eventName: 'feature_usage',
      feature: feature,
      screen: screen,
      metadata: metadata,
    );
  }

  /// Ghi nhận lượt xem một màn hình.
  Future<void> logScreenView(String screen) {
    return _send(eventName: 'screen_view', screen: screen);
  }

  /// Gửi một sự kiện lên backend.
  ///
  /// Mọi lỗi đều bị nuốt — ghi nhận thống kê không được làm hỏng app.
  Future<void> _send({
    required String eventName,
    String? feature,
    String? screen,
    String? platform,
    String? appVersion,
    Map<String, Object?>? metadata,
  }) async {
    try {
      await _client.post(
        '/app-usage/events',
        body: {
          'eventName': eventName,
          if (feature != null) 'feature': feature,
          if (screen != null) 'screen': screen,
          if (_sessionId != null) 'sessionId': _sessionId,
          if (_userId != null) 'userId': _userId,
          if (platform != null) 'platform': platform,
          if (appVersion != null) 'appVersion': appVersion,
          if (metadata != null && metadata.isNotEmpty)
            'metadata': metadata.map(
              (key, value) => MapEntry(key, value?.toString()),
            ),
        },
      );
    } on ApiException catch (error) {
      debugPrint('[AppUsage] Không gửi được sự kiện "$eventName": ${error.message}');
    } catch (error) {
      debugPrint('[AppUsage] Lỗi khi gửi sự kiện "$eventName": $error');
    }
  }

  void dispose() => _client.dispose();
}
