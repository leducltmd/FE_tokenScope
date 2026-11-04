/// Mô hình một kết nối nhà cung cấp AI đã lưu trên backend.
///
/// Dữ liệu này đến từ API thật (`GET /api/providers`) — không có dữ liệu giả lập.
class ProviderConnection {
  const ProviderConnection({
    required this.id,
    required this.name,
    required this.providerType,
    required this.providerName,
    required this.letter,
    required this.status,
    required this.usageAvailable,
    required this.models,
    required this.totalTokens,
    required this.totalCost,
    required this.requestCount,
    this.maskedApiKey,
    this.maskedAdminApiKey,
    this.maskedWorkspaceId,
    this.lastCheckStatus,
    this.secretKeyStatus,
    this.adminKeyStatus,
    this.lastCheckedAt,
    this.lastSyncedAt,
  });

  /// ID kết nối (UUID) trên backend.
  final String id;

  /// Tên kết nối do người dùng đặt — "OpenAI Personal".
  final String name;

  /// Mã nhà cung cấp — `openai`, `anthropic`, `google`, `mistral`, `groq`.
  final String providerType;

  /// Tên hiển thị của nhà cung cấp — "OpenAI".
  final String providerName;

  /// Chữ cái hiển thị trong ô logo.
  final String letter;

  /// Trạng thái kết nối — `active` hoặc `error`.
  final String status;

  /// Nhà cung cấp có công bố API usage/billing hay không.
  final bool usageAvailable;

  /// Danh sách model đọc được từ nhà cung cấp.
  final List<String> models;

  /// API key đã che — `••••••••abcd`.
  final String? maskedApiKey;

  /// Admin API Key đã che (OpenAI / Anthropic) — `••••••••abcd`.
  ///
  /// `null` nghĩa là người dùng chưa cung cấp khoá quản trị tổ chức.
  final String? maskedAdminApiKey;

  /// Workspace ID của Anthropic đã che — `••••••••abcd`.
  ///
  /// `null` nghĩa là chưa cấu hình Workspace ID.
  final String? maskedWorkspaceId;

  /// Trạng thái kiểm tra gần nhất — `success`, `invalidKey`, ...
  final String? lastCheckStatus;

  /// Trạng thái Secret API Key (chỉ Anthropic) — kiểm tra độc lập.
  ///
  /// `connected` | `invalid` | `missingPermissions` | `missingWorkspace` | `missing`.
  final String? secretKeyStatus;

  /// Trạng thái Admin API Key (chỉ Anthropic) — kiểm tra độc lập.
  ///
  /// `connected` | `invalid` | `missingPermissions` | `missingWorkspace` | `missing`.
  final String? adminKeyStatus;

  /// Thời điểm kiểm tra gần nhất.
  final DateTime? lastCheckedAt;

  /// Thời điểm đồng bộ usage gần nhất.
  final DateTime? lastSyncedAt;

  /// Tổng token đã dùng (từ bảng usage_records).
  final int totalTokens;

  /// Tổng chi phí (USD).
  final double totalCost;

  /// Số lượt gọi đã ghi nhận.
  final int requestCount;

  /// Kết nối đang hoạt động.
  bool get isActive => status == 'active';

  /// Nhà cung cấp có dữ liệu usage/billing để đồng bộ.
  bool get hasUsageAccess =>
      usageAvailable && lastCheckStatus == 'success';

  factory ProviderConnection.fromJson(Map<String, dynamic> json) {
    final rawModels = json['models'];
    return ProviderConnection(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      providerType: json['providerType'] as String? ?? '',
      providerName: json['providerName'] as String? ?? '',
      letter: json['letter'] as String? ?? '?',
      status: json['status'] as String? ?? 'active',
      usageAvailable: json['usageAvailable'] as bool? ?? false,
      models: rawModels is List
          ? rawModels.map((m) => m.toString()).toList()
          : const <String>[],
      maskedApiKey: json['maskedApiKey'] as String?,
      maskedAdminApiKey: json['maskedAdminApiKey'] as String?,
      maskedWorkspaceId: json['maskedWorkspaceId'] as String?,
      lastCheckStatus: json['lastCheckStatus'] as String?,
      secretKeyStatus: json['secretKeyStatus'] as String?,
      adminKeyStatus: json['adminKeyStatus'] as String?,
      lastCheckedAt: _parseDate(json['lastCheckedAt']),
      lastSyncedAt: _parseDate(json['lastSyncedAt']),
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0,
      requestCount: (json['requestCount'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

/// Tổng quan nhà cung cấp trả về từ `GET /api/providers`.
class ProvidersOverview {
  const ProvidersOverview({
    required this.providers,
    required this.totalTokens,
    required this.totalCost,
    required this.requestCount,
    required this.connectedCount,
    this.totalLimit = 0,
  });

  final List<ProviderConnection> providers;
  final int totalTokens;
  final double totalCost;
  final int requestCount;
  final int connectedCount;

  /// Tổng hạn mức ngân sách đang áp dụng (USD).
  final double totalLimit;

  factory ProvidersOverview.fromJson(Map<String, dynamic> json) {
    final raw = json['providers'];
    final totals = json['totals'] as Map<String, dynamic>? ?? const {};
    return ProvidersOverview(
      providers: raw is List
          ? raw
                .whereType<Map<String, dynamic>>()
                .map(ProviderConnection.fromJson)
                .toList()
          : const <ProviderConnection>[],
      totalTokens: (totals['totalTokens'] as num?)?.toInt() ?? 0,
      totalCost: (totals['totalCost'] as num?)?.toDouble() ?? 0,
      requestCount: (totals['requestCount'] as num?)?.toInt() ?? 0,
      connectedCount: (totals['connectedCount'] as num?)?.toInt() ?? 0,
      totalLimit: (totals['totalLimit'] as num?)?.toDouble() ?? 0,
    );
  }
}
