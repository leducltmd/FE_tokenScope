/// Mô hình ngân sách thật từ backend (`GET /api/budgets`).
class BudgetOverview {
  const BudgetOverview({
    required this.periodLabel,
    required this.totalLimit,
    required this.threshold,
    required this.spent,
    required this.percent,
    required this.thresholdPercent,
    required this.providers,
    required this.projects,
    required this.forecast,
  });

  /// Nhãn chu kỳ — `01/11 - 30/11`.
  final String periodLabel;

  /// Hạn mức tổng (USD).
  final double totalLimit;

  /// Ngưỡng cảnh báo (USD).
  final double threshold;

  /// Chi phí đã dùng trong chu kỳ (USD).
  final double spent;

  /// Phần trăm đã dùng so với hạn mức tổng.
  final double percent;

  /// Phần trăm ngưỡng cảnh báo đã đạt.
  final double thresholdPercent;

  /// Hạn mức theo nhà cung cấp.
  final List<BudgetProviderUsage> providers;

  /// Hạn mức theo dự án.
  final List<BudgetProjectUsage> projects;

  /// Dự báo chi tiêu cuối chu kỳ (USD).
  final double forecast;

  /// Số tiền còn lại.
  double get remaining => totalLimit - spent;

  factory BudgetOverview.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>? ?? const {};
    final rawProviders = json['providers'];
    final rawProjects = json['projects'];
    return BudgetOverview(
      periodLabel: period['label'] as String? ?? '',
      totalLimit: (json['totalLimit'] as num?)?.toDouble() ?? 0,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0,
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
      thresholdPercent: (json['thresholdPercent'] as num?)?.toDouble() ?? 0,
      providers: rawProviders is List
          ? rawProviders
                .whereType<Map<String, dynamic>>()
                .map(BudgetProviderUsage.fromJson)
                .toList()
          : const <BudgetProviderUsage>[],
      projects: rawProjects is List
          ? rawProjects
                .whereType<Map<String, dynamic>>()
                .map(BudgetProjectUsage.fromJson)
                .toList()
          : const <BudgetProjectUsage>[],
      forecast: (json['forecast'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Hạn mức chi phí của một nhà cung cấp.
class BudgetProviderUsage {
  const BudgetProviderUsage({
    required this.providerType,
    required this.name,
    required this.models,
    required this.spent,
    required this.limit,
  });

  final String providerType;
  final String name;
  final String models;
  final double spent;
  final double limit;

  factory BudgetProviderUsage.fromJson(Map<String, dynamic> json) {
    return BudgetProviderUsage(
      providerType: json['providerType'] as String? ?? '',
      name: json['name'] as String? ?? '',
      models: json['models'] as String? ?? '',
      spent: (json['spent'] as num?)?.toDouble() ?? 0,
      limit: (json['limit'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Hạn mức chi phí của một dự án.
class BudgetProjectUsage {
  const BudgetProjectUsage({
    required this.id,
    required this.name,
    required this.models,
    required this.spent,
    required this.limit,
  });

  final String id;
  final String name;
  final String models;
  final double spent;
  final double limit;

  factory BudgetProjectUsage.fromJson(Map<String, dynamic> json) {
    return BudgetProjectUsage(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      models: json['models'] as String? ?? '',
      spent: (json['spent'] as num?)?.toDouble() ?? 0,
      limit: (json['limit'] as num?)?.toDouble() ?? 0,
    );
  }
}
