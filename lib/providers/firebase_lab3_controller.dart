import 'package:flutter/foundation.dart';

import '../models/in_app_notification.dart';
import '../services/firebase_analytics_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_crashlytics_service.dart';
import '../services/firebase_messaging_service.dart';
import '../services/firebase_remote_config_service.dart';
import '../services/firebase_storage_service.dart';

/// ViewModel boundary for all Lab 3 Firebase capabilities.
///
/// Screens depend on this controller instead of importing Firebase SDKs or
/// service singletons directly.
class FirebaseLab3Controller extends ChangeNotifier {
  FirebaseLab3Controller({
    FirebaseAnalyticsService? analytics,
    FirebaseCrashlyticsService? crashlytics,
    FirebaseMessagingService? messaging,
    FirebaseRemoteConfigService? remoteConfig,
    FirebaseStorageService? storage,
  }) : _analytics = analytics ?? FirebaseAnalyticsService.instance,
       _crashlytics = crashlytics ?? FirebaseCrashlyticsService.instance,
       _messaging = messaging ?? FirebaseMessagingService.instance,
       _remoteConfig = remoteConfig ?? FirebaseRemoteConfigService.instance,
       _storage = storage ?? FirebaseStorageService.instance {
    _messaging.notificationsNotifier.addListener(notifyListeners);
  }

  static final FirebaseLab3Controller instance = FirebaseLab3Controller();

  final FirebaseAnalyticsService _analytics;
  final FirebaseCrashlyticsService _crashlytics;
  final FirebaseMessagingService _messaging;
  final FirebaseRemoteConfigService _remoteConfig;
  final FirebaseStorageService _storage;

  Future<void> initialize({void Function(String screen)? onNavigate}) async {
    await FirebaseAuthService.ensureInitialized();
    await _crashlytics.initialize();
    await _remoteConfig.initialize();
    await _analytics.initialize();
    await _messaging.initialize(onNavigate: onNavigate);
  }

  void setNavigationHandler(void Function(String screen)? onNavigate) {
    _messaging.setNavigationHandler(onNavigate);
  }

  ValueListenable<List<InAppNotification>> get notifications =>
      _messaging.notificationsNotifier;

  String? get currentNotificationToken => _messaging.currentToken;

  bool get isNotificationAuthorized => _messaging.isAuthorized;

  Future<bool> requestNotificationPermission() async {
    final result = await _messaging.requestPermission();
    notifyListeners();
    return result;
  }

  Future<String?> fetchNotificationToken() async {
    final result = await _messaging.fetchDeviceToken();
    notifyListeners();
    return result;
  }

  void markAllNotificationsAsRead() => _messaging.markAllAsRead();

  void clearNotifications() => _messaging.clearAll();

  void simulateNotification() => _messaging.simulateNotification();

  bool get isPromoBannerEnabled => _remoteConfig.isPromoBannerEnabled;
  String get promoBannerText => _remoteConfig.promoBannerText;
  int get maxHistoryItems => _remoteConfig.maxHistoryItems;
  bool get isPdfExportEnabled => _remoteConfig.isPdfExportEnabled;

  Future<bool> refreshRemoteConfig() async {
    final updated = await _remoteConfig.refresh();
    notifyListeners();
    return updated;
  }

  Future<Uint8List> generatePdfReport({
    required String userName,
    required String userEmail,
    required int totalTokens,
    required double totalCost,
    required int requestCount,
    required List<Map<String, dynamic>> providers,
  }) {
    return _storage.generatePdfReport(
      userName: userName,
      userEmail: userEmail,
      totalTokens: totalTokens,
      totalCost: totalCost,
      requestCount: requestCount,
      providers: providers,
    );
  }

  Future<StorageUploadResult> uploadReportPdf({
    required Uint8List pdfBytes,
    void Function(double progress)? onProgress,
  }) {
    return _storage.uploadReportPdf(pdfBytes: pdfBytes, onProgress: onProgress);
  }

  Future<void> logLogin({required String method}) =>
      _analytics.logLogin(method: method);

  Future<void> setAnalyticsUserId(String userId) =>
      _analytics.setUserId(userId);

  Future<void> setCrashlyticsUserId(String userId) =>
      _crashlytics.setUserId(userId);

  Future<void> logLogout({String screen = 'settings'}) =>
      _analytics.logLogout(screen: screen);

  Future<void> logConnectProvider({
    required String providerType,
    required bool hasAdminKey,
  }) => _analytics.logConnectProvider(
    providerType: providerType,
    hasAdminKey: hasAdminKey,
  );

  Future<void> logViewUsageHistory({
    required int totalRecords,
    String filterProvider = 'all',
  }) => _analytics.logViewUsageHistory(
    totalRecords: totalRecords,
    filterProvider: filterProvider,
  );

  Future<void> logViewUsageDetail({
    required String model,
    required bool isSuccess,
    required int latencyMs,
  }) => _analytics.logViewUsageDetail(
    model: model,
    isSuccess: isSuccess,
    latencyMs: latencyMs,
  );

  Future<void> logExportReport({
    required String format,
    required int fileSizeBytes,
  }) =>
      _analytics.logExportReport(format: format, fileSizeBytes: fileSizeBytes);

  Future<void> logUpdateBudget({
    required bool hasLimit,
    required int warningPercent,
  }) => _analytics.logUpdateBudget(
    hasLimit: hasLimit,
    warningPercent: warningPercent,
  );

  Future<void> setCrashlyticsCustomKey(String key, Object value) =>
      _crashlytics.setCustomKey(key, value);

  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) =>
      _crashlytics.recordError(exception, stack, reason: reason, fatal: fatal);

  void triggerTestCrash() => _crashlytics.triggerTestCrash();

  @override
  void dispose() {
    _messaging.notificationsNotifier.removeListener(notifyListeners);
    super.dispose();
  }
}
