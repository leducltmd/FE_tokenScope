/// Mô hình dữ liệu hiển thị cho màn hình tổng quan của TokenScope.
///
/// Các lớp này là lớp trình bày (presentation) — không phụ thuộc Prisma
/// hay HTTP, giúp giao diện dựng được với dữ liệu mẫu và dễ kiểm thử.
library;

/// Nhà cung cấp API đang kết nối.
class ProviderSummary {
  const ProviderSummary({
    required this.name,
    required this.status,
    required this.modelCount,
    required this.costToday,
    this.logoLetter,
    this.logoColor,
  });

  final String name;
  final String status;
  final int modelCount;
  final String costToday;
  final String? logoLetter;
  final int? logoColor;
}

/// Tổng hợp lượng token trong ngày.
class TokenSummary {
  const TokenSummary({
    required this.total,
    required this.input,
    required this.output,
  });

  final int total;
  final int input;
  final int output;
}

/// Tiến độ ngân sách tháng.
class BudgetSummary {
  const BudgetSummary({
    required this.title,
    required this.spent,
    required this.limit,
    required this.percentUsed,
    this.remaining,
  });

  final String title;
  final String spent;
  final String limit;
  final int percentUsed;
  final String? remaining;
}

/// Một điểm trong biểu đồ cột.
class UsagePoint {
  const UsagePoint({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  final String label;
  final int value;
  final bool isHighlighted;
}

/// Một bản ghi sử dụng gần đây.
class UsageLogEntry {
  const UsageLogEntry({
    required this.model,
    required this.provider,
    required this.tokens,
    required this.cost,
    required this.time,
    this.isSuccess = true,
  });

  final String model;
  final String provider;
  final int tokens;
  final String cost;
  final String time;
  final bool isSuccess;
}
