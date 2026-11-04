/// Số liệu phân tích thật từ backend (`GET /api/usage/analysis`).
class UsageAnalysis {
  const UsageAnalysis({
    required this.totalTokens,
    required this.totalCost,
    required this.requestCount,
    required this.inputTokens,
    required this.outputTokens,
    required this.inputRatio,
    required this.outputRatio,
    required this.weekly,
    required this.peak,
    required this.dailyAverage,
    required this.byProvider,
    required this.byModel,
  });

  /// Tổng token trong khoảng phân tích.
  final int totalTokens;

  /// Tổng chi phí (USD).
  final double totalCost;

  /// Số lượt gọi.
  final int requestCount;

  /// Tổng token đầu vào.
  final int inputTokens;

  /// Tổng token đầu ra.
  final int outputTokens;

  /// Tỷ lệ token đầu vào — `0.735`.
  final double inputRatio;

  /// Tỷ lệ token đầu ra — `0.265`.
  final double outputRatio;

  /// Chuỗi điểm theo ngày.
  final List<DailyAnalysisPoint> weekly;

  /// Điểm đỉnh trong khoảng phân tích.
  final DailyAnalysisPoint? peak;

  /// Trung bình token mỗi ngày.
  final int dailyAverage;

  /// Phân bổ theo nhà cung cấp.
  final List<ProviderAnalysis> byProvider;

  /// Mô hình dùng nhiều nhất.
  final List<ModelAnalysis> byModel;

  factory UsageAnalysis.fromJson(Map<String, dynamic> json) {
    final rawWeekly = json['weekly'];
    final rawProviders = json['byProvider'];
    final rawModels = json['byModel'];
    final rawPeak = json['peak'];

    return UsageAnalysis(
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0,
      requestCount: (json['requestCount'] as num?)?.toInt() ?? 0,
      inputTokens: (json['inputTokens'] as num?)?.toInt() ?? 0,
      outputTokens: (json['outputTokens'] as num?)?.toInt() ?? 0,
      inputRatio: (json['inputRatio'] as num?)?.toDouble() ?? 0,
      outputRatio: (json['outputRatio'] as num?)?.toDouble() ?? 0,
      weekly: rawWeekly is List
          ? rawWeekly
                .whereType<Map<String, dynamic>>()
                .map(DailyAnalysisPoint.fromJson)
                .toList()
          : const <DailyAnalysisPoint>[],
      peak: rawPeak is Map<String, dynamic>
          ? DailyAnalysisPoint.fromJson(rawPeak)
          : null,
      dailyAverage: (json['dailyAverage'] as num?)?.toInt() ?? 0,
      byProvider: rawProviders is List
          ? rawProviders
                .whereType<Map<String, dynamic>>()
                .map(ProviderAnalysis.fromJson)
                .toList()
          : const <ProviderAnalysis>[],
      byModel: rawModels is List
          ? rawModels
                .whereType<Map<String, dynamic>>()
                .map(ModelAnalysis.fromJson)
                .toList()
          : const <ModelAnalysis>[],
    );
  }
}

/// Một điểm dữ liệu theo ngày.
class DailyAnalysisPoint {
  const DailyAnalysisPoint({
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

  factory DailyAnalysisPoint.fromJson(Map<String, dynamic> json) {
    return DailyAnalysisPoint(
      date: json['date'] as String? ?? '',
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Phân bổ theo nhà cung cấp.
class ProviderAnalysis {
  const ProviderAnalysis({
    required this.providerType,
    required this.provider,
    required this.totalTokens,
    required this.totalCost,
    required this.requestCount,
  });

  final String providerType;
  final String provider;
  final int totalTokens;
  final double totalCost;
  final int requestCount;

  factory ProviderAnalysis.fromJson(Map<String, dynamic> json) {
    return ProviderAnalysis(
      providerType: json['providerType'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0,
      requestCount: (json['requestCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Số liệu của một mô hình AI.
class ModelAnalysis {
  const ModelAnalysis({
    required this.model,
    required this.provider,
    required this.providerType,
    required this.totalTokens,
    required this.totalCost,
    required this.requestCount,
  });

  final String model;
  final String provider;
  final String providerType;
  final int totalTokens;
  final double totalCost;
  final int requestCount;

  factory ModelAnalysis.fromJson(Map<String, dynamic> json) {
    return ModelAnalysis(
      model: json['model'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      providerType: json['providerType'] as String? ?? '',
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0,
      requestCount: (json['requestCount'] as num?)?.toInt() ?? 0,
    );
  }
}
