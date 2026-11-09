/// Tổng hợp usage từ backend (`GET /api/usage/summary`).
class UsageSummary {
  const UsageSummary({
    required this.totalTokens,
    required this.totalCost,
    required this.requestCount,
    required this.byProvider,
    required this.daily,
    this.inputTokens,
    this.outputTokens,
  });

  /// Tổng token đã dùng.
  final int totalTokens;

  /// Phân rã token nếu backend cung cấp.
  final int? inputTokens;
  final int? outputTokens;

  /// Tổng chi phí (USD).
  final double totalCost;

  /// Tổng số lượt gọi.
  final int requestCount;

  /// Phân bổ theo từng nhà cung cấp.
  final List<ProviderUsageBreakdown> byProvider;

  /// Số liệu theo từng ngày (đã sắp xếp tăng dần).
  final List<DailyUsage> daily;

  factory UsageSummary.fromJson(Map<String, dynamic> json) {
    final providers = json['byProvider'];
    final days = json['daily'];
    return UsageSummary(
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      inputTokens: (json['inputTokens'] as num?)?.toInt(),
      outputTokens: (json['outputTokens'] as num?)?.toInt(),
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0,
      requestCount: (json['requestCount'] as num?)?.toInt() ?? 0,
      byProvider: providers is List
          ? providers
                .whereType<Map<String, dynamic>>()
                .map(ProviderUsageBreakdown.fromJson)
                .toList()
          : const <ProviderUsageBreakdown>[],
      daily: days is List
          ? days
                .whereType<Map<String, dynamic>>()
                .map(DailyUsage.fromJson)
                .toList()
          : const <DailyUsage>[],
    );
  }
}

/// Phân bổ token/chi phí của một nhà cung cấp.
class ProviderUsageBreakdown {
  const ProviderUsageBreakdown({
    required this.providerType,
    required this.provider,
    required this.totalTokens,
    required this.totalCost,
    required this.requestCount,
  });

  /// Mã nhà cung cấp — `openai`.
  final String providerType;

  /// Tên hiển thị — `OpenAI`.
  final String provider;

  /// Tổng token.
  final int totalTokens;

  /// Tổng chi phí (USD).
  final double totalCost;

  /// Số lượt gọi.
  final int requestCount;

  factory ProviderUsageBreakdown.fromJson(Map<String, dynamic> json) {
    return ProviderUsageBreakdown(
      providerType: json['providerType'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0,
      requestCount: (json['requestCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Số liệu usage của một ngày.
class DailyUsage {
  const DailyUsage({
    required this.date,
    required this.totalTokens,
    required this.totalCost,
  });

  /// Ngày theo định dạng `YYYY-MM-DD`.
  final String date;

  /// Tổng token trong ngày.
  final int totalTokens;

  /// Tổng chi phí trong ngày (USD).
  final double totalCost;

  factory DailyUsage.fromJson(Map<String, dynamic> json) {
    return DailyUsage(
      date: json['date'] as String? ?? '',
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0,
    );
  }
}
