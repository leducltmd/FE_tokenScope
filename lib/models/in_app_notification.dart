/// Mô hình thông báo nội bộ ứng dụng nhận từ Firebase Cloud Messaging (FCM).
///
/// Tuân thủ Slide 11–13 của Lab 3: Lưu lịch sử thông báo và điều hướng khi chạm.
class InAppNotification {
  InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.targetScreen,
    this.data = const {},
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final String? targetScreen;
  final Map<String, dynamic> data;
  bool isRead;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'receivedAt': receivedAt.toIso8601String(),
    'targetScreen': targetScreen,
    'data': data,
    'isRead': isRead,
  };

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    return InAppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Thông báo mới',
      body: json['body']?.toString() ?? '',
      receivedAt:
          DateTime.tryParse(json['receivedAt']?.toString() ?? '') ??
          DateTime.now(),
      targetScreen: json['targetScreen']?.toString(),
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
      isRead: json['isRead'] == true,
    );
  }

  String get timeFormatted {
    final now = DateTime.now();
    final diff = now.difference(receivedAt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${receivedAt.day}/${receivedAt.month} ${receivedAt.hour}:${receivedAt.minute.toString().padLeft(2, '0')}';
  }
}
