import 'package:flutter/foundation.dart';

import '../models/budget_overview.dart';
import '../services/budget_service.dart';

/// ViewModel quản lý số liệu ngân sách.
///
/// Dữ liệu lấy từ backend thật (`GET /api/budgets`) — không có dữ liệu giả lập.
class BudgetController extends ChangeNotifier {
  BudgetController({BudgetService? service})
    : _service = service ?? ApiBudgetService();

  BudgetService _service;

  bool _isLoading = false;
  bool _isDisposed = false;
  bool _hasError = false;
  String? _errorMessage;
  BudgetOverview? _overview;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  BudgetOverview? get overview => _overview;

  /// Cho phép thay nguồn dữ liệu.
  void useService(BudgetService service) {
    _service = service;
    load();
  }

  /// Tải số liệu ngân sách từ backend.
  Future<void> load() async {
    if (_isLoading || _isDisposed) return;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      _overview = await _service.getOverview();
      _hasError = false;
      _errorMessage = null;
    } catch (error) {
      _hasError = true;
      _errorMessage = error.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  /// Cập nhật hạn mức ngân sách và ngưỡng cảnh báo lên backend.
  Future<bool> updateBudget({
    required double totalLimit,
    double warningPercent = 80,
  }) async {
    if (_isDisposed) return false;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      _overview = await _service.updateBudget(
        totalLimit: totalLimit,
        warningPercent: warningPercent,
      );
      _hasError = false;
      _errorMessage = null;
      return true;
    } catch (error) {
      _hasError = true;
      _errorMessage = error.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
