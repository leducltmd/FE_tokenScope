import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/in_app_notification.dart';
import '../firebase_options.dart';
import 'notification_store.dart';

/// Hàm xử lý tin nhắn FCM chạy nền (Background / Terminated).
/// Phải là top-level function và được gắn @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM Background] Nhận tin nhắn ngầm ID: ${message.messageId}');
  debugPrint('[FCM Background] Tiêu đề: ${message.notification?.title}');
  debugPrint('[FCM Background] Dữ liệu: ${message.data}');

  final notification = _notificationFromMessage(message);
  final store = NotificationStore();
  final history = await store.load();
  history.insert(0, notification);
  await store.save(history);
}

InAppNotification _notificationFromMessage(RemoteMessage message) {
  return InAppNotification(
    id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title:
        message.notification?.title ??
        message.data['title']?.toString() ??
        'Thông báo mới',
    body:
        message.notification?.body ??
        message.data['body']?.toString() ??
        'Bạn có bản cập nhật mới từ TokenScope.',
    receivedAt: DateTime.now(),
    targetScreen: message.data['screen']?.toString(),
    data: message.data,
  );
}

/// Dịch vụ quản lý thông báo đẩy qua Firebase Cloud Messaging (FCM).
///
/// Tuân thủ Slide 11–13 của Lab 3:
/// - Xử lý đầy đủ 3 trạng thái:
///   1. Mở (Foreground): `onMessage`
///   2. Nền (Background): `onBackgroundMessage` & `onMessageOpenedApp`
///   3. Đã đóng (Terminated): `getInitialMessage`
/// - Yêu cầu quyền nhận thông báo trên Android 13+ (POST_NOTIFICATIONS).
/// - Lưu trữ lịch sử thông báo vào danh sách hiển thị trong ứng dụng.
/// - Ánh xạ thao tác chạm thông báo tới màn hình phù hợp.
/// - Cung cấp FCM Device Token để kiểm thử gửi từ Firebase Console.
class FirebaseMessagingService {
  FirebaseMessagingService({
    FirebaseMessaging? messaging,
    NotificationStore? store,
  }) : _messaging = messaging,
       _store = store ?? NotificationStore();

  final FirebaseMessaging? _messaging;
  final NotificationStore _store;

  FirebaseMessaging get _instance => _messaging ?? FirebaseMessaging.instance;

  static final FirebaseMessagingService instance = FirebaseMessagingService();

  /// Danh sách thông báo nội bộ nhận được (dùng ValueNotifier để UI tự cập nhật).
  final ValueNotifier<List<InAppNotification>> notificationsNotifier =
      ValueNotifier<List<InAppNotification>>([]);

  /// Token FCM của thiết bị hiện tại.
  String? currentToken;

  /// Quyền thông báo hiện tại.
  AuthorizationStatus? permissionStatus;

  bool get isAuthorized => permissionStatus == AuthorizationStatus.authorized;

  /// Callback chuyển trang khi người dùng chạm vào thông báo.
  void Function(String screen)? onNavigateCallback;
  String? _pendingNavigation;

  static bool _isInitialized = false;

  bool get _hasFirebase => !kIsWeb && Firebase.apps.isNotEmpty;

