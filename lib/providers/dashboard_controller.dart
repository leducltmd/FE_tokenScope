import 'package:flutter/foundation.dart';

import '../models/usage_summary.dart';
import '../services/api_client.dart';

/// Nguồn dữ liệu tổng quan (dashboard).
abstract class DashboardService {
  /// Lấy tổng hợp token & chi phí từ backend.
  Future<UsageSummary> getSummary();
}

/// Triển khai gọi backend thật (`GET /api/usage/summary`).
class ApiDashboardService implements DashboardService {
  ApiDashboardService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<UsageSummary> getSummary() async {
    final data = await _client.get('/usage/summary');
    return UsageSummary.fromJson(data);
  }
}

/// ViewModel cho màn hình tổng quan.
///
/// Lưu số liệu thật từ backend và xử lý trạng thái loading / lỗi.
class DashboardController extends ChangeNotifier {
  DashboardController({DashboardService? service})
    : _service = service ?? ApiDashboardService();

  DashboardService _service;

  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  UsageSummary? _summary;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  UsageSummary? get summary => _summary;

  /// Cho phép thay nguồn dữ liệu.
  void useService(DashboardService service) {
    _service = service;
    load();
  }

  /// Tải tổng hợp usage.
  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _service.getSummary();
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
}
