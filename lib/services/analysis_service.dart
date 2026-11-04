import '../models/usage_analysis.dart';
import 'api_client.dart';

/// Nguồn dữ liệu phân tích — mặc định gọi backend thật
/// (`GET /api/usage/analysis`).
abstract class AnalysisService {
  /// Lấy số liệu phân tích trong `days` ngày gần nhất.
  Future<UsageAnalysis> getAnalysis({int days = 7});
}

/// Triển khai gọi backend thật.
class ApiAnalysisService implements AnalysisService {
  ApiAnalysisService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<UsageAnalysis> getAnalysis({int days = 7}) async {
    final data = await _client.get('/usage/analysis', query: {'days': '$days'});
    return UsageAnalysis.fromJson(data);
  }
}
