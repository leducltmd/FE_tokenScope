import 'package:flutter/foundation.dart';

import '../models/usage_record.dart';
import '../services/api_usage_history_service.dart';
import '../services/usage_history_service.dart';

/// ViewModel/Controller quản lý trạng thái của màn hình Lịch sử sử dụng (Usage History).
/// Tuân thủ mô hình MVVM của TokenScope: tách biệt logic và trạng thái khỏi giao diện UI.
class UsageHistoryController extends ChangeNotifier {
  UsageHistoryController({UsageHistoryService? service})
    : _service = service ?? ApiUsageHistoryService();

  UsageHistoryService _service;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _errorMessage;

  List<UsageRecord> _records = [];
  int _totalCount = 0;
  int _offset = 0;
  static const int _pageSize = 5;
  int _maxVisibleRecords = 20;

  String _searchQuery = '';
  String _selectedProvider = 'all'; // 'all', 'OpenAI', 'Gemini', 'Anthropic'
  String _selectedTimeRange = 'today'; // 'today', '7days', '30days'

  // ── Getters ──────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  List<UsageRecord> get records => List.unmodifiable(_records);
  int get totalCount => _totalCount;
  int get visibleCount => _records.length;
  bool get hasMore => _records.length < _totalCount;
  bool get isEmpty => !_isLoading && !_hasError && _records.isEmpty;

  String get searchQuery => _searchQuery;
  String get selectedProvider => _selectedProvider;
  String get selectedTimeRange => _selectedTimeRange;

  int get maxVisibleRecords => _maxVisibleRecords;

  void setMaxVisibleRecords(int value) {
    final next = value > 0 ? value : 20;
    if (_maxVisibleRecords == next) return;
    _maxVisibleRecords = next;
    if (_records.length > _maxVisibleRecords) {
      _records = _records.take(_maxVisibleRecords).toList();
      _offset = _records.length;
    }
    _totalCount = _totalCount > _maxVisibleRecords
        ? _maxVisibleRecords
        : _totalCount;
    notifyListeners();
  }

  /// Cho phép thay đổi service (ví dụ chuyển từ mock sang API backend thật khi sẵn sàng).
  void useService(UsageHistoryService service) {
    _service = service;
    loadRecords(refresh: true);
  }

  /// Tải danh sách bản ghi đầu tiên hoặc làm mới dữ liệu.
  Future<void> loadRecords({bool refresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    if (refresh) {
      _offset = 0;
    }
    notifyListeners();

    try {
      final total = await _service.getTotalCount(
        searchQuery: _searchQuery,
        provider: _selectedProvider,
        timeRange: _selectedTimeRange,
      );

      final fetched = await _service.getRecords(
        searchQuery: _searchQuery,
        provider: _selectedProvider,
        timeRange: _selectedTimeRange,
        offset: 0,
        limit: _pageSize < _maxVisibleRecords ? _pageSize : _maxVisibleRecords,
      );

      _records = fetched.take(_maxVisibleRecords).toList();
      _totalCount = total > _maxVisibleRecords ? _maxVisibleRecords : total;
      _offset = fetched.length;
      _hasError = false;
      _errorMessage = null;
    } catch (e) {
      _hasError = true;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _records = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tải thêm bản ghi (Phân trang khi người dùng nhấn "Tải thêm 20 bản ghi").
  Future<void> loadMore() async {
    if (_isLoadingMore ||
        _isLoading ||
        !hasMore ||
        _offset >= _maxVisibleRecords) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final remaining = _maxVisibleRecords - _offset;
      final more = await _service.getRecords(
        searchQuery: _searchQuery,
        provider: _selectedProvider,
        timeRange: _selectedTimeRange,
        offset: _offset,
        limit: remaining < 20 ? remaining : 20,
      );

      if (more.isNotEmpty) {
        _records = [..._records, ...more].take(_maxVisibleRecords).toList();
        _offset += more.length;
      }
    } catch (e) {
      // Giữ nguyên danh sách hiện tại nếu tải thêm thất bại
      _errorMessage = 'Không thể tải thêm bản ghi: ${e.toString()}';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Tìm kiếm theo từ khoá (prompt ID, model, tên dự án...).
  Future<void> setSearchQuery(String query) async {
    if (_searchQuery == query) return;
    _searchQuery = query;
    await loadRecords(refresh: true);
  }

  /// Lọc theo nhà cung cấp ('all', 'OpenAI', 'Gemini', 'Anthropic').
  Future<void> setProvider(String provider) async {
    if (_selectedProvider == provider) return;
    _selectedProvider = provider;
    await loadRecords(refresh: true);
  }

  /// Lọc theo khoảng thời gian ('today', '7days', '30days').
  Future<void> setTimeRange(String timeRange) async {
    if (_selectedTimeRange == timeRange) return;
    _selectedTimeRange = timeRange;
    await loadRecords(refresh: true);
  }

  /// Xóa toàn bộ bộ lọc và từ khóa tìm kiếm.
  Future<void> clearFilters() async {
    _searchQuery = '';
    _selectedProvider = 'all';
    _selectedTimeRange = 'today';
    await loadRecords(refresh: true);
  }

  /// Thử lại sau khi gặp lỗi.
  Future<void> retry() => loadRecords(refresh: true);
}
