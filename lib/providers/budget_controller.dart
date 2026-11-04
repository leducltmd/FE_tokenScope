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
    if (_isLoading) return;
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
      notifyListeners();
    }
  }
}
