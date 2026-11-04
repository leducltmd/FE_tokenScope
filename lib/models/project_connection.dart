/// Mô hình một dự án kèm số liệu usage thật từ backend (`GET /api/projects`).
class ProjectConnection {
  const ProjectConnection({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.environment,
    required this.totalTokens,
    required this.totalCost,
    required this.requestCount,
    required this.monthlyLimit,
    required this.budgetPercent,
    required this.systemSharePercent,
    required this.models,
  });

  /// ID dự án (UUID) trên backend.
  final String id;

  /// Tên dự án.
  final String name;

  /// Mô tả dự án.
  final String? description;

  /// Mã màu định dạng `#RRGGBB`.
  final String color;

  /// Môi trường triển khai — Production / Staging / Internal.
  final String environment;

  /// Tổng token đã dùng.
  final int totalTokens;

  /// Tổng chi phí đã dùng (USD).
  final double totalCost;

  /// Số lượt gọi.
  final int requestCount;

  /// Hạn mức ngân sách (USD) — `null` nếu chưa đặt.
  final double? monthlyLimit;

  /// Phần trăm hạn mức đã dùng.
  final double budgetPercent;

  /// Phần trăm token so với toàn hệ thống.
  final double systemSharePercent;

  /// Các mô hình AI đã dùng trong dự án.
  final List<ProjectModelUsage> models;

  factory ProjectConnection.fromJson(Map<String, dynamic> json) {
    final rawModels = json['models'];
    return ProjectConnection(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      color: json['color'] as String? ?? '#6366F1',
      environment: json['environment'] as String? ?? 'Production',
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0,
      requestCount: (json['requestCount'] as num?)?.toInt() ?? 0,
      monthlyLimit: (json['monthlyLimit'] as num?)?.toDouble(),
      budgetPercent: (json['budgetPercent'] as num?)?.toDouble() ?? 0,
      systemSharePercent:
          (json['systemSharePercent'] as num?)?.toDouble() ?? 0,
      models: rawModels is List
          ? rawModels
                .whereType<Map<String, dynamic>>()
                .map(ProjectModelUsage.fromJson)
                .toList()
          : const <ProjectModelUsage>[],
    );
  }
}

/// Một mô hình AI được dùng trong dự án.
class ProjectModelUsage {
  const ProjectModelUsage({
    required this.provider,
    required this.model,
    required this.totalTokens,
  });

  /// Tên nhà cung cấp.
  final String provider;

  /// Tên mô hình.
  final String model;

  /// Tổng token của mô hình trong dự án.
  final int totalTokens;

  factory ProjectModelUsage.fromJson(Map<String, dynamic> json) {
    return ProjectModelUsage(
      provider: json['provider'] as String? ?? '',
      model: json['model'] as String? ?? '',
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Tổng quan dự án trả về từ `GET /api/projects`.
class ProjectsOverview {
  const ProjectsOverview({
    required this.projects,
    required this.totalTokens,
    required this.totalCost,
    required this.requestCount,
    required this.projectCount,
  });

  final List<ProjectConnection> projects;
  final int totalTokens;
  final double totalCost;
  final int requestCount;
  final int projectCount;

  factory ProjectsOverview.fromJson(Map<String, dynamic> json) {
    final raw = json['projects'];
    final totals = json['totals'] as Map<String, dynamic>? ?? const {};
    return ProjectsOverview(
      projects: raw is List
          ? raw
                .whereType<Map<String, dynamic>>()
                .map(ProjectConnection.fromJson)
                .toList()
          : const <ProjectConnection>[],
      totalTokens: (totals['totalTokens'] as num?)?.toInt() ?? 0,
      totalCost: (totals['totalCost'] as num?)?.toDouble() ?? 0,
      requestCount: (totals['requestCount'] as num?)?.toInt() ?? 0,
      projectCount: (totals['projectCount'] as num?)?.toInt() ?? 0,
    );
  }
}
