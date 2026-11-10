/// Mô hình dữ liệu cho bản ghi lịch sử gọi AI API (Usage Record).
class UsageRecord {
  const UsageRecord({
    required this.id,
    required this.promptId,
    required this.provider,
    required this.model,
    required this.project,
    required this.projectIconType,
    required this.timestamp,
    required this.timeDisplay,
    required this.dateDisplay,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
    required this.cost,
    this.currency = 'USD',
    required this.latencyMs,
    required this.statusCode,
    required this.statusMessage,
    required this.isSuccess,
    this.errorMessage,
    required this.promptPreview,
    required this.responsePreview,
    this.requestHeaders,
    this.apiEndpoint,
  });

  final String id;
  final String promptId;
  final String provider;
  final String model;
  final String project;
  final String projectIconType;
  final DateTime timestamp;
  final String timeDisplay;
  final String dateDisplay;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final double cost;
  final String currency;
  final int latencyMs;
  final int statusCode;
  final String statusMessage;
  final bool isSuccess;
  final String? errorMessage;
  final String promptPreview;
  final String responsePreview;
  final Map<String, String>? requestHeaders;
  final String? apiEndpoint;

  /// Định dạng giờ — `10:42:15`.
  static String _formatTime(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    final ss = value.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  /// Định dạng ngày — `Hôm nay (15/10)` hoặc `15/10/2026`.
  static String _formatDate(DateTime value) {
    final now = DateTime.now();
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final isToday =
        value.year == now.year && value.month == now.month && value.day == now.day;
    if (isToday) return 'Hôm nay ($dd/$mm)';
    if (value.year == now.year) return '$dd/$mm';
    return '$dd/$mm/${value.year}';
  }

  /// Định dạng số nguyên với dấu chấm ngăn cách hàng nghìn (chuẩn Việt Nam: 1.420).
  static String formatNumber(int number) {    final str = number.toString();
    final buffer = StringBuffer();
    final len = str.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  /// Định dạng token đầu vào: `1.420`
  String get formattedInputTokens => formatNumber(inputTokens);

  /// Định dạng token đầu ra: `580`
  String get formattedOutputTokens => formatNumber(outputTokens);

  /// Alias theo tên trường của backend (`promptTokens`).
  int get promptTokens => inputTokens;

  /// Alias theo tên trường của backend (`completionTokens`).
  int get completionTokens => outputTokens;

  /// Định dạng tổng token: `2.000`
  String get formattedTotalTokens => formatNumber(totalTokens);

  /// Định dạng chi phí theo USD (ví dụ: `$0.0150` hoặc `$0.0000`).
  String get formattedCost {
    return '\$${cost.toStringAsFixed(4)}';
  }

  /// Chuỗi thời gian đầy đủ: `10:42:15 - Hôm nay (15/10)`
  String get fullTimeDisplay => '$timeDisplay - $dateDisplay';

  /// Khởi tạo từ JSON (hỗ trợ chuyển sang API backend sau này).
  factory UsageRecord.fromJson(Map<String, dynamic> json) {
    final timestamp = json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
        : DateTime.now();

    // Backend không gửi `timeDisplay`/`dateDisplay` — tự suy ra từ timestamp.
    final timeDisplay =
        json['timeDisplay'] as String? ?? _formatTime(timestamp);
    final dateDisplay =
        json['dateDisplay'] as String? ?? _formatDate(timestamp);

    return UsageRecord(
      id: json['id'] as String? ?? '',
      promptId: json['promptId'] as String? ?? '',
      provider: json['provider'] as String? ?? 'OpenAI',
      model: json['model'] as String? ?? '',
      project: json['project'] as String? ?? 'General',
      projectIconType: json['projectIconType'] as String? ?? 'folder',
      timestamp: timestamp,
      timeDisplay: timeDisplay,
      dateDisplay: dateDisplay,
      inputTokens: (json['inputTokens'] as num?)?.toInt() ?? 0,
      outputTokens: (json['outputTokens'] as num?)?.toInt() ?? 0,
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      latencyMs: (json['latencyMs'] as num?)?.toInt() ?? 0,
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 200,
      statusMessage: json['statusMessage'] as String? ?? 'Thành công (200 OK)',
      isSuccess: json['isSuccess'] as bool? ?? true,
      errorMessage: json['errorMessage'] as String?,
      promptPreview: json['promptPreview'] as String? ?? '',
      responsePreview: json['responsePreview'] as String? ?? '',
      requestHeaders: (json['requestHeaders'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v.toString()),
      ),
      apiEndpoint: json['apiEndpoint'] as String?,
    );
  }

  /// Chuyển đổi sang JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'promptId': promptId,
      'provider': provider,
      'model': model,
      'project': project,
      'projectIconType': projectIconType,
      'timestamp': timestamp.toIso8601String(),
      'timeDisplay': timeDisplay,
      'dateDisplay': dateDisplay,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'totalTokens': totalTokens,
      'cost': cost,
      'currency': currency,
      'latencyMs': latencyMs,
      'statusCode': statusCode,
      'statusMessage': statusMessage,
      'isSuccess': isSuccess,
      'errorMessage': errorMessage,
      'promptPreview': promptPreview,
      'responsePreview': responsePreview,
      'requestHeaders': requestHeaders,
      'apiEndpoint': apiEndpoint,
    };
  }
}
