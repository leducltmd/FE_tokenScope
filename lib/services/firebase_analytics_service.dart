import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Dịch vụ theo dõi hành vi người dùng qua Firebase Analytics.
///
/// Tuân thủ Slide 14–16 của Lab 3 và tài liệu docs/analytics-plan.md:
/// - Định nghĩa đủ 7 sự kiện bắt buộc.
/// - Gắn User ID sau đăng nhập.
/// - Tuyệt đối không gửi thông tin cá nhân (PII) như email, họ tên vào tham số.
class FirebaseAnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics;

  final FirebaseAnalytics? _analytics;

  static final FirebaseAnalyticsService instance = FirebaseAnalyticsService();

  FirebaseAnalytics get _instance =>
      _analytics ?? FirebaseAnalytics.instance;

  static bool _isInitialized = false;

  bool get _hasFirebase => !kIsWeb && Firebase.apps.isNotEmpty;

  Future<void> initialize() async {
    if (!_hasFirebase || _isInitialized) return;
    try {
      await _instance.setAnalyticsCollectionEnabled(true);
      _isInitialized = true;
      debugPrint('[Analytics] Khởi tạo thành công.');
    } catch (e) {
      debugPrint('[Analytics] Khởi tạo thất bại: $e');
    }
  }

  /// Thiết lập User ID sau khi xác thực thành công.
  Future<void> setUserId(String userId) async {
    if (!_hasFirebase) return;
    try {
      await _instance.setUserId(id: userId);
    } catch (_) {}
  }

  /// Sự kiện 1: Đăng nhập (Khuyến nghị).
  Future<void> logLogin({required String method}) async {
    if (!_hasFirebase) return;
    try {
      await _instance.logLogin(loginMethod: method);
    } catch (_) {}
  }

  /// Sự kiện 2: Đăng xuất.
  Future<void> logLogout({String screen = 'settings'}) async {
    if (!_hasFirebase) return;
    try {
      await _instance.logEvent(
        name: 'logout',
        parameters: {'screen': screen},
      );
    } catch (_) {}
  }

  /// Sự kiện 3: Kết nối nhà cung cấp AI.
  Future<void> logConnectProvider({
    required String providerType,
    required bool hasAdminKey,
  }) async {
    if (!_hasFirebase) return;
    try {
      await _instance.logEvent(
        name: 'connect_provider',
        parameters: {
          'provider_type': providerType,
          'has_admin_key': hasAdminKey ? 1 : 0,
        },
      );
    } catch (_) {}
  }

  /// Sự kiện 4: Xem danh sách lịch sử sử dụng.
  Future<void> logViewUsageHistory({
    required int totalRecords,
    String filterProvider = 'all',
  }) async {
    if (!_hasFirebase) return;
    try {
      await _instance.logEvent(
        name: 'view_usage_history',
        parameters: {
          'total_records': totalRecords,
          'filter_provider': filterProvider,
        },
      );
    } catch (_) {}
  }

  /// Sự kiện 5: Xem chi tiết một bản ghi lượt gọi AI.
  Future<void> logViewUsageDetail({
    required String model,
    required bool isSuccess,
    required int latencyMs,
  }) async {
    if (!_hasFirebase) return;
    try {
      final bucket = latencyMs < 1000
          ? '<1s'
          : (latencyMs <= 3000 ? '1-3s' : '>3s');
      await _instance.logEvent(
        name: 'view_usage_detail',
        parameters: {
          'model': model,
          'is_success': isSuccess ? 1 : 0,
          'latency_bucket': bucket,
        },
      );
    } catch (_) {}
  }

  /// Sự kiện 6: Xuất báo cáo PDF.
  Future<void> logExportReport({
    required String format,
    required int fileSizeBytes,
  }) async {
    if (!_hasFirebase) return;
    try {
      await _instance.logEvent(
        name: 'export_report',
        parameters: {
          'format': format,
          'file_size_kb': (fileSizeBytes / 1024).round(),
          'storage_destination': 'firebase_storage',
        },
      );
    } catch (_) {}
  }

  /// Sự kiện 7: Cập nhật cấu hình ngân sách.
  Future<void> logUpdateBudget({
    required bool hasLimit,
    required int warningPercent,
  }) async {
    if (!_hasFirebase) return;
    try {
      await _instance.logEvent(
        name: 'update_budget',
        parameters: {
          'has_limit': hasLimit ? 1 : 0,
          'warning_percent': warningPercent,
        },
      );
    } catch (_) {}
  }
}
