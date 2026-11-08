import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/in_app_notification.dart';

/// Persistent local storage for FCM notifications.
///
/// This keeps the notification center available after a background or
/// terminated-message delivery. The store is deliberately independent from
/// the UI so it can also be used by the FCM background isolate.
class NotificationStore {
  static const _fileName = 'tokenscope_notifications.json';

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<List<InAppNotification>> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                InAppNotification.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<InAppNotification> notifications) async {
    try {
      final file = await _file();
      await file.writeAsString(
        jsonEncode(notifications.map((item) => item.toJson()).toList()),
      );
    } catch (_) {
      // Notification persistence must never prevent the app from starting.
    }
  }
}
