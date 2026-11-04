import '../models/usage_record.dart';

/// Interface định nghĩa các phương thức lấy lịch sử sử dụng AI API.
/// Tách biệt hoàn toàn để sau này có thể thay thế bằng ApiUsageHistoryService kết nối backend.
abstract class UsageHistoryService {
  /// Lấy danh sách bản ghi theo phân trang và bộ lọc.
  Future<List<UsageRecord>> getRecords({
    String? searchQuery,
    String? provider,
    String? timeRange,
    int offset = 0,
    int limit = 5,
  });

  /// Lấy tổng số lượng bản ghi thỏa mãn điều kiện lọc.
  Future<int> getTotalCount({
    String? searchQuery,
    String? provider,
    String? timeRange,
  });

  /// Lấy chi tiết một bản ghi theo ID.
  Future<UsageRecord?> getRecordById(String id);
}
