import 'package:flutter/foundation.dart';

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
/// ứng viên và các service gọi API thử lần lượt cho tới khi kết nối được.
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
