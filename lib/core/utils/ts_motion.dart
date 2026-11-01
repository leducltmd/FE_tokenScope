import 'package:flutter/widgets.dart';

/// Chế độ chuyển động — cho phép tắt hiệu ứng lặp vô hạn khi chạy kiểm thử.
///
/// Các hiệu ứng nhấp nháy liên tục (chấm "Live", sóng đồng bộ) sẽ khiến
/// `pumpAndSettle` không bao giờ hoàn tất. Vì vậy trong môi trường test,
/// các hiệu ứng này được khoá ở trạng thái tĩnh.
abstract final class TsMotion {
  /// Cờ build tùy chọn — đặt qua `--dart-define=FLUTTER_TEST=true`.
  static const bool isTestFlag = bool.fromEnvironment('FLUTTER_TEST');

  /// Có nên chạy hiệu ứng chuyển động lặp hay không.
  ///
  /// Tự động tắt khi ứng dụng chạy trong `flutter test`.
  static bool get enabled {
    if (isTestFlag) return false;
    final binding = WidgetsBinding.instance;
    // `AutomatedTestWidgetsFlutterBinding` — tên lớp luôn chứa "Test".
    return !binding.runtimeType.toString().contains('Test');
  }
}
