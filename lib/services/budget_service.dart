import '../models/budget_overview.dart';
import 'api_client.dart';

/// Nguồn dữ liệu ngân sách — mặc định gọi backend thật (`GET /api/budgets`).
abstract class BudgetService {
  /// Lấy số liệu ngân sách của chu kỳ hiện tại.
  Future<BudgetOverview> getOverview();
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
}
