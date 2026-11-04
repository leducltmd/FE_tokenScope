import 'package:flutter/foundation.dart';

import '../models/usage_analysis.dart';
import '../services/analysis_service.dart';

/// ViewModel cho màn hình "Phân tích sử dụng AI".
///
/// Dữ liệu lấy từ backend thật (`GET /api/usage/analysis`) — không có dữ liệu
/// giả lập.
class AnalysisController extends ChangeNotifier {
  AnalysisController({AnalysisService? service})
    : _service = service ?? ApiAnalysisService();

  AnalysisService _service;

  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  UsageAnalysis? _analysis;

  /// Số ngày đang phân tích.
  int _days = 7;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  UsageAnalysis? get analysis => _analysis;
  int get days => _days;

  /// Cho phép thay nguồn dữ liệu.
  void useService(AnalysisService service) {
    _service = service;
    load();
  }

  /// Đổi khoảng thời gian phân tích rồi tải lại.
  Future<void> setRange(int days) async {
    if (_days == days) return;
    _days = days;
    await load();
  }

  /// Tải số liệu phân tích từ backend.
  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      _analysis = await _service.getAnalysis(days: _days);
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
