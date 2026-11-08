import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Dịch vụ quản lý sự cố và báo cáo lỗi qua Firebase Crashlytics.
///
/// Tuân thủ Slide 17–19 của Lab 3:
/// - Khởi tạo bộ xử lý lỗi Flutter & PlatformDispatcher.
/// - Ghi nhận lỗi không gây dừng app (non-fatal error).
/// - Gắn User ID và Custom Key chẩn đoán.
/// - Cung cấp nút gây crash có chủ đích trong khu vực trình diễn.
class FirebaseCrashlyticsService {
  FirebaseCrashlyticsService({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics;

  final FirebaseCrashlytics? _crashlytics;

  static final FirebaseCrashlyticsService instance = FirebaseCrashlyticsService();

  FirebaseCrashlytics get _instance =>
      _crashlytics ?? FirebaseCrashlytics.instance;

  static bool _isInitialized = false;

  bool get _hasFirebase => !kIsWeb && Firebase.apps.isNotEmpty;

  /// Khởi tạo tích hợp Crashlytics với Flutter framework.
  Future<void> initialize() async {
    if (!_hasFirebase || _isInitialized) return;

    try {
      // 1. Chuyển tất cả lỗi chưa bắt của Flutter framework tới Crashlytics
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        _instance.recordFlutterFatalError(details);
      };

      // 2. Chuyển tất cả lỗi bất đồng bộ không được bắt tới Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        _instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Bật thu thập Crashlytics khi ở debug/release
      await _instance.setCrashlyticsCollectionEnabled(true);
      _isInitialized = true;
      debugPrint('[Crashlytics] Khởi tạo thành công.');
    } catch (e) {
      debugPrint('[Crashlytics] Khởi tạo thất bại: $e');
    }
  }

  /// Gắn User ID vào báo cáo Crashlytics sau khi đăng nhập.
  Future<void> setUserId(String userId) async {
    if (!_hasFirebase) return;
    try {
      await _instance.setUserIdentifier(userId);
    } catch (_) {}
  }

  /// Gắn khoá chẩn đoán tuỳ chỉnh (Custom Key).
  Future<void> setCustomKey(String key, Object value) async {
    if (!_hasFirebase) return;
    try {
      if (value is String) {
        await _instance.setCustomKey(key, value);
      } else if (value is bool) {
        await _instance.setCustomKey(key, value);
      } else if (value is int) {
        await _instance.setCustomKey(key, value);
      } else if (value is double) {
        await _instance.setCustomKey(key, value);
      } else {
        await _instance.setCustomKey(key, value.toString());
      }
    } catch (_) {}
  }

  /// Ghi nhận lỗi không gây dừng ứng dụng (non-fatal error) từ luồng thực tế.
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    if (!_hasFirebase) return;
    try {
      await _instance.recordError(
        exception,
        stack,
        reason: reason,
        fatal: fatal,
      );
    } catch (_) {}
  }

  /// Kích hoạt cú crash thử nghiệm (Fatal Crash) có chủ đích cho buổi demo Lab 3.
  ///
  /// CẢNH BÁO: Thao tác này sẽ làm app dừng ngay lập tức để gửi log lên Crashlytics Console!
  void triggerTestCrash() {
    if (!_hasFirebase) return;
    if (kIsWeb) {
      throw StateError('Thử nghiệm Crashlytics trên nền tảng Web.');
    }
    _instance.crash();
  }
}
