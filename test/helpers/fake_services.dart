import 'package:tokenscope/models/usage_record.dart';
import 'package:tokenscope/models/usage_summary.dart';
import 'package:tokenscope/providers/dashboard_controller.dart';
import 'package:tokenscope/providers/usage_history_controller.dart';
import 'package:tokenscope/services/usage_history_service.dart';

/// Service tổng quan giả lập — trả về dữ liệu có cùng hình dạng với dữ liệu
/// thật từ backend (`GET /api/usage/summary`).
class FakeDashboardService implements DashboardService {
  @override
  Future<UsageSummary> getSummary() async {
    return UsageSummary(
      totalTokens: 2450000,
      inputTokens: 1800000,
      outputTokens: 650000,
      totalCost: 34.8,
      requestCount: 1482,
      byProvider: const [
        ProviderUsageBreakdown(
          providerType: 'openai',
          provider: 'OpenAI',
          totalTokens: 1200000,
          totalCost: 19.2,
          requestCount: 700,
        ),
        ProviderUsageBreakdown(
          providerType: 'google',
          provider: 'Google Gemini',
          totalTokens: 800000,
          totalCost: 7.4,
          requestCount: 500,
        ),
        ProviderUsageBreakdown(
          providerType: 'anthropic',
          provider: 'Anthropic Claude',
          totalTokens: 450000,
          totalCost: 8.2,
          requestCount: 282,
        ),
      ],
      daily: List.generate(
        7,
        (index) => DailyUsage(
          date: '2026-10-${(9 + index).toString().padLeft(2, '0')}',
          totalTokens: 180000 + index * 15000,
          totalCost: 2.5 + index,
        ),
      ),
    );
  }
}

/// Bản ghi mẫu dùng cho test — khớp với dữ liệu trả về từ backend.
UsageRecord buildTestUsageRecord({
  String id = 'rec_01hk8a92m4b',
  String provider = 'Anthropic Claude',
  String model = 'claude-3-5-sonnet',
  String project = 'Copilot Backend',
  int totalTokens = 1420,
  double cost = 0.0042,
}) {
  return UsageRecord(
    id: id,
    promptId: 'pmt_94821a0f',
    provider: provider,
    model: model,
    project: project,
    projectIconType: 'code',
    timestamp: DateTime(2026, 10, 15, 14, 28, 5),
    timeDisplay: '14:28:05',
    dateDisplay: 'Hôm nay (15/10)',
    inputTokens: totalTokens - 220,
    outputTokens: 220,
    totalTokens: totalTokens,
    cost: cost,
    latencyMs: 420,
    statusCode: 200,
    statusMessage: 'Thành công (200 OK)',
    isSuccess: true,
    promptPreview: 'Test',
    responsePreview: 'Test',
  );
}

/// Service lịch sử giả lập — trả về một bản ghi mẫu.
class FakeUsageHistoryService implements UsageHistoryService {
  FakeUsageHistoryService({this.records});

  /// Danh sách bản ghi trả về (mặc định một bản ghi mẫu).
  final List<UsageRecord>? records;

  @override
  Future<List<UsageRecord>> getRecords({
    String? searchQuery,
    String? provider,
    String? timeRange,
    int offset = 0,
    int limit = 5,
  }) async {
    final list = records ?? [buildTestUsageRecord()];
    if (offset >= list.length) return [];
    final end = (offset + limit < list.length) ? offset + limit : list.length;
    return list.sublist(offset, end);
  }

  @override
  Future<int> getTotalCount({
    String? searchQuery,
    String? provider,
    String? timeRange,
  }) async {
    return records?.length ?? 1;
  }

  @override
  Future<UsageRecord?> getRecordById(String id) async {
    final list = records ?? [buildTestUsageRecord()];
    for (final record in list) {
      if (record.id == id) return record;
    }
    return null;
  }
}

/// Tạo controller tổng quan dùng service giả lập.
DashboardController buildFakeDashboardController() {
  return DashboardController(service: FakeDashboardService());
}

/// Tạo controller lịch sử dùng service giả lập.
UsageHistoryController buildFakeHistoryController({
  List<UsageRecord>? records,
}) {
  return UsageHistoryController(
    service: FakeUsageHistoryService(records: records),
  );
}
