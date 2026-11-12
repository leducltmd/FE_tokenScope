import '../models/budget_overview.dart';
import 'api_client.dart';

/// Nguồn dữ liệu ngân sách — mặc định gọi backend thật (`GET /api/budgets`).
abstract class BudgetService {
  /// Lấy số liệu ngân sách của chu kỳ hiện tại.
  Future<BudgetOverview> getOverview();

  /// Cập nhật hạn mức ngân sách và ngưỡng cảnh báo lên backend.
  Future<BudgetOverview> updateBudget({
    required double totalLimit,
    double warningPercent = 80,
  });
}

/// Triển khai gọi backend thật.
class ApiBudgetService implements BudgetService {
  ApiBudgetService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<BudgetOverview> getOverview() async {
    final data = await _client.get('/budgets');
    return BudgetOverview.fromJson(data);
  }

  @override
  Future<BudgetOverview> updateBudget({
    required double totalLimit,
    double warningPercent = 80,
  }) async {
    final data = await _client.put(
      '/budgets',
      body: {
        'totalLimit': totalLimit,
        'warningPercent': warningPercent,
      },
    );
    return BudgetOverview.fromJson(data);
  }
}
