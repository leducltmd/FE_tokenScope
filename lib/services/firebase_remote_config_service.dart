import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Dịch vụ quản lý cấu hình từ xa qua Firebase Remote Config.
///
/// Tuân thủ Slide 20–22 của Lab 3:
/// - Định nghĩa tối thiểu 2 tham số và giá trị mặc định.
/// - Tải và kích hoạt qua lớp dịch vụ riêng (fetchAndActivate).
/// - Liên kết trực tiếp với giao diện người dùng.
/// - Dự phòng giá trị mặc định khi mất kết nối mạng.
class FirebaseRemoteConfigService {
  FirebaseRemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig;

  final FirebaseRemoteConfig? _remoteConfig;

  static final FirebaseRemoteConfigService instance = FirebaseRemoteConfigService();

  FirebaseRemoteConfig get _instance =>
      _remoteConfig ?? FirebaseRemoteConfig.instance;

  // ── Khóa tham số cấu hình từ xa ──────────────────────────────────────────
  static const String keyPromoBannerEnabled = 'promo_banner_enabled';
  static const String keyPromoBannerText = 'promo_banner_text';
  static const String keyMaxHistoryItems = 'max_history_items';
  static const String keyEnablePdfExport = 'enable_pdf_export';

  // ── Giá trị mặc định khi chưa tải được từ Firebase ────────────────────────
  static const Map<String, dynamic> _defaults = {
    keyPromoBannerEnabled: false,
    keyPromoBannerText: 'TokenScope Pro: Đã hỗ trợ giám sát Google Gemini 2.5!',
    keyMaxHistoryItems: 20,
    keyEnablePdfExport: true,
  };

  static bool _isInitialized = false;

  bool get _hasFirebase => !kIsWeb && Firebase.apps.isNotEmpty;

  /// Khởi tạo và tải cấu hình từ xa.
  Future<void> initialize() async {
    if (!_hasFirebase || _isInitialized) return;

    try {
      // 1. Cấu hình thời gian chờ và tần suất fetch (ở chế độ phát triển để fetch ngay)
      await _instance.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(minutes: 1), // 1 phút để test demo nhanh
        ),
      );

      // 2. Thiết lập giá trị mặc định dự phòng khi mất mạng
      await _instance.setDefaults(_defaults);

      // 3. Tải và kích hoạt cấu hình từ xa
      await _instance.fetchAndActivate();
      _isInitialized = true;
      debugPrint('[RemoteConfig] Tải cấu hình thành công: '
          'promo_enabled=$isPromoBannerEnabled, text=$promoBannerText');
    } catch (e) {
      debugPrint('[RemoteConfig] Không thể tải cấu hình (dùng giá trị mặc định): $e');
    }
  }

  /// Làm mới cấu hình thủ công (ví dụ khi người dùng vuốt làm mới màn hình).
  Future<bool> refresh() async {
    if (!_hasFirebase) return false;
    try {
      return await _instance.fetchAndActivate();
    } catch (e) {
      debugPrint('[RemoteConfig] Lỗi khi làm mới: $e');
      return false;
    }
  }

  // ── Getters đọc tham số ────────────────────────────────────────────────
  /// Bật/tắt banner thông báo nổi bật trên Dashboard.
  bool get isPromoBannerEnabled {
    if (!_hasFirebase) return _defaults[keyPromoBannerEnabled] as bool;
    return _instance.getBool(keyPromoBannerEnabled);
  }

  /// Nội dung thông điệp banner từ xa.
  String get promoBannerText {
    if (!_hasFirebase) return _defaults[keyPromoBannerText] as String;
    final text = _instance.getString(keyPromoBannerText);
    return text.isNotEmpty ? text : _defaults[keyPromoBannerText] as String;
  }

  /// Số lượng bản ghi tối đa hiển thị trong Lịch sử.
  int get maxHistoryItems {
    if (!_hasFirebase) return _defaults[keyMaxHistoryItems] as int;
    final val = _instance.getInt(keyMaxHistoryItems);
    return val > 0 ? val : _defaults[keyMaxHistoryItems] as int;
  }

  /// Bật/tắt tính năng xuất báo cáo PDF.
  bool get isPdfExportEnabled {
    if (!_hasFirebase) return _defaults[keyEnablePdfExport] as bool;
    return _instance.getBool(keyEnablePdfExport);
  }
}
