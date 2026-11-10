import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'firebase_crashlytics_service.dart';

/// Lớp phía app trong luồng Crash Testing.
///
/// Vai trò:
/// 1. Đăng ký thiết bị với backend để Admin Web biết app đang chạy.
/// 2. Polling backend để nhận yêu cầu crash từ Admin Web.
/// 3. Khi nhận được yêu cầu → ghi nhận vào Crashlytics → kích hoạt crash
///    có chủ đích để test luồng báo cáo lỗi.
///
/// Lưu ý an toàn:
/// - Chỉ hoạt động khi backend trả về yêu cầu (tức là Admin đã bấm nút).
/// - Backend tự chặn ở môi trường production (`CRASH_TESTING_ENABLED`).
/// - Trên Web không kích hoạt crash vì Crashlytics không hỗ trợ web.
class CrashTestClient {
  CrashTestClient({
    ApiClient? client,
    FirebaseCrashlyticsService? crashlytics,
  }) : _client = client ?? ApiClient(),
       _crashlytics = crashlytics ?? FirebaseCrashlyticsService.instance;

  final ApiClient _client;
  final FirebaseCrashlyticsService _crashlytics;

  /// Khoá định danh thiết bị — sinh một lần rồi lưu lại trong bộ nhớ.
  late final String deviceId = _generateDeviceId();

  Timer? _pollTimer;

  /// Số giây giữa hai lần polling.
  static const Duration pollInterval = Duration(seconds: 5);

  /// Cờ đã khởi động hay chưa.
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  /// Khởi động: đăng ký thiết bị và bắt đầu polling.
  ///
  /// [userId] là id người dùng hiện tại (có thể null nếu chưa đăng nhập).
  Future<void> start({String? userId}) async {
    if (_isRunning) return;
    _isRunning = true;

    await _registerDevice(userId);

    _pollTimer = Timer.periodic(pollInterval, (_) => _poll());
  }

  /// Dừng polling (ví dụ khi app vào nền sâu).
  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isRunning = false;
  }

  /// Đăng ký thiết bị với backend.
  Future<void> _registerDevice(String? userId) async {
    try {
      await _client.post(
        '/crash-testing/devices',
        body: {
          'deviceId': deviceId,
          'userId': userId,
          'deviceName': _deviceName(),
          'platform': defaultTargetPlatform.name,
          'appVersion': '1.0.0+1',
        },
      );
    } on ApiException catch (error) {
      // Tính năng đang tắt ở backend hoặc thiết bị chưa được phép — im lặng.
      debugPrint('[CrashTest] Không đăng ký được thiết bị: ${error.message}');
    } catch (error) {
      debugPrint('[CrashTest] Lỗi đăng ký thiết bị: $error');
    }
  }

  /// Polling — lấy yêu cầu crash từ backend.
  Future<void> _poll() async {
    try {
      final data = await _client.get(
        '/crash-testing/poll',
        query: {'deviceId': deviceId},
      );

      final requests = data['requests'];
      if (requests is! List || requests.isEmpty) return;

      for (final raw in requests) {
        if (raw is! Map) continue;
        final id = raw['id']?.toString();
        if (id == null || id.isEmpty) continue;
        await _handleCrashRequest(id);
      }
    } on ApiException catch (error) {
      // 403 = tính năng bị tắt — dừng polling để không gọi lại liên tục.
      if (error.statusCode == 403) {
        debugPrint('[CrashTest] Tính năng bị tắt — dừng polling.');
        stop();
      }
    } catch (_) {
      // Bỏ qua lỗi mạng — lần polling sau sẽ thử lại.
    }
  }

  /// Xử lý một yêu cầu crash từ Admin Web.
  Future<void> _handleCrashRequest(String requestId) async {
    debugPrint('[CrashTest] Nhận yêu cầu crash: $requestId');

    // Báo "đã nhận lệnh" trước khi crash — backend chuyển sang `triggered`.
    await _report(requestId, 'triggered', 'Đã nhận lệnh từ Admin Web.');

    if (kIsWeb) {
      await _report(
        requestId,
        'failed',
        'Crashlytics không hỗ trợ nền tảng Web — không thể kích hoạt crash.',
      );
      return;
    }

    try {
      // Ghi nhận log Crashlytics kèm thông tin chẩn đoán trước khi crash.
      await _crashlytics.setCustomKey('crash_test_request_id', requestId);
      await _crashlytics.setCustomKey('crash_test_triggered', true);
      await _crashlytics.recordError(
        StateError('TokenScope Admin Crash Test — request $requestId'),
        StackTrace.current,
        reason: 'Admin Web yêu cầu kích hoạt crash có chủ đích để kiểm thử.',
        fatal: false,
      );
      await _report(
        requestId,
        'reported',
        'Đã ghi nhận log Crashlytics. Đang kích hoạt crash...',
      );
    } catch (error) {
      debugPrint('[CrashTest] Không ghi được log Crashlytics: $error');
    }

    // Cho backend vài nhịp để nhận báo cáo "reported" trước khi app chết.
    await Future<void>.delayed(const Duration(milliseconds: 800));

    // Kích hoạt crash có chủ đích — dừng ứng dụng ngay lập tức.
    _crashlytics.triggerTestCrash();

    // Dự phòng: nếu Crashlytics chưa được bật, vẫn crash để test luồng.
    throw StateError('TokenScope Admin Crash Test — request $requestId');
  }

  /// Báo cáo trạng thái lên backend.
  Future<void> _report(
    String requestId,
    String status,
    String? result,
  ) async {
    try {
      await _client.post(
        '/crash-testing/requests/$requestId/report',
        body: {
          'status': status,
          if (result != null) 'result': result,
        },
      );
    } catch (_) {
      // Bỏ qua — trạng thái cuối cùng vẫn được suy ra từ log backend.
    }
  }

  /// Sinh định danh thiết bị ổn định trong suốt phiên chạy app.
  String _generateDeviceId() {
    final random = Random();
    final suffix = List.generate(
      12,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return 'flutter-device-$suffix';
  }

  /// Tên thiết bị ước lượng để hiển thị trên Admin Web.
  String _deviceName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android Emulator / Device';
      case TargetPlatform.iOS:
        return 'iOS Device';
      case TargetPlatform.windows:
        return 'Windows Desktop';
      case TargetPlatform.macOS:
        return 'macOS Desktop';
      case TargetPlatform.linux:
        return 'Linux Desktop';
      case TargetPlatform.fuchsia:
        return 'Fuchsia Device';
    }
  }

  void dispose() {
    stop();
    _client.dispose();
  }
}
