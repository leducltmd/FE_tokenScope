import '../models/usage_record.dart';
import 'api_client.dart';
import 'usage_history_service.dart';

/// Triển khai gọi backend thật (`GET /api/usage/records`).
class ApiUsageHistoryService implements UsageHistoryService {
  ApiUsageHistoryService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Chuyển khoảng thời gian của UI thành mốc thời gian ISO để backend lọc.
  static DateTime? _fromFor(String? timeRange) {
    final now = DateTime.now();
    switch (timeRange) {
      case 'today':
        return DateTime(now.year, now.month, now.day);
      case '7days':
        return now.subtract(const Duration(days: 7));
      case '30days':
        return now.subtract(const Duration(days: 30));
      default:
        return null;
    }
  }

  /// Chuẩn hoá tên nhà cung cấp của UI về mã providerType của backend.
  static String? _providerTypeFor(String? provider) {
    if (provider == null || provider == 'all' || provider == 'Tất cả') {
      return null;
    }
    final value = provider.toLowerCase();
    if (value.contains('openai')) return 'openai';
    if (value.contains('gemini') || value.contains('google')) return 'google';
    if (value.contains('anthropic') || value.contains('claude')) {
      return 'anthropic';
    }
    if (value.contains('mistral')) return 'mistral';
    if (value.contains('groq')) return 'groq';
    return provider;
  }

  @override
  Future<List<UsageRecord>> getRecords({
    String? searchQuery,
    String? provider,
    String? timeRange,
    int offset = 0,
    int limit = 5,
  }) async {
    final from = _fromFor(timeRange);
    final data = await _client.get(
      '/usage/records',
      query: {
        if (searchQuery != null && searchQuery.trim().isNotEmpty)
          'search': searchQuery.trim(),
        if (_providerTypeFor(provider) != null)
          'providerType': _providerTypeFor(provider)!,
        if (from != null) 'from': from.toIso8601String(),
        'offset': '$offset',
        'limit': '$limit',
      },
    );

    final raw = data['records'];
    if (raw is! List) return const <UsageRecord>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(UsageRecord.fromJson)
        .toList();
  }

  @override
  Future<int> getTotalCount({
    String? searchQuery,
    String? provider,
    String? timeRange,
  }) async {
    final from = _fromFor(timeRange);
    final data = await _client.get(
      '/usage/records',
      query: {
        if (searchQuery != null && searchQuery.trim().isNotEmpty)
          'search': searchQuery.trim(),
        if (_providerTypeFor(provider) != null)
          'providerType': _providerTypeFor(provider)!,
        if (from != null) 'from': from.toIso8601String(),
        'offset': '0',
        'limit': '1',
      },
    );

    final total = data['total'];
    return total is num ? total.toInt() : 0;
  }

  @override
  Future<UsageRecord?> getRecordById(String id) async {
    try {
      final data = await _client.get('/usage/records/$id');
      final raw = data['record'];
      if (raw is Map<String, dynamic>) return UsageRecord.fromJson(raw);
      return null;
    } on ApiException {
      return null;
    }
  }
}
