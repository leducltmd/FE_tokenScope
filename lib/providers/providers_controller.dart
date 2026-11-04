import 'package:flutter/foundation.dart';

import '../models/provider_connection.dart';
import '../services/provider_service.dart';

/// ViewModel quản lý danh sách nhà cung cấp AI đã kết nối.
///
/// Dữ liệu lấy từ backend thật (`GET /api/providers`) — không có dữ liệu giả lập.
class ProvidersController extends ChangeNotifier {
  ProvidersController({ProviderService? service})
    : _service = service ?? ApiProviderService();

  ProviderService _service;

  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isSyncing = false;

  List<ProviderConnection> _providers = const [];
  int _totalTokens = 0;
  double _totalCost = 0;
  int _requestCount = 0;
  double _totalLimit = 0;

  // ── Getters ──────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get isSyncing => _isSyncing;
  List<ProviderConnection> get providers => List.unmodifiable(_providers);
  int get totalTokens => _totalTokens;
  double get totalCost => _totalCost;
  int get requestCount => _requestCount;

  /// Tổng hạn mức ngân sách của các nhà cung cấp (USD).
  double get totalLimit => _totalLimit;
  bool get isEmpty => !_isLoading && !_hasError && _providers.isEmpty;

  /// Cho phép thay nguồn dữ liệu (ví dụ khi chuyển từ mock sang API thật).
  void useService(ProviderService service) {
    _service = service;
    loadProviders();
  }

  /// Tải danh sách nhà cung cấp từ backend.
  Future<void> loadProviders() async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final overview = await _service.getProviders();
      _providers = overview.providers;
      _totalTokens = overview.totalTokens;
      _totalCost = overview.totalCost;
      _requestCount = overview.requestCount;
      _totalLimit = overview.totalLimit;
      _hasError = false;
      _errorMessage = null;
    } catch (error) {
      _hasError = true;
      _errorMessage = error.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đồng bộ usage từ một nhà cung cấp cụ thể.
  Future<ProviderSyncResult> syncUsage(String providerId) async {
    _isSyncing = true;
    notifyListeners();

    try {
      final result = await _service.syncUsage(providerId);
      await loadProviders();
      return result;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Kiểm tra lại một kết nối đã lưu.
  Future<ProviderConnectionCheck> recheck(String providerId) async {
    try {
      final result = await _service.recheck(providerId);
      await loadProviders();
      return result;
    } catch (_) {
      rethrow;
    }
  }

  /// Xoá một kết nối.
  Future<void> deleteProvider(String providerId) async {
    await _service.delete(providerId);
    await loadProviders();
  }

  /// Đổi tên một kết nối.
  Future<void> renameProvider(String providerId, String name) async {
    await _service.rename(providerId, name);
    await loadProviders();
  }

  /// Cập nhật khoá của một kết nối — từng loại khoá độc lập.
  ///
  /// Chỉ trường được truyền lên mới thay đổi; các trường khác giữ nguyên.
  Future<ProviderConnection> updateProviderKeys(
    String providerId, {
    String? apiKey,
    String? adminApiKey,
    String? workspaceId,
    bool clearAdminApiKey = false,
  }) async {
    final provider = await _service.updateKeys(
      providerId,
      apiKey: apiKey,
      adminApiKey: adminApiKey,
      workspaceId: workspaceId,
      clearAdminApiKey: clearAdminApiKey,
    );
    await loadProviders();
    return provider;
  }
}