  /// Khởi tạo Firebase Messaging.
  Future<void> initialize({void Function(String screen)? onNavigate}) async {
    setNavigationHandler(onNavigate);
    if (!_hasFirebase || _isInitialized) return;

    try {
      // 1. Đăng ký background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // 2. Yêu cầu quyền trên Android 13+ và iOS
      await requestPermission();

      // 3. Lấy FCM Device Token
      await fetchDeviceToken();
      notificationsNotifier.value = await _store.load();

      // 4. Lắng nghe thông báo khi ứng dụng đang mở (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          '[FCM Foreground] Nhận thông báo: ${message.notification?.title}',
        );
        _handleIncomingMessage(message);
      });

      // 5. Xử lý khi người dùng chạm vào thông báo từ thanh trạng thái (Background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
          '[FCM Click] Mở từ background: ${message.notification?.title}',
        );
        _handleNotificationTap(message);
      });

      // 6. Xử lý khi ứng dụng được khởi chạy từ trạng thái Terminated (Đã đóng)
      final initialMessage = await _instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          '[FCM Terminated] Khởi chạy từ thông báo: ${initialMessage.notification?.title}',
        );
        _handleNotificationTap(initialMessage);
      }

      _isInitialized = true;
      debugPrint('[FCM] Khởi tạo dịch vụ thành công.');
    } catch (e) {
      debugPrint('[FCM] Khởi tạo thất bại: $e');
    }
  }

  /// Gắn handler sau khi MaterialApp đã sẵn sàng nhận route.
  void setNavigationHandler(void Function(String screen)? onNavigate) {
    onNavigateCallback = onNavigate;
    final pending = _pendingNavigation;
    if (pending != null && onNavigate != null) {
      _pendingNavigation = null;
      Future<void>.microtask(() => onNavigate(pending));
    }
  }

  /// Yêu cầu quyền nhận thông báo trên Android 13+.
  Future<bool> requestPermission() async {
    if (!_hasFirebase) return false;
    try {
      final settings = await _instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      permissionStatus = settings.authorizationStatus;
      debugPrint('[FCM] Trạng thái cấp quyền: ${settings.authorizationStatus}');
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('[FCM] Lỗi xin quyền thông báo: $e');
      return false;
    }
  }

  /// Lấy hoặc làm mới Device Token từ Firebase.
  Future<String?> fetchDeviceToken() async {
    if (!_hasFirebase) return null;
    try {
      // ignore: deprecated_member_use
      currentToken = await _instance.getToken();
      debugPrint('[FCM Token] $currentToken');

      // Lắng nghe khi token thay đổi
      // ignore: deprecated_member_use
      _instance.onTokenRefresh.listen((newToken) {
        currentToken = newToken;
        debugPrint('[FCM Token Refreshed] $newToken');
      });

      return currentToken;
    } catch (e) {
      debugPrint('[FCM] Không thể lấy Device Token: $e');
      return null;
    }
  }

  /// Xử lý tin nhắn đến và thêm vào danh sách thông báo.
  void _handleIncomingMessage(RemoteMessage message) {
    addNotification(_notificationFromMessage(message));
  }

  /// Xử lý thao tác chạm vào thông báo để điều hướng màn hình.
  void _handleNotificationTap(RemoteMessage message) {
    _handleIncomingMessage(message);
    final targetScreen = message.data['screen']?.toString() ?? 'alerts';
    final handler = onNavigateCallback;
    if (handler == null) {
      _pendingNavigation = targetScreen;
    } else {
      handler(targetScreen);
    }
  }

  /// Thêm thông báo vào danh sách lưu trữ trong app.
  void addNotification(InAppNotification notification) {
    final currentList = List<InAppNotification>.from(
      notificationsNotifier.value,
    );
    if (currentList.any((item) => item.id == notification.id)) return;
    currentList.insert(0, notification);
    notificationsNotifier.value = currentList;
    unawaited(_store.save(currentList));
  }

  /// Đánh dấu tất cả thông báo là đã đọc.
  void markAllAsRead() {
    final updated = notificationsNotifier.value.map((n) {
      n.isRead = true;
      return n;
    }).toList();
    notificationsNotifier.value = updated;
    unawaited(_store.save(updated));
  }

  /// Xóa toàn bộ thông báo.
  void clearAll() {
    notificationsNotifier.value = [];
    unawaited(_store.save(const []));
  }

  /// Giả lập một thông báo mẫu để trình diễn kiểm thử (Testing & Demo).
  ///
  /// Hữu ích khi chạy trên máy ảo chưa kích hoạt Google Play Services
  /// hoặc để demo trực tiếp luồng nhận thông báo và điều hướng theo yêu cầu Lab 3.
  void simulateNotification({
    String title = 'Cảnh báo ngân sách AI',
    String body = 'Chi phí gọi Google Gemini đạt ngưỡng 80% ngân sách tháng.',
    String screen = 'budget',
  }) {
    final simNotification = InAppNotification(
      id: 'sim_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      receivedAt: DateTime.now(),
      targetScreen: screen,
      data: {'screen': screen, 'source': 'simulated_lab3'},
    );

    addNotification(simNotification);
    debugPrint('[FCM Sim] Đã thêm thông báo giả lập: $title');
  }
}
